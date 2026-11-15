# hsuanice_Pro Tools Separate Clip At Selection.lua — Changelog

hsuanice_Pro Tools Separate Clip At Selection

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.8.2 [260508.1313]`).

```text
0.8.2 [260508.1313] - Boundary-aware inside-TS selection. When a TS edge
                       split is suppressed because TS_s/TS_e land on a
                       fade-in out point or fade-out in point, the
                       extended Left/Right piece (or the original item,
                       if both edges were suppressed) stays selected
                       instead of being filtered out by the strict
                       "pos >= ts_s AND fin <= ts_e" rule.
0.8.1 [260508.1259] - Boundary cases: select only the surviving item that
                       overlaps the TS (Left for s_at_start, Right for
                       e_at_end). The other survivor is left untouched
                       but unselected.
0.8.0 [260507.1500] - TS-in-crossfade boundary cases now trim BOTH items
                       to fully break the crossfade. TS_s = cf_start:
                       trim Left.fin AND Right.pos to ts_e. TS_e = cf_end:
                       trim Left.fin AND Right.pos to ts_s. Both
                       survivors selected. (Previously only one side was
                       trimmed, leaving an unintended residual overlap.)
0.7.0 [260507.1430] - Don't delete items in TS-in-crossfade cases (fixes
                       regression from 0.6.0 where outer pieces were
                       erased entirely). TS_s = cf_start case: trim Left
                       to ts_e and leave Right alone (manual selection
                       mark). TS_e = cf_end case: mirror. TS strictly
                       inside: v0.5.0 logic + selection filter.
                       Boundary-suppression: split point at fade-in/out
                       boundaries no-ops on that item.
0.6.0 [260507.1330] - TS-in-crossfade resolves to ONE surviving item with
                       deletion of the other (USER REJECTED this).
0.5.0 [260507.1230] - Crossfade-aware (cursor + TS).
0.4.0 [260507.1130] - Asymmetric fade rule + per-mode selection handling.
0.3.0 [260507.1100] - First custom version.
0.2.0 [260506.2030] - Map to native 40196.
0.1.0 [260415.1250] - Stub placeholder created.
```

