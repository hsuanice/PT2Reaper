# hsuanice_PT_Grid.lua — Changelog

hsuanice_PT_Grid - Grid Library

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.5 [260712.1307]`).

```text
0.3.5 [260712.1307]
  - Samples mode minimum grid value is now 100 samples.
    Removed 10 / 2 / 1 sample presets to avoid inaccurate sub-100
    behavior and instability at 1 sample.
0.3.4 [260503.1918]
  - Auto-resync on project fps / BPM change. When the user changes
    the Video frame rate (or BPM), simulated grids (Timecode /
    Feet+Frames / Min:Secs / Samples) now re-apply with the new
    environment instead of jumping to a fallback display ("1/X" etc).
    Only fires when the parameter that actually affects the current
    preset has changed (fps only matters for unit==18 frame presets).
0.3.3 [260503.1909]
  - Fix: TimeMap_curFrameRate returns (fps, isdrop) — fps is the FIRST
    value, not the second. We were doing `local _, fps = ...` which
    captured isdrop (a boolean) as fps and threw away the real frame
    rate. Symptoms:
      * Non-drop projects (24/25/30/60): fps captured as `false`, our
        guard `if not fps or fps <= 0 then fps = 24 end` defaulted to
        24 silently. Worked only by coincidence at 24 fps.
      * Drop-frame projects (29.97DF/23.976DF): fps captured as `true`,
        the guard hit `true <= 0` → "attempt to compare boolean with
        number" → script crash.
    Now reads fps as the first return; calculations are accurate at all
    fps including the 1.001-slowdown rates (23.976 = 24000/1001 exact,
    29.97 = 30000/1001 exact).
0.3.2 [260503.1550]
  - Add 5-iteration deferred retry to keep 40904 OFF when applying a
    non-native_frame preset. Defends against REAPER state that re-engages
    Frame grid after our toggle (observed: user adjusts Frame's "minimum
    pixels" in Snap/Grid Settings + Enter — REAPER then keeps re-applying
    Frame across our changes for several event loops). The retry chain
    stops as soon as 40904 stays OFF.
0.3.1 [260503.1528]
  - Remove Metronome preset (added in 0.3.0). Reasons:
    (1) REAPER's native "Metronome" dropdown isn't a distinct API state,
        so we couldn't reliably sync it from REAPER → panel.
    (2) The dynamic 1/denom calculation depended on
        TimeMap_GetTimeSigAtTime returning denominator at index 3, but
        empirically position 3 is tempo (e.g. 120), not denominator —
        so apply produced grid_div = 1/120, not 1/4 at 4/4.
    Use a specific beat preset (1/4, 1/8, etc.) for the equivalent grid.
  - DEFAULT_IDX[Measure] reverts 6 → 5.
0.3.0 [260503.1509]
  - Add "Metronome" preset to Measure mode (idx 1). Sets grid_div to
    1/denom based on the current time signature (4/4 → 1/4 note, 6/8
    → 1/8 note, 3/2 → 1/2 note). Display label: "Metronome".
  - REAPER's native "Metronome" dropdown isn't a distinct API state — it
    just clears Frame/Measure flags back to the last beat grid_div. So
    we can't auto-sync our panel into "Metronome" when the user picks
    it natively; auto-sync prefers fixed presets instead. To get
    "Metronome" behavior in our panel, pick it from our menu.
  - Increase/Decrease skip Metronome in the cycle (its idx position
    doesn't reflect its grid_div magnitude, so stepping onto it would
    cause an unnatural jump).
  - DEFAULT_IDX[Measure] bumped 5 → 6 because Metronome was inserted
    at idx 1; "1/4" is still the default.
0.2.3 [260503.1442]
  - Fix: get_text was logging "sim_mismatch" on every frame in non-Measure
    modes when grid_div drifted from saved preset, flooding the ReaScript
    console (~30 Hz) when REAPER's native grid was changed externally.
    The mismatch case now relies on the wrapper's per-transition log.
  - Add: Measure mode preset_idx auto-syncs to grid_div when an exact
    preset match is found (e.g. user picks "1/8" via REAPER's native grid
    menu → our panel's check-mark moves to "1/8").
0.2.2 [260503.1439]
  - Add debug logging gated by ExtState 'debug' = '1'. Toggle from the
    Grid Nudge Panel's right-click menu. Logs each apply() step
    (40904 state, grid_div, swing, BPM) and get_text() decisions
    (rate-limited to transitions). Use to diagnose stuck-on-Frame.
  - Add M.set_debug(bool) and M.is_debug() helpers.
0.2.1 [260503.1428]
  - Fix: switching from a native_frame preset (Frame grid on) to a
    simulated preset (e.g. Timecode "1/2 frame") sometimes displayed
    the previous grid value (e.g. "1/8") on the first attempt and only
    worked on the second. REAPER's command 40904 (toggle Frame grid)
    appears to reset grid_div as a side-effect when going on→off.
    apply() now writes grid_div BEFORE the toggle, AFTER the toggle,
    and once more on the next event loop iteration via r.defer.
  - Loosen get_text validation tolerance from 0.5% to 1% to handle
    finer grids (e.g. 1 sub frame ≈ 1/4800) where REAPER's float
    storage may round slightly.
0.2.0 [260503.1409]
  - Add native_frame flag on Timecode/Feet+Frames "1 frame" presets.
    Engages REAPER's command 40904 (Frame grid) — exact, tempo-free.
    Panel still displays the TC format string for these presets.
  - Add M.DEFAULT_IDX so mode toggle picks the most useful starting
    preset (e.g. switching to Timecode lands on "1 frame" / native).
  - ensure_tempo accepts an optional preset arg and skips the prompt
    when preset.native_frame is set.
  - increase/decrease bail when external Frame grid is engaged AND
    saved state isn't a native_frame preset (preserves user intent).
0.1.0 [260503.1314]
  - Initial release. Replaces the inline Native/Timecode-only logic in
    hsuanice_Grid Nudge Panel.lua and the Increase/Decrease scripts.
```

