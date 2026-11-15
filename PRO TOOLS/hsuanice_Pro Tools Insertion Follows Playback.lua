--[[
@description hsuanice_Pro Tools Insertion Follows Playback
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Insertion Follows Playback**
  (PT key: N (Commands Focus), Control+N)

  Toggle. On: when Play/Stop or Play Half Speed stops, the edit cursor stays
  where playback stopped. Off: it stays where playback started.
  The setting is saved; the toolbar button is lit while it is on.

  Self-contained: uses hsuanice_PT_Transport.lua (same folder), a copy of the
  Main keymap's hsuanice_Transport scripts without QuickPunch.
  Credits: behaviour modelled on TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts):
  TJF playback that reads insertion toggle, TJF Toggle Insertion follows Playback,
  TJF Playback at Half Speed once.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
if not ok then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua', 'Error', 0)
  return
end

local _, _, _, cmd = r.get_action_context()
r.SetExtState(T.NS, 'cmd_follows', tostring(cmd), true)
T.set_follows(not T.follows())
r.defer(function() end) -- no undo point
