--[[
@description hsuanice_Pro Tools Double Click Timeline Ruler
@version 26.1117.2337pre1
@author hsuanice
@noindex
@changelog
  - Time selection between the nearest markers (regions not used); Link off: the loop points and the Time marker stay as they were.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Companion of Pro Tools Click Timeline Ruler (mouse modifier: Ruler - double click).

  The time selection becomes the range between the nearest markers on either side of the
  double click (regions are not used). The Time marker (marker 9999 ">") is not counted.
  No marker before: from the project start; none after: to the project end.
  Link Timeline and Edit Selection off: the loop points and the Time marker stay as they were
  before the double click (the first click of it is undone). Link on: the loop points follow
  the time selection (REAPER).

  Set it in Preferences > Editing Behavior > Mouse Modifiers > Ruler > double click.
  Self-contained: uses hsuanice_PT_Transport.lua (same folder).
  - Tags : Timeline, Selection
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
r.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping): where was clicked
local p = r.GetCursorPosition()
r.SetEditCurPos2(0, cur, false, false)

if not T.linked() then T.ruler_undo_click() end -- loop points + Time marker as before the first click

local skip = T.time_marker() -- the Time marker's number (not a marker for this)
local prev, nxt
local i = 0
while true do
  local ret, isrgn, pos, _, _, idx = r.EnumProjectMarkers3(0, i)
  if ret == 0 then break end
  if not isrgn and idx ~= skip then
    if pos <= p and (not prev or pos > prev) then prev = pos end
    if pos > p and (not nxt or pos < nxt) then nxt = pos end
  end
  i = i + 1
end
local s, e = prev or 0, nxt or r.GetProjectLength(0)
if e > s then
  r.GetSet_LoopTimeRange2(0, true, false, s, e, false) -- the time selection (Link on: loop too)
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point
