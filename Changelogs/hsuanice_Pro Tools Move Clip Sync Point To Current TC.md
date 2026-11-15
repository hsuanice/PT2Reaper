# hsuanice_Pro Tools Move Clip Sync Point To Current TC.lua — Changelog

hsuanice_Pro Tools Move Clip Sync Point To Current TC

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.2 [260506.1730]`).

```text
0.3.2 [260506.1730] - PT-style fit check: if aligning the leftmost sync
                       to project start would push any moved item to a
                       negative position, the action no-ops entirely
                       (items stay, selection stays). Matches PT —
                       "sync point to current TC" can't satisfy items
                       whose snap_offset > 0 when target is timeline 0.
0.3.1 [260506.1700] - Time-selection mode now requires items to also be
                       item-selected. Previously items overlapping the
                       time selection on tracks the user wasn't focused
                       on (no item selection there) would also be split
                       and moved. Now we iterate only selected items in
                       time mode (matches PT — time selection alone
                       doesn't pick up unselected items).
0.3.0 [260506.1620] - Add cut-and-paste split (matches Move Clip
                       Start/End behavior). Reference changed to
                       earliest sync absolute position (was earliest
                       item start). Selection follows the moved content.
0.2.0 [260506.1515] - First implementation (group move, no split).
0.1.0 [260413.1324] - Stub placeholder created
```

