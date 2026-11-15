--[[
@description hsuanice_Pro Tools Trim Clip Start To Fill Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Trim Clip Start To Fill Selection**
  EXTEND ONLY — for each selected item, if the razor (or time selection)
  begins BEFORE the item's pos, extend the LEFT edge to the selection's
  start. If the selection's start is inside the item, do nothing on this
  side (this is not a trim).
  Fade-in length is preserved (the fade-in END follows the new pos).
  Source-bound clamp: extending stops at source start (no warning).
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
  local sel_s = Trim.get_selection_for_item(item)
  if sel_s then
    local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    if sel_s < pos then
      Trim.trim_left(item, sel_s, "length")
    end
  end
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Trim Clip Start To Fill Selection', -1)
