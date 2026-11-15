# hsuanice_Pro Tools Delete Fades.lua — Changelog

hsuanice_Pro Tools Delete Fades

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.2.1 [260505.1635]`).

```text
0.2.1 [260505.1635] - Fix razor priority: when an xfade pair is processed,
                       only the xfade-side fades are cleared (left's
                       fade-out + right's fade-in). The OTHER side's
                       fades (left's fade-in, right's fade-out) are no
                       longer touched. So razor on just the crossfade
                       region now correctly deletes only the crossfade
                       and snaps to midpoint, leaving any unrelated
                       fade-in/out on those items intact.
0.2.0 [260505.1608] - Real implementation. Uses Library/hsuanice_PT_Fades.lua
                       for scope detection. Snap-to-midpoint for xfades.
                       Manual fades cleared by zeroing D_FADEIN/OUTLEN.
0.1.0 [260413.1324] - Stub placeholder created
```

