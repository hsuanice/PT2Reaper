# hsuanice_Pro Tools Play Timeline Selection.lua — Changelog

hsuanice_Pro Tools Play Timeline Selection

## 26.1117.2309pre1

- Link off: plays from the Time marker (V) when there are no loop points; the edit cursor (Edit position) stays.

## 26.1117.1556

- Play Timeline Selection without a Timeline Selection, pre-roll on: every retrigger starts the pre-roll before the Time position (it went on from where it was).

## 26.1117.1553pre1

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).
- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it. The playhead stays at the Timeline Selection start.

## 26.1117.1552

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).
- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it. The playhead stays at the Timeline Selection start.

## 26.1117.1546pre1

- Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it. The playhead stays at the Timeline Selection start.

## 26.1117.1259pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2128

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2125pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2111pre1

- Timeline Selection = the loop points only; Insertion Follows Playback on clears only them (razor areas and time selection kept).

## 26.1115.2104pre1

- Retrigger with Insertion Follows Playback on also clears the Timeline Selection (Pro Tools).

## 26.1115.2100pre1

- Retrigger while playing: Insertion Follows Playback on plays again from the playhead; off from the selection start.

## 26.1115.2057pre1

- Pressed while playing: always plays again from the start (Insertion Follows Playback on too).

## 26.1115.2045pre1

- Rewritten: Pro Tools behaviour with Insertion Follows Playback and Link Timeline and Edit Selection; stops at the selection end (Play Watcher, no task control dialog).

