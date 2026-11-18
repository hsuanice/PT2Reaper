--[[
@description hsuanice_Pro Tools Pre Post Roll Playback
@version 26.1118.2039
@author hsuanice
@noindex
@changelog
  - Release: the rolls are used for recording too; turning them on turns REAPER's own pre-roll off (tested in REAPER).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Pre Post Roll Playback**
  (PT key: Command+K)

  Toggle for both rolls at once: either one on -> both off; both off -> both on.
  The lengths and the separate on / off switches are in the Counters Panel.
  On: Play/Stop and Play Timeline Selection start the pre-roll length before the Timeline
  Selection (the loop points) and stop the post-roll length after it; without a Timeline
  Selection, playback starts the pre-roll length before the playhead. The playhead stays
  where it is. The Edit Selection is not affected (Play Edit Selection plays it as it is).
  Recording (Record Punch, QuickPunch on or off) uses the same rolls: from the pre-roll
  before the Timeline Selection / Time position; a Timeline Selection is recorded alone and
  playback stops the post-roll length after it.
  Turning a roll on turns REAPER's own pre-roll (Metronome and pre-roll settings) off, so
  the two do not add up; the metronome is not touched.
  The toolbar button is lit while a roll is on.

  Self-contained: uses hsuanice_PT_Transport.lua (same folder).
  - Tags : Options menu, Transport
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
if not ok or type(T) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua\n\n' .. tostring(T), 'Error', 0)
  return
end

T.toggle_rolls()
r.defer(function() end) -- no undo point
