# hsuanice_PT_Trim.lua — Changelog

hsuanice_PT_Trim — Pro Tools-style trim/extend helpers

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.2.0 [260504.1620]`).

```text
0.2.0 [260504.1620] - Add snapshot_selection() / expand_selection_to_items() helpers so
                      Trim Clip … to File … scripts can update razor + TS to follow
                      the new (extended) item extents. Razors on tracks that didn't
                      originally have a razor stay untouched.
0.1.0 [260504.1520] - Initial release
```

