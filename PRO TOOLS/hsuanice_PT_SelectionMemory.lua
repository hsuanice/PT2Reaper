--[[
@description hsuanice_PT_SelectionMemory - the last Edit Selection, for Restore Last Selection (PT2Reaper library)
@version 26.1118.1118
@author hsuanice
@noindex
@changelog
  - Release: remembers the Edit Selection right after the mouse release; restored ranges put the playhead at their start (tested in REAPER, speed like Pro Tools).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of Restore Last Selection and the Counters Panel. Loaded with dofile().

  Pro Tools Restore Last Selection (Cmd+Opt+Z) swaps the Edit Selection with the one before
  it (one level; pressing it again goes back). Only the Edit Selection: a range on tracks,
  or a position on tracks. The Timeline Selection (loop points) is not part of it.
  REAPER does not tell scripts when a selection changes, so the Counters Panel (always
  running) calls watch() every check (0.1 s): a selection counts once the mouse button is up
  and it has stayed the same for 0.15 s (0.5 s without js_ReaScriptAPI). Restoring a range
  also puts the playhead (edit cursor) at its start.
  A selection is stored as text in ExtState (not saved):
    "R|start|end|GUID,GUID"  range (razor areas, else the time selection) on tracks
    "P|position|GUID,GUID"   position (edit cursor) on the selected tracks
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local S = {}
S.NS = 'hsuanice_PT_CountersPanel' -- shared with the Counters Panel
-- seconds a selection must stay the same to count: with js_ReaScriptAPI the mouse button is
-- known, so a selection counts right after the mouse is released (0.15 s: other scripts that
-- sync the track selection a frame later are not recorded half-way); without it 0.5 s.
S.SETTLE = r.JS_Mouse_GetState and 0.15 or 0.5
local EPS = 1e-9
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''

local function get(k) return r.GetExtState(S.NS, k) end
local function set(k, v) r.SetExtState(S.NS, k, v, false) end

-- The current Edit Selection as text (see the header)
function S.capture()
  local t0, t1, guids = nil, nil, {}
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, s = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false)
    local on = false
    for a, b, g in (s or ''):gmatch('(%S+)%s+(%S+)%s+"([^"]*)"') do
      local x, y = tonumber(a), tonumber(b)
      if g == '' and x and y and y > x + EPS then
        t0 = t0 and math.min(t0, x) or x
        t1 = t1 and math.max(t1, y) or y
        on = true
      end
    end
    if on then guids[#guids + 1] = r.GetTrackGUID(tr) end
  end
  if t0 then return string.format('R|%.10f|%.10f|%s', t0, t1, table.concat(guids, ',')) end
  local sel = {}
  for i = 0, r.CountSelectedTracks(0) - 1 do sel[#sel + 1] = r.GetTrackGUID(r.GetSelectedTrack(0, i)) end
  local ts, te = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if te > ts + EPS then return string.format('R|%.10f|%.10f|%s', ts, te, table.concat(sel, ',')) end
  return string.format('P|%.10f|%s', r.GetCursorPosition(), table.concat(sel, ','))
end

local function mouse_down()
  if r.JS_Mouse_GetState then return r.JS_Mouse_GetState(1) & 1 == 1 end -- js_ReaScriptAPI (optional)
  return false
end

-- Counters Panel, every check: records the selection once it has settled.
local pending, pending_since
function S.watch(now)
  set('sel_hb', string.format('%.3f', now))
  local snap = S.capture()
  if snap ~= pending then pending, pending_since = snap, now; return end
  local cur = get('sel_cur')
  if snap == cur or now - pending_since < S.SETTLE or mouse_down() then return end
  if cur ~= '' then set('sel_prev', cur) end
  set('sel_cur', snap)
end

-- Another project: the remembered selections belong to the old one.
function S.reset()
  set('sel_cur', ''); set('sel_prev', '')
  pending, pending_since = nil, nil
end

function S.watching()
  local hb = tonumber(get('sel_hb'))
  return hb ~= nil and r.time_precise() - hb < 1
end

local function track_indexes(list)
  local want, sel, any = {}, {}, false
  for g in (list or ''):gmatch('[^,]+') do want[g] = true end
  for i = 0, r.CountTracks(0) - 1 do
    if want[r.GetTrackGUID(r.GetTrack(0, i))] then sel[i], any = true, true end
  end
  return sel, any
end

-- Write a stored selection back
local function apply(text)
  local kind, a, b, list = text:match('^(R)|([^|]+)|([^|]+)|(.*)$')
  if kind then
    local MS = dofile(DIR .. 'hsuanice_PT_MouseSelect.lua')
    local sel = track_indexes(list)
    MS.apply(tonumber(a), tonumber(b), sel)
    r.SetEditCurPos(tonumber(a), false, false) -- the playhead (Edit position) goes to the range start
    return true
  end
  local p
  kind, p, list = text:match('^(P)|([^|]+)|(.*)$')
  if not kind then return false end
  local sel = track_indexes(list)
  for i = 0, r.CountTracks(0) - 1 do -- no range any more: track-level razor areas off
    local tr = r.GetTrack(0, i)
    local _, s = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false)
    if s and s ~= '' then
      local keep = {}
      for x, y, g in s:gmatch('(%S+)%s+(%S+)%s+"([^"]*)"') do
        if g ~= '' then keep[#keep + 1] = string.format('%s %s "%s"', x, y, g) end
      end
      r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', table.concat(keep, ' '), true)
    end
    local want = sel[i] == true
    if r.IsTrackSelected(tr) ~= want then r.SetTrackSelected(tr, want) end
  end
  r.GetSet_LoopTimeRange2(0, true, false, 0, 0, false)
  r.SetEditCurPos(tonumber(p), false, false)
  return true
end

-- Restore Last Selection: swap the current Edit Selection with the previous one.
-- A selection made less than 0.5 s ago (not recorded yet) counts as the current one.
-- Returns "ok" | "none" (nothing remembered) | "not_watching" (Counters Panel not running).
function S.restore()
  if not S.watching() then return 'not_watching' end
  local live, cur, prev = S.capture(), get('sel_cur'), get('sel_prev')
  local target
  if cur ~= '' and live ~= cur then target = cur else target = prev end
  if target == '' or target == live then return 'none' end
  if not apply(target) then return 'none' end
  set('sel_prev', live)
  set('sel_cur', S.capture()) -- as REAPER has it now (the Panel sees no change)
  return 'ok'
end

return S
