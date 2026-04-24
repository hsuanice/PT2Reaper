-- @description hsuanice_Pro Tools Nudge Clip Earlier By Grid
-- @version 0.8.5 [260422.1820]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Nudge Clip Earlier By Grid**
--
--   Selection-aware nudge using Razor area as selection.
--   Each selected item is judged independently based on
--   how the razor area overlaps its fade/clip zones.
--
--   Rules (move later, earlier is reversed):
--   fade_in+clip+fade_out covered -> item position move
--   clip only covered             -> contents +delta, fade_in +delta, fade_out -delta
--   clip+fade_out covered         -> contents +delta, fade_in +delta, right end moves
--   fade_in+clip covered          -> left end moves, fade_out -delta
--   fade_out only covered         -> right end moves, clip gets longer
--   fade_in only covered          -> left end moves, clip gets longer
--   nothing covered               -> selection only moves (no item change)
--
--   Tags: Editing
-- @changelog
--   0.8.5 [260422.1820] - All razors sync: any blocked track freezes all razors and time selection (not per-track)
--   0.8.4 [260422.1820] - nudge_item returns false on guard block; main loop freezes razor+time-sel when all tracks blocked
--   0.8.3 [260422.1820] - Case 2: unify Earlier fi_len guard — stops when fi_len exhausted (Zone A consumed) for all xf cases
--   0.8.2 [260422.1820] - Case 2: remove STARTOFFS change — zone boundary move must not shift audio content
--   0.8.1 [260422.1820] - Case 2: Zone D stop guard — broaden fo_len guard to cover left_xf-only (no right_xf) Later
--   0.8.0 [260422.1820] - Case 2: Zone D atomic update (item_e_A shifts with fi_end_B — left crossfade consistent)
--                       - Case 2: expanded stop guards covering both Zone B (right_xf) and Zone D (left_xf)
--   0.7.0 [260422.1728] - Case 2: Zone C atomic update (pos_B shifts with fo_start — crossfade consistent)
--                       - Case 2: stop guards — C eating A (Earlier) and crossfade vanishing (Later)
--                       - Case 4: don't change fo_len when right crossfade exists (right edge fixed)
--                       - Case 6: stop guard — Later can't let C eat right item's clip body
--   0.6.0 [260422.1728] - fi_covered/fo_covered require fade > 0; sync always-set; Case 2&4 sync fo
--   0.5.0 [260422.1709] - Use effective fades (AUTO overrides manual) for coverage and sync
--   0.4.0 [260421.1214] - Crossfade-aware nudge via NudgeEdge module
--   0.3.0 [260419.1806] - Rewrite: full PT selection-aware nudge logic
--   0.2.0 [260418.1931] - ApplyNudge via PT_Nudge library

local r = reaper
local info = debug.getinfo(1, "S")
local dir = info.source:match("^@(.*[/\\])") or ""
local ok, Nudge = pcall(dofile, dir .. "hsuanice_PT_Nudge.lua")
if not ok then
  r.ShowMessageBox("Could not load hsuanice_PT_Nudge.lua", "Error", 0)
  return
end
local _, Sync      = pcall(dofile, dir .. "../Library/hsuanice_PT_SelectionSync.lua")
local _, NudgeEdge = pcall(dofile, dir .. "../Library/hsuanice_PT_NudgeEdge.lua")

local EPS = 1e-4

