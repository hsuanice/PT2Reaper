--[[
@description hsuanice_Pro Tools Link Timeline and Edit Selection
@version 26.1118.0115pre1
@author hsuanice
@noindex
@changelog
  - About: the Time marker is named with its timecode.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Link Timeline and Edit Selection**
  (Shift + /).

  ## Behaviour
  - Toggles REAPER's "Loop points linked to time selection" (40621).
  - Mirrors the native toggle state onto this script's own toggle
    so other scripts can read our state via:
      reaper.GetToggleCommandStateEx(0, reaper.NamedCommandLookup("_<this script's RS hash>"))
  - Turned on: the Time marker (marker 9999, the Timeline position with Link off) is removed.

  ## Razor link (disabled)
  - Earlier 0.2.x / 0.3.0 builds added a defer watcher that also
    synced full-track razor zones to the loop range. Disabled per
    user request 2026-05-10 — the watcher is still in git history
    if needed again later.

  - Tags : Editing, Selection, Options, Link
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

-- Toggle the native REAPER action.
r.Main_OnCommand(40621, 0)

-- Mirror the native toggle state onto this script's own toggle
-- so other scripts can read our state via GetToggleCommandStateEx.
local native_state = r.GetToggleCommandStateEx(0, 40621)
local cmd_id = ({r.get_action_context()})[4]
r.SetToggleCommandState(0, cmd_id, native_state)
r.RefreshToolbar2(0, cmd_id)

-- Link on: the Timeline and Edit positions are the edit cursor again - the Time marker
-- (Link off only, see hsuanice_PT_Transport.lua) is removed. The Counters Panel does the
-- same when Link is turned on elsewhere.
if native_state == 1 then
  local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
  local ok, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
  if ok and type(T) == 'table' and T.clear_time_pos then T.clear_time_pos(); r.UpdateArrange() end
end
