--[[
@description hsuanice_Pro Tools Move Edit Insertion To Session Start - Extend Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools:
  **Move Edit Insertion To Session Start [Extend Selection]**

  ## Behaviour
  - Extends selection leftward to session start (0)
  - Cursor moves to session start (new left edge)
  - Right edge of existing selection is preserved
  - Selection only grows, never shrinks

  - Tags : Editing, Navigation, Selection
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

local function get_selected_tracks()
  local tracks = {}
  for i = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(tr, "I_SELECTED") == 1 then
      tracks[#tracks+1] = tr
    end
  end
  return tracks
end

local EPS = 1e-4
local cursor_pos = r.GetCursorPosition()
local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts = te > ts + EPS

-- Right anchor = selection end or cursor (whichever is rightmost)
local right_anchor = has_ts and math.max(te, cursor_pos) or cursor_pos

-- New left edge = session start
local new_pos = 0.0

-- Move cursor to session start
r.SetEditCurPos(new_pos, false, false)

-- Set time selection + razor
r.GetSet_LoopTimeRange(true, false, new_pos, right_anchor, false)

local tracks = get_selected_tracks()
for _, tr in ipairs(tracks) do
  local razor_str = string.format('%.14f %.14f ""', new_pos, right_anchor)
  r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", razor_str, true)
end

r.defer(function() end)
