-- @description hsuanice_Pro Tools Cut Time
-- @version 0.2.0 [260506.2030]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Cut Time** — removes the time selection range
--   from the timeline and ripples later content earlier.
--   Thin wrapper over native action 40201 "Time selection: Remove contents
--   of time selection (moving later items)".
-- @changelog
--   0.2.0 [260506.2030] - Map to native 40201.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40201, 0)  -- Time selection: Remove contents of time selection (moving later items)
