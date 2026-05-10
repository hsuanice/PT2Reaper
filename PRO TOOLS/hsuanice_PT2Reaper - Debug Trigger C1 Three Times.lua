-- @description hsuanice_PT2Reaper - Debug Trigger C1 Three Times
-- @version 0.1.0 [260509.1955]
-- @author hsuanice
-- @about
--   Diagnostic. Calls hsuanice_Pro Tools Play Edit Selection.lua
--   three times in a row via Main_OnCommand (each call separated
--   by a brief defer cycle). If the C1 console shows three
--   "INVOCATION #N" lines, the script is being launched correctly
--   on every call — meaning any "missing 2nd press" symptom is on
--   the keyboard-shortcut side (shortcut not delivered, focus
--   stolen, etc.), not on the script side.
--
--   Bind to a toolbar button (or run from Action List) and watch
--   the C1 console.
--
--   - Tags : Diagnostic
-- @changelog
--   0.1.0 [260509.1955] - Initial.

local r = reaper

local C1_CMD = r.NamedCommandLookup("_RS35d3333a892b732bd3778bad2d6f53ec6f58a110")
if not C1_CMD or C1_CMD == 0 then
  r.ShowMessageBox(
    "Could not look up C1 named command (_RS35d3333a892b732bd3778bad2d6f53ec6f58a110).\n" ..
    "Has the C1 script's command ID changed?",
    "Debug Trigger", 0)
  return
end

r.ShowConsoleMsg("[Trigger] C1 command id = " .. C1_CMD .. "\n")
r.ShowConsoleMsg("[Trigger] press #1 at " .. string.format("%.4f", r.time_precise()) .. "\n")
r.Main_OnCommand(C1_CMD, 0)

local n = 1
local function next_call()
  n = n + 1
  if n > 3 then return end
  r.ShowConsoleMsg("[Trigger] press #" .. n .. " at " .. string.format("%.4f", r.time_precise()) .. "\n")
  r.Main_OnCommand(C1_CMD, 0)
  r.defer(next_call)
end
r.defer(next_call)
