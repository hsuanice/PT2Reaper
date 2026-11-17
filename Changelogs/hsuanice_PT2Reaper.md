# hsuanice_PT2Reaper.lua — Changelog

PT2Reaper package

## 26.1118.0114

- Release: Change Edit to Match Timeline / Change Timeline to Match Edit (+ Start / End) (tested in REAPER and Pro Tools)

## 26.1118.0102pre1

- Change Edit to Match Timeline / Change Timeline to Match Edit (+ Start / End): Pro Tools behaviour with loop points, razor areas and the Time marker

## 26.1118.0059

- Release: Time marker / ruler clicks (Pro Tools Timeline and Marker rulers), Link-off playback keeps the Edit position, Play Edit Selection from the Edit position (tested in REAPER)

## 26.1118.0055pre1

- Counters Panel: stale razor areas cleared at once when the loop points are dragged (Link on)

## 26.1118.0047pre1

- Link on: loop points dragged on their own clear stale razor areas; ruler lane double click (Link off) moves the Edit position to the range start

## 26.1118.0028pre1

- Ruler: time scale vs marker / region lanes (SWS) - Pro Tools Timeline ruler vs Marker ruler

## 26.1118.0008pre1

- Click Timeline Ruler with Link on clears every range (razor areas, time selection, loop points)

## 26.1117.2344pre1

- Link Timeline and Edit Selection turned on removes the Time marker

## 26.1117.2341pre1

- Time marker duplicates cleaned up (one only); ruler double click: gap between the nearest markers or region edges

## 26.1117.2337pre1

- Ruler double click: time selection between the nearest markers; loop points and Time marker kept. Time marker named >

## 26.1117.2320pre1

- Time marker: no name, marker number 9999 (older V / >< markers are replaced when moved)

## 26.1117.2317pre1

- Time marker renamed V -> >< (an existing V marker is still found and renamed)

## 26.1117.2316pre1

- Double Click Timeline Ruler: time selection to region / between markers without counting the Time marker (V)

## 26.1117.2309pre1

- Link off: the Time marker (V) is the Timeline position - Click Timeline Ruler (mouse modifier) sets it, the Timeline plays from it and the edit cursor (Edit position) stays

## 26.1117.2247pre1

- Play Edit Selection pressed again while playing from a position: plays from the Edit position again

## 26.1117.2242pre1

- Play Edit Selection with no Edit range plays from the Edit position (playhead), not from the loop points

## 26.1117.2043pre1

- Restore Last Selection (Cmd+Opt+Z): the Counters Panel remembers the previous Edit Selection; one level, swaps current and previous (Pro Tools).

## 26.1117.2017

- Release: the Grid follows the user when a project opens or a project tab is switched (tested in REAPER).

## 26.1117.2015pre1

- The Grid follows the user (Pro Tools): when a project opens or another project tab is chosen with a different grid saved in it (e.g. Frame), the chosen Grid is put back.

## 26.1117.1556

- Release: Play Timeline Selection without a Timeline Selection retriggers with the pre-roll (tested in REAPER).

## 26.1117.1553pre1

- Play Timeline Selection without a Timeline Selection, pre-roll on: every retrigger starts the pre-roll before the Time position (it went on from where it was).

## 26.1117.1552

- Release: Pre Post Roll Playback (Cmd+K) - the pre-roll / post-roll play around the Timeline Selection (tested in REAPER).

## 26.1117.1546pre1

- Insertion Follows Playback on with pre-roll / post-roll: stops at the post-roll end and clears the Timeline Selection, as without the rolls (26.1117.1532pre1 kept the selections - reverted).

## 26.1117.1423pre1

- Fix: with QuickPunch mode on and no armed track, Space now plays the Timeline Selection and stops at its end (it played on).

## 26.1117.1259pre1

- Pre Post Roll Playback (Cmd+K): one toggle for both rolls; the rolls now play around the Timeline Selection (Space, Play Timeline Selection).

## 26.1116.2255

- Release: Play To / From / Through Edit Start / End (tested in REAPER); the N button shows the saved state after a restart.

## 26.1116.2231pre1

- Fix: the Insertion Follows Playback (N) button shows the saved state again after a REAPER restart (it looked off while N was on).

## 26.1116.2123pre1

- Play To / From / Through Edit Start / End: Pro Tools behaviour with the Pre-roll / Post-roll lengths.

## 26.1116.2056

- Tested in REAPER: Counters Panel (with details window and hover info).

## 26.1116.2053pre1

- Counters Panel: hover info on Grid / Nudge.

