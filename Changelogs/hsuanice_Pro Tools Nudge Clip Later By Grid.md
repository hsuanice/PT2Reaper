# hsuanice_Pro Tools Nudge Clip Later By Grid.lua — Changelog

hsuanice_Pro Tools Nudge Clip Later By Grid

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.11.0 [260509.0041]`).

```text
0.11.0 [260509.0041] - Fix: razor that fully encloses an item now
                       always triggers Case 1 (full position move),
                       regardless of fade presence. Previously a
                       razor wider than the item with fi_len=0 or
                       fo_len=0 was misclassified as Case 2/3/4
                       and got blocked by the fade-len guard
                       ("must equal item width to move"). Same
                       fix applied in detect_case and nudge_item.
0.10.4 [260504.1217] - Add guards to no-razor chain auto-include:
                       * Body-collapse guard on the auto-included partner. Move Later shrinks
                         right partner's body each step (Case 7-like); block when partner's
                         body would reach ≤ 1 grid. Symmetric for Move Earlier on left partner.
                       * Source-bound guard. Move Earlier on right partner decreases its
                         STARTOFFS (could go negative); Move Later on left partner extends
                         its right end past source. Show "cannot extend past clip boundary"
                         warning and freeze.
                       When the guard fires, the selected item itself doesn't move either —
                       razor / TS freeze along with it (so the chain stays in sync).
0.10.3 [260504.1200] - Fix Move Later breaking xfade auto-include: find_right_xfade was being
                       called AFTER shifting the selected item's pos, so for Move Later the
                       new fo_start landed past the partner's pos and the partner wasn't
                       found (Earlier worked because the new fo_start moved into Middle's
                       range). Now both xfade partners are captured BEFORE shifting.
0.10.2 [260504.1151] - Refine v0.10.1 chain auto-include — the previous version recursively
                       pulled in the entire crossfade chain (Left → Middle → Right → ...).
                       Now matches razor-selection semantic: only 1-hop xfade neighbors of
                       the user-selected item are auto-included, and the partner gets an
                       edge-shift (Case 6/7-like) instead of a full position move so its
                       OTHER-side crossfade stays intact.
                       Net result: clicking a single item with crossfade only moves that
                       item + its immediate partner; a 3-item chain no longer drags the far
                       end with it.
0.10.1 [260504.1136] - Two follow-ups to v0.10.0:
                       * No-zone-match razor: previously froze the track ("blocked"). Now falls
                         through as "selection-only move" — razor and TS shift by delta but
                         no item is modified. Fixes "razor in body interior can't Move" bug.
                       * No-razor branch: chain auto-include — when only one item is clicked
                         and Moved, recursively pull any crossfade neighbors into this Move
                         so the whole chain shifts and crossfades stay aligned (instead of
                         partner staying put and overlap shrinking to nothing).
