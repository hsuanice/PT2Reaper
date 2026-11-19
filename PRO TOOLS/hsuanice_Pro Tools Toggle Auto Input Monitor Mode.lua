--[[
@description hsuanice_Pro Tools Toggle Auto Input Monitor Mode
@version 26.1119.1341pre1
@author hsuanice
@noindex
@changelog
  - Record-armed tracks switch between Auto Input (REAPER: auto / tape style) and Input Only monitoring.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Toggle Auto Input Monitor Mode**
  (PT key: Option+K)

  Pro Tools switches between Auto Input Monitoring and Input Only Monitoring; it only acts on
  record-armed tracks. Here the record-armed tracks switch together:
  - all of them on input monitoring (REAPER "Record monitoring: on" = Input Only) ->
    REAPER "auto (tape style)" = Auto Input: the input while stopped and inside a punch,
    playback while playing over existing material;
  - otherwise -> all of them Input Only.
  No record-armed track: nothing (Pro Tools).
  Input Monitor Tracks with an Edit Selection (Shift+I) switches single tracks, armed or not.
  The toolbar button is lit while the armed tracks are Input Only.

  - Tags : Recording, Tracks
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local MON_ON, MON_AUTO = 1, 2 -- I_RECMON: 1 = on (Input Only), 2 = auto (tape style)

local armed = {}
for i = 0, r.CountTracks(0) - 1 do
  local tr = r.GetTrack(0, i)
  if r.GetMediaTrackInfo_Value(tr, "I_RECARM") == 1 then armed[#armed + 1] = tr end
end
if #armed == 0 then return r.defer(function() end) end

local all_input = true
for _, tr in ipairs(armed) do
  if r.GetMediaTrackInfo_Value(tr, "I_RECMON") ~= MON_ON then all_input = false; break end
end
local mode = all_input and MON_AUTO or MON_ON

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
for _, tr in ipairs(armed) do r.SetTrackUIInputMonitor(tr, mode, 2) end -- 2: no selection ganging
r.PreventUIRefresh(-1)
r.TrackList_AdjustWindows(false)
local _, _, _, cmd = r.get_action_context()
if cmd and cmd ~= 0 then r.SetToggleCommandState(0, cmd, mode == MON_ON and 1 or 0); r.RefreshToolbar2(0, cmd) end
r.Undo_EndBlock('Pro Tools: ' .. (mode == MON_ON and 'Input Only' or 'Auto Input') .. ' monitoring', -1)
