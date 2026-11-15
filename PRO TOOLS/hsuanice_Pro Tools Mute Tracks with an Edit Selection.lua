--[[
@description hsuanice_Pro Tools Mute Tracks with an Edit Selection
@version 26.1115.1428pre1
@author hsuanice
@noindex
@changelog
  - First implementation (was a stub).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Mute Tracks with an Edit Selection**
  (PT key: Shift+M)

  Mutes / unmutes the tracks of the Edit Selection: tracks with a razor area; with no razor area,
  the selected tracks; with neither, the tracks of the selected items.
  Pro Tools style toggle: if any of these tracks is off, all go on; if all are on, all go off.
  Works like clicking the track button (track groups and REAPER's preferences apply).

  - Tags : Tracks, Editing
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, TE = pcall(dofile, DIR .. 'hsuanice_PT_TrackEdit.lua')
if not ok or type(TE) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_TrackEdit.lua\n\n' .. tostring(TE), 'Error', 0)
  return
end

local tracks = TE.edit_tracks()
if #tracks == 0 then return r.defer(function() end) end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
local on = TE.toggle_all(tracks,
  function(tr) return r.GetMediaTrackInfo_Value(tr, "B_MUTE") == 1 end,
  function(tr, on) r.SetTrackUIMute(tr, on and 1 or 0, 0) end)
r.PreventUIRefresh(-1)
r.TrackList_AdjustWindows(false)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Mute ' .. (on and 'on' or 'off') .. ' (' .. #tracks .. ' track' .. (#tracks == 1 and '' or 's') .. ')', -1)
