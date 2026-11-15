--[[
@description hsuanice_PT_MouseSelect - Pro Tools mouse clicks on the Edit Selection (PT2Reaper library)
@version 26.1115.1932
@author hsuanice
@noindex
@changelog
  - Shift-click (Pro Tools): a track outside the selection is only added (the range stays); inside the selection, the nearer edge trims to the click.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the PT2Reaper mouse modifier actions. Loaded with dofile().

  The Edit Selection is one time range shared by a set of tracks (razor areas, mirrored to the
  time selection and the track selection).
  Based on hsuanice's "Extend Razor Edit to Mouse Cursor like Pro Tools" (ReaScripts), which was
  inspired by Daniel Kharrat's "Extend razor edit area to mouse cursor (select tracks in between)".
  Gap selection inspired by benmrx (Ben Kersten)'s "MRX_RazorEdit_Enclose_EmptyArea".
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local M = {}
local EPS = 1e-9

M.SYNC_TIME_SELECTION = true   -- time selection = the Edit Selection range
M.SYNC_TRACK_SELECTION = true  -- selected tracks = the tracks of the Edit Selection

local function track_index(tr)
  return math.floor(r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")) - 1 -- master = -2
end

-- P_RAZOREDITS -> track-level ranges + envelope-lane entries (kept as they are)
local function parse_razor(tr)
  local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
  local ranges, env = {}, {}
  for a, b, guid in (s or ""):gmatch('(%S+)%s+(%S+)%s+"([^"]*)"') do
    local st, en = tonumber(a), tonumber(b)
    if st and en then
      if guid == "" then
        ranges[#ranges + 1] = { st, en }
      else
        env[#env + 1] = string.format('%s %s "%s"', a, b, guid)
      end
    end
  end
  return ranges, env
end

-- Mouse time: let REAPER move the edit cursor to the mouse, read it, put the cursor back.
-- snap = true follows snap / grid (40513), false = exact mouse position (40514).
function M.mouse_time(snap)
  local old = r.GetCursorPosition()
  r.Main_OnCommand(snap and 40513 or 40514, 0)
  local t = r.GetCursorPosition()
  r.SetEditCurPos(old, false, false)
  return t
end

-- Track under the mouse (nil for the master track / no track)
function M.mouse_track()
  local x, y = r.GetMousePosition()
  local tr = r.GetTrackFromPoint(x, y)
  if tr and track_index(tr) >= 0 then return tr end
end

-- REAPER clears razor areas on mouse-down over an item, before the click action runs.
-- hsuanice's "Toggle Track and Razor Item Link like Pro Tools" (if it runs) stores the last
-- razor area in ExtState; use it only while the time selection still equals that range.
-- Optional: without it, the time selection + selected tracks are used.
local function remembered_razor(sel)
  local v = r.GetExtState("hsuanice_Link", "last_razor")
  local a, b, list = v:match("^(%S+) (%S+) (%S+)$")
  local s0, s1 = tonumber(a), tonumber(b)
  if not (s0 and s1) then return nil end
  local ts0, ts1 = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if math.abs(ts0 - s0) > 1e-6 or math.abs(ts1 - s1) > 1e-6 then return nil end
  local want, found = {}, false
  for g in list:gmatch("[^,]+") do want[g] = true end
  for i = 0, r.CountTracks(0) - 1 do
    if want[r.GetTrackGUID(r.GetTrack(0, i))] then sel[i], found = true, true end
  end
  if found then return s0, s1 end
end

-- Current Edit Selection: t0, t1, sel (track index -> true), has_tracks.
-- Razor areas (union); else the remembered razor; else time selection (or edit cursor)
-- + selected tracks (or the last touched track).
function M.current()
  local t0, t1, sel, has = nil, nil, {}, false
  for i = 0, r.CountTracks(0) - 1 do
    for _, rg in ipairs((parse_razor(r.GetTrack(0, i)))) do
      t0 = t0 and math.min(t0, rg[1]) or rg[1]
      t1 = t1 and math.max(t1, rg[2]) or rg[2]
      sel[i], has = true, true
    end
  end
  if t0 then return t0, t1, sel, has end

  t0, t1 = remembered_razor(sel)
  if t0 then return t0, t1, sel, true end

  local ts0, ts1 = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts1 - ts0 > EPS then
    t0, t1 = ts0, ts1
  else
    t0 = r.GetCursorPosition(); t1 = t0
  end
  for i = 0, r.CountSelectedTracks(0) - 1 do
    local idx = track_index(r.GetSelectedTrack(0, i))
    if idx >= 0 then sel[idx], has = true, true end
  end
  if not has then
    local lt = r.GetLastTouchedTrack()
    local idx = lt and track_index(lt) or -1
    if idx >= 0 then sel[idx], has = true, true end
  end
  return t0, t1, sel, has
end

-- Write the Edit Selection: one track-level razor range on every track in sel, no other
-- track-level razor areas (envelope-lane areas kept); time / track selection mirrored.
function M.apply(t0, t1, sel)
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local ranges, env = parse_razor(tr)
    local in_area = sel[i] == true
    if in_area or #ranges > 0 then
      local parts = {}
      if in_area then parts[1] = string.format('%.14f %.14f ""', t0, t1) end
      for _, e in ipairs(env) do parts[#parts + 1] = e end
      r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", table.concat(parts, " "), true)
    end
    if M.SYNC_TRACK_SELECTION and r.IsTrackSelected(tr) ~= in_area then
      r.SetTrackSelected(tr, in_area)
    end
  end
  if M.SYNC_TIME_SELECTION then r.GetSet_LoopTimeRange(true, false, t0, t1, false) end
end

-- Extend the current Edit Selection to cover [c0, c1] and add track tr (only grows).
-- trim_t given = Pro Tools Shift-click:
--   * tr already in the selection: [c0, c1] outside the range extends it; inside the range,
--     the nearer edge moves to trim_t (the selection shrinks).
--   * tr not in the selection: only the track is added, the range stays as it is.
--   * no range yet (only an insertion point): extends from it to the click.
function M.extend(c0, c1, tr, trim_t)
  local t0, t1, sel, has = M.current()
  local idx = tr and track_index(tr) or -1
  local range_only = trim_t and t1 - t0 > EPS and idx >= 0 and not sel[idx]
  if range_only then
    -- keep t0, t1
  elseif trim_t and c0 > t0 + EPS and c1 < t1 - EPS and trim_t > t0 + EPS and trim_t < t1 - EPS then
    if trim_t - t0 < t1 - trim_t then t0 = trim_t else t1 = trim_t end
  else
    t0, t1 = math.min(t0, c0), math.max(t1, c1)
  end
  if tr and track_index(tr) >= 0 then sel[track_index(tr)], has = true, true end
  if not has or t1 - t0 <= EPS then return false end
  M.apply(t0, t1, sel)
  return true
end

-- End of the last item on the visible tracks (Pro Tools "session end")
local function session_end()
  local e = 0
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if r.IsTrackVisible(tr, false) then
      local n = r.CountTrackMediaItems(tr)
      if n > 0 then
        for j = 0, n - 1 do
          local it = r.GetTrackMediaItem(tr, j)
          local en = r.GetMediaItemInfo_Value(it, "D_POSITION") + r.GetMediaItemInfo_Value(it, "D_LENGTH")
          if en > e then e = en end
        end
      end
    end
  end
  return e
end

-- Empty space between clips on track tr around time t: g0, g1 (nil when t is on a clip or
-- the track has no clips). Before the first clip: from 0. After the last clip: to the
-- session end (last clip end of the visible tracks), nil when there is nothing after it.
function M.gap_at(tr, t)
  local n = r.CountTrackMediaItems(tr)
  if n == 0 then return nil end
  local g0, g1 = 0, nil
  for j = 0, n - 1 do
    local it = r.GetTrackMediaItem(tr, j)
    local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local en = p + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if p < t - EPS and en > t + EPS then return nil end -- on a clip
    if en <= t + EPS and en > g0 then g0 = en end
    if p >= t - EPS and (not g1 or p < g1) then g1 = p end
  end
  if not g1 then
    g1 = session_end()
    if g1 <= g0 + EPS then return nil end
  end
  if g1 - g0 <= EPS then return nil end
  return g0, g1
end

return M
