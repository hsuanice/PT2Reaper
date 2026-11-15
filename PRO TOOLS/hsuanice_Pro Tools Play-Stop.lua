--[[
@description hsuanice_Pro Tools Play/Stop
@version 26.1115.2128
@author hsuanice
@noindex
@changelog
  - Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Play/Stop**
  (PT key: Space, NumPad 0)

  Stopped: plays the Timeline Selection (the loop points) and stops at its end; with no
  Timeline Selection, plays from the edit cursor.
  With QuickPunch on (QuickPunch toggle, or an auto-punch record mode) and
  record-armed tracks, the play is a QuickPunch pass instead (background recording,
  punch with Record Punch or automatically at the time selection / selected items).
  Playing: stops. Insertion Follows Playback on: the edit cursor stays where playback
  stopped and the Timeline Selection (loop points) is cleared (Link Timeline and Edit
  Selection on: the Edit Selection too - razor areas, time selection); off: back
  to where playback started, selections kept. Stopping also ends a half speed play.
  Credits: behaviour modelled on TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts):
  TJF playback that reads insertion toggle, TJF Toggle Insertion follows Playback,
  TJF Playback at Half Speed once.

  Self-contained: uses hsuanice_PT_Transport.lua and hsuanice_PT_QuickPunch.lua
  (same folder), copies of the Beta Testing/QuickPunch scripts (26.1114).
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok1, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
local ok2, QP = pcall(dofile, DIR .. 'hsuanice_PT_QuickPunch.lua')
if not (ok1 and ok2) then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua / hsuanice_PT_QuickPunch.lua\n\n'
    .. tostring(ok1 and '' or T) .. tostring(ok2 and '' or QP), 'Error', 0)
  return
end

T.reset_half_speed()
T.refresh_follows_button()
QP.disarm_buffers()

if T.is_running() then
  T.watch_clear()
  T.before_stop()
  if QP.pass_active() then QP.stop(T.follows()) else r.Main_OnCommand(1016, 0) end
  if T.follows() then T.clear_timeline() end -- Pro Tools: N on clears the Timeline Selection
elseif QP.mode_on() then
  if QP.start_pass(false, T.start_position()) == "none" then T.play() end
else
  local s, e = T.timeline_range()
  if s then T.play_range(s, e) else T.play() end
end
r.defer(function() end) -- no "ReaScript: Run" undo point (the pass makes its own)
