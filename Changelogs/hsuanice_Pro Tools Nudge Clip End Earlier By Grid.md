# hsuanice_Pro Tools Nudge Clip End Earlier By Grid.lua — Changelog

hsuanice_Pro Tools Nudge Clip End Earlier By Grid

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.8.3 [260503.1934]`).

```text
0.8.3 [260503.1934] - Fix: TimeMap_curFrameRate return order — fps was being read as
                      the isdrop boolean, causing get_delta() at unit==18 to default to
                      24 on non-drop projects and crash on drop-frame projects.
0.8.2 [260424.2227] - No-razor branch: skip item when right xfade partner is also selected.
                      Treats full crossfade pair as one virtual item — only the trailing
                      O-end nudges (matches nudge_start behavior). Also closes a TS-sync hole
                      where in-library skip's delta_used=0 was dragging min_actual down.
0.8.1 [260422.1820] - Handle "skipped" return value from nudge_end (3rd value `true`).
                      Skipped items don't influence min_actual sync, so pure razor + TS shift correctly
                      when crossfade pair has one item handling, the other skipping.
0.8.0 [260422.1820] - Item-track is anchor: track min |shift_e| from nudge_end; pure razors
                      and time selection sync to that effective_delta. When item is blocked
                      (zone guard), all razors and TS freeze together.
0.7.1 [260422.1820] - Pure-razor and time-selection width guard: keep razor/TS >= 1 nudge grid
                      when shrinking (End Earlier: re moves left).
0.7.0 [260422.1820] - Sync razors on tracks WITHOUT items: pure-razor tracks now shift along
                      with item-driven nudge (matches Move script behavior).
0.6.0 [260421.1214] - Use NudgeEdge module (crossfade-aware nudge_end)
0.5.0 [260421.1048] - Item-only selection uses nudge_end (fade-aware) instead of ApplyNudge
0.4.0 [260420.1523] - Add fill mechanism + correct zone-size stop guard
0.3.0 [260420.1247] - 3-boundary logic with stop guard
0.2.0 [260420.1132] - PT selection-aware nudge
0.1.0 [260419.1012] - Initial release
```

