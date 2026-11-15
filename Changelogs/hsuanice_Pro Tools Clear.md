# hsuanice_Pro Tools Clear.lua — Changelog

hsuanice_Pro Tools Clear

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.2 [260506.2010]`).

```text
0.4.2 [260506.2010]
  - Always clear time selection at end too (alongside razor + item
    selection). After Clear runs, all selection-like state is gone.
0.4.1 [260506.1945]
  - Fade preservation on outer pieces: left piece keeps its original
    fade-in (truncated to its new length), right piece gets a fade-in
    equal to whatever portion of the original fade-in extended past
    the cut, fade-out kept (truncated). Previously REAPER's split
    cleared fades on the new edges so a cut through a fade region
    lost the fade entirely.
  - Always clear item selection at end (matches PT — after Clear, no
    items remain selected).
0.4.0 [260506.1920]
  - PT-style partial removal: when items + time selection (or razor)
    intersect, split items at the boundaries and remove only the
    inside pieces. Surviving outer pieces keep their fade-in /
    fade-out (REAPER's SplitMediaItem preserves boundary fades),
    matching PT behavior. Previously 40006 removed whole items so
    fades disappeared.
0.3.1 [260506.1850]
  - Always clear razor edit zones at the end.
0.3.0 [260506.1830]
  - Context-aware clear (mirrors Delete Selection priority ladder).
0.2.0 [260506.1810]
  - Thin wrapper over native 40006.
0.1.0 [260413.1324]
  - Stub placeholder created.
```

