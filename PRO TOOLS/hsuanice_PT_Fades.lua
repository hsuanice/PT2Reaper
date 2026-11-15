--[[
@description hsuanice_PT_Fades — Pro Tools-style fade helpers
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared library for Pro Tools "Create Fades", "Apply Next/Previous Fade
  Shape", "Execute Crossfade Last Setting", "Delete Fades", and related
  scripts. Encapsulates REAPER's two fade chunk encodings so calling
  scripts only deal with GUI shape indices (1..7).

  GUI shape order (matches REAPER 7.71 fade actions):
    1 Linear / 2 Slight Convex (Equal Power) / 3 Slight Concave /
    4 Sharp Convex / 5 Sharp Concave / 6 Slight S-Curve / 7 Sharp S-Curve

  Chunk format reference (empirical, REAPER 7.71+):
    FADEIN/FADEOUT (legacy, 7 tokens):
      <type> <manual_len> <auto_len> 0 <active> <curv> <dir>
      type field1 = 0..6 (simple PT index) or 10/11/12 (extended)
      Sharp S-curve quirk: encoded as fractional 5.1 (not 6)
      curv sign FLIPS between FADEIN and FADEOUT for the same visual shape

    FADEINNEW/FADEOUTNEW (current auto-fade, 6 tokens):
      <a> <b> <c> <type> <curv> <flag>
      type 10 = exponential, 11 = constant power, 12 = s-curve
      curv = -1..+1 (NO sign flip between in/out)
      flag = continuous S-curve intensity (0.5 = Slight, 1 = Sharp);
             type=12 with flag=0 renders as Linear
--]]

local r = reaper
local F = {}

-- ----- Constants ---------------------------------------------------------

F.SHAPE_NAMES = {
  "Linear",
  "Slight Convex (Equal Power)",
  "Slight Concave",
  "Sharp Convex",
  "Sharp Concave",
  "Slight S-Curve",
  "Sharp S-Curve",
}
F.FADEIN_CMDS  = {41514,41515,41516,41517,41518,41519,41836}
F.FADEOUT_CMDS = {41521,41522,41523,41524,41525,41526,41837}
-- XFADE shape actions (41528-41533, 41838) are intentionally not exposed
-- because they unreliably update only the right item's fade-in. Use
-- patch_xfade_new() to write the FADEINNEW/FADEOUTNEW chunk lines directly.

F.XFADE_GAP = 0.005   -- items within 5ms are treated as touching
F.EPS       = 1e-4

-- ----- Item info helpers -------------------------------------------------

function F.clamp_shape(s)
  return math.max(1, math.min(7, s))
end

