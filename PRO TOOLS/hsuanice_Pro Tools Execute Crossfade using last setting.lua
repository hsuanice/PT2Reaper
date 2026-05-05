-- @description hsuanice_Pro Tools Execute Crossfade using last setting
-- @version 0.4.1 [260505.1945]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Execute Crossfade using last setting**
--   (Cmd+Ctrl+F / Ctrl+F). Re-runs Create Fades with the last shape +
--   length the user picked, without showing the GUI.
--
--   **Selection-aware (same as Create Fades):**
--     - Razor / time selection / item selection determines which type of
--       fade applies per item (fade-in / fade-out / crossfade)
--     - Single-category shape-only mode: length comes from the selection
--       (per-item for fade-in/out; selection length for crossfade)
--     - Mixed-type batch mode: length comes from stored ms / frame value
--
--   **Stored settings** (set every time Create Fades' OK is clicked, in
--   ExtState section "hsuanice_PT2Reaper_CreateFades"):
--     - fadein_shape / fadeout_shape / xfade_shape (1..7)
--     - fadein_ms / fadeout_ms / xfade_ms (number, in saved unit)
--     - length_unit ("ms" or "frame")
--
--   Razor, time selection, and item selection are preserved after apply.
--   - Tags: Editing, Fades
-- @changelog
--   0.4.1 [260505.1945] - Position the xfade exactly at the selection (not
--                          just match its length). Matches PT behavior:
--                          when the razor/TS doesn't sit on the existing
--                          midpoint, the recreated crossfade follows the
--                          selection bounds and the midpoint changes
--                          accordingly. Library v0.2.x exposes sel_start /
--                          sel_end via det for this; both touching and
--                          already-overlapping pair paths use it.
--   0.4.0 [260505.1930] - Rewrite to use F.detect_create_targets() (the
--                          shared Create-Fades-style detection). Now correctly
--                          recalls per-type shape AND length based on selection
--                          geometry — razor at item start applies fade-in only,
--                          razor on xfade region applies xfade only, etc.
--                          Crossfade length now comes from the selection in
--                          shape-only mode (matches Create Fades behavior),
--                          fall back to stored ms/frame in batch mode.
--   0.3.0 [260505.1815] - Honor the length_unit ExtState key.
--   0.2.0 [260505.1608] - Real implementation; reads ExtState.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local F = dofile(_dir .. '../Library/hsuanice_PT_Fades.lua')
if not F then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Fades.lua",
    "Execute Crossfade Last Setting", 0)
  return
end

local EXT_SEC = "hsuanice_PT2Reaper_CreateFades"

local function read_shape(key, fallback)
  local v = tonumber(r.GetExtState(EXT_SEC, key))
  if v then return F.clamp_shape(math.floor(v)) end
  return fallback
end
local function read_value(key, fallback)
  local v = tonumber(r.GetExtState(EXT_SEC, key))
  return (v and v > 0) and math.floor(v) or fallback
end

local DEFAULT_SHAPE = 1
local DEFAULT_MS    = 10

