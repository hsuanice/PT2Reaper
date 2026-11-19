--[[
@description hsuanice_Pro Tools Fit Track Size To Window
@version 26.1119.1341pre1
@author hsuanice
@noindex
@changelog
  - The tracks of the Edit Selection fill the arrange view vertically; not a toggle.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Fit Track Size To Window**
  (PT keys: Command+Control+Up Arrow, Command+Control+Down Arrow)

  The tracks of the Edit Selection (tracks with a razor area; else the selected tracks; else
  the tracks of the selected items) get the same height so that together they fill the
  arrange view, and they are scrolled to the top. Not a toggle: pressing it again changes
  nothing (Pro Tools). Horizontal zoom is not changed.
  Needs js_ReaScriptAPI to measure the arrange view; without it REAPER's "Toggle track zoom
  to maximum height" is used on the selected tracks instead.

  Self-contained: uses hsuanice_PT_TrackEdit.lua (same folder).
  - Tags : Zoom, Tracks
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

local CMD_MAX_HEIGHT = 40113 -- View: Toggle track zoom to maximum height (limit to 100% of arrange view)
local TRACKVIEW_ID = 1000    -- the arrange (track view) child window of the main window

local tracks = TE.edit_tracks()
if #tracks == 0 then return r.defer(function() end) end

local tv = r.JS_Window_FindChildByID and r.JS_Window_FindChildByID(r.GetMainHwnd(), TRACKVIEW_ID)
local okc, _, view_h = false, 0, 0
if tv then okc, _, view_h = r.JS_Window_GetClientSize(tv) end

r.PreventUIRefresh(1)
if okc and view_h and view_h > 0 then
  -- the envelope lanes of a track take their own room: the track part shares the rest
  local env_h = 0
  for _, tr in ipairs(tracks) do
    -- I_WNDH = the track with its envelope lanes, I_TCPH = the track alone
    env_h = env_h + math.max(0, r.GetMediaTrackInfo_Value(tr, "I_WNDH") - r.GetMediaTrackInfo_Value(tr, "I_TCPH"))
  end
  local h = math.max(1, math.floor((view_h - env_h) / #tracks))
  for _, tr in ipairs(tracks) do r.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", h) end
  r.TrackList_AdjustWindows(false)
  -- scroll the first one to the top
  local okp, pos = r.JS_Window_GetScrollInfo(tv, "v")
  if okp then
    r.JS_Window_SetScrollPos(tv, "v", math.floor(pos + r.GetMediaTrackInfo_Value(tracks[1], "I_TCPY")))
  end
else
  -- no js_ReaScriptAPI: REAPER's own (selected tracks); turn it off first so it never restores
  if r.GetToggleCommandState(CMD_MAX_HEIGHT) == 1 then r.Main_OnCommand(CMD_MAX_HEIGHT, 0) end
  r.Main_OnCommand(CMD_MAX_HEIGHT, 0)
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.defer(function() end) -- no undo point (zoom is not undoable in Pro Tools either)