-- Returns a list of selected items in the form {item, pos, len, fin}, sorted by position.
function F.get_sel_items()
  local items = {}
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    local it  = r.GetSelectedMediaItem(0,i)
    local pos = r.GetMediaItemInfo_Value(it,"D_POSITION")
    local len = r.GetMediaItemInfo_Value(it,"D_LENGTH")
    items[#items+1] = {item=it, pos=pos, len=len, fin=pos+len}
  end
  table.sort(items, function(a,b) return a.pos < b.pos end)
  return items
end

-- Group items by track, then within each track find adjacent overlapping or
-- touching pairs. Returns list of {left=A, right=B, overlap=N, touching=bool}.
-- A and B are entries from the input items list.
function F.find_xfade_pairs(items)
  local pairs_out = {}
  local by_track = {}
  for _, it in ipairs(items) do
    local tr = r.GetMediaItemTrack(it.item)
    by_track[tr] = by_track[tr] or {}
    table.insert(by_track[tr], it)
  end
  for _, group in pairs(by_track) do
    table.sort(group, function(a,b) return a.pos < b.pos end)
    for i = 1, #group-1 do
      local a, b = group[i], group[i+1]
      local gap = b.pos - a.fin
      if gap <= F.XFADE_GAP then
        local overlap = math.max(0, a.fin - b.pos)
        pairs_out[#pairs_out+1] = {
          left = a, right = b,
          overlap = overlap,
          touching = (gap >= -F.EPS),
        }
      end
    end
  end
  return pairs_out
end

-- ----- Shape detection ---------------------------------------------------

-- Map (type, curv, flag) from the NEW format → GUI shape index (1..7).
function F.classify_new_shape(type_f, curv_f, flag_f)
  if type_f == 11 then return 2 end  -- Slight Convex (Equal Power)
  if type_f == 12 then
    return ((flag_f or 0) >= 0.75) and 7 or 6  -- Sharp (~1) vs Slight (~0.5)
  end
  -- type 10: classify by curvature (no sign flip in NEW format)
  if math.abs(curv_f) < 0.05 then return 1 end       -- Linear
  if curv_f >=  0.75 then return 4 end               -- Sharp Convex (~+1)
  if curv_f <= -0.75 then return 5 end               -- Sharp Concave (~-1)
  if curv_f >  0     then return 2 end               -- Slight Convex (rare type 10 case)
  return 3                                           -- Slight Concave (~-0.5)
end

-- Map (type, curv) from the legacy format → GUI shape index. is_fadein flips curv sign.
function F.classify_legacy_shape(field1, field6, is_fadein)
  if field1 >= 0 and field1 <= 6 then
    -- Simple 0..6 encoding from FADEIN/FADEOUT actions, with one quirk:
    -- REAPER 7.71+ encodes Sharp S-curve as the fractional value 5.1 (not 6),
    -- while Slight S-curve stays at integer 5. Treat any 5.x with x>0 as 7.
    local int_part = math.floor(field1)
    local has_frac = (field1 - int_part) > 0.05
    if int_part == 5 and has_frac then return 7 end
    return F.clamp_shape(int_part + 1)
  end
  if field1 == 11 then return 2 end
  if field1 == 12 then return 6 end  -- legacy line can't distinguish 7
  local c = is_fadein and -field6 or field6
  if math.abs(c) < 0.05 then return 1 end
  if c >=  0.75 then return 4 end
  if c <= -0.75 then return 5 end
  if c >  0     then return 4 end
  return 3
end

-- Read the FADEINNEW or FADEOUTNEW line. Returns GUI shape (1..7), or nil if
-- the line is missing or describes "no auto-fade" (type field < 10).
function F.shape_from_new_line(item, side)
  local prefix = (side == "fadein") and "FADEINNEW" or "FADEOUTNEW"
  local ok, chunk = r.GetItemStateChunk(item, "", false)
  if not ok or not chunk then return nil end
  local line = chunk:match("\n" .. prefix .. " ([^\n]+)")
              or chunk:match("^" .. prefix .. " ([^\n]+)")
  if not line then return nil end
  local toks = {}
  for tok in line:gmatch("%S+") do toks[#toks+1] = tok end
  local type_f = tonumber(toks[4]) or 0
  local curv_f = tonumber(toks[5]) or 0
  local flag_f = tonumber(toks[6]) or 0
  if type_f < 10 then return nil end
  return F.classify_new_shape(type_f, curv_f, flag_f)
end

-- Read the legacy FADEIN/FADEOUT line. Always returns 1..7 (defaults to 1).
function F.shape_from_legacy_line(item, line_prefix)
  local ok, chunk = r.GetItemStateChunk(item, "", false)
  if not ok or not chunk then return 1 end
  local line = chunk:match("\n" .. line_prefix .. " ([^\n]+)")
              or chunk:match("^" .. line_prefix .. " ([^\n]+)")
  if not line then return 1 end
  local toks = {}
  for tok in line:gmatch("%S+") do toks[#toks+1] = tok end
  local f1 = tonumber(toks[1]) or 0
  local f6 = tonumber(toks[6]) or 0
  return F.classify_legacy_shape(f1, f6, line_prefix == "FADEIN")
end

-- Effective fade-in shape: NEW line if active, else legacy.
function F.existing_fadein_shape(item)
  return F.shape_from_new_line(item, "fadein") or F.shape_from_legacy_line(item, "FADEIN")
end
function F.existing_fadeout_shape(item)
  return F.shape_from_new_line(item, "fadeout") or F.shape_from_legacy_line(item, "FADEOUT")
end

-- ----- Crossfade chunk write ---------------------------------------------

-- Build a FADEINNEW or FADEOUTNEW chunk line content for the chosen GUI shape.
-- (No length in this line — REAPER computes auto-fade length from item overlap,
-- or D_FADEIN/OUTLEN_AUTO when set explicitly.)
function F.build_new_line(gui_shape)
  local TYPE = {[1]=10, [2]=11, [3]=10, [4]=10, [5]=10, [6]=12, [7]=12}
  local CURV = {[1]=0,  [2]=0.5, [3]=-0.5, [4]=1, [5]=-1, [6]=0, [7]=0}
  local FLAG = {[1]=0,  [2]=0,   [3]=0,    [4]=0, [5]=0,  [6]=0.5, [7]=1}
  return string.format("10 0 0 %d %.10g %.10g",
    TYPE[gui_shape] or 10, CURV[gui_shape] or 0, FLAG[gui_shape] or 0)
end

-- Patch (or insert) the FADEINNEW/FADEOUTNEW line in an item's chunk.
function F.patch_xfade_new(item, side, gui_shape)
  local new_prefix = (side == "fadein") and "FADEINNEW" or "FADEOUTNEW"
  local old_prefix = (side == "fadein") and "FADEIN"    or "FADEOUT"
  local ok, chunk = r.GetItemStateChunk(item, "", false)
  if not ok or not chunk then return end
  local new_data = F.build_new_line(gui_shape)
  local pattern  = "(\n" .. new_prefix .. " )[^\n]+"
  local replaced, n = chunk:gsub(pattern, "%1" .. new_data, 1)
  if n == 0 then
    -- Line missing — insert after the corresponding FADEIN/FADEOUT line.
    local insert_pat = "(\n" .. old_prefix .. " [^\n]+)"
    replaced = chunk:gsub(insert_pat, "%1\n" .. new_prefix .. " " .. new_data, 1)
  end
  r.SetItemStateChunk(item, replaced, false)
end

-- ----- Manual fade apply (uses native FADEIN/OUT actions) ----------------

-- Apply a fade-in shape to a SINGLE item via the native FADEIN_CMDS action.
-- Saves and restores the global selection.
function F.apply_fadein_shape(item, gui_shape)
  local prev_sel = {}
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    prev_sel[#prev_sel+1] = r.GetSelectedMediaItem(0, i)
  end
  r.Main_OnCommand(40289, 0)
  r.SetMediaItemSelected(item, true)
  r.Main_OnCommand(F.FADEIN_CMDS[F.clamp_shape(gui_shape)], 0)
  r.Main_OnCommand(40289, 0)
  for _, it in ipairs(prev_sel) do r.SetMediaItemSelected(it, true) end
end

function F.apply_fadeout_shape(item, gui_shape)
  local prev_sel = {}
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    prev_sel[#prev_sel+1] = r.GetSelectedMediaItem(0, i)
  end
  r.Main_OnCommand(40289, 0)
  r.SetMediaItemSelected(item, true)
  r.Main_OnCommand(F.FADEOUT_CMDS[F.clamp_shape(gui_shape)], 0)
  r.Main_OnCommand(40289, 0)
  for _, it in ipairs(prev_sel) do r.SetMediaItemSelected(it, true) end
end

-- Apply a crossfade shape to a left/right item pair (writes both NEW lines).
function F.apply_xfade_shape(left_item, right_item, gui_shape)
  F.patch_xfade_new(left_item,  "fadeout", gui_shape)
  F.patch_xfade_new(right_item, "fadein",  gui_shape)
end

-- Variants that DON'T save/restore selection. Use inside with_preserved_state()
-- when applying many shapes in a row.
function F.set_fadein_shape(item, gui_shape)
  r.Main_OnCommand(40289, 0)
  r.SetMediaItemSelected(item, true)
  r.Main_OnCommand(F.FADEIN_CMDS[F.clamp_shape(gui_shape)], 0)
end
function F.set_fadeout_shape(item, gui_shape)
  r.Main_OnCommand(40289, 0)
  r.SetMediaItemSelected(item, true)
  r.Main_OnCommand(F.FADEOUT_CMDS[F.clamp_shape(gui_shape)], 0)
end

-- ----- Selection / scope preservation -----------------------------------

-- Snapshot all razor edit strings (one per track) so we can restore them.
function F.snapshot_razors()
  local snap = {}
  for ti = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    snap[#snap+1] = {track=tr, str=s or ""}
  end
  return snap
end

-- Restore razor edit strings from a snapshot.
function F.restore_razors(snap)
  if not snap then return end
  for _, e in ipairs(snap) do
    r.GetSetMediaTrackInfo_String(e.track, "P_RAZOREDITS", e.str, true)
  end
end

-- Run fn() with item selection, time selection AND razor edits saved/restored.
-- (Some fade actions / Main_OnCommand calls in REAPER 7.71+ clear razor edits
-- as a side effect, so we snapshot them defensively.)
function F.with_preserved_state(fn)
  local prev_sel = {}
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    prev_sel[#prev_sel+1] = r.GetSelectedMediaItem(0, i)
  end
  local ts, te  = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local has_ts  = te > ts + F.EPS
  local razors  = F.snapshot_razors()

  local ok, err = pcall(fn)

  r.Main_OnCommand(40289, 0)
  for _, it in ipairs(prev_sel) do r.SetMediaItemSelected(it, true) end
  if has_ts then r.GetSet_LoopTimeRange(true, false, ts, te, false) end
  F.restore_razors(razors)

  if not ok then error(err) end
end

-- ----- Scope + target detection -----------------------------------------

-- Read all razor zones across all tracks (only the track-area razors with guid="").
-- Returns: list of {track, s, e}.
function F.get_all_razor_zones()
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

-- Determine the active scope and gather the fade targets it implies.
--
-- Scope priority: Razor > Time selection > Item selection.
-- Returns a table:
--   {
--     scope         = "razor" | "time" | "items",
--     xfade_pairs   = list of {left={item,pos,len,fin}, right={...}} pairs
--                     where BOTH items are in the active set,
--     fadein_items  = list of items whose fade-in is in scope and NOT
--                     handled by an xfade pair,
--     fadeout_items = list of items whose fade-out is in scope and NOT
--                     handled by an xfade pair,
--   }
--
-- Region filtering for fades:
--   "items"  → no region filter; any fade on a selected item counts
--   "time"   → fade region must overlap the time selection
--   "razor"  → fade region must overlap a razor zone on its track
function F.gather_fade_targets()
  local zones = F.get_all_razor_zones()
  local scope, time_s, time_e

  if #zones > 0 then
    scope = "razor"
  else
    local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if te > ts + F.EPS then
      scope = "time"; time_s = ts; time_e = te
    else
      scope = "items"
    end
  end

  -- Build active set: item -> {pos, len, fin, track, razor_zones}
  local active = {}
  local function ensure(it, pos, len, tr)
    if not active[it] then
      active[it] = {pos=pos, len=len, fin=pos+len, track=tr, razor_zones={}}
    end
    return active[it]
  end

  if scope == "razor" then
    -- PT-like: razor IS the selection. Item selection is irrelevant; we only
    -- look at items overlapping a razor zone on their track.
    for _, rz in ipairs(zones) do
      local n = r.CountTrackMediaItems(rz.track)
      for i = 0, n-1 do
        local it  = r.GetTrackMediaItem(rz.track, i)
        local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
        local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
        if pos < rz.e and pos + len > rz.s then
          local info = ensure(it, pos, len, rz.track)
          table.insert(info.razor_zones, rz)
        end
      end
    end
  elseif scope == "time" then
    -- Time selection alone doesn't select items in PT — the user must have
    -- items selected too. So in time mode, active = (item-selected) AND
    -- (overlaps time selection). This makes the crossfade rule symmetric
    -- with item-selection mode: an xfade pair only fires when BOTH items
    -- are explicitly item-selected.
    for i = 0, r.CountSelectedMediaItems(0)-1 do
      local it  = r.GetSelectedMediaItem(0, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < time_e and pos + len > time_s then
        ensure(it, pos, len, r.GetMediaItemTrack(it))
      end
    end
  else  -- items
    for i = 0, r.CountSelectedMediaItems(0)-1 do
      local it  = r.GetSelectedMediaItem(0, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local len = r.GetMediaItemInfo_Value(it, "D_LENGTH")
      ensure(it, pos, len, r.GetMediaItemTrack(it))
    end
  end

  -- Sort active items into a list.
  local items_list = {}
  for it, info in pairs(active) do
    items_list[#items_list+1] = {item=it, pos=info.pos, len=info.len, fin=info.fin}
  end
  table.sort(items_list, function(a,b) return a.pos < b.pos end)

  -- Find xfade pairs (per-track adjacency, both ends in active set).
  local xfade_pairs = F.find_xfade_pairs(items_list)

  -- For razor scope, additionally require the xfade region to overlap a razor
  -- zone on the items' track. Otherwise an xfade outside the razor would still
  -- be processed because both items happen to overlap the razor elsewhere.
  if scope == "razor" then
    local kept = {}
    for _, p in ipairs(xfade_pairs) do
      local xs, xe = p.right.pos, p.left.fin
      for _, rz in ipairs(active[p.left.item].razor_zones) do
        if xs < rz.e and xe > rz.s then kept[#kept+1] = p; break end
      end
    end
    xfade_pairs = kept
  end

  -- Helper: does [a, b] overlap any razor zone on this item's track?
  local function fade_in_razor(info, fa, fb)
    for _, rz in ipairs(info.razor_zones) do
      if fa < rz.e and fb > rz.s then return true end
    end
    return false
  end

  -- fadein_items / fadeout_items are intentionally limited to MANUAL fades.
  -- Auto fades (D_FADEIN/OUTLEN_AUTO > 0) ARE crossfades by definition, and
  -- the user's rule requires both items of an xfade pair to be in the active
  -- set before we touch them — that's enforced via xfade_pairs only. So a
  -- single selected item from an xfade pair (whose only fade is the auto one)
  -- correctly produces no work here.
  local fadein_items, fadeout_items = {}, {}
  for it, info in pairs(active) do
    local fi  = r.GetMediaItemInfo_Value(it, "D_FADEINLEN")        or 0
    local fia = r.GetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO")   or 0
    local fo  = r.GetMediaItemInfo_Value(it, "D_FADEOUTLEN")       or 0
    local foa = r.GetMediaItemInfo_Value(it, "D_FADEOUTLEN_AUTO")  or 0

    if fi > F.EPS and fia <= F.EPS then
      local s, e = info.pos, info.pos + fi
      local in_scope = (scope == "items")
        or (scope == "time"  and s < time_e and e > time_s)
        or (scope == "razor" and fade_in_razor(info, s, e))
      if in_scope then fadein_items[#fadein_items+1] = it end
    end
    if fo > F.EPS and foa <= F.EPS then
      local s, e = info.fin - fo, info.fin
      local in_scope = (scope == "items")
        or (scope == "time"  and s < time_e and e > time_s)
        or (scope == "razor" and fade_in_razor(info, s, e))
      if in_scope then fadeout_items[#fadeout_items+1] = it end
    end
  end

  return {
    scope         = scope,
    xfade_pairs   = xfade_pairs,
    fadein_items  = fadein_items,
    fadeout_items = fadeout_items,
  }
end

-- ----- Create-Fades-style detection ---------------------------------------
--
-- Port of the detection logic from "hsuanice_Pro Tools Create Fades.lua" so
-- both Create Fades and Execute Crossfade Last Setting share the same
-- selection-aware fade categorization. Unlike gather_fade_targets() (which
-- only returns items with EXISTING fades, intended for cycle/delete), this
-- function returns the fades IMPLIED by the current selection geometry —
-- so it works for creating new fades on items that don't have one yet.
--
-- Returns a table with:
--   types         = list of "fade_in" / "fade_out" / "crossfade"
--   items         = list of {item, pos, len, fin} sorted by position
--   fadein_items  = list of {item={item,pos,...}, len=number_or_nil, use_ms=bool}
--   fadeout_items = same shape
--   xfade_pairs   = list of {left=info, right=info, overlap, touching}
--   def_fadein_shape, def_fadeout_shape, def_xfade_shape (1..7)
--   def_batch_ms  = number (default ms for batch input)
--   show_length   = bool (true → batch UI with ms fields; false → shape only)
--   sel_xlen      = optional number (selection length, used by xfade in
--                    single-category shape-only mode)
local FADE_IN_TAG  = "fade_in"
local FADE_OUT_TAG = "fade_out"
local XFADE_TAG    = "crossfade"

local function get_razor_range_union()
  local min_pos, max_end = math.huge, -math.huge
  local found = false
  for ti = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      local toks = {}
      for t in s:gmatch("%S+") do toks[#toks+1] = t end
      for i = 1, #toks-2, 3 do
        local rs   = tonumber(toks[i])
        local re   = tonumber(toks[i+1])
        local guid = toks[i+2]
        if rs and re and guid == '""' then
          found = true
          if rs < min_pos then min_pos = rs end
          if re > max_end then max_end = re end
        end
      end
    end
  end
  if found then return min_pos, max_end end
  return nil, nil
end

function F.detect_create_targets()
  local items = F.get_sel_items()
  local det = {
    types = {}, items = items,
    fadein_items = {}, fadeout_items = {}, xfade_pairs = {},
    def_fadein_shape = 1, def_fadeout_shape = 1, def_xfade_shape = 2,
    def_batch_ms = 10,
    show_length = true,
  }
  if #items == 0 then return det end

  local EPS = F.EPS
  local EXT_SEC = "hsuanice_PT2Reaper_CreateFades"
  local v_default = tonumber(r.GetExtState(EXT_SEC, "fadein_ms"))
  if v_default and v_default > 0 then det.def_batch_ms = math.floor(v_default) end

  -- Scope priority: Razor > Time > none.
  local sel_start, sel_end
  local rz_s, rz_e = get_razor_range_union()
  local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local has_ts = te > ts + EPS
  if rz_s then sel_start, sel_end = rz_s, rz_e
  elseif has_ts then sel_start, sel_end = ts, te end

  -- xfade pairs: per-track adjacency.
  det.xfade_pairs = F.find_xfade_pairs(items)
  local has_xfade = #det.xfade_pairs > 0
  local is_multi  = #items > 1

  if sel_start then
    if is_multi or has_xfade then
      -- Batch path
      det.show_length = true
      local is_xfade_right, is_xfade_left = {}, {}
      for _, p in ipairs(det.xfade_pairs) do
        is_xfade_left [p.left.item]  = true
        is_xfade_right[p.right.item] = true
      end
      for _, it in ipairs(items) do
        local ts_at_start = sel_start <= it.pos + EPS
        local te_at_end   = sel_end   >= it.fin  - EPS
        local te_inside   = sel_end   >  it.pos + EPS and sel_end < it.fin - EPS
        local ts_inside   = sel_start >  it.pos + EPS and sel_start < it.fin - EPS
        if ts_at_start and (te_inside or te_at_end) then
          if not is_xfade_right[it.item] then
            det.fadein_items[#det.fadein_items+1] = {item=it, len=nil, use_ms=true}
          end
        end
        if te_at_end and (ts_inside or ts_at_start) then
          if not is_xfade_left[it.item] then
            det.fadeout_items[#det.fadeout_items+1] = {item=it, len=nil, use_ms=true}
          end
        end
      end
    else
      -- Single-item path
      local it = items[1]
      local ts_at_start = sel_start <= it.pos + EPS
      local te_at_end   = sel_end   >= it.fin  - EPS
      local te_inside   = sel_end   >  it.pos + EPS and sel_end < it.fin - EPS
      local ts_inside   = sel_start >  it.pos + EPS and sel_start < it.fin - EPS

      if ts_at_start and te_inside then
        det.fadein_items[#det.fadein_items+1] = {item=it, len=sel_end - it.pos, use_ms=false}
        det.show_length = false
      elseif ts_inside and te_at_end then
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=it.fin - sel_start, use_ms=false}
        det.show_length = false
      elseif ts_at_start and te_at_end then
        det.fadein_items[#det.fadein_items+1]   = {item=it, len=nil, use_ms=true}
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=nil, use_ms=true}
        det.show_length = true
      else
        local fi_len = r.GetMediaItemInfo_Value(it.item, "D_FADEINLEN")
        local fo_len = r.GetMediaItemInfo_Value(it.item, "D_FADEOUTLEN")
        if fi_len > EPS then
          det.fadein_items[#det.fadein_items+1]   = {item=it, len=fi_len, use_ms=false}
        end
        if fo_len > EPS then
          det.fadeout_items[#det.fadeout_items+1] = {item=it, len=fo_len, use_ms=false}
        end
        det.show_length = false
      end
    end
  else
    -- No selection: items only, batch with ms, exclude xfade boundaries.
    det.show_length = true
    local is_xfade_right, is_xfade_left = {}, {}
    for _, p in ipairs(det.xfade_pairs) do
      is_xfade_left [p.left.item]  = true
      is_xfade_right[p.right.item] = true
    end
    for _, it in ipairs(items) do
      local fi_len = r.GetMediaItemInfo_Value(it.item, "D_FADEINLEN")
      local fo_len = r.GetMediaItemInfo_Value(it.item, "D_FADEOUTLEN")
      if not is_xfade_right[it.item] then
        det.fadein_items[#det.fadein_items+1]   = {item=it, len=fi_len > EPS and fi_len or nil, use_ms=true}
      end
      if not is_xfade_left[it.item] then
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=fo_len > EPS and fo_len or nil, use_ms=true}
      end
    end
  end

  -- Single-category batch → shape-only with selection-derived lengths.
  local n_in   = #det.fadein_items
  local n_out  = #det.fadeout_items
  local n_x    = #det.xfade_pairs
  local n_cats = (n_in > 0 and 1 or 0) + (n_out > 0 and 1 or 0) + (n_x > 0 and 1 or 0)
  if n_cats == 1 and sel_start and sel_end and (sel_end - sel_start) > EPS then
    det.show_length = false
    for _, fi in ipairs(det.fadein_items) do
      fi.len = sel_end - fi.item.pos; fi.use_ms = false
    end
    for _, fo in ipairs(det.fadeout_items) do
      fo.len = fo.item.fin - sel_start; fo.use_ms = false
    end
    if n_x > 0 then
      det.sel_xlen  = sel_end - sel_start
      -- Pass the selection bounds through so apply() can POSITION the xfade
      -- exactly at the selection (not just match its length around the old
      -- item boundary, which would offset the xfade if the selection isn't
      -- centered on the boundary — e.g. razor 7 frames placed half a frame
      -- right of the touching point).
      det.sel_start = sel_start
      det.sel_end   = sel_end
    end
  end

  -- Types list
  if #det.fadein_items  > 0 then det.types[#det.types+1] = FADE_IN_TAG  end
  if #det.xfade_pairs   > 0 then det.types[#det.types+1] = XFADE_TAG    end
  if #det.fadeout_items > 0 then det.types[#det.types+1] = FADE_OUT_TAG end

  -- Defaults from existing fades.
  if items[1] then
    det.def_fadein_shape  = F.existing_fadein_shape(items[1].item)
    det.def_fadeout_shape = F.existing_fadeout_shape(items[1].item)
  end
  if #det.fadein_items > 0 then
    det.def_fadein_shape  = F.existing_fadein_shape(det.fadein_items[1].item.item)
  end
  if #det.fadeout_items > 0 then
    det.def_fadeout_shape = F.existing_fadeout_shape(det.fadeout_items[1].item.item)
  end
  if #det.xfade_pairs > 0 then
    det.def_xfade_shape   = F.existing_fadein_shape(det.xfade_pairs[1].right.item)
  end

  return det
end

F.FADE_IN_TAG  = FADE_IN_TAG
F.FADE_OUT_TAG = FADE_OUT_TAG
F.XFADE_TAG    = XFADE_TAG

return F
