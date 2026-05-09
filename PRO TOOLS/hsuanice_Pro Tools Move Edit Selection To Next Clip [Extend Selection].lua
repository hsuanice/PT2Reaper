-- @description hsuanice_Pro Tools Move Edit Selection To Next Clip [Extend Selection]
-- @version 0.2.0 [260509.1036]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools:
--   **Move Edit Selection To Next Clip [Extend Selection]**
--   (Cmd+Ctrl+Shift+' / Ctrl+Shift+Tab)
--
--   ## Behaviour
--   - Edit cursor stays at selection LEFT edge (anchor)
--   - Finds next transient/edge from selection RIGHT edge
--   - Extends selection rightward; cursor stays at left
--   - Selection only grows, never shrinks
--
--   Works with "Tab to Transient" toggle (ON=transients, OFF=item edges).
--   Transient mode applies the shared min-gap filter from
--   `Library/hsuanice_PT_Transient.lua` (`hsuanice_PT_Transient/min_ms`).
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags : Editing, Navigation, Selection
--
-- @changelog
--   0.2.0 [260509.1036] - First implementation. Mirrors Move Edit
--                          Insertion To Next Edit [Extend Selection]
--                          v0.2.0.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Move Edit Selection To Next Clip [Extend Selection]", 0)
  return
end

local function get_tab_toggle_state()
  local section = r.SectionFromUniqueID(0)
  local idx = 0
  while true do
    local cid, cname = r.kbd_enumerateActions(section, idx)
    if cid == 0 and idx > 0 then break end
    if cname and cname:lower():find("pro tools tab to transient", 1, true) then
      return r.GetToggleCommandStateEx(0, cid) == 1
    end
    idx = idx + 1
    if idx > 200000 then break end
  end
  return false
end

local function get_selected_tracks()
  local tracks = {}
  for i = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(tr, "I_SELECTED") == 1 then
      tracks[#tracks+1] = tr
    end
  end
  return tracks
end

local EPS = 1e-4
local cursor_pos = r.GetCursorPosition()
local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = te > ts + EPS

local anchor = has_ts and math.min(ts, cursor_pos) or cursor_pos
local search_from = has_ts and te or cursor_pos

r.SetEditCurPos(search_from, false, false)
r.Main_OnCommand(41229, 0)  -- Save selection set
r.Main_OnCommand(40421, 0)  -- Select all items in track

if get_tab_toggle_state() then
  Tran.cursor_to_next_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40319, 0)  -- Next item edge
end

local new_pos = r.GetCursorPosition()
r.Main_OnCommand(41239, 0)  -- Restore selection set

if math.abs(new_pos - search_from) > EPS then
  r.SetEditCurPos(anchor, false, false)
  r.GetSet_LoopTimeRange(true, false, anchor, new_pos, false)

  local tracks = get_selected_tracks()
  for _, tr in ipairs(tracks) do
    local razor_str = string.format('%.14f %.14f ""', anchor, new_pos)
    r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", razor_str, true)
  end
end

r.defer(function() end)
