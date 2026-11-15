# hsuanice_Pro Tools Space Clips.lua — Changelog

hsuanice_Pro Tools Space Clips

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.5.0 [260509.0220]`).

```text
0.5.0 [260509.0220] - After spacing, expand the time selection
                       and per-track razor zones to cover the
                       repositioned items. Expand-only — never
                       shrinks. TS / razor with no overlap with
                       items are also adjusted (their bounds
                       grow to include the items if items now
                       extend past).
0.4.0 [260509.0206] - Simplify unit formats:
                       Timecode (HH:MM:SS:FF) → Frames (decimal)
                       Min:Secs (M:SS.mmm)     → Secs (0.000)
                       Beats (decimal)         → Bar.Beat (0.00)
                       Internal storage stays as seconds. Old
                       ExtState values auto-migrate to new names.
0.3.0 [260509.0142] - Add Beats unit. Uses project-start tempo for
                       beats↔seconds conversion (constant-tempo
                       approximation; tempo-variant projects will
                       see slight drift). Stored value remains
                       internal seconds.
0.2.0 [260509.0129] - First implementation. GFX dialog (no
                       ReaImGui) with Timecode / Min:Secs unit
                       toggle, Item Start / Item End anchor
                       toggle, Single / Cross Track mode toggle,
                       OK / Cancel buttons. Settings persist
                       via ExtState; switching unit reformats
                       without losing the internal seconds value.
                       Default anchor is Item End. Logic ported
                       from Beta Testing/hsuanice_Item Reposition.
0.1.0 [260413.1324] - Stub placeholder created.
```

