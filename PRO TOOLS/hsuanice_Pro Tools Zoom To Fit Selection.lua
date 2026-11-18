--[[
@description hsuanice_Pro Tools Zoom To Fit Selection
@version 26.1118.1327pre1
@author hsuanice
@noindex
@changelog
  - First version (was a placeholder): same as Zoom To Fit Horizontal Selection (Pro Tools).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Zoom To Fit Selection**
  (PT key: Option+F)

  In Pro Tools (tested by hsuanice 261118) it does exactly what Zoom To Fit Horizontal
  Selection does: Edit range -> fills the arrange view (small margins); no Edit range -> the
  Edit position is centered, zoom kept. Track heights are not changed; not a toggle.
  Runs hsuanice_Pro Tools Zoom To Fit Horizontal Selection.lua (same folder), so both stay
  the same.
  - Tags : Edit Tools, Zoom
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
dofile(DIR .. 'hsuanice_Pro Tools Zoom To Fit Horizontal Selection.lua')
