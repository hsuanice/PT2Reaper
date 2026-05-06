-- @description hsuanice_Pro Tools Copy and Move Clip Sync Point To Current TC
-- @version 0.3.2 [260506.1730]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Copy and Move Clip Sync Point To Current TC**
--   (Opt+Ctrl+U)
--
--   Like "Move Clip Sync Point To Current TC" but originals stay intact —
--   only COPIES of inside-selection portions are placed at the target so
--   the leftmost SYNC POINT among in-scope items lands on project start
--   (timeline 0). Selection (TS / razor) follows the copies.
--
--   PT-style cut-and-paste split for partial overlaps: only the inside
--   portion is cloned (chunk-clone with STARTOFFS adjusted by
--   inside-offset * playrate per take). Outside-selection parts and the
--   original item itself are not touched.
--
--   Reference: among all in-scope items, the one with the LEFTMOST sync
--   point absolute position. delta = target − ref_sync_abs.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.3.2 [260506.1730] - PT-style fit check: if any clone would land at a
--                          negative position, the action no-ops entirely
--                          (no clones, no selection move).
--   0.3.1 [260506.1700] - Time mode now requires items to also be
--                          item-selected (matches PT — time selection alone
--                          doesn't pick up unselected items on other tracks).
--   0.3.0 [260506.1635] - Add cut-and-paste split for partial overlaps
--                          (matches Copy and Move Clip Start/End behavior).
--                          Reference = earliest sync absolute position.
--   0.2.0 [260506.1530] - First implementation (whole-item clone, no split).
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

local function clone_item(orig, track, new_pos, new_len, inside_offset)
  local _, chunk = r.GetItemStateChunk(orig, "", false)
  local new_item = r.AddMediaItemToTrack(track)
  r.SetItemStateChunk(new_item, chunk, false)
  r.SetMediaItemInfo_Value(new_item, "D_POSITION", new_pos)
  r.SetMediaItemInfo_Value(new_item, "D_LENGTH",   new_len)
  if inside_offset > EPS then
    for ti = 0, r.CountTakes(new_item) - 1 do
      local t = r.GetTake(new_item, ti)
      if t and not r.TakeIsMIDI(t) then
        local o  = r.GetMediaItemTakeInfo_Value(t, "D_STARTOFFS") or 0
        local pr = r.GetMediaItemTakeInfo_Value(t, "D_PLAYRATE")  or 1.0
        if pr <= 0 then pr = 1.0 end
        r.SetMediaItemTakeInfo_Value(t, "D_STARTOFFS", o + inside_offset * pr)
      end
    end
  end
  return new_item
end

local function clone_items_inside(infos, sel_s, sel_e, delta)
  for _, info in ipairs(infos) do
    local a = math.max(info.pos, sel_s)
    local b = math.min(info.fin, sel_e)
    local inside_offset = a - info.pos
    clone_item(info.item, r.GetMediaItemTrack(info.item),
               a + delta, b - a, inside_offset)
  end
end

local function min_sync_abs(infos)
  local m = math.huge
  for _, info in ipairs(infos) do
    local sync_abs = info.pos + (r.GetMediaItemInfo_Value(info.item, "D_SNAPOFFSET") or 0)
    if sync_abs < m then m = sync_abs end
  end
  return m
end

local zones = get_razor_zones()
local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = ts_e > ts_s + EPS

local sel_s, sel_e
local mode

if #zones > 0 then
  mode = "razor"
  sel_s, sel_e = math.huge, -math.huge
  for _, rz in ipairs(zones) do
    if rz.s < sel_s then sel_s = rz.s end
    if rz.e > sel_e then sel_e = rz.e end
  end
elseif has_ts then
  mode = "time"
  sel_s, sel_e = ts_s, ts_e
else
  mode = "items"
end

if mode == "items" then
  local n = r.CountSelectedMediaItems(0)
  if n == 0 then return end
  local ref_sync = math.huge
  local min_pos  = math.huge
  local sel_items = {}
  for i = 0, n-1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local sync = pos + (r.GetMediaItemInfo_Value(it, "D_SNAPOFFSET") or 0)
    if sync < ref_sync then ref_sync = sync end
    if pos  < min_pos  then min_pos  = pos  end
    sel_items[#sel_items+1] = it
  end
  local delta = target - ref_sync
  -- PT-style fit check: if any clone would land at a negative position,
  -- abort entirely (no clones placed, no selection moved).
  if min_pos + delta < -EPS then return end
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for _, it in ipairs(sel_items) do
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
    local tr  = r.GetMediaItemTrack(it)
    clone_item(it, tr, pos + delta, len, 0)
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Copy and Move Clip Sync Point To Current TC", -1)
  return
end

local infos = {}
if mode == "razor" then
  local seen = {}
  for _, rz in ipairs(zones) do
    local n = r.CountTrackMediaItems(rz.track)
    for i = 0, n-1 do
      local it  = r.GetTrackMediaItem(rz.track, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < rz.e - EPS and fin > rz.s + EPS and not seen[it] then
        seen[it] = true
        infos[#infos+1] = {item=it, pos=pos, fin=fin}
      end
    end
  end
else  -- time mode: selected items only
  local n = r.CountSelectedMediaItems(0)
  for i = 0, n-1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos < sel_e - EPS and fin > sel_s + EPS then
      infos[#infos+1] = {item=it, pos=pos, fin=fin}
    end
  end
end
if #infos == 0 then return end

local delta = target - min_sync_abs(infos)

-- PT-style fit check: if any clone would land at a negative position,
-- abort entirely (no clones placed, no selection moved).
local min_new_pos = math.huge
for _, info in ipairs(infos) do
  local a = math.max(info.pos, sel_s)
  if a + delta < min_new_pos then min_new_pos = a + delta end
end
if min_new_pos < -EPS then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

clone_items_inside(infos, sel_s, sel_e, delta)

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
