-- @description hsuanice_Pro Tools Mute Tracks with an Edit Selection
-- @version 0.2.0 [260509.1245]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Mute Tracks with an Edit Selection**
--   (Shift+M)
--
--   Toggles mute on every track that has any of:
--   - selected media items
--   - track-level razor edit zones
--
--   PT-style mixed handling: if the affected tracks have mixed mute
--   states, all are unified to MUTED. If uniform, all toggle.
--
--   - Tags : Editing, Selection, Tracks
-- @changelog
--   0.2.0 [260509.1245] - First implementation. Targets tracks with
--                          item selection OR razor zones; PT-style
--                          mixed-state unification to muted.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper

local function track_has_razor(tr)
  local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
  return s and s ~= ""
end

-- Collect target tracks
local targets = {}

for i = 0, r.CountSelectedMediaItems(0) - 1 do
  local it = r.GetSelectedMediaItem(0, i)
  if r.ValidatePtr(it, "MediaItem*") then
    targets[r.GetMediaItem_Track(it)] = true
  end
end

for ti = 0, r.CountTracks(0) - 1 do
  local tr = r.GetTrack(0, ti)
  if track_has_razor(tr) then targets[tr] = true end
end

-- Collect into ordered list, count mute states
local list, muted_n, unmuted_n = {}, 0, 0
for tr in pairs(targets) do
  list[#list+1] = tr
  if r.GetMediaTrackInfo_Value(tr, "B_MUTE") > 0.5 then
    muted_n = muted_n + 1
  else
    unmuted_n = unmuted_n + 1
  end
end
if #list == 0 then return end

r.Undo_BeginBlock()

local target_state
if #list == 1 then
  -- Single track: regular toggle
  target_state = (muted_n == 0)
elseif muted_n > 0 and unmuted_n > 0 then
  -- Mixed: unify to MUTED (PT-style)
  target_state = true
else
  -- Uniform: toggle all
  target_state = (muted_n == 0)
end

for _, tr in ipairs(list) do
  r.SetMediaTrackInfo_Value(tr, "B_MUTE", target_state and 1 or 0)
end

r.Undo_EndBlock("Pro Tools: Mute Tracks with an Edit Selection", -1)
