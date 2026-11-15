--[[
@description hsuanice_Pro Tools Play Edit Selection
@version 26.1115.2045pre1
@author hsuanice
@noindex
@changelog
  - Rewritten: Pro Tools behaviour with Insertion Follows Playback and Link Timeline and Edit Selection; stops at the selection end (Play Watcher, no task control dialog).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Play Edit Selection**
  (PT key: Control+[, Option+[)

  Plays the Edit Selection (razor areas, else the time selection) and stops at its end.
  Insertion Follows Playback on: the edit cursor stays at the end and the Timeline Selection
  is cleared (the loop points; linked: the Edit Selection too); off: back to the selection
  start, selections kept. With Link Timeline and Edit Selection off the Edit Selection is
  never cleared.
  Pressed while playing: plays the selection again from its start.
  No selection: plays from the edit cursor (like Play).
  During a QuickPunch pass: ends the recording, then plays.

  Self-contained: uses hsuanice_PT_Transport.lua, hsuanice_PT_QuickPunch.lua and
  hsuanice_PT_Play Watcher.lua (same folder).
  - Tags : Transport, Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok1, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
local ok2, QP = pcall(dofile, DIR .. 'hsuanice_PT_QuickPunch.lua')
if not ok1 or type(T) ~= 'table' or not ok2 or type(QP) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua / hsuanice_PT_QuickPunch.lua\n\n'
    .. tostring(ok1 and '' or T) .. tostring(ok2 and '' or QP), 'Error', 0)
  return
end

T.reset_half_speed()
T.refresh_follows_button()

local s, e = T.edit_range()
if QP.pass_active() and T.is_running() then
  QP.stop(T.follows())
  if s then T.play_range(s, e, true) else T.play_range(r.GetCursorPosition(), 1e12, true) end
elseif s then
  T.play_range(s, e)
elseif not T.is_running() then
  T.play()
end
r.defer(function() end) -- no undo point
