--[[
@description hsuanice_PT_Transport - Transport Library (PT2Reaper)
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the PT2Reaper transport scripts (Play-Stop, Play Half Speed,
  Insertion Follows Playback). Loaded with dofile(); not an action.
  Copied from Beta Testing/QuickPunch/hsuanice_Transport Core.lua (26.1114) so the
  PT script set is self-contained; own ExtState namespace "hsuanice_PT_Transport"
  (independent of the Main keymap's Transport scripts).
  Credits: behaviour modelled on TJF Scripts by Tim Farrell (github.com/sonictim/TJF-Scripts):
  TJF playback that reads insertion toggle, TJF Toggle Insertion follows Playback,
  TJF Playback at Half Speed once.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local T = {}
T.NS = "hsuanice_PT_Transport"

local CMD_PLAY = 1007
local CMD_STOP = 1016
local CMD_EDIT_TO_PLAY = 40434 -- View: Move edit cursor to play cursor

-- Insertion Follows Playback (Pro Tools "N"): saved, survives a REAPER restart.
function T.follows() return r.GetExtState(T.NS, "insertion_follows") == "1" end
function T.refresh_follows_button()
  local cmd = tonumber(r.GetExtState(T.NS, "cmd_follows"))
  if cmd then
    r.SetToggleCommandState(0, cmd, T.follows() and 1 or 0)
    r.RefreshToolbar2(0, cmd)
  end
end
function T.set_follows(on)
  r.SetExtState(T.NS, "insertion_follows", on and "1" or "0", true)
  T.refresh_follows_button()
end

-- Half speed is "once": any stop / next play goes back to normal speed.
function T.set_half_speed()
  r.CSurf_OnPlayRateChange(0.5)
  r.SetExtState(T.NS, "half_speed", "1", false)
end
function T.reset_half_speed()
  if r.GetExtState(T.NS, "half_speed") == "1" then
    r.CSurf_OnPlayRateChange(1)
    r.SetExtState(T.NS, "half_speed", "0", false)
  end
end

-- Where playback starts: the start of the time selection, else the edit cursor.
function T.start_position()
  local ts, te = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if te > ts then return ts end
  return r.GetCursorPosition()
end

function T.is_running() return r.GetPlayState() ~= 0 end

function T.play()
  r.SetEditCurPos2(0, T.start_position(), true, false)
  r.Main_OnCommand(CMD_PLAY, 0)
end

-- Insertion Follows Playback on: the edit cursor stays where playback stopped.
function T.before_stop()
  if T.follows() then r.Main_OnCommand(CMD_EDIT_TO_PLAY, 0) end
end

function T.stop()
  T.before_stop()
  r.Main_OnCommand(CMD_STOP, 0)
end

return T
