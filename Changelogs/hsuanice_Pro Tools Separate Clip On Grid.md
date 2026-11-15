# hsuanice_Pro Tools Separate Clip On Grid.lua — Changelog

hsuanice_Pro Tools Separate Clip On Grid

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.1 [260508.1407]`).

```text
0.3.1 [260508.1407] - Remember last pre-amount via ExtState
                       (namespace "hsuanice_PT_SeparateClipOnGrid",
                       key "pre_ms", persist=true). Default for first
                       run is "0".
0.3.0 [260508.1351] - Add Pre-Separate Amount dialog (matches PT).
                       pre_ms = 0 routes to native 40932. pre_ms > 0
                       uses custom item-end-anchored split walking left
                       by grid value in the quarter-note domain
                       (handles tempo changes). Removed SWS dependency
                       (uses stock GetSetProjectGrid + TimeMap2 APIs).
0.2.0 [260508.1319] - First implementation. Custom grid iteration via
                       SWS BR_GetNextGridDivision.
0.1.0 [260413.1324] - Stub placeholder created.
```

