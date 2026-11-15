--[[
@description hsuanice_Pro Tools Move Edit Insertion To Session End
@version 26.1115.1428pre1
@author hsuanice
@noindex
@changelog
  - First implementation (was a stub).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion To Session End**
  (PT key: Opt+Return)

  Moves the edit insertion (edit cursor) to the session end = the end of the last item
  (same end as Move Edit Insertion To Session End - Extend Selection). The edit selection
  (time selection, razor areas) is collapsed to the insertion point; the view follows.

  - Tags : Selection, Editing
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

-- Edit insertion only: the edit selection (time selection + razor areas) is collapsed;
-- the track selection stays (it marks where the insertion is).
local function collapse_selection()
  r.GetSet_LoopTimeRange(true, false, 0, 0, false)
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, rz = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if rz and rz ~= "" then r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", true) end
  end
end

local session_end = 0
for i = 0, r.CountMediaItems(0) - 1 do
  local it = r.GetMediaItem(0, i)
  local e = r.GetMediaItemInfo_Value(it, "D_POSITION") + r.GetMediaItemInfo_Value(it, "D_LENGTH")
  if e > session_end then session_end = e end
end

r.PreventUIRefresh(1)
collapse_selection()
r.SetEditCurPos(session_end, true, false)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point (like moving the cursor by hand)
