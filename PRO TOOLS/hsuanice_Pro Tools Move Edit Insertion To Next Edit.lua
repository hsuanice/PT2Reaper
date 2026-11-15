--[[
@description hsuanice_Pro Tools Move Edit Insertion To Next Edit
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion To Next Edit** (Tab key)

  ## Behaviour
  Reads the "Tab to Transient" toggle state:
  - ON  → moves cursor to next transient (filtered by shared min-gap
    setting, see `Library/hsuanice_PT_Transient.lua` /
    `hsuanice_PT_Transient/min_ms`). Transients within `min_ms` of the
    starting cursor are skipped; if none far enough is found, cursor
    stays put.
  - OFF → moves cursor to next item edge.

  Saves and restores item selection so the user sees no change.

  ## Dependency
  - `Library/hsuanice_PT_Transient.lua`

  - Tags : Editing, Navigation
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

-- Load Library/hsuanice_PT_Transient.lua
local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. 'hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load hsuanice_PT_Transient.lua",
    "Move Edit Insertion To Next Edit", 0)
  return
end

local function get_tab_toggle_state()
  local section = r.SectionFromUniqueID(0)
  local idx = 0
  while true do
    local cid, cname = r.kbd_enumerateActions(section, idx)
    if cid == 0 and idx > 0 then break end
    if cname and cname:lower():find("pro tools tab to transient", 1, true) then
      return r.GetToggleCommandStateEx(0, cid) == 1
    end
    idx = idx + 1
    if idx > 200000 then break end
  end
  return false
end

-- Save current item selection
r.Main_OnCommand(41229, 0)  -- Selection set: Save set #01

-- Select all items in track (so navigation works regardless of selection)
r.Main_OnCommand(40421, 0)  -- Item: Select all items in track

-- Move cursor
if get_tab_toggle_state() then
  Tran.cursor_to_next_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40319, 0)  -- Item navigation: Move cursor right to edge of item
end

-- Restore original item selection
r.Main_OnCommand(41239, 0)  -- Selection set: Load set #01

r.defer(function() end)  -- prevent undo
