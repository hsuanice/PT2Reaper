-- @description hsuanice_Pro Tools Rename Clips
-- @version 0.4.2 [260509.0014]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Rename Clips** (Cmd+Opt+Shift+R)
--
--   Custom GFX dialog with:
--   - Editable Name field via Library/hsuanice_GFXInputField.lua —
--     macOS-style behaviour (single-click positions caret, double-click
--     selects all, drag selects range, Shift+arrow/Home/End extend
--     selection, Cmd/Ctrl+A select all, full caret editing).
--   - Read-only Clip Info: Source / Start / Sync / End / Duration.
--   - OK / Cancel buttons. Enter = OK, Esc = Cancel.
--
--   For multiple selected items: dialog opens sequentially in
--   track-top-to-bottom, position-left-to-right order. Cancel halts
--   the chain (already-renamed items stay renamed).
--
--   ## Dependency
--   - `PRO TOOLS/hsuanice_PT_GFXInputField.lua`
--
--   - Tags: Editing, Clips
-- @changelog
--   0.4.2 [260509.0014] - Picks up hsuanice_PT_GFXInputField 0.2.0:
--                          Cmd+Left/Right (line edge), Option+Left/Right
--                          (word jump), all with Shift extension. Cmd+A
--                          select-all also accepts char 1 (Ctrl+A) so
--                          it works on the macOS REAPER builds that
--                          emit it that way.
--   0.4.1 [260509.0010] - Library renamed to hsuanice_PT_GFXInputField
--                          and moved from Library/ to PRO TOOLS/.
--                          Updated dofile path. No behaviour change.
--   0.4.0 [260509.0008] - Refactor onto Library/hsuanice_GFXInputField
--                          (extracted shared input-field behavior).
--                          Adds Cmd/Ctrl+A select all (free in the
--                          library). No other behavior change.
--   0.3.2 [260509.0002] - Shift+Arrow / Shift+Home / Shift+End now
--                          extend the selection from a sticky anchor
--                          (set on first shifted move). Releasing
--                          shift and pressing arrow drops the anchor
--                          and collapses to the caret as before.
--   0.3.1 [260509.0000] - Reset cursor-blink phase on every caret
--                          movement (arrow keys, Home/End, click,
--                          drag, type, delete) so the caret is
--                          always visible right after it moves
--                          instead of possibly being mid-off-blink.
--   0.3.0 [260508.2351] - Native-feeling text input: single-click
--                          positions the caret at the click point
--                          (instead of selecting all), double-click
--                          selects all, click-and-drag selects a
--                          range. Selection state now anchor + caret
--                          (range = [min..max] of the two), so
--                          typing/Backspace/Delete replace the
--                          selection.
--   0.2.0 [260508.2324] - First implementation. Custom GFX dialog
--                          (no ReaImGui dependency) with full text
--                          editing, Clip Info panel, sequential
--                          multi-select rename.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local IF = dofile(_dir .. 'hsuanice_PT_GFXInputField.lua')
if not IF then
  r.ShowMessageBox("Could not load PRO TOOLS/hsuanice_PT_GFXInputField.lua",
    "Rename Clips", 0)
  return
end

-- ---------------------------------------------------------------- helpers ----

local function fmt_tc(t)
  return r.format_timestr_pos(t, "", -1)
end

local function basename(path)
  if not path or path == "" then return "" end
  return path:match("([^/\\]+)$") or path
end

local function get_item_info(item)
  if not item or not r.ValidatePtr(item, "MediaItem*") then return nil end
  local pos  = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local len  = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local snap = r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET") or 0
  local take = r.GetActiveTake(item)
  local name, src = "", "—"
  if take then
    name = r.GetTakeName(take) or ""
    if r.TakeIsMIDI(take) then
      src = "(MIDI)"
    else
      local source = r.GetMediaItemTake_Source(take)
      if source then
        local fn = r.GetMediaSourceFileName(source, "")
        src = basename(fn)
      end
    end
  end
  return {
    item  = item,
    take  = take,
    name  = name,
    src   = src,
    start = pos,
    sync  = pos + snap,
    fin   = pos + len,
    dur   = len,
  }
