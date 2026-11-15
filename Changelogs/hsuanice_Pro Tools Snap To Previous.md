# hsuanice_Pro Tools Snap To Previous.lua — Changelog

hsuanice_Pro Tools Snap To Previous

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.0 [260509.0031]`).

```text
0.3.0 [260509.0031] - Treat TS_start and per-track razor zones
                       as part of the moving body when computing
                       the left extent. Razor zones now shift
                       along with items + TS.
0.2.0 [260509.0021] - First implementation. Per-track group-move
                       using minimum-magnitude-negative-delta to
                       keep the move safe across all tracks;
                       time selection follows the items.
0.1.0 [260413.1324] - Stub placeholder created.
```

