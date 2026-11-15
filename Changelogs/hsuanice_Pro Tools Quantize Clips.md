# hsuanice_Pro Tools Quantize Clips.lua — Changelog

hsuanice_Pro Tools Quantize Clips

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.4.0 [260508.1927]`).

```text
0.4.0 [260508.1927] - Pure-native rewrite. No SWS dependency. Uses
                       GetSetProjectGrid + TimeMap2_timeToQN /
                       QNToTime to snap each selected item's
                       position to the nearest grid line in the
                       QN domain (tempo-aware), preserving length.
0.3.0 [260508.1925] - Switch from native action 41165 (which had
                       no visible effect) to SWS named command
                       `_SWS_QUANTITESTART2`.
0.2.0 [260506.2030] - Map to native 41165.
0.1.0 [260413.1324] - Stub placeholder created.
```