end

-- Collect selected items, sorted by (track index, position)
local items = {}
for i = 0, r.CountSelectedMediaItems(0) - 1 do
  items[#items+1] = r.GetSelectedMediaItem(0, i)
end
if #items == 0 then return end

table.sort(items, function(a, b)
  local ta  = r.GetMediaItem_Track(a)
  local tb  = r.GetMediaItem_Track(b)
  local tia = r.GetMediaTrackInfo_Value(ta, "IP_TRACKNUMBER")
  local tib = r.GetMediaTrackInfo_Value(tb, "IP_TRACKNUMBER")
  if tia ~= tib then return tia < tib end
  local pa = r.GetMediaItemInfo_Value(a, "D_POSITION")
  local pb = r.GetMediaItemInfo_Value(b, "D_POSITION")
  return pa < pb
end)

-- ---------------------------------------------------------------- UI ----

local W, H        = 480, 360
local FONT_SIZE   = 16
local SMALL_FONT  = 14
local FIELD_X     = 18
local FIELD_Y     = 60
local FIELD_W     = W - 36
local FIELD_H     = 32

local NAME_HDR_Y   = 18
local INFO_HDR_Y   = 110
local INFO_LINE0_Y = 140
local LINE_H       = 26

local BTN_Y = H - 52
local BTN_H = 36

local buttons = {
  { label = "Cancel", action = "cancel", x = W - 230, w = 100 },
  { label = "OK",     action = "ok",     x = W - 118, w = 100 },
}

local COL_BG          = {0.93, 0.93, 0.93}
local COL_LABEL       = {0.10, 0.10, 0.10}
local COL_DIM         = {0.40, 0.40, 0.40}
local COL_HEADER_BG   = {0.78, 0.78, 0.78}
local COL_BTN_BG      = {0.97, 0.97, 0.97}
local COL_BTN_HOVER   = {0.85, 0.90, 1.00}
local COL_BTN_BORDER  = {0.55, 0.55, 0.55}
local COL_BTN_TEXT    = {0.10, 0.10, 0.10}

local function set_col(c) gfx.set(c[1], c[2], c[3]) end

-- ---------------------------------------------------------------- input field ----

local field = IF.new{
  x           = FIELD_X,
  y           = FIELD_Y,
  w           = FIELD_W,
  h           = FIELD_H,
  value       = "",
  char_filter = IF.filter_ascii_print,
  font        = "Helvetica",
  font_size   = FONT_SIZE,
}

-- ---------------------------------------------------------------- state ----

local cur_idx   = 1
local cur_info  = nil
local last_lmb  = false
local exiting   = false

local function load_current()
  cur_info = get_item_info(items[cur_idx])
  if not cur_info or not cur_info.take then return false end
  field:set_value(cur_info.name or "")
  return true
end

local function commit_current()
  if cur_info and cur_info.take then
    r.GetSetMediaItemTakeInfo_String(cur_info.take, "P_NAME", field:get_value(), true)
  end
end

local function in_button(b, mx, my)
  return mx >= b.x and mx < b.x + b.w
     and my >= BTN_Y and my < BTN_Y + BTN_H
end

-- ---------------------------------------------------------------- draw ----

local function draw()
  set_col(COL_BG)
  gfx.rect(0, 0, W, H, true)

  gfx.setfont(1, "Helvetica", FONT_SIZE)

  set_col(COL_HEADER_BG)
  gfx.rect(0, NAME_HDR_Y - 4, W, 26, true)
  set_col(COL_LABEL)
  gfx.x, gfx.y = FIELD_X, NAME_HDR_Y
  gfx.drawstr("Name")

  if #items > 1 then
    gfx.setfont(1, "Helvetica", SMALL_FONT)
    set_col(COL_DIM)
    local prog = string.format("%d / %d", cur_idx, #items)
    local pw = gfx.measurestr(prog)
    gfx.x = W - FIELD_X - pw
    gfx.y = NAME_HDR_Y + 2
    gfx.drawstr(prog)
    gfx.setfont(1, "Helvetica", FONT_SIZE)
  end

  field:draw()

  set_col(COL_HEADER_BG)
  gfx.rect(0, INFO_HDR_Y - 4, W, 24, true)
  set_col(COL_LABEL)
  gfx.x, gfx.y = FIELD_X, INFO_HDR_Y
  gfx.drawstr("Clip Info")

  gfx.setfont(1, "Helvetica", SMALL_FONT)
  local function info_line(idx, label, value)
    local y = INFO_LINE0_Y + idx * LINE_H
    set_col(COL_DIM)
    gfx.x, gfx.y = FIELD_X, y
    gfx.drawstr(label)
    set_col(COL_LABEL)
    gfx.x = FIELD_X + 100
    gfx.drawstr(value or "")
  end
  if cur_info then
    info_line(0, "Source",   cur_info.src)
    info_line(1, "Start",    fmt_tc(cur_info.start))
    info_line(2, "Sync",     fmt_tc(cur_info.sync))
    info_line(3, "End",      fmt_tc(cur_info.fin))
    info_line(4, "Duration", fmt_tc(cur_info.dur))
  end
  gfx.setfont(1, "Helvetica", FONT_SIZE)

  local mx, my = gfx.mouse_x, gfx.mouse_y
  for _, b in ipairs(buttons) do
    local hover = in_button(b, mx, my)
    set_col(hover and COL_BTN_HOVER or COL_BTN_BG)
    gfx.rect(b.x, BTN_Y, b.w, BTN_H, true)
    set_col(COL_BTN_BORDER)
    gfx.rect(b.x, BTN_Y, b.w, BTN_H, false)

    set_col(COL_BTN_TEXT)
    local tw = gfx.measurestr(b.label)
    gfx.x = b.x + (b.w - tw) // 2
    gfx.y = BTN_Y + (BTN_H - FONT_SIZE) // 2
    gfx.drawstr(b.label)
  end
end

-- ---------------------------------------------------------------- loop ----

local function exit_dialog()
  exiting = true
  gfx.quit()
end

local function advance_or_finish()
  cur_idx = cur_idx + 1
  while cur_idx <= #items do
    if load_current() then return end
    cur_idx = cur_idx + 1
  end
  exit_dialog()
end

local function loop()
  if exiting then return end

  -- Read mouse + keyboard ONCE per frame
  local lmb = (gfx.mouse_cap & 1) == 1
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local char = gfx.getchar()

  -- Button click handling first (rising-edge of LMB)
  if lmb and not last_lmb then
    for _, b in ipairs(buttons) do
      if in_button(b, mx, my) then
        if b.action == "ok" then
          commit_current()
          advance_or_finish()
        else
          exit_dialog()
        end
        if exiting then return end
        last_lmb = lmb
        draw(); gfx.update(); r.defer(loop); return
      end
    end
  end
  last_lmb = lmb

  -- Field handles its own mouse + keyboard
  local result = field:update(char)
  if result == "closed" or result == "esc" then
    exit_dialog()
    return
  elseif result == "enter" then
    commit_current()
    advance_or_finish()
    if exiting then return end
  end

  draw()
  gfx.update()
  r.defer(loop)
end

-- ---------------------------------------------------------------- start ----

while cur_idx <= #items and not load_current() do
  cur_idx = cur_idx + 1
end
if cur_idx > #items then return end

local mx_screen, my_screen = r.GetMousePosition()
local win_x = math.floor(mx_screen - W / 2)
local win_y = math.floor(my_screen - H / 2)

r.Undo_BeginBlock()
r.atexit(function()
  r.Undo_EndBlock("Pro Tools: Rename Clips", -1)
  r.UpdateArrange()
end)

gfx.init("Name", W, H, 0, win_x, win_y)
gfx.setfont(1, "Helvetica", FONT_SIZE)
loop()
