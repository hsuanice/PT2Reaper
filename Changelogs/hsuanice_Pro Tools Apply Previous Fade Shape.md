# hsuanice_Pro Tools Apply Previous Fade Shape.lua — Changelog

hsuanice_Pro Tools Apply Previous Fade Shape

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.2 [260505.1530]`).

```text
0.3.2 [260505.1530] - Library v0.2.2: only MANUAL fades on selected
                       items get cycled as fade-in/fade-out. Auto fades
                       (which are crossfades) are only cycled when both
                       xfade items are in the active set, so a single
                       item from an xfade pair leaves the xfade alone.
0.3.1 [260505.1505] - Library v0.2.1: razor edits now preserved across
                       apply (some fade actions clear them as a side
                       effect); time-selection mode now requires items
                       to ALSO be item-selected (matches PT — time
                       selection alone does not select items, so the
                       crossfade-needs-both-selected rule applies the
                       same way as in items-only mode).
0.3.0 [260505.1430] - Add Razor > Time > Items scope detection;
                       xfade only when both items in active set;
                       per-region fade filtering (razor zone / time range);
                       preserve item selection + time selection after apply.
0.2.0 [260505.1358] - Real implementation. Uses Library/hsuanice_PT_Fades.lua
                       for shape detection and chunk writing. Supports all
                       three fade types (in/out/crossfade) in one pass.
0.1.0 [260413.1324] - Stub placeholder created
```

