--[[
@description hsuanice_PT_Play Watcher - stops playback at the end of a played selection (PT2Reaper)
@version 26.1115.2045pre1
@author hsuanice
@noindex
@changelog
  - First version.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Background helper of Play/Stop, Play Edit Selection and Play Timeline Selection.
  Not an action to run by hand: those scripts launch it (when it is not running yet) and it
  ends by itself when there is nothing left to watch.

  Stops playback at the end of the range that was started (Pro Tools: playback of a
  selection stops at its end). Insertion Follows Playback on: the edit cursor stays at the
  end and the Timeline Selection is cleared; off: back to the range start.
  With Repeat on, playback goes back to the range start instead.
  When asked to start after a QuickPunch pass, waits until the pass is finished.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local T = dofile(DIR .. 'hsuanice_PT_Transport.lua')
local okq, QP = pcall(dofile, DIR .. 'hsuanice_PT_QuickPunch.lua')
if not okq or type(QP) ~= 'table' then QP = nil end

-- launched again while running (should not happen: the heartbeat prevents it): no dialog
if r.set_action_options then r.set_action_options(1 | 2) end

local EPS = 1e-9
local last_watch, seen_running, since = nil, false, r.time_precise()

local function finish()
  r.SetExtState(T.NS, "watcher_hb", "", false)
end

local function loop()
  r.SetExtState(T.NS, "watcher_hb", string.format("%.3f", r.time_precise()), false)
  local w = r.GetExtState(T.NS, "watch")
  if w ~= last_watch then last_watch, seen_running, since = w, false, r.time_precise() end
  local s, e = T.watch_get()
  if not s then return finish() end

  -- start after a QuickPunch pass: wait until it is stopped and finished
  if r.GetExtState(T.NS, "wait_qp") == "1" then
    if r.GetPlayState() ~= 0 or (QP and QP.pass_active()) then
      if r.time_precise() - since > 10 then T.watch_clear(); return finish() end -- give up
      return r.defer(loop)
    end
    r.SetExtState(T.NS, "wait_qp", "", false)
    r.SetEditCurPos2(0, s, true, false)
    r.Main_OnCommand(1007, 0) -- Transport: Play
    since = r.time_precise()
    return r.defer(loop)
  end

  local st = r.GetPlayState()
  if st & 4 == 4 then T.watch_clear(); return finish() end -- recording: not ours
  if st & 1 == 0 then
    -- stopped elsewhere (Space, Stop): done. Just started: give the transport a moment.
    if seen_running or r.time_precise() - since > 0.5 then T.watch_clear(); return finish() end
    return r.defer(loop)
  end
  seen_running = true

  if r.GetPlayPosition() >= e - EPS then
    if r.GetSetRepeat(-1) == 1 then
      r.SetEditCurPos2(0, s, false, true)
    else
      T.watch_clear()
      T.range_end(s, e)
      return finish()
    end
  end
  r.defer(loop)
end

r.atexit(finish)
loop()
