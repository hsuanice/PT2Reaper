-- @description hsuanice_Pro Tools Trim Clip To Fill Selection
-- @version 0.2.0 [260504.1520]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Trim Clip To Fill Selection**
--   EXTEND ONLY — equivalent to running both Trim Clip Start to Fill Selection
--   and Trim Clip End to Fill Selection in one action.
--   For each selected item:
--     • If razor (or TS) starts before the item's pos, extend the LEFT edge.
--     • If razor (or TS) ends after the item's end, extend the RIGHT edge.
--     • Sides whose selection edge is inside the item are not trimmed.
--   Fade lengths preserved on both sides (fade boundaries follow the edges).
--   Source-bound clamp: extends stop at source start / end (no warning).
--   - Tags: Editing
-- @changelog
--   0.2.0 [260504.1520] - Implemented via hsuanice_PT_Trim library (mode="length"
--                          on both sides). Razor on item's track preferred,
--                          falls back to TS.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper
local info = debug.getinfo(1, 'S')
local dir  = info.source:match('^@(.*[/\\])') or ''
local ok, Trim = pcall(dofile, dir .. '../Library/hsuanice_PT_Trim.lua')
if not ok or type(Trim) ~= "table" then
  r.ShowMessageBox('Could not load hsuanice_PT_Trim.lua', 'Error', 0)
  return
end

local n = r.CountSelectedMediaItems(0)
if n == 0 then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
for i = 0, n - 1 do
  local item = r.GetSelectedMediaItem(0, i)
  local sel_s, sel_e = Trim.get_selection_for_item(item)
  if sel_s and sel_e then
    local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local en  = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    -- Extend right first so left-side STARTOFFS shift doesn't affect it
    if sel_e > en then
      Trim.trim_right(item, sel_e, "length")
    end
    if sel_s < pos then
      Trim.trim_left(item, sel_s, "length")
    end
  end
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Trim Clip To Fill Selection', -1)
