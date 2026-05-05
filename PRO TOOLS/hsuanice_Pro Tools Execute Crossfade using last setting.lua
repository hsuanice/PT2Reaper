-- @description hsuanice_Pro Tools Execute Crossfade using last setting
-- @version 0.3.0 [260505.1815]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Execute Crossfade using last setting**
--   (Cmd+Ctrl+F / Ctrl+F). Re-applies the last fade settings used by
--   Create Fades (shape + ms length per fade type) to the current
--   selection without showing the GUI.
--
--   Reads from ExtState section "hsuanice_PT2Reaper_CreateFades" — set
--   by the GUI of "hsuanice_Pro Tools Create Fades.lua" each time you
--   click OK. If the user has never run Create Fades before, defaults
--   are applied (Linear shape, 10ms length).
--
--   **Scope priority: Razor > Time selection > Item selection** (same as
--   Apply Next/Previous Fade Shape). Crossfade requires both items in
--   the active set; otherwise just the active side's manual fade-in or
--   fade-out is set.
--
--   Razor, time selection, and item selection are preserved after apply.
--   - Tags: Editing, Fades
-- @changelog
--   0.3.0 [260505.1815] - Honor the length_unit ExtState key set by Create
--                          Fades v0.7.0+. When the saved unit is "frame",
--                          values are interpreted as frames (converted via
--                          TimeMap_curFrameRate) instead of milliseconds.
--   0.2.0 [260505.1608] - Real implementation. Reads Create Fades' ExtState
--                          (xfade_shape, xfade_ms, fadein_shape, fadein_ms,
--                          fadeout_shape, fadeout_ms) and applies to current
--                          selection via Library/hsuanice_PT_Fades.lua.
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

local DEFAULT_SHAPE = 1   -- Linear
local DEFAULT_MS    = 10
local length_unit   = (r.GetExtState(EXT_SEC, "length_unit") == "frame") and "frame" or "ms"
local fadein_shape  = read_shape("fadein_shape",  DEFAULT_SHAPE)
local fadeout_shape = read_shape("fadeout_shape", DEFAULT_SHAPE)
local xfade_shape   = read_shape("xfade_shape",   DEFAULT_SHAPE)
local fadein_val    = read_value("fadein_ms",     DEFAULT_MS)
local fadeout_val   = read_value("fadeout_ms",    DEFAULT_MS)
local xfade_val     = read_value("xfade_ms",      DEFAULT_MS)

-- Convert a typed length value to seconds based on the saved unit.
local function to_seconds(v)
  if length_unit == "frame" then
    local fr = r.TimeMap_curFrameRate(0) or 24
    if fr <= 0 then fr = 24 end
    return v / fr
  end
  return v / 1000.0
end
local fadein_sec  = to_seconds(fadein_val)
local fadeout_sec = to_seconds(fadeout_val)
local xfade_sec   = to_seconds(xfade_val)

local t = F.gather_fade_targets()
if #t.xfade_pairs == 0 and #t.fadein_items == 0 and #t.fadeout_items == 0 then
  return
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
F.with_preserved_state(function()
  -- Crossfade pairs: write shape via NEW chunk lines + set auto-fade lengths
  -- so the visible crossfade has the chosen length. (Item geometry is NOT
  -- modified — this script only sets shapes/lengths on existing relationships.
  -- Use Create Fades to extend touching items into a real crossfade first.)
  for _, p in ipairs(t.xfade_pairs) do
    -- Only set lengths if the pair already has overlap (auto-fade exists).
    -- For touching pairs with no overlap, the user should run Create Fades first.
    if p.overlap > F.EPS then
      r.SetMediaItemInfo_Value(p.left.item,  "D_FADEOUTLEN_AUTO",
        math.min(xfade_sec, p.overlap))
      r.SetMediaItemInfo_Value(p.right.item, "D_FADEINLEN_AUTO",
        math.min(xfade_sec, p.overlap))
    end
    F.apply_xfade_shape(p.left.item, p.right.item, xfade_shape)
  end

  -- Manual fade-in items: apply shape via FADEIN_CMD, then enforce length.
  for _, it in ipairs(t.fadein_items) do
    F.set_fadein_shape(it, fadein_shape)
    r.SetMediaItemInfo_Value(it, "D_FADEINLEN", fadein_sec)
  end

  -- Manual fade-out items: same.
  for _, it in ipairs(t.fadeout_items) do
    F.set_fadeout_shape(it, fadeout_shape)
    r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", fadeout_sec)
  end
end)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Execute Crossfade using last setting", -1)