-- Build S table from ExtState (same shape Create Fades' apply expects).
local S = {
  fadein_shape  = read_shape("fadein_shape",  DEFAULT_SHAPE),
  fadeout_shape = read_shape("fadeout_shape", DEFAULT_SHAPE),
  xfade_shape   = read_shape("xfade_shape",   DEFAULT_SHAPE),
  fadein_ms     = read_value("fadein_ms",     DEFAULT_MS),
  fadeout_ms    = read_value("fadeout_ms",    DEFAULT_MS),
  xfade_ms      = read_value("xfade_ms",      DEFAULT_MS),
  length_unit   = (r.GetExtState(EXT_SEC, "length_unit") == "frame") and "frame" or "ms",
}

local function to_seconds(v)
  if not v then return nil end
  if S.length_unit == "frame" then
    local fr = r.TimeMap_curFrameRate(0) or 24
    if fr <= 0 then fr = 24 end
    return v / fr
  end
  return v / 1000.0
end

-- Selection-aware detection (same as Create Fades).
local det = F.detect_create_targets()
if #det.types == 0 then return end

local EPS = F.EPS

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

-- Snapshot razor edits (Create Fades does the same).
local razor_snap = F.snapshot_razors()

local function sel_only(item)
  r.Main_OnCommand(40289, 0)
  r.SetMediaItemSelected(item, true)
end

-- Apply per detected fade-in item: use selection-derived len when use_ms=false,
-- else use stored ms/frame.
for _, fi in ipairs(det.fadein_items) do
  local item = fi.item.item
  local len = fi.use_ms and to_seconds(S.fadein_ms) or fi.len
  sel_only(item)
  r.Main_OnCommand(F.FADEIN_CMDS[S.fadein_shape], 0)
  if len and len > 0 then
    r.SetMediaItemInfo_Value(item, "D_FADEINLEN", len)
  end
end

for _, fo in ipairs(det.fadeout_items) do
  local item = fo.item.item
  local len = fo.use_ms and to_seconds(S.fadeout_ms) or fo.len
  sel_only(item)
  r.Main_OnCommand(F.FADEOUT_CMDS[S.fadeout_shape], 0)
  if len and len > 0 then
    r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", len)
  end
end

-- Crossfade pairs: same length-resolution as Create Fades' apply.
for _, pair in ipairs(det.xfade_pairs) do
  local left, right = pair.left.item, pair.right.item

  local xlen
  if det.show_length and S.xfade_ms then
    xlen = to_seconds(S.xfade_ms)
  elseif det.sel_xlen and det.sel_xlen > EPS then
    xlen = det.sel_xlen
  elseif pair.overlap > EPS then
    xlen = pair.overlap
  else
    local existing = r.GetMediaItemInfo_Value(left, "D_FADEOUTLEN")
    xlen = existing > EPS and existing or 0.010
  end

  local current_overlap = pair.overlap
  local needs_resize = math.abs(xlen - current_overlap) > EPS

  -- Geometry adjustment. If we have explicit selection bounds (det.sel_start /
  -- det.sel_end from a razor/TS in single-category xfade-only mode), POSITION
  -- the xfade to MATCH the selection exactly — left.fin = sel_end, right.pos =
  -- sel_start. Otherwise fall back to the symmetric center-around-old-boundary
  -- behavior. This avoids offsetting the xfade by half a frame when the user's
  -- razor isn't centered on the original touching point.
  if (pair.touching or needs_resize) and det.sel_start and det.sel_end then
    local rp = r.GetMediaItemInfo_Value(right, "D_POSITION")
    local lp = r.GetMediaItemInfo_Value(left,  "D_POSITION")
    local rt = r.GetActiveTake(right)
    local ro = rt and r.GetMediaItemTakeInfo_Value(rt, "D_STARTOFFS") or 0
    local pr = rt and r.GetMediaItemTakeInfo_Value(rt, "D_PLAYRATE")  or 1.0
    if pr <= 0 then pr = 1.0 end
    local rfin = rp + r.GetMediaItemInfo_Value(right, "D_LENGTH")

    r.SetMediaItemInfo_Value(left,  "D_LENGTH",   det.sel_end - lp)
    r.SetMediaItemInfo_Value(right, "D_POSITION", det.sel_start)
    r.SetMediaItemInfo_Value(right, "D_LENGTH",   rfin - det.sel_start)
    if rt then
      r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS",
        math.max(0, ro + (det.sel_start - rp) * pr))
    end
  elseif pair.touching then
    local half = xlen * 0.5
    local ll = r.GetMediaItemInfo_Value(left,  "D_LENGTH")
    local rp = r.GetMediaItemInfo_Value(right, "D_POSITION")
    local rl = r.GetMediaItemInfo_Value(right, "D_LENGTH")
    local rt = r.GetActiveTake(right)
    local ro = rt and r.GetMediaItemTakeInfo_Value(rt, "D_STARTOFFS") or 0
    r.SetMediaItemInfo_Value(left,  "D_LENGTH",   ll + half)
    r.SetMediaItemInfo_Value(right, "D_POSITION", rp - half)
    r.SetMediaItemInfo_Value(right, "D_LENGTH",   rl + half)
    if rt then r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS", math.max(0, ro - half)) end
  elseif needs_resize then
    local diff = xlen - current_overlap
    local half = diff * 0.5
    local ll = r.GetMediaItemInfo_Value(left,  "D_LENGTH")
    local rp = r.GetMediaItemInfo_Value(right, "D_POSITION")
    local rl = r.GetMediaItemInfo_Value(right, "D_LENGTH")
    local rt = r.GetActiveTake(right)
    local ro = rt and r.GetMediaItemTakeInfo_Value(rt, "D_STARTOFFS") or 0
    r.SetMediaItemInfo_Value(left,  "D_LENGTH",   ll + half)
    r.SetMediaItemInfo_Value(right, "D_POSITION", rp - half)
    r.SetMediaItemInfo_Value(right, "D_LENGTH",   rl + half)
    if rt then r.SetMediaItemTakeInfo_Value(rt, "D_STARTOFFS", math.max(0, ro - half)) end
  end

  -- Set auto-fade lengths so the visible xfade has the right length.
  r.SetMediaItemInfo_Value(left,  "D_FADEOUTLEN_AUTO", xlen)
  r.SetMediaItemInfo_Value(right, "D_FADEINLEN_AUTO",  xlen)
  -- Apply shape via NEW chunk lines.
  F.apply_xfade_shape(left, right, S.xfade_shape)
end

-- Restore selection + razor edits.
r.Main_OnCommand(40289, 0)
for _, it in ipairs(det.items) do
  r.SetMediaItemSelected(it.item, true)
end
F.restore_razors(razor_snap)

r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Execute Crossfade using last setting", -1)
