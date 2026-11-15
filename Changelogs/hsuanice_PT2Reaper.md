# hsuanice_PT2Reaper.lua — Changelog

PT2Reaper package

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

