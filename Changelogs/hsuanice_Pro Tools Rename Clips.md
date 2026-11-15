# hsuanice_Pro Tools Rename Clips.lua — Changelog

hsuanice_Pro Tools Rename Clips

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.2 [260509.0014]`).

```text
0.4.2 [260509.0014] - Picks up hsuanice_PT_GFXInputField 0.2.0:
                       Cmd+Left/Right (line edge), Option+Left/Right
                       (word jump), all with Shift extension. Cmd+A
                       select-all also accepts char 1 (Ctrl+A) so
                       it works on the macOS REAPER builds that
                       emit it that way.
0.4.1 [260509.0010] - Library renamed to hsuanice_PT_GFXInputField
                       and moved from Library/ to PRO TOOLS/.
                       Updated dofile path. No behaviour change.
0.4.0 [260509.0008] - Refactor onto Library/hsuanice_GFXInputField
                       (extracted shared input-field behavior).
                       Adds Cmd/Ctrl+A select all (free in the
                       library). No other behavior change.
0.3.2 [260509.0002] - Shift+Arrow / Shift+Home / Shift+End now
                       extend the selection from a sticky anchor
                       (set on first shifted move). Releasing
                       shift and pressing arrow drops the anchor
                       and collapses to the caret as before.
0.3.1 [260509.0000] - Reset cursor-blink phase on every caret
                       movement (arrow keys, Home/End, click,
                       drag, type, delete) so the caret is
                       always visible right after it moves
                       instead of possibly being mid-off-blink.
0.3.0 [260508.2351] - Native-feeling text input: single-click
                       positions the caret at the click point
                       (instead of selecting all), double-click
                       selects all, click-and-drag selects a
                       range. Selection state now anchor + caret
                       (range = [min..max] of the two), so
                       typing/Backspace/Delete replace the
                       selection.
0.2.0 [260508.2324] - First implementation. Custom GFX dialog
                       (no ReaImGui dependency) with full text
                       editing, Clip Info panel, sequential
                       multi-select rename.
0.1.0 [260413.1324] - Stub placeholder created.
```

