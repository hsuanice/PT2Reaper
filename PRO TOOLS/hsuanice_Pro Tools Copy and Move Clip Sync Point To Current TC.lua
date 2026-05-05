-- @description hsuanice_Pro Tools Copy and Move Clip Sync Point To Current TC
-- @version 0.2.0 [260506.1530]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Copy and Move Clip Sync Point To Current TC**
--   (Opt+Ctrl+U)
--
--   Like "Move Clip Sync Point To Current TC" but originals stay intact —
--   only COPIES of the in-scope items are placed at the target so the
--   earliest item's sync point lands on project start (timeline 0). All
--   copies preserve their relative positions and individual sync points.
--   Selection (TS / razor) follows the copies.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.2.0 [260506.1530] - Real implementation. Mirrors Move Clip Sync
--                          Point To Current TC, but clones items instead
--                          of moving them. No splitting on partial
--                          overlaps — the whole item is cloned.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper
local EPS = 1e-9

local target = 0  -- "Current TC" = project start

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

-- Whole-item clone (no STARTOFFS adjustment — clones reproduce the original
-- exactly, just shifted in position).
local function clone_item_whole(orig, track, new_pos)
  local _, chunk = r.GetItemStateChunk(orig, "", false)
  local new_item = r.AddMediaItemToTrack(track)
  r.SetItemStateChunk(new_item, chunk, false)
  r.SetMediaItemInfo_Value(new_item, "D_POSITION", new_pos)
  return new_item
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

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

for _, it in ipairs(items) do
  local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  local tr  = r.GetMediaItemTrack(it)
  clone_item_whole(it, tr, pos + delta)
end

-- Selection follows copies.
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
r.Undo_EndBlock("Pro Tools: Copy and Move Clip Sync Point To Current TC", -1)
