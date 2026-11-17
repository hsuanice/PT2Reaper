--[[
@description hsuanice_Pro Tools Double Click Timeline Ruler
@version 26.1117.2317pre1
@author hsuanice
@noindex
@changelog
  - Time marker renamed from V to >< (a V marker from 26.1117.2309pre1 is still found and renamed when moved).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Companion of Pro Tools Click Timeline Ruler (mouse modifier: Ruler - double click).

  Does what REAPER's ruler double click "Set time selection to region" does - inside a
  region: the time selection becomes the region; else: the range between the markers on
  either side - but the Time marker ("><", put down by the first click of the double click
  with Link Timeline and Edit Selection off) is not counted as a marker.
  No marker before: from the project start; none after: to the project end.

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

local skip = T.time_marker() -- the Time marker's number (not a marker for this)
local rs, re_, prev, nxt
local i = 0
while true do
  local ret, isrgn, pos, rend, _, idx = r.EnumProjectMarkers3(0, i)
  if ret == 0 then break end
  if isrgn then
    if pos <= p and p < rend and (not rs or pos > rs) then rs, re_ = pos, rend end -- innermost
  elseif idx ~= skip then
    if pos <= p and (not prev or pos > prev) then prev = pos end
    if pos > p and (not nxt or pos < nxt) then nxt = pos end
  end
  i = i + 1
end
local s, e
if rs then s, e = rs, re_ else s, e = prev or 0, nxt or r.GetProjectLength(0) end
if e > s then
  r.GetSet_LoopTimeRange2(0, true, false, s, e, false) -- the time selection (Link on: loop too)
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point