-- Get nudge delta in seconds
local function get_delta()
  local mode, idx = Nudge.get_state()
  local preset = Nudge.get_preset(mode, idx)
  if not preset then return 0 end
  local unit  = preset.unit
  local value = preset.value
  if unit == 0  then return value / 1000.0 end
  if unit == 1  then return value end
  if unit == 17 then
    local sr = r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)
    return value / sr
  end
  if unit == 18 then
    local _, fps = r.TimeMap_curFrameRate(0)
    fps = (fps and fps > 0) and fps or 24
    return value / fps
  end
  if unit == 16 then
    local pos = r.GetCursorPosition()
    local bpm, _ = r.GetProjectTimeSignature2(0)
    local _, bps = r.TimeMap_GetTimeSigAtTime(0, pos)
    return math.floor(value) * (60.0/bpm) * bps
  end
  if unit >= 3 and unit <= 15 then
    local bpm, _ = r.GetProjectTimeSignature2(0)
    local beat_sec = 60.0 / bpm
    local note_map = {[3]=1/64,[4]=1/32,[5]=1/16,[6]=1/8,[7]=1/4,
      [8]=1/2,[9]=1,[10]=2,[11]=4,[12]=8,[13]=16,[14]=32,[15]=64}
    return beat_sec * (note_map[unit] or 1) * value
  end
  return 0
end

-- Get razor range for a track (guid="" track-level only)
local function get_track_razor(track)
  local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if not s or s == "" then return nil end
  local rs, re = s:match('(%S+)%s+(%S+)%s+""')
  if rs and re then return tonumber(rs), tonumber(re) end
  return nil
end

