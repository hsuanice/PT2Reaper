# hsuanice_Pro Tools Delete Selection.lua — Changelog

hsuanice_Pro Tools Delete Selection

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.3 [261031.1149]`).

```text
0.3.3 [261031.1149]
  - Fix: deleting a range at an item's tail removed the whole fade-out
    (and at its head, the fade-in) even when the fade started outside
    the range. Outer pieces now trim fades like PT: the fade keeps its
    far end and is only shortened.
  - Fade shape, curve and S-curve intensity are kept.
0.3.2 [260506.2010]
  - Always clear time selection at end too (alongside razor + item
    selection).
0.3.1 [260506.1945]
  - Fade preservation on outer pieces: left piece keeps its original
    fade-in (truncated to its new length), right piece gets a fade-in
    equal to whatever portion of the original fade-in extended past
    the cut, fade-out kept (truncated).
  - Always clear item selection at end (matches PT).
0.3.0 [260506.1920]
  - PT-style partial removal: when items + time selection (or razor)
    intersect, split items at the boundaries and remove only the
    inside pieces. Surviving outer pieces keep their fade-in /
    fade-out, matching PT behavior.
0.2.0 [260506.1850]
  - Always clear razor edit zones at the end.
0.1.0 [260415.1250]
  - Initial release: context-aware delete mirroring PT behaviour.
```

