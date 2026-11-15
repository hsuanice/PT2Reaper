--[[
@description hsuanice_Pro Tools Move Edit Insertion To Song Start
@version 26.1115.1524pre1
@author hsuanice
@noindex
@changelog
  - Clears every kind of selection: time selection, loop points, razor areas, item selection (track selection stays).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion To Song Start**
  (PT key: Control+Shift+Return)

  Moves the edit insertion (edit cursor) to the start of the project. Every kind of selection
  (time selection, loop points, razor areas, item selection) is cleared; the track
  selection stays. The view follows.

  - Tags : Selection, Editing
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

-- Edit insertion only: every kind of selection is cleared - time selection, loop points,
-- razor areas and item selection. The track selection stays (it marks where the insertion is).
local function collapse_selection()
  r.GetSet_LoopTimeRange(true, false, 0, 0, false) -- time selection
  r.GetSet_LoopTimeRange(true, true, 0, 0, false)  -- loop points
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, rz = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if rz and rz ~= "" then r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", true) end
  end
  r.SelectAllMediaItems(0, false)                  -- item selection
end

r.PreventUIRefresh(1)
collapse_selection()
r.SetEditCurPos(0, true, false)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point (like moving the cursor by hand)
