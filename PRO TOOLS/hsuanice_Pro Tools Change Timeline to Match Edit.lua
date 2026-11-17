--[[
@description hsuanice_Pro Tools Change Timeline to Match Edit
@version 26.1118.0102pre1
@author hsuanice
@noindex
@changelog
  - First version (was a placeholder): Pro Tools behaviour with loop points, razor areas and the Time marker.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Change Timeline to Match Edit**
  (PT key: Control+O (Commands Focus: O))

  Copies the Edit Selection (razor areas, else the time selection) to the Timeline Selection
  (loop points). No Edit range: the Timeline position goes to the Edit position - loop points
  cleared and, with Link Timeline and Edit Selection off, the Time marker put there.

  Self-contained: uses hsuanice_PT_MatchSelection.lua, hsuanice_PT_Transport.lua and
  hsuanice_PT_MouseSelect.lua (same folder).
  - Tags : Editing, Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, M = pcall(dofile, DIR .. 'hsuanice_PT_MatchSelection.lua')
if not ok or type(M) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_MatchSelection.lua\n\n' .. tostring(M), 'Error', 0)
  return
end
M.run(M.timeline_to_edit, nil, 'Change Timeline to Match Edit')
