--[[
@description hsuanice_Pro Tools Trim Clip End to Fill Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Trim Clip End to Fill Selection**
  EXTEND ONLY — for each selected item, if the razor (or time selection)
  ends AFTER the item's end, extend the RIGHT edge to the selection's end.
  If the selection's end is inside the item, do nothing on this side.
  Fade-out length is preserved (the fade-out START follows the new end).
  Source-bound clamp: extending stops at source end (no warning).
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
