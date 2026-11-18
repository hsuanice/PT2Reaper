--[[
@description hsuanice_Pro Tools Zoom To Fit Horizontal Selection
@version 26.1118.1259pre1
@author hsuanice
@noindex
@changelog
  - First version (was a placeholder): Pro Tools behaviour - fits the Edit range, else centers the Edit position.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Zoom To Fit Horizontal Selection**
  (PT keys: Command+F5, Command+Control+], Option+Control+F)

  Edit range (razor areas, else the time selection): zooms horizontally so it fills the
  arrange view, with a small margin on both sides (4 % of its length, as Pro Tools).
  No Edit range (only a position; loop points do not count): the zoom stays, the view is
  scrolled so the Edit position (edit cursor) is in the middle.
  Track heights are not changed. Not a toggle: pressing it again changes nothing (Pro Tools).

  Self-contained: uses hsuanice_PT_Transport.lua (same folder).
  - Tags : Edit Tools, Zoom
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

local MARGIN = 0.04 -- of the selection length, each side

local s, e = T.edit_range()
if s then
  local m = (e - s) * MARGIN
  r.GetSet_ArrangeView2(0, true, 0, 0, s - m, e + m)
else
  local v0, v1 = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
  local half = (v1 - v0) / 2
  local c = r.GetCursorPosition()
  r.GetSet_ArrangeView2(0, true, 0, 0, c - half, c + half)
end
r.UpdateArrange()
r.defer(function() end) -- no undo point (zoom is not undoable in Pro Tools either)
