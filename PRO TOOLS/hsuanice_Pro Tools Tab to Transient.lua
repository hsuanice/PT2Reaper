--[[
@description hsuanice_Pro Tools Tab to Transient
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # hsuanice Pro Tools Keybindings for REAPER

  Replicates Pro Tools: **Tab to Transient** toggle

  When ON:  Tab moves to next transient (item edges + internal peaks)
  When OFF: Tab moves to next item edge only

  Other scripts read this toggle state via:
    reaper.NamedCommandLookup("_RS<this_script_hash>")
    reaper.GetToggleCommandStateEx(0, cmd_id)

  - Mac shortcut (PT) : Command + Option + Tab
  - Tags              : Editing, Options menu
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local cmd_id = ({r.get_action_context()})[4]
local state = r.GetToggleCommandStateEx(0, cmd_id)

if state ~= 1 then state = 1 else state = 0 end

r.SetToggleCommandState(0, cmd_id, state)
r.RefreshToolbar2(0, cmd_id)
r.defer(function() end)  -- keep script alive to maintain toggle state
