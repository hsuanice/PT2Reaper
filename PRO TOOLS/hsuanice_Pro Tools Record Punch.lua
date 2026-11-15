--[[
@description hsuanice_Pro Tools Record Punch
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Record Punch**
  (PT key: F12, Cmd+Space, NumPad 3)

  Your Record key. QuickPunch off: Transport: Record - nothing changes.
  During a QuickPunch pass: first press = punch in, next press = punch out
  (stopping also punches out). Several punches per pass are fine. Monitoring
  switches with the punch: playback before it; inside it the input, with the
  track's items muted. QuickPunch on, stopped: starts a pass and punches in at once.

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

local _, _, _, cmd = r.get_action_context()
QP.set("cmd_punch", cmd)
QP.disarm_buffers()

if QP.pass_active() and (r.GetPlayState() & 4) == 4 then
  QP.punch_toggle() -- (also lights the button)
elseif QP.mode_on() and r.GetPlayState() == 0 then
  T.reset_half_speed()
  -- from stop: punch in at once (with an auto-punch range: the range punches instead)
  local res = QP.start_pass(true, T.start_position())
  if res == "none" then r.Main_OnCommand(1013, 0) end
else
  r.Main_OnCommand(1013, 0) -- Transport: Record
end
r.defer(function() end) -- no "ReaScript: Run" undo point (the pass makes its own)
