--[[
@description hsuanice_Pro Tools Decrease Grid Value
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Decreases grid to next smaller value within the current mode
  (Measure / Min:Secs / Timecode / Feet+Frames / Samples).
  Mode and current preset are read from the Grid Nudge Panel ExtState.
  Mac shortcut (PT): Shift + Minus
  Tags: Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local info = debug.getinfo(1, 'S')
local dir = info.source:match('^@(.*[/\\])') or ''
local ok, Grid = pcall(dofile, dir .. 'hsuanice_PT_Grid.lua')
if not ok or type(Grid) ~= 'table' then return end

Grid.decrease()
r.defer(function() end)
