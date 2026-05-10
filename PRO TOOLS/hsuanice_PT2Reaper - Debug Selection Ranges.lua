-- @description hsuanice_PT2Reaper - Debug Selection Ranges
-- @version 0.1.0 [260509.1412]
-- @author hsuanice
-- @about
--   Diagnostic. Prints to the ReaScript console:
--   - Time selection range  (REAPER's GetSet_LoopTimeRange(false))
--   - Loop point range      (REAPER's GetSet_LoopTimeRange(true))
--   - Razor edit zones      (per track, P_RAZOREDITS)
--   - Edit cursor + play state
--
--   Useful for confirming which API call retrieves which range. PT's
--   "Timeline Selection" maps to REAPER's loop points; PT's "Edit
--   Selection" maps to razor edit zones.
--
--   - Tags : Diagnostic
-- @changelog
--   0.1.0 [260509.1412] - Initial release.

local r = reaper

local function fmt(t) return string.format("%.6f", t) end
local function len(s, e) return e - s end

local out = {}
out[#out+1] = "=== PT2Reaper Debug Selection Ranges ==="

-- 1. Time selection (isLoop = false)
do
  local s, e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if e > s + 1e-9 then
    out[#out+1] = string.format("Time selection : [%s, %s]  len=%s",
      fmt(s), fmt(e), fmt(len(s, e)))
  else
    out[#out+1] = "Time selection : (none)"
  end
end

-- 2. Loop points (isLoop = true)
do
  local s, e = r.GetSet_LoopTimeRange(false, true, 0, 0, false)
  if e > s + 1e-9 then
    out[#out+1] = string.format("Loop points    : [%s, %s]  len=%s",
      fmt(s), fmt(e), fmt(len(s, e)))
  else
    out[#out+1] = "Loop points    : (none)"
  end
end

-- 3. Razor edit zones (track-level + envelope-locked)
do
  out[#out+1] = ""
  out[#out+1] = "Razor edit zones:"
  local any = false
  for ti = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, ti)
    local _, name = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    local _, str  = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if str and str ~= "" then
      any = true
      out[#out+1] = string.format("  Track %d (%s):", ti + 1, name)
      for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
        local s, e = tonumber(s_str), tonumber(e_str)
        if s and e then
          local kind = (guid == '""') and "track-level" or ("env " .. guid)
          out[#out+1] = string.format("    [%s, %s]  len=%s  (%s)",
            fmt(s), fmt(e), fmt(e - s), kind)
        end
      end
    end
  end
  if not any then out[#out+1] = "  (none)" end
end

-- 4. Cursor + play state + repeat
do
  out[#out+1] = ""
  out[#out+1] = string.format("Edit cursor    : %s", fmt(r.GetCursorPosition()))
  out[#out+1] = string.format("Play position  : %s", fmt(r.GetPlayPosition()))
  local ps = r.GetPlayState()
  local ps_str = "stopped"
  if (ps & 1) ~= 0 then ps_str = "playing" end
  if (ps & 2) ~= 0 then ps_str = ps_str .. " | paused" end
  if (ps & 4) ~= 0 then ps_str = ps_str .. " | recording" end
  out[#out+1] = string.format("Play state     : %d (%s)", ps, ps_str)
  out[#out+1] = string.format("Repeat (loop)  : %d (%s)",
    r.GetSetRepeat(-1), r.GetSetRepeat(-1) == 1 and "ON" or "OFF")
end

out[#out+1] = "==========================================\n"

r.ShowConsoleMsg(table.concat(out, "\n") .. "\n")
