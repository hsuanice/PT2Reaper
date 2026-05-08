-- @description hsuanice_Pro Tools Separate Clip At Selection
-- @version 0.8.1 [260508.1259]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Separate Clip At Selection** (Cmd+E)
--
--   ## Modes
--   - **Time selection exists** → split selected items at TS_s and TS_e.
--     After: TS / razor preserved; item selection keeps inside-TS pieces
--     plus crossfade-resolved survivors.
--   - **No time selection**     → split selected items at the edit cursor.
--     After: razor / TS / item selection cleared.
--
--   ## Boundary suppression (no-separate cases)
--   - TS_s OR TS_e at a fade boundary (fade-in out point or fade-out in
--     point) on a selected item → that split point is skipped on that item.
--   - TS_s = cf_start AND TS_e = cf_end (TS exactly equals crossfade) →
--     entire pair untouched.
--
--   ## Crossfade-in-TS rules (TS overlaps a crossfade pair)
--   - TS_s = cf_start, TS_e < cf_end → trim BOTH Left.fin and Right.pos to
--     TS_e (fully breaks the crossfade); select Left only (the side whose
--     range overlaps the TS).
--   - TS_s > cf_start, TS_e = cf_end → trim BOTH Left.fin and Right.pos to
--     TS_s (fully breaks the crossfade); select Right only.
--   - TS strictly inside crossfade   → fall through to plain split + crossfade
--     trim at TS_s; select inside-TS pieces only.
--
--   ## Crossfade-at-cursor rule
--   Cursor inside an overlap region trims BOTH items to cursor.
--
--   ## Plain split fade rule
--   - split inside fade-in  → left.fade-in cleared, right gets remainder.
--   - split inside fade-out → right.fade-out cleared, left gets portion.
--   - Tags: Editing, Clips
-- @changelog
--   0.8.1 [260508.1259] - Boundary cases: select only the surviving item that
--                          overlaps the TS (Left for s_at_start, Right for
--                          e_at_end). The other survivor is left untouched
--                          but unselected.
--   0.8.0 [260507.1500] - TS-in-crossfade boundary cases now trim BOTH items
--                          to fully break the crossfade. TS_s = cf_start:
--                          trim Left.fin AND Right.pos to ts_e. TS_e = cf_end:
--                          trim Left.fin AND Right.pos to ts_s. Both
--                          survivors selected. (Previously only one side was
--                          trimmed, leaving an unintended residual overlap.)
--   0.7.0 [260507.1430] - Don't delete items in TS-in-crossfade cases (fixes
--                          regression from 0.6.0 where outer pieces were
--                          erased entirely). TS_s = cf_start case: trim Left
--                          to ts_e and leave Right alone (manual selection
--                          mark). TS_e = cf_end case: mirror. TS strictly
--                          inside: v0.5.0 logic + selection filter.
--                          Boundary-suppression: split point at fade-in/out
--                          boundaries no-ops on that item.
--   0.6.0 [260507.1330] - TS-in-crossfade resolves to ONE surviving item with
--                          deletion of the other (USER REJECTED this).
--   0.5.0 [260507.1230] - Crossfade-aware (cursor + TS).
--   0.4.0 [260507.1130] - Asymmetric fade rule + per-mode selection handling.
--   0.3.0 [260507.1100] - First custom version.
--   0.2.0 [260506.2030] - Map to native 40196.
--   0.1.0 [260415.1250] - Stub placeholder created.

local r = reaper
local EPS = 1e-9

