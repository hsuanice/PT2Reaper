# hsuanice_Pro Tools Move Clip Start To Current TC.lua — Changelog

hsuanice_Pro Tools Move Clip Start To Current TC

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.0 [260506.1305]`).

```text
0.4.0 [260506.1305] - Switch to PT-style cut-and-paste split on partial
                       overlaps. Items partially overlapping the
                       selection are split at the selection boundaries
                       and only the inside portion moves; the outside
                       parts stay in place. Replaces the v0.2/v0.3
                       "auto-extend selection to wrap whole item"
                       behavior, which the user confirmed PT does NOT do.
0.3.0 [260506.1230] - Target changed to project start (timeline 0).
0.2.0 [260506.1145] - Real implementation (auto-extend variant).
0.1.0 [260413.1324] - Stub placeholder created
```

