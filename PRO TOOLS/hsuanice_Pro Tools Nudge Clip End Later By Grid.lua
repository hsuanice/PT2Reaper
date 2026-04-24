-- @description hsuanice_Pro Tools Nudge Clip End Later By Grid
-- @version 0.6.0 [260421.1214]
-- @author hsuanice
-- @about
--   Replicates Pro Tools: **Nudge Clip End Later By Grid**
--   Fill + nudge mechanism: boundary fills to selection edge first, then nudges.
--   Zone-aware stop guard prevents zone from disappearing.
--   Tags: Editing
-- @changelog
--   0.6.0 [260421.1214] - Use NudgeEdge module (crossfade-aware nudge_end)
--   0.5.0 [260421.1048] - Item-only selection uses nudge_end (fade-aware) instead of ApplyNudge
--   0.4.0 [260420.1523] - Add fill mechanism + correct zone-size stop guard
--   0.3.0 [260420.1247] - 3-boundary logic with stop guard
--   0.2.0 [260420.1132] - PT selection-aware nudge
--   0.1.0 [260419.1012] - Initial release

local r = reaper
local info = debug.getinfo(1, 'S')
local dir = info.source:match('^@(.*[/\\])') or ''
local ok, Nudge = pcall(dofile, dir .. 'hsuanice_PT_Nudge.lua')
if not ok then
  r.ShowMessageBox('Could not load hsuanice_PT_Nudge.lua', 'Error', 0)
  return
end
local _, NudgeEdge = pcall(dofile, dir .. '../Library/hsuanice_PT_NudgeEdge.lua')

local EPS = 1e-4

local function get_delta()
  local mode, idx = Nudge.get_state()
  local preset = Nudge.get_preset(mode, idx)
  if not preset then return 0 end
  local unit, value = preset.unit, preset.value
  if unit == 0  then return value / 1000.0 end
  if unit == 1  then return value end
  if unit == 17 then
    local sr = r.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
    return value / sr
  end
  if unit == 18 then
    local _, fps = r.TimeMap_curFrameRate(0)
    fps = (fps and fps > 0) and fps or 24
    return value / fps
  end
  if unit == 16 then
    local bpm = r.GetProjectTimeSignature2(0)
    local _, bps = r.TimeMap_GetTimeSigAtTime(0, r.GetCursorPosition())
    return math.floor(value) * (60.0/bpm) * bps
  end
  if unit >= 3 and unit <= 15 then
    local bpm = r.GetProjectTimeSignature2(0)
    local beat_sec = 60.0 / bpm
    local note_map = {[3]=1/64,[4]=1/32,[5]=1/16,[6]=1/8,[7]=1/4,
      [8]=1/2,[9]=1,[10]=2,[11]=4,[12]=8,[13]=16,[14]=32,[15]=64}
    return beat_sec * (note_map[unit] or 1) * value
  end
  return 0
end

local function get_track_razor(track)
  local _, s = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
  if not s or s == '' then return nil, nil end
  local rs, re = s:match('(%S+)%s+(%S+)%s+""')
  if rs and re then return tonumber(rs), tonumber(re) end
  return nil, nil
end

local function update_razor(track, new_s, new_e)
  local _, s = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
  if not s or s == '' then return end
  local updated = s:gsub('(%S+)%s+(%S+)%s+""', function()
    return string.format('%.14f %.14f ""', new_s, new_e)
  end)
  r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', updated, true)
end

local nudge_end = NudgeEdge and NudgeEdge.nudge_end or function(_, sel_s, sel_e, _) return sel_s, sel_e end

local delta = get_delta()
if math.abs(delta) < 1e-10 then return end

local has_items = r.CountSelectedMediaItems(0) > 0
local has_razor = false
for ti = 0, r.CountTracks(0)-1 do
  local _, s = r.GetSetMediaTrackInfo_String(r.GetTrack(0,ti), 'P_RAZOREDITS', '', false)
  if s and s ~= '' then has_razor = true; break end
end
local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = ts_e > ts_s + EPS

if not has_items and not has_razor and not has_ts then
  r.SetEditCurPos(r.GetCursorPosition() + delta, true, false)
  r.defer(function() end)
  return
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local new_sel_e_global = nil

for i = 0, r.CountSelectedMediaItems(0) - 1 do
  local item  = r.GetSelectedMediaItem(0, i)
  local track = r.GetMediaItemTrack(item)
  local sel_s, sel_e = get_track_razor(track)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local item_e = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')

  if sel_s and sel_e then
    if sel_e > pos + EPS and sel_s < item_e - EPS then
      local new_s, new_e = nudge_end(item, sel_s, sel_e, delta)
      if math.abs(new_s - sel_s) > 1e-10 or math.abs(new_e - sel_e) > 1e-10 then
        new_sel_e_global = new_e
        update_razor(track, new_s, new_e)
      end
    end
  else
    local _, new_e = nudge_end(item, pos, item_e, delta)
    if math.abs(new_e - item_e) > 1e-10 then
      new_sel_e_global = new_e
    end
  end
end

if not has_items then
  if has_razor then
    for ti = 0, r.CountTracks(0) - 1 do
      local tr = r.GetTrack(0, ti)
      local rs, re = get_track_razor(tr)
      if rs then
        new_sel_e_global = re + delta
        update_razor(tr, rs, re + delta)
      end
    end
  elseif has_ts then
    new_sel_e_global = ts_e + delta
  end
end

local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
if te > ts + EPS and new_sel_e_global then
  r.GetSet_LoopTimeRange(true, false, ts, new_sel_e_global, false)
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Nudge Clip End Later By Grid', -1)
