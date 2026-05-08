-- @description hsuanice_Pro Tools Space Clips
-- @version 0.5.0 [260509.0220]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Space Clips** (Opt+Shift+H)
--
--   Repositions selected items so each item starts at a fixed
--   `interval` distance after the previous item's anchor (Item Start
--   or Item End). The first item in the sort order is left in place;
--   subsequent items are repositioned.
--
--   ## Units (simple decimal formats)
--   - **Frames**  — whole frames at the project frame rate, e.g. `30`
--   - **Secs**    — seconds with three decimals, e.g. `1.500`
--   - **Bar.Beat** — decimal bars at the project's first time
--                    signature / tempo, e.g. `1.50` (= 1.5 bars).
--                    Tempo / time-sig variation is approximated.
--
--   ## Modes
--   - **Anchor**:
--     - Item End   — gap of `interval` between adjacent items
--                    (default; interval=0 → items abut)
--     - Item Start — every item placed at prev.start + interval
--                    (constant pitch / overlap)
--   - **Mode**:
--     - Single Track — sort + position per track independently
--     - Cross Track  — sort all selected items globally, position one
--                      after another regardless of track
--
--   ## Persistence
--   ExtState namespace `hsuanice_PT_SpaceClips` keeps `interval_sec`
--   (numeric, in seconds), `unit`, `anchor`, `mode` between runs.
--   Switching unit reformats the same internal seconds value.
--
--   ## Dependency
--   - `PRO TOOLS/hsuanice_PT_GFXInputField.lua`
--
--   - Tags: Editing, Clips
-- @changelog
--   0.5.0 [260509.0220] - After spacing, expand the time selection
--                          and per-track razor zones to cover the
--                          repositioned items. Expand-only — never
--                          shrinks. TS / razor with no overlap with
--                          items are also adjusted (their bounds
--                          grow to include the items if items now
--                          extend past).
--   0.4.0 [260509.0206] - Simplify unit formats:
--                          Timecode (HH:MM:SS:FF) → Frames (decimal)
--                          Min:Secs (M:SS.mmm)     → Secs (0.000)
--                          Beats (decimal)         → Bar.Beat (0.00)
--                          Internal storage stays as seconds. Old
--                          ExtState values auto-migrate to new names.
--   0.3.0 [260509.0142] - Add Beats unit. Uses project-start tempo for
--                          beats↔seconds conversion (constant-tempo
--                          approximation; tempo-variant projects will
--                          see slight drift). Stored value remains
--                          internal seconds.
--   0.2.0 [260509.0129] - First implementation. GFX dialog (no
--                          ReaImGui) with Timecode / Min:Secs unit
--                          toggle, Item Start / Item End anchor
--                          toggle, Single / Cross Track mode toggle,
--                          OK / Cancel buttons. Settings persist
--                          via ExtState; switching unit reformats
--                          without losing the internal seconds value.
--                          Default anchor is Item End. Logic ported
--                          from Beta Testing/hsuanice_Item Reposition.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local IF = dofile(_dir .. 'hsuanice_PT_GFXInputField.lua')
if not IF then
  r.ShowMessageBox("Could not load hsuanice_PT_GFXInputField.lua",
    "Space Clips", 0)
  return
end

-- ---------------------------------------------------------------- format ----

local function fps()
  local v = r.TimeMap_curFrameRate(0)
  if not v or v <= 0 then v = 24 end
  return v
end

local function bpm_at_start()
  local bpm = r.GetProjectTimeSignature2(0)
  if not bpm or bpm <= 0 then bpm = 120 end
  return bpm
end

local function beats_per_bar()
  local n = r.TimeMap_GetTimeSigAtTime(0, 0)
  if not n or n <= 0 then n = 4 end
  return n
end

-- Frames (integer)
local function format_frames(t)
  return tostring(math.floor(t * fps() + 0.5))
end

local function parse_frames(s)
  if not s or s == "" then return nil end
  local n = tonumber(s)
  if n then return n / fps() end
  return nil
end

-- Secs (decimal seconds, 3 decimals)
local function format_secs(t)
  return string.format("%.3f", t)
end

local function parse_secs(s)
  if not s or s == "" then return nil end
  return tonumber(s)
end

-- Bar.Beat (decimal bars, 2 decimals; uses project-start tempo + time sig)
local function format_barbeat(t)
  local bars = t * bpm_at_start() / (60 * beats_per_bar())
  return string.format("%.2f", bars)
end

local function parse_barbeat(s)
  if not s or s == "" then return nil end
  local n = tonumber(s)
  if n then return n * beats_per_bar() * 60 / bpm_at_start() end
  return nil
end

