--[[
@description hsuanice_Pro Tools Save As
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Save As**
  (PT key: Cmd+Control+S - confirmed in Pro Tools by hsuanice)

  Thin wrapper over native 40022 (File: Save project as...).

  - Tags : Misc, File menu
  Built with AI: written with Claude Code (Anthropic).
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40022, 0)
