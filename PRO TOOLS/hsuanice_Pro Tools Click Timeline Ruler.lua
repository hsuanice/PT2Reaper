--[[
@description hsuanice_Pro Tools Click Timeline Ruler
@version 26.1117.2337pre1
@author hsuanice
@noindex
@changelog
  - Time marker named ">"; remembers the loop points and the marker for a double click.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: clicking the Timebase ruler
  (mouse modifier: Ruler - left click)

  Pro Tools keeps two positions when nothing is selected: the Timeline position (set by
  clicking the ruler) and the Edit position. REAPER has one edit cursor, so with Link
  Timeline and Edit Selection off this click does not move the edit cursor (it stays the
  Edit position): it clears the Timeline Selection (loop points) and puts the Time marker
  (marker 9999 ">", blue) where you clicked (snapped to the grid). Space / Play Timeline Selection
  then play from the marker. Playing: playback goes on from there.
  Part of a double click: Double Click Timeline Ruler puts the loop points and the marker back.
  Link on: like REAPER's own click, the edit cursor moves there (no marker).

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
if T.linked() then
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
