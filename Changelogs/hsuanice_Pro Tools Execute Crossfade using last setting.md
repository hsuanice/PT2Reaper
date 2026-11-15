# hsuanice_Pro Tools Execute Crossfade using last setting.lua — Changelog

hsuanice_Pro Tools Execute Crossfade using last setting

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.1 [260505.1945]`).

```text
0.4.1 [260505.1945] - Position the xfade exactly at the selection (not
                       just match its length). Matches PT behavior:
                       when the razor/TS doesn't sit on the existing
                       midpoint, the recreated crossfade follows the
                       selection bounds and the midpoint changes
                       accordingly. Library v0.2.x exposes sel_start /
                       sel_end via det for this; both touching and
                       already-overlapping pair paths use it.
0.4.0 [260505.1930] - Rewrite to use F.detect_create_targets() (the
                       shared Create-Fades-style detection). Now correctly
                       recalls per-type shape AND length based on selection
                       geometry — razor at item start applies fade-in only,
                       razor on xfade region applies xfade only, etc.
                       Crossfade length now comes from the selection in
                       shape-only mode (matches Create Fades behavior),
                       fall back to stored ms/frame in batch mode.
0.3.0 [260505.1815] - Honor the length_unit ExtState key.
0.2.0 [260505.1608] - Real implementation; reads ExtState.
0.1.0 [260413.1324] - Stub placeholder created
```

