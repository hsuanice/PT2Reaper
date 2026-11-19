--[[
@description hsuanice_Pro Tools Horizontal Zoom to Show All
@version 26.1119.1341pre1
@author hsuanice
@noindex
@changelog
  - Same as Zoom To Show All (horizontal only, as Pro Tools).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Horizontal Zoom to Show All**
  (PT keys: Command+Control+[, Option+Control+A)

  The same as Zoom To Show All (in Pro Tools both zoom horizontally only): the whole
  session fills the arrange view; track heights are not changed.

  Self-contained: runs hsuanice_Pro Tools Zoom To Show All.lua (same folder).
  - Tags : Zoom
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
dofile(DIR .. 'hsuanice_Pro Tools Zoom To Show All.lua')
