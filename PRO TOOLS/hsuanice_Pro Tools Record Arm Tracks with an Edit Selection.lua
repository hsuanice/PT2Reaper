--[[
@description hsuanice_Pro Tools Record Arm Tracks with an Edit Selection
@version 26.1115.1531
@author hsuanice
@noindex
@changelog
  - Fix: each track really flips its own state (no selection ganging; before, all selected tracks changed the same way).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Record Arm Tracks with an Edit Selection**
  (PT key: Shift+R)

  Record-arms / disarms the tracks of the Edit Selection: tracks with a razor area; with no razor area,
  the selected tracks; with neither, the tracks of the selected items.
  Pro Tools style toggle: every track flips its own state (a mixed selection stays mixed).
  Works like clicking the track button (track groups and REAPER's preferences apply), but
  without selection ganging (igngroupflags 2), so each track keeps its own state.

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
local n_on, n_off = TE.toggle_each(tracks,
  function(tr) return r.GetMediaTrackInfo_Value(tr, "I_RECARM") == 1 end,
  function(tr, on) r.SetTrackUIRecArm(tr, on and 1 or 0, 2) end)
r.PreventUIRefresh(-1)
r.TrackList_AdjustWindows(false)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Record arm toggle (' .. n_on .. ' on, ' .. n_off .. ' off)', -1)
