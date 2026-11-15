--[[
@description hsuanice_Pro Tools Nudge Play Later By Grid
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Nudge Play Later By Grid**
  (PT key: Control+.; Commands Focus: Period)

  Pro Tools (stopped): moves the edit cursor later; selected clips move
  with it - the same as Nudge Clip Later By Grid (NumPad +).
  So this runs hsuanice_Pro Tools Nudge Clip Later By Grid.lua with
  the current Nudge value.
  Undo history shows "Pro Tools: Nudge Clip Later By Grid".

  - Tags : Editing, Transport
  Built with AI: written with Claude Code (Anthropic).
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local dir = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local target = dir .. 'hsuanice_Pro Tools Nudge Clip Later By Grid.lua'

local ok, err = pcall(dofile, target)
if not ok then
  r.ShowMessageBox('Could not run ' .. target .. '\n\n' .. tostring(err), 'Error', 0)
end
