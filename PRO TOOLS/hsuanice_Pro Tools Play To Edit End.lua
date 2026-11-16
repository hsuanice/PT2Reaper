--[[
@description hsuanice_Pro Tools Play To Edit End
@version 26.1116.2255
@author hsuanice
@noindex
@changelog
  - First working version (was a placeholder): Pro Tools behaviour with the Pre-roll / Post-roll lengths of the Counters Panel.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Play To Edit End**
  (PT key: Control+8)

  Plays from the Pre-roll length before the Edit Selection end up to the end.
  Edit Selection = razor areas, else the time selection; no selection: the edit cursor.
  Uses the Pre-roll / Post-roll lengths set in the Counters Panel, whether the rolls are on
  or off (as Pro Tools does). Stops by itself. The playhead (edit cursor) stays where it is;
  Insertion Follows Playback on: it ends at the stop position and the Timeline Selection
  (loop points) is cleared - with Link Timeline and Edit Selection on, the Edit Selection too.
  Pressed while playing: plays again. During a QuickPunch pass: ends the recording first.

  Self-contained: uses hsuanice_PT_Transport.lua, hsuanice_PT_QuickPunch.lua and
  hsuanice_PT_Play Watcher.lua (same folder).
  - Tags : Transport
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok1, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
if not ok1 or type(T) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua\n\n' .. tostring(T), 'Error', 0)
  return
end
local ok2, QP = pcall(dofile, DIR .. 'hsuanice_PT_QuickPunch.lua')
if not ok2 or type(QP) ~= 'table' then QP = nil end

T.play_around_edit("end", "to", QP)
r.defer(function() end) -- no undo point