-- Nudge one item based on razor selection overlap
local function nudge_item(item, sel_s, sel_e, delta)
  local track   = r.GetMediaItemTrack(item)
  local pos     = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local len     = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  -- Use effective fades (AUTO overrides manual) so crossfade zone is detected correctly
  local fi_len  = NudgeEdge and NudgeEdge.get_fi(item) or r.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  local fo_len  = NudgeEdge and NudgeEdge.get_fo(item) or r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
  local item_e  = pos + len
  local fi_end  = pos + fi_len
  local fo_start = item_e - fo_len

  local fi_covered   = fi_len > EPS and (sel_s <= pos      + EPS and sel_e >= fi_end    - EPS)
  local fo_covered   = fo_len > EPS and (sel_s <= fo_start + EPS and sel_e >= item_e   - EPS)
  local clip_covered = sel_s <= fi_end   + EPS and sel_e >= fo_start - EPS

  if sel_e <= pos + EPS or sel_s >= item_e - EPS then return end

  local take = r.GetActiveTake(item)

  -- Find crossfade neighbors before any modifications
  local left_xf  = NudgeEdge and NudgeEdge.find_left_xfade(track, item) or nil
  local right_xf = NudgeEdge and NudgeEdge.find_right_xfade(track, item) or nil

  -- Adjust left xfade partner after this item's left edge moves to pos+delta
  local function sync_left()
    if not left_xf then return end
    local la_e   = r.GetMediaItemInfo_Value(left_xf, 'D_POSITION')
                 + r.GetMediaItemInfo_Value(left_xf, 'D_LENGTH')
    local new_ov = math.max(0, la_e - (pos + delta))
    if NudgeEdge then
      NudgeEdge.set_fo(left_xf, new_ov)
      NudgeEdge.set_fi(item, new_ov)
    else
      r.SetMediaItemInfo_Value(left_xf, 'D_FADEOUTLEN', new_ov)
      r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', new_ov)
    end
  end

  -- Adjust right xfade partner after this item's right edge moves to item_e+delta
  local function sync_right()
    if not right_xf then return end
    local rc_pos = r.GetMediaItemInfo_Value(right_xf, 'D_POSITION')
    local new_ov = math.max(0, (item_e + delta) - rc_pos)
    if NudgeEdge then
      NudgeEdge.set_fi(right_xf, new_ov)
      NudgeEdge.set_fo(item, new_ov)
    else
      r.SetMediaItemInfo_Value(right_xf, 'D_FADEINLEN', new_ov)
      r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', new_ov)
    end
  end

  local function set_fi_item(v) if NudgeEdge then NudgeEdge.set_fi(item, v) else r.SetMediaItemInfo_Value(item, 'D_FADEINLEN',  v) end end
  local function set_fo_item(v) if NudgeEdge then NudgeEdge.set_fo(item, v) else r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', v) end end

  if fi_covered and clip_covered and fo_covered then
    -- Case 1: entire item -> position move (both ends shift by delta)
    r.SetMediaItemInfo_Value(item, 'D_POSITION', pos + delta)
    sync_left(); sync_right()

  elseif clip_covered and not fi_covered and not fo_covered then
    -- Case 2: Zone B or Zone D shift — fi_end and fo_start both move by delta
    -- Zone C right atomic (Zone B): pos_B shifts with fo_start_A
    -- Zone C left atomic (Zone D): item_e_A shifts with fi_end_B
    -- Stop guards
    if delta > 0 and fo_len - delta < EPS then return false end               -- fo_len would be exhausted (Later)
    if delta < 0 and fi_len + delta < EPS then return false end               -- fi_len would be exhausted (Earlier) — Zone A consumed
    if not right_xf and not left_xf and delta < 0 and (fo_start - fi_end) + delta < EPS then return false end
    -- Left atomic (Zone D): item_e_A moves with fi_end_B
    if left_xf then
      local la_len = r.GetMediaItemInfo_Value(left_xf, 'D_LENGTH')
      local la_fo  = NudgeEdge and NudgeEdge.get_fo(left_xf) or r.GetMediaItemInfo_Value(left_xf, 'D_FADEOUTLEN')
      r.SetMediaItemInfo_Value(left_xf, 'D_LENGTH', la_len + delta)
      if la_fo > EPS then
        if NudgeEdge then NudgeEdge.set_fo(left_xf, la_fo + delta)
        else r.SetMediaItemInfo_Value(left_xf, 'D_FADEOUTLEN', la_fo + delta) end
      end
      set_fi_item(fi_len + delta)
    else
      set_fi_item(math.max(0, fi_len + delta))
    end
    -- Right atomic (Zone B): pos_B moves with fo_start_A
    if right_xf then
      local xf_pos  = r.GetMediaItemInfo_Value(right_xf, 'D_POSITION')
      local xf_len  = r.GetMediaItemInfo_Value(right_xf, 'D_LENGTH')
      local xf_fi   = NudgeEdge and NudgeEdge.get_fi(right_xf) or r.GetMediaItemInfo_Value(right_xf, 'D_FADEINLEN')
      local xf_take = r.GetActiveTake(right_xf)
      r.SetMediaItemInfo_Value(right_xf, 'D_POSITION', xf_pos + delta)
      r.SetMediaItemInfo_Value(right_xf, 'D_LENGTH',   xf_len - delta)
      set_fo_item(fo_len - delta)
      if xf_fi > EPS then
        if NudgeEdge then NudgeEdge.set_fi(right_xf, xf_fi - delta)
        else r.SetMediaItemInfo_Value(right_xf, 'D_FADEINLEN', xf_fi - delta) end
      end
      if xf_take then
        local offs = r.GetMediaItemTakeInfo_Value(xf_take, 'D_STARTOFFS')
        r.SetMediaItemTakeInfo_Value(xf_take, 'D_STARTOFFS', offs + delta)
      end
    else
      set_fo_item(math.max(0, fo_len - delta))
    end

  elseif clip_covered and not fi_covered and fo_covered then
    -- Case 3: clip + fade_out -> fi grows, right end moves, contents move right
    r.SetMediaItemInfo_Value(item, 'D_LENGTH', len + delta)
    set_fi_item(fi_len + delta)
    if take then
      local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs - delta)
    end
    sync_right()

  elseif clip_covered and fi_covered and not fo_covered then
    -- Case 4: fade_in + clip -> left end moves, right edge fixed, contents move right
    -- Crossfade fo stays (right edge fixed = physical overlap unchanged)
    r.SetMediaItemInfo_Value(item, 'D_POSITION', pos + delta)
    r.SetMediaItemInfo_Value(item, 'D_LENGTH',   len - delta)
    if not right_xf then
      set_fo_item(math.max(0, fo_len - delta))
    end
    if take then
      local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs - delta)
    end
    sync_left()

  elseif fo_covered and not clip_covered then
    -- Case 6: fade_out only -> right end moves
    -- Stop: Later (delta>0) — don't let C eat right item's clip body
    if delta > 0 and right_xf then
      local xf_len = r.GetMediaItemInfo_Value(right_xf, 'D_LENGTH')
      local xf_fo  = NudgeEdge and NudgeEdge.get_fo(right_xf) or r.GetMediaItemInfo_Value(right_xf, 'D_FADEOUTLEN')
      local xf_fi  = NudgeEdge and NudgeEdge.get_fi(right_xf) or r.GetMediaItemInfo_Value(right_xf, 'D_FADEINLEN')
      if xf_len - xf_fo - xf_fi - delta <= EPS then return false end
    end
    r.SetMediaItemInfo_Value(item, 'D_LENGTH', len + delta)
    sync_right()

  elseif fi_covered and not clip_covered then
    -- Case 7: fade_in only -> left end moves
    r.SetMediaItemInfo_Value(item, 'D_POSITION', pos + delta)
    r.SetMediaItemInfo_Value(item, 'D_LENGTH',   len - delta)
    if take then
      local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs + delta)
    end
    sync_left()

  end
  return true
