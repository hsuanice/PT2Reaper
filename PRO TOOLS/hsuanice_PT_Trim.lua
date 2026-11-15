--[[
@description hsuanice_PT_Trim — Pro Tools-style trim/extend helpers
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared library for Pro Tools "Trim Clip ..." scripts.

  Two fade-preservation modes:
    "boundary" — preserve the fade boundary at its absolute timeline position
                 (fade length adjusts when the edge moves into / out of the fade).
                 Used by Trim ... To Cursor and Trim Clip To Selection.
    "length"   — preserve the fade length (the fade boundary follows the edge).
                 Used by Trim ... To Fill Selection.

  Source-bound clamp: extends are clamped to the available source headroom on
  the relevant side (no warning popup; just stops at the boundary).

  Multi-take: when the LEFT edge moves, D_STARTOFFS of every audio take in the
  item is shifted by the same delta so cross-take alignment is preserved.
--]]

local r   = reaper
local EPS = 1e-9
local M   = {}

-- ----- razor / selection helpers -----------------------------------------

function M.get_track_razor(track)
  local _, s = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
  if not s or s == '' then return nil end
  local rs, re = s:match('(%S+)%s+(%S+)%s+""')
  if rs and re then return tonumber(rs), tonumber(re) end
  return nil
end

-- Razor on item's track first; falls back to time selection.
function M.get_selection_for_item(item)
  local track = r.GetMediaItemTrack(item)
  local rs, re = M.get_track_razor(track)
  if rs and re then return rs, re end
  local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if te > ts + 1e-4 then return ts, te end
  return nil
end

-- ----- source-bound helpers ----------------------------------------------

