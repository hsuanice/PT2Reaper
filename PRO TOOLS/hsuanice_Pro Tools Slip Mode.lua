--[[
@description hsuanice_Pro Tools Slip Mode
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # hsuanice Pro Tools Keybindings for REAPER

  Wrapper replicating Pro Tools: **Slip Mode**

  ## Mapping
  - Pro Tools equivalent : Slip Mode
  - Reaper action        : Snapping: Disable snap
  - Command ID           : 40753
  - Mac shortcut (PT)    : F2
  - Tags                 : Edit Tools, Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40753, 0)
