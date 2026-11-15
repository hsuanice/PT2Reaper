# hsuanice_PT_Transient Settings.lua — Changelog

hsuanice_PT_Transient Settings

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.2 [260509.0014]`).

```text
0.4.2 [260509.0014] - Picks up hsuanice_PT_GFXInputField 0.2.0:
                       Cmd+Left/Right (edge), Option+Left/Right
                       (word jump). Cmd+A select-all is more
                       tolerant of the macOS char-code 1 quirk.
0.4.1 [260509.0010] - Library renamed to hsuanice_PT_GFXInputField
                       and moved from Library/ to PRO TOOLS/.
                       Updated dofile path. No behaviour change.
0.4.0 [260509.0008] - Refactor onto Library/hsuanice_GFXInputField
                       for consistent native-feeling text editing
                       across all gfx-based dialogs. Adds
                       Cmd/Ctrl+A select all and click-drag
                       range select (free in the library).
0.3.4 [260508.1844] - Proper text-editing in the input field:
                       tracks caret position, supports left/right
                       arrow keys, Home, End, Delete (forward), and
                       inserts/removes characters at the caret rather
                       than only at the end. Cursor renders at the
                       caret position. Selecting + typing still
                       replaces the whole field.
0.3.3 [260508.1834] - Text-selection highlight (macOS-style):
                       dialog opens with all text pre-selected (blue
                       highlight, white text); clicking the field
                       re-selects all; typing a digit replaces the
                       selection; Backspace while selected clears
                       the field. Cursor hidden while selected.
0.3.2 [260508.1806] - Visual feedback on the input field: blue
                       accent border (always-focused look since
                       there's only one field) and a thicker (2px)
                       blinking cursor, so users notice the field
                       is editable without clicking.
0.3.1 [260508.1802] - Light/native-style colour palette (light grey
                       background, white field, subtle button borders).
                       Bigger font (size 16). Window is centred on the
                       current mouse position so it pops near the
                       user's focus instead of the screen origin.
0.3.0 [260508.1758] - Replace blocking GetUserInputs with a stock-gfx
                       custom dialog so the user can click "Transient
                       Setting" to open REAPER's native panel without
                       a modal dialog blocking it. Three buttons:
                       OK / Cancel / Transient Setting. Pressing
                       Transient Setting saves the current min_ms
                       value first, then opens action 41208.
0.2.1 [260508.1741] - Hardcode native action 41208 (verified by user
                       as the panel-opening command). Removed the
                       runtime name-lookup fallback.
0.2.0 [260508.1724] - Open REAPER native transient detection panel
                       alongside our min-gap dialog. Action looked up
                       at runtime by partial name match. Shorten
                       dialog label so it no longer truncates.
0.1.0 [260508.1648] - Initial release.
```

