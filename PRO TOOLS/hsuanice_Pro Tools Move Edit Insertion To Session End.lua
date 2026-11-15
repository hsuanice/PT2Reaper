--[[
@description hsuanice_Pro Tools Move Edit Insertion To Session End
@version 26.1115.1531
@author hsuanice
@noindex
@changelog
  - Clears every kind of selection: time selection, loop points, razor areas, item selection (track selection stays).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion To Session End**
  (PT key: Opt+Return)

  Moves the edit insertion (edit cursor) to the session end = the end of the last item on a
  visible track
  (same end as Move Edit Insertion To Session End - Extend Selection). Every kind of selection
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

-- Session end = end of the last item on a visible track (hidden tracks - archives, QuickPunch
-- buffer tracks - are not part of the session you see)
local session_end = 0
for ti = 0, r.CountTracks(0) - 1 do
  local tr = r.GetTrack(0, ti)
  if r.IsTrackVisible(tr, false) then
    for ii = 0, r.CountTrackMediaItems(tr) - 1 do
      local it = r.GetTrackMediaItem(tr, ii)
      local e = r.GetMediaItemInfo_Value(it, "D_POSITION") + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if e > session_end then session_end = e end
    end
  end
end

r.PreventUIRefresh(1)
collapse_selection()
r.SetEditCurPos(session_end, true, false)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point (like moving the cursor by hand)
