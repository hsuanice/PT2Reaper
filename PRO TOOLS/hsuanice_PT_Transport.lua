--[[
@description hsuanice_PT_Transport - Transport Library (PT2Reaper)
@version 26.1115.2125pre1
@author hsuanice
@noindex
@changelog
  - Insertion Follows Playback on with Link Timeline and Edit Selection on: the Edit Selection (razor areas, time selection) is cleared together with the loop points; Link off: only the loop points.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the PT2Reaper transport scripts (Play-Stop, Play Half Speed,
  Insertion Follows Playback). Loaded with dofile(); not an action.
  Copied from Beta Testing/QuickPunch/hsuanice_Transport Core.lua (26.1114) so the
  PT script set is self-contained; own ExtState namespace "hsuanice_PT_Transport"
  (independent of the Main keymap's Transport scripts).
  Credits: behaviour modelled on TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts):
  TJF playback that reads insertion toggle, TJF Toggle Insertion follows Playback,
  TJF Playback at Half Speed once.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local T = {}
T.NS = "hsuanice_PT_Transport"

local CMD_PLAY = 1007
local CMD_STOP = 1016
local CMD_EDIT_TO_PLAY = 40434 -- View: Move edit cursor to play cursor

-- Insertion Follows Playback (Pro Tools "N"): saved, survives a REAPER restart.
function T.follows() return r.GetExtState(T.NS, "insertion_follows") == "1" end
function T.refresh_follows_button()
  local cmd = tonumber(r.GetExtState(T.NS, "cmd_follows"))
  if cmd then
    r.SetToggleCommandState(0, cmd, T.follows() and 1 or 0)
    r.RefreshToolbar2(0, cmd)
  end
end
function T.set_follows(on)
  r.SetExtState(T.NS, "insertion_follows", on and "1" or "0", true)
  T.refresh_follows_button()
end

-- Half speed is "once": any stop / next play goes back to normal speed.
function T.set_half_speed()
  r.CSurf_OnPlayRateChange(0.5)
  r.SetExtState(T.NS, "half_speed", "1", false)
end
function T.reset_half_speed()
  if r.GetExtState(T.NS, "half_speed") == "1" then
    r.CSurf_OnPlayRateChange(1)
    r.SetExtState(T.NS, "half_speed", "0", false)
  end
end

-- Where playback starts: the start of the Timeline Selection, else the edit cursor.
-- The edit cursor is neutral (Pro Tools): a time selection that is only the Edit Selection
-- (razor areas / time selection) does not move the play start.
function T.start_position()
  local s = T.timeline_range()
  return s or r.GetCursorPosition()
end

function T.is_running() return r.GetPlayState() ~= 0 end

function T.play()
  r.SetEditCurPos2(0, T.start_position(), true, false)
  r.Main_OnCommand(CMD_PLAY, 0)
end

-- Insertion Follows Playback on: the edit cursor stays where playback stopped.
function T.before_stop()
  if T.follows() then r.Main_OnCommand(CMD_EDIT_TO_PLAY, 0) end
end

function T.stop()
  T.before_stop()
  r.Main_OnCommand(CMD_STOP, 0)
end

------------------------------------------------------------------------------
-- Selections (Pro Tools -> REAPER)
--   Edit Selection     = razor areas (union of track-level areas), else the time selection
--   Timeline Selection = the loop points (always; with Link Timeline and Edit Selection on,
--                        REAPER 40621 makes them follow the time selection)
--   The edit cursor is the playhead and belongs to neither selection.
------------------------------------------------------------------------------
local EPS = 1e-9
local CMD_LINK = 40621
T.WATCHER_SCRIPT = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or '') .. "hsuanice_PT_Play Watcher.lua"

function T.linked() return r.GetToggleCommandState(CMD_LINK) == 1 end

function T.edit_range()
  local s, e
  for i = 0, r.CountTracks(0) - 1 do
    local _, str = r.GetSetMediaTrackInfo_String(r.GetTrack(0, i), "P_RAZOREDITS", "", false)
    for a, b, g in (str or ""):gmatch('(%S+)%s+(%S+)%s+"([^"]*)"') do
      local x, y = tonumber(a), tonumber(b)
      if g == "" and x and y and y > x + EPS then
        s = s and math.min(s, x) or x
        e = e and math.max(e, y) or y
      end
    end
  end
  if s then return s, e end
  local ts, te = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if te > ts + EPS then return ts, te end
end

function T.timeline_range()
  local ls, le = r.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)
  if le > ls + EPS then return ls, le end
