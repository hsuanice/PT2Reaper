# hsuanice_Pro Tools Copy and Move Clip Sync Point To Current TC.lua — Changelog

hsuanice_Pro Tools Copy and Move Clip Sync Point To Current TC

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.2 [260506.1730]`).

```text
0.3.2 [260506.1730] - PT-style fit check: if any clone would land at a
                       negative position, the action no-ops entirely
                       (no clones, no selection move).
0.3.1 [260506.1700] - Time mode now requires items to also be
                       item-selected (matches PT — time selection alone
                       doesn't pick up unselected items on other tracks).
0.3.0 [260506.1635] - Add cut-and-paste split for partial overlaps
                       (matches Copy and Move Clip Start/End behavior).
                       Reference = earliest sync absolute position.
0.2.0 [260506.1530] - First implementation (whole-item clone, no split).
0.1.0 [260413.1324] - Stub placeholder created
```