local function format_time(t, unit)
  if unit == "frames"  then return format_frames(t)  end
  if unit == "barbeat" then return format_barbeat(t) end
  return format_secs(t)
end

local function parse_time(s, unit)
  if unit == "frames"  then return parse_frames(s)  end
  if unit == "barbeat" then return parse_barbeat(s) end
  return parse_secs(s)
end

-- ---------------------------------------------------------------- state ----

local NS = "hsuanice_PT_SpaceClips"

local function get_str(k, d) local v = r.GetExtState(NS, k); if v == "" then return d end; return v end
local function set_str(k, v) r.SetExtState(NS, k, v, true) end

local interval_sec = tonumber(get_str("interval_sec", "0")) or 0
local unit         = get_str("unit",   "secs")     -- "frames" | "secs" | "barbeat"
local anchor       = get_str("anchor", "end")      -- "start" | "end"   (default end)
local mode         = get_str("mode",   "single")   -- "single" | "cross"

-- Migrate legacy unit values from earlier versions.
if unit == "timecode" then unit = "frames"  end
if unit == "minsecs"  then unit = "secs"    end
if unit == "beats"    then unit = "barbeat" end
if unit ~= "frames" and unit ~= "secs" and unit ~= "barbeat" then unit = "secs" end
if anchor ~= "start" and anchor ~= "end" then anchor = "end" end
if mode   ~= "single" and mode ~= "cross" then mode = "single" end

-- ---------------------------------------------------------------- UI ----

local W, H        = 480, 260
local FONT_SIZE   = 16
local LBL_X       = 18
local FIELD_X     = 130
local FIELD_W     = 180
local FIELD_H     = 32
local ROW_H       = 44
local ROW_INTERVAL = 18
local ROW_UNIT     = 18 + ROW_H
local ROW_ANCHOR   = 18 + ROW_H * 2
local ROW_MODE     = 18 + ROW_H * 3

local BTN_Y = H - 56
local BTN_H = 36

local main_buttons = {
  { label = "OK",     action = "ok",     x = W - 230, w = 100 },
  { label = "Cancel", action = "cancel", x = W - 118, w = 100 },
}

local COL_BG          = {0.93, 0.93, 0.93}
local COL_LABEL       = {0.10, 0.10, 0.10}
local COL_BTN_BG      = {0.97, 0.97, 0.97}
local COL_BTN_HOVER   = {0.85, 0.90, 1.00}
local COL_BTN_BORDER  = {0.55, 0.55, 0.55}
local COL_BTN_TEXT    = {0.10, 0.10, 0.10}
local COL_TOG_ON_BG   = {0.30, 0.55, 0.95}
local COL_TOG_ON_TEXT = {1.00, 1.00, 1.00}

local function set_col(c) gfx.set(c[1], c[2], c[3]) end

-- ---------------------------------------------------------------- field ----

local field = IF.new{
  x = FIELD_X, y = ROW_INTERVAL + 4,
  w = FIELD_W, h = FIELD_H,
  value       = format_time(interval_sec, unit),
  char_filter = IF.filter_time,
  font        = "Helvetica",
  font_size   = FONT_SIZE,
}

local function refresh_field_format()
  field:set_value(format_time(interval_sec, unit))
end

local function commit_field_to_seconds()
  local n = parse_time(field:get_value(), unit)
  if n then interval_sec = n end
end

-- ---------------------------------------------------------------- toggle row ----

local function build_row(y_base, options)
  -- options: { {label, value}, ... }
  local btns = {}
  local x = FIELD_X
  local btn_h = 30
  for _, o in ipairs(options) do
    local w = math.max(90, gfx.measurestr and gfx.measurestr(o.label) + 24 or 100)
    btns[#btns+1] = { label = o.label, value = o.value,
                      x = x, y = y_base + 4, w = w, h = btn_h }
    x = x + w + 6
  end
  return btns
end

-- We need gfx initialized before measurestr works correctly. Build rows lazily.
local unit_btns, anchor_btns, mode_btns

local function build_all_rows()
  unit_btns   = build_row(ROW_UNIT,   {
    { label = "Frames",   value = "frames"  },
    { label = "Secs",     value = "secs"    },
    { label = "Bar.Beat", value = "barbeat" },
  })
  anchor_btns = build_row(ROW_ANCHOR, {
    { label = "Item Start", value = "start" },
    { label = "Item End",   value = "end"   },
  })
  mode_btns   = build_row(ROW_MODE,   {
    { label = "Single Track", value = "single" },
    { label = "Cross Track",  value = "cross"  },
  })
end

local function in_btn(b, mx, my)
  return mx >= b.x and mx < b.x + b.w
     and my >= b.y and my < b.y + b.h
end

