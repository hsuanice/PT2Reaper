--[[
@description hsuanice_Pro Tools Extend Edit Selection Down Including Folder Siblings
@version 26.1118.1524pre1
@author hsuanice
@noindex
@changelog
  - First version (was a placeholder): Pro Tools behaviour, tested in Pro Tools by hsuanice.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Extend Edit Selection Down Including Folder Siblings**
  (PT key: Option+Control+Shift+;)

  Like Extend Edit Insertion Down, the Edit Selection only grows by the next visible track
  below it, with the same time range. When that track is inside a folder, all the
  visible tracks of that folder come with it (Audio 2 -> Folder 1 -> Folder 1 + Audio 3-5; Audio 4 -> + Audio 3, 5).
  A folder track itself is added like any track; the tracks of a closed folder are skipped.
  Edit Selection tracks: the tracks with a razor area (the track selection follows when all
  of them were selected); with no razor area, the selected tracks. Hidden tracks are skipped.

  Self-contained: uses hsuanice_PT_TrackEdit.lua (same folder).
  - Tags : Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, TE = pcall(dofile, DIR .. 'hsuanice_PT_TrackEdit.lua')
if not ok or type(TE) ~= 'table' or not TE.extend_with_siblings then
  r.ShowMessageBox('Could not load hsuanice_PT_TrackEdit.lua\n\n' .. tostring(TE), 'Error', 0)
  return
end

r.PreventUIRefresh(1)
local moved = TE.extend_with_siblings(1)
r.PreventUIRefresh(-1)
if moved then
  r.TrackList_AdjustWindows(false)
  r.UpdateArrange()
end
r.defer(function() end) -- no undo point (a selection change, like Pro Tools)
