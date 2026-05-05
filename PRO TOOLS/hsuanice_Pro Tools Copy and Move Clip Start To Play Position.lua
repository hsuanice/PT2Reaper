-- @description hsuanice_Pro Tools Copy and Move Clip Start To Play Position
-- @version 0.2.1 [260506.1430]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Copy and Move Clip Start To Play Position**
--   (Opt+Ctrl+H)
--
--   Like "Move Clip Start To Play Position" but the originals stay intact —
--   only COPIES of the inside-selection portions are placed at the target.
--   Target = edit cursor (PT-tested: Play Position uses edit cursor in
--   REAPER, even during playback).
--
--   For each item overlapping the selection, the part inside selection is
--   cloned (chunk + STARTOFFS adjustment for partial overlaps) and placed
--   on the same track at the target. Outside-selection parts and the
--   original item itself are not touched.
--
--   Always clones, even when the cursor is already at the selection start
--   (delta = 0) — matches PT's Spot semantics for the Play Position variant.
--
--   Selection (TS / razor) IS shifted to the target so it follows the new
--   copies (matches PT).
--
--   Scope priority: Razor > Time selection > Item selection. Items-only
--   mode duplicates each selected item to the target (no splitting).
--
--   - Tags: Clips, Editing
-- @changelog
--   0.2.1 [260506.1430] - Selection (TS / razor) now follows the copies to
--                          the target — matches PT. Originals still untouched.
--   0.2.0 [260506.1400] - Real implementation. Mirrors Copy and Move
--                          Clip Start To Current TC, but target is edit
--                          cursor. Always clones even when delta=0.
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

local function clone_track_inside(track, sel_s, sel_e, delta)
  local n = r.CountTrackMediaItems(track)
  local originals = {}
  for i = 0, n-1 do
    local it  = r.GetTrackMediaItem(track, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos < sel_e - EPS and fin > sel_s + EPS then
      originals[#originals+1] = {item=it, pos=pos, fin=fin}
    end
  end
  for _, info in ipairs(originals) do
    local a = math.max(info.pos, sel_s)
    local b = math.min(info.fin, sel_e)
    local inside_offset = a - info.pos
    clone_item(info.item, track, a + delta, b - a, inside_offset)
  end
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
  local earliest = math.huge
  local sel_items = {}
  for i = 0, n-1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    if pos < earliest then earliest = pos end
    sel_items[#sel_items+1] = it
  end
  local delta = target - earliest
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
  r.Undo_EndBlock("Pro Tools: Copy and Move Clip Start To Play Position", -1)
  return
end

local delta = target - sel_s
-- NOTE: do NOT short-circuit when delta == 0 — Spot semantics still produce
-- a clone of the inside-selection portion in place.

local has_overlap = false
local function track_has_overlap(tr)
  local n = r.CountTrackMediaItems(tr)
  for i = 0, n-1 do
    local it  = r.GetTrackMediaItem(tr, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos < sel_e - EPS and fin > sel_s + EPS then return true end
  end
  return false
end
if mode == "razor" then
  local seen = {}
  for _, rz in ipairs(zones) do
    if not seen[rz.track] and track_has_overlap(rz.track) then
      has_overlap = true; break
    end
    seen[rz.track] = true
  end
else
  for ti = 0, r.CountTracks(0)-1 do
    if track_has_overlap(r.GetTrack(0, ti)) then has_overlap = true; break end
  end
end
if not has_overlap then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

if mode == "razor" then
  local seen = {}
  for _, rz in ipairs(zones) do
    if not seen[rz.track] then
      seen[rz.track] = true
      clone_track_inside(rz.track, sel_s, sel_e, delta)
    end
  end
else
  for ti = 0, r.CountTracks(0)-1 do
    clone_track_inside(r.GetTrack(0, ti), sel_s, sel_e, delta)
  end
end

-- Shift TS / razor to the target location so the selection follows the copies.
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
r.Undo_EndBlock("Pro Tools: Copy and Move Clip Start To Play Position", -1)