-- ---- Plain split with asymmetric fade rule -------------------------------
local function split_with_fades(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_fin = item_pos + item_len
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return nil end

  local fi_orig = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")  or 0
  local fo_orig = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN") or 0

  local right = r.SplitMediaItem(item, pos)
  if not right then return nil end

  local left_len  = pos - item_pos
  local right_len = item_fin - pos

  local fi_end_abs = item_pos + fi_orig
  if (pos > item_pos + EPS) and (pos < fi_end_abs - EPS) then
    r.SetMediaItemInfo_Value(item,  "D_FADEINLEN", 0)
    r.SetMediaItemInfo_Value(right, "D_FADEINLEN", math.min(fi_end_abs - pos, right_len))
  else
    r.SetMediaItemInfo_Value(item,  "D_FADEINLEN", math.min(fi_orig, left_len))
    r.SetMediaItemInfo_Value(right, "D_FADEINLEN", 0)
  end

  local fo_start_abs = item_fin - fo_orig
  if (pos > fo_start_abs + EPS) and (pos < item_fin - EPS) then
    r.SetMediaItemInfo_Value(item,  "D_FADEOUTLEN", math.min(pos - fo_start_abs, left_len))
    r.SetMediaItemInfo_Value(right, "D_FADEOUTLEN", 0)
  else
    r.SetMediaItemInfo_Value(item,  "D_FADEOUTLEN", 0)
    r.SetMediaItemInfo_Value(right, "D_FADEOUTLEN", math.min(fo_orig, right_len))
  end

  return right
end

-- Boundary-suppression check: should we skip splitting `item` at `pos`
-- because pos is exactly at a fade-in/fade-out boundary?
local function pos_at_fade_boundary(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_fin = item_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local fi = math.max(
    r.GetMediaItemInfo_Value(item, "D_FADEINLEN")      or 0,
    r.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO") or 0)
  local fo = math.max(
    r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")      or 0,
    r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO") or 0)
  if fi > 0 and math.abs(pos - (item_pos + fi)) < EPS then return true end
  if fo > 0 and math.abs(pos - (item_fin - fo)) < EPS then return true end
  return false
end

-- ---- Auto-fade-aware trim helpers ----------------------------------------
local function trim_left_to(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_fin = item_pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return end
  local fo_eff = math.max(
    r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")      or 0,
    r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO") or 0)
  local fo_start_abs = item_fin - fo_eff
  r.SetMediaItemInfo_Value(item, "D_LENGTH", pos - item_pos)
  local new_fo = (pos > fo_start_abs + EPS) and (pos - fo_start_abs) or fo_eff
  new_fo = math.min(new_fo, pos - item_pos)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN",      new_fo)
  r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
end

local function trim_right_to(item, pos)
  local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_fin = item_pos + item_len
  if pos <= item_pos + EPS or pos >= item_fin - EPS then return end
  local fi_eff = math.max(
    r.GetMediaItemInfo_Value(item, "D_FADEINLEN")      or 0,
    r.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO") or 0)
  local fi_end_abs = item_pos + fi_eff
  local delta = pos - item_pos
  r.SetMediaItemInfo_Value(item, "D_POSITION", pos)
  r.SetMediaItemInfo_Value(item, "D_LENGTH",   item_len - delta)
  for ti = 0, r.CountTakes(item) - 1 do
    local t = r.GetTake(item, ti)
    if t and not r.TakeIsMIDI(t) then
      local o  = r.GetMediaItemTakeInfo_Value(t, "D_STARTOFFS") or 0
      local pr = r.GetMediaItemTakeInfo_Value(t, "D_PLAYRATE")  or 1.0
      if pr <= 0 then pr = 1.0 end
      r.SetMediaItemTakeInfo_Value(t, "D_STARTOFFS", o + delta * pr)
    end
  end
  local new_fi = (pos < fi_end_abs - EPS) and (fi_end_abs - pos) or 0
  new_fi = math.min(new_fi, item_len - delta)
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN",      new_fi)
  r.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
end

-- ---- Crossfade pair detection (overlap-based, robust to boundary cases) --
local function find_crossfade_pairs(items)
  local pairs_out, seen = {}, {}
  for i = 1, #items do
    local a = items[i]
    if not seen[a] then
      local a_pos = r.GetMediaItemInfo_Value(a, "D_POSITION")
      local a_fin = a_pos + r.GetMediaItemInfo_Value(a, "D_LENGTH")
      local a_track = r.GetMediaItemTrack(a)
      for j = i+1, #items do
        local b = items[j]
        if not seen[b] and r.GetMediaItemTrack(b) == a_track then
          local b_pos = r.GetMediaItemInfo_Value(b, "D_POSITION")
          local b_fin = b_pos + r.GetMediaItemInfo_Value(b, "D_LENGTH")
          local ov_s = math.max(a_pos, b_pos)
          local ov_e = math.min(a_fin, b_fin)
          if ov_e > ov_s + EPS then
            local L, R
            if a_pos < b_pos then L, R = a, b else L, R = b, a end
            pairs_out[#pairs_out+1] = { left=L, right=R, cf_start=ov_s, cf_end=ov_e }
            seen[a] = true; seen[b] = true
            break
          end
        end
      end
    end
  end
  return pairs_out
end

-- ---- Mode + setup --------------------------------------------------------

local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
local has_ts     = ts_e > ts_s + EPS
local cursor     = r.GetCursorPosition()
local positions  = has_ts and {ts_s, ts_e} or {cursor}

local sel_items = {}
for i = 0, r.CountSelectedMediaItems(0)-1 do
  sel_items[#sel_items+1] = r.GetSelectedMediaItem(0, i)
end
if #sel_items == 0 then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

-- ---- Crossfade pair handling ---------------------------------------------

local handled_items   = {}  -- items removed from the plain-split pool
local manual_select   = {}  -- items that should be selected at the end
                            -- regardless of inside-TS filter

local pairs_in_sel = find_crossfade_pairs(sel_items)

for _, p in ipairs(pairs_in_sel) do
  local cf_s, cf_e = p.cf_start, p.cf_end

  if has_ts and ts_s < cf_e - EPS and ts_e > cf_s + EPS then
    local s_at_start = math.abs(ts_s - cf_s) < EPS
    local e_at_end   = math.abs(ts_e - cf_e) < EPS

    if s_at_start and e_at_end then
      handled_items[p.left]  = true
      handled_items[p.right] = true
      manual_select[p.left]  = true
      manual_select[p.right] = true
    elseif s_at_start then
      trim_left_to(p.left,   ts_e)
      trim_right_to(p.right, ts_e)
      handled_items[p.left]  = true
      handled_items[p.right] = true
      manual_select[p.left]  = true
    elseif e_at_end then
      trim_left_to(p.left,   ts_s)
      trim_right_to(p.right, ts_s)
      handled_items[p.left]  = true
      handled_items[p.right] = true
      manual_select[p.right] = true
    else
      -- TS strictly inside crossfade → fall through to v0.5.0 logic at ts_s
      trim_left_to(p.left,  ts_s)
      trim_right_to(p.right, ts_s)
      -- right still in pool; further plain split at ts_e will produce the
      -- inside-TS piece that gets selected via the inside-TS filter below.
    end
  elseif (not has_ts) and cursor > cf_s + EPS and cursor < cf_e - EPS then
    handled_items[p.left]  = true
    handled_items[p.right] = true
    trim_left_to(p.left,  cursor)
    trim_right_to(p.right, cursor)
  end
end

-- ---- Plain split on remaining items --------------------------------------

local pool = {}
for _, it in ipairs(sel_items) do
  if not handled_items[it] then pool[#pool+1] = it end
end

local all_pieces = {}
for _, it in ipairs(pool) do all_pieces[#all_pieces+1] = it end

for _, sp in ipairs(positions) do
  local snapshot = {}
  for _, it in ipairs(all_pieces) do snapshot[#snapshot+1] = it end
  for _, it in ipairs(snapshot) do
    if not pos_at_fade_boundary(it, sp) then
      local new_right = split_with_fades(it, sp)
      if new_right then all_pieces[#all_pieces+1] = new_right end
    end
  end
end

-- ---- Selection handling --------------------------------------------------

r.Main_OnCommand(40289, 0)  -- unselect all

if has_ts then
  -- Inside-TS pieces from plain-split pool
  for _, it in ipairs(all_pieces) do
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos >= ts_s - EPS and fin <= ts_e + EPS then
      r.SetMediaItemSelected(it, true)
    end
  end
  -- Manually-marked items (crossfade-pair survivors) — select regardless
  for it in pairs(manual_select) do
    if r.ValidatePtr(it, "MediaItem*") then
      r.SetMediaItemSelected(it, true)
    end
  end
else
  for ti = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, ti)
    local _, s = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if s and s ~= "" then
      r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
    end
  end
  r.GetSet_LoopTimeRange(true, false, 0, 0, false)
end

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Separate Clip At Selection", -1)
