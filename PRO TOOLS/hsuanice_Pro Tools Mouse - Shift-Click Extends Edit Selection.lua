--[[
@description hsuanice_Pro Tools Mouse - Shift-Click Extends Edit Selection
@version 26.1115.1930pre1
@author hsuanice
@noindex
@changelog
  - Pro Tools: Shift-click on a track outside the selection only adds the track (the range stays); inside the selection, the nearer edge trims to the click.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Shift-click extends the Edit Selection** (mouse)

  Extends the Edit Selection to the mouse position. Only grows: clicking before the range
  extends its start, after it extends its end. Clicking inside it trims the nearer edge
  (start or end) to the click. Clicking a clip outside the range extends to cover the whole
  clip; the click position follows snap / grid.
  Clicking a track that is not in the selection only adds that track (the range stays);
  every track of the selection gets the same range.
  The edit cursor does not move.

  Setup: Preferences > Mouse Modifiers > Track (left click), Media item bottom half (left click)
  and Razor edit area (left click) > Shift: this action.
  Based on hsuanice's "Extend Razor Edit to Mouse Cursor like Pro Tools", inspired by
  Daniel Kharrat's "Extend razor edit area to mouse cursor (select tracks in between)".

  - Tags : Selection, Mouse
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, MS = pcall(dofile, DIR .. 'hsuanice_PT_MouseSelect.lua')
if not ok or type(MS) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_MouseSelect.lua\n\n' .. tostring(MS), 'Error', 0)
  return
end

local x, y = r.GetMousePosition()
local item = r.GetItemFromPoint(x, y, true)
local c0, c1, tr
local t = MS.mouse_time(true)
if item then
  c0 = r.GetMediaItemInfo_Value(item, "D_POSITION")
  c1 = c0 + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  tr = r.GetMediaItem_Track(item)
else
  c0, c1 = t, t
  tr = MS.mouse_track()
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
MS.extend(c0, c1, tr, t)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Shift-click extends Edit Selection", -1)
