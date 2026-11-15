# hsuanice_PT_Transient.lua — Changelog

hsuanice_PT_Transient — Pro Tools-style transient helpers

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.2.0 [260508.1648]`).

```text
0.2.0 [260508.1648] - Add cursor-walk helpers
                       cursor_to_next/prev_transient(min_sec) for
                       Tab-style navigation with shared min-gap
                       filter. Caller manages item selection setup
                       (e.g. action 40421 Select all items in track).
0.1.0 [260508.1643] - Initial library: shared min_ms ExtState +
                       enumerate_transients (40375 walk with cursor /
                       selection save-restore) + filter_min_gap.
```

