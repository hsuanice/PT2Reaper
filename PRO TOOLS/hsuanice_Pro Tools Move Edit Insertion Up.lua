--[[
@description hsuanice_Pro Tools Move Edit Insertion Up
@version 26.1115.1533pre1
@author hsuanice
@noindex
@changelog
  - First implementation (was a stub).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Move Edit Insertion Up**
  (PT key: Control+P (Commands Focus: P))

  Moves the whole Edit Selection one visible track UP (same time range). Nothing moves when
  a track of it is already the first visible track. Razor areas on envelope lanes are dropped.
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
local moved = TE.move_insertion(-1)
r.PreventUIRefresh(-1)
if moved then
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
end
r.defer(function() end) -- no undo point (a selection change, like Pro Tools)
