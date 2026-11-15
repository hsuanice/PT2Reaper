--[[
@description hsuanice_Pro Tools QuickPunch
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **QuickPunch**
  (PT key: NumPad 6, Cmd+Shift+P)

  Toggle. On: Play/Stop and Record Punch work as a Pro Tools style QuickPunch.
  Off: they are a normal Play / Stop and Transport: Record. REAPER always starts
  with the mode off. Put it on a toolbar: the button is lit while the mode is on.
  QuickPunch is also on, without this toggle, while REAPER's record mode is time
  selection auto-punch or selected item auto-punch (those ranges punch automatically);
  switching it off then also sets the record mode back to normal.

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
QP.set("cmd_toggle", cmd)
if QP.mode_on() then
  -- Off must really be off: an auto-punch record mode (time selection / selected items)
  -- also counts as QuickPunch on, so go back to the normal record mode too.
  QP.set_mode(false)
  if QP.mode_on() then r.Main_OnCommand(40252, 0) end -- Record: Set record mode to normal
else
  QP.set_mode(true)
end
r.defer(function() end) -- no "ReaScript: Run" undo point
