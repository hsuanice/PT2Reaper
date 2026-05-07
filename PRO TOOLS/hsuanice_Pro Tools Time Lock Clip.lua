-- @description hsuanice_Pro Tools Time Lock Clip
-- @version 0.2.0 [260506.1810]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Time Lock Clip** (Opt+Ctrl+L) — toggles time
--   lock on selected items. REAPER's per-item lock (C_LOCK) is a single
--   flag covering both edit and time lock — so this script is functionally
--   identical to "Edit Lock Clip" in REAPER.
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
r.Undo_EndBlock("Pro Tools: Time Lock Clip", -1)
