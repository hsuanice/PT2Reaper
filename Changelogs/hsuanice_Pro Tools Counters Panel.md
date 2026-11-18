# hsuanice_Pro Tools Counters Panel.lua — Changelog

hsuanice_Pro Tools Counters Panel

## 26.1118.1150pre1

- Edit Selection values in white (like razor areas), Timeline Selection values in cyan (like the loop points), blue when they show the Time marker. Also still: the Grid is checked again for 5 s after a project opens.

## 26.1118.1058pre1

- The Grid is checked again every 0.5 s for 5 s after REAPER starts / a project opens: the project's own grid (e.g. Frame) could still be loading at the first check.

## 26.1118.0059

- Release: Time marker shown and kept tidy; Link on, dragged loop points clear stale razor areas (tested in REAPER).

## 26.1118.0055pre1

- Link on: razor areas that no longer match dragged loop points are cleared at once (checked every frame, no settle delay).

## 26.1118.0047pre1

- Link on: loop points made on their own (dragged in the ruler) clear razor areas that no longer match them (Pro Tools: one selection).

## 26.1117.2320pre1

- Time marker: no name, marker number 9999 (a V or >< marker from the 26.1117 pre-releases is replaced when moved).

## 26.1117.2317pre1

- Time marker renamed from V to >< (a V marker from 26.1117.2309pre1 is still found and renamed when moved).

## 26.1117.2309pre1

- Link off: Timeline Selection counters show the Time marker (V) when there are no loop points; the marker is removed when loop points are made or Link is turned on.

## 26.1117.2043pre1

- The Grid follows the user (Pro Tools): when a project opens or another project tab is chosen with a different grid saved in it (e.g. Frame), the chosen Grid is put back.

## 26.1117.2017

- The Grid follows the user (Pro Tools): when a project opens or another project tab is chosen with a different grid saved in it (e.g. Frame), the chosen Grid is put back.

## 26.1117.2015pre1

- Updates at once when Pre Post Roll Playback (Cmd+K) switches the rolls; its toolbar button shows the saved state after a restart.

## 26.1117.1552

- Updates at once when Pre Post Roll Playback (Cmd+K) switches the rolls; its toolbar button shows the saved state after a restart.

## 26.1117.1259pre1

- Fix: the Insertion Follows Playback (N) button shows the saved state again after a REAPER restart (it looked off while N was on).

## 26.1116.2255

- Fix: the Insertion Follows Playback (N) button shows the saved state again after a REAPER restart (it looked off while N was on).

## 26.1116.2231pre1

- Hover info (after 0.5 s) on Grid, Nudge, Items / Tracks and Pre-roll / Post-roll.

## 26.1116.2056

- Hover info (after 0.5 s) on Grid, Nudge, Items / Tracks and Pre-roll / Post-roll.

## 26.1116.2053pre1

- Hover info (after 0.5 s) on Grid, Nudge, Items / Tracks and Pre-roll / Post-roll.

## 26.1116.2047pre1

- Hover info on Items / Tracks (item details window) and on Pre-roll / Post-roll (name: on / off, value: type the length).

## 26.1116.2042pre1

- Hover info on Items / Tracks: click opens the item details window, click again closes it.

## 26.1116.2037pre1

- Items under Grid / Nudge, Tracks under Pre / Post-roll, in their own zone with a line above; numbers grow to the left, nothing moves; no extra gap after Grid.

## 26.1116.2028pre1

- Fixed column width for Items / Tracks (up to 99999 / 9999): large counts no longer push the next sections onto a new row.

## 26.1116.1953pre1

- Selection details open in their own floating window (click Items or Tracks); the window reopens where it was.

## 26.1116.1945pre1

- First version: Edit Selection, Grid / Nudge + selection counts, Pre-roll / Post-roll and Timeline Selection in one dockable window.

## 26.1116.1938pre1

- First version: Edit Selection, Grid / Nudge + selection counts, Pre-roll / Post-roll and Timeline Selection in one dockable window.

