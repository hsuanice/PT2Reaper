-- @description hsuanice_Pro Tools Snap To Previous
-- @version 0.3.0 [260509.0031]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Snap To Previous** (Opt+Ctrl+Comma)
--
--   Group-moves the entire moving body (selected items + time
--   selection + razor edit zones) to the left so it abuts the
--   previous non-selected item.
--
--   ## Algorithm
--   The "moving body" on each track contains:
--   - the selected items on that track
--   - the time selection (a global, treated as if present on every
--     constrained track)
--   - the razor edit zones on that track
--
--   1. Collect constrained tracks: every track that has selected
--      items OR razor zones.
--   2. Per constrained track, compute the leftmost extent of the
--      moving body — `left_pos = min(item.pos, TS_start, razor.s)`.
--   3. Find the last non-selected item on the same track whose
--      end position is <= `left_pos`.
--   4. delta = prev_item.fin - left_pos (only kept if < 0).
--   5. Across all constrained tracks, take max(delta) (the negative
--      number closest to zero) so no track's moving body overlaps
--      its previous neighbour.
--   6. Shift all selected items, the time selection, and every
--      track's razor zones by `delta`.
--
--   Pure REAPER native — only `D_POSITION` and `P_RAZOREDITS` /
--   loop time range are written; length, fades, snap offset, and
--   take properties are all preserved.
--
--   - Tags: Editing, Clips
-- @changelog
--   0.3.0 [260509.0031] - Treat TS_start and per-track razor zones
--                          as part of the moving body when computing
--                          the left extent. Razor zones now shift
--                          along with items + TS.
--   0.2.0 [260509.0021] - First implementation. Per-track group-move
--                          using minimum-magnitude-negative-delta to
--                          keep the move safe across all tracks;
--                          time selection follows the items.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r   = reaper
local EPS = 1e-9

local n_sel = r.CountSelectedMediaItems(0)
if n_sel == 0 then return end

-- 1. Collect selected items + per-track buckets
local sel_items = {}
local sel_set   = {}
local tracks    = {}

for i = 0, n_sel - 1 do
  local it = r.GetSelectedMediaItem(0, i)
  sel_items[#sel_items+1] = it
  sel_set[it] = true
  local tr = r.GetMediaItem_Track(it)
  tracks[tr] = tracks[tr] or { sel = {} }
  table.insert(tracks[tr].sel, it)
end

-- 2. Time selection bounds
local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = ts_e > ts_s + EPS

-- 3. Razor zones per track
local razor_per_track = {}
local n_tracks = r.CountTracks(0)
for ti = 0, n_tracks - 1 do
  local tr = r.GetTrack(0, ti)
  local _, str = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
  if str and str ~= "" then
    local zones = {}
    for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
      local s = tonumber(s_str)
      local e = tonumber(e_str)
      if s and e then zones[#zones+1] = {s = s, e = e, guid = guid} end
    end
    if #zones > 0 then razor_per_track[tr] = zones end
  end
end

-- 4. Compute the smallest-magnitude negative delta across constrained tracks
local constrained = {}
for tr in pairs(tracks)         do constrained[tr] = true end
for tr in pairs(razor_per_track) do constrained[tr] = true end

local best_delta  -- negative, closest to 0
for tr in pairs(constrained) do
  local info = tracks[tr] or { sel = {} }

  local left_pos = math.huge
  for _, it in ipairs(info.sel) do
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    if pos < left_pos then left_pos = pos end
  end
  if has_ts and ts_s < left_pos then left_pos = ts_s end
  if razor_per_track[tr] then
    for _, z in ipairs(razor_per_track[tr]) do
      if z.s < left_pos then left_pos = z.s end
    end
  end

  if left_pos < math.huge then
    local nearest_fin
    local n = r.CountTrackMediaItems(tr)
    for k = 0, n - 1 do
      local it = r.GetTrackMediaItem(tr, k)
      if not sel_set[it] then
        local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
        local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
        if fin <= left_pos + EPS then
          if not nearest_fin or fin > nearest_fin then
            nearest_fin = fin
          end
        end
      end
    end
    if nearest_fin then
      local delta = nearest_fin - left_pos  -- ≤ 0
      if delta < -EPS then
        if not best_delta or delta > best_delta then
          best_delta = delta
        end
      end
    end
  end
end

if not best_delta then return end

-- 5. Apply: move items, TS, razor zones
r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for _, it in ipairs(sel_items) do
  if r.ValidatePtr(it, "MediaItem*") then
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    r.SetMediaItemInfo_Value(it, "D_POSITION", pos + best_delta)
  end
end

if has_ts then
  r.GetSet_LoopTimeRange(true, false, ts_s + best_delta, ts_e + best_delta, false)
end

for tr, zones in pairs(razor_per_track) do
  local parts = {}
  for _, z in ipairs(zones) do
    parts[#parts+1] = string.format("%.14f %.14f %s",
      z.s + best_delta, z.e + best_delta, z.guid)
  end
  r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
    table.concat(parts, " "), true)
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Snap To Previous", -1)
