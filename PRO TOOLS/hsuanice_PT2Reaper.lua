--[[
@description PT2Reaper - Pro Tools style editing, nudge, fades and QuickPunch for REAPER
@version 26.1115.1548
@author hsuanice
@metapackage
@provides
  [main] hsuanice_Grid Nudge Panel.lua
  [main] hsuanice_Grid_Nudge_Panel_Reset_Position.lua
  [main] hsuanice_PT_Transient Settings.lua
  [main] hsuanice_Pro Tools Apply Next Fade Shape.lua
  [main] hsuanice_Pro Tools Apply Previous Fade Shape.lua
  [main] hsuanice_Pro Tools Clear All Soloed Tracks.lua
  [main] hsuanice_Pro Tools Clear.lua
  [main] hsuanice_Pro Tools Consolidate Selection.lua
  [main] hsuanice_Pro Tools Copy and Move Clip End To Current TC.lua
  [main] hsuanice_Pro Tools Copy and Move Clip End To Play Position.lua
  [main] hsuanice_Pro Tools Copy and Move Clip Start To Current TC.lua
  [main] hsuanice_Pro Tools Copy and Move Clip Start To Play Position.lua
  [main] hsuanice_Pro Tools Copy and Move Clip Sync Point To Current TC.lua
  [main] hsuanice_Pro Tools Copy and Move Clip Sync Point To Play Position.lua
  [main] hsuanice_Pro Tools Create Fades.lua
  [main] hsuanice_Pro Tools Decrease Grid Value.lua
  [main] hsuanice_Pro Tools Decrease Nudge Value.lua
  [main] hsuanice_Pro Tools Delete Fades.lua
  [main] hsuanice_Pro Tools Delete Selection.lua
  [main] hsuanice_Pro Tools Double Edit Selection.lua
  [main] hsuanice_Pro Tools Duplicate.lua
  [main] hsuanice_Pro Tools Edit Lock Clip.lua
  [main] hsuanice_Pro Tools Execute Crossfade using last setting.lua
  [main] hsuanice_Pro Tools Fade In From Start To Cursor.lua
  [main] hsuanice_Pro Tools Fade Out From Cursor To End.lua
  [main] hsuanice_Pro Tools Grid Mode.lua
  [main] hsuanice_Pro Tools Group Clips.lua
  [main] hsuanice_Pro Tools Halve Edit Selection.lua
  [main] hsuanice_Pro Tools Heal Separation.lua
  [main] hsuanice_Pro Tools Identify Sync Point.lua
  [main] hsuanice_Pro Tools Increase Grid Value.lua
  [main] hsuanice_Pro Tools Increase Nudge Value.lua
  [main] hsuanice_Pro Tools Input Monitor Tracks with an Edit Selection.lua
  [main] hsuanice_Pro Tools Insertion Follows Playback.lua
  [main] hsuanice_Pro Tools Link Timeline and Edit Selection.lua
  [main] hsuanice_Pro Tools Link Track And Edit Selection.lua
  [main] hsuanice_Pro Tools Loop Clips.lua
  [main] hsuanice_Pro Tools Move Clip End To Current TC.lua
  [main] hsuanice_Pro Tools Move Clip End To Play Position.lua
  [main] hsuanice_Pro Tools Move Clip Start To Current TC.lua
  [main] hsuanice_Pro Tools Move Clip Start To Play Position.lua
  [main] hsuanice_Pro Tools Move Clip Sync Point To Current TC.lua
  [main] hsuanice_Pro Tools Move Clip Sync Point To Play Position.lua
  [main] hsuanice_Pro Tools Move Edit Insertion Down.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Next Edit - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Next Edit.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Previous Edit - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Previous Edit.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Session End - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Session End.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Session Start - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Insertion To Song Start.lua
  [main] hsuanice_Pro Tools Move Edit Insertion Up.lua
  [main] hsuanice_Pro Tools Move Edit Selection To Next Clip - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Selection To Next Clip.lua
  [main] hsuanice_Pro Tools Move Edit Selection To Previous Clip - Extend Selection.lua
  [main] hsuanice_Pro Tools Move Edit Selection To Previous Clip.lua
  [main] hsuanice_Pro Tools Mute Tracks with an Edit Selection.lua
  [main] hsuanice_Pro Tools Mute Unmute Clip.lua
  [main] hsuanice_Pro Tools Nudge Clip Contents Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip Contents Later By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip End Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip End Later By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip Later By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip Start Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Clip Start Later By Grid.lua
  [main] hsuanice_Pro Tools Nudge Play Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Play Earlier By Next Larger Grid.lua
  [main] hsuanice_Pro Tools Nudge Play Later By Grid.lua
  [main] hsuanice_Pro Tools Nudge Play Later By Next Larger Grid.lua
  [main] hsuanice_Pro Tools Nudge Selection Earlier By Grid - Selection End - Selection Start.lua
  [main] hsuanice_Pro Tools Nudge Selection Earlier By Grid - Selection End.lua
  [main] hsuanice_Pro Tools Nudge Selection Earlier By Grid - Selection Start.lua
  [main] hsuanice_Pro Tools Nudge Selection Earlier By Grid.lua
  [main] hsuanice_Pro Tools Nudge Selection Later By Grid - Selection End - Selection Start.lua
  [main] hsuanice_Pro Tools Nudge Selection Later By Grid - Selection End.lua
  [main] hsuanice_Pro Tools Nudge Selection Later By Grid - Selection Start.lua
  [main] hsuanice_Pro Tools Nudge Selection Later By Grid.lua
  [main] hsuanice_Pro Tools Play Half Speed.lua
  [main] hsuanice_Pro Tools Play-Stop.lua
  [main] hsuanice_Pro Tools Quantize Clips.lua
  [main] hsuanice_Pro Tools QuickPunch.lua
  [main] hsuanice_Pro Tools Quit.lua
  [main] hsuanice_Pro Tools Record Arm Tracks with an Edit Selection.lua
  [main] hsuanice_Pro Tools Record Punch.lua
  [main] hsuanice_Pro Tools Redo.lua
  [main] hsuanice_Pro Tools Remove Edit Insertion From Bottom Track.lua
  [main] hsuanice_Pro Tools Remove Edit Insertion From Top Track.lua
  [main] hsuanice_Pro Tools Rename Clips.lua
  [main] hsuanice_Pro Tools Repeat.lua
  [main] hsuanice_Pro Tools Return To Zero.lua
  [main] hsuanice_Pro Tools Save As.lua
  [main] hsuanice_Pro Tools Save.lua
  [main] hsuanice_Pro Tools Select All.lua
  [main] hsuanice_Pro Tools Separate Clip At Selection.lua
  [main] hsuanice_Pro Tools Separate Clip At Transients.lua
  [main] hsuanice_Pro Tools Separate Clip On Grid.lua
  [main] hsuanice_Pro Tools Shrink Edit Selection To Next Edit.lua
  [main] hsuanice_Pro Tools Shrink Edit Selection To Previous Edit.lua
  [main] hsuanice_Pro Tools Shuffle Mode.lua
  [main] hsuanice_Pro Tools Slip Mode.lua
  [main] hsuanice_Pro Tools Snap To Next.lua
  [main] hsuanice_Pro Tools Snap To Previous.lua
  [main] hsuanice_Pro Tools Solo Tracks with an Edit Selection.lua
  [main] hsuanice_Pro Tools Space Clips.lua
  [main] hsuanice_Pro Tools Spot Mode.lua
  [main] hsuanice_Pro Tools Tab to Transient.lua
  [main] hsuanice_Pro Tools Time Lock Clip.lua
  [main] hsuanice_Pro Tools Trim Clip End To Cursor.lua
  [main] hsuanice_Pro Tools Trim Clip End to Fill Selection.lua
  [main] hsuanice_Pro Tools Trim Clip Start To Cursor.lua
  [main] hsuanice_Pro Tools Trim Clip Start To Fill Selection.lua
  [main] hsuanice_Pro Tools Trim Clip To File Boundaries.lua
  [main] hsuanice_Pro Tools Trim Clip To Fill Selection.lua
  [main] hsuanice_Pro Tools Trim Clip To Selection.lua
  [main] hsuanice_Pro Tools Trim Clips End To File End.lua
  [main] hsuanice_Pro Tools Trim Clips Start To File Start.lua
  [main] hsuanice_Pro Tools Undo.lua
  [main] hsuanice_Pro Tools Ungroup Clips.lua
  [main] hsuanice_Pro Tools Unloop Clips.lua
  [main] hsuanice_Pro Tools Zoom Toggle.lua
  [nomain] hsuanice_PT_Fades.lua
  [nomain] hsuanice_PT_GFXInputField.lua
  [nomain] hsuanice_PT_Grid.lua
  [nomain] hsuanice_PT_Nudge.lua
  [nomain] hsuanice_PT_NudgeEdge.lua
  [nomain] hsuanice_PT_QuickPunch Pass Monitor.lua
  [nomain] hsuanice_PT_QuickPunch.lua
  [nomain] hsuanice_PT_TrackEdit.lua
  [nomain] hsuanice_PT_Transient.lua
  [nomain] hsuanice_PT_Transport.lua
  [nomain] hsuanice_PT_Trim.lua
@changelog
  - Tested in REAPER: Move Edit Insertion Up / Down, Remove Edit Insertion From Top / Bottom Track.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # PT2Reaper

  Pro Tools style editing for REAPER: one REAPER action per Pro Tools command, named after the
  Pro Tools command (Action List: search "Pro Tools").

  Highlights
  - Nudge: clip / clip start / end / contents / selection / play, by the Nudge value of the
    Grid Nudge Panel (Pro Tools Nudge presets: Measure, Min:Secs, Timecode, Feet+Frames, Samples).
  - Edit selection: Tab to Transient, Move / Extend / Shrink Edit Selection, Double / Halve,
    Separate Clip (at selection, on grid, at transients), Trim, Clear / Delete with partial fades.
  - Fades: Create Fades, Delete Fades, fade shapes, crossfades.
  - Transport: Play/Stop, Play Half Speed, Insertion Follows Playback, QuickPunch and Record Punch
    (punch in / out while playing; the pass records in the background on hidden "QP buffer" tracks).

  How to use
  - Nothing is bound automatically. A good way: put the Pro Tools keys in an alternate keymap
    section (Action List > Section: "Main (alt-1)") and switch with
    "Main action section: Toggle override to alt-1", so your own REAPER keys stay untouched.
  - The Grid Nudge Panel shows and sets the Grid and Nudge values.

  Requirements
  - REAPER 7.
  - js_ReaScriptAPI (optional): the Grid Nudge Panel gives the keyboard focus back to the
    arrange view after a click.

  Credits
  - Transport (Play/Stop, Play Half Speed, Insertion Follows Playback): behaviour modelled on
    TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts).
  - Pro Tools is a trademark of Avid Technology; this project is not affiliated with Avid.
  - Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.

  ## Suggested shortcuts (Pro Tools keys)
  - Apply Next Fade Shape: Opt+Control+Right
  - Apply Previous Fade Shape: Opt+Control+Left
  - Clear: Cmd+B
  - Consolidate Selection: Opt+#, Opt+Shift+NumPad 3
  - Copy and Move Clip End To Current TC: Opt+Control+I
  - Copy and Move Clip End To Play Position: Opt+Control+K
  - Copy and Move Clip Start To Current TC: Opt+Control+Y
  - Copy and Move Clip Start To Play Position: Opt+Control+H
  - Copy and Move Clip Sync Point To Current TC: Opt+Control+U
  - Copy and Move Clip Sync Point To Play Position: Opt+Control+J
  - Create Fades: Cmd+F
  - Decrease Grid Value: _, Opt+Control+NumPad -
  - Decrease Nudge Value: Cmd+Opt+NumPad -, Opt+_, Cmd+Opt+-
  - Delete Selection: Delete, Backspace
  - Double Edit Selection: Cmd+Opt+Control+"
  - Duplicate: Cmd+D
  - Edit Lock Clip: Cmd+L
  - Execute Crossfade using last setting: Cmd+Control+F, Control+F, F
  - Fade In From Start To Cursor: D, Control+D
  - Fade Out From Cursor To End: Control+G, G
  - Grid Mode: Opt+4, F4
  - Group Clips: Cmd+Opt+G
  - Halve Edit Selection: Cmd+Opt+Shift+Control+L
  - Heal Separation: Cmd+H
  - Identify Sync Point: Cmd+,
  - Increase Grid Value: +, Opt+Control+NumPad +
  - Increase Nudge Value: Opt++, Cmd+Opt+NumPad +, Cmd+Opt+=
  - Input Monitor Tracks with an Edit Selection: Shift+I
  - Insertion Follows Playback: N, Control+N
  - Link Timeline and Edit Selection: Shift+NumPad /, ?
  - Link Track And Edit Selection: Shift+T
  - Loop Clips: Cmd+Opt+L
  - Move Clip End To Current TC: Control+I, I
  - Move Clip End To Play Position: K, Control+K
  - Move Clip Start To Current TC: Control+Y, Y
  - Move Clip Start To Play Position: Control+H, H
  - Move Clip Sync Point To Current TC: Control+U, U
  - Move Clip Sync Point To Play Position: J, Control+J
  - Move Edit Insertion Down: ;, Control+;
  - Move Edit Insertion To Next Edit - Extend Selection: ", Control+", Shift+Tab
  - Move Edit Insertion To Next Edit: ', Control+', Tab
  - Move Edit Insertion To Previous Edit - Extend Selection: Shift+Control+L, Opt+Shift+Tab, Shift+L
  - Move Edit Insertion To Previous Edit: L, Control+L, Opt+Tab
  - Move Edit Insertion To Session End - Extend Selection: Opt+Shift+Return
  - Move Edit Insertion To Session End: Opt+Return
  - Move Edit Insertion To Session Start - Extend Selection: Shift+Return
  - Move Edit Insertion To Song Start: Shift+Control+Return
  - Move Edit Insertion Up: P, Control+P
  - Move Edit Selection To Next Clip - Extend Selection: Cmd+Control+", Shift+Control+Tab
  - Move Edit Selection To Next Clip: Cmd+Control+', Control+Tab
  - Move Edit Selection To Previous Clip - Extend Selection: Opt+Shift+Control+Tab, Cmd+Shift+Control+L
  - Move Edit Selection To Previous Clip: Opt+Control+Tab, Cmd+Control+L
  - Mute Tracks with an Edit Selection: Shift+M
  - Mute Unmute Clip: Cmd+M
  - Nudge Clip Contents Earlier By Grid: Control+NumPad -
  - Nudge Clip Contents Later By Grid: Control+NumPad +
  - Nudge Clip Earlier By Grid: NumPad -
  - Nudge Clip End Earlier By Grid: Cmd+NumPad -
  - Nudge Clip End Later By Grid: Cmd+NumPad +
  - Nudge Clip Later By Grid: NumPad +
  - Nudge Clip Start Earlier By Grid: Opt+NumPad -
  - Nudge Clip Start Later By Grid: Opt+NumPad +
  - Nudge Play Earlier By Grid: Control+,, ,
  - Nudge Play Earlier By Next Larger Grid: Control+M, M
  - Nudge Play Later By Grid: Control+., .
  - Nudge Play Later By Next Larger Grid: /, Control+/
  - Nudge Selection Earlier By Grid - Selection End - Selection Start: Cmd+Opt+Shift+NumPad -
  - Nudge Selection Earlier By Grid - Selection End: Cmd+Shift+NumPad -
  - Nudge Selection Earlier By Grid - Selection Start: Opt+Shift+NumPad -
  - Nudge Selection Earlier By Grid: Shift+NumPad -
  - Nudge Selection Later By Grid - Selection End - Selection Start: Cmd+Opt+Shift+NumPad +
  - Nudge Selection Later By Grid - Selection End: Cmd+Shift+NumPad +
  - Nudge Selection Later By Grid - Selection Start: Opt+Shift+NumPad +
  - Nudge Selection Later By Grid: Shift+NumPad +
  - Play Half Speed: Shift+Space
  - Play-Stop: NumPad 0, Space
  - Quantize Clips: Cmd+NumPad 0, Cmd+0
  - QuickPunch: NumPad 6, Cmd+Shift+P
  - Quit: Cmd+Q
  - Record Arm Tracks with an Edit Selection: Shift+R
  - Record Punch: F12, Cmd+Space, NumPad 3
  - Redo: Shift+Control+Z, Shift+Z, Cmd+Shift+Z
  - Remove Edit Insertion From Bottom Track: Opt+Control+;
  - Remove Edit Insertion From Top Track: Opt+Control+P
  - Rename Clips: Cmd+Opt+Shift+R
  - Repeat: Opt+R
  - Return To Zero: Return
  - Save As: Cmd+Control+S
  - Save: Cmd+S
  - Select All: Cmd+A
  - Separate Clip At Selection: B, Control+B, Cmd+E
  - Shrink Edit Selection To Next Edit: Cmd+Opt+Shift+L
  - Shrink Edit Selection To Previous Edit: Cmd+Opt+"
  - Shuffle Mode: Opt+1, F1
  - Slip Mode: F2, Opt+2
  - Snap To Next: Opt+Control+.
  - Snap To Previous: Opt+Control+,
  - Solo Tracks with an Edit Selection: Shift+S
  - Space Clips: Opt+Shift+H
  - Spot Mode: F3, Opt+3
  - Tab to Transient: Cmd+Opt+Tab
  - Time Lock Clip: Opt+Control+L
  - Trim Clip End To Cursor: Opt+*, Opt+Shift+NumPad 8, S, Control+S
  - Trim Clip Start To Cursor: Opt+&, A, Control+A, Opt+Shift+NumPad 7
  - Trim Clip To File Boundaries: Cmd+Control+T
  - Trim Clip To Selection: Cmd+T
  - Trim Clips End To File End: Cmd+Control+Y
  - Trim Clips Start To File Start: Cmd+Control+R
  - Undo: Z, Control+Z, Cmd+Z
  - Ungroup Clips: Cmd+Opt+U
  - Zoom Toggle: Control+E, E

  Shortcuts are suggestions only (the Pro Tools keys) - nothing is assigned automatically. macOS names; on Windows Cmd = Ctrl, Option = Alt, Control = Win.
@links
  GitHub https://github.com/hsuanice/PT2Reaper
  Forum thread https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]
-- This file only describes the package for ReaPack; it is not installed.
