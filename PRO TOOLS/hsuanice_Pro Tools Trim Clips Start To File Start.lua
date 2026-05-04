-- @description hsuanice_Pro Tools Trim Clips Start To File Start
-- @version 0.3.0 [260504.1620]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Trim Clip Start to File Start**
--   Extends the LEFT edge of each selected item up to:
--     • the previous neighbor's end on the same track, or
--     • the source media start if no neighbor exists.
--   Prevents revealing beyond recorded source content.
--   Collapses a left-side blank loop (created by SWS "Trim to fill selection")
--   in a content-preserving way: push start right by overshoot, shorten length,
--   zero D_STARTOFFS. Right side untouched.
--   - Tags: Editing
-- @changelog
--   0.3.0 [260504.1620] - Selection follows extend: razor (per track) and time selection
--                          now expand to encompass the items' new extents (left edge only).
--   0.2.0 [260504.1520] - Header standardized to PT2Reaper line-comment style;
--                          logic unchanged from v0.1.1.
--   0.1.1               - Fix: collapse LEFT blank loop without shifting perceived content earlier:
--                            • If D_STARTOFFS < 0, move item start right by overshoot, shorten length
--                              by overshoot, and set D_STARTOFFS = 0 (mirrors Boundaries behavior).
--                              Right side untouched.
--                            • Preserve normal left-edge reveal in non-loop cases (can extend to true file start).
--   0.1                 - Beta release


-- Load PT_Trim library (for snapshot_selection / expand_selection_to_items)
local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local _ok, Trim = pcall(dofile, _dir .. '../Library/hsuanice_PT_Trim.lua')
if not _ok then Trim = nil end

reaper.Undo_BeginBlock()

local num_items = reaper.CountSelectedMediaItems(0)
if num_items == 0 then return end

local _sel_snap = Trim and Trim.snapshot_selection() or nil

-- Normalize ONLY the left blank-loop case in a content-preserving way:
-- If D_STARTOFFS < 0, push start RIGHT by the overshoot, shorten length by the same amount,
-- and zero the offset. Do NOT touch right-side behavior.
-- Returns: len, take_offset, playrate, src_len, left_fixed (boolean)
local function normalize_left_blank_loop_preserve_content(item, take)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

  local source = reaper.GetMediaItemTake_Source(take)
  local src_len, isQN = reaper.GetMediaSourceLength(source)
  if isQN then
    return len, take_offset, playrate, src_len, false
  end

  local safe_rate = math.max(1e-12, playrate)
  local left_fixed = false

  if take_offset < 0 then
    -- Amount exceeded before true file start (seconds at project rate)
    local overshoot = (-take_offset) / safe_rate
    local new_pos   = pos + overshoot
    local new_len   = math.max(0, len - overshoot)

    -- Content-preserving collapse: push start right, shorten length, zero offset
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH",   new_len)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)

    -- Update locals
    pos = new_pos
    len = new_len
    take_offset = 0
    left_fixed = true
  end

  return len, take_offset, playrate, src_len, left_fixed
end

for i = 0, num_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local track = reaper.GetMediaItemTrack(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = pos + len
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then goto continue end

  -- Step 1: collapse left blank loop (if any) in a content-preserving way
  local take_offset, playrate, src_len, left_fixed
  len, take_offset, playrate, src_len, left_fixed = normalize_left_blank_loop_preserve_content(item, take)

  -- Refresh geometry after normalization
  pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  item_end = pos + len

  -- If we just collapsed a left blank loop, stop here to avoid additional reveal in this pass.
  if left_fixed then
    goto continue
  end

  -- Step 2: normal left-edge reveal (original behavior)
  local safe_rate = math.max(1e-12, playrate)
  local max_reveal = (take_offset / safe_rate) -- seconds of headroom to the true file start

  -- Find the end of the previous neighbor on the same track
  local prev_edge = 0
  local item_count = reaper.CountTrackMediaItems(track)
  for j = 0, item_count - 1 do
    local other = reaper.GetTrackMediaItem(track, j)
    if other ~= item then
      local other_pos = reaper.GetMediaItemInfo_Value(other, "D_POSITION")
      local other_len = reaper.GetMediaItemInfo_Value(other, "D_LENGTH")
      local other_end = other_pos + other_len
      if other_end <= pos and other_end > prev_edge then
        prev_edge = other_end
      end
    end
  end

  local want_reveal = pos - prev_edge
  local actual_reveal = math.min(want_reveal, math.max(0, max_reveal))

  if actual_reveal > 0 then
    local new_pos = pos - actual_reveal
    local new_len = item_end - new_pos
    local new_offset = take_offset - (actual_reveal * safe_rate)

    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", new_offset)
  end

  ::continue::
end

if Trim and _sel_snap then Trim.expand_selection_to_items(_sel_snap) end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Extend item left edge to previous item or source start", -1)