local function in_main_btn(b, mx, my)
  return mx >= b.x and mx < b.x + b.w
     and my >= BTN_Y and my < BTN_Y + BTN_H
end

local function draw_toggle_row(btns, current)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  for _, b in ipairs(btns) do
    local sel = (b.value == current)
    if sel then
      set_col(COL_TOG_ON_BG)
    else
      local hover = in_btn(b, mx, my)
      set_col(hover and COL_BTN_HOVER or COL_BTN_BG)
    end
    gfx.rect(b.x, b.y, b.w, b.h, true)
    set_col(COL_BTN_BORDER)
    gfx.rect(b.x, b.y, b.w, b.h, false)
    set_col(sel and COL_TOG_ON_TEXT or COL_BTN_TEXT)
    local tw = gfx.measurestr(b.label)
    gfx.x = b.x + (b.w - tw) // 2
    gfx.y = b.y + (b.h - FONT_SIZE) // 2 + 1
    gfx.drawstr(b.label)
  end
end

-- ---------------------------------------------------------------- draw ----

local function draw()
  set_col(COL_BG)
  gfx.rect(0, 0, W, H, true)

  gfx.setfont(1, "Helvetica", FONT_SIZE)
  set_col(COL_LABEL)

  -- Labels
  gfx.x, gfx.y = LBL_X, ROW_INTERVAL + 8
  gfx.drawstr("Interval:")
  gfx.x, gfx.y = LBL_X, ROW_UNIT + 12
  gfx.drawstr("Unit:")
  gfx.x, gfx.y = LBL_X, ROW_ANCHOR + 12
  gfx.drawstr("Anchor:")
  gfx.x, gfx.y = LBL_X, ROW_MODE + 12
  gfx.drawstr("Mode:")

  -- Input field
  field:draw()

  -- Toggle rows
  draw_toggle_row(unit_btns,   unit)
  draw_toggle_row(anchor_btns, anchor)
  draw_toggle_row(mode_btns,   mode)

  -- Main buttons
  local mx, my = gfx.mouse_x, gfx.mouse_y
  for _, b in ipairs(main_buttons) do
    local hover = in_main_btn(b, mx, my)
    set_col(hover and COL_BTN_HOVER or COL_BTN_BG)
    gfx.rect(b.x, BTN_Y, b.w, BTN_H, true)
    set_col(COL_BTN_BORDER)
    gfx.rect(b.x, BTN_Y, b.w, BTN_H, false)
    set_col(COL_BTN_TEXT)
    local tw = gfx.measurestr(b.label)
    gfx.x = b.x + (b.w - tw) // 2
    gfx.y = BTN_Y + (BTN_H - FONT_SIZE) // 2 + 1
    gfx.drawstr(b.label)
  end
end

-- ---------------------------------------------------------------- repos ----

