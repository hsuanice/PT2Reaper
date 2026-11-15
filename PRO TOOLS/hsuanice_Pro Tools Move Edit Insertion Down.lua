--[[
@description hsuanice_Pro Tools Move Edit Insertion Down
@version 26.1115.1539pre1
@author hsuanice
@noindex
@changelog
  - Like Pro Tools: the selection collapses to one track below its top track (was: whole selection moved).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion Down**
  (PT key: Control+; (Commands Focus: ;))

  Like Pro Tools, the Edit Selection collapses to ONE track: the visible track below the top
  track of the selection, same time range (Audio 6-8 -> Audio 7 -> Audio 8 for Down). Nothing
  moves when there is no such track. Razor areas on envelope lanes are dropped.
  Edit Selection tracks: the tracks with a razor area (the track selection follows when all
  of them were selected); with no razor area, the selected tracks. Hidden tracks are skipped.
  The edit cursor and the time selection stay.

  - Tags : Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, TE = pcall(dofile, DIR .. 'hsuanice_PT_TrackEdit.lua')
if not ok or type(TE) ~= 'table' or not TE.move_insertion then
  r.ShowMessageBox('Could not load hsuanice_PT_TrackEdit.lua\n\n' .. tostring(TE), 'Error', 0)
  return
end

r.PreventUIRefresh(1)
local moved = TE.move_insertion(1)
r.PreventUIRefresh(-1)
if moved then
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
end
r.defer(function() end) -- no undo point (a selection change, like Pro Tools)
