-- @description hsuanice_Pro Tools Move Clip Start To Play Position
-- @version 0.4.1 [260506.1325]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Clip Start To Play Position** (Ctrl+H)
--
--   Aligns the SELECTION's start to the EDIT cursor. Items that overlap the
--   selection get their portion-inside-selection cut out and moved with the
--   selection — cut-and-paste semantics, NOT a "selection auto-extends to
--   the whole item" semantics. Parts of items outside the selection are
--   split off and stay put.
--
--   Example: selection 5..8, item 4..6, edit cursor at 1 → split item at 5;
--   the 4..5 piece stays where it is; the 5..6 piece moves with the
--   selection (delta = 1 − 5 = −4), landing at 1..2.
--
--   PT testing showed Play Position uses the EDIT cursor in REAPER (not the
--   play head), even during playback. For "move to project start" use the
--   "Move Clip Start To Current TC" variant instead.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.4.1 [260506.1325] - Always split at selection boundaries, even when
--                          delta is zero (cursor at selection start). PT's
--                          Play Position variant has Spot semantics that
--                          always cut the inside-selection portion into its
--                          own item, regardless of whether anything ends up
--                          moving.
--   0.4.0 [260506.1305] - Switch to PT-style cut-and-paste split on partial
--                          overlaps. Shares logic with the Current TC variant
--                          but uses edit cursor as the target.
--   0.2.0 [260506.1145] - Real implementation (auto-extend variant).
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper
local EPS = 1e-9

local target = r.GetCursorPosition()  -- "Play Position" → edit cursor in REAPER

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

local function split_and_move_track(track, sel_s, sel_e, delta)
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

local delta

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
  delta = target - earliest
  if math.abs(delta) < EPS then return end
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  for _, it in ipairs(sel_items) do
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    r.SetMediaItemInfo_Value(it, "D_POSITION", p + delta)
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Move Clip Start To Play Position", -1)
  return
end

delta = target - sel_s
-- NOTE: do NOT short-circuit when delta == 0. PT's "Spot" semantics for the
-- Play Position variant always perform the split-at-selection-boundaries,
-- even when the cursor is already at the selection start (so the inside
-- portion becomes its own item even without any movement).

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
      split_and_move_track(rz.track, sel_s, sel_e, delta)
    end
  end
else
  for ti = 0, r.CountTracks(0)-1 do
    split_and_move_track(r.GetTrack(0, ti), sel_s, sel_e, delta)
  end
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
r.Undo_EndBlock("Pro Tools: Move Clip Start To Play Position", -1)
