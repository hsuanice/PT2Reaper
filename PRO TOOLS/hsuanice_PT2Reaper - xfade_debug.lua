-- hsuanice_PT2Reaper - xfade_debug.lua
-- Debug tool: detect crossfades on selected items and dump state to console
-- Run this BEFORE nudging to confirm crossfade detection is working.

local r = reaper
local EPS = 1e-4

local function fmt(n) return string.format("%.5f", n) end

-- Same logic as NudgeEdge.find_left_xfade
local function find_left_xfade(track, item)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local item_e = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local best, best_end = nil, -math.huge
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local other = r.GetTrackMediaItem(track, i)
    if other ~= item then
      local op = r.GetMediaItemInfo_Value(other, 'D_POSITION')
      local oe = op + r.GetMediaItemInfo_Value(other, 'D_LENGTH')
      if op < pos - EPS and oe > pos + EPS and oe < item_e - EPS then
        if oe > best_end then best = other; best_end = oe end
      end
    end
  end
  return best
end

-- Same logic as NudgeEdge.find_right_xfade
local function find_right_xfade(track, item)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local item_e = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local best, best_pos = nil, math.huge
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local other = r.GetTrackMediaItem(track, i)
    if other ~= item then
      local op = r.GetMediaItemInfo_Value(other, 'D_POSITION')
      local oe = op + r.GetMediaItemInfo_Value(other, 'D_LENGTH')
      if op > pos + EPS and op < item_e - EPS and oe > item_e - EPS then
        if op < best_pos then best = other; best_pos = op end
      end
    end
  end
  return best
end

local function item_name(item)
  local take = r.GetActiveTake(item)
  if take then
    local _, name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
    if name and name ~= '' then return name end
  end
  return '(no name)'
end

local function dump_item(label, item)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len    = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local fi     = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
  local fo     = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
  local item_e = pos + len
  reaper.ShowConsoleMsg(string.format(
    "  %s: \"%s\"\n    pos=%s  end=%s  len=%s\n    fi_len=%s  fo_len=%s\n    fi_end=%s  fo_start=%s\n",
    label, item_name(item),
    fmt(pos), fmt(item_e), fmt(len),
    fmt(fi), fmt(fo),
    fmt(pos + fi), fmt(item_e - fo)
  ))
end

-- -----------------------------------------------------------------------
-- Main
-- -----------------------------------------------------------------------

local n = r.CountSelectedMediaItems(0)
if n == 0 then
  r.ShowConsoleMsg("No items selected.\n")
  return
end

r.ShowConsoleMsg("=== XFADE DEBUG ===\n")

for i = 0, n - 1 do
  local item  = r.GetSelectedMediaItem(0, i)
  local track = r.GetMediaItemTrack(item)
  local _, tname = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

  r.ShowConsoleMsg(string.format("\n[Item %d] track: \"%s\"\n", i + 1, tname or ''))
  dump_item("THIS", item)

  local lxf = find_left_xfade(track, item)
  local rxf = find_right_xfade(track, item)

  if lxf then
    local lxf_pos = r.GetMediaItemInfo_Value(lxf, 'D_POSITION')
    local lxf_len = r.GetMediaItemInfo_Value(lxf, 'D_LENGTH')
    local lxf_e   = lxf_pos + lxf_len
    local overlap  = lxf_e - r.GetMediaItemInfo_Value(item, 'D_POSITION')
    r.ShowConsoleMsg(string.format("  LEFT XFADE detected (overlap=%.5f):\n", overlap))
    dump_item("  LEFT", lxf)
  else
    r.ShowConsoleMsg("  LEFT XFADE: none\n")
  end

  if rxf then
    local item_e  = r.GetMediaItemInfo_Value(item, 'D_POSITION') + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local rxf_pos = r.GetMediaItemInfo_Value(rxf, 'D_POSITION')
    local overlap  = item_e - rxf_pos
    r.ShowConsoleMsg(string.format("  RIGHT XFADE detected (overlap=%.5f):\n", overlap))
    dump_item("  RIGHT", rxf)
  else
    r.ShowConsoleMsg("  RIGHT XFADE: none\n")
  end

  -- Also check razor on this track
  local _, razor_str = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
  if razor_str and razor_str ~= '' then
    local rs, re = razor_str:match('(%S+)%s+(%S+)%s+""')
    if rs and re then
      r.ShowConsoleMsg(string.format("  RAZOR: %s → %s\n", fmt(tonumber(rs)), fmt(tonumber(re))))
    end
  else
    r.ShowConsoleMsg("  RAZOR: none\n")
  end
end

r.ShowConsoleMsg("\n=== END ===\n")
