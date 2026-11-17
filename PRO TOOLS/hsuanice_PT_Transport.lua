--[[
@description hsuanice_PT_Transport - Transport Library (PT2Reaper)
@version 26.1118.0119
@author hsuanice
@noindex
@changelog
  - Release: the Time marker (9999) is named with the timecode of its position (tested in REAPER).
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
local FOLLOWS_SCRIPT = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or '') .. "hsuanice_Pro Tools Insertion Follows Playback.lua"
function T.refresh_follows_button()
  -- found by path: a command ID saved in an earlier session can be a different action now
  local cmd = r.file_exists(FOLLOWS_SCRIPT) and r.AddRemoveReaScript(true, 0, FOLLOWS_SCRIPT, false) or 0
  if not cmd or cmd == 0 then cmd = tonumber(r.GetExtState(T.NS, "cmd_follows")) end
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
  return s or T.time_pos() or r.GetCursorPosition()
end

function T.is_running() return r.GetPlayState() ~= 0 end

-- Plain play from the start position (Timeline Selection start, else the Time marker, else
-- the edit cursor). Pre-roll on (Pro Tools): starts the pre-roll length earlier. The edit
-- cursor: Link on, at the start position; Link off, where it is (the Edit position).
function T.play()
  local p = T.start_position()
  local home = T.home_for(p)
  local pre, on = T.roll("preroll")
  if on and pre > 0 and p > 0 then
    T.start_at(math.max(0, p - pre), home)
  else
    T.start_at(p, home)
  end
end

-- Insertion Follows Playback on: the Timeline position goes where playback stopped -
-- Link on: the edit cursor; Link off: the Time marker (the edit cursor, the Edit position, stays).
function T.before_stop()
  if not T.follows() then return end
  if T.linked() then r.Main_OnCommand(CMD_EDIT_TO_PLAY, 0) else T.set_time_pos(r.GetPlayPosition()) end
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

-- union of the track-level razor areas, or nil
function T.razor_range()
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
  return s, e
end

function T.edit_range()
  local s, e = T.razor_range()
  if s then return s, e end
  local ts, te = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if te > ts + EPS then return ts, te end
end

function T.timeline_range()
  local ls, le = r.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)
  if le > ls + EPS then return ls, le end
end

------------------------------------------------------------------------------
-- Time marker (Link Timeline and Edit Selection off). Pro Tools shows two positions when
-- nothing is selected: the Timeline position (blue, set by clicking the ruler) and the Edit
-- position. REAPER has one edit cursor, so with Link off:
--   edit cursor = the Edit position (it stays where it is while the Timeline plays)
--   Time marker = the Timeline position: a project marker number 9999 named with its timecode (blue), set by
--                 "Pro Tools Click Timeline Ruler" (mouse modifier) and, Insertion Follows
--                 Playback on, by stopping. A Timeline Selection (loop points) is the
--                 Timeline position instead: the Counters Panel removes the marker then,
--                 and with Link on.
------------------------------------------------------------------------------
T.TIME_ID = 9999 -- marker number, far from the usual numbers
-- name = the timecode of its position (shown in the ruler)
function T.time_name(p) return r.format_timestr_pos(p, "", 5) end
local OLD_NAMES = { V = true, ["><"] = true } -- 26.1117 pre-releases: still found, replaced when moved
T.TIME_COLOR = r.ColorToNative(40, 120, 255) | 0x1000000

