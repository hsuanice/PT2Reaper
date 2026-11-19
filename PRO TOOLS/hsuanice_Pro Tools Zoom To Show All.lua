--[[
@description hsuanice_Pro Tools Zoom To Show All
@version 26.1119.1341pre1
@author hsuanice
@noindex
@changelog
  - Zooms horizontally so the whole session fits the arrange view.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Zoom To Show All**
  (PT key: Option+A)

  Zooms horizontally so the whole session (project start to the end of the last item /
  marker) fills the arrange view, with a small margin after the end (4 % of the length).
  Horizontal only: track heights are not changed (Pro Tools). Empty project: nothing.
  Horizontal Zoom to Show All (Command+Control+[, Option+Control+A) does the same.

  - Tags : Zoom
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local MARGIN = 0.04 -- of the session length, after the end

local len = r.GetProjectLength(0)
if len > 0 then
  r.GetSet_ArrangeView2(0, true, 0, 0, 0, len * (1 + MARGIN))
  r.UpdateArrange()
end
r.defer(function() end) -- no undo point (zoom is not undoable in Pro Tools either)