end

-- Main
local delta = -get_delta()
if math.abs(delta) < 1e-10 then return end

-- Fallback: no items selected and no razor -> move edit cursor only
local has_items = r.CountSelectedMediaItems(0) > 0
local has_razor = false
for ti = 0, r.CountTracks(0) - 1 do
  local _, s = r.GetSetMediaTrackInfo_String(r.GetTrack(0,ti), 'P_RAZOREDITS', '', false)
  if s and s ~= '' then has_razor = true; break end
end

if not has_items and not has_razor then
  r.SetEditCurPos(r.GetCursorPosition() + delta, true, false)
  r.defer(function() end)
  return
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

-- track_nudged: nil = no item processed, true = moved, false = all blocked
local track_nudged = {}

for i = 0, r.CountSelectedMediaItems(0) - 1 do
  local item  = r.GetSelectedMediaItem(0, i)
  local track = r.GetMediaItemTrack(item)
  local sel_s, sel_e = get_track_razor(track)
  local pos   = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len   = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local item_e = pos + len

  if sel_s and sel_e then
    -- Razor exists: use razor as selection
    if sel_e > pos + EPS and sel_s < item_e - EPS then
      local clamped_s = math.max(sel_s, pos)
      local clamped_e = math.min(sel_e, item_e)
      local moved = nudge_item(item, clamped_s, clamped_e, delta)
      if moved == false then
        if track_nudged[track] == nil then track_nudged[track] = false end
      else
        track_nudged[track] = true  -- success (or no-match nil) overrides block
      end
    end
  else
    -- No razor: item selection = entire item -> position move
    if NudgeEdge then NudgeEdge.nudge_position(item, delta)
    else r.SetMediaItemInfo_Value(item, 'D_POSITION', pos + delta) end
    track_nudged[track] = true
  end
end

-- All razors sync: if any track is blocked, freeze all razors and time selection
local any_blocked = false
for _, v in pairs(track_nudged) do
  if v == false then any_blocked = true; break end
end
local do_move = not any_blocked

for ti = 0, r.CountTracks(0) - 1 do
  if do_move then
    local track = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
    if s and s ~= '' then
      local new_s = s:gsub('(%S+)%s+(%S+)%s+""', function(a, b)
        local rs, re = tonumber(a), tonumber(b)
        if rs and re then
          return string.format('%.14f %.14f ""', rs + delta, re + delta)
        end
        return a .. ' ' .. b .. ' ""'
      end)
      r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', new_s, true)
    end
  end
end

local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
if te > ts + EPS and do_move then
  r.GetSet_LoopTimeRange(true, false, ts + delta, te + delta, false)
end

if Sync then Sync.cursor_follow() end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Nudge Clip Earlier By Grid', -1)