end

-- Insertion Follows Playback on: stopping clears the Timeline Selection (the loop points).
-- Link Timeline and Edit Selection on: the Edit Selection is linked to it and is cleared too
-- (razor areas, time selection); off: the Edit Selection is kept.
function T.clear_timeline()
  if T.linked() then
    r.Main_OnCommand(42406, 0) -- Razor edit: Clear all areas
    r.GetSet_LoopTimeRange2(0, true, false, 0, 0, false)
  end
  r.GetSet_LoopTimeRange2(0, true, true, 0, 0, false)
end

------------------------------------------------------------------------------
-- Play a range and stop at its end (Pro Tools Play Edit / Timeline Selection, Space)
-- The key scripts end at once; "hsuanice_PT_Play Watcher.lua" (a separate defer script,
-- launched when it is not running) stops playback at the range end. State in ExtState:
--   watch = "start,end" (empty = nothing to watch), wait_qp = "1" (start after QuickPunch)
------------------------------------------------------------------------------
function T.watch_get()
  local a, b = r.GetExtState(T.NS, "watch"):match("^([^,]+),([^,]+)$")
  return tonumber(a), tonumber(b)
end
function T.watch_clear() r.SetExtState(T.NS, "watch", "", false); r.SetExtState(T.NS, "watch_home", "", false) end

local function ensure_watcher()
  local hb = tonumber(r.GetExtState(T.NS, "watcher_hb"))
  if hb and r.time_precise() - hb < 1 then return end
  local cmd = r.AddRemoveReaScript(true, 0, T.WATCHER_SCRIPT, true)
  if cmd and cmd ~= 0 then r.Main_OnCommand(cmd, 0) end
end

-- Start (or restart) playback at s and stop at e. Playing already: seek to s.
-- after_qp: wait until the QuickPunch pass is finished, then start.
-- home (optional): where the edit cursor (playhead) stays - playback runs from s, the edit
-- cursor goes back to home at once and stays there (Play Edit Selection: the playhead /
-- Timeline position is not lost). Without it, the playhead is s.
function T.play_range(s, e, after_qp, home)
  r.SetExtState(T.NS, "watch", string.format("%.10f,%.10f", s, e), false)
  r.SetExtState(T.NS, "watch_home", home and string.format("%.10f", home) or "", false)
  if after_qp then
    r.SetExtState(T.NS, "wait_qp", "1", false)
  else
    r.SetExtState(T.NS, "wait_qp", "", false)
    T.start_at(s, home)
  end
  ensure_watcher()
end

-- Playback from s (seek when already playing); then the edit cursor back to home (no seek)
function T.start_at(s, home)
  if T.is_running() then
    r.SetEditCurPos2(0, s, false, true) -- seek
  else
    r.SetEditCurPos2(0, s, true, false)
    r.Main_OnCommand(CMD_PLAY, 0)
  end
  if home then r.SetEditCurPos2(0, home, false, false) end
end

function T.watch_home() return tonumber(r.GetExtState(T.NS, "watch_home")) end

-- What happens when playback reaches the range end (Pro Tools):
--   Insertion Follows on : stop at the end, clear the Timeline Selection
--   off                  : stop, back to the range start (or the playhead it kept), all kept
function T.range_end(s, e, home)
  r.Main_OnCommand(CMD_STOP, 0)
  if T.follows() then
    r.SetEditCurPos2(0, e, false, false)
    T.clear_timeline()
  else
    r.SetEditCurPos2(0, home or s, false, false)
  end
  r.UpdateArrange()
end

return T
