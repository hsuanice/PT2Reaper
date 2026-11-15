--[[
@description hsuanice_Pro Tools Delete Selection
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  # hsuanice Pro Tools Keybindings for REAPER

  Wrapper replicating Pro Tools: **Delete Selection** (Delete key)

  PT's Delete is context-aware. This script mirrors that with PT-style
  partial removal that preserves fades on the surviving outer pieces.

  ## Mapping
  - Razor zones exist           → Split items at zone edges, remove
                                   inside pieces (per zone, per track).
                                   Outer pieces keep their fades.
  - Selected items + time sel   → Split selected items at TS edges,
                                   remove inside pieces. Outer pieces
                                   keep their fades.
  - Selected items only         → Remove items (40006).
  - Selected envelope points    → Delete envelope points (40333).
  - Automation items selected   → Delete automation items (42086).
  - Time selection exists       → Remove time selection (40635).
  - Razor at end                → Clear razor zones (always).

  - Mac shortcut (PT) : Delete
  - Tags              : Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local EPS = 1e-9

-- Fade line snapshot / shape restore (shape, curve, S-curve intensity).
-- Own copy of fade_line / restore_fade_shape from hsuanice_Hover.lua (hsuanice Library),
-- so the PT2Reaper scripts are self-contained.
-- The item chunk's FADEIN / FADEOUT line holds shape, length, curve and S-curve intensity.
-- Writing the fade fields through the API can reset the shape and curve to Linear, so the
-- line is read before an edge edit and its shape/curve tokens are put back afterwards.
local Hover = {}
local function item_head(it)
  local ok, chunk = r.GetItemStateChunk(it, "", false)
  if not ok or not chunk then return nil end
  local cut = chunk:find("\n<", 1, true) or #chunk  -- item-level lines come before any <TAKE / <SOURCE block
  return chunk, cut
end
function Hover.fade_line(it, key)
  local chunk, cut = item_head(it)
  if not chunk then return nil end
  return chunk:sub(1, cut):match("\n(" .. key .. " [^\r\n]*)")
end
-- Keep the new length tokens (2 and 3) and restore every other token from old_line
function Hover.restore_fade_shape(it, key, old_line)
  if not old_line then return end
  local chunk, cut = item_head(it)
  if not chunk then return end
  local head, rest = chunk:sub(1, cut), chunk:sub(cut + 1)
  local new_line = head:match("\n(" .. key .. " [^\r\n]*)")
  if not new_line or new_line == old_line then return end
  local old_t, new_t = {}, {}
  for t in old_line:gmatch("%S+") do old_t[#old_t + 1] = t end
  for t in new_line:gmatch("%S+") do new_t[#new_t + 1] = t end
  if #old_t ~= #new_t or #new_t < 4 then return end
  old_t[3], old_t[4] = new_t[3], new_t[4]  -- [1] is the key itself
  local merged = table.concat(old_t, " ")
  if merged == new_line then return end
  local new_head = head:gsub("\n" .. key .. " [^\r\n]*", function() return "\n" .. merged end, 1)
  r.SetItemStateChunk(it, new_head .. rest, false)
end

local function get_razor_zones()
  local zones = {}
  for ti = 0, r.CountTracks(0)-1 do
    local tr = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      local toks = {}
      for t in s:gmatch("%S+") do toks[#toks+1] = t end
      for i = 1, #toks-2, 3 do
        local rs   = tonumber(toks[i])
        local re   = tonumber(toks[i+1])
        local guid = toks[i+2]
        if rs and re and guid == '""' then
          zones[#zones+1] = {track=tr, s=rs, e=re}
        end
      end
    end
  end
  return zones
end

-- Set a piece's fade lengths, then put back the original shape / curve
-- (writing the length can reset the shape to Linear)
local function set_piece_fades(piece, fi, fo, fi_line, fo_line)
  r.SetMediaItemInfo_Value(piece, "D_FADEINLEN",  fi)
  r.SetMediaItemInfo_Value(piece, "D_FADEOUTLEN", fo)
  if Hover then
    if fi > EPS then Hover.restore_fade_shape(piece, "FADEIN",  fi_line) end
    if fo > EPS then Hover.restore_fade_shape(piece, "FADEOUT", fo_line) end
  end
end

-- Split items overlapping [s, e] and remove inside pieces. Outer pieces
-- keep their fades like a PT trim: a fade keeps its far end (fade-in end /
-- fade-out start) and is shortened only when the cut runs into it.
local function partial_remove(victims, s, e)
  for _, v in ipairs(victims) do
    local fi_orig = r.GetMediaItemInfo_Value(v.item, "D_FADEINLEN")  or 0
    local fo_orig = r.GetMediaItemInfo_Value(v.item, "D_FADEOUTLEN") or 0
    local fi_line = Hover and Hover.fade_line(v.item, "FADEIN")
    local fo_line = Hover and Hover.fade_line(v.item, "FADEOUT")

    local left_piece, right_piece
    local it = v.item

    if v.pos < s - EPS then
      it = r.SplitMediaItem(it, s)
      left_piece = v.item
    end
    if v.fin > e + EPS then
      right_piece = r.SplitMediaItem(it, e)
    end

    r.DeleteTrackMediaItem(r.GetMediaItemTrack(it), it)

    if left_piece then
      local left_len = s - v.pos
      if left_len > EPS then
        -- fade-out keeps its start; it survives only if it started before the cut
        local fo_remain = (fo_orig > 0) and math.max(0, s - (v.fin - fo_orig)) or 0
        set_piece_fades(left_piece, math.min(fi_orig, left_len),
          math.min(fo_remain, left_len), fi_line, fo_line)
      end
    end
    if right_piece then
      local right_len = v.fin - e
      if right_len > EPS then
        -- fade-in keeps its end; it survives only if it ended after the cut
        local fi_remain = (fi_orig > 0) and math.max(0, v.pos + fi_orig - e) or 0
        set_piece_fades(right_piece, math.min(fi_remain, right_len),
          math.min(fo_orig, right_len), fi_line, fo_line)
      end
    end
  end
end

r.Undo_BeginBlock()

local did_something = false

-- 1. Razor zones — partial remove items in each zone
local zones = get_razor_zones()
if #zones > 0 then
  for _, rz in ipairs(zones) do
    local victims = {}
    local n = r.CountTrackMediaItems(rz.track)
    for i = 0, n-1 do
      local it  = r.GetTrackMediaItem(rz.track, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < rz.e - EPS and fin > rz.s + EPS then
        victims[#victims+1] = {item=it, pos=pos, fin=fin}
      end
    end
    if #victims > 0 then
      partial_remove(victims, rz.s, rz.e)
      did_something = true
    end
  end
end

-- 2. Selected items (with optional TS for partial removal)
if not did_something and r.CountSelectedMediaItems(0) > 0 then
  local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_e > ts_s + EPS then
    local victims = {}
    for i = 0, r.CountSelectedMediaItems(0)-1 do
      local it  = r.GetSelectedMediaItem(0, i)
      local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
      if pos < ts_e - EPS and fin > ts_s + EPS then
        victims[#victims+1] = {item=it, pos=pos, fin=fin}
      end
    end
    if #victims > 0 then
      partial_remove(victims, ts_s, ts_e)
      did_something = true
    else
      r.Main_OnCommand(40006, 0)
      did_something = true
    end
  else
    r.Main_OnCommand(40006, 0)
    did_something = true
  end
end

-- 3. Selected envelope points
if not did_something then
  for ti = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, ti)
    for ei = 0, r.CountTrackEnvelopes(track) - 1 do
      local env = r.GetTrackEnvelope(track, ei)
      for pi = 0, r.CountEnvelopePoints(env) - 1 do
        local _, _, _, _, _, selected = r.GetEnvelopePoint(env, pi)
        if selected then
          r.Main_OnCommand(40333, 0)
          did_something = true
          break
        end
      end
      if did_something then break end
    end
    if did_something then break end
  end
end

-- 4. Automation items selected
if not did_something then
  for ti = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, ti)
    for ei = 0, r.CountTrackEnvelopes(track) - 1 do
      local env = r.GetTrackEnvelope(track, ei)
      for ai = 0, r.CountAutomationItems(env) - 1 do
        local sel = r.GetSetAutomationItemInfo(env, ai, "D_UISEL", 0, false)
        if sel > 0.5 then
          r.Main_OnCommand(42086, 0)
          did_something = true
          break
        end
      end
      if did_something then break end
    end
    if did_something then break end
  end
end

-- 5. Time selection fallback
if not did_something then
  local ts, te = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if te > ts then
    r.Main_OnCommand(40635, 0)
  end
end

-- Always clear razor edit zones at the end.
for ti = 0, r.CountTracks(0) - 1 do
  local track = r.GetTrack(0, ti)
  local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if s and s ~= "" then
    r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
  end
end

-- Always clear item selection at the end (matches PT).
r.Main_OnCommand(40289, 0)  -- Item: Unselect (clear selection of) all items

-- Always clear time selection at the end too.
r.GetSet_LoopTimeRange(true, false, 0, 0, false)

r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Delete Selection", -1)