-- every Time marker in the project: { {e = enum index, idx = number, pos, name}, ... }
-- (normally one; an older one left beside the new one is cleaned up by set / clear)
local function time_markers()
  local list, i = {}, 0
  while true do
    local ret, isrgn, pos, _, name, idx, color = r.EnumProjectMarkers3(0, i)
    if ret == 0 then return list end
    if not isrgn and color == T.TIME_COLOR and (idx == T.TIME_ID or OLD_NAMES[name]) then
      list[#list + 1] = { e = i, idx = idx, pos = pos, name = name }
    end
    i = i + 1
  end
end

-- delete these Time markers (by enum index, last first: the numbers can be the same)
local function delete_markers(list)
  for k = #list, 1, -1 do r.DeleteProjectMarkerByIndex(0, list[k].e) end
end

-- the marker's number and position (whatever the Link state), or nil
function T.time_marker()
  local m = time_markers()[1]
  if m then return m.idx, m.pos end
end

-- the Timeline position as a point (Link off, no Timeline Selection): the marker, or nil
function T.time_pos()
  if T.linked() then return nil end
  local _, pos = T.time_marker()
  return pos
end

function T.set_time_pos(p)
  local list = time_markers()
  local keep
  for k, m in ipairs(list) do if m.idx == T.TIME_ID then keep = k; break end end
  if keep then table.remove(list, keep) end
  delete_markers(list) -- extra / older ones
  if keep then
    r.SetProjectMarker3(0, T.TIME_ID, false, p, 0, T.time_name(p), T.TIME_COLOR)
  else
    r.AddProjectMarker2(0, false, p, 0, T.time_name(p), T.TIME_ID, T.TIME_COLOR)
  end
end

function T.clear_time_pos()
  local list = time_markers()
  delete_markers(list)
  return #list > 0
end

-- Which part of the ruler the mouse is on (SWS): "timeline" (the time scale; Pro Tools
-- Timeline ruler) | "lane" (region / marker / tempo lanes; Pro Tools Marker ruler) | nil
-- (no SWS, or not over the ruler: the scripts then treat the whole ruler as the timeline)
function T.ruler_segment()
  if not r.BR_GetMouseCursorContext then return nil end
  local win, seg = r.BR_GetMouseCursorContext()
  if win ~= "ruler" then return nil end
  if seg == "timeline" then return "timeline" end
  return "lane"
end

-- Ruler double click: REAPER runs the click action first (Click Timeline Ruler: loop points
-- cleared, Time marker moved). The click remembers what was there; a double click right
-- after puts it back, so a double click leaves the loop points and the marker alone.
T.RULER_DBL = 1.0 -- seconds
function T.ruler_remember()
  local now = r.time_precise()
  local t = tonumber(r.GetExtState(T.NS, "ruler_t"))
  if t and now - t < T.RULER_DBL then return end -- second click of a double click: keep the first
  local ls, le = r.GetSet_LoopTimeRange2(0, false, true, 0, 0, false)
  local _, mp = T.time_marker()
  r.SetExtState(T.NS, "ruler_t", string.format("%.3f", now), false)
  r.SetExtState(T.NS, "ruler_prev", string.format("%.10f,%.10f,%s", ls, le, mp and string.format("%.10f", mp) or ""), false)
end
function T.ruler_undo_click()
  local t = tonumber(r.GetExtState(T.NS, "ruler_t"))
  r.SetExtState(T.NS, "ruler_t", "", false)
  if not t or r.time_precise() - t >= T.RULER_DBL then return false end
  local a, b, m = r.GetExtState(T.NS, "ruler_prev"):match("^([^,]+),([^,]+),(.*)$")
  if not a then return false end
  r.GetSet_LoopTimeRange2(0, true, true, tonumber(a), tonumber(b), false)
  if tonumber(m) then T.set_time_pos(tonumber(m)) else T.clear_time_pos() end
  return true
end

-- where the edit cursor stays while the Timeline plays from p:
-- Link on, p (the playhead is the Timeline position); Link off, where it is (the Edit position)
function T.home_for(p)
  if T.linked() then return p end
  return r.GetCursorPosition()
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
    if T.linked() then
      r.SetEditCurPos2(0, e, false, false)
    else -- the Timeline position goes to the end; the Edit position stays
      T.set_time_pos(e)
      r.SetEditCurPos2(0, home or s, false, false)
    end
    T.clear_timeline()
  else
    r.SetEditCurPos2(0, home or s, false, false)
  end
  r.UpdateArrange()
end

------------------------------------------------------------------------------
-- Pre-roll / Post-roll (Pro Tools), global: seconds + on/off, saved across restarts.
-- Set in the Counters Panel; used by Play To / From / Through Edit Start / End.
------------------------------------------------------------------------------
function T.roll(which) -- which = "preroll" | "postroll" -> seconds, on
  local sec = tonumber(r.GetExtState(T.NS, which))
  if not sec then sec = which == "preroll" and 2 or 1 end
  return sec, r.GetExtState(T.NS, which .. "_on") == "1" -- off by default (Pro Tools)
end
function T.set_roll(which, sec, on)
  if sec then r.SetExtState(T.NS, which, string.format("%.10f", math.max(0, sec)), true) end
  if on ~= nil then
    r.SetExtState(T.NS, which .. "_on", on and "1" or "0", true)
    T.refresh_rolls_button()
  end
end

-- Pre Post Roll Playback (Pro Tools Cmd+K): one toggle for both. Either on -> both off;
-- both off -> both on.
function T.rolls_on()
  local _, a = T.roll("preroll")
  local _, b = T.roll("postroll")
  return a or b
end
function T.toggle_rolls()
  local on = not T.rolls_on()
  T.set_roll("preroll", nil, on)
  T.set_roll("postroll", nil, on)
end
local ROLLS_SCRIPT = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or '') .. "hsuanice_Pro Tools Pre Post Roll Playback.lua"
function T.refresh_rolls_button() -- lit while a roll is on; found by path (see refresh_follows_button)
  local cmd = r.file_exists(ROLLS_SCRIPT) and r.AddRemoveReaScript(true, 0, ROLLS_SCRIPT, false) or 0
  if cmd and cmd ~= 0 then
    r.SetToggleCommandState(0, cmd, T.rolls_on() and 1 or 0)
    r.RefreshToolbar2(0, cmd)
  end
