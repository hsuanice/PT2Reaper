-- @description hsuanice_Pro Tools Shrink Edit Selection To Next Edit
-- @version 0.2.0 [260509.1036]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Shrink Edit Selection To Next Edit**
--   (Cmd+Opt+Shift+L)
--
--   Shrinks the selection from the LEFT side: TS_s moves rightward
--   to the next edit point that is still inside the current TS.
--   - Tab to Transient ON  → next edit = next transient
--     (filtered by shared min-gap setting).
--   - Tab to Transient OFF → next edit = next item edge.
--
--   Time selection + razor zones on selected tracks shrink together.
--   No-op if no TS / next edit would land on / past TS_e.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags : Editing, Selection
--
-- @changelog
--   0.2.0 [260509.1036] - First implementation. Shrinks left side via
--                          native 40319 (or transient walk via library).
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local EPS = 1e-4

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Shrink Edit Selection To Next Edit", 0)
  return
end

local function get_tab_toggle_state()
  local section = r.SectionFromUniqueID(0)
  local idx = 0
  while true do
    local cid, cname = r.kbd_enumerateActions(section, idx)
    if cid == 0 and idx > 0 then break end
    if cname and cname:lower():find("pro tools tab to transient", 1, true) then
      return r.GetToggleCommandStateEx(0, cid) == 1
    end
    idx = idx + 1
    if idx > 200000 then break end
  end
  return false
end

local function get_selected_tracks()
  local tracks = {}
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(tr, "I_SELECTED") == 1 then
      tracks[#tracks+1] = tr
    end
  end
  return tracks
end

local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
if te <= ts + EPS then return end

local cursor_save = r.GetCursorPosition()
r.SetEditCurPos(ts, false, false)
r.Main_OnCommand(41229, 0)  -- Save selection set
r.Main_OnCommand(40421, 0)  -- Select all items in track

if get_tab_toggle_state() then
  Tran.cursor_to_next_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40319, 0)  -- Next item edge
end

local new_ts = r.GetCursorPosition()
r.Main_OnCommand(41239, 0)  -- Restore selection set
r.SetEditCurPos(cursor_save, false, false)

if new_ts > ts + EPS and new_ts < te - EPS then
  r.Undo_BeginBlock()
  r.GetSet_LoopTimeRange(true, false, new_ts, te, false)

  for _, tr in ipairs(get_selected_tracks()) do
    local _, str = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if str and str ~= "" then
      local parts = {}
      for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
        local s = tonumber(s_str); local e = tonumber(e_str)
        if s and e then
          local ns = math.max(s, new_ts)
          if ns < e - EPS then
            parts[#parts+1] = string.format("%.14f %.14f %s", ns, e, guid)
          end
        end
      end
      r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
        table.concat(parts, " "), true)
    end
  end
  r.Undo_EndBlock("Pro Tools: Shrink Edit Selection To Next Edit", -1)
end
