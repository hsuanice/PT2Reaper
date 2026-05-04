-- @description hsuanice_Pro Tools Trim Clip End to Fill Selection
-- @version 0.2.0 [260504.1520]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Trim Clip End to Fill Selection**
--   EXTEND ONLY — for each selected item, if the razor (or time selection)
--   ends AFTER the item's end, extend the RIGHT edge to the selection's end.
--   If the selection's end is inside the item, do nothing on this side.
--   Fade-out length is preserved (the fade-out START follows the new end).
--   Source-bound clamp: extending stops at source end (no warning).
--   - Tags: Editing
-- @changelog
--   0.2.0 [260504.1520] - Implemented via hsuanice_PT_Trim library (mode="length").
--                          Razor on item's track preferred, falls back to TS.
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
  local _, sel_e = Trim.get_selection_for_item(item)
  if sel_e then
    local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local en  = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    if sel_e > en then
      Trim.trim_right(item, sel_e, "length")
    end
  end
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Trim Clip End To Fill Selection', -1)
