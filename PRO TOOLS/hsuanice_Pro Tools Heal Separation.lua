--[[
@description hsuanice_Pro Tools Heal Separation
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # hsuanice Pro Tools Keybindings for REAPER

  Wrapper replicating Pro Tools: **Heal Separation**

  ## Mapping
  - Pro Tools equivalent : Heal Separation
  - Reaper action        : Item: Heal splits in items
  - Command ID           : 40548
  - Mac shortcut (PT)    : Command + H
  - Tags                 : Edit menu, Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40548, 0)
