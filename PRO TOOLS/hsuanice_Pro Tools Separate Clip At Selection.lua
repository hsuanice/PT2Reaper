-- @description hsuanice_Pro Tools Separate Clip At Selection
-- @version 0.5.0 [260507.1230]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Separate Clip At Selection** (Cmd+E)
--
--   ## Behavior
--   - **Time selection exists** → split each selected item at TS_start AND
--     TS_end. After: TS / razor preserved; item selection keeps ONLY the
--     pieces inside the TS range.
--   - **No time selection**     → split each selected item at the edit
--     cursor. After: razor / TS / item selection all cleared.
--   - **Crossfade-aware**       → if a split point lands inside the overlap
--     region of two items on the same track (i.e., a crossfade), both items
--     are TRIMMED to the split point instead of being split:
--       * left crossfading item   → length cropped to split, fade-out set
--         to the portion of the auto/manual fade that fell before split.
--       * right crossfading item  → position pushed to split, fade-in set
--         to the remainder past split, D_STARTOFFS adjusted to keep audio
--         aligned.
--     The two items now TOUCH at the split point with regular fades — the
--     crossfade is broken, replaced by a fade-out + fade-in pair.
--   - **Plain split fade rule**  → outside crossfade regions, asymmetric:
--       * split inside fade-in   → left.fade-in cleared, right gets remainder.
--       * split inside fade-out  → right.fade-out cleared, left gets portion.
--   - Tags: Editing, Clips
-- @changelog
--   0.5.0 [260507.1230] - Crossfade-aware: split points inside item-overlap
--                          regions now trim both items to the split point,
--                          converting the crossfade into a fade-out / fade-in
--                          pair (matches PT). Outside crossfades, the
--                          asymmetric fade rule from 0.4.0 still applies.
--   0.4.0 [260507.1130] - Asymmetric fade rule + per-mode selection handling.
--   0.3.0 [260507.1100] - First custom version.
--   0.2.0 [260506.2030] - Map to native 40196.
--   0.1.0 [260415.1250] - Stub placeholder created.

local r = reaper
local EPS = 1e-9