local function reposition_items()
  local n_sel = r.CountSelectedMediaItems(0)
  if n_sel < 2 then return end

  local items = {}
  for i = 0, n_sel - 1 do items[i+1] = r.GetSelectedMediaItem(0, i) end

  local from_end = (anchor == "end")
  local cross    = (mode   == "cross")

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  if cross then
    table.sort(items, function(a, b)
      local pa = r.GetMediaItemInfo_Value(a, "D_POSITION")
      local la = r.GetMediaItemInfo_Value(a, "D_LENGTH")
      local pb = r.GetMediaItemInfo_Value(b, "D_POSITION")
      local lb = r.GetMediaItemInfo_Value(b, "D_LENGTH")
      return (from_end and (pa + la) or pa) < (from_end and (pb + lb) or pb)
    end)
    if from_end then
      local pos = r.GetMediaItemInfo_Value(items[1], "D_POSITION")
                + r.GetMediaItemInfo_Value(items[1], "D_LENGTH")
      for i = 2, #items do
        local item = items[i]
        local len  = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local new_pos = pos + interval_sec
        r.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
        pos = new_pos + len
      end
    else
      local pos = r.GetMediaItemInfo_Value(items[1], "D_POSITION")
      for i = 1, #items do
        r.SetMediaItemInfo_Value(items[i], "D_POSITION", pos)
        pos = pos + interval_sec
      end
    end
  else
    local by_track = {}
    for _, it in ipairs(items) do
      local tr = r.GetMediaItem_Track(it)
      by_track[tr] = by_track[tr] or {}
      table.insert(by_track[tr], it)
    end
    for _, list in pairs(by_track) do
      table.sort(list, function(a, b)
        return r.GetMediaItemInfo_Value(a, "D_POSITION")
             < r.GetMediaItemInfo_Value(b, "D_POSITION")
      end)
      if from_end then
        local pos = r.GetMediaItemInfo_Value(list[1], "D_POSITION")
                  + r.GetMediaItemInfo_Value(list[1], "D_LENGTH")
        for i = 2, #list do
          local item = list[i]
          local len  = r.GetMediaItemInfo_Value(item, "D_LENGTH")
          local new_pos = pos + interval_sec
          r.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
          pos = new_pos + len
        end
      else
        local pos = r.GetMediaItemInfo_Value(list[1], "D_POSITION")
        for i = 1, #list do
          r.SetMediaItemInfo_Value(list[i], "D_POSITION", pos)
          pos = pos + interval_sec
        end
      end
    end
  end

  -- Expand TS + razor (selection-grows-with-items; never shrinks)
  local items_min_pos, items_max_fin = math.huge, -math.huge
  local per_track_bounds = {}
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    if r.ValidatePtr(item, "MediaItem*") then
      local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      local fin = pos + r.GetMediaItemInfo_Value(item, "D_LENGTH")
      if pos < items_min_pos then items_min_pos = pos end
      if fin > items_max_fin then items_max_fin = fin end
      local tr = r.GetMediaItem_Track(item)
      local b = per_track_bounds[tr]
      if b then
        if pos < b.s then b.s = pos end
        if fin > b.e then b.e = fin end
      else
        per_track_bounds[tr] = { s = pos, e = fin }
      end
    end
  end

  if items_min_pos < math.huge then
    -- Time selection: only grow
    local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if ts_e > ts_s + 1e-9 then
      local new_s = math.min(ts_s, items_min_pos)
      local new_e = math.max(ts_e, items_max_fin)
      if new_s < ts_s - 1e-9 or new_e > ts_e + 1e-9 then
        r.GetSet_LoopTimeRange(true, false, new_s, new_e, false)
      end
    end

    -- Razor zones per track: only grow
    for tr, bnd in pairs(per_track_bounds) do
      local _, str = r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
      if str and str ~= "" then
        local parts = {}
        local changed = false
        for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
          local s = tonumber(s_str)
          local e = tonumber(e_str)
          if s and e then
            local new_s = math.min(s, bnd.s)
            local new_e = math.max(e, bnd.e)
            if new_s < s - 1e-9 or new_e > e + 1e-9 then changed = true end
            parts[#parts+1] = string.format("%.14f %.14f %s", new_s, new_e, guid)
          end
        end
        if changed then
          r.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS",
            table.concat(parts, " "), true)
        end
      end
    end
  end

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Space Clips", -1)
end

-- ---------------------------------------------------------------- loop ----

local last_lmb = false
local exiting  = false

local function exit_dialog() exiting = true; gfx.quit() end

local function persist()
  set_str("interval_sec", tostring(interval_sec))
  set_str("unit",   unit)
  set_str("anchor", anchor)
  set_str("mode",   mode)
end

local function loop()
  if exiting then return end

  local lmb = (gfx.mouse_cap & 1) == 1
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local char = gfx.getchar()

  -- Toggle row clicks first (rising-edge only)
  if lmb and not last_lmb then
    -- Main buttons
    for _, b in ipairs(main_buttons) do
      if in_main_btn(b, mx, my) then
        if b.action == "ok" then
          commit_field_to_seconds()
          persist()
          reposition_items()
        end
        exit_dialog()
        return
      end
    end
    -- Unit toggle
    for _, b in ipairs(unit_btns) do
      if in_btn(b, mx, my) and b.value ~= unit then
        commit_field_to_seconds()  -- save current parsed value
        unit = b.value
        refresh_field_format()
        last_lmb = lmb
        draw(); gfx.update(); r.defer(loop); return
      end
    end
    -- Anchor toggle
    for _, b in ipairs(anchor_btns) do
      if in_btn(b, mx, my) then anchor = b.value; break end
    end
    -- Mode toggle
    for _, b in ipairs(mode_btns) do
      if in_btn(b, mx, my) then mode = b.value; break end
    end
  end
  last_lmb = lmb

  -- Field handles its own keyboard / mouse + returns special tokens
  local result = field:update(char)
  if result == "closed" or result == "esc" then
    exit_dialog(); return
  elseif result == "enter" then
    commit_field_to_seconds()
    persist()
    reposition_items()
    exit_dialog(); return
  end

  draw()
  gfx.update()
  r.defer(loop)
end

-- ---------------------------------------------------------------- start ----

local mx_screen, my_screen = r.GetMousePosition()
local win_x = math.floor(mx_screen - W / 2)
local win_y = math.floor(my_screen - H / 2)

gfx.init("Space Clips", W, H, 0, win_x, win_y)
gfx.setfont(1, "Helvetica", FONT_SIZE)
build_all_rows()
loop()
