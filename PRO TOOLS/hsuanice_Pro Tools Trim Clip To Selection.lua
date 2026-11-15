--[[
@description hsuanice_Pro Tools Trim Clip To Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Trim Clip To Selection**
  TRIM ONLY — for each selected item:
    • If razor (or TS) starts INSIDE the item (sel_s > pos), trim the LEFT
      edge to sel_s.
    • If razor (or TS) ends INSIDE the item (sel_e < end), trim the RIGHT
      edge to sel_e.
    • Sides whose selection edge is at or outside the item are not extended
      (this is not a fill/extend action).
  Fade boundaries are preserved at their absolute timeline positions; if
  the trim crosses a fade zone, that fade's length is cropped (the portion
  inside the kept region survives).
  - Tags: Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local info = debug.getinfo(1, 'S')
local dir  = info.source:match('^@(.*[/\\])') or ''
local ok, Trim = pcall(dofile, dir .. 'hsuanice_PT_Trim.lua')
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
    -- Trim right first, then left (so left STARTOFFS shift doesn't disturb the right calc)
    if sel_e < en and sel_e > pos then
      Trim.trim_right(item, sel_e, "boundary")
    end
    if sel_s > pos and sel_s < en then
      Trim.trim_left(item, sel_s, "boundary")
    end
  end
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Trim Clip To Selection', -1)
