-- @description hsuanice_Pro Tools Edit Lock Clip
-- @version 0.2.0 [260506.1810]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Edit Lock Clip** (Cmd+L) — toggles edit lock on
--   the selected items. PT distinguishes Edit Lock (locks editing) from Time
--   Lock (locks position); REAPER's per-item lock covers all of these, so
--   both PT actions map to the same REAPER lock.
-- @changelog
--   0.2.0 [260506.1810] - Custom toggle on C_LOCK for selected items.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local n = r.CountSelectedMediaItems(0)
if n == 0 then return end
local first_locked = r.GetMediaItemInfo_Value(r.GetSelectedMediaItem(0,0), "C_LOCK") > 0
local new_state = first_locked and 0 or 1
r.Undo_BeginBlock()
for i = 0, n-1 do
  r.SetMediaItemInfo_Value(r.GetSelectedMediaItem(0, i), "C_LOCK", new_state)
end
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Edit Lock Clip", -1)
