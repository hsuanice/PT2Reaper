-- @description hsuanice_Pro Tools Ungroup Clips
-- @version 0.2.0 [260506.1810]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Ungroup Clips** (Cmd+Opt+U) — removes selected
--   items from their group. Thin wrapper over native action 40033 "Item
--   grouping: Remove items from group".
-- @changelog
--   0.2.0 [260506.1810] - Map to native 40033.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40033, 0)  -- Item grouping: Remove items from group
