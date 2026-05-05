-- @description hsuanice_Pro Tools Create Fades
-- @version 0.7.2 [260505.1945]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Create Fades**
--
--   Auto-detects fade type from time selection + items:
--   - ts before item start, te inside item  → Fade In
--   - ts inside item, te after item end     → Fade Out
--   - items overlap, ts inside overlap area → Crossfade
--   - ts≈first item start AND te≈last item end → Batch (all three)
--
--   Mac shortcut (PT): Command + F
--
-- @changelog
--   0.7.2 [260505.1945]
--     - Fix xfade position when razor/TS isn't centered on the items'
--       touching point. Previous behavior centered the new overlap
--       symmetrically around the OLD boundary using only the selection
--       LENGTH, which offset the xfade by half the asymmetry (visible
--       as ~half a frame off when razor isn't symmetrically placed).
--       Now uses the selection BOUNDS (sel_start/sel_end from the
--       library's detect_create_targets) to position the xfade exactly
--       at the selection: left.fin = sel_end, right.pos = sel_start.
--   0.7.1 [260505.1840]
--     - Replace the single "Unit: ms/frame" toggle button with two
--       mutually-exclusive checkboxes ("ms" and "frame") in the lower-left.
--       Click a checkbox to switch unit; the other unchecks. Same conversion
--       behavior — values are recomputed so the physical length is preserved.
--   0.7.0 [260505.1815]
--     - Add length-unit toggle (ms / frame). Click the "Unit:" button
--       (left of Cancel/OK) to swap. Field labels update to "(ms)" or
--       "(frame)". Toggling converts displayed values so the physical
--       length is preserved (uses project frame rate from
--       TimeMap_curFrameRate). Useful for sub-frame-accurate fades —
--       e.g. type "1" in frame mode for a single-frame fade. Unit
--       choice and per-field values are persisted in ExtState alongside
--       the existing shape/ms keys, so "Execute Crossfade Last Setting"
--       sees them too.
--     - Tab now cycles between length input fields (commits current,
--       jumps to next, wraps to the first). Enter still commits and
--       exits editing mode.
--   0.6.4 [260505.1745]
--     - Generalize the single-category shape-only rule across batch detection.
--       When the detected set is all fade-in OR all fade-out OR all crossfade
--       (only one of the three types non-empty), GUI drops the ms field and
--       lengths come from the selection — same UX as the single-item path.
--       Per-item lengths: fade-in = sel_end - item.pos; fade-out = item.fin -
--       sel_start; crossfade = sel_end - sel_start. Mixed-type batch (e.g.
--       fade-in + fade-out) keeps the batch UI with ms fields.
--   0.6.3 [260505.1730]
--     - Crossfade-only mode: when a razor or time selection is present, the
--       crossfade length is now adjusted to match the selection length
--       (mirrors fade-in/fade-out shape-only behavior). Items are
--       extended/shrunk symmetrically by the existing apply geometry path
--       to reach the target overlap. Falls back to the existing overlap if
--       there's no selection (items-only mode).
--   0.6.2 [260505.1715]
--     - Preserve razor edits across apply (some fade actions clear razor as
--       a side effect). Snapshot via F.snapshot_razors() at start, restore
--       via F.restore_razors() at end. Time selection was already preserved.
--   0.6.1 [260505.1700]
--     - Crossfade-only mode now hides the length (ms) input field and just
--       uses the existing overlap as the crossfade length. The shape radio
--       is the only control. Mirrors the existing Fade-In-only / Fade-Out-
--       only shape-only behavior. (Triggers when xfade_pairs > 0 and there
--       are no separate fade-in/fade-out items in the detected set.)
--   0.6.0 [260505.1608]
--     - Refactor: chunk parsing / shape detection / shape writing now live
--       in Library/hsuanice_PT_Fades.lua (shared with Apply Next/Previous,
--       Execute Crossfade Last Setting, Delete Fades). No behavior change in
--       this script — all helpers delegate to the library.
--     - Save fadein_shape / xfade_shape / fadeout_shape to ExtState alongside
--       the existing ms fields, so "Execute Crossfade Last Setting" can
--       re-apply the same shape without showing the GUI.
--   0.5.3 [260505.1313]
--     - Fix Slight S-curve crossfade rendering as Linear: the flag field in
--       FADEINNEW/FADEOUTNEW is a continuous S-curve INTENSITY, not a binary
--       Slight/Sharp marker. REAPER renders type=12 with flag=0 as Linear.
--       Confirmed via DUMP G (REAPER native 41533 Slight S-curve):
--         FADEINNEW 10 0 0 12 0 0.5  (flag = 0.5 for Slight)
--         FADEINNEW 10 0 0 12 0 1    (flag = 1   for Sharp, from earlier dump)
--       Updated build_new_line FLAG map: shape 6 → 0.5, shape 7 → 1.
--       Updated classify_new_shape detection threshold to 0.75 so flag values
--       in the Slight range (0.5) classify as 6, and Sharp range (1) as 7.
--   0.5.2 [260505.1236]
--     - Fix: multi-pair selection across different tracks didn't detect any
--       crossfade pairs. The xfade-pair check was iterating list-adjacent
--       items (sorted by position globally), so two items on different tracks
--       interleaved by position got skipped. Now groups items by track first,
--       then checks position-adjacency within each track.
--     - Fix: applying a crossfade to touching items (no prior overlap) only
--       extended the items but produced no visible fade. REAPER does NOT
--       auto-compute D_FADEIN/OUTLEN_AUTO from item overlap when geometry is
--       set via API (only XFADE_CMDS do that). Now sets D_FADEOUTLEN_AUTO
--       (left) and D_FADEINLEN_AUTO (right) directly to xlen so the visible
--       auto-fade has the correct length.
--     - Known minor issue: when an existing fade-in/out is set to Sharp
--       S-curve (7) via REAPER's manual fade actions and the script is
--       reopened, the GUI may pre-select Slight S-curve (6) instead of 7
--       in some cases. The detection logic for the legacy 5.x fractional
--       encoding works in most cases but may have edge cases with how
--       different REAPER builds round/store the fractional value. Doesn't
--       affect functionality — apply still produces the chosen shape.
--   0.5.1 [260505.1225]
--     - Fix Sharp S-curve (7) detection for fade-in / fade-out: REAPER 7.71+
--       encodes Sharp S-curve in the legacy FADEIN/FADEOUT line as the
--       fractional value 5.1 (not 6 as the simple 0..6 encoding would suggest);
--       Slight S-curve stays at integer 5. classify_legacy_shape() now treats
--       any 5.x with x>0 as shape 7. Crossfade detection (FADEINNEW/FADEOUTNEW)
--       was already correct via the flag field — this fix only affects the
--       legacy line read for non-crossfade fade-in / fade-out.
--   0.5.0 [260504.2356]
--     - Crossfade detect + apply rewritten to use FADEINNEW/FADEOUTNEW chunk
--       lines (the "NEW" auto-fade format), discovered via full chunk dumps.
--       Previous v0.4.x wrote the legacy FADEIN/FADEOUT lines, which REAPER
--       ignores for the visible auto-fade shape — so picking a shape did
--       nothing visually.
--     - FADEINNEW/FADEOUTNEW format: <a> <b> <c> <type> <curv> <flag>
--         type 10 = exponential, 11 = constant power (Slight Convex / Eq.P.),
--         12 = s-curve. curv = -1..+1 (no sign flip between in/out, unlike
--         legacy). flag = 1 only for Sharp S-curve (the missing distinction
--         between shape 6 and 7 we couldn't find before).
--     - Sharp S-curve (7) is now fully supported for crossfades — it writes
--       type=12 curv=0 flag=1, which REAPER renders distinctly from Slight
--       S-curve (type=12 curv=0 flag=0).
--     - Detection precedence: shape_from_new_line() (NEW format) takes
--       priority over the legacy FADEIN/FADEOUT line. Falls back to legacy
--       only if the NEW line is missing or describes "no auto-fade".
--   0.4.2 [260504.2328]
--     - Confirmed via dump: REAPER normalizes type=12 (S-curve) chunks back
--       to curv=0 even when we write a non-zero curvature, so the v0.4.1
--       attempt to round-trip Sharp S-curve via curvature failed. Reverted:
--       crossfade apply now writes curv=0 for both shape 6 and 7 (they are
--       functionally identical for crossfades), and detect always returns
--       shape 6 for type=12. Shape 7 remains in the GUI because fade-in /
--       fade-out paths DO distinguish 6 vs 7 via FADEIN_CMDS / FADEOUT_CMDS
--       (the simple field1=0..6 encoding preserves the distinction there).
--   0.4.1 [260504.2255]
--     - Sharp S-curve (7) experimental fix (later reverted in 0.4.2).
--   0.4.0 [260504.2238]
--     - Crossfade detect + apply rewritten based on actual chunk dump.
--       REAPER's FADEIN/FADEOUT chunk line uses TWO different encodings:
--         FADEIN_CMDS / FADEOUT_CMDS (manual): field1 = 0..6 (PT shape - 1)
--         XFADE_CMDS (crossfade):              field1 = 10/11/12, field6 = curvature
--       Field layout (7 tokens): <type> <manual_len> <auto_len> 0 <flag> <curv> <dir>
--       type 10 = exponential (curvature -1..+1); type 11 = constant power
--       (Slight Convex / Equal Power); type 12 = s-curve. Curvature sign flips
--       between FADEIN (right side) and FADEOUT (left side) of a crossfade.
--     - Detect: classify_chunk_shape() now handles both encodings and returns
--       the correct GUI shape (1..7) for crossfades. Previous v0.3.11/12 only
--       worked for simple fades.
--     - Apply: stop using XFADE_CMDS (41528-41533, 41838) — those actions are
--       unreliable and often only update the right item's fade-in. The script
--       now writes the FADEOUT line on the left item and FADEIN line on the
--       right item directly via SetItemStateChunk, which consistently sets
--       both sides of the visible crossfade.
--     - Note: XFADE actions don't distinguish Slight S-curve (6) from Sharp
--       S-curve (7) — both produce type=12, curv=0 in the chunk. They render
--       identically until REAPER provides separate native encoding.
--   0.3.11 [260504.1957]
--     - Fix shape auto-detect: REAPER's GetMediaItemInfo_Value(C_FADEINSHAPE) returns
--       garbage on 7.71+ (encoded internal values like 10/12 instead of the 0-6 shape
--       index). Switched to parsing the item state chunk's FADEIN/FADEOUT line, which
--       reliably gives the correct shape index (0-6 mapped to GUI options 1-7).
--   0.3.10 [260504.1910]
--     - GUI: pre-select radio buttons to match the existing fade shape on the
--       selected items (was meant to work via existing_xxx_shape lookup, but now
--       has a baseline read from items[1] so it always reflects current state
--       even when the scenario-specific fadein/fadeout list is empty).
--   0.3.9 [260504.1859]
--     - GUI: rename SHAPE_NAMES to match REAPER 7.71's renamed fade shape actions:
--       1=Linear, 2=Slight Convex (Equal Power), 3=Slight Concave,
--       4=Sharp Convex, 5=Sharp Concave, 6=Slight S-Curve, 7=Sharp S-Curve.
--       Action command IDs and shape index mapping unchanged — display only.
--   0.3.8 [260418.1035]
--     - Fix: xfade detection only pairs items on the same track
--   0.3.7 [260418.1027]
--     - Fix: set xfade length before AND after action to prevent shape reset
--   0.3.6 [260418.1013]
--     - Fix: existing overlap resize — adjust item boundaries when xfade length changes
--     - Fix: touching uses extend by half each side; overlap uses same approach
--   0.3.5 [260417.2041]
--     - Fix: shape-only mode reads existing fadeout length instead of using 10ms fallback
--     - Fix: xfade length logic: batch=ms, real overlap=overlap, touching=existing or default
--   0.3.4 [260417.2028]
--     - Fix: call UpdateArrange after extending touching items before applying xfade shape
--     - Fix: re-apply xfade length after action call
--   0.3.3 [260417.2018]
--     - Fix: xfade boundaries excluded from fadein/fadeout lists (no duplicate settings)
--     - Fix: same exclusion applied to no-selection case
--   0.3.2 [260417.2013]
--     - Fix: XFADE_GAP=5ms for touch detection (was EPS=0.1ms, too small for sample-level gaps)
--     - Fix: touching flag based on gap>=0 not overlap<EPS
--   0.3.1 [260417.2006]
--     - Fix: clicking new input field commits previous field first
--     - Fix: clicking input field clears to empty (type to replace)
--     - Fix: commit_field keeps old value when nothing typed
--     - Fix: batch mode checks each item individually for fade in/out
--   0.3.0 [260417.1946]
--     - Rewrite detect: Razor > Time Sel > Item Sel priority
--     - Single boundary: use selection length, shape-only UI (no ms field)
--     - Multiple items or xfade: batch UI with ms fields
--     - No selection: batch UI, ms from settings
--     - Fix: xfade length uses selection/overlap in shape-only mode
--     - Fix: apply respects use_ms flag per fade item
--   0.2.6 [260417.1848]
--     - Fix: batch detection uses covers_start+covers_end (not exact match)
--     - Fix: no-time-sel always adds all items to list (creates new fades if none exist)
--     - Fix: multiple items with razor/time > item span now detected correctly
--     - Fix: touch+multiple items now shows full batch UI
--     - Fix: xfade length in apply correctly uses S.xfade_ms in batch mode
--   0.2.5 [260417.1836]
--     - Fix: commit_field moved to frame scope (was inside batch block, invisible to OK button)
--   0.2.4 [260417.1831]
--     - Fix: click-outside uses mouse-up edge (just_released) not held state
--     - Fix: commit keeps current value if input is invalid/empty
--     - Add: ExtState remembers last ms values across sessions
--   0.2.3 [260417.1828]
--     - Fix: Type 5 = t^4 (steeper concave, more arched than Type 3)
--   0.2.2 [260417.1708]
--     - Fix: Type 2 = 1-(1-t)^2 (fast start); Type 4 = very fast start; Type 5 = asymmetric S
--   0.2.1 [260417.1703]
--     - Fix: Type 6 = gentle S-curve (smooth step); Type 7 = steeper S
--   0.2.0 [260417.1702]
--     - Fix: curve_y rewritten to match actual Reaper visual shapes from screenshot
--     - Fix: shape names updated (Type 1=Linear, Type 2=Equal Power, rest=Type N)
--   0.1.9 [260417.1656]
--     - Fix: remove D_FADEINDIR override — just call action, let Reaper set shape correctly
--     - Fix: remove SHAPE_DIR table (unnecessary)
--     - Fix: shape names simplified to Type 1-7 to match Reaper action names
--   0.1.8 [260417.1648]
--     - Confirmed: Fade Out (41521-41526,41837) and Crossfade (41528-41533,41838)
--       share same shape order as Fade In — no command changes needed
--     - Fade Out preview correctly mirrors Fade In (1-t transform)
--     - Crossfade preview shows both curves crossing
--   0.1.7 [260417.1640]
--     - Fix: correct shape order from visual testing (S-Curve=type7, Fast Start=type3, etc.)
--     - Fix: SHAPE_DIR updated to match actual Reaper storage values
--     - Fix: curve_y preview corrected for all 7 shapes
--   0.1.6 [260417.1624]
--     - Fix: SHAPE_DIR corrected from visual testing (Fast Start/End swapped, S-Curve dir=0)
--     - Fix: curve_y preview matches actual Reaper visual output
--   0.1.5 [260417.1609]
--     - Fix: set D_FADEINDIR/D_FADEOUTDIR per shape after action call
--     - Fix: fade in length detection (allow te at item end)
--     - Fix: set length after action (not before)
--     - Fix: curve_y matches actual Reaper shape behaviour
--     - Fix: better shape names
--   0.1.4 [260417.1511]
--     - Fix: use detected time sel length for fade, not batch_ms
--     - Fix: batch mode has 3 separate editable length fields
--     - Fix: ESC/Enter won't close window while editing a field
--   0.1.3 [260417.1302]
--     - Fix: gfx.moveto does not exist; use gfx.line for curve drawing
--   0.1.2 [260417.1255]
--     - Fix: rewrite detection logic based on actual PT usage patterns
--     - Fix: fade in = ts before/at item start; fade out = te after/at item end
--   0.1.1 [260417.1232]
--     - Fix: proper defer-based GFX loop
--   0.1.0 [260417.1229]
--     - Initial release

local r = reaper

-- Load PT_Fades library (shared with Apply Next/Previous Fade Shape, Execute
-- Crossfade Last Setting, Delete Fades, etc.)
local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local F = dofile(_dir .. '../Library/hsuanice_PT_Fades.lua')
if not F then
  reaper.ShowMessageBox("Could not load Library/hsuanice_PT_Fades.lua", "Create Fades", 0)
  return
end

local FADE_IN  = "fade_in"
local FADE_OUT = "fade_out"
local XFADE    = "crossfade"
local EPS       = F.EPS
local XFADE_GAP = F.XFADE_GAP

local SHAPE_NAMES  = F.SHAPE_NAMES
local FADEIN_CMDS  = F.FADEIN_CMDS
local FADEOUT_CMDS = F.FADEOUT_CMDS

-- Aliases for shape detection / writing (delegated to library).
local existing_fadein_shape  = F.existing_fadein_shape
local existing_fadeout_shape = F.existing_fadeout_shape
local patch_xfade_new        = F.patch_xfade_new

-- ============================================================
-- DETECTION
-- ============================================================
local get_sel_items = F.get_sel_items

local function get_razor_range()
  -- Get the union of all track-level razor areas (guid="")
  local min_pos, max_end = math.huge, -math.huge
  local found = false
  for ti = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      local toks = {}
      for t in s:gmatch("%S+") do toks[#toks+1] = t end
      for i = 1, #toks-2, 3 do
        local rs = tonumber(toks[i])
        local re = tonumber(toks[i+1])
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

local function detect()
  local items = get_sel_items()

  local det = {
    types={}, items=items,
    fadein_items={}, fadeout_items={}, xfade_pairs={},
    def_fadein_shape=1, def_fadeout_shape=1, def_xfade_shape=2,
    def_batch_ms=10,
    -- show_length: true = show ms fields in UI; false = shape only
    show_length=true,
  }

  if #items == 0 then return det end

  -- Load remembered batch ms
  local EXT_SEC = "hsuanice_PT2Reaper_CreateFades"
  local function remembered_ms(key)
    local v = tonumber(r.GetExtState(EXT_SEC, key))
    return (v and v > 0) and math.floor(v) or det.def_batch_ms
  end
  det.def_batch_ms = remembered_ms("fadein_ms")

  -- Priority: Razor > Time Selection > Item Selection
  local sel_start, sel_end
  local rz_s, rz_e = get_razor_range()
  local ts, te = r.GetSet_LoopTimeRange(false,false,0,0,false)
  local has_ts = te > ts + EPS

  if rz_s then
    sel_start, sel_end = rz_s, rz_e
  elseif has_ts then
    sel_start, sel_end = ts, te
  end

  -- Check xfade pairs per-track. Items are globally sorted by position, so
  -- adjacent-in-list items on different tracks would be wrongly skipped if we
  -- only paired list-adjacent items. Group by track first, then check
  -- position-adjacency within each track.
  do
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
        if gap <= XFADE_GAP then
          local overlap = math.max(0, a.fin - b.pos)
          det.xfade_pairs[#det.xfade_pairs+1] = {
            left=a, right=b, overlap=overlap,
            touching=(gap >= -EPS)
          }
        end
      end
    end
  end

  local has_xfade = #det.xfade_pairs > 0
  local is_multi  = #items > 1

  if sel_start then
    -- We have a selection range (razor or time sel)
    local first = items[1]
    local last  = items[#items]

    -- Determine if this is a "boundary" selection (single edge only)
    -- or a "full coverage" selection (batch)
    local covers_first_start = sel_start <= first.pos + EPS
    local covers_last_end    = sel_end   >= last.fin  - EPS

    if is_multi or has_xfade then
      -- Multiple items: batch UI
      det.show_length = true

      -- Build sets of items that are xfade left/right edges
      -- so we don't add fadein/fadeout on xfade boundaries
      local is_xfade_right = {}  -- item.item pointer → true if it's the right side of an xfade
      local is_xfade_left  = {}  -- item.item pointer → true if it's the left side of an xfade
      for _, pair in ipairs(det.xfade_pairs) do
        is_xfade_left[pair.left.item]   = true  -- left item's right edge = xfade
        is_xfade_right[pair.right.item] = true  -- right item's left edge = xfade
      end

      -- Check each item individually for fade in/out
      -- Skip edges that are part of a crossfade
      for _, it in ipairs(items) do
        local ts_at_start = sel_start <= it.pos + EPS
        local te_at_end   = sel_end   >= it.fin  - EPS
        local te_inside   = sel_end   >  it.pos + EPS and sel_end < it.fin - EPS
        local ts_inside   = sel_start >  it.pos + EPS and sel_start < it.fin - EPS

        -- Fade In: selection covers this item's start
        -- But skip if this item's left edge is part of a crossfade
        if ts_at_start and (te_inside or te_at_end) then
          if not is_xfade_right[it.item] then
            det.fadein_items[#det.fadein_items+1] = {item=it, len=nil, use_ms=true}
          end
        end
        -- Fade Out: selection covers this item's end
        -- But skip if this item's right edge is part of a crossfade
        if te_at_end and (ts_inside or ts_at_start) then
          if not is_xfade_left[it.item] then
            det.fadeout_items[#det.fadeout_items+1] = {item=it, len=nil, use_ms=true}
          end
        end
      end

    else
      -- Single item
      local it = items[1]
      local ts_at_start = sel_start <= it.pos + EPS
      local te_at_end   = sel_end   >= it.fin  - EPS
      local te_inside   = sel_end   >  it.pos + EPS and sel_end < it.fin - EPS
      local ts_inside   = sel_start >  it.pos + EPS and sel_start < it.fin - EPS

      if ts_at_start and te_inside then
        -- Selection covers item start → fade in, length = sel_end - item.pos
        det.fadein_items[#det.fadein_items+1] = {item=it, len=sel_end - it.pos, use_ms=false}
        det.show_length = false  -- shape only

      elseif ts_inside and te_at_end then
        -- Selection covers item end → fade out, length = item.fin - sel_start
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=it.fin - sel_start, use_ms=false}
        det.show_length = false  -- shape only

      elseif ts_at_start and te_at_end then
        -- Full item coverage → fade in + fade out with ms
        det.fadein_items[#det.fadein_items+1]   = {item=it, len=nil, use_ms=true}
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=nil, use_ms=true}
        det.show_length = true

      else
        -- Selection inside item (no boundary) → shape only, use existing fade lengths
        local fi_len = r.GetMediaItemInfo_Value(it.item,"D_FADEINLEN")
        local fo_len = r.GetMediaItemInfo_Value(it.item,"D_FADEOUTLEN")
        if fi_len > EPS then
          det.fadein_items[#det.fadein_items+1]   = {item=it, len=fi_len, use_ms=false}
        end
        if fo_len > EPS then
          det.fadeout_items[#det.fadeout_items+1] = {item=it, len=fo_len, use_ms=false}
        end
        det.show_length = false  -- shape only
      end
    end

  else
    -- No selection: item selection only → batch UI with ms
    det.show_length = true

    local is_xfade_right = {}
    local is_xfade_left  = {}
    for _, pair in ipairs(det.xfade_pairs) do
      is_xfade_left[pair.left.item]   = true
      is_xfade_right[pair.right.item] = true
    end

    for _, it in ipairs(items) do
      local fi_len = r.GetMediaItemInfo_Value(it.item,"D_FADEINLEN")
      local fo_len = r.GetMediaItemInfo_Value(it.item,"D_FADEOUTLEN")
      if not is_xfade_right[it.item] then
        det.fadein_items[#det.fadein_items+1]   = {item=it, len=fi_len > EPS and fi_len or nil, use_ms=true}
      end
      if not is_xfade_left[it.item] then
        det.fadeout_items[#det.fadeout_items+1] = {item=it, len=fo_len > EPS and fo_len or nil, use_ms=true}
      end
    end
  end

  -- Single-category batch: when the detected set is all fade-in, all fade-out,
  -- OR all crossfade (only one of the three types is non-empty), drop the
  -- ms input field and derive lengths from the selection — same UX as the
  -- single-item shape-only path. Mixed-type batch (e.g. fade-in + fade-out)
  -- keeps the batch UI with ms fields so the user can set each independently.
  local n_in   = #det.fadein_items
  local n_out  = #det.fadeout_items
  local n_x    = #det.xfade_pairs
  local n_cats = (n_in > 0 and 1 or 0) + (n_out > 0 and 1 or 0) + (n_x > 0 and 1 or 0)
  if n_cats == 1 and sel_start and sel_end and (sel_end - sel_start) > EPS then
    det.show_length = false
    for _, fi in ipairs(det.fadein_items) do
      fi.len = sel_end - fi.item.pos
      fi.use_ms = false
    end
    for _, fo in ipairs(det.fadeout_items) do
      fo.len = fo.item.fin - sel_start
      fo.use_ms = false
    end
    if n_x > 0 then
      det.sel_xlen = sel_end - sel_start
    end
  end

  -- Build types list
  if #det.fadein_items  > 0 then det.types[#det.types+1] = FADE_IN  end
  if #det.xfade_pairs   > 0 then det.types[#det.types+1] = XFADE   end
  if #det.fadeout_items > 0 then det.types[#det.types+1] = FADE_OUT end

  -- Defaults from existing fades.
  -- First, baseline from the very first selected item (covers edge cases where the
  -- detected fadein_items/fadeout_items lists end up empty but the panel is still shown).
  if items[1] then
    det.def_fadein_shape  = existing_fadein_shape(items[1].item)
    det.def_fadeout_shape = existing_fadeout_shape(items[1].item)
  end
  -- Then refine from the actual scenario's representative item, if available.
  if #det.fadein_items  > 0 then
    det.def_fadein_shape  = existing_fadein_shape(det.fadein_items[1].item.item)
  end
  if #det.fadeout_items > 0 then
    det.def_fadeout_shape = existing_fadeout_shape(det.fadeout_items[1].item.item)
  end
  if #det.xfade_pairs   > 0 then
    -- Crossfade shape lives on the right item's fade-in (and the left's fade-out matches).
    det.def_xfade_shape   = existing_fadein_shape(det.xfade_pairs[1].right.item)
  end

  return det
end

-- ============================================================
-- APPLY
-- ============================================================
local function apply(det, S)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- Snapshot razor edits up-front; some fade actions clear them as a side
  -- effect. Time selection is left alone (REAPER doesn't clear it). Item
  -- selection is restored explicitly below.
  local razor_snap = F.snapshot_razors()

  local function sel_only(item)
    r.Main_OnCommand(40289,0)
    r.SetMediaItemSelected(item,true)
  end

  -- Convert a typed length value (S.*_ms) to seconds based on S.length_unit.
  local function to_seconds(v)
    if not v then return nil end
    if S.length_unit == "frame" then
      local fr = r.TimeMap_curFrameRate(0) or 24
      if fr <= 0 then fr = 24 end
      return v / fr
    end
    return v / 1000.0
  end

  local is_batch = det.show_length  -- show_length = has ms fields in UI

  for _, fi in ipairs(det.fadein_items) do
    local item = fi.item.item
    local len
    if fi.use_ms then
      len = to_seconds(S.fadein_ms) or fi.len
    else
      len = fi.len  -- use detected length directly
    end
    sel_only(item)
    r.Main_OnCommand(FADEIN_CMDS[S.fadein_shape], 0)
    if len and len > 0 then
      r.SetMediaItemInfo_Value(item, "D_FADEINLEN", len)
    end
  end

  for _, fo in ipairs(det.fadeout_items) do
    local item = fo.item.item
    local len
    if fo.use_ms then
      len = to_seconds(S.fadeout_ms) or fo.len
    else
      len = fo.len
    end
    sel_only(item)
    r.Main_OnCommand(FADEOUT_CMDS[S.fadeout_shape], 0)
    if len and len > 0 then
      r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", len)
    end
  end

  for _, pair in ipairs(det.xfade_pairs) do
    local left  = pair.left.item
    local right = pair.right.item

    -- Determine target xfade length:
    --   batch mode (ms field shown)  → typed ms
    --   crossfade-only with razor/TS → selection length
    --   crossfade-only items mode    → existing overlap
    --   no overlap and no fallback   → existing fade-out length, or 10ms
    local xlen
    if det.show_length and S.xfade_ms then
      xlen = to_seconds(S.xfade_ms)
    elseif det.sel_xlen and det.sel_xlen > EPS then
      xlen = det.sel_xlen
    elseif pair.overlap > EPS then
      xlen = pair.overlap
    else
      local existing = r.GetMediaItemInfo_Value(left, "D_FADEOUTLEN")
      xlen = existing > EPS and existing or 0.010
    end

    local current_overlap = pair.overlap
    local needs_resize = math.abs(xlen - current_overlap) > EPS

    if (pair.touching or needs_resize) and det.sel_start and det.sel_end then
      -- POSITION the xfade exactly at the selection (left.fin = sel_end,
      -- right.pos = sel_start). Avoids the "off by half a frame" issue when
      -- the user's razor isn't centered on the original touching point —
      -- the symmetric center-around-old-boundary path below would offset
      -- the xfade by half the asymmetry.
      local rp   = r.GetMediaItemInfo_Value(right, "D_POSITION")
      local lp   = r.GetMediaItemInfo_Value(left,  "D_POSITION")
      local rt   = r.GetActiveTake(right)
      local ro   = rt and r.GetMediaItemTakeInfo_Value(rt, "D_STARTOFFS") or 0
      local pr   = rt and r.GetMediaItemTakeInfo_Value(rt, "D_PLAYRATE")  or 1.0
      if pr <= 0 then pr = 1.0 end
      local rfin = rp + r.GetMediaItemInfo_Value(right, "D_LENGTH")
      r.SetMediaItemInfo_Value(left,  "D_LENGTH",   det.sel_end - lp)
      r.SetMediaItemInfo_Value(right, "D_POSITION", det.sel_start)
      r.SetMediaItemInfo_Value(right, "D_LENGTH",   rfin - det.sel_start)
      if rt then
        r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS",
          math.max(0, ro + (det.sel_start - rp) * pr))
      end
      r.UpdateArrange()

    elseif pair.touching then
      -- No overlap yet, no selection bounds: extend both items symmetrically.
      local half = xlen * 0.5
      local ll   = r.GetMediaItemInfo_Value(left,  "D_LENGTH")
      local rp   = r.GetMediaItemInfo_Value(right, "D_POSITION")
      local rl   = r.GetMediaItemInfo_Value(right, "D_LENGTH")
      local rt   = r.GetActiveTake(right)
      local ro   = rt and r.GetMediaItemTakeInfo_Value(rt,"D_STARTOFFS") or 0
      r.SetMediaItemInfo_Value(left,  "D_LENGTH",   ll + half)
      r.SetMediaItemInfo_Value(right, "D_POSITION", rp - half)
      r.SetMediaItemInfo_Value(right, "D_LENGTH",   rl + half)
      if rt then r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS", math.max(0, ro - half)) end
      r.UpdateArrange()

    elseif needs_resize then
      -- Already overlapping, no selection bounds: resize symmetrically.
      local diff = xlen - current_overlap
      local half = diff * 0.5
      local ll   = r.GetMediaItemInfo_Value(left,  "D_LENGTH")
      local rp   = r.GetMediaItemInfo_Value(right, "D_POSITION")
      local rl   = r.GetMediaItemInfo_Value(right, "D_LENGTH")
      local rt   = r.GetActiveTake(right)
      local ro   = rt and r.GetMediaItemTakeInfo_Value(rt,"D_STARTOFFS") or 0
      r.SetMediaItemInfo_Value(left,  "D_LENGTH",   ll + half)
      r.SetMediaItemInfo_Value(right, "D_POSITION", rp - half)
      r.SetMediaItemInfo_Value(right, "D_LENGTH",   rl + half)
      if rt then r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS", math.max(0, ro - half)) end
      r.UpdateArrange()
    end

    -- Set the auto-fade lengths directly. REAPER does NOT auto-compute these
    -- from item overlap when geometry is set via API (it does when XFADE_CMDS
    -- run), so we have to write D_FADEIN/OUTLEN_AUTO ourselves — otherwise the
    -- visible auto-fade has length 0 and looks invisible.
    r.SetMediaItemInfo_Value(left,  "D_FADEOUTLEN_AUTO", xlen)
    r.SetMediaItemInfo_Value(right, "D_FADEINLEN_AUTO",  xlen)

    -- Apply crossfade shape by patching both items' FADEINNEW/FADEOUTNEW lines.
    -- The visible auto-fade shape is controlled by these "NEW" chunk lines, NOT
    -- by FADEIN/FADEOUT (legacy) or by XFADE_CMDS actions (which only update the
    -- right item's fade-in).
    patch_xfade_new(left,  "fadeout", S.xfade_shape)
    patch_xfade_new(right, "fadein",  S.xfade_shape)
  end

  -- Restore original selection + razor edits
  r.Main_OnCommand(40289,0)
  for _, it in ipairs(det.items) do
    r.SetMediaItemSelected(it.item,true)
  end
  F.restore_razors(razor_snap)

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Create Fades",-1)
end

-- ============================================================
-- GFX HELPERS
-- ============================================================
local function sc(rv,gv,bv,av)
  gfx.set(rv/255,gv/255,bv/255,(av or 255)/255)
end

local function curve_y(t,s)
  if s==1 then
    return t                                        -- Linear
  elseif s==2 then
    return 1-(1-t)*(1-t)                           -- Equal Power: fast start, slow end
  elseif s==3 then
    return t*t                                      -- slow start, fast end (concave)
  elseif s==4 then
    return 1-(1-t)*(1-t)*(1-t)*(1-t)              -- very fast start
  elseif s==5 then
    return t*t*t*t                             -- steeper concave than type 3 (t^4)
  elseif s==6 then
    return t*t*(3-2*t)                             -- gentle S (smooth step)
  elseif s==7 then
    local t2 = t*t*(3-2*t)
    return t2*t2*(3-2*t2)                          -- steeper S
  end
  return t
end

local function draw_preview(x,y,w,h,shape,ft)
  sc(40,40,40); gfx.rect(x,y,w,h,1)
  sc(85,85,85); gfx.rect(x,y,w,h,0)
  local p=5
  local bx,by,bw,bh = x+p,y+p,w-p*2,h-p*2
  sc(52,52,62); gfx.rect(bx,by,bw,bh,1)
  local function plot(cr,cg,cb,tf)
    sc(cr,cg,cb)
    local prev_px, prev_py = nil, nil
    for i=0,bw-1 do
      local t=i/(bw-1)
      local cy=curve_y(tf(t),shape)
      local px=bx+i; local py=by+bh-math.floor(cy*bh)
      if prev_px then gfx.line(prev_px,prev_py,px,py,1) end
      prev_px=px; prev_py=py
    end
  end
  if ft==FADE_IN  then plot(255,80,80,  function(t) return t   end)
  elseif ft==FADE_OUT then plot(80,100,255, function(t) return 1-t end)
  else
    plot(80,100,255, function(t) return 1-t end)
    plot(255,80,80,  function(t) return t   end)
  end
end

local function draw_radio(x,y,w,options,selected)
  local ih=22; local rs=8; local clicked=nil
  local mx,my,mb = gfx.mouse_x,gfx.mouse_y,gfx.mouse_cap&1
  gfx.setfont(1,"Arial",12)
  for i,opt in ipairs(options) do
    local iy=y+(i-1)*ih
    local rx,ry=x+4,iy+ih/2-rs/2
    sc(165,165,165); gfx.circle(rx+rs/2,ry+rs/2,rs/2,false,true)
    if i==selected then sc(75,145,255); gfx.circle(rx+rs/2,ry+rs/2,rs/2-2,true,true) end
    sc(210,210,210); gfx.x=rx+rs+5; gfx.y=iy+4; gfx.drawstr(opt)
    if mb==1 and mx>=x and mx<=x+w and my>=iy and my<iy+ih then clicked=i end
  end
  return clicked
end

local function draw_btn(x,y,w,h,lbl,hc,nc)
  local mx,my,mb = gfx.mouse_x,gfx.mouse_y,gfx.mouse_cap&1
  local hover = mx>=x and mx<=x+w and my>=y and my<=y+h
  local c = hover and (hc or {80,120,200}) or (nc or {58,58,58})
  sc(table.unpack(c)); gfx.rect(x,y,w,h,1)
  sc(120,120,120);     gfx.rect(x,y,w,h,0)
  sc(220,220,220); gfx.setfont(1,"Arial",13)
  local sw=gfx.measurestr(lbl)
  gfx.x=x+w/2-sw/2; gfx.y=y+h/2-7; gfx.drawstr(lbl)
  return hover and mb==1
end

-- Small checkbox + label. Returns true on click. Click hit area covers box+label.
local function draw_check(x, y, label, checked)
  local mx, my, mb = gfx.mouse_x, gfx.mouse_y, gfx.mouse_cap & 1
  local cs = 14
  gfx.setfont(1,"Arial",12)
  local label_w = gfx.measurestr(label)
  local total_w = cs + 6 + label_w
  local hover = mx >= x and mx <= x + total_w and my >= y and my <= y + cs
  -- box
  if checked then sc(70,120,210) else sc(28,28,28) end
  gfx.rect(x, y, cs, cs, 1)
  sc(120,120,120); gfx.rect(x, y, cs, cs, 0)
  -- check tick
  if checked then
    sc(255,255,255)
    gfx.line(x+3, y+cs/2,   x+cs/2, y+cs-3)
    gfx.line(x+cs/2, y+cs-3, x+cs-3, y+3)
  end
  -- label
  sc(210,210,210)
  gfx.x = x + cs + 6; gfx.y = y + 1
  gfx.drawstr(label)
  return hover and mb == 1
end

-- ============================================================
-- UI (defer loop)
-- ============================================================
local function run_ui(det)
  if #det.types==0 then
    r.ShowMessageBox(
      "No fade detected.\n\nUsage:\n• Fade In:  time sel starts before item, ends inside\n• Fade Out: time sel starts inside item, ends after\n• Crossfade: select 2 overlapping items\n• Batch:    time sel covers entire item(s) span",
      "Create Fades", 0)
    return
  end

  local types      = det.types
  local show_multi = #types > 1        -- show multiple panels
  local show_len   = det.show_length   -- show ms length fields

  local PANEL_W   = 210
  local PREVIEW_H = 110
  local RADIO_H   = #SHAPE_NAMES * 22
  local PANEL_H   = 24 + PREVIEW_H + 12 + RADIO_H + 8
  local PAD       = 10
  local num       = show_multi and #types or 1
  local WIN_W     = PANEL_W*num + PAD*(num+1)
  local BATCH_ROW = show_len and 36 or 0
  local WIN_H     = PAD + PANEL_H + BATCH_ROW + PAD + 38 + PAD

  local EXT_SEC = "hsuanice_PT2Reaper_CreateFades"

  local function get_remembered_ms(key, fallback)
    local v = tonumber(r.GetExtState(EXT_SEC, key))
    return (v and v > 0) and math.floor(v) or fallback
  end
  local function get_remembered_unit()
    local u = r.GetExtState(EXT_SEC, "length_unit")
    return (u == "frame") and "frame" or "ms"
  end

  local S = {
    fadein_shape  = det.def_fadein_shape,
    fadeout_shape = det.def_fadeout_shape,
    xfade_shape   = det.def_xfade_shape,
    fadein_ms  = get_remembered_ms("fadein_ms",  det.def_batch_ms),
    xfade_ms   = get_remembered_ms("xfade_ms",   det.def_batch_ms),
    fadeout_ms = get_remembered_ms("fadeout_ms",  det.def_batch_ms),
    length_unit = get_remembered_unit(),  -- "ms" or "frame"; values above are in this unit
  }
  -- Only expose ms fields if show_length
  if not show_len then
    S.fadein_ms  = nil
    S.xfade_ms   = nil
    S.fadeout_ms = nil
  end

  -- Save ms values + shapes + unit to ExtState (read by "Execute Crossfade
  -- Last Setting"). Values stored AS TYPED in the chosen unit.
  local function save_ms()
    if S.fadein_ms  then r.SetExtState(EXT_SEC, "fadein_ms",  tostring(S.fadein_ms),  true) end
    if S.xfade_ms   then r.SetExtState(EXT_SEC, "xfade_ms",   tostring(S.xfade_ms),   true) end
    if S.fadeout_ms then r.SetExtState(EXT_SEC, "fadeout_ms", tostring(S.fadeout_ms), true) end
    r.SetExtState(EXT_SEC, "fadein_shape",  tostring(S.fadein_shape),  true)
    r.SetExtState(EXT_SEC, "xfade_shape",   tostring(S.xfade_shape),   true)
    r.SetExtState(EXT_SEC, "fadeout_shape", tostring(S.fadeout_shape), true)
    r.SetExtState(EXT_SEC, "length_unit",   S.length_unit,             true)
  end

  -- Toggle ms <-> frame, converting all field values so the physical length
  -- is preserved across the toggle (ms 100 at 24fps becomes 2 frames, etc).
  local function toggle_unit()
    local fr = r.TimeMap_curFrameRate(0) or 24
    if fr <= 0 then fr = 24 end
    local function conv(v)
      if not v then return nil end
      if S.length_unit == "ms" then
        return math.max(1, math.floor(v / 1000 * fr + 0.5))   -- ms → frame
      else
        return math.max(1, math.floor(v / fr * 1000 + 0.5))   -- frame → ms
      end
    end
    S.fadein_ms  = conv(S.fadein_ms)
    S.xfade_ms   = conv(S.xfade_ms)
    S.fadeout_ms = conv(S.fadeout_ms)
    S.length_unit = (S.length_unit == "ms") and "frame" or "ms"
  end

  -- Which length field is being edited (nil=none)
  local editing_field = nil
  local editing_str   = ""
  local prev_mb = 0  -- track mouse button edge for click-outside commit

  local done=false; local ok_result=false

  gfx.init("Create Fades", WIN_W, WIN_H, 0, 300, 200)

  local function draw_panel(px,py,pt)
    local sk = pt==FADE_IN and "fadein_shape" or pt==FADE_OUT and "fadeout_shape" or "xfade_shape"
    local title = pt==FADE_IN and "Fade In" or pt==FADE_OUT and "Fade Out" or "Crossfade"

    sc(44,44,44); gfx.rect(px,py,PANEL_W,PANEL_H,1)
    sc(72,72,72); gfx.rect(px,py,PANEL_W,PANEL_H,0)

    gfx.setfont(2,"Arial",13,string.byte("b")); sc(200,200,200)
    local tw=gfx.measurestr(title)
    gfx.x=px+PANEL_W/2-tw/2; gfx.y=py+6; gfx.drawstr(title)

    draw_preview(px+6, py+24, PANEL_W-12, PREVIEW_H, S[sk], pt)

    gfx.setfont(1,"Arial",11); sc(145,145,145)
    gfx.x=px+8; gfx.y=py+24+PREVIEW_H+6; gfx.drawstr("Shape:")

    local clicked = draw_radio(px+8, py+24+PREVIEW_H+18, PANEL_W-16, SHAPE_NAMES, S[sk])
    if clicked then S[sk]=clicked end
  end

  local function frame()
    if done then return end
    local char=gfx.getchar()
    if char==-1 then done=true; ok_result=false; return end
    -- Only close on ESC/Enter if not editing a field
    if char==27 and not editing_field then done=true; ok_result=false; return end
    if char==13 and not editing_field then done=true; ok_result=true;  return end

    local cur_mb = gfx.mouse_cap & 1  -- current mouse button state (frame level)

    local function commit_field()
      if not editing_field then return end
      if editing_str ~= "" then
        local v = tonumber(editing_str)
        if v and v > 0 then S[editing_field] = math.floor(v) end
      end
      -- if empty, keep current S value unchanged
      editing_field = nil; editing_str = ""
    end

    sc(30,30,30); gfx.rect(0,0,WIN_W,WIN_H,1)

    if not show_multi then
      draw_panel(PAD, PAD, types[1])
    else
      for i,pt in ipairs(types) do
        draw_panel(PAD+(i-1)*(PANEL_W+PAD), PAD, pt)
      end
    end

    -- Length row (only when show_len=true)
    if show_len then
      local ly = PAD + PANEL_H + 6
      gfx.setfont(1,"Arial",11)

      local field_defs = {}
      for i,pt in ipairs(types) do
        local fk    = pt==FADE_IN and "fadein_ms" or pt==FADE_OUT and "fadeout_ms" or "xfade_ms"
        local label = pt==FADE_IN and "Fade In" or pt==FADE_OUT and "Fade Out" or "XFade"
        local fx    = PAD + (i-1)*(PANEL_W+PAD)
        field_defs[#field_defs+1] = {key=fk, label=label, x=fx}
      end

      local fmx,fmy,fmb = gfx.mouse_x,gfx.mouse_y,cur_mb
      local just_released = (cur_mb==0 and prev_mb==1)

      for _, fd in ipairs(field_defs) do
        sc(145,145,145)
        gfx.x=fd.x; gfx.y=ly+6; gfx.drawstr(fd.label.." ("..S.length_unit.."):")
        local bx=fd.x+86; local bw=54; local bh=20
        local is_ed = (editing_field==fd.key)
        if is_ed then sc(35,45,65) else sc(28,28,28) end
        gfx.rect(bx,ly+2,bw,bh,1)
        if is_ed then sc(80,130,220) else sc(85,85,85) end
        gfx.rect(bx,ly+2,bw,bh,0)
        sc(210,210,210)
        local disp = is_ed and (editing_str.."|") or tostring(S[fd.key])
        local dw=gfx.measurestr(disp)
        gfx.x=bx+bw/2-dw/2; gfx.y=ly+5; gfx.drawstr(disp)
        if fmb==1 and fmx>=bx and fmx<=bx+bw and fmy>=ly+2 and fmy<=ly+2+bh then
          if editing_field~=fd.key then
            commit_field()          -- commit previous field first
            editing_field=fd.key
            editing_str=""          -- clear so user types fresh (select-all behaviour)
          end
        end
      end

      -- Keyboard: digits, backspace, enter to commit, tab to cycle to next field.
      if editing_field and char>0 then
        if char>=48 and char<=57 then
          editing_str=editing_str..string.char(char)
        elseif char==8 and #editing_str>0 then
          editing_str=editing_str:sub(1,-2)
        elseif char==13 then
          commit_field()
        elseif char==9 then
          -- Tab: commit current field, jump to next (cycle through field_defs).
          local cur_key = editing_field
          commit_field()
          for i, fd in ipairs(field_defs) do
            if fd.key == cur_key then
              local next_idx = (i % #field_defs) + 1
              editing_field = field_defs[next_idx].key
              editing_str   = ""
              break
            end
          end
        elseif char==27 then
          editing_field=nil; editing_str=""; char=0
        end
      end
      -- Click outside on mouse-up: commit
      if just_released and editing_field then
        local on_any=false
        for _,fd in ipairs(field_defs) do
          if fmx>=fd.x+86 and fmx<=fd.x+140 and fmy>=ly+2 and fmy<=ly+22 then on_any=true end
        end
        if not on_any then commit_field() end
      end
    end

    local btn_y = WIN_H - PAD - 32
    if draw_btn(WIN_W-PAD-84,    btn_y, 84, 30, "OK",     {55,95,175},{50,50,50}) then
      commit_field()  -- commit any in-progress edit
      done=true; ok_result=true
    end
    if draw_btn(WIN_W-PAD-84-92, btn_y, 84, 30, "Cancel", {100,50,50},{50,50,50}) then
      done=true; ok_result=false
    end
    -- Unit selection: two mutually-exclusive checkboxes (radio behavior).
    -- Only meaningful when length fields are shown.
    if show_len then
      local cy = btn_y + 8
      if draw_check(PAD,      cy, "ms",    S.length_unit == "ms") then
        if S.length_unit ~= "ms"    then commit_field(); toggle_unit() end
      end
      if draw_check(PAD + 60, cy, "frame", S.length_unit == "frame") then
        if S.length_unit ~= "frame" then commit_field(); toggle_unit() end
      end
    end

    prev_mb = cur_mb
    gfx.update()
    if not done then r.defer(frame) end
  end

  r.defer(frame)

  r.atexit(function()
    gfx.quit()
    if ok_result then
      save_ms()
      apply(det, S)
    end
  end)
end

-- ============================================================
-- ENTRY
-- ============================================================
local det = detect()
run_ui(det)