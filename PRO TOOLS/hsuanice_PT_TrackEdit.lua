--[[
@description hsuanice_PT_TrackEdit - tracks of the Edit Selection (PT2Reaper library)
@version 26.1115.1513pre1
@author hsuanice
@noindex
@changelog
  - toggle_each(): every track flips its own state, like Pro Tools (a mixed selection stays mixed).
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

return M
