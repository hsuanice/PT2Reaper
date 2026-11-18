# hsuanice_PT_QuickPunch.lua — Changelog

hsuanice_PT_QuickPunch - QuickPunch Library (PT2Reaper)

## 26.1118.1937pre1

- start_pass takes the Pro Tools rolls (pre-roll, Timeline Selection as the record range) instead of REAPER's pre-roll.

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.1.3 [261115.1345]`).

```text
0.1.3 [261115.1345]
  - Punched items are no longer selected after a pass (Pro Tools does not select
    them); the item selection is left as it was. Selecting them let the link scripts
    make a time selection, so the next Play / Record jumped back to the first punch.
0.1.2 [261115.1336]
  - No more cursor jump when a pass stops: REAPER's "Move edit cursor to end of
    recording" (40300) is switched off during the pass and restored after it (like
    pre-roll), and C.stop() places the cursor at once.
0.1.1 [261115.1331]
  - Insertion Follows Playback now works during a QuickPunch pass: C.stop(follows)
    stores where the edit cursor must end (stop position / where it was before Play)
    and the pass end puts it there (REAPER's record-stop cursor rules no longer win).
0.1.0 [261115.1250]
  - First version: copy of hsuanice_QuickPunch Core 26.1114.1519pre1 (monitor path
    points to hsuanice_PT_QuickPunch Pass Monitor.lua).
```

