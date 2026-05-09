-- @description hsuanice_Pro Tools Shrink Edit Selection To Previous Edit
-- @version 0.2.0 [260509.1036]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Shrink Edit Selection To Previous Edit**
--   (Cmd+Opt+Shift+')
--
--   Shrinks the selection from the RIGHT side: TS_e moves leftward
--   to the previous edit point that is still inside the current TS.
--   - Tab to Transient ON  → previous edit = previous transient
--     (filtered by shared min-gap setting).
--   - Tab to Transient OFF → previous edit = previous item edge.
--
--   Time selection + razor zones on selected tracks shrink together.
--   No-op if no TS / previous edit would land on / before TS_s.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags : Editing, Selection
--
-- @changelog
--   0.2.0 [260509.1036] - First implementation. Mirrors Shrink To
--                          Next Edit; uses native 40318 (or transient
--                          walk via library).
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local EPS = 1e-4

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "Shrink Edit Selection To Previous Edit", 0)
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
r.SetEditCurPos(te, false, false)
r.Main_OnCommand(41229, 0)
r.Main_OnCommand(40421, 0)

if get_tab_toggle_state() then
  Tran.cursor_to_prev_transient(Tran.get_min_sec())
else
  r.Main_OnCommand(40318, 0)  -- Previous item edge
end

local new_te = r.GetCursorPosition()
r.Main_OnCommand(41239, 0)
r.SetEditCurPos(cursor_save, false, false)

if new_te < te - EPS and new_te > ts + EPS then
  r.Undo_BeginBlock()
  r.GetSet_LoopTimeRange(true, false, ts, new_te, false)

  for _, tr in ipairs(get_selected_tracks()) do
    local _, str = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if str and str ~= "" then
      local parts = {}
      for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
        local s = tonumber(s_str); local e = tonumber(e_str)
        if s and e then
          local ne = math.min(e, new_te)
          if ne > s + EPS then
            parts[#parts+1] = string.format("%.14f %.14f %s", s, ne, guid)
          end
        end
      end
      r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
        table.concat(parts, " "), true)
    end
  end
  r.Undo_EndBlock("Pro Tools: Shrink Edit Selection To Previous Edit", -1)
end