end

-- Play again from position p while playing (Play Timeline Selection without a Timeline
-- Selection). Pre-roll on: from the pre-roll before p, every time (Pro Tools); the playhead
-- stays at p. Off: from p.
function T.replay_from(p)
  local pre, on = T.roll("preroll")
  local home = T.home_for(p)
  if on and pre > 0 then
    T.start_at(math.max(0, p - pre), home)
  else
    T.start_at(p, home)
  end
end

-- The Timeline Selection as Space / Play Timeline Selection play it (Pro Tools: the rolls
-- belong to the Timeline Selection, not to the Edit Selection): s, e, home or nil.
-- Pre-roll on: starts that much earlier; post-roll on: ends that much later; home = where
-- the edit cursor stays (Link on: the Timeline Selection start; off: the Edit position).
function T.timeline_bounds()
  local ls, le = T.timeline_range()
  if not ls then return nil end
  local pre, pon = T.roll("preroll")
  local post, qon = T.roll("postroll")
  return math.max(0, ls - (pon and pre or 0)), le + (qon and post or 0), T.home_for(ls)
end

------------------------------------------------------------------------------
-- Play To / From / Through Edit Start / End (Pro Tools)
--   edge = "start" | "end" of the Edit Selection (no selection: the edit cursor)
--   how  = "to" (pre-roll before -> edge) | "from" (edge -> post-roll after) |
--          "through" (pre-roll before -> post-roll after)
-- The pre-roll / post-roll lengths are used whether the rolls are on or off. Stops at the
-- end; the playhead (edit cursor) stays where it is while it plays and afterwards follows
-- the usual rules (Insertion Follows Playback on: stop position + Timeline Selection cleared).
-- QP: the QuickPunch library (optional) - a running pass is ended first.
------------------------------------------------------------------------------
function T.play_around_edit(edge, how, QP)
  T.reset_half_speed()
  T.refresh_follows_button() -- the N button shows the saved state (it is off after a restart)
  local es, ee = T.edit_range()
  local cur = r.GetCursorPosition()
  local p = edge == "end" and (ee or cur) or (es or cur)
  local pre, post = T.roll("preroll"), T.roll("postroll")
  local s = how == "from" and p or math.max(0, p - pre)
  local e = how == "to" and p or p + post
  if e - s <= EPS then return end
  if QP and QP.pass_active() and T.is_running() then
    QP.stop(T.follows())
    T.play_range(s, e, true, r.GetCursorPosition())
    return
  end
  local home = T.watch_home() or cur
  if not T.is_running() then home = cur end
  T.play_range(s, e, false, home)
end

return T
