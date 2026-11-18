# hsuanice_PT_Transport.lua — Changelog

hsuanice_PT_Transport - Transport Library (PT2Reaper)

## 26.1118.2035pre1

- Recording that stops by itself with Insertion Follows Playback on: the Time position goes where it stopped (Timeline Selection end + post-roll).

## 26.1118.1937pre1

- Recording uses the Pro Tools rolls (record_plan / record_native / record_end / record_finish); turning a roll on turns REAPER's own pre-roll off.

## 26.1118.0119

- Release: the Time marker (9999) is named with the timecode of its position (tested in REAPER).

## 26.1118.0115pre1

- Time marker (9999) named with the timecode of its position (was ">").

## 26.1118.0059

- Release: Link off - the Time marker (9999 ">") is the Timeline position, the edit cursor stays the Edit position (tested in REAPER).

## 26.1118.0047pre1

- razor_range(): the union of the track-level razor areas (edit_range uses it).

## 26.1118.0028pre1

- ruler_segment(): which part of the ruler the mouse is on (SWS) - time scale or marker / region lanes.

## 26.1117.2341pre1

- Only one Time marker: extra or older ones (V, ><) left in the project are deleted when it is set or cleared.

## 26.1117.2337pre1

- Time marker named ">" (number 9999); remembers the ruler click so a double click can put the loop points and the marker back.

## 26.1117.2320pre1

- Time marker: no name, marker number 9999 (a V or >< marker from the 26.1117 pre-releases is replaced when moved).

## 26.1117.2317pre1

- Time marker renamed from V to >< (a V marker from 26.1117.2309pre1 is still found and renamed when moved).

## 26.1117.2309pre1

- Link off: the Time marker (V) is the Timeline position when there are no loop points; the Timeline plays from it and the edit cursor (Edit position) stays; Insertion Follows Playback moves the marker, not the edit cursor.

## 26.1117.1556

- Play Timeline Selection without a Timeline Selection, pre-roll on: every retrigger starts the pre-roll before the Time position (it went on from where it was).

## 26.1117.1553pre1

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).
- Pre-roll / post-roll on: Space and Play Timeline Selection play from the pre-roll before the Timeline Selection to the post-roll after it; plain play starts the pre-roll before the playhead. toggle_rolls() for Pre Post Roll Playback.

## 26.1117.1552

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).
- Pre-roll / post-roll on: Space and Play Timeline Selection play from the pre-roll before the Timeline Selection to the post-roll after it; plain play starts the pre-roll before the playhead. toggle_rolls() for Pre Post Roll Playback.

## 26.1117.1546pre1

- Pre-roll / post-roll on: Space and Play Timeline Selection play from the pre-roll before the Timeline Selection to the post-roll after it; plain play starts the pre-roll before the playhead. toggle_rolls() for Pre Post Roll Playback.

## 26.1117.1259pre1

- Fix: the Insertion Follows Playback (N) button shows the saved state again after a REAPER restart (it looked off while N was on).

## 26.1116.2255

- Fix: the Insertion Follows Playback (N) button shows the saved state again after a REAPER restart (it looked off while N was on).

## 26.1116.2231pre1

- play_around_edit(): Play To / From / Through Edit Start / End with the pre-roll / post-roll lengths.

## 26.1116.2123pre1

- play_around_edit(): Play To / From / Through Edit Start / End with the pre-roll / post-roll lengths.

## 26.1116.2056

- Pre-roll / Post-roll settings (global, off by default) for the Counters Panel and the Play To / From / Through actions.

## 26.1116.1938pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2128

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2125pre1

- Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.

## 26.1115.2121pre1

- play_range() home: the playhead (edit cursor) can stay where it is while another range plays (Play Edit Selection).

## 26.1115.2111pre1

- Insertion Follows Playback on clears only the Timeline Selection (loop points); razor areas and the time selection are always kept.

## 26.1115.2053pre1

- Edit / Timeline Selection helpers, play_range() + Play Watcher (stop at the selection end), Pro Tools end rules. Play start = Timeline Selection start, else the edit cursor (a time selection that is only the Edit Selection no longer moves it).

## 26.1115.2045pre1

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

History before 26.1115.1407 (moved out of the script header; last header version: `0.1.0 [261115.1230]`).

```text
0.1.0 [261115.1230]
  - First version: copy of hsuanice_Transport Core (QuickPunch not included).
```

