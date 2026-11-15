--[[
@description hsuanice_Pro Tools Clear All Soloed Tracks
@version 26.1115.1531
@author hsuanice
@noindex
@changelog
  - First implementation (was a stub).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Clear All Soloed Tracks**
  (PT key: none)

  Unsolos every track (native 40340, Track: Unsolo all tracks).

  - Tags : Selection, Editing
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40340, 0)
