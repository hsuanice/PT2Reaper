-- @description hsuanice_Pro Tools Clear
-- @version 0.4.2 [260506.2010]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   # hsuanice Pro Tools Keybindings for REAPER
--
--   Wrapper replicating Pro Tools: **Clear** (Cmd+B)
--
--   PT's Clear is context-aware — it removes whatever is currently
--   "selected": items, envelope points, automation items, or the time
--   selection itself. This script mirrors that, with PT-style partial
--   removal that preserves fades on the surviving outer pieces.
--
--   ## Mapping
--   - Razor zones exist           → Split items at zone edges, remove
--                                    inside pieces (per zone, per track).
--                                    Outer pieces keep their fades.
--   - Selected items + time sel   → Split selected items at TS edges,
--                                    remove inside pieces. Outer pieces
--                                    keep their fades.
--   - Selected items only         → Remove items (40006).
--   - Selected envelope points    → Delete envelope points (40333).
--   - Automation items selected   → Delete automation items (42086).
--   - Time selection exists       → Remove time selection (40635).
--   - Razor at end                → Clear razor zones (always, regardless
--                                    of which branch ran).
--
--   - Mac shortcut (PT) : Cmd+B
--   - Tags              : Editing
--
-- @changelog
--   0.4.2 [260506.2010]
--     - Always clear time selection at end too (alongside razor + item
--       selection). After Clear runs, all selection-like state is gone.
--   0.4.1 [260506.1945]
--     - Fade preservation on outer pieces: left piece keeps its original
--       fade-in (truncated to its new length), right piece gets a fade-in
--       equal to whatever portion of the original fade-in extended past
--       the cut, fade-out kept (truncated). Previously REAPER's split
--       cleared fades on the new edges so a cut through a fade region
--       lost the fade entirely.
--     - Always clear item selection at end (matches PT — after Clear, no
--       items remain selected).
--   0.4.0 [260506.1920]
--     - PT-style partial removal: when items + time selection (or razor)
--       intersect, split items at the boundaries and remove only the
--       inside pieces. Surviving outer pieces keep their fade-in /
--       fade-out (REAPER's SplitMediaItem preserves boundary fades),
--       matching PT behavior. Previously 40006 removed whole items so
--       fades disappeared.
--   0.3.1 [260506.1850]
--     - Always clear razor edit zones at the end.
--   0.3.0 [260506.1830]
--     - Context-aware clear (mirrors Delete Selection priority ladder).
--   0.2.0 [260506.1810]
--     - Thin wrapper over native 40006.
--   0.1.0 [260413.1324]
--     - Stub placeholder created.

local r = reaper
local EPS = 1e-9

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

-- Split items overlapping [s, e] and remove the inside pieces. Outer pieces
-- get their fades restored manually because REAPER's SplitMediaItem doesn't
-- preserve fade-in / fade-out across the new edges:
--   * LEFT outer piece (item.pos..s)  → fade-in kept (truncated to piece
--     length), fade-out cleared.
--   * RIGHT outer piece (e..item.fin) → fade-in length = remainder of the
--     original fade-in past `e` (so the visual fade survives if the cut
--     went through the fade region). fade-out kept (truncated).
local function partial_remove(victims, s, e)
  for _, v in ipairs(victims) do
    local fi_orig = r.GetMediaItemInfo_Value(v.item, "D_FADEINLEN")  or 0
    local fo_orig = r.GetMediaItemInfo_Value(v.item, "D_FADEOUTLEN") or 0

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
        r.SetMediaItemInfo_Value(left_piece, "D_FADEINLEN",
          math.min(fi_orig, left_len))
        r.SetMediaItemInfo_Value(left_piece, "D_FADEOUTLEN", 0)
      end
    end
    if right_piece then
      local right_len = v.fin - e
      if right_len > EPS then
        local fi_remain = math.max(0, v.pos + fi_orig - e)
        r.SetMediaItemInfo_Value(right_piece, "D_FADEINLEN",
          math.min(fi_remain, right_len))
        r.SetMediaItemInfo_Value(right_piece, "D_FADEOUTLEN",
          math.min(fo_orig, right_len))
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
    -- Items + TS: PT-style partial removal — split at TS edges, remove
    -- the inside pieces. Outer pieces keep their fades.
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
      -- Selected items don't overlap TS — remove whole.
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

-- Always clear item selection at the end (matches PT — after Clear,
-- nothing should remain selected).
r.Main_OnCommand(40289, 0)  -- Item: Unselect (clear selection of) all items

-- Always clear time selection at the end too.
r.GetSet_LoopTimeRange(true, false, 0, 0, false)

r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Clear", -1)
