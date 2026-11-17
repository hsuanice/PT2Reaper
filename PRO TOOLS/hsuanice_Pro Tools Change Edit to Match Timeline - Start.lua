--[[
@description hsuanice_Pro Tools Change Edit to Match Timeline - Start
@version 26.1118.0114
@author hsuanice
@noindex
@changelog
  - Release: Pro Tools behaviour with loop points, razor areas and the Time marker; Start / End move only that edge (tested in REAPER and Pro Tools).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Change Edit to Match Timeline (Start)**
  (PT key: Option+Control+Shift+0)

  Moves the Edit Selection start to the Timeline Selection start; the Edit end stays. No Edit
  range (only a position): like Change Edit to Match Timeline.

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
M.run(M.edit_to_timeline, "start", 'Change Edit to Match Timeline (Start)')