## 26.1116.2047pre1

- Counters Panel: hover info on Pre-roll / Post-roll.

## 26.1116.2042pre1

- Counters Panel: hover info on Items / Tracks.

## 26.1116.2037pre1

- Counters Panel: Items / Tracks in their own zone.

## 26.1116.2028pre1

- Counters Panel: fixed width for Items / Tracks counts.

## 26.1116.1953pre1

- Counters Panel: click Items or Tracks for the details; windows reopen where they were.

## 26.1116.1945pre1

- Counters Panel: the selection details open in their own floating window.

## 26.1116.1938pre1

- Counters Panel: Edit Selection, Grid / Nudge with selection counts, Pre-roll / Post-roll and Timeline Selection in one dockable window.

## 26.1115.2128

- Tested in REAPER: Play/Stop, Play Edit Selection, Play Timeline Selection with Pro Tools Insertion Follows Playback / Link rules.

## 26.1115.2125pre1

- Insertion Follows Playback on + Link Timeline and Edit Selection on: the Edit Selection is cleared together with the loop points.

## 26.1115.2121pre1

- Play Edit Selection: the playhead (edit cursor) stays where it was while the Edit Selection plays.

## 26.1115.2111pre1

- Timeline Selection = the loop points only; Insertion Follows Playback on clears only the loop points - razor areas and the time selection are always kept.

## 26.1115.2104pre1

- Play Timeline Selection: retrigger with Insertion Follows Playback on clears the Timeline Selection.

## 26.1115.2100pre1

- Play Timeline Selection: retrigger while playing - Insertion Follows Playback on from the playhead, off from the selection start.

## 26.1115.2057pre1

- Play Timeline Selection: pressed while playing always plays again from the start.

## 26.1115.2053pre1

- Fix: with no Timeline Selection, playback starts at the edit cursor (Link off: the Edit Selection no longer moves the play start).

## 26.1115.2045pre1

- Play Edit Selection / Play Timeline Selection / Play-Stop: Pro Tools behaviour - stop at the selection end; Insertion Follows Playback and Link Timeline and Edit Selection decide where playback ends and what is cleared.

## 26.1115.1932

- Tested in REAPER: Mouse - Shift-Click Extends Edit Selection, Double-Click Selects Gap Between Clips, Shift-Double-Click Extends Edit Selection Over Gap.

## 26.1115.1930pre1

- Pro Tools: Shift-click on a track outside the selection only adds the track (the range stays).

## 26.1115.1920pre1

- Shift-click inside the Edit Selection trims the nearer edge to the click (Pro Tools).

## 26.1115.1825pre1

- Mouse modifier actions: Shift-click extends the Edit Selection; double-click empty track space selects the gap between clips; Shift-double-click adds the gap.

## 26.1115.1638

- Tested in REAPER: Extend Edit Insertion Up / Down.

## 26.1115.1555pre1

- New: Extend Edit Insertion Up / Down (the selection only grows by one track).

## 26.1115.1548

- Tested in REAPER: Move Edit Insertion Up / Down, Remove Edit Insertion From Top / Bottom Track.

## 26.1115.1539pre1

- Move Edit Insertion Up / Down: the edit selection collapses to one track below / above its top track, like Pro Tools.

## 26.1115.1533pre1

- New: Move Edit Insertion Up / Down, Remove Edit Insertion From Top / Bottom Track.

## 26.1115.1531

- Tested in REAPER: Solo / Mute / Record Arm / Input Monitor Tracks with an Edit Selection, Clear All Soloed Tracks, Return To Zero, Move Edit Insertion To Song Start / Session End.

## 26.1115.1524pre1

- Return To Zero, Move Edit Insertion To Song Start / Session End: clear every kind of selection (time selection, loop points, razor areas, item selection); track selection stays.

## 26.1115.1519pre1

- Tracks with an Edit Selection: each track really flips its own state (no selection ganging).
- New: Return To Zero - edit cursor to the project start, edit selection cleared.

## 26.1115.1513pre1

- Tracks with an Edit Selection: every track flips its own state, like Pro Tools (a mixed selection stays mixed).
- Move Edit Insertion To Session End (+ Extend Selection): session end = last item on a visible track (hidden tracks made it jump far too late).

## 26.1115.1428pre1

- New: Solo / Mute / Record Arm / Input Monitor Tracks with an Edit Selection, Clear All Soloed Tracks, Move Edit Insertion To Session End / Song Start.

## 26.1115.1407

- First release of the PT2Reaper package (all Pro Tools actions in one package).
- File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".

