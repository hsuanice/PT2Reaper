--[[
@description hsuanice_Pro Tools Mouse - Double-Click Selects Gap Between Clips
@version 26.1115.1932
@author hsuanice
@noindex
@changelog
  - First version.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **double-click on empty track space selects the space between clips** (mouse)

  The new Edit Selection is the gap on the clicked track: from the end of the clip before
  to the start of the clip after (before the first clip: from 0; after the last clip: to the
  session end). Other selections are replaced; the edit cursor goes to the selection start.

  Setup: Preferences > Mouse Modifiers > Track > Double click > (no modifier): this action.
  Gap selection inspired by benmrx (Ben Kersten)'s "MRX_RazorEdit_Enclose_EmptyArea".

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

local tr = MS.mouse_track()
if not tr then return r.defer(function() end) end
local g0, g1 = MS.gap_at(tr, MS.mouse_time(false))
if not g0 then return r.defer(function() end) end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
local sel = {}
sel[math.floor(r.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")) - 1] = true
MS.apply(g0, g1, sel)
r.SetEditCurPos(g0, false, false)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Double-click selects gap", -1)
