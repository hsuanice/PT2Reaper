-- @description hsuanice_Pro Tools Double Edit Selection
-- @version 0.2.0 [260509.1036]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Double Edit Selection**
--   (Cmd+Opt+Ctrl+Shift+')
--
--   Doubles the length of the time selection and every razor zone,
--   keeping the LEFT edge as the anchor (selection extends rightward).
--   No-op if neither time selection nor razor exists.
--
--   - Tags : Editing, Selection
--
-- @changelog
--   0.2.0 [260509.1036] - First implementation. Doubles TS + razor
--                          length from the left anchor. Replaces the
--                          incorrect 0.1.0 mapping to native 40031
--                          (which was View: Zoom time selection).
--   0.1.0 [260413.1324] - Initial stub mismapped to action 40031.

local r = reaper
local EPS = 1e-9

local function scale_selection(factor)
  local changed = false
  -- Time selection
  local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if te > ts + EPS then
    local new_te = ts + factor * (te - ts)
    r.GetSet_LoopTimeRange(true, false, ts, new_te, false)
    changed = true
  end
  -- Razor zones (per track)
  for ti = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, ti)
    local _, str = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if str and str ~= "" then
      local parts = {}
      for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
        local s = tonumber(s_str)
        local e = tonumber(e_str)
        if s and e then
          parts[#parts+1] = string.format("%.14f %.14f %s",
            s, s + factor * (e - s), guid)
          changed = true
        end
      end
      if #parts > 0 then
        r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
          table.concat(parts, " "), true)
      end
    end
  end
  return changed
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
scale_selection(2.0)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Double Edit Selection", -1)
