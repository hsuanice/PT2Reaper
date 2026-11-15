--[[
@description hsuanice_Pro Tools Link Timeline and Edit Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Link Timeline and Edit Selection**
  (Shift + /).

  ## Behaviour
  - Toggles REAPER's "Loop points linked to time selection" (40621).
  - Mirrors the native toggle state onto this script's own toggle
    so other scripts can read our state via:
      reaper.GetToggleCommandStateEx(0, reaper.NamedCommandLookup("_<this script's RS hash>"))

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
