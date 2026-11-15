--[[
@description hsuanice_Pro Tools Mouse - Shift-Double-Click Extends Edit Selection Over Gap
@version 26.1115.1825pre1
@author hsuanice
@noindex
@changelog
  - First version.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Shift-double-click on empty track space adds the gap to the Edit Selection** (mouse)

  Like the double-click (the space between the clips on the clicked track), but the current
  Edit Selection is extended to cover the gap instead of being replaced, and the clicked track
  is added. The edit cursor does not move.

  Setup: Preferences > Mouse Modifiers > Track > Double click > Shift: this action.

  - Tags : Selection, Mouse
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, MS = pcall(dofile, DIR .. 'hsuanice_PT_MouseSelect.lua')
if not ok or type(MS) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_MouseSelect.lua\n\n' .. tostring(MS), 'Error', 0)
  return
end

local tr = MS.mouse_track()
if not tr then return r.defer(function() end) end
local g0, g1 = MS.gap_at(tr, MS.mouse_time(false))
if not g0 then return r.defer(function() end) end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
MS.extend(g0, g1, tr)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Shift-double-click extends Edit Selection over gap", -1)
