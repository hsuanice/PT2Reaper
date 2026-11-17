--[[
@description hsuanice_Pro Tools Play Timeline Selection
@version 26.1117.1532pre1
@author hsuanice
@noindex
@changelog
  - Pre-roll / post-roll on: when the Timeline Selection has played to its end, the Time and Edit selections are kept even with Insertion Follows Playback on (as Pro Tools); the playhead goes back to the Timeline Selection start.
  - Pre-roll / post-roll on (Counters Panel, Cmd+K): plays from the pre-roll before the Timeline Selection to the post-roll after it. The playhead stays at the Timeline Selection start.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Play Timeline Selection**
  (PT key: Control+], Option+])

  Plays the Timeline Selection (the loop points) and stops at its end - like Space, but it always plays
  (never stops). Insertion Follows Playback on: the edit cursor stays at the end and the
  Timeline Selection is cleared; off: back to its start, selections kept.
  Pressed while playing (retrigger): Insertion Follows Playback on - plays again from where
  playback is now and clears the Timeline Selection (linked: the Edit Selection too); off - from the selection start
  (no selection: the edit cursor).
  No selection: plays from the edit cursor.
  During a QuickPunch pass: ends the recording, then plays.

  Self-contained: uses hsuanice_PT_Transport.lua, hsuanice_PT_QuickPunch.lua and
  hsuanice_PT_Play Watcher.lua (same folder).
  - Tags : Transport, Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok1, T = pcall(dofile, DIR .. 'hsuanice_PT_Transport.lua')
local ok2, QP = pcall(dofile, DIR .. 'hsuanice_PT_QuickPunch.lua')
if not ok1 or type(T) ~= 'table' or not ok2 or type(QP) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_Transport.lua / hsuanice_PT_QuickPunch.lua\n\n'
    .. tostring(ok1 and '' or T) .. tostring(ok2 and '' or QP), 'Error', 0)
  return
end

T.reset_half_speed()
T.refresh_follows_button()

local s, e, home, keep = T.timeline_bounds() -- with the pre-roll / post-roll when they are on
if QP.pass_active() and T.is_running() then
  QP.stop(T.follows())
  if s then T.play_range(s, e, true, home, keep) else T.play_range(r.GetCursorPosition(), 1e12, true) end
elseif T.is_running() then
  -- retrigger. Insertion Follows Playback on: from where playback is now (the insertion
  -- follows it) and the Timeline Selection is cleared (no stop at its end any more);
  -- off: from the Timeline Selection start, else from the edit cursor.
  if T.follows() then
    if s then T.watch_clear(); T.clear_timeline(); r.UpdateArrange() end
    r.SetEditCurPos2(0, r.GetPlayPosition(), false, true)
  elseif s then
    T.play_range(s, e, false, home, keep)
  else
    T.watch_clear(); r.SetEditCurPos2(0, r.GetCursorPosition(), false, true)
  end
elseif s then
  T.play_range(s, e, false, home, keep)
else
  T.play()
end
r.defer(function() end) -- no undo point
