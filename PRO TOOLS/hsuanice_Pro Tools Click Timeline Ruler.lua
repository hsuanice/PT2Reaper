--[[
@description hsuanice_Pro Tools Click Timeline Ruler
@version 26.1118.0119
@author hsuanice
@noindex
@changelog
  - Release: the Time marker is named with its timecode (tested in REAPER).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: clicking the Timebase ruler
  (mouse modifier: Ruler - left click)

  Pro Tools keeps two positions when nothing is selected: the Timeline position (set by
  clicking the ruler) and the Edit position. REAPER has one edit cursor, so with Link
  Timeline and Edit Selection off this click does not move the edit cursor (it stays the
  Edit position): it clears the Timeline Selection (loop points) and puts the Time marker
  (marker 9999, named with its timecode, blue) where you clicked (snapped to the grid). Space / Play Timeline Selection
  then play from the marker. Playing: playback goes on from there.
  Marker / region lanes (top part of the ruler; needs SWS to tell them apart): Link on, the
  same; Link off, like a click on empty track space - the edit cursor (Edit position) moves
  there and the Edit range (razor areas, time selection) is cleared; loop points and the
  Time marker stay (Pro Tools: the Marker ruler does not set the Timeline position then).
  Part of a double click: Double Click Timeline Ruler puts the loop points and the marker back.
  Link on: the edit cursor moves there and every range is cleared - razor areas, time
  selection, loop points (Pro Tools); no marker.

  Set it in Preferences > Editing Behavior > Mouse Modifiers > Ruler > left click.
  Self-contained: uses hsuanice_PT_Transport.lua (same folder).
  - Tags : Transport, Timeline
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
if not ok or type(T) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua\n\n' .. tostring(T), 'Error', 0)
  return
end

local cur = r.GetCursorPosition()
r.PreventUIRefresh(1)
r.Main_OnCommand(40513, 0) -- View: Move edit cursor to mouse cursor (snapping): where was clicked
local p = r.GetCursorPosition()
local lane = T.ruler_segment() == "lane" -- marker / region lanes (SWS), else the time scale
if lane and not T.linked() then
  -- Pro Tools Marker ruler, Link off: like a click on empty track space - the Edit position
  -- moves there and the Edit range is cleared; the Timeline (loop points, Time marker) stays
  r.Main_OnCommand(42406, 0) -- Razor edit: Clear all areas
  r.GetSet_LoopTimeRange2(0, true, false, 0, 0, false)
elseif T.linked() then
  -- Pro Tools: a point now - every range is cleared (razor areas, time selection, loop points)
  r.Main_OnCommand(42406, 0) -- Razor edit: Clear all areas
  r.GetSet_LoopTimeRange2(0, true, false, 0, 0, false)
  r.GetSet_LoopTimeRange2(0, true, true, 0, 0, false)
  if T.is_running() then T.watch_clear(); r.SetEditCurPos2(0, p, false, true) end
else
  r.SetEditCurPos2(0, cur, false, false) -- the Edit position stays
  T.ruler_remember() -- a double click (Double Click Timeline Ruler) puts it back
  r.GetSet_LoopTimeRange2(0, true, true, 0, 0, false) -- a point now: no Timeline Selection
  T.set_time_pos(p)
  if T.is_running() then T.watch_clear(); T.start_at(p, cur) end
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point
