--[[
@description hsuanice_Pro Tools Record Punch
@version 26.1118.1937pre1
@author hsuanice
@noindex
@changelog
  - Record with the Pro Tools rolls (QuickPunch on or off): pre-roll before the Time position / Timeline Selection, only the Timeline Selection is recorded, stops at its end + post-roll.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Record Punch**
  (PT key: F12, Cmd+Space, NumPad 3)

  Your Record key. From stop it uses the Pro Tools rolls (Counters Panel pre-roll /
  post-roll, Cmd+K), with QuickPunch on or off:
  - no Timeline Selection (loop points): plays from the Time position - pre-roll and
    records from the Time position until you stop;
  - Timeline Selection: plays from its start - pre-roll, records only the selection and
    stops at its end + post-roll. Insertion Follows Playback on: the Timeline position goes
    to the selection end and the selection is cleared; off: everything stays.
  REAPER's own pre-roll is not used for this (put back afterwards).
  QuickPunch off: REAPER's own Record; the new items are trimmed to the record range when it
  has stopped. Playing (QuickPunch off): Transport: Record.
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
elseif r.GetPlayState() == 0 then
  T.reset_half_speed()
  T.watch_clear()
  -- the Pro Tools rolls (Counters Panel, Cmd+K) and the Timeline Selection (record range)
  local plan = T.record_plan()
  local res = "none"
  if QP.mode_on() then
    -- from stop: punch in at once (with a Timeline Selection: that range punches instead)
    res = QP.start_pass(true, plan.base, { pre = plan.pre, range = plan.s and { plan.s, plan.e } or nil })
    if res == "started" then T.watch_record("qp", plan) end
  end
  if res == "none" then T.record_native() end
else
  r.Main_OnCommand(1013, 0) -- Transport: Record (playing: REAPER punches in)
end
r.defer(function() end) -- no "ReaScript: Run" undo point (the pass makes its own)
