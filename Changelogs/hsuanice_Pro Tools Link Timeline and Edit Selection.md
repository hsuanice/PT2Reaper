# hsuanice_Pro Tools Link Timeline and Edit Selection.lua — Changelog

hsuanice_Pro Tools Link Timeline and Edit Selection

## 26.1118.0059

- Release: turning Link on removes the Time marker (tested in REAPER).

## 26.1117.2344pre1

- Turned on: removes the Time marker (marker 9999 ">", the Timeline position with Link off).

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.1 [260510.1225]`).

```text
0.3.1 [260510.1225] - Razor link disabled per user request.
                       Reverted to a simple 40621 toggle wrapper
                       (functionally equivalent to 0.1.5). The
                       0.3.0 watcher / PreventUIRefresh / etc.
                       are kept in git history for revival.
0.3.0 [260510.1215] - Drop time-selection branch (loop<->razor
                       only). Performance pass: skip per-track
                       razor writes when the zone already matches
                       the target, wrap writes in PreventUIRefresh,
                       and call UpdateArrange only when something
                       actually changed.
0.2.0 [260510.1149] - Rewrote as background toggle with defer
                       watcher. Linked loop + time + razor (each
                       toggleable via USER CONFIG).
0.1.5 [260415.1629] - Initial release. Toggled native action
                       40621 (loop linked to time).
```

