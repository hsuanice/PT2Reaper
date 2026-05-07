-- @description hsuanice_Pro Tools Group Clips
-- @version 0.2.0 [260506.1810]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Group Clips** (Cmd+Opt+G) — groups selected items.
--   Thin wrapper over native action 40032 "Item grouping: Group items".
-- @changelog
--   0.2.0 [260506.1810] - Map to native 40032.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40032, 0)  -- Item grouping: Group items
