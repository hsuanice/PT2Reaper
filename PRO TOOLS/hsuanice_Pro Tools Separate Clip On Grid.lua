--[[
@description hsuanice_Pro Tools Separate Clip On Grid
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Separate Clip On Grid**

  Splits each selected item at every grid line within its span, with an
  optional Pre-Separate Amount that reserves a fixed-width tail piece on
  each item.

  ## Behavior
  - Prompts for "Pre-Separate Amount" in milliseconds (0-99 ms).
  - **pre_ms = 0** → routes to native action 40932 "Item: Split items at
    timeline grid" (project-grid-aligned splits).
  - **pre_ms > 0** → item-end-anchored splits:
    - rightmost piece: exactly `pre_ms` wide
    - middle pieces: each one grid-value wide (tempo-aware via QN domain)
    - leftmost piece: whatever remains
  - Items not crossing any grid line (or too short for the pre-amount)
    are left untouched.

  - Tags: Editing, Clips
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local EPS = 1e-9

-- 1. Prompt for Pre-Separate Amount (ms) — remembers last value
local EXT_NS, EXT_KEY = "hsuanice_PT_SeparateClipOnGrid", "pre_ms"
local prev = r.GetExtState(EXT_NS, EXT_KEY)
if prev == "" then prev = "0" end

local rv, str = r.GetUserInputs("Pre-Separate Amount", 1,
  "Pre-separate amount (ms):,extrawidth=80", prev)
if not rv then return end
local pre_ms = tonumber(str)
if not pre_ms or pre_ms < 0 then pre_ms = 0 end
if pre_ms > 99 then pre_ms = 99 end
local pre_sec = pre_ms / 1000

r.SetExtState(EXT_NS, EXT_KEY, tostring(pre_ms), true)

-- 2. pre_ms == 0 -> native 40932 (project-grid-aligned splits)
if pre_ms == 0 then
  r.Main_OnCommand(40932, 0)
  return
end

-- 3. pre_ms > 0 -> custom item-end-anchored split

local sel = {}
for i = 0, r.CountSelectedMediaItems(0) - 1 do
  sel[#sel+1] = r.GetSelectedMediaItem(0, i)
end
if #sel == 0 then return end

-- Grid step in quarter notes (whole-note division * 4)
local _, division = r.GetSetProjectGrid(0, false)
if not division or division <= 0 then return end
local div_qn = division * 4

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for _, original in ipairs(sel) do
  local item     = original
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_fin = item_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")

  local last_anchor = item_fin - pre_sec

  if last_anchor > item_pos + EPS and last_anchor < item_fin - EPS then
    r.SplitMediaItem(item, last_anchor)
    -- After split: `item` (original handle) refers to the LEFT piece
    -- [item_pos, last_anchor]. Continue splitting the left piece going
    -- further leftward.
  end

  -- Walk leftward in the QN domain (tempo-aware).
  local cur_qn = r.TimeMap2_timeToQN(0, last_anchor)
  while true do
    local next_qn  = cur_qn - div_qn
    local next_pos = r.TimeMap2_QNToTime(0, next_qn)
    if next_pos <= item_pos + EPS then break end
    -- Split the leftmost remaining piece (which `item` now refers to).
    local left_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local left_fin = left_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
    if next_pos > left_pos + EPS and next_pos < left_fin - EPS then
      r.SplitMediaItem(item, next_pos)
    end
    cur_qn = next_qn
  end
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Separate Clip On Grid", -1)
