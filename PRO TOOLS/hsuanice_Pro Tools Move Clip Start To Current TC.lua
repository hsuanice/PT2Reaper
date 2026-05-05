-- @description hsuanice_Pro Tools Move Clip Start To Current TC
-- @version 0.4.0 [260506.1305]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Move Clip Start To Current TC** (Ctrl+Y)
--
--   Aligns the SELECTION's start to project start (timeline 0). Items that
--   overlap the selection get their portion-inside-selection cut out and
--   moved with the selection — cut-and-paste semantics, NOT a "selection
--   auto-extends to the whole item" semantics. Parts of items outside the
--   selection are split off and stay put.
--
--   Example: selection 5..8, item 4..6 → split item at 5; the 4..5 piece
--   stays where it is; the 5..6 piece moves with the selection (delta = 0
--   − 5 = −5), landing at 0..1.
--
--   Items fully inside the selection are not split — they just move.
--
--   **Scope priority: Razor > Time selection > Item selection.**
--     - Razor: scope = union of all track-area razor zones; only items on
--       razor tracks are processed
--     - Time: scope = time-selection bounds; all tracks
--     - Items only: no splitting (items are already the unit of work);
--       earliest selected item's start = the alignment reference; all
--       selected items shift by the same delta
--
--   No-op when no items end up in scope.
--
--   For "move to edit cursor" use the "Move Clip Start To Play Position"
--   variant instead.
--
--   - Tags: Clips, Editing
-- @changelog
--   0.4.0 [260506.1305] - Switch to PT-style cut-and-paste split on partial
--                          overlaps. Items partially overlapping the
--                          selection are split at the selection boundaries
--                          and only the inside portion moves; the outside
--                          parts stay in place. Replaces the v0.2/v0.3
--                          "auto-extend selection to wrap whole item"
--                          behavior, which the user confirmed PT does NOT do.
--   0.3.0 [260506.1230] - Target changed to project start (timeline 0).
--   0.2.0 [260506.1145] - Real implementation (auto-extend variant).
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper
local EPS = 1e-9

local target = 0  -- "Current TC" = project start (timeline 0).

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

-- Split + move items overlapping [sel_s, sel_e] on `track`. Outside-selection
-- parts are split off and stay put; the inside portion gets moved by delta.
local function split_and_move_track(track, sel_s, sel_e, delta)
  local n = r.CountTrackMediaItems(track)
  -- Snapshot original items first; splits will mutate the track item list.
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
    -- Split at sel_s if item starts before; the right half is the inside-side.
    if info.pos < sel_s - EPS then
      it = r.SplitMediaItem(it, sel_s)
    end
    -- Split at sel_e if item ends after; the left half stays as our inside item.
    if info.fin > sel_e + EPS then
      r.SplitMediaItem(it, sel_e)
    end
    -- Now `it` spans max(pos,sel_s) .. min(fin,sel_e). Move it.
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    r.SetMediaItemInfo_Value(it, "D_POSITION", p + delta)
  end
end

-- ---- Determine scope ----------------------------------------------------

local zones = get_razor_zones()
local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = ts_e > ts_s + EPS

local sel_s, sel_e
local mode  -- "razor" | "time" | "items"

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
  -- No splitting: just shift each selected item by delta = target − earliest.
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
  r.Undo_EndBlock("Pro Tools: Move Clip Start To Current TC", -1)
  return
end

-- Razor / Time mode: split items at selection boundaries and move inside parts.
delta = target - sel_s
if math.abs(delta) < EPS then return end

-- Pre-check: do any items actually overlap the selection? If not, no-op (PT).
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
else  -- time
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
else  -- time
  for ti = 0, r.CountTracks(0)-1 do
    split_and_move_track(r.GetTrack(0, ti), sel_s, sel_e, delta)
  end
end

-- Shift the selection itself (so the user's selection follows the moved content).
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
r.Undo_EndBlock("Pro Tools: Move Clip Start To Current TC", -1)
