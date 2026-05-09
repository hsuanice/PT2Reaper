-- @description hsuanice_Pro Tools Move Edit Selection To Next Clip
-- @version 0.2.0 [260509.1036]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Edit Selection To Next Clip**
--   (Cmd+Ctrl+' / Ctrl+Tab)
--
--   Same logic as Move Edit Insertion To Next Edit:
--   - Tab to Transient ON  → moves cursor to next transient (filtered
--     by shared min-gap setting in Library/hsuanice_PT_Transient.lua).
--   - Tab to Transient OFF → moves cursor to next item edge.
--
--   Saves and restores item selection so the user sees no change.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags : Editing, Navigation, Selection
--
-- @changelog
--   0.2.0 [260509.1036] - First implementation. Mirrors Move Edit
--                          Insertion To Next Edit v0.2.0 — same Tab to
--                          Transient + min-gap behaviour.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Move Edit Selection To Next Clip", 0)
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

r.Main_OnCommand(41229, 0)  -- Selection set: Save set #01
r.Main_OnCommand(40421, 0)  -- Item: Select all items in track

if get_tab_toggle_state() then
  Tran.cursor_to_next_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40319, 0)  -- Item navigation: Move cursor right to edge of item
end

r.Main_OnCommand(41239, 0)  -- Selection set: Load set #01

r.defer(function() end)