local function max_extend_left(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return math.huge end
  local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') or 0
  local rate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') or 1.0
  if rate <= 0 then rate = 1.0 end
  return offs / rate
end

local function max_extend_right(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return math.huge end
  local source = r.GetMediaItemTake_Source(take)
  if not source then return math.huge end
  local src_len, isQN = r.GetMediaSourceLength(source)
  if isQN then return math.huge end
  local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') or 0
  local rate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') or 1.0
  if rate <= 0 then rate = 1.0 end
  local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  return math.max(0, (src_len - offs) / rate - len)
end

local function sync_takes_offset(item, delta_pos)
  for ti = 0, r.CountTakes(item) - 1 do
    local t = r.GetTake(item, ti)
    if t and not r.TakeIsMIDI(t) then
      local o  = r.GetMediaItemTakeInfo_Value(t, 'D_STARTOFFS') or 0
      local pr = r.GetMediaItemTakeInfo_Value(t, 'D_PLAYRATE') or 1.0
      if pr <= 0 then pr = 1.0 end
      r.SetMediaItemTakeInfo_Value(t, 'D_STARTOFFS', o + delta_pos * pr)
    end
  end
end

-- ----- core trim/extend functions ----------------------------------------

-- Move item's LEFT edge to target_pos.
--   mode = "boundary": preserve fade-in END (fade length shrinks/grows).
--   mode = "length":   preserve fade-in length (fade-in END follows the edge).
function M.trim_left(item, target_pos, mode)
  local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local en  = pos + len
  if target_pos >= en - EPS then return end  -- can't trim past item end

  local take     = r.GetActiveTake(item)
  local is_audio = take and (not r.TakeIsMIDI(take))

  local new_pos = target_pos
  -- Source bound clamp: only when extending left (target before pos)
  if is_audio and new_pos < pos then
    local min_pos = pos - max_extend_left(item)
    if new_pos < min_pos then new_pos = min_pos end
  end
  if math.abs(new_pos - pos) < 1e-12 then return end
  local new_len = en - new_pos

  -- Fade-in
  local old_fi = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN') or 0
  local new_fi
  if mode == "length" then
    new_fi = old_fi  -- fade-in length unchanged; fi_end follows new pos
  else
    -- "boundary": fi_end stays at absolute (pos + old_fi); fi length adjusts
    local fi_end_abs = pos + old_fi
    new_fi = (old_fi > 0) and math.max(0, fi_end_abs - new_pos) or 0
  end

  -- Apply (clear AUTO so the manual value sticks)
  r.SetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO', 0)
  if is_audio then
    sync_takes_offset(item, new_pos - pos)
  end
  r.SetMediaItemInfo_Value(item, 'D_POSITION',  new_pos)
  r.SetMediaItemInfo_Value(item, 'D_LENGTH',    new_len)
  r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', new_fi)
end

-- Move item's RIGHT edge to target_pos.
--   mode = "boundary": preserve fade-out START (fade length shrinks/grows).
--   mode = "length":   preserve fade-out length (fade-out START follows the edge).
function M.trim_right(item, target_pos, mode)
  local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local en  = pos + len
  if target_pos <= pos + EPS then return end  -- can't trim past item start

  local take     = r.GetActiveTake(item)
  local is_audio = take and (not r.TakeIsMIDI(take))

  local new_en = target_pos
  -- Source bound clamp: only when extending right (target past en)
  if is_audio and new_en > en then
    local max_en = en + max_extend_right(item)
    if new_en > max_en then new_en = max_en end
  end
  if math.abs(new_en - en) < 1e-12 then return end
  local new_len = new_en - pos

  -- Fade-out
  local old_fo = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN') or 0
  local new_fo
  if mode == "length" then
    new_fo = old_fo  -- fade-out length unchanged; fo_start follows new en
  else
    -- "boundary": fo_start stays at absolute (en - old_fo); fo length adjusts
    local fo_start_abs = en - old_fo
    new_fo = (old_fo > 0) and math.max(0, new_en - fo_start_abs) or 0
  end

  r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO', 0)
  r.SetMediaItemInfo_Value(item, 'D_LENGTH',     new_len)
  r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', new_fo)
end

-- ----- selection follow-extend helpers -----------------------------------

-- Snapshot the current razor (per track) and time selection. Returns a table
-- you pass into expand_selection_to_items() after running an extend operation.
function M.snapshot_selection()
  local snap = { razor = {}, ts_s = 0, ts_e = 0, has_ts = false }
  for ti = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false)
    if s and s ~= '' then
      local rs, re = s:match('(%S+)%s+(%S+)%s+""')
      if rs and re then snap.razor[tr] = { s = tonumber(rs), e = tonumber(re) } end
    end
  end
  local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_e > ts_s + 1e-4 then
    snap.has_ts = true; snap.ts_s = ts_s; snap.ts_e = ts_e
  end
  return snap
end

-- Expand the original razor (per track) and time selection to encompass each
-- selected item's CURRENT extent. Only writes if values actually changed.
-- Tracks that didn't originally have a razor are not touched.
-- (Use after running a Trim/Extend operation to make selection follow items.)
function M.expand_selection_to_items(snap)
  if not snap then return end
  local per_track = {}
  local g_min, g_max = math.huge, -math.huge
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    local tr   = r.GetMediaItemTrack(item)
    local pos  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local en   = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local pt = per_track[tr] or { mn = math.huge, mx = -math.huge }
    if pos < pt.mn then pt.mn = pos end
    if en  > pt.mx then pt.mx = en  end
    per_track[tr] = pt
    if pos < g_min then g_min = pos end
    if en  > g_max then g_max = en  end
  end
  -- Razor (per track that originally had razor)
  for tr, rz in pairs(snap.razor) do
    local pt = per_track[tr]
    if pt then
      local new_s = math.min(rz.s, pt.mn)
      local new_e = math.max(rz.e, pt.mx)
      if math.abs(new_s - rz.s) > 1e-6 or math.abs(new_e - rz.e) > 1e-6 then
        r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS',
          string.format('%.14f %.14f ""', new_s, new_e), true)
      end
    end
  end
  -- Time selection
  if snap.has_ts and g_min < math.huge then
    local new_ts_s = math.min(snap.ts_s, g_min)
    local new_ts_e = math.max(snap.ts_e, g_max)
    if math.abs(new_ts_s - snap.ts_s) > 1e-6 or math.abs(new_ts_e - snap.ts_e) > 1e-6 then
      r.GetSet_LoopTimeRange(true, false, new_ts_s, new_ts_e, false)
    end
  end
end

return M
