-- @description hsuanice_Pro Tools Identify Sync Point
-- @version 0.2.0 [260506.1750]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Identify Sync Point** (Cmd+Comma)
--   Thin wrapper over REAPER native action 40541 "Item: Set snap offset to
--   cursor" — sets the sync point (D_SNAPOFFSET) of each selected item to
--   the position under the edit cursor.
--   - Tags: Clips, Editing
-- @changelog
--   0.2.0 [260506.1750] - Map to native 40541.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40541, 0)  -- Item: Set snap offset to cursor
