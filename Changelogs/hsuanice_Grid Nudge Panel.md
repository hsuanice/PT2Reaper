# hsuanice_Grid Nudge Panel.lua — Changelog

hsuanice_Grid Nudge Panel

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.9 [260503.1918]`).

```text
0.4.9 [260503.1918]
  - Picks up hsuanice_PT_Grid 0.3.4: auto-resync on project fps/BPM
    change so grid panel doesn't jump to a fallback when fps changes.
0.4.8 [260503.1909]
  - Fix: format_nudge_value swapped TimeMap_curFrameRate return values.
    Same bug as PT_Grid 0.3.3 — fps was being captured as isdrop, so
    Nudge "Timecode" mode display was always computed at 24 fps and
    crashed on drop-frame projects.
  - Picks up hsuanice_PT_Grid 0.3.3.
0.4.7 [260503.1550]
  - Picks up hsuanice_PT_Grid 0.3.2: deferred retry chain to keep
    Frame grid OFF when REAPER state re-engages it after our toggle.
0.4.6 [260503.1528]
  - Picks up hsuanice_PT_Grid 0.3.1: Metronome preset removed (couldn't
    sync reliably and the implementation had a denominator/tempo bug).
0.4.5 [260503.1509]
  - Picks up hsuanice_PT_Grid 0.3.0: adds "Metronome" preset to Measure
    mode. Sets grid_div = 1/denom (4/4 → 1/4, 6/8 → 1/8, etc.).
0.4.4 [260503.1442]
  - Picks up hsuanice_PT_Grid 0.2.3: log spam fix + Measure auto-sync.
0.4.3 [260503.1439]
  - Right-click menu adds "Debug log" toggle and "Clear ReaScript console".
    Output goes to View → Show ReaScript console output. Useful for
    diagnosing intermittent grid-switch issues.
0.4.2 [260503.1428]
  - Picks up hsuanice_PT_Grid 0.2.1: defensive grid_div writes around
    command 40904 toggle. Fixes "first attempt fails, second works"
    symptom when leaving Timecode "1 frame" (native_frame).
0.4.1 [260503.1409]
  - Timecode "1 frame" and Feet+Frames "1 frame" now engage REAPER's
    built-in Frame grid (cmd 40904) under the hood — exact, tempo-free.
    Display still shows the TC string (e.g. "00:00:00:01.00").
  - Mode switch picks DEFAULT_IDX per mode (Timecode / Feet+Frames land
    on "1 frame" → no tempo prompt fires when you just switch modes).
0.4.0 [260503.1314]
  - Restructure: Grid menu now mirrors Nudge — 5 modes
    (Measure / Min:Secs / Timecode / Feet+Frames / Samples).
    Top half = preset values, bottom half = mode list.
  - Fix: simulated modes (non-Measure) at BPM != 120 used to silently
    auto-revert to Native because of float-rounding mismatch. Tolerance
    loosened (5e-3) and auto-revert removed.
  - Add: when switching into a simulated mode at BPM != 120, prompt
    Yes/No/Cancel — Yes sets BPM to 120, No proceeds (may drift).
  - Refactor: shared logic moved to Library/PRO TOOLS/hsuanice_PT_Grid.lua,
    which Increase/Decrease Grid Value scripts also consume.
  - Note: Frame grid (40904) is still detected and displayed as "Frame",
    but no longer a menu entry — pick a Measure / Timecode preset instead.
0.3.0 [260502.1928]
  - Add: Grid "Timecode" mode (1 sec / 6 frames / 1 frame / 1/2 / 1/4 / 1 sub frame)
    Simulated via tempo calculation; assumes constant tempo (post-production).
  - Add: Tempo warning when switching Grid into Timecode mode if BPM != 120.
  - Add: Auto-revert Grid mode to Native when grid_div changes externally.
  - Sync: Increase/Decrease Grid Value scripts iterate TC presets in TC mode.
0.2.0 [260418.2036]
  - Rewrite: GFX window instead of JS_Composite (more stable, dockable)
  - Fix: menu index was off-by-one (gfx.showmenu is 1-based)
  - Fix: Bars+Beats and Min-Secs display names
0.1.8 [260418.2031]
  - Fix: Min:Secs colon was triggering submenu in gfx menu
0.1.7 [260418.2017]
  - Fix: window switch during drag
0.1.6 [260418.1943]
  - TC format: always HH:MM:SS:FF.XX
0.1.5 [260418.1931]
  - Fix: NUDGE_MODES, grid menu Reaper native values
0.1.0 [260418.1534]
  - Initial release (JS_Composite)
```

