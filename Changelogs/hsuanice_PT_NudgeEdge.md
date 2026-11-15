# hsuanice_PT_NudgeEdge.lua — Changelog

hsuanice_PT_NudgeEdge — Fade-aware clip edge nudge library

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.20.0 [260509.0105]`).

```text
0.20.0 [260509.0105] - Two fixes for items without fades:
                      * nudge_start P1 (Start Later): guard
                        `(fi_len + fill_amt) <= |delta|` was blocking
                        when fi_len = 0 even though the item had room
                        to shrink. Relaxed: only check fade-in
                        absorption when fi_len > 0; always check the
                        item won't shrink to <= 0.
                      * nudge_end P1 (End Earlier/Later): mirror
                        relax on the fo_len guard. Guard the
                        `set_fo(item, fo_len + total)` write with
                        `if fo_len > EPS` so a fadeless item doesn't
                        sprout an unwanted fade-out.
                      * nudge_start P3 / nudge_end P3: same set_*
                        guards on the current item (the partner xf
                        fade writes were already guarded).
0.19.1 [260430.1135] - nudge_start P2 atomic: add body-collapse guard for Start Earlier (delta>0).
                      Start Earlier shrinks Left's D_LENGTH (atomic step), so Left.body
                      (= len - fi - fo) eventually collapses. Block when Left.body shrinks to ≤ 1 grid.
                      (Pairs with the existing Start Later guard on current item's body.)
0.19.0 [260430.1127] - nudge_start P2 + left xfade partner: add atomic update mirroring nudge_end P2.
                      Modify Right (current item) pos/len/STARTOFFS as before, AND atomically
                      update Left.D_LENGTH so item_e_L follows new fi_end_R (= pos_R + fi_len).
                      Left.pos / D_STARTOFFS / fo_len untouched (Left's content stays in timeline,
                      Left only grows/shrinks on right side). Source-bound clamp on Left's right
                      extension for Start Later. Body-collapse guard for current item (Right) on
                      Start Later.
                      Also: nudge_start else now also skips when right xfade partner is selected
                      (mirrors v0.18.5 left-partner skip), preventing Left from over-shifting razor
                      after Right's P2 atomic.
0.18.6 [260430.1130] - nudge_end P2 atomic: add body-collapse guard for End Later (delta>0).
                      In xfade C-shift, Right.D_LENGTH shrinks each nudge, so Right's body
                      (= len - fi - fo) eventually collapses. Block when body would shrink to 0
                      (preserve at least 1 grid).
0.18.5 [260430.1101] - nudge_start / nudge_end else branch: skip when xfade partner is selected.
                      Returns (sel_s, sel_e, true) so the script's update_razor isn't called and
                      min_actual isn't dragged. Fixes Test 21 where Right's nudge_end fell to
                      else after Left's atomic update and overwrote the item-track razor with
                      sel_e + delta (shrinking razor by an extra grid).
0.18.4 [260430.1052] - nudge_end P2 with right xfade: full PT-aligned atomic C-shift.
                      Left.D_LENGTH += total (item_e shifts).
                      Right.D_POSITION += total (pos/fade-in start shifts).
                      Right.D_LENGTH -= total (end preserved).
                      Right.D_STARTOFFS += total (content stays in timeline).
                      Right.fi_len untouched — fi_end_R = pos + fi_len auto-tracks new item_e_L,
                      keeping both C-start (fo_start_L = pos_R) and C-end (item_e_L = fi_end_R) aligned.
                      Source-bound clamp on Right's STARTOFFS for End Earlier (block if no source room).
0.18.3 [260430.1042] - nudge_end P2 with right xfade: minimal atomic — modify Left.D_LENGTH and
                      atomically shrink/grow Right.fi_len so fi_end_R follows new item_e_L
                      (keeps C-end aligned). Right.D_POSITION / D_LENGTH / D_STARTOFFS untouched
                      so Right's content stays put in timeline. Adds body-collapse guard for
                      End Later (so Right's body doesn't disappear when fi grows).
0.18.2 [260430.1019] - nudge_end P2: revert atomic crossfade shift. Per Test 21 PT clarification,
                      Right xfade partner stays untouched (no pos/len/STARTOFFS change). Only Left.
                      D_LENGTH changes; the crossfade boundary "shifts" because Left's item_e and
                      fo_start move together. Audio content of Right is preserved in timeline.
0.18.1 [260430.1012] - nudge_end P2 + right xfade partner atomic C-shift refinements (per Test 21 expected):
                      * Right.D_LENGTH now compensates so Right.end stays put (Right grows on left side
                        for Earlier, shrinks on left for Later). Previously Right shifted whole.
                      * Selection sel_e shifts by total (no more snap-to-fo_start). Removes the asymmetric
                        Earlier/Later return rule.
                      STARTOFFS still unchanged for now (audio shifts with Right's left edge).
0.18.0 [260425.1216] - nudge_end P2 + right xfade partner: atomic C-shift.
                      When fo_start_L = pos_R (C-start), nudging B-end shifts the entire C-zone:
                      Left.D_LENGTH += total (item_e shifts), Right.D_POSITION += total (pos shifts).
                      Right.D_LENGTH unchanged (Right shifts whole, end follows pos).
                      Fade lengths (fo_L, fi_R) unchanged so C-end = fi_end_R also tracks item_e_L.
                      Selection: Earlier snaps sel_e to new fo_start (selection shrinks to body-only),
                      Later shifts sel_e by total (selection extends with C-zone).
                      Aligns with PT behavior reported in Test 21 ("C 整個平移").
0.17.0 [260425.1018] - Zone-stay guard: each P2/P3 priority now blocks when the next nudge would
                      leave 0 (or less) of the relevant zone-in-selection grid. Preserves "the
                      last 1 grid" of selection inside its original zone in all 4 mirror cases:
                        * nudge_start P2 (Start Later): block when (sel_e - fi_end) <= |delta|
                        * nudge_start P3 (Start Later): block when (sel_e - fo_start) <= |delta|
                        * nudge_end   P2 (End Earlier): block when (fo_start - sel_s) <= |delta|
                        * nudge_end   P3 (End Earlier): block when (fi_end - sel_s) <= |delta|
                      Existing whole-zone collapse guards still cover their cases; this guard
                      protects the per-selection slice that those didn't see.
0.16.0 [260425.0924] - PT-aligned fill semantics: fill+nudge now only triggers at the 6 discrete
                      fade-zone edges (I-start, I-end, C-start, C-end, O-start, O-end). When sel_s
                      (or sel_e for nudge_end) is strictly inside fade interior or body interior,
                      fill_amt is forced to 0 and only delta is applied. Selection return values
                      switched from `boundary - total` to `sel_s/sel_e - total`, so razor/TS sync
                      follows item shift correctly even when fill is skipped.
                      Affected: nudge_start P2 (fade-in interior), nudge_start P3 (body interior),
                      nudge_end P2 (fade-out interior), nudge_end P3 (body interior).
0.15.2 [260424.2213] - nudge_end P3: move "left xfade partner selected" skip check BEFORE the
                      new_fi_len/clip_len_after guards. When partner pre-grew our fi_len, fi_end
                      equals fo_start - 1, so clip_len_after guard would fire (delta>0 case) and
                      return without the skipped marker, dragging min_actual to 0. Fixes Nudge
                      End Later C-end with both crossfade partners selected.
0.15.1 [260424.2207] - Zone-collapse guard now returns skipped marker when selected left-xfade partner pre-shrunk the razor.
                      Fixes Start Later / End Earlier with two crossfade partners selected: second item's
                      zone-collapse guard fired before its skip guard could mark it as skipped, dragging
                      min_actual to 0 and freezing TS + pure-razor sync.
0.15.0 [260422.1820] - nudge_start P1 + nudge_end P1/P3 skip guards return 3rd value `true` (skipped marker).
                      Callers can distinguish "skipped" (partner handled) from "blocked" (zone collapse)
                      for correct sync logic with crossfade pairs.
0.14.0 [260422.1820] - Source-boundary clamp (two-step PT behavior):
                       nudge_start P1/P2/P3 and nudge_end P1/P2/P3 first clamp `total` to the
                       source limit (so a too-large razor still extends to the maximum possible);
                       only the next attempt — when already at the boundary — shows the warning
                       "You cannot extend the fade past the clip boundary." (once per script run).
0.13.0 [260422.1728] - nudge_end P1: skip when right xfade partner is selected and sel_e covers its right edge (prevents double-processing)
                      - nudge_position: fix right/left sync to always set new overlap (was only shrinking, not growing)
0.12.0 [260422.1709] - nudge_end P1: add crossfade guard for End Later — prevent right xfade partner's clip body from disappearing
0.11.0 [260422.1655] - Use effective fades: read D_FADEINLEN_AUTO/D_FADEOUTLEN_AUTO (REAPER auto-crossfade)
                      - get_fi/get_fo: effective = AUTO when non-zero, else manual
                      - set_fi/set_fo: writes to whichever property is currently active
                      - find_left_xfade: use get_fo(other) for detection
                      - find_right_xfade: use get_fo(item); fo_len=0 → search from pos (bare overlap)
                      - All nudge_start/nudge_end fade reads/writes updated to use helpers
                      - P1 skip guard: use get_fo(lxf) + fo_len > EPS check (bare overlaps don't skip)
0.10.0 [260422.1407] - Fix nudge_start else branch: sel_s + delta → sel_s - delta (Earlier was moving RIGHT)
                      - Fix P1 skip guard: only skip item B when sel_s <= lxf_fo_start + EPS
0.9.0 [260422.1407] - find_right_xfade: remove fi_len_B > EPS requirement (broke Zone C when fi_len_B = 0)
                     - find_left_xfade: revert to oe < item_e; add o_fo > EPS filter
0.8.0 [260422.1407] - Zone C atomic update: expand partner pos/len FIRST to prevent REAPER clamping fo_len
                     - nudge_start P1: skip when left xfade partner is selected
0.7.0 [260422.1214] - P1 nudge_start: only grow fi_len if it was already > 0
0.5.0 [260422.1214] - P3/P1 nudge_start: skip partner updates when partner is already selected
0.2.0 [260421.1214] - Expose find_left/right_xfade + nudge_position for Move scripts
0.1.0 [260421.1214] - Initial release
```

