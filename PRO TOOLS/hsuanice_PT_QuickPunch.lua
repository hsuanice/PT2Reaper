--[[
@description hsuanice_PT_QuickPunch - QuickPunch Library (PT2Reaper)
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the PT2Reaper QuickPunch actions (Record Punch, QuickPunch,
  hsuanice_PT_QuickPunch Pass Monitor) and of Play/Stop / Play Half Speed.
  Loaded with dofile(); not an action.
  Copied from Beta Testing/QuickPunch/hsuanice_QuickPunch Core.lua (26.1114.1519pre1) so the
  PT script set is self-contained. Data keys (ExtState "hsuanice_QuickPunch", P_EXT
  hsuanice_QP_*, "QP buffer - " tracks) are unchanged, so projects recorded with the
  earlier version keep working.

  QuickPunch emulates a Pro Tools style QuickPunch:
    * A pass (Play while QuickPunch mode is on) records every record-armed track's input on a
      hidden "QP buffer" track, from the play start. Nothing is drawn on the visible tracks;
      the visible track only monitors (record mode "none").
    * QP Punch marks punch-in / punch-out while the pass runs and switches the monitoring:
      playback before the punch; inside it the input, with the track's items muted, and a red
      "QP recording" item growing on the track.
    * When the pass stops, QP Pass Monitor finishes it:
        - punches: the recording is cut to the punch ranges and put on the visible track (the
          rest of the recording stays available as handles); the material under a punch is cut
          out, like Pro Tools (its files are untouched: drag the item edges to get it back).
        - no punch: the recording is deleted (the files one pass later, so an Undo still finds
          them) and the project is left as it was ("QuickPunch: pass (no punch)" undo point).
    * QuickPunch mode is on with Toggle QP QuickPunch Mode, or while REAPER's record mode is
      an auto-punch mode: then the time selection / selected items punch in and out
      automatically (QP Pass Monitor), manual punches still work.
    * Pre-roll on record is done by the pass itself, so the pre-roll is recorded (handles).
    * A whole pass is one undo point: one Undo goes back to before Play.
    * Fixed item lanes are never changed (on a track that has them, new items go on the
      lane that plays).

  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local C = {}

C.NS = "hsuanice_QuickPunch"
C.DIR = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or ""
C.MONITOR_SCRIPT = C.DIR .. "hsuanice_PT_QuickPunch Pass Monitor.lua"

-- Settings ------------------------------------------------------------------
-- true: playback before a punch, input monitoring inside it (Pro Tools auto input).
-- false: the tracks' monitoring is never touched.
C.SWITCH_MONITORING = true
-- true: a whole pass is one undo point (REAPER's own "recorded media" undo point is undone
-- and the recording rebuilt inside the QuickPunch undo point).
C.MERGE_UNDO = true

C.BUFFER_TRACK_PREFIX = "QP buffer - "
local SRC_KEY = "P_EXT:hsuanice_QP_src" -- on a buffer track: GUID of the track it records for

local EPS = 1e-9
local HUGE = math.huge

local CMD_RECORD = 1013
local CMD_STOP_SAVE_ALL = 40667
local REC_MODES = { 40252, 40076, 40253 } -- normal, time selection auto-punch, item auto-punch
local REC_NORMAL, REC_AUTO_TIMESEL, REC_AUTO_ITEMS = 40252, 40076, 40253
local CMD_PREROLL_REC = 41819 -- Pre-roll: toggle pre-roll on record
local CMD_ENDCUR_REC = 40300  -- Options: Move edit cursor to end of recording, when recording ends
local AUTO_LEAD = 0.02        -- auto punch switches this much before the boundary (one cycle)
local RECMODE_INPUT, RECMODE_NONE = 0, 2

------------------------------------------------------------------------------
-- Small helpers
------------------------------------------------------------------------------
function C.get(key) return r.GetExtState(C.NS, key) end
function C.set(key, val) r.SetExtState(C.NS, key, tostring(val), false) end
function C.del(key) r.DeleteExtState(C.NS, key, false) end

-- Temporary debug log (REAPER resource folder / Data / hsuanice_QuickPunch_debug.log)
C.DEBUG = false
function C.log(...)
  if not C.DEBUG then return end
  local f = io.open(r.GetResourcePath() .. "/Data/hsuanice_QuickPunch_debug.log", "a")
  if not f then return end
  local parts = {}
  for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
  f:write(os.date("%H:%M:%S"), string.format(" %.3f ", r.time_precise() % 1000), table.concat(parts, " "), "\n")
  f:close()
end

local function split(s, sep)
  local t = {}
  if not s or s == "" then return t end
  for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do t[#t + 1] = part end
  return t
end

function C.item_guid(it)
  local _, g = r.GetSetMediaItemInfo_String(it, "GUID", "", false)
  return g
end

function C.track_by_guid(g)
  if not g or g == "" then return nil end
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if r.GetTrackGUID(tr) == g then return tr end
  end
end

function C.buffer_source(tr)
  local _, g = r.GetSetMediaTrackInfo_String(tr, SRC_KEY, "", false)
  return g or ""
end

function C.armed_tracks()
  local t = {}
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(tr, "I_RECARM") == 1 and C.buffer_source(tr) == "" then t[#t + 1] = tr end
  end
  return t
end

function C.track_name(tr)
  local _, n = r.GetTrackName(tr)
  return n
end

local function buffer_name(tr) return C.BUFFER_TRACK_PREFIX .. C.track_name(tr) end

function C.pass_active()
  return C.get("pass") == "1"
end

-- REAPER's record mode (normal / time selection auto-punch / selected item auto-punch)
function C.rec_mode()
  for _, id in ipairs(REC_MODES) do
    if r.GetToggleCommandState(id) == 1 then return id end
  end
  return REC_NORMAL
end

-- QuickPunch mode: on while REAPER's record mode is an auto-punch mode, or switched on with
-- Toggle QP QuickPunch Mode (not saved, REAPER always starts with it off).
function C.mode_on()
  local m = C.rec_mode()
  return C.get("mode") == "1" or m == REC_AUTO_TIMESEL or m == REC_AUTO_ITEMS
end
function C.set_mode(on)
  C.set("mode", on and "1" or "0")
  local cmd = tonumber(C.get("cmd_toggle"))
  if cmd then r.SetToggleCommandState(0, cmd, on and 1 or 0); r.RefreshToolbar2(0, cmd) end
end

local function track_items(tr)
  local t = {}
  for i = 0, r.CountTrackMediaItems(tr) - 1 do t[#t + 1] = r.GetTrackMediaItem(tr, i) end
  return t
end

-- On a track with fixed lanes (the user's own choice) a new item must go on the lane that
-- plays, else it lands on a hidden lane (REAPER put new items on lane 1 of a collapsed
-- 2-lane track). Read only: lanes are never changed. nil = no fixed lanes.
local function playing_lane(tr)
  if r.GetMediaTrackInfo_Value(tr, "I_FREEMODE") ~= 2 then return nil end
  local n = math.floor(r.GetMediaTrackInfo_Value(tr, "I_NUMFIXEDLANES") + 0.5)
  for k = 0, n - 1 do
    if r.GetMediaTrackInfo_Value(tr, "C_LANEPLAYS:" .. k) > 0 then return k end
  end
  return 0
end

-- Cut `it` so that its part inside [a, b] is a separate item; returns that part.
local function isolate(it, a, b)
  local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
  local e = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
  if b <= pos + EPS or a >= e - EPS then return nil end
  local mid = it
  if a > pos + EPS then mid = r.SplitMediaItem(it, a) end
  if mid and b < e - EPS then r.SplitMediaItem(mid, b) end
  return mid
end

local function source_file(take)
  if not take then return nil end
  local src = r.GetMediaItemTake_Source(take)
  local parent = src and r.GetMediaSourceParent(src)
  while parent do src = parent; parent = r.GetMediaSourceParent(src) end
  local f = src and r.GetMediaSourceFileName(src, "")
  if f and f ~= "" then return f end
end

local function file_used_anywhere(path)
  for i = 0, r.CountMediaItems(0) - 1 do
    local it = r.GetMediaItem(0, i)
    for t = 0, r.CountTakes(it) - 1 do
      if source_file(r.GetTake(it, t)) == path then return true end
    end
  end
  return false
end

------------------------------------------------------------------------------
-- Hidden buffer tracks (one per armed track, reused, at the end of the project)
------------------------------------------------------------------------------
function C.buffer_track_for(tr, create)
  local g = r.GetTrackGUID(tr)
  for i = 0, r.CountTracks(0) - 1 do
    local b = r.GetTrack(0, i)
    if C.buffer_source(b) == g then return b end
  end
  if not create then return nil end
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, false)
  local b = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(b, SRC_KEY, g, true)
  r.GetSetMediaTrackInfo_String(b, "P_NAME", buffer_name(tr), true)
  r.SetMediaTrackInfo_Value(b, "B_SHOWINTCP", 0)
  r.SetMediaTrackInfo_Value(b, "B_SHOWINMIXER", 0)
  r.SetMediaTrackInfo_Value(b, "B_MAINSEND", 0)
  r.SetMediaTrackInfo_Value(b, "I_RECMON", 0)
  r.SetMediaTrackInfo_Value(b, "I_RECARM", 0)
  return b
end

-- buffer tracks whose track is gone and that hold nothing are removed
local function remove_orphan_buffer_tracks()
  for i = r.CountTracks(0) - 1, 0, -1 do
    local b = r.GetTrack(0, i)
    local src = C.buffer_source(b)
    if src ~= "" and not C.track_by_guid(src) and r.CountTrackMediaItems(b) == 0 then r.DeleteTrack(b) end
  end
end

------------------------------------------------------------------------------
-- Snapshot of the armed tracks for one pass
------------------------------------------------------------------------------
-- line: trackGUID \t bufferGUID \t recmode \t recmon \t recmonitems \t bufferItemGUIDs(csv) \t recarm
local function snapshot_line(tr, b)
  local guids = {}
  for _, it in ipairs(track_items(b)) do guids[#guids + 1] = C.item_guid(it) end
  return table.concat({
    r.GetTrackGUID(tr), r.GetTrackGUID(b),
    math.floor(r.GetMediaTrackInfo_Value(tr, "I_RECMODE")),
    math.floor(r.GetMediaTrackInfo_Value(tr, "I_RECMON")),
    math.floor(r.GetMediaTrackInfo_Value(tr, "I_RECMONITEMS")),
    table.concat(guids, ","),
    math.floor(r.GetMediaTrackInfo_Value(tr, "I_RECARM")),
  }, "\t")
end

local function parse_snapshot()
  local t = {}
  for _, line in ipairs(split(C.get("snap"), "\n")) do
    local f = split(line, "\t")
    local s = {
      guid = f[1], bguid = f[2], recmode = tonumber(f[3]) or 0, recmon = tonumber(f[4]) or 0,
      recmonitems = tonumber(f[5]) or 1, bitems = {}, recarm = tonumber(f[7]) or 1,
    }
    for _, g in ipairs(split(f[6] or "", ",")) do s.bitems[g] = true end
    t[#t + 1] = s
  end
  return t
end

------------------------------------------------------------------------------
-- Monitoring switch (Pro Tools auto input)
------------------------------------------------------------------------------
-- "Recording" placeholders: a red empty item on each armed track from the punch-in, growing
-- with the play cursor (QP Pass Monitor) until the punch-out; deleted when the pass finishes.
local PH_KEY = "P_EXT:hsuanice_QP_rec" -- "1" = growing, "0" = punched out

local function ph_state(it)
  local _, v = r.GetSetMediaItemInfo_String(it, PH_KEY, "", false)
  return v or ""
end

local function snapshot_tracks()
  local t = {}
  for _, s in ipairs(parse_snapshot()) do
    local tr = C.track_by_guid(s.guid)
    if tr then t[#t + 1] = tr end
  end
  return t
end

local function bump_ph_rev() C.set("ph_rev", (tonumber(C.get("ph_rev")) or 0) + 1) end

local function add_placeholders(pos)
  C.log("add_placeholders pos", pos, "tracks", #snapshot_tracks())
  for _, tr in ipairs(snapshot_tracks()) do
    local it = r.AddMediaItemToTrack(tr)
    C.log("  placeholder on", C.track_name(tr), "item", tostring(it), "freemode", r.GetMediaTrackInfo_Value(tr, "I_FREEMODE"),
      "lanes", r.GetMediaTrackInfo_Value(tr, "I_NUMFIXEDLANES"), "lane", r.GetMediaItemInfo_Value(it, "I_FIXEDLANE"))
    r.SetMediaItemInfo_Value(it, "D_POSITION", pos)
    r.SetMediaItemInfo_Value(it, "D_LENGTH", 0.001)
    local lane = playing_lane(tr)
    if lane then r.SetMediaItemInfo_Value(it, "I_FIXEDLANE", lane) end
    r.SetMediaItemInfo_Value(it, "I_CUSTOMCOLOR", r.ColorToNative(200, 30, 30) | 0x1000000)
    r.GetSetMediaItemInfo_String(it, "P_NOTES", "QP recording", true)
    r.GetSetMediaItemInfo_String(it, PH_KEY, "1", true)
  end
  bump_ph_rev()
end

-- the growing placeholders (QP Pass Monitor caches them until "ph_rev" changes)
function C.active_placeholders()
  local t = {}
  for _, tr in ipairs(snapshot_tracks()) do
    for _, it in ipairs(track_items(tr)) do
      if ph_state(it) == "1" then t[#t + 1] = it end
    end
  end
  return t
end

function C.extend_placeholders(items, pos)
  for _, it in ipairs(items) do
    if r.ValidatePtr2(0, it, "MediaItem*") then
      local len = pos - r.GetMediaItemInfo_Value(it, "D_POSITION")
      if len > 0.001 then r.SetMediaItemInfo_Value(it, "D_LENGTH", len) end
    end
  end
end

local function close_placeholders(pos)
  local items = C.active_placeholders()
  C.extend_placeholders(items, pos)
  for _, it in ipairs(items) do r.GetSetMediaItemInfo_String(it, PH_KEY, "0", true) end
  bump_ph_rev()
end

local function delete_placeholders()
  C.log("delete_placeholders")
  for _, tr in ipairs(snapshot_tracks()) do
    for _, it in ipairs(track_items(tr)) do
      if ph_state(it) ~= "" then r.DeleteTrackMediaItem(tr, it) end
    end
  end
  bump_ph_rev()
end

-- Outside a punch: the track's playback, no input. Inside: the input, with the track's items
-- muted (the items muted here are listed in ExtState "muted" and unmuted on punch-out).
local function unmute_items()
  local want = {}
  for _, g in ipairs(split(C.get("muted"), ",")) do want[g] = true end
  C.set("muted", "")
  if next(want) == nil then return end
  for _, s in ipairs(parse_snapshot()) do
    local tr = C.track_by_guid(s.guid)
    if tr then
      for _, it in ipairs(track_items(tr)) do
        if want[C.item_guid(it)] then r.SetMediaItemInfo_Value(it, "B_MUTE", 0) end
      end
    end
  end
end

function C.apply_monitoring(punched)
  if not C.SWITCH_MONITORING then return end
  unmute_items()
  local muted = {}
  for _, s in ipairs(parse_snapshot()) do
    local tr = C.track_by_guid(s.guid)
    if tr then
      r.SetMediaTrackInfo_Value(tr, "I_RECMON", punched and 1 or 0)
      if punched then
        for _, it in ipairs(track_items(tr)) do
          if r.GetMediaItemInfo_Value(it, "B_MUTE") == 0 and ph_state(it) == "" then
            r.SetMediaItemInfo_Value(it, "B_MUTE", 1)
            muted[#muted + 1] = C.item_guid(it)
          end
        end
      end
    end
  end
  C.set("muted", table.concat(muted, ","))
  r.UpdateArrange()
end

------------------------------------------------------------------------------
-- Buffer leftovers and recorded files
------------------------------------------------------------------------------
-- Items on a hidden buffer track are leftovers of a recording (normally none between passes).
local function buffer_tracks()
  local t = {}
  for i = 0, r.CountTracks(0) - 1 do
    local b = r.GetTrack(0, i)
    if C.buffer_source(b) ~= "" then t[#t + 1] = b end
  end
  return t
end

-- Outside a pass no buffer track may stay armed (it would record with every normal recording).
function C.disarm_buffers()
  if C.pass_active() then return end
  for _, b in ipairs(buffer_tracks()) do
    if r.GetMediaTrackInfo_Value(b, "I_RECARM") ~= 0 then r.SetMediaTrackInfo_Value(b, "I_RECARM", 0) end
  end
end

-- Recorded files that are no longer needed: deleted one call later (if nothing uses them then),
-- so an Undo / Redo right after a pass still finds them.
function C.trash_files(files)
  local _, old = r.GetProjExtState(0, C.NS, "trash")
  local now = {}
  for _, f in ipairs(files) do now[f] = true end
  for _, f in ipairs(split(old, "\n")) do
    if not now[f] and not file_used_anywhere(f) then
      os.remove(f)
      os.remove(f .. ".reapeaks")
    end
  end
  r.SetProjExtState(0, C.NS, "trash", table.concat(files, "\n"))
end

-- Delete the buffer items (except the GUIDs in `keep`). Their recorded files are deleted one
-- purge later (if nothing uses them), so an Undo right after still finds them.
function C.purge_buffers(keep)
  local files = {}
  for _, b in ipairs(buffer_tracks()) do
    for _, it in ipairs(track_items(b)) do
      if not (keep and keep[C.item_guid(it)]) then
        local f = source_file(r.GetActiveTake(it))
        if f then files[#files + 1] = f end
        r.DeleteTrackMediaItem(b, it)
      end
    end
  end
  C.trash_files(files)
  remove_orphan_buffer_tracks()
end

------------------------------------------------------------------------------
-- Start / stop a pass
------------------------------------------------------------------------------
local function launch_monitor()
  local cmd = r.AddRemoveReaScript(true, 0, C.MONITOR_SCRIPT, true)
  if cmd and cmd ~= 0 then r.Main_OnCommand(cmd, 0) return true end
  return false
end

-- Auto-punch ranges of REAPER's auto-punch record modes: the time selection, or the (merged)
-- time ranges of the selected items (time selection mode: the loop points when there is no time selection). {} in normal mode or when there is nothing to punch.
function C.auto_ranges(mode)
  local t = {}
  if mode == REC_AUTO_TIMESEL then
    -- the time selection; when there is none, the loop points (they can be unlinked from the
    -- time selection, and then the ruler's range is the loop)
    local ts, te = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
    if te <= ts then ts, te = r.GetSet_LoopTimeRange2(0, false, true, 0, 0, false) end
    if te > ts then t[1] = { ts, te } end
  elseif mode == REC_AUTO_ITEMS then
    for i = 0, r.CountSelectedMediaItems(0) - 1 do
      local it = r.GetSelectedMediaItem(0, i)
      local a = r.GetMediaItemInfo_Value(it, "D_POSITION")
      t[#t + 1] = { a, a + r.GetMediaItemInfo_Value(it, "D_LENGTH") }
    end
    table.sort(t, function(x, y) return x[1] < y[1] end)
    local merged = {}
    for _, p in ipairs(t) do
      local last = merged[#merged]
      if last and p[1] <= last[2] + EPS then last[2] = math.max(last[2], p[2])
      else merged[#merged + 1] = { p[1], p[2] } end
    end
    t = merged
  end
  return t
end

-- REAPER's pre-roll on record, in seconds at time `t` (0 when it is off)
function C.preroll_seconds(t)
  if r.GetToggleCommandState(CMD_PREROLL_REC) ~= 1 then return 0 end
  local meas = 1
  if r.get_config_var_string then
    local ok, v = r.get_config_var_string("prerollmeas")
    if ok and tonumber(v) then meas = tonumber(v) end
  end
  local num, denom, bpm = r.TimeMap_GetTimeSigAtTime(0, t)
  if not num or num <= 0 then num, denom, bpm = 4, 4, 120 end
  return meas * num * (60 / bpm) * (4 / denom)
end

-- Returns "started", "none" (no armed track: the caller plays normally) or nil (cancelled / busy).
-- `start` (optional): project time to start at (else the edit cursor).
function C.start_pass(punch_now, start)
  C.log("start_pass punch_now", punch_now, "playstate", r.GetPlayState(), "pass_active", C.pass_active(), "mode", C.get("mode"))
  if r.GetPlayState() ~= 0 then return end
  -- the previous pass stopped but is not finished yet (the monitor waits a cycle): finish it now
  if C.pass_active() then C.finalize() end

  local tracks = C.armed_tracks()
  if #tracks == 0 then return "none" end

  local bad = {}
  for _, tr in ipairs(tracks) do
    if r.GetMediaTrackInfo_Value(tr, "I_RECMODE") ~= RECMODE_INPUT then bad[#bad + 1] = C.track_name(tr) end
  end
  if #bad > 0 then
    r.MB("QuickPunch records the track input. Set the record mode to \"Record: input\" on:\n  "
      .. table.concat(bad, "\n  "), "QuickPunch", 0)
    return
  end

  -- where the pass starts: an auto-punch range starts it (pre-roll before it, or the edit cursor
  -- when that is earlier); REAPER's own pre-roll would not record, so it is done here instead
  -- (recording from the very start = handles before the first punch)
  local mode = C.rec_mode()
  local auto = C.auto_ranges(mode)
  local cursor = r.GetCursorPosition()
  local base = start or cursor
  local pre
  if #auto > 0 then
    base = auto[1][1]
    pre = C.preroll_seconds(base)
    if pre == 0 and cursor < base then pre = base - cursor end
  else
    pre = C.preroll_seconds(base)
  end
  local play_from = math.max(0, base - pre)
  C.log("start_pass recmode", mode, "auto ranges", #auto, auto[1] and auto[1][1] or "-", auto[1] and auto[1][2] or "-",
    "cursor", cursor, "start", start, "pre", pre, "play_from", play_from)
  if punch_now and #auto > 0 then punch_now = false end -- the auto ranges punch
  if punch_now and play_from < base - EPS then
    -- Record from stop with pre-roll: punch in at the cursor, after the pre-roll
    auto = { { base, 1e12 } }
    punch_now = false
  end

  -- no undo point here: the pass becomes one undo point when it is finished
  C.set("undo_pre", r.Undo_CanUndo2(0) or "")
  r.PreventUIRefresh(1)
  r.SetEditCurPos2(0, play_from, false, false)

  local lines = {}
  for _, tr in ipairs(tracks) do
    local b = C.buffer_track_for(tr, true)
    lines[#lines + 1] = snapshot_line(tr, b)
    -- the hidden buffer track records the same input; the visible track only monitors
    r.SetMediaTrackInfo_Value(b, "I_RECINPUT", r.GetMediaTrackInfo_Value(tr, "I_RECINPUT"))
    r.SetMediaTrackInfo_Value(b, "I_NCHAN", r.GetMediaTrackInfo_Value(tr, "I_NCHAN"))
    r.SetMediaTrackInfo_Value(b, "I_RECMODE", RECMODE_INPUT)
    r.SetMediaTrackInfo_Value(b, "I_RECMON", 0)
    r.SetMediaTrackInfo_Value(b, "I_RECARM", 1)
    -- while recording the buffer track has the track's own name, so the recorded files are
    -- named like a normal recording of that track
    r.GetSetMediaTrackInfo_String(b, "P_NAME", C.track_name(tr), true)
    r.SetMediaTrackInfo_Value(tr, "I_RECMODE", RECMODE_NONE)
    if C.SWITCH_MONITORING then r.SetMediaTrackInfo_Value(tr, "I_RECMONITEMS", 1) end
  end
  C.set("snap", table.concat(lines, "\n"))

  C.set("recmode", mode)
  if mode ~= REC_NORMAL then r.Main_OnCommand(REC_NORMAL, 0) end
  local preroll_on = r.GetToggleCommandState(CMD_PREROLL_REC) == 1
  C.set("preroll", preroll_on and "1" or "0")
  if preroll_on then r.Main_OnCommand(CMD_PREROLL_REC, 0) end
  -- a pass is a recording: REAPER would move the edit cursor to the end of it on stop.
  -- Off during the pass (Insertion Follows Playback decides instead), back on after it.
  local endcur_on = r.GetToggleCommandState(CMD_ENDCUR_REC) == 1
  C.set("endcur", endcur_on and "1" or "0")
  if endcur_on then r.Main_OnCommand(CMD_ENDCUR_REC, 0) end
  local parts = {}
  for _, p in ipairs(auto) do parts[#parts + 1] = string.format("%.10f,%.10f", p[1], p[2]) end
  C.set("auto", table.concat(parts, ";"))
  C.set("start_cursor", string.format("%.10f", cursor))
  C.set("play_from", string.format("%.10f", play_from))

  local pos = play_from
  C.set("punches", punch_now and string.format("%.10f,", pos) or "")
  C.set("punched", punch_now and "1" or "0")
  C.set("muted", "")
  C.set("auto_done", "0")
  C.set("pass_id", string.format("%.6f", r.time_precise()))
  C.set("pass", "1")
  C.apply_monitoring(punch_now)
  if punch_now then add_placeholders(pos); C.light_punch(true) end

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)

  r.Main_OnCommand(CMD_RECORD, 0)
  if not launch_monitor() then
    r.Main_OnCommand(CMD_STOP_SAVE_ALL, 0)
    C.finalize()
    r.MB("Could not start QP Pass Monitor:\n" .. C.MONITOR_SCRIPT, "QuickPunch", 0)
    return
  end
  return "started"
end

-- stop the transport during a pass (no "save recorded media?" prompt)
-- `follows` (optional, Insertion Follows Playback): where the edit cursor ends once the
-- pass is finished - true: where playback stopped; false: where it was before Play.
-- (REAPER's own record-stop cursor rules would otherwise decide.)
function C.stop(follows)
  if follows ~= nil then
    local pos = follows and r.GetPlayPosition() or tonumber(C.get("start_cursor"))
    if pos then C.set("stop_cursor", string.format("%.10f", pos)) end
  end
  r.Main_OnCommand(CMD_STOP_SAVE_ALL, 0)
  -- put it there at once (the pass end does it again, in case something moved it)
  local want = tonumber(C.get("stop_cursor"))
  if want then r.SetEditCurPos2(0, want, false, false) end
end

------------------------------------------------------------------------------
-- Punch in / out
------------------------------------------------------------------------------
function C.punch_toggle(pos)
  pos = pos or r.GetPlayPosition()
  local punched = C.get("punched") == "1"
  C.log("punch_toggle pos", pos, punched and "-> OUT" or "-> IN", "playstate", r.GetPlayState())
  C.set("punches", C.get("punches") .. string.format(punched and "%.10f;" or "%.10f,", pos))
  C.set("punched", punched and "0" or "1")
  -- switch the monitoring right here (not a monitor cycle later)
  if punched then
    close_placeholders(pos)
    C.apply_monitoring(false)
  else
    C.apply_monitoring(true)
    add_placeholders(pos)
  end
  C.light_punch(not punched)
  return not punched
end

-- QP Punch's toolbar button follows the punch state
function C.light_punch(on)
  local cmd = tonumber(C.get("cmd_punch"))
  if cmd then r.SetToggleCommandState(0, cmd, on and 1 or 0); r.RefreshToolbar2(0, cmd) end
end

-- Auto punch: called by QP Pass Monitor every cycle with the play position. Punches in at the
-- start and out at the end of each auto-punch range (exact boundaries); a manual punch in
-- between is respected (already in -> no punch-in; already out -> no punch-out).
function C.auto_step(playpos)
  local auto = C.get("auto")
  if auto == "" then return end
  local done = tonumber(C.get("auto_done")) or 0 -- number of boundaries passed
  local bounds = {}
  for _, seg in ipairs(split(auto, ";")) do
    local a, b = seg:match("^([^,]+),(.+)$")
    bounds[#bounds + 1] = { t = tonumber(a), inn = true }
    bounds[#bounds + 1] = { t = tonumber(b), inn = false }
  end
  while bounds[done + 1] and playpos >= bounds[done + 1].t - AUTO_LEAD do
    local e = bounds[done + 1]
    C.log("auto_step boundary", e.t, e.inn and "IN" or "OUT", "playpos", playpos, "punched", C.get("punched"))
    local punched = C.get("punched") == "1"
    if e.inn ~= punched then C.punch_toggle(e.t) end
    done = done + 1
  end
  C.set("auto_done", done)
end

-- "in,out;in,out;in," -> { {a, b}, ... } (an open punch ends at the end of the pass)
local function parse_punches()
  local t = {}
  for _, seg in ipairs(split(C.get("punches"), ";")) do
    local a, b = seg:match("^([^,]+),(.*)$")
    a = tonumber(a)
    if a then
      b = tonumber(b) or HUGE
      if b > a + EPS then t[#t + 1] = { a, b } end
    end
  end
  table.sort(t, function(x, y) return x[1] < y[1] end)
  return t
end

------------------------------------------------------------------------------
-- Finish a pass (called by QP Pass Monitor after the transport stopped)
------------------------------------------------------------------------------
local function finish_track(s, punches, selected)
  local tr = C.track_by_guid(s.guid)
  local b = C.track_by_guid(s.bguid)
  if b then r.SetMediaTrackInfo_Value(b, "I_RECARM", 0) end
  if not tr then return end
  if b then r.GetSetMediaTrackInfo_String(b, "P_NAME", buffer_name(tr), true) end

  -- restore the track settings changed for the pass
  r.SetMediaTrackInfo_Value(tr, "I_RECMODE", s.recmode)
  r.SetMediaTrackInfo_Value(tr, "I_RECARM", s.recarm)
  if C.SWITCH_MONITORING then
    r.SetMediaTrackInfo_Value(tr, "I_RECMON", s.recmon)
    r.SetMediaTrackInfo_Value(tr, "I_RECMONITEMS", s.recmonitems)
  end
  if not b then return end

  local new = {}
  for _, it in ipairs(track_items(b)) do
    if not s.bitems[C.item_guid(it)] then new[#new + 1] = it end
  end
  if #new == 0 or #punches == 0 then return end -- (the buffer is deleted by the caller)

  -- an open punch (no punch-out before stop) ends where the recording ends
  local rec_end = 0
  for _, it in ipairs(new) do
    rec_end = math.max(rec_end, r.GetMediaItemInfo_Value(it, "D_POSITION") + r.GetMediaItemInfo_Value(it, "D_LENGTH"))
  end
  local ps = {}
  for _, p in ipairs(punches) do
    local e = math.min(p[2], rec_end)
    if e > p[1] + EPS then ps[#ps + 1] = { p[1], e } end
  end

  -- 1) the material under the punches is cut out, like Pro Tools (files untouched)
  for _, p in ipairs(ps) do
    for _, it in ipairs(track_items(tr)) do
      local mid = isolate(it, p[1], p[2])
      if mid then r.DeleteTrackMediaItem(tr, mid) end
    end
  end

  -- 2) the recording cut to the punches -> the track; the rest is deleted by the caller
  --    (the recorded file keeps it: drag the item edges to reveal the handles)
  local keep = {}
  for _, p in ipairs(ps) do
    for _, it in ipairs(track_items(b)) do
      local g = C.item_guid(it)
      if not keep[g] and not s.bitems[g] then
        local mid = isolate(it, p[1], p[2])
        if mid then keep[C.item_guid(mid)] = mid end
      end
    end
  end
  local lane = playing_lane(tr)
  for _, mid in pairs(keep) do
    r.MoveMediaItemToTrack(mid, tr)
    if lane then r.SetMediaItemInfo_Value(mid, "I_FIXEDLANE", lane) end
    selected[#selected + 1] = mid
  end
end

-- Undo everything back to the undo point that was current when the pass started (REAPER's
-- "recorded media" and anything done during the pass), at most MAX_UNDO steps. Succeeds only if
-- that point is reached and the recorded items are gone; otherwise everything is redone.
local MAX_UNDO = 50
local function undo_recording(rec)
  if not C.MERGE_UNDO then return false end
  local pre = C.get("undo_pre")
  local steps = 0
  while (r.Undo_CanUndo2(0) or "") ~= pre and steps < MAX_UNDO do
    if (r.Undo_DoUndo2(0) or 0) == 0 then break end
    steps = steps + 1
  end
  local gone = true
  for _, list in pairs(rec) do
    for _, e in ipairs(list) do
      if r.ValidatePtr2(0, e.item, "MediaItem*") then gone = false end
    end
  end
  if steps > 0 and gone and (r.Undo_CanUndo2(0) or "") == pre then return true end
  for _ = 1, steps do r.Undo_DoRedo2(0) end
  return false
end

local function end_pass_state()
  local mode = tonumber(C.get("recmode")) or REC_NORMAL
  if mode ~= REC_NORMAL then r.Main_OnCommand(mode, 0) end
  if C.get("preroll") == "1" and r.GetToggleCommandState(CMD_PREROLL_REC) ~= 1 then r.Main_OnCommand(CMD_PREROLL_REC, 0) end
  if C.get("endcur") == "1" and r.GetToggleCommandState(CMD_ENDCUR_REC) ~= 1 then r.Main_OnCommand(CMD_ENDCUR_REC, 0) end
  -- the edit cursor was moved to the play start (pre-roll): back to where it was, unless
  -- something else moved it (Insertion Follows Playback)
  local sc, pf = tonumber(C.get("start_cursor")), tonumber(C.get("play_from"))
  local want = tonumber(C.get("stop_cursor")) -- set by Play/Stop (Insertion Follows Playback)
  if want then
    r.SetEditCurPos2(0, want, false, false)
  elseif sc and pf and math.abs(r.GetCursorPosition() - pf) < 1e-6 then
    r.SetEditCurPos2(0, sc, false, false)
  end
  for _, k in ipairs({ "pass", "snap", "punches", "punched", "muted", "recmode", "undo_pre",
                       "preroll", "auto", "auto_done", "start_cursor", "play_from",
                       "stop_cursor", "endcur" }) do C.del(k) end
  C.light_punch(false)
end

-- "QP in" / "QP out" markers left by older versions
local function remove_old_markers()
  for i = r.CountProjectMarkers(0) - 1, 0, -1 do
    local _, isrgn, _, _, name = r.EnumProjectMarkers3(0, i)
    if not isrgn and (name == "QP in" or name == "QP out") then r.DeleteProjectMarkerByIndex(0, i) end
  end
end

function C.finalize()
  local snaps = parse_snapshot()
  local punches = parse_punches()
  C.log("finalize punches", #punches, "tracks", #snaps, "active placeholders", #C.active_placeholders())
  C.set("pass", "0") -- the monitor stops at once if it is still running

  -- the recorded buffer items, as chunks (to rebuild them after the undo)
  local rec, any, files = {}, false, {}
  for i, s in ipairs(snaps) do
    rec[i] = {}
    local b = C.track_by_guid(s.bguid)
    for _, it in ipairs(b and track_items(b) or {}) do
      local g = C.item_guid(it)
      if not s.bitems[g] then
        local ok, chunk = r.GetItemStateChunk(it, "", false)
        if ok then rec[i][#rec[i] + 1] = { item = it, guid = g, chunk = chunk }; any = true end
        local f = source_file(r.GetActiveTake(it))
        if f then files[#files + 1] = f end
      end
    end
  end
  local merged = any and undo_recording(rec)

  if merged and #punches == 0 then
    -- no punch: the undo removed the recording (REAPER's recording undo point holds items only,
    -- so the track settings are restored here). The undo point only clears the redo history
    -- (a Redo would bring the mid-pass state back).
    r.Undo_BeginBlock()
    unmute_items()
    delete_placeholders()
    for _, s in ipairs(snaps) do finish_track(s, punches, {}) end
    C.trash_files(files)
    end_pass_state()
    r.UpdateArrange()
    r.Undo_EndBlock("QuickPunch: pass (no punch)", -1)
    return
  end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  -- (REAPER's recording undo point holds items only: track settings are restored by finish_track)
  unmute_items()
  delete_placeholders()
  -- rebuild every recorded item that is gone (undone with the pass; or, if the undo history was
  -- redone, lost with a buffer track that no undo point holds) - a recording is never lost
  for i, s in ipairs(snaps) do
    local tr = C.track_by_guid(s.guid)
    if tr then
      for _, e in ipairs(rec[i]) do
        if not r.ValidatePtr2(0, e.item, "MediaItem*") then
          local b = C.buffer_track_for(tr, true)
          s.bguid = r.GetTrackGUID(b)
          local it = r.AddMediaItemToTrack(b)
          r.SetItemStateChunk(it, e.chunk, false)
        end
      end
    end
  end
  remove_old_markers()

  local selected = {}
  for _, s in ipairs(snaps) do finish_track(s, punches, selected) end
  C.purge_buffers(nil) -- whatever is left of the recording (no punch, outside the punches)
  -- Like Pro Tools: the punched clips are not selected and the selection is left as it was
  -- (selecting them made the item/time-selection links pull the next Play back to them).
  for _, it in ipairs(selected) do r.SetMediaItemSelected(it, false) end
  end_pass_state()

  r.PreventUIRefresh(-1)
  r.TrackList_AdjustWindows(false)
  r.UpdateTimeline()
  r.UpdateArrange()
  r.Undo_EndBlock(#selected > 0 and "QuickPunch: punch" or "QuickPunch: pass", -1)
end

return C
