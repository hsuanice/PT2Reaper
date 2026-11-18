# hsuanice_Pro Tools Play-Stop.lua — Changelog

hsuanice_Pro Tools Play/Stop

## 26.1118.1937pre1

- QuickPunch on: Space plays from the pre-roll and stops at the Timeline Selection end + post-roll.

## 26.1117.1552

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).
- Fix: with QuickPunch mode on and no armed track, Space now plays the Timeline Selection and stops at its end (it played on).
- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it; without one, starts the pre-roll before the playhead. The playhead stays where it is.

## 26.1117.1546pre1

- Fix: with QuickPunch mode on and no armed track, Space now plays the Timeline Selection and stops at its end (it played on).
- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it; without one, starts the pre-roll before the playhead. The playhead stays where it is.

## 26.1117.1423pre1

- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it; without one, starts the pre-roll before the playhead. The playhead stays where it is.

## 26.1117.1259pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2128

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2125pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2111pre1

- Insertion Follows Playback on clears only the Timeline Selection (loop points); razor areas and the time selection are always kept.

## 26.1115.2045pre1

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.3.1 [261115.1331]`).

```text
0.3.1 [261115.1331] - Insertion Follows Playback respected when stopping a QuickPunch pass.
0.3.0 [261115.1250] - QuickPunch added (copy of hsuanice_Transport - Play Stop 26.1114.1519pre1).
0.2.0 [261115.1230] - First implementation (copied from hsuanice_Transport 26.1114).
0.1.0 [260413.1324] - Stub placeholder created.
```

