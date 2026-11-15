--[[
@description hsuanice_Pro Tools Decrease Nudge Value
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Decreases nudge value to next preset in current mode. Stops at list boundary.
  Mac shortcut (PT): Option + Shift + -
  Tags: Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local info = debug.getinfo(1, 'S')
local dir = info.source:match('^@(.*[/\\])') or ''
local ok, Nudge = pcall(dofile, dir .. 'hsuanice_PT_Nudge.lua')
if not ok then return end

Nudge.decrease()
r.defer(function() end)
