# hsuanice_Pro Tools Create Fades.lua — Changelog

hsuanice_Pro Tools Create Fades

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.7.2 [260505.1945]`).

```text
0.7.2 [260505.1945]
  - Fix xfade position when razor/TS isn't centered on the items'
    touching point. Previous behavior centered the new overlap
    symmetrically around the OLD boundary using only the selection
    LENGTH, which offset the xfade by half the asymmetry (visible
    as ~half a frame off when razor isn't symmetrically placed).
    Now uses the selection BOUNDS (sel_start/sel_end from the
    library's detect_create_targets) to position the xfade exactly
    at the selection: left.fin = sel_end, right.pos = sel_start.
0.7.1 [260505.1840]
  - Replace the single "Unit: ms/frame" toggle button with two
    mutually-exclusive checkboxes ("ms" and "frame") in the lower-left.
    Click a checkbox to switch unit; the other unchecks. Same conversion
    behavior — values are recomputed so the physical length is preserved.
0.7.0 [260505.1815]
  - Add length-unit toggle (ms / frame). Click the "Unit:" button
    (left of Cancel/OK) to swap. Field labels update to "(ms)" or
    "(frame)". Toggling converts displayed values so the physical
    length is preserved (uses project frame rate from
    TimeMap_curFrameRate). Useful for sub-frame-accurate fades —
    e.g. type "1" in frame mode for a single-frame fade. Unit
    choice and per-field values are persisted in ExtState alongside
    the existing shape/ms keys, so "Execute Crossfade Last Setting"
    sees them too.
  - Tab now cycles between length input fields (commits current,
    jumps to next, wraps to the first). Enter still commits and
    exits editing mode.
0.6.4 [260505.1745]
  - Generalize the single-category shape-only rule across batch detection.
    When the detected set is all fade-in OR all fade-out OR all crossfade
    (only one of the three types non-empty), GUI drops the ms field and
    lengths come from the selection — same UX as the single-item path.
    Per-item lengths: fade-in = sel_end - item.pos; fade-out = item.fin -
    sel_start; crossfade = sel_end - sel_start. Mixed-type batch (e.g.
    fade-in + fade-out) keeps the batch UI with ms fields.
0.6.3 [260505.1730]
  - Crossfade-only mode: when a razor or time selection is present, the
    crossfade length is now adjusted to match the selection length
    (mirrors fade-in/fade-out shape-only behavior). Items are
    extended/shrunk symmetrically by the existing apply geometry path
    to reach the target overlap. Falls back to the existing overlap if
    there's no selection (items-only mode).
0.6.2 [260505.1715]
  - Preserve razor edits across apply (some fade actions clear razor as
    a side effect). Snapshot via F.snapshot_razors() at start, restore
    via F.restore_razors() at end. Time selection was already preserved.
0.6.1 [260505.1700]
  - Crossfade-only mode now hides the length (ms) input field and just
    uses the existing overlap as the crossfade length. The shape radio
    is the only control. Mirrors the existing Fade-In-only / Fade-Out-
    only shape-only behavior. (Triggers when xfade_pairs > 0 and there
    are no separate fade-in/fade-out items in the detected set.)
0.6.0 [260505.1608]
  - Refactor: chunk parsing / shape detection / shape writing now live
    in Library/hsuanice_PT_Fades.lua (shared with Apply Next/Previous,
    Execute Crossfade Last Setting, Delete Fades). No behavior change in
    this script — all helpers delegate to the library.
  - Save fadein_shape / xfade_shape / fadeout_shape to ExtState alongside
    the existing ms fields, so "Execute Crossfade Last Setting" can
    re-apply the same shape without showing the GUI.
0.5.3 [260505.1313]
  - Fix Slight S-curve crossfade rendering as Linear: the flag field in
    FADEINNEW/FADEOUTNEW is a continuous S-curve INTENSITY, not a binary
    Slight/Sharp marker. REAPER renders type=12 with flag=0 as Linear.
    Confirmed via DUMP G (REAPER native 41533 Slight S-curve):
      FADEINNEW 10 0 0 12 0 0.5  (flag = 0.5 for Slight)
      FADEINNEW 10 0 0 12 0 1    (flag = 1   for Sharp, from earlier dump)
    Updated build_new_line FLAG map: shape 6 → 0.5, shape 7 → 1.
    Updated classify_new_shape detection threshold to 0.75 so flag values
    in the Slight range (0.5) classify as 6, and Sharp range (1) as 7.
0.5.2 [260505.1236]
  - Fix: multi-pair selection across different tracks didn't detect any
    crossfade pairs. The xfade-pair check was iterating list-adjacent
    items (sorted by position globally), so two items on different tracks
    interleaved by position got skipped. Now groups items by track first,
    then checks position-adjacency within each track.
  - Fix: applying a crossfade to touching items (no prior overlap) only
    extended the items but produced no visible fade. REAPER does NOT
    auto-compute D_FADEIN/OUTLEN_AUTO from item overlap when geometry is
    set via API (only XFADE_CMDS do that). Now sets D_FADEOUTLEN_AUTO
    (left) and D_FADEINLEN_AUTO (right) directly to xlen so the visible
    auto-fade has the correct length.
  - Known minor issue: when an existing fade-in/out is set to Sharp
    S-curve (7) via REAPER's manual fade actions and the script is
    reopened, the GUI may pre-select Slight S-curve (6) instead of 7
    in some cases. The detection logic for the legacy 5.x fractional
    encoding works in most cases but may have edge cases with how
    different REAPER builds round/store the fractional value. Doesn't
    affect functionality — apply still produces the chosen shape.
0.5.1 [260505.1225]
  - Fix Sharp S-curve (7) detection for fade-in / fade-out: REAPER 7.71+
    encodes Sharp S-curve in the legacy FADEIN/FADEOUT line as the
    fractional value 5.1 (not 6 as the simple 0..6 encoding would suggest);
    Slight S-curve stays at integer 5. classify_legacy_shape() now treats
    any 5.x with x>0 as shape 7. Crossfade detection (FADEINNEW/FADEOUTNEW)
    was already correct via the flag field — this fix only affects the
    legacy line read for non-crossfade fade-in / fade-out.
0.5.0 [260504.2356]
  - Crossfade detect + apply rewritten to use FADEINNEW/FADEOUTNEW chunk
    lines (the "NEW" auto-fade format), discovered via full chunk dumps.
    Previous v0.4.x wrote the legacy FADEIN/FADEOUT lines, which REAPER
    ignores for the visible auto-fade shape — so picking a shape did
    nothing visually.
  - FADEINNEW/FADEOUTNEW format: <a> <b> <c> <type> <curv> <flag>
      type 10 = exponential, 11 = constant power (Slight Convex / Eq.P.),
      12 = s-curve. curv = -1..+1 (no sign flip between in/out, unlike
      legacy). flag = 1 only for Sharp S-curve (the missing distinction
      between shape 6 and 7 we couldn't find before).
  - Sharp S-curve (7) is now fully supported for crossfades — it writes
    type=12 curv=0 flag=1, which REAPER renders distinctly from Slight
    S-curve (type=12 curv=0 flag=0).
  - Detection precedence: shape_from_new_line() (NEW format) takes
    priority over the legacy FADEIN/FADEOUT line. Falls back to legacy
    only if the NEW line is missing or describes "no auto-fade".
0.4.2 [260504.2328]
  - Confirmed via dump: REAPER normalizes type=12 (S-curve) chunks back
    to curv=0 even when we write a non-zero curvature, so the v0.4.1
    attempt to round-trip Sharp S-curve via curvature failed. Reverted:
    crossfade apply now writes curv=0 for both shape 6 and 7 (they are
    functionally identical for crossfades), and detect always returns
    shape 6 for type=12. Shape 7 remains in the GUI because fade-in /
    fade-out paths DO distinguish 6 vs 7 via FADEIN_CMDS / FADEOUT_CMDS
    (the simple field1=0..6 encoding preserves the distinction there).
0.4.1 [260504.2255]
  - Sharp S-curve (7) experimental fix (later reverted in 0.4.2).
0.4.0 [260504.2238]
  - Crossfade detect + apply rewritten based on actual chunk dump.
    REAPER's FADEIN/FADEOUT chunk line uses TWO different encodings:
      FADEIN_CMDS / FADEOUT_CMDS (manual): field1 = 0..6 (PT shape - 1)
      XFADE_CMDS (crossfade):              field1 = 10/11/12, field6 = curvature
    Field layout (7 tokens): <type> <manual_len> <auto_len> 0 <flag> <curv> <dir>
    type 10 = exponential (curvature -1..+1); type 11 = constant power
    (Slight Convex / Equal Power); type 12 = s-curve. Curvature sign flips
    between FADEIN (right side) and FADEOUT (left side) of a crossfade.
  - Detect: classify_chunk_shape() now handles both encodings and returns
    the correct GUI shape (1..7) for crossfades. Previous v0.3.11/12 only
    worked for simple fades.
  - Apply: stop using XFADE_CMDS (41528-41533, 41838) — those actions are
    unreliable and often only update the right item's fade-in. The script
    now writes the FADEOUT line on the left item and FADEIN line on the
    right item directly via SetItemStateChunk, which consistently sets
    both sides of the visible crossfade.
  - Note: XFADE actions don't distinguish Slight S-curve (6) from Sharp
    S-curve (7) — both produce type=12, curv=0 in the chunk. They render
    identically until REAPER provides separate native encoding.
0.3.11 [260504.1957]
  - Fix shape auto-detect: REAPER's GetMediaItemInfo_Value(C_FADEINSHAPE) returns
    garbage on 7.71+ (encoded internal values like 10/12 instead of the 0-6 shape
    index). Switched to parsing the item state chunk's FADEIN/FADEOUT line, which
    reliably gives the correct shape index (0-6 mapped to GUI options 1-7).
0.3.10 [260504.1910]
  - GUI: pre-select radio buttons to match the existing fade shape on the
    selected items (was meant to work via existing_xxx_shape lookup, but now
    has a baseline read from items[1] so it always reflects current state
    even when the scenario-specific fadein/fadeout list is empty).
0.3.9 [260504.1859]
  - GUI: rename SHAPE_NAMES to match REAPER 7.71's renamed fade shape actions:
    1=Linear, 2=Slight Convex (Equal Power), 3=Slight Concave,
    4=Sharp Convex, 5=Sharp Concave, 6=Slight S-Curve, 7=Sharp S-Curve.
    Action command IDs and shape index mapping unchanged — display only.
0.3.8 [260418.1035]
  - Fix: xfade detection only pairs items on the same track
0.3.7 [260418.1027]
  - Fix: set xfade length before AND after action to prevent shape reset
0.3.6 [260418.1013]
  - Fix: existing overlap resize — adjust item boundaries when xfade length changes
  - Fix: touching uses extend by half each side; overlap uses same approach
0.3.5 [260417.2041]
  - Fix: shape-only mode reads existing fadeout length instead of using 10ms fallback
  - Fix: xfade length logic: batch=ms, real overlap=overlap, touching=existing or default
0.3.4 [260417.2028]
  - Fix: call UpdateArrange after extending touching items before applying xfade shape
  - Fix: re-apply xfade length after action call
0.3.3 [260417.2018]
  - Fix: xfade boundaries excluded from fadein/fadeout lists (no duplicate settings)
  - Fix: same exclusion applied to no-selection case
0.3.2 [260417.2013]
  - Fix: XFADE_GAP=5ms for touch detection (was EPS=0.1ms, too small for sample-level gaps)
  - Fix: touching flag based on gap>=0 not overlap<EPS
0.3.1 [260417.2006]
  - Fix: clicking new input field commits previous field first
  - Fix: clicking input field clears to empty (type to replace)
  - Fix: commit_field keeps old value when nothing typed
  - Fix: batch mode checks each item individually for fade in/out
0.3.0 [260417.1946]
  - Rewrite detect: Razor > Time Sel > Item Sel priority
  - Single boundary: use selection length, shape-only UI (no ms field)
  - Multiple items or xfade: batch UI with ms fields
  - No selection: batch UI, ms from settings
  - Fix: xfade length uses selection/overlap in shape-only mode
  - Fix: apply respects use_ms flag per fade item
0.2.6 [260417.1848]
  - Fix: batch detection uses covers_start+covers_end (not exact match)
  - Fix: no-time-sel always adds all items to list (creates new fades if none exist)
  - Fix: multiple items with razor/time > item span now detected correctly
  - Fix: touch+multiple items now shows full batch UI
  - Fix: xfade length in apply correctly uses S.xfade_ms in batch mode
0.2.5 [260417.1836]
  - Fix: commit_field moved to frame scope (was inside batch block, invisible to OK button)
0.2.4 [260417.1831]
  - Fix: click-outside uses mouse-up edge (just_released) not held state
  - Fix: commit keeps current value if input is invalid/empty
  - Add: ExtState remembers last ms values across sessions
0.2.3 [260417.1828]
  - Fix: Type 5 = t^4 (steeper concave, more arched than Type 3)
0.2.2 [260417.1708]
  - Fix: Type 2 = 1-(1-t)^2 (fast start); Type 4 = very fast start; Type 5 = asymmetric S
0.2.1 [260417.1703]
  - Fix: Type 6 = gentle S-curve (smooth step); Type 7 = steeper S
0.2.0 [260417.1702]
  - Fix: curve_y rewritten to match actual Reaper visual shapes from screenshot
  - Fix: shape names updated (Type 1=Linear, Type 2=Equal Power, rest=Type N)
0.1.9 [260417.1656]
  - Fix: remove D_FADEINDIR override — just call action, let Reaper set shape correctly
  - Fix: remove SHAPE_DIR table (unnecessary)
  - Fix: shape names simplified to Type 1-7 to match Reaper action names
0.1.8 [260417.1648]
  - Confirmed: Fade Out (41521-41526,41837) and Crossfade (41528-41533,41838)
    share same shape order as Fade In — no command changes needed
  - Fade Out preview correctly mirrors Fade In (1-t transform)
  - Crossfade preview shows both curves crossing
0.1.7 [260417.1640]
  - Fix: correct shape order from visual testing (S-Curve=type7, Fast Start=type3, etc.)
  - Fix: SHAPE_DIR updated to match actual Reaper storage values
  - Fix: curve_y preview corrected for all 7 shapes
0.1.6 [260417.1624]
  - Fix: SHAPE_DIR corrected from visual testing (Fast Start/End swapped, S-Curve dir=0)
  - Fix: curve_y preview matches actual Reaper visual output
0.1.5 [260417.1609]
  - Fix: set D_FADEINDIR/D_FADEOUTDIR per shape after action call
  - Fix: fade in length detection (allow te at item end)
  - Fix: set length after action (not before)
  - Fix: curve_y matches actual Reaper shape behaviour
  - Fix: better shape names
0.1.4 [260417.1511]
  - Fix: use detected time sel length for fade, not batch_ms
  - Fix: batch mode has 3 separate editable length fields
  - Fix: ESC/Enter won't close window while editing a field
0.1.3 [260417.1302]
  - Fix: gfx.moveto does not exist; use gfx.line for curve drawing
0.1.2 [260417.1255]
  - Fix: rewrite detection logic based on actual PT usage patterns
  - Fix: fade in = ts before/at item start; fade out = te after/at item end
0.1.1 [260417.1232]
  - Fix: proper defer-based GFX loop
0.1.0 [260417.1229]
  - Initial release
```

