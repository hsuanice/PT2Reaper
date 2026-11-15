--[[
@description hsuanice_Pro Tools Nudge Selection Earlier By Grid - Selection Start
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Nudge Selection Earlier By Grid [Selection Start]**
  (PT key: Opt+Shift+NumPad -)

  Nudges the Edit Selection earlier by the current Nudge value
  (hsuanice_Grid Nudge Panel). Items never move.
  Moves only the START of the Edit Selection (end stays).

  - Edit Selection = time selection + every razor area.
  - Start and end never cross; nothing goes below project start.
  - No selection: moves the edit cursor (edit insertion).
  - Edit cursor follows the selection start when Link Timeline and
    Edit Selection (40621) is on (hsuanice_PT_SelectionSync).

  - Tags : Selection
  Built with AI: written with Claude Code (Anthropic).
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local info = debug.getinfo(1, 'S')
local dir = info.source:match('^@(.*[/\\])') or ''
local ok, Nudge = pcall(dofile, dir .. 'hsuanice_PT_Nudge.lua')
if not ok or not Nudge.nudge_selection then
  r.ShowMessageBox('Could not load hsuanice_PT_Nudge.lua (0.5.0 or newer needed)', 'Error', 0)
  return
end
local _, Sync = pcall(dofile, dir .. 'hsuanice_PT_SelectionSync.lua')
if type(Sync) ~= 'table' then Sync = nil end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
local moved = Nudge.nudge_selection('start', true)
if moved and type(Sync) == 'table' and Sync.cursor_follow then Sync.cursor_follow() end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Nudge Selection Earlier By Grid [Selection Start]', -1)

-- Loop-link can reset the cursor after a time selection change; follow once more
if moved and type(Sync) == 'table' and Sync.cursor_follow then
  r.defer(function() Sync.cursor_follow() end)
end
