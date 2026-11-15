--[[
@description hsuanice_PT_TrackEdit - tracks of the Edit Selection (PT2Reaper library)
@version 26.1115.1428pre1
@author hsuanice
@noindex
@changelog
  - First version: edit_tracks() + toggle_all() for the "... Tracks with an Edit Selection" actions.
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

-- Pro Tools style toggle for several tracks: if any track is off, all go on; if all are
-- on, all go off. is_on(track) -> bool, set(track, on).
-- Returns the new state (true / false) or nil when there is no track.
function M.toggle_all(tracks, is_on, set)
  if #tracks == 0 then return nil end
  local all_on = true
  for _, tr in ipairs(tracks) do
    if not is_on(tr) then all_on = false; break end
  end
  local on = not all_on
  for _, tr in ipairs(tracks) do set(tr, on) end
  return on
end

return M
