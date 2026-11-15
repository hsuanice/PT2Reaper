--[[
@description hsuanice_Pro Tools Quantize Clips
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Quantize Clips** (Cmd+0 / Cmd+Numpad 0)

  Snaps each selected item's start position to the NEAREST grid
  line. Item length, fades, snap offset, and take properties are
  preserved (only `D_POSITION` is changed).

  Pure REAPER native (no SWS dependency). Tempo-aware: works in the
  quarter-note domain via `TimeMap2_*` so it handles tempo changes
  correctly.

  Equivalent to SWS named command `_SWS_QUANTITESTART2` ("SWS:
  Quantize item's start to grid (keep length)") but native.

  - Tags: Editing, Clips
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

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
