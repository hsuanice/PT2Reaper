# hsuanice_Pro Tools Trim Clip To File Boundaries.lua — Changelog

hsuanice_Pro Tools Trim Clip To File Boundaries

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.0 [260504.1620]`).

```text
0.3.0 [260504.1620] - Selection follows extend: razor (per track) and time selection
                       now expand to encompass the items' new extents after trimming
                       to file boundaries. Tracks that didn't originally have razor
                       are untouched.
0.2.0 [260504.1520] - Header standardized to PT2Reaper line-comment style;
                       logic unchanged from v0.1.1.
0.1.1               - Fix: items stretched beyond source by "SWS/AW: Trim selected items
                       to fill selection" could create a blank loop on the left
                       (negative D_STARTOFFS). Now:
                         • Left side is clamped back to true file start (D_STARTOFFS → 0).
                         • Right side overrun/loop is unlooped and clamped to file end.
                         • normalize_loop_and_clamp() refactor to handle both sides robustly.
                         • Turn off B_LOOPSRC before clamping to honor pref 42218.
                         • Minor: take_offset/playrate/src_len declared local (avoid globals).
                         • Behavior preserved: never overlaps neighbors; fades untouched.
0.1                 - Beta release
```

