# hsuanice_PT_Fades.lua — Changelog

hsuanice_PT_Fades — Pro Tools-style fade helpers

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.2.2 [260505.1530]`).

```text
0.2.2 [260505.1530] - gather_fade_targets(): fadein_items/fadeout_items now
                       only include items with MANUAL fades (D_FADEINLEN /
                       D_FADEOUTLEN > 0 with corresponding _AUTO == 0). Auto
                       fades (which are crossfades) are only cycled via the
                       xfade_pairs path, which requires BOTH items in the
                       active set. Previously a single selected item from an
                       xfade pair would have its auto-fade side cycled
                       independently — that broke the "xfade requires both
                       items selected" rule.
0.2.1 [260505.1505] - with_preserved_state() now also snapshots/restores
                       razor edits (some fade actions clear them).
                       gather_fade_targets() now requires item selection
                       in time-selection mode (razor mode still uses razor
                       coverage as the implicit selection, PT-like).
0.2.0 [260505.1430] - Add gather_fade_targets() for Razor > Time > Items scope
                       detection with per-region fade filtering. Add
                       with_preserved_state() to wrap operations in
                       item-selection + time-selection preservation. Add
                       set_fadein_shape() / set_fadeout_shape() variants
                       that don't save/restore (intended for batch use
                       inside with_preserved_state).
0.1.0 [260505.1313] - Initial extraction from hsuanice_Pro Tools Create Fades.lua v0.5.3
```

