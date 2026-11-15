# hsuanice_PT_GFXInputField.lua — Changelog

hsuanice_PT_GFXInputField — Native-feeling text input for gfx

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.0 [260509.0129]`).

```text
0.3.0 [260509.0129] - Add `filter_time` (digits + `:` + `.` + `-`)
                       for time-format inputs like timecode and
                       minutes:seconds.
0.2.0 [260509.0014] - Add Cmd+Left/Right (jump to line start/end)
                       and Option+Left/Right (jump by word
                       boundary). Both honour Shift for selection
                       extension. Cmd+A select-all also accepts
                       the legacy char-code 1 (Ctrl+A) which some
                       REAPER builds emit on macOS.
0.1.1 [260509.0010] - Renamed file from hsuanice_GFXInputField.lua
                       to hsuanice_PT_GFXInputField.lua. Moved out of
                       Library/ and into PRO TOOLS/ alongside the
                       other PT_ library scripts (hsuanice_PT_Nudge,
                       hsuanice_PT_Grid). No code change.
0.1.0 [260509.0005] - Initial release. Extracted from the input
                       field embedded in hsuanice_Pro Tools Rename
                       Clips v0.3.2. Adds Cmd / Ctrl + A select all.
```

