# PT2Reaper

Pro Tools style editing for REAPER — one REAPER action per Pro Tools command, named after the
Pro Tools command, so Pro Tools muscle memory works in REAPER.

## Install (ReaPack)

1. Extensions > ReaPack > Import repositories…, paste:
   `https://github.com/hsuanice/PT2Reaper/raw/master/index.xml`
2. Extensions > ReaPack > Browse packages… > install **PT2Reaper**.
3. Action List: search **Pro Tools**.

Everything is one package: the actions plus the shared files they need (no other package to install).

## What's inside

- **Nudge** — Nudge Clip / Clip Start / Clip End / Clip Contents / Selection / Play,
  earlier / later, by the Nudge value (and "Next Larger"). Pro Tools Nudge presets
  (Measure, Min:Secs, Timecode, Feet+Frames, Samples) in the **Grid Nudge Panel**.
- **Edit selection** — Tab to Transient, Move / Extend / Shrink Edit Selection,
  Double / Halve Edit Selection, Link Timeline and Edit Selection.
- **Editing** — Separate Clip (at selection, on grid, at transients), Trim Clip, Clear,
  Delete Selection (partial fades kept), Repeat, Snap To Next / Previous, Space Clips,
  Quantize Clips, Rename Clips, Group / Ungroup, Lock, Loop, Mute.
- **Fades** — Create Fades, Delete Fades, Apply Next / Previous Fade Shape, crossfades.
- **Transport** — Play/Stop, Play Half Speed, Insertion Follows Playback,
  **QuickPunch** + **Record Punch** (punch in / out while playing; the pass records in the
  background on hidden "QP buffer" tracks, one Undo goes back to before Play).
- **Session** — Save, Save As, Quit, Zoom Toggle, Spot Mode.

The package's About page (ReaPack > Browse packages > PT2Reaper > About) lists every action
with its Pro Tools shortcut.

## Shortcuts

Nothing is bound automatically. Suggested setup: put the Pro Tools keys in an alternate
keymap section (Action List > Section: **Main (alt-1)**) and switch with
"Main action section: Toggle override to alt-1" — your own REAPER keys stay untouched.

## Requirements

- REAPER 7
- js_ReaScriptAPI (optional): the Grid Nudge Panel gives the keyboard focus back to the
  arrange view after a click.

## Credits

- Transport (Play/Stop, Play Half Speed, Insertion Follows Playback): behaviour modelled on
  [TJF Scripts](https://github.com/sonictim/TJF-Scripts) by Tim Farrell.
- Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
- Pro Tools is a trademark of Avid Technology, Inc. This project is not affiliated with Avid.

## Links

- Forum thread: https://forum.cockos.com/showthread.php?p=2910884#post2910884
- Changelogs: [Changelogs/](Changelogs/)
- More scripts by hsuanice: https://github.com/hsuanice/ReaScripts
