--[[
@description hsuanice_PT_TrackEdit - tracks of the Edit Selection (PT2Reaper library)
@version 26.1115.1539pre1
@author hsuanice
@noindex
@changelog
  - move_insertion(): the edit selection collapses to one track below / above its top track, like Pro Tools.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the PT2Reaper "... Tracks with an Edit Selection" actions. Loaded with dofile().

  Tracks of the Edit Selection (Pro Tools): tracks that have a razor area; with no razor area,
  the selected tracks; with neither, the tracks of the selected items.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local M = {}

function M.edit_tracks()
  local razor, selected, seen = {}, {}, {}
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, rz = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if rz and rz:match("%S") then razor[#razor + 1] = tr end
    if r.IsTrackSelected(tr) then selected[#selected + 1] = tr end
  end
  if #razor > 0 then return razor end
  if #selected > 0 then return selected end
  local items = {}
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local tr = r.GetMediaItem_Track(r.GetSelectedMediaItem(0, i))
    if not seen[tr] then seen[tr] = true; items[#items + 1] = tr end
  end
  return items
end

-- Pro Tools style toggle for several tracks: every track flips its own state (a mixed
-- selection stays mixed - Pro Tools does not make them all the same).
-- is_on(track) -> bool, set(track, on). Returns how many tracks went on and off.
function M.toggle_each(tracks, is_on, set)
  local n_on, n_off = 0, 0
  for _, tr in ipairs(tracks) do
    local on = not is_on(tr)
    set(tr, on)
    if on then n_on = n_on + 1 else n_off = n_off + 1 end
  end
  return n_on, n_off
end

------------------------------------------------------------------------------
-- Edit insertion up / down (Move Edit Insertion Up / Down, Remove Edit Insertion From
-- Top / Bottom Track). Works on visible tracks only (hidden tracks are skipped).
-- Razor mode: the tracks with a razor area; the track selection follows only when every
-- one of those tracks was selected (Track and Razor link style). Else: the selected tracks.
------------------------------------------------------------------------------
local function visible_tracks()
  local list, idx = {}, {}
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if r.IsTrackVisible(tr, false) then list[#list + 1] = tr; idx[tr] = #list end
  end
  return list, idx
end

local function get_razor(tr)
  local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
  return s or ""
end

-- track-level razor zones only (envelope-lane zones belong to that track's envelopes)
local function track_zones(s)
  local t = {}
  for a, b, g in s:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
    if g == '""' then t[#t + 1] = a .. " " .. b .. ' ""' end
  end
  return table.concat(t, " ")
end

local function edit_rows()
  local vis, idx = visible_tracks()
  local rows, all_sel = {}, true
  for _, tr in ipairs(vis) do
    if get_razor(tr):match("%S") then
      rows[#rows + 1] = tr
      if not r.IsTrackSelected(tr) then all_sel = false end
    end
  end
  if #rows > 0 then return "razor", rows, vis, idx, all_sel end
  for _, tr in ipairs(vis) do
    if r.IsTrackSelected(tr) then rows[#rows + 1] = tr end
  end
  return "tracks", rows, vis, idx, true
end

-- dir = 1 (down) or -1 (up). Pro Tools: the edit selection collapses to ONE track, the one
-- below (down) / above (up) the TOP track of the selection, same time range (Audio 6-8 ->
-- down -> Audio 7 -> down -> Audio 8). Nothing moves when there is no such track.
-- Returns true when something moved.
function M.move_insertion(dir)
  local mode, rows, vis, idx, sel_follows = edit_rows()
  if #rows == 0 then return false end
  local target = vis[idx[rows[1]] + dir]
  if not target then return false end
  if mode == "razor" then
    local zones = ""
    for _, tr in ipairs(rows) do
      zones = track_zones(get_razor(tr))
      if zones ~= "" then break end -- the top track's time range (first one that has one)
    end
    for _, tr in ipairs(rows) do r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", true) end
    r.GetSetMediaTrackInfo_String(target, "P_RAZOREDITS", zones, true)
  end
  if sel_follows then
    for _, tr in ipairs(rows) do r.SetTrackSelected(tr, false) end
    r.SetTrackSelected(target, true)
  end
  return true
end

-- edge = "top" or "bottom". Keeps at least one track. Returns true when a track was removed.
function M.remove_insertion(edge)
  local mode, rows, _, _, sel_follows = edit_rows()
  if #rows <= 1 then return false end
  local tr = edge == "top" and rows[1] or rows[#rows]
  if mode == "razor" then r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", true) end
  if sel_follows then r.SetTrackSelected(tr, false) end
  return true
end

return M
