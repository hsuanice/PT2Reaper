# hsuanice_Pro Tools Separate Clip At Transients.lua — Changelog

hsuanice_Pro Tools Separate Clip At Transients

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.5.0 [260508.1643]`).

```text
0.5.0 [260508.1643] - Refactor onto Library/hsuanice_PT_Transient.lua.
                       min_ms now reads/writes the shared namespace
                       `hsuanice_PT_Transient/min_ms` so Tab navigation
                       + any future consumers share one tuning value.
                       pre_ms stays in `hsuanice_PT_SeparateClipAtTransients`
                       (per-script). Transient enumeration + min-gap
                       filter delegated to the library.
0.4.1 [260508.1622] - Set DEBUG = false (verified working). No
                       behavior change.
0.4.0 [260508.1611] - Add Min-clip-length filter (0-999 ms,
                       transient-to-transient distance). Single
                       dialog now has two fields: pre-amount + min
                       length. Both persist via ExtState (keys
                       "pre_ms" and "min_ms"). Transients walking
                       forward via 40375 are filtered ascending so
                       neighbours within `min_ms` of the previous
                       kept transient are dropped before splitting.
0.3.3 [260508.1541] - Fix: action IDs were swapped. 40375 is the
                       forward "next transient" action; 40376 is the
                       reverse "previous transient" action. Switched
                       to 40375 for forward walking. Removed probe
                       diagnostic. DEBUG kept on for one round.
0.3.2 [260508.1536] - Diagnostic build. Probes which action ID actually
                       advances the cursor on the user's REAPER (since
                       40376 came back inert). Prints action names via
                       kbd_getTextFromCmd for several candidate IDs and
                       measures cursor delta after each Main_OnCommand
                       on the first selected item.
0.3.1 [260508.1533] - Debug build. Removed PreventUIRefresh wrapper
                       (suspected of suppressing cursor/40376 action).
                       Added console-log diagnostic for each item:
                       enumerated transient count + split positions.
                       Set DEBUG=false at the top of the script to
                       silence once verified working.
0.3.0 [260508.1448] - Pure-native rewrite. Adds Pre-Separate Amount
                       dialog (0-99 ms, remembers last value via
                       ExtState namespace
                       "hsuanice_PT_SeparateClipAtTransients").
                       Enumerates transients via native action 40376
                       (per-item solo-select), splits at
                       (transient - pre_sec). No SWS dependency. Edit
                       cursor + original item selection restored after
                       run; new right-side pieces also selected.
0.2.0 [260508.1319] - First implementation. Wraps SWS Xenakios command
                       `_XENAKIOS_SPLIT_ITEMSATRANSIENTS`.
0.1.0 [260413.1324] - Stub placeholder created.
```

