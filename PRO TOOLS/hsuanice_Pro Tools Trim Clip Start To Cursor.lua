-- @description hsuanice_Pro Tools Trim Clip Start To Cursor
-- @version 0.2.0 [260504.1520]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Trim Clip Start To Cursor**
--   Trim or extend the LEFT edge of selected items to the edit cursor.
--   Preserves the fade-in END at its absolute timeline position; the fade-in
--   length adjusts (it shrinks if the new pos crosses the fade-in zone, or
--   stays the same when extending leftward into pre-roll).
--   Differs from REAPER native 41305, which deletes/resets the fade.
--   Source-bound clamp: extending stops at the source start (no warning).
--   - Tags: Editing
-- @changelog
--   0.2.0 [260504.1520] - Implemented via hsuanice_PT_Trim library (mode="boundary").
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
local cur = r.GetCursorPosition()

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
for i = 0, n - 1 do
  Trim.trim_left(r.GetSelectedMediaItem(0, i), cur, "boundary")
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Trim Clip Start To Cursor', -1)
