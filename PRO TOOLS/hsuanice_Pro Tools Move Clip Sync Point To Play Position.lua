-- @description hsuanice_Pro Tools Move Clip Sync Point To Play Position
-- @version 0.2.0 [260506.1515]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Clip Sync Point To Play Position** (Ctrl+J)
--
--   Aligns the SYNC POINT of the earliest-by-position item in scope to
--   the EDIT cursor. All items in scope shift by the same delta so
--   relative positions and individual sync points are preserved.
--
--   Mirrors Move Clip Sync Point To Current TC; target = edit cursor.
--   No splitting on partial overlaps.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.2.0 [260506.1515] - Real implementation. Mirrors the Current TC
--                          variant, target = edit cursor.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper
local EPS = 1e-9

local target = r.GetCursorPosition()  -- "Play Position" → edit cursor

local function get_razor_zones()
  local zones = {}
  for ti = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      local toks = {}
      for t in s:gmatch("%S+") do toks[#toks+1] = t end
      for i = 1, #toks-2, 3 do
        local rs   = tonumber(toks[i])
        local re   = tonumber(toks[i+1])
        local guid = toks[i+2]
        if rs and re and guid == '""' then
          zones[#zones+1] = {track=tr, s=rs, e=re}
        end
      end
    end
  end
  return zones
end

local zones = get_razor_zones()
local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = ts_e > ts_s + EPS

local items = {}

if #zones > 0 then
  local seen = {}
  for _, rz in ipairs(zones) do
    local n = r.CountTrackMediaItems(rz.track)
    for i = 0, n-1 do
      local it  = r.GetTrackMediaItem(rz.track, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < rz.e - EPS and fin > rz.s + EPS and not seen[it] then
        seen[it] = true
        items[#items+1] = it
      end
    end
  end
elseif has_ts then
  for ti = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, ti)
    local n  = r.CountTrackMediaItems(tr)
    for i = 0, n-1 do
      local it  = r.GetTrackMediaItem(tr, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < ts_e - EPS and fin > ts_s + EPS then
        items[#items+1] = it
      end
    end
  end
else
  local n = r.CountSelectedMediaItems(0)
  for i = 0, n-1 do
    items[#items+1] = r.GetSelectedMediaItem(0, i)
  end
end

if #items == 0 then return end

local ref_item, ref_pos = nil, math.huge
for _, it in ipairs(items) do
  local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  if pos < ref_pos then
    ref_pos = pos
    ref_item = it
  end
end
local ref_sync_offset = r.GetMediaItemInfo_Value(ref_item, "D_SNAPOFFSET") or 0
local ref_sync_abs    = ref_pos + ref_sync_offset
local delta = target - ref_sync_abs
if math.abs(delta) < EPS then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for _, it in ipairs(items) do
  local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  r.SetMediaItemInfo_Value(it, "D_POSITION", pos + delta)
end

if has_ts then
  r.GetSet_LoopTimeRange(true, false, ts_s + delta, ts_e + delta, false)
end
if #zones > 0 then
  local tracks_with_razor = {}
  for _, rz in ipairs(zones) do tracks_with_razor[rz.track] = true end
  for tr in pairs(tracks_with_razor) do
    local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    local out = {}
    if s and s ~= "" then
      local toks = {}
      for t in s:gmatch("%S+") do toks[#toks+1] = t end
      for i = 1, #toks-2, 3 do
        local rs   = tonumber(toks[i])
        local re   = tonumber(toks[i+1])
        local guid = toks[i+2]
        if rs and re and guid == '""' then
          out[#out+1] = string.format("%.14f %.14f \"\"", rs + delta, re + delta)
        else
          out[#out+1] = string.format("%s %s %s", toks[i], toks[i+1], toks[i+2])
        end
      end
    end
    r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", table.concat(out, " "), true)
  end
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Move Clip Sync Point To Play Position", -1)
