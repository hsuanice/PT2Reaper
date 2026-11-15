--[[
@description hsuanice_PT_Transient — Pro Tools-style transient helpers
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared library for Pro Tools "Separate Clip At Transients", "Tab to
  Transient" navigation, and any other script that needs REAPER's
  transient detection plus a minimum-gap filter.

  Transient detection is REAPER native (no SWS dependency): uses
  action 40375 "Item navigation: Move cursor to next transient in
  items". Sensitivity follows REAPER's global Options → Media →
  Transient detection settings.

  ## Shared min-gap setting
  All consumers read/write a single minimum-gap value (in milliseconds)
  via ExtState namespace `hsuanice_PT_Transient`, key `min_ms`.
  Range 0-999. 0 = no filter.

  ## API
  - get_min_ms() / set_min_ms(v) / get_min_sec()
  - enumerate_transients(item)        → ascending list of times
  - filter_min_gap(list, min_sec)     → drops entries within min_sec
                                         of the previously kept entry
  - cursor_to_next_transient(min_sec) → walks cursor forward via 40375,
                                         skipping transients within
                                         min_sec of original cursor;
                                         restores cursor if none found
  - cursor_to_prev_transient(min_sec) → mirror, via 40376
--]]

local r   = reaper
local EPS = 1e-9
local T   = {}

T.EXT_NS    = "hsuanice_PT_Transient"
T.MIN_MS_KEY = "min_ms"

function T.get_min_ms()
  local s = r.GetExtState(T.EXT_NS, T.MIN_MS_KEY)
  local n = tonumber(s) or 0
  if n < 0 then n = 0 end
  if n > 999 then n = 999 end
  return n
end

function T.set_min_ms(v)
  v = tonumber(v) or 0
  if v < 0 then v = 0 end
  if v > 999 then v = 999 end
  r.SetExtState(T.EXT_NS, T.MIN_MS_KEY, tostring(math.floor(v + 0.5)), true)
end

function T.get_min_sec()
  return T.get_min_ms() / 1000
end

-- Enumerate transient times inside an item via native action 40375.
-- Saves and restores cursor + item selection. Returns ascending list
-- of times (raw, unfiltered). Returns {} if item is invalid.
function T.enumerate_transients(item)
  if not item or not r.ValidatePtr(item, "MediaItem*") then return {} end
  local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local fin = pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- Save selection + cursor
  local saved_cursor = r.GetCursorPosition()
  local saved_sel = {}
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    saved_sel[#saved_sel+1] = r.GetSelectedMediaItem(0, i)
  end

  -- Solo-select target item, set cursor to its start
  r.SelectAllMediaItems(0, false)
  r.SetMediaItemSelected(item, true)
  r.SetEditCurPos(pos, false, false)

  local out = {}
  local guard = 0
  while true do
    guard = guard + 1
    if guard > 10000 then break end
    local before = r.GetCursorPosition()
    r.Main_OnCommand(40375, 0)  -- next transient in items
    local after = r.GetCursorPosition()
    if after <= before + EPS then break end
    if after >= fin    - EPS   then break end
    if after >  pos    + EPS then out[#out+1] = after end
  end

  -- Restore selection + cursor
  r.SelectAllMediaItems(0, false)
  for _, it in ipairs(saved_sel) do
    if r.ValidatePtr(it, "MediaItem*") then
      r.SetMediaItemSelected(it, true)
    end
  end
  r.SetEditCurPos(saved_cursor, false, false)

  return out
end

-- Apply min-gap filter to an ASCENDING list. Drops entries that are
-- within `min_sec` of the previously kept entry. Returns a new table.
function T.filter_min_gap(list, min_sec)
  if not list then return {} end
  if not min_sec or min_sec <= 0 then
    local copy = {}
    for i, v in ipairs(list) do copy[i] = v end
    return copy
  end
  local kept = {}
  local last
  for _, v in ipairs(list) do
    if not last or (v - last) >= min_sec - EPS then
      kept[#kept+1] = v
      last = v
    end
  end
  return kept
end

-- Walk cursor forward to the next transient that is at least `min_sec`
-- away from the cursor's starting position. Uses native action 40375
-- repeatedly. If no qualifying transient is found, the cursor is
-- restored to its starting position (so a Tab keystroke is a no-op
-- rather than landing on a too-close transient).
--
-- Caller is responsible for setting up item selection (e.g. 40421
-- Select all items in track) before calling, and restoring after.
function T.cursor_to_next_transient(min_sec)
  local c0 = r.GetCursorPosition()
  if not min_sec or min_sec <= 0 then
    r.Main_OnCommand(40375, 0)
    return r.GetCursorPosition()
  end
  local prev   = c0
  local found  = false
  local guard  = 0
  while true do
    guard = guard + 1
    if guard > 10000 then break end
    r.Main_OnCommand(40375, 0)
    local cur = r.GetCursorPosition()
    if cur <= prev + EPS then break end                          -- no advance
    if (cur - c0) >= min_sec - EPS then found = true; break end
    prev = cur
  end
  if not found then r.SetEditCurPos(c0, false, false) end
  return r.GetCursorPosition()
end

-- Walk cursor backward to the previous transient that is at least
-- `min_sec` away from the cursor's starting position. Mirror of
-- cursor_to_next_transient.
function T.cursor_to_prev_transient(min_sec)
  local c0 = r.GetCursorPosition()
  if not min_sec or min_sec <= 0 then
    r.Main_OnCommand(40376, 0)
    return r.GetCursorPosition()
  end
  local prev   = c0
  local found  = false
  local guard  = 0
  while true do
    guard = guard + 1
    if guard > 10000 then break end
    r.Main_OnCommand(40376, 0)
    local cur = r.GetCursorPosition()
    if cur >= prev - EPS then break end
    if (c0 - cur) >= min_sec - EPS then found = true; break end
    prev = cur
  end
  if not found then r.SetEditCurPos(c0, false, false) end
  return r.GetCursorPosition()
end

return T