-- ---- Plain split with asymmetric fade rule -------------------------------
local function split_with_fades(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_fin = item_pos + item_len
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return nil end

  local fi_orig = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")  or 0
  local fo_orig = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN") or 0

  local right = r.SplitMediaItem(item, pos)
  if not right then return nil end

  local left_len  = pos - item_pos
  local right_len = item_fin - pos

  local fi_end_abs = item_pos + fi_orig
  if (pos > item_pos + EPS) and (pos < fi_end_abs - EPS) then
    r.SetMediaItemInfo_Value(item,  "D_FADEINLEN", 0)
    r.SetMediaItemInfo_Value(right, "D_FADEINLEN", math.min(fi_end_abs - pos, right_len))
  else
    r.SetMediaItemInfo_Value(item,  "D_FADEINLEN", math.min(fi_orig, left_len))
    r.SetMediaItemInfo_Value(right, "D_FADEINLEN", 0)
  end

  local fo_start_abs = item_fin - fo_orig
  if (pos > fo_start_abs + EPS) and (pos < item_fin - EPS) then
    r.SetMediaItemInfo_Value(item,  "D_FADEOUTLEN", math.min(pos - fo_start_abs, left_len))
    r.SetMediaItemInfo_Value(right, "D_FADEOUTLEN", 0)
  else
    r.SetMediaItemInfo_Value(item,  "D_FADEOUTLEN", 0)
    r.SetMediaItemInfo_Value(right, "D_FADEOUTLEN", math.min(fo_orig, right_len))
  end

  return right
end

-- ---- Crossfade-aware trim helpers ----------------------------------------

-- Trim the LEFT item of a crossfade pair to end at `pos`. The fade-out is
-- set to the portion of the (auto-or-manual) fade-out that fell before
-- `pos`. Auto-fade is cleared because the items no longer overlap after.
local function trim_left_crossfade(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_fin = item_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return end

  local fo_man  = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")      or 0
  local fo_auto = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO") or 0
  local fo_eff  = math.max(fo_man, fo_auto)
  local fo_start_abs = item_fin - fo_eff

  r.SetMediaItemInfo_Value(item, "D_LENGTH", pos - item_pos)

  local new_fo
  if pos > fo_start_abs + EPS then
    new_fo = pos - fo_start_abs
  else
    new_fo = fo_eff
  end
  new_fo = math.min(new_fo, pos - item_pos)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN",      new_fo)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
end

-- Trim the RIGHT item of a crossfade pair to start at `pos`. Position is
-- pushed to `pos`, length shortened, take STARTOFFS shifted to keep audio
-- in sync. Fade-in is set to the (auto-or-manual) fade-in's remainder past
-- `pos`. Auto-fade cleared.
local function trim_right_crossfade(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_fin = item_pos + item_len
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return end

  local fi_man  = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")      or 0
  local fi_auto = r.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO") or 0
  local fi_eff  = math.max(fi_man, fi_auto)
  local fi_end_abs = item_pos + fi_eff

  local delta = pos - item_pos
  r.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  r.SetMediaItemInfo_Value(item, "D_LENGTH",   item_len - delta)
  for ti = 0, r.CountTakes(item) - 1 do
    local t = r.GetTake(item, ti)
    if t and not r.TakeIsMIDI(t) then
      local o  = r.GetMediaItemTakeInfo_Value(t, "D_STARTOFFS") or 0
      local pr = r.GetMediaItemTakeInfo_Value(t, "D_PLAYRATE")  or 1.0
      if pr <= 0 then pr = 1.0 end
      r.SetMediaItemTakeInfo_Value(t, "D_STARTOFFS", o + delta * pr)
    end
  end

  local new_fi
  if pos < fi_end_abs - EPS then
    new_fi = fi_end_abs - pos
  else
    new_fi = 0
  end
  new_fi = math.min(new_fi, item_len - delta)
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN",      new_fi)
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
end

-- Find a crossfade pair (two items on the same track that both strictly
-- contain `pos` in their interior) within `pool`. Returns left, right items
-- (sorted by position) or nil, nil.
local function find_crossfade_pair(pool, pos, handled)
  for i = 1, #pool do
    local a = pool[i]
    if not handled[a] then
      local a_pos = r.GetMediaItemInfo_Value(a, "D_POSITION")
      local a_fin = a_pos + r.GetMediaItemInfo_Value(a, "D_LENGTH")
      if pos > a_pos + EPS and pos < a_fin - EPS then
        local a_track = r.GetMediaItemTrack(a)
        for j = i+1, #pool do
          local b = pool[j]
          if not handled[b] and r.GetMediaItemTrack(b) == a_track then
            local b_pos = r.GetMediaItemInfo_Value(b, "D_POSITION")
            local b_fin = b_pos + r.GetMediaItemInfo_Value(b, "D_LENGTH")
            if pos > b_pos + EPS and pos < b_fin - EPS then
              if a_pos < b_pos then return a, b else return b, a end
            end
          end
        end
      end
    end
  end
  return nil, nil
end

-- ---- Determine mode + split positions ------------------------------------

local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts     = ts_e > ts_s + EPS
local cursor     = r.GetCursorPosition()

local positions = has_ts and {ts_s, ts_e} or {cursor}

local pool = {}
for i = 0, r.CountSelectedMediaItems(0)-1 do
  pool[#pool+1] = r.GetSelectedMediaItem(0, i)
end
if #pool == 0 then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for _, sp in ipairs(positions) do
  local handled = {}
  -- Crossfade pairs first (greedy — keep finding pairs until none remain).
  while true do
    local left, right = find_crossfade_pair(pool, sp, handled)
    if not left or not right then break end
    trim_left_crossfade(left, sp)
    trim_right_crossfade(right, sp)
    handled[left]  = true
    handled[right] = true
  end
  -- Plain split on remaining unhandled items.
  local snapshot = {}
  for _, it in ipairs(pool) do
    if not handled[it] then snapshot[#snapshot+1] = it end
  end
  for _, it in ipairs(snapshot) do
    local new_right = split_with_fades(it, sp)
    if new_right then pool[#pool+1] = new_right end
  end
end

-- ---- Selection handling --------------------------------------------------

r.Main_OnCommand(40289, 0)  -- unselect all

if has_ts then
  for _, it in ipairs(pool) do
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos >= ts_s - EPS and fin <= ts_e + EPS then
      r.SetMediaItemSelected(it, true)
    end
  end
else
  for ti = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
    end
  end
  r.GetSet_LoopTimeRange(true, false, 0, 0, false)
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Separate Clip At Selection", -1)
