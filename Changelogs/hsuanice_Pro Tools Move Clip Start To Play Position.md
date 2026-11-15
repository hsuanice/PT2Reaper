# hsuanice_Pro Tools Move Clip Start To Play Position.lua — Changelog

hsuanice_Pro Tools Move Clip Start To Play Position

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.1 [260506.1325]`).

```text
0.4.1 [260506.1325] - Always split at selection boundaries, even when
                       delta is zero (cursor at selection start). PT's
                       Play Position variant has Spot semantics that
                       always cut the inside-selection portion into its
                       own item, regardless of whether anything ends up
                       moving.
0.4.0 [260506.1305] - Switch to PT-style cut-and-paste split on partial
                       overlaps. Shares logic with the Current TC variant
                       but uses edit cursor as the target.
0.2.0 [260506.1145] - Real implementation (auto-extend variant).
0.1.0 [260413.1324] - Stub placeholder created
```

