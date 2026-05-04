-- @description hsuanice_Pro Tools Trim Clips End To File End
-- @version 0.3.0 [260504.1620]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Trim Clip End to File End**
--   Extends the RIGHT edge of each selected item up to:
--     • the next neighbor's start on the same track, or
--     • the source media end if no neighbor exists.
--   Auto-unloops and clamps any item that was previously stretched past the
--   source by SWS "Trim to fill selection". Respects playrate and STARTOFFS.
--   - Tags: Editing
-- @changelog
--   0.3.0 [260504.1620] - Selection follows extend: razor (per track) and time selection
--                          now expand to encompass the items' new extents (right edge only).
--   0.2.0 [260504.1520] - Header standardized to PT2Reaper line-comment style;
--                          logic unchanged from v0.1.
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

local function normalize_loop_and_clamp(item, take)
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local take_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local source = reaper.GetMediaItemTake_Source(take)
  local src_len, isQN = reaper.GetMediaSourceLength(source)
  if isQN then return len, take_offset, playrate, src_len end

  local max_len_from_offset = math.max(0, (src_len - take_offset) / math.max(1e-12, playrate))

  local is_loop = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC")
  if is_loop == 1 or len > max_len_from_offset + 1e-9 then
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
    if len > max_len_from_offset then
      reaper.SetMediaItemInfo_Value(item, "D_LENGTH", max_len_from_offset)
      len = max_len_from_offset
    end
  end

  return len, take_offset, playrate, src_len
end

for i = 0, num_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local track = reaper.GetMediaItemTrack(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = pos + len
  local take = reaper.GetActiveTake(item)

  if not take or reaper.TakeIsMIDI(take) then goto continue end

  -- Normalize loop/length first
  len, take_offset, playrate, src_len = normalize_loop_and_clamp(item, take)
  pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  item_end = pos + len

  local max_total_len = src_len / math.max(1e-12, playrate)
  local available_tail = max_total_len - (take_offset / playrate + len)
  if available_tail < 0 then available_tail = 0 end

  -- Find next neighbor start on the same track
  local next_pos = math.huge
  local item_count = reaper.CountTrackMediaItems(track)
  for j = 0, item_count - 1 do
    local other = reaper.GetTrackMediaItem(track, j)
    if other ~= item then
      local other_pos = reaper.GetMediaItemInfo_Value(other, "D_POSITION")
      if other_pos >= item_end and other_pos < next_pos then
        next_pos = other_pos
      end
    end
  end

  local want_extend = (next_pos < math.huge) and (next_pos - item_end) or available_tail
  local actual_extend = math.min(want_extend, available_tail)
  if actual_extend > 0 then
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len + actual_extend)
  end

  ::continue::
end

if Trim and _sel_snap then Trim.expand_selection_to_items(_sel_snap) end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Trim Clips End To File End (auto-unloop & clamp first)", -1)

