-- @description hsuanice_Pro Tools Move Clip Sync Point To Play Position
-- @version 0.3.1 [260506.1700]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Clip Sync Point To Play Position** (Ctrl+J)
--
--   Aligns the leftmost SYNC POINT among items in scope to the EDIT cursor.
--   All in-scope items shift by the same delta. The selection (TS / razor)
--   follows.
--
--   PT-style cut-and-paste split: items partially overlapping the selection
--   are split at sel_s/sel_e; only the inside-selection portion moves;
--   outside parts stay put. Always splits even when delta = 0 (Spot semantics).
--
--   Reference: among all in-scope items, the one with the LEFTMOST sync
--   point absolute position. delta = target − ref_sync_abs.
--
--   Scope priority: Razor > Time selection > Item selection.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.3.1 [260506.1700] - Time mode now requires items to also be
--                          item-selected (matches PT — time selection alone
--                          doesn't pick up unselected items on other tracks).
--   0.3.0 [260506.1620] - Add cut-and-paste split. Reference = earliest
--                          sync absolute position. Always splits even at
--                          delta=0 (matches Move Clip Start To Play Position).
--   0.2.0 [260506.1515] - First implementation (group move, no split).
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

local function split_and_move_items(infos, sel_s, sel_e, delta)
  for _, info in ipairs(infos) do
    local it = info.item
    if info.pos < sel_s - EPS then
      it = r.SplitMediaItem(it, sel_s)
    end
    if info.fin > sel_e + EPS then
      r.SplitMediaItem(it, sel_e)
    end
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    r.SetMediaItemInfo_Value(it, "D_POSITION", p + delta)
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
  local sel_items = {}
  for i = 0, n-1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local sync = pos + (r.GetMediaItemInfo_Value(it, "D_SNAPOFFSET") or 0)
    if sync < ref_sync then ref_sync = sync end
    sel_items[#sel_items+1] = it
  end
  local delta = target - ref_sync
  if math.abs(delta) < EPS then return end
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for _, it in ipairs(sel_items) do
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    r.SetMediaItemInfo_Value(it, "D_POSITION", p + delta)
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Move Clip Sync Point To Play Position", -1)
  return
end

-- Build the in-scope item list. Razor mode: items overlapping any razor
-- zone on its track. Time mode: ONLY selected items overlapping the time
-- selection (matches PT — time selection alone doesn't pick up unselected
-- items on other tracks).
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
-- NOTE: do NOT short-circuit when delta == 0 — Spot semantics still split.

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

split_and_move_items(infos, sel_s, sel_e, delta)

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
