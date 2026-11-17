--[[
@description hsuanice_PT_MatchSelection - Change Edit to Match Timeline / Timeline to Match Edit (PT2Reaper library)
@version 26.1118.0114
@author hsuanice
@noindex
@changelog
  - Release: Change Edit to Match Timeline / Change Timeline to Match Edit (tested in REAPER).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Shared code of the six "Change Edit to Match Timeline" / "Change Timeline to Match Edit"
  scripts. Loaded with dofile().

  Selections (as everywhere in PT2Reaper):
    Timeline Selection = loop points; no loop points: a position - the Time marker (marker 9999,
                         Link off), else the edit cursor
    Edit Selection     = razor areas on tracks (else the time selection); no range: a position
                         - the edit cursor
  part = nil (whole) | "start" | "end": only that edge is copied, the other edge stays. When
  the side that keeps its other edge has no range (only a position), the whole is copied.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local T = dofile(DIR .. 'hsuanice_PT_Transport.lua')
local MS = dofile(DIR .. 'hsuanice_PT_MouseSelect.lua')
local M = {}
local EPS = 1e-9

-- track-level razor areas off (envelope-lane areas kept), time selection off
local function clear_edit_range()
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, s = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false)
    if s and s ~= '' then
      local keep = {}
      for x, y, g in s:gmatch('(%S+)%s+(%S+)%s+"([^"]*)"') do
        if g ~= '' then keep[#keep + 1] = string.format('%s %s "%s"', x, y, g) end
      end
      r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', table.concat(keep, ' '), true)
    end
  end
  r.GetSet_LoopTimeRange2(0, true, false, 0, 0, false)
end

-- the Timeline position when there are no loop points
local function time_point() return T.time_pos() or r.GetCursorPosition() end

-- the new [s, e] from the source range and the target's own range (part = only one edge)
local function merge(src0, src1, own0, own1, part)
  if not part or not own0 then return src0, src1 end
  if part == 'start' then return src0, own1 end
  return own0, src1
end

-- Change Edit to Match Timeline
function M.edit_to_timeline(part)
  local ls, le = T.timeline_range()
  if not ls then ls = time_point(); le = ls end
  local es, ee = T.edit_range()
  local s, e = merge(ls, le, es, ee, part)
  if e < s + EPS then -- a position: the Edit position goes there, no Edit range
    clear_edit_range()
    r.SetEditCurPos2(0, s, false, false)
    return true
  end
  -- the Edit Selection's tracks: those with razor areas, else the selected tracks
  local sel, has = {}, false
  for i = 0, r.CountTracks(0) - 1 do
    local _, str = r.GetSetMediaTrackInfo_String(r.GetTrack(0, i), 'P_RAZOREDITS', '', false)
    if (str or ''):match('%S+%s+%S+%s+""') then sel[i], has = true, true end
  end
  if not has then
    for i = 0, r.CountTracks(0) - 1 do
      if r.IsTrackSelected(r.GetTrack(0, i)) then sel[i], has = true, true end
    end
  end
  if has then
    MS.apply(s, e, sel) -- razor areas on the Edit Selection's tracks; time selection mirrored
  else
    r.GetSet_LoopTimeRange2(0, true, false, s, e, false)
  end
  return true
end

-- Change Timeline to Match Edit
function M.timeline_to_edit(part)
  local es, ee = T.edit_range()
  if not es then es = r.GetCursorPosition(); ee = es end
  local ls, le = T.timeline_range()
  local s, e = merge(es, ee, ls, le, part)
  if e < s + EPS then -- a position: the Timeline position goes there, no loop points
    r.GetSet_LoopTimeRange2(0, true, true, 0, 0, false)
    if not T.linked() then T.set_time_pos(s) end
    return true
  end
  r.GetSet_LoopTimeRange2(0, true, true, s, e, false) -- (the Counters Panel removes the Time marker)
  if not T.linked() then T.clear_time_pos() end
  return true
end

-- the action scripts: one undo point each
function M.run(fn, part, title)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  fn(part)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock('Pro Tools: ' .. title, -1)
end

return M
