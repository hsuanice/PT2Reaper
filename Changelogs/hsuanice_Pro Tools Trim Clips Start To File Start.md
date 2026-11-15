# hsuanice_Pro Tools Trim Clips Start To File Start.lua — Changelog

hsuanice_Pro Tools Trim Clips Start To File Start

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.0 [260504.1620]`).

```text
0.3.0 [260504.1620] - Selection follows extend: razor (per track) and time selection
                       now expand to encompass the items' new extents (left edge only).
0.2.0 [260504.1520] - Header standardized to PT2Reaper line-comment style;
                       logic unchanged from v0.1.1.
0.1.1               - Fix: collapse LEFT blank loop without shifting perceived content earlier:
                         • If D_STARTOFFS < 0, move item start right by overshoot, shorten length
                           by overshoot, and set D_STARTOFFS = 0 (mirrors Boundaries behavior).
                           Right side untouched.
                         • Preserve normal left-edge reveal in non-loop cases (can extend to true file start).
0.1                 - Beta release
```

