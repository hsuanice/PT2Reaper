--[[
@description hsuanice_Pro Tools Halve Edit Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Halve Edit Selection**
  (Cmd+Opt+Ctrl+Shift+L)

  Halves the length of the time selection and every razor zone,
  keeping the LEFT edge as the anchor (selection contracts from
  the right). No-op if neither time selection nor razor exists.

  - Tags : Editing, Selection
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local EPS = 1e-9

local function scale_selection(factor)
  local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if te > ts + EPS then
    local new_te = ts + factor * (te - ts)
    r.GetSet_LoopTimeRange(true, false, ts, new_te, false)
  end
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
        end
      end
      if #parts > 0 then
        r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
          table.concat(parts, " "), true)
      end
    end
  end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
scale_selection(0.5)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Halve Edit Selection", -1)
