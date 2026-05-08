-- @description hsuanice_Pro Tools Quantize Clips
-- @version 0.4.0 [260508.1927]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Quantize Clips** (Cmd+0 / Cmd+Numpad 0)
--
--   Snaps each selected item's start position to the NEAREST grid
--   line. Item length, fades, snap offset, and take properties are
--   preserved (only `D_POSITION` is changed).
--
--   Pure REAPER native (no SWS dependency). Tempo-aware: works in the
--   quarter-note domain via `TimeMap2_*` so it handles tempo changes
--   correctly.
--
--   Equivalent to SWS named command `_SWS_QUANTITESTART2` ("SWS:
--   Quantize item's start to grid (keep length)") but native.
--
--   - Tags: Editing, Clips
-- @changelog
--   0.4.0 [260508.1927] - Pure-native rewrite. No SWS dependency. Uses
--                          GetSetProjectGrid + TimeMap2_timeToQN /
--                          QNToTime to snap each selected item's
--                          position to the nearest grid line in the
--                          QN domain (tempo-aware), preserving length.
--   0.3.0 [260508.1925] - Switch from native action 41165 (which had
--                          no visible effect) to SWS named command
--                          `_SWS_QUANTITESTART2`.
--   0.2.0 [260506.2030] - Map to native 41165.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r   = reaper
local EPS = 1e-9

local n_sel = r.CountSelectedMediaItems(0)
if n_sel == 0 then return end

local _, division = r.GetSetProjectGrid(0, false)
if not division or division <= 0 then return end
local div_qn = division * 4  -- whole-note → quarter-note units

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for i = 0, n_sel - 1 do
  local item = r.GetSelectedMediaItem(0, i)
  if r.ValidatePtr(item, "MediaItem*") then
    local pos    = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local cur_qn = r.TimeMap2_timeToQN(0, pos)
    local k      = math.floor(cur_qn / div_qn + 0.5)
    local snap_q = k * div_qn
    local snap_t = r.TimeMap2_QNToTime(0, snap_q)
    if snap_t < 0 then snap_t = 0 end
    if math.abs(snap_t - pos) > EPS then
      r.SetMediaItemInfo_Value(item, "D_POSITION", snap_t)
    end
  end
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Quantize Clips", -1)
