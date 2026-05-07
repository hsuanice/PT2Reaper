-- @description hsuanice_Pro Tools Loop Clips
-- @version 0.2.0 [260506.1810]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Loop Clips** (Cmd+Opt+L) — enables loop source
--   on selected items (B_LOOPSRC = 1). The visible content tiles whenever
--   the item is longer than the source.
-- @changelog
--   0.2.0 [260506.1810] - Set B_LOOPSRC = 1 on each selected item.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local n = r.CountSelectedMediaItems(0)
if n == 0 then return end
r.Undo_BeginBlock()
for i = 0, n-1 do
  r.SetMediaItemInfo_Value(r.GetSelectedMediaItem(0, i), "B_LOOPSRC", 1)
end
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Loop Clips", -1)
