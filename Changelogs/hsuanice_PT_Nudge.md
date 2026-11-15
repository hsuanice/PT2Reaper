# hsuanice_PT_Nudge.lua — Changelog

hsuanice_PT_Nudge - Nudge Library

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.5.1 [261115.1141]`).

```text
0.5.1 [261115.1141]
  - M.get_state honors global HSUANICE_PT_NUDGE_STEP (temporary preset
    offset, -1 = next larger) for the Next Larger Grid scripts.
0.5.0 [261115.1100]
  - Add M.nudge_selection(edge, reverse): nudges only the Edit Selection
    (time selection + all razor areas) by the current Nudge value;
    edge = 'both' / 'start' / 'end'. Start/end never cross each other,
    nothing goes below 0. No selection: moves the edit cursor
    ('both' / 'start'). Used by the Nudge Selection scripts.
0.4.5 [260504.1230]
  - Public M.calc_delta_sec(preset, reverse) — exposes the seconds conversion that
    was internal to nudge_razor. Lets scripts do per-item processing (e.g. Contents
    Later/Earlier with source-bound clamp) without duplicating the unit conversion.
0.4.4 [260503.1918]
  - Fix: r.ApplyNudge with unit=18 (frames) doesn't track project fps
    reliably — at non-24 fps it appears to default to 24, so item
    nudges came out wrong (e.g. 6 frames at 25 fps gave 12000 samples
    instead of 11520 at 48k). M.apply now converts frame-unit values
    to seconds (unit=1) before calling ApplyNudge, using the same fps
    lookup calc_delta_sec uses for razor-area mode.
0.4.3 [260503.1909]
  - Fix: TimeMap_curFrameRate returns (fps, isdrop) — fps is FIRST.
    `calc_delta_sec` was doing `local _, fps = ...` which captured
    isdrop (a boolean) as the frame rate. Frame-unit nudges (Timecode
    / Feet+Frames) were always computed at the 24 fps fallback for
    non-drop projects, and crashed on drop-frame projects.
0.2.0 [260418.1931]
  - Sync NUDGE_PRESETS with Grid Nudge Panel (Feet+Frames restored)
0.1.0 [260418.1534]
  - Initial release
```

