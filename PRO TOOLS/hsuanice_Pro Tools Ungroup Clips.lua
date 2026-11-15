--[[
@description hsuanice_Pro Tools Ungroup Clips
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Ungroup Clips** (Cmd+Opt+U) — removes selected
  items from their group. Thin wrapper over native action 40033 "Item
  grouping: Remove items from group".
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40033, 0)  -- Item grouping: Remove items from group
