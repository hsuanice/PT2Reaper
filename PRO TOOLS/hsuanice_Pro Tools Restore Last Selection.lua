-- @description hsuanice_Pro Tools Restore Last Selection
-- @version 0.2.0 [260509.1245]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Restore Last Selection** (Cmd+Opt+Z)
--
--   Loads REAPER's "Selection set #01" (item selection + time
--   selection). Pair this script with a "Save Selection Set #01"
--   keystroke (native action 41229) so you can snapshot a selection
--   and recall it later.
--
--   ## Caveat (vs. PT)
--   PT auto-tracks the previous selection — pressing Cmd+Opt+Z
--   restores the selection that existed BEFORE the most recent
--   change. REAPER doesn't expose this natively. A future iteration
--   may add a defer-based selection-history watcher to fully match
--   PT; for now this script just calls native action 41239
--   (Selection set: Load set #01), so you must have saved one with
--   action 41229 first.
--
--   - Tags : Editing, Selection
-- @changelog
--   0.2.0 [260509.1245] - Initial implementation as wrapper for
--                          native action 41239 (Load Selection Set
--                          #01). Full PT-style auto-history TBD.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
r.Main_OnCommand(41239, 0)  -- Selection set: Load set #01
