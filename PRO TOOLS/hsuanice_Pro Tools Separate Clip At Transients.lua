-- @description hsuanice_Pro Tools Separate Clip At Transients
-- @version 0.5.0 [260508.1643]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Separate Clip At Transients**
--
--   Detects transients in selected items and splits each item at
--   `transient - pre_ms` for every detected transient.
--
--   ## Behavior
--   - Prompts for two values (single dialog):
--     - "Pre-separate amount (ms)" : 0-99 (per-script, remembered)
--     - "Minimum clip length (ms)" : 0-999 (transient-to-transient
--       minimum spacing; transients closer than this to the previous
--       kept transient are dropped before splitting)
--   - The min-length value is the SHARED Pro Tools transient setting
--     (namespace `hsuanice_PT_Transient`, key `min_ms`). Changing it
--     here also affects Tab-to-Transient navigation and any other
--     consumers of the shared library.
--   - **pre_ms = 0** → split exactly at each (kept) transient.
--   - **pre_ms > 0** → split at `transient - pre_ms` (pre-roll before
--     each transient, matching Pro Tools).
--   - Transient detection sensitivity follows REAPER's global settings
--     (Options → Media → Transient detection). The Min-clip-length
--     filter is the primary tool for cleaning up over-detection.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags: Editing, Clips
-- @changelog
--   0.5.0 [260508.1643] - Refactor onto Library/hsuanice_PT_Transient.lua.
--                          min_ms now reads/writes the shared namespace
--                          `hsuanice_PT_Transient/min_ms` so Tab navigation
--                          + any future consumers share one tuning value.
--                          pre_ms stays in `hsuanice_PT_SeparateClipAtTransients`
--                          (per-script). Transient enumeration + min-gap
--                          filter delegated to the library.
--   0.4.1 [260508.1622] - Set DEBUG = false (verified working). No
--                          behavior change.
--   0.4.0 [260508.1611] - Add Min-clip-length filter (0-999 ms,
--                          transient-to-transient distance). Single
--                          dialog now has two fields: pre-amount + min
--                          length. Both persist via ExtState (keys
--                          "pre_ms" and "min_ms"). Transients walking
--                          forward via 40375 are filtered ascending so
--                          neighbours within `min_ms` of the previous
--                          kept transient are dropped before splitting.
--   0.3.3 [260508.1541] - Fix: action IDs were swapped. 40375 is the
--                          forward "next transient" action; 40376 is the
--                          reverse "previous transient" action. Switched
--                          to 40375 for forward walking. Removed probe
--                          diagnostic. DEBUG kept on for one round.
--   0.3.2 [260508.1536] - Diagnostic build. Probes which action ID actually
--                          advances the cursor on the user's REAPER (since
--                          40376 came back inert). Prints action names via
--                          kbd_getTextFromCmd for several candidate IDs and
--                          measures cursor delta after each Main_OnCommand
--                          on the first selected item.
--   0.3.1 [260508.1533] - Debug build. Removed PreventUIRefresh wrapper
--                          (suspected of suppressing cursor/40376 action).
--                          Added console-log diagnostic for each item:
--                          enumerated transient count + split positions.
--                          Set DEBUG=false at the top of the script to
--                          silence once verified working.
--   0.3.0 [260508.1448] - Pure-native rewrite. Adds Pre-Separate Amount
--                          dialog (0-99 ms, remembers last value via
--                          ExtState namespace
--                          "hsuanice_PT_SeparateClipAtTransients").
--                          Enumerates transients via native action 40376
--                          (per-item solo-select), splits at
--                          (transient - pre_sec). No SWS dependency. Edit
--                          cursor + original item selection restored after
--                          run; new right-side pieces also selected.
--   0.2.0 [260508.1319] - First implementation. Wraps SWS Xenakios command
--                          `_XENAKIOS_SPLIT_ITEMSATRANSIENTS`.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r   = reaper
local EPS = 1e-9

-- Load Library/hsuanice_PT_Transient.lua
local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Separate Clip At Transients", 0)
  return
end

-- 1. Two-field dialog
local PRE_NS = "hsuanice_PT_SeparateClipAtTransients"
local prev_pre = r.GetExtState(PRE_NS, "pre_ms")
if prev_pre == "" then prev_pre = "0" end
local prev_min = tostring(Tran.get_min_ms())  -- shared value

local rv, csv = r.GetUserInputs("Separate Clip At Transients", 2,
  "Pre-separate amount (ms):,Minimum clip length (ms):,extrawidth=80",
  prev_pre .. "," .. prev_min)
if not rv then return end

local pre_str, min_str = csv:match("([^,]*),([^,]*)")
local pre_ms = tonumber(pre_str) or 0
local min_ms = tonumber(min_str) or 0
if pre_ms < 0   then pre_ms = 0   end
if pre_ms > 99  then pre_ms = 99  end
if min_ms < 0   then min_ms = 0   end
if min_ms > 999 then min_ms = 999 end
local pre_sec = pre_ms / 1000
local min_sec = min_ms / 1000

r.SetExtState(PRE_NS, "pre_ms", tostring(math.floor(pre_ms + 0.5)), true)
Tran.set_min_ms(min_ms)  -- writes shared namespace

-- 2. Snapshot current selection + cursor
local sel_items = {}
for i = 0, r.CountSelectedMediaItems(0) - 1 do
  sel_items[#sel_items+1] = r.GetSelectedMediaItem(0, i)
end
if #sel_items == 0 then return end

local orig_cursor = r.GetCursorPosition()

r.Undo_BeginBlock()

local new_pieces = {}

for _, item in ipairs(sel_items) do
  if r.ValidatePtr(item, "MediaItem*") then
    local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")

    -- Library: enumerate raw transients (saves/restores cursor + sel)
    local raw  = Tran.enumerate_transients(item)
    -- Library: filter by min-gap (transients[] ascending)
    local kept = Tran.filter_min_gap(raw, min_sec)

    -- Sort descending so we can keep splitting the LEFT piece
    table.sort(kept, function(a, b) return a > b end)

    for _, T in ipairs(kept) do
      local split_pos = T - pre_sec
      if split_pos > pos + EPS and split_pos < fin - EPS then
        local left_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local left_fin = left_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
        if split_pos > left_pos + EPS and split_pos < left_fin - EPS then
          local right = r.SplitMediaItem(item, split_pos)
          if right then new_pieces[#new_pieces+1] = right end
        end
      end
    end
  end
end

-- 3. Restore cursor + select originals + all new right-side pieces
r.SelectAllMediaItems(0, false)
for _, it in ipairs(sel_items) do
  if r.ValidatePtr(it, "MediaItem*") then
    r.SetMediaItemSelected(it, true)
  end
end
for _, it in ipairs(new_pieces) do
  if r.ValidatePtr(it, "MediaItem*") then
    r.SetMediaItemSelected(it, true)
  end
end

r.SetEditCurPos(orig_cursor, false, false)

r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Separate Clip At Transients", -1)
