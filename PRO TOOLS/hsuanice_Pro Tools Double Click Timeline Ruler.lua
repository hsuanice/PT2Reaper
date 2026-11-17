--[[
@description hsuanice_Pro Tools Double Click Timeline Ruler
@version 26.1118.0047pre1
@author hsuanice
@noindex
@changelog
  - Link off: the edit cursor (Edit position) goes to the start of the selected range.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Companion of Pro Tools Click Timeline Ruler (mouse modifier: Ruler - double click).

  Pro Tools: a double click on the Marker ruler selects the gap between markers; on the
  Timeline ruler it is a click. In REAPER (needs SWS to tell the parts of the ruler apart):
  - marker / region / tempo lanes (top part of the ruler): the gap between the nearest edges
    on either side - an edge is a marker or a region start / end (marker to marker, marker to
    region, region to region...); the Time marker (9999 ">") is not counted; no marker
    before: from the project start, none after: to the project end. It becomes the Edit
    range (time selection; no razor areas) and, Link Timeline and Edit Selection on, the
    Timeline range (loop points) too. Link off: the loop points stay and the edit cursor
    (Edit position) goes to the range start.
  - time scale: nothing more (the first click of the double click set the position).
  Without SWS the whole ruler acts as the lanes, and with Link off the loop points and the
  Time marker are put back as they were before the first click.

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

local seg = T.ruler_segment()
if seg == "timeline" then -- Pro Tools: a double click on the time scale is a click (done by the first one)
  r.PreventUIRefresh(-1)
  r.defer(function() end)
  return
end
-- no SWS (whole ruler): put back what the first click (Click Timeline Ruler) changed
if not seg and not T.linked() then T.ruler_undo_click() end

local skip = T.time_marker() -- the Time marker's number (not a marker for this)
local prev, nxt
local function edge(x) -- a marker, or a region start / end
  if x <= p and (not prev or x > prev) then prev = x end
  if x > p and (not nxt or x < nxt) then nxt = x end
end
local i = 0
while true do
  local ret, isrgn, pos, rend, _, idx = r.EnumProjectMarkers3(0, i)
  if ret == 0 then break end
  if isrgn then edge(pos); edge(rend)
  elseif idx ~= skip then edge(pos) end
  i = i + 1
end
local s, e = prev or 0, nxt or r.GetProjectLength(0)
if e > s then
  -- Edit range = time selection (no razor areas: Pro Tools selects on the Marker ruler only);
  -- Link on: the Timeline range (loop points) too
  r.GetSet_LoopTimeRange2(0, true, false, s, e, false)
  if T.linked() then r.GetSet_LoopTimeRange2(0, true, true, s, e, false)
  else r.SetEditCurPos2(0, s, false, false) end -- Link off: the Edit position goes to the range start
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point
