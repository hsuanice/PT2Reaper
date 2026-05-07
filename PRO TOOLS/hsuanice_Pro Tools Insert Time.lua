-- @description hsuanice_Pro Tools Insert Time
-- @version 0.2.0 [260506.2030]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Insert Time** — inserts blank time at the time
--   selection, rippling later content later.
--   Thin wrapper over native action 40200 "Time selection: Insert empty
--   space at time selection (moving later items)".
-- @changelog
--   0.2.0 [260506.2030] - Map to native 40200.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40200, 0)  -- Time selection: Insert empty space at time selection (moving later items)
