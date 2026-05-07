-- @description hsuanice_Pro Tools Quantize Clips
-- @version 0.2.0 [260506.2030]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Quantize Clips** (Cmd+Numpad 0) — snaps the
--   start positions of selected items to the grid.
--   Thin wrapper over native action 41165 "Item: Quantize item positions
--   to grid".
-- @changelog
--   0.2.0 [260506.2030] - Map to native 41165.
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(41165, 0)  -- Item: Quantize item positions to grid
