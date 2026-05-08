-- @description hsuanice_Pro Tools Move Edit Insertion To Previous Edit
-- @version 0.2.0 [260508.1648]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Edit Insertion To Previous Edit** (Shift+Tab)
--
--   ## Behaviour
--   Reads the "Tab to Transient" toggle state:
--   - ON  → moves cursor to previous transient (filtered by shared
--     min-gap setting, see `Library/hsuanice_PT_Transient.lua` /
--     `hsuanice_PT_Transient/min_ms`). Transients within `min_ms` of
--     the starting cursor are skipped; if none far enough is found,
--     cursor stays put.
--   - OFF → moves cursor to previous item edge.
--
--   Saves and restores item selection so the user sees no change.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags : Editing, Navigation
--
-- @changelog
--   0.2.0 [260508.1648]
--     - Tab-to-Transient mode now applies the shared min-gap filter
--       from Library/hsuanice_PT_Transient.lua. Library is a hard dep.
--   0.1.0 [260418.1120]
--     - Initial release.

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Move Edit Insertion To Previous Edit", 0)
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

-- Select all items in track
r.Main_OnCommand(40421, 0)  -- Item: Select all items in track

-- Move cursor
if get_tab_toggle_state() then
  Tran.cursor_to_prev_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40318, 0)  -- Item navigation: Move cursor left to edge of item
end

-- Restore original item selection
r.Main_OnCommand(41239, 0)  -- Selection set: Load set #01

r.defer(function() end)  -- prevent undo
