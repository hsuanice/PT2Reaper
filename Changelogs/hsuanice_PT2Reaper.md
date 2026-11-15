# hsuanice_PT2Reaper.lua — Changelog

PT2Reaper package

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

