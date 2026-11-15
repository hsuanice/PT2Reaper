--[[
@description hsuanice_Pro Tools Redo
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # hsuanice Pro Tools Keybindings for REAPER

  Wrapper replicating Pro Tools: **Redo**

  ## Mapping
  - Pro Tools equivalent : Redo
  - Reaper action        : Edit: Redo
  - Command ID           : 40030
  - Mac shortcut (PT)    : Control + Shift + Z
  - Tags                 : Edit menu, Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40030, 0)