0.10.0 [260504.1104] - Chain-aware Move (Option C, two-phase compute then apply):
                       * Added detect_case() and compute_intent() helpers — these classify
                         each selected item's case and predict its post-Move pos/end.
                       * New main-script intent pre-pass builds intent_pos / intent_end
                         tables for every selected item BEFORE any modification.
                       * sync_left / sync_right now look up partner intent first; falls back
                         to the partner's current pos/end only when the partner is not
                         being processed this Move.
                       * Case 3 Later body / xf_body guards and Case 6 Later xf_body guard
                         now skip when the partner will shift this Move (chain shift keeps
                         crossfade overlap unchanged, body doesn't actually shrink).
                       Fixes 3-item chain Move where Left's body=1 grid would block all
                       further Move Later even though chain shift would preserve it.
0.9.12 [260503.1934] - Fix: TimeMap_curFrameRate return order — fps was being read as the
                       isdrop boolean, causing get_delta() at unit==18 to default to 24
                       (silent) on non-drop projects and crash ("compare number with boolean")
                       on drop-frame projects.
0.9.11 [260422.1820] - Case 3 with left_xf: add Zone C atomic update (la extends/shrinks with item_e_A = fi_end_B).
                       Symmetric to Case 4 with right_xf (v0.9.9). Crossfade stays consistent.
                       Source-bound clamp added for la_take right bound on Later.
0.9.10 [260422.1820] - Case 4: remove STARTOFFS adjustment to fix double-shifted content (was 2*delta, now 1*delta).
                       pos += delta alone shifts content by delta naturally.
0.9.9 [260422.1820] - Case 4 with right_xf: add Zone C atomic update (pos_B and crossfade shift with Bl-end).
                       Previously kept crossfade fixed; now matches PT semantic where I+Bl shifts as a unit
                       and the Bl-end (= pos_B) follows. Crossfade shrinks for Later, grows for Earlier.
                       Source-bound clamp added for xf_take left bound on Earlier.
0.9.8 [260422.1820] - Two-pass processing: dry-run all items first to detect would-be blocks.
                       If any item would block, abort all modifications (prevents partial-modification
                       where one item blocks but another's sync_left/right modifies the blocked item).
                       Case 7 Later: guard now always checks body (not fi) since fi is restored by sync.
0.9.7 [260422.1820] - Pre-capture fade snapshot (fi_len/fo_len) for case detection.
                       sync_right/sync_left modifying another item's fades no longer breaks
                       subsequent items' case detection (fixes C-zone Move Later getting stuck).
                       Case 6 Earlier guard: use body (not fo) since fo is restored by sync_left.
0.9.6 [260422.1820] - nudge_item returns false on no-case-match (razor partially covers item but no zone fully).
                       Main loop: any item blocked overrides track_nudged → razor/TS freeze for that track.
                       Prevents razor drift when razor doesn't perfectly cover any zone.
0.9.5 [260422.1820] - Case 7 Later: split guard by left_xf (fi shrinks if xf, body shrinks otherwise).
                       Case 3 Later with right_xf: guard body and right item's body (xf grows).
0.9.4 [260422.1820] - Case 4 Later guard fix: protect fo (the actually shrinking zone), not buffer.
                       No right_xf: fo >= 2*delta. With right_xf: body >= 2*delta.
0.9.3 [260422.1820] - Zone-preservation guards extended:
                       Case 3 Earlier: fi >= 2*|delta| (and fo >= 2*|delta| with right_xf).
                       Case 6 Earlier: body (no xf) or fo (with xf) >= 2*|delta|.
                       Case 6 Later: right_xf body >= 2*delta (1-grid pattern).
0.9.2 [260422.1820] - Zone-preservation guard refined: adjacent zone (in direction of movement)
                       must stay >= 1 nudge grid after shift. Case 7 Later: body >= 2*delta.
                       Case 4 Later: (fo+body) >= 2*delta (no xf) or body >= 2*delta (with xf).
0.9.1 [260422.1820] - Zone-collapse guard for Case 4/7 Later: prevent fi from extending past item_e
                       (delta > len - fi_len → block); razor freezes via track_nudged sync.
0.9.0 [260422.1820] - Source-bound clamp for Move (two-step PT behavior):
                     Cases 2/3/4/6/7 first clamp delta to source limit; razor follows actual movement
                     via min |actual_delta|; next attempt at the boundary shows the warning.
0.8.5 [260422.1820] - All razors sync: any blocked track freezes all razors and time selection (not per-track)
0.8.4 [260422.1820] - nudge_item returns false on guard block; main loop freezes razor+time-sel when all tracks blocked
0.8.3 [260422.1820] - Case 2: unify Earlier fi_len guard — stops when fi_len exhausted (Zone A consumed) for all xf cases
0.8.2 [260422.1820] - Case 2: remove STARTOFFS change — zone boundary move must not shift audio content
0.8.1 [260422.1820] - Case 2: Zone D stop guard — broaden fo_len guard to cover left_xf-only (no right_xf) Later
0.8.0 [260422.1820] - Case 2: Zone D atomic update (item_e_A shifts with fi_end_B — left crossfade consistent)
                    - Case 2: expanded stop guards covering both Zone B (right_xf) and Zone D (left_xf)
0.7.0 [260422.1728] - Case 2: Zone C atomic update (pos_B shifts with fo_start — crossfade consistent)
                    - Case 2: stop guards — C eating A (Earlier) and crossfade vanishing (Later)
                    - Case 4: don't change fo_len when right crossfade exists (right edge fixed)
                    - Case 6: stop guard — Later can't let C eat right item's clip body
0.5.0 [260422.1711] - Use effective fades (AUTO overrides manual) for coverage and sync
0.4.0 [260421.1214] - Crossfade-aware nudge via NudgeEdge module
0.3.0 [260419.1806] - Rewrite: full PT selection-aware nudge logic
0.2.0 [260418.1931] - ApplyNudge via PT_Nudge library
```

