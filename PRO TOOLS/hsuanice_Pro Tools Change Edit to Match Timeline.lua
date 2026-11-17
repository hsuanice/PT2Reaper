--[[
@description hsuanice_Pro Tools Change Edit to Match Timeline
@version 26.1118.0114
@author hsuanice
@noindex
@changelog
  - Release: Pro Tools behaviour with loop points, razor areas and the Time marker; Start / End move only that edge (tested in REAPER and Pro Tools).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Change Edit to Match Timeline**
  (PT key: Control+0 (Commands Focus: 0))

  Copies the Timeline Selection (loop points) to the Edit Selection: razor areas on the Edit
  Selection's tracks (else the selected tracks; none: the time selection only). No loop points:
  the Edit position (edit cursor) goes to the Timeline position (Time marker / edit cursor) and
  the Edit range is cleared.

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
M.run(M.edit_to_timeline, nil, 'Change Edit to Match Timeline')
