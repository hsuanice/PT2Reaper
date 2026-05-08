-- @description hsuanice_PT_Transient Settings
-- @version 0.3.4 [260508.1844]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Settings entry point for the shared Pro Tools transient helpers.
--
--   Custom dialog (built on REAPER's stock `gfx`) with three buttons:
--   - **OK**                — saves min_ms, closes.
--   - **Cancel**             — closes without saving (Esc / window close
--                              also map here).
--   - **Transient Setting**  — saves min_ms, closes our dialog, then
--                              opens REAPER's native transient detection
--                              panel via action 41208 so you can adjust
--                              sensitivity / threshold without our modal
--                              dialog blocking interaction.
--
--   The min-gap value is stored in ExtState namespace
--   `hsuanice_PT_Transient`, key `min_ms`, via
--   Library/hsuanice_PT_Transient.lua.
--
--   ## Dependency
--   - `Library/hsuanice_PT_Transient.lua`
--
--   - Tags: Editing, Settings, Transient
-- @changelog
--   0.3.4 [260508.1844] - Proper text-editing in the input field:
--                          tracks caret position, supports left/right
--                          arrow keys, Home, End, Delete (forward), and
--                          inserts/removes characters at the caret rather
--                          than only at the end. Cursor renders at the
--                          caret position. Selecting + typing still
--                          replaces the whole field.
--   0.3.3 [260508.1834] - Text-selection highlight (macOS-style):
--                          dialog opens with all text pre-selected (blue
--                          highlight, white text); clicking the field
--                          re-selects all; typing a digit replaces the
--                          selection; Backspace while selected clears
--                          the field. Cursor hidden while selected.
--   0.3.2 [260508.1806] - Visual feedback on the input field: blue
--                          accent border (always-focused look since
--                          there's only one field) and a thicker (2px)
--                          blinking cursor, so users notice the field
--                          is editable without clicking.
--   0.3.1 [260508.1802] - Light/native-style colour palette (light grey
--                          background, white field, subtle button borders).
--                          Bigger font (size 16). Window is centred on the
--                          current mouse position so it pops near the
--                          user's focus instead of the screen origin.
--   0.3.0 [260508.1758] - Replace blocking GetUserInputs with a stock-gfx
--                          custom dialog so the user can click "Transient
--                          Setting" to open REAPER's native panel without
--                          a modal dialog blocking it. Three buttons:
--                          OK / Cancel / Transient Setting. Pressing
--                          Transient Setting saves the current min_ms
--                          value first, then opens action 41208.
--   0.2.1 [260508.1741] - Hardcode native action 41208 (verified by user
--                          as the panel-opening command). Removed the
--                          runtime name-lookup fallback.
--   0.2.0 [260508.1724] - Open REAPER native transient detection panel
--                          alongside our min-gap dialog. Action looked up
--                          at runtime by partial name match. Shorten
--                          dialog label so it no longer truncates.
--   0.1.0 [260508.1648] - Initial release.

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local Tran  = dofile(_dir .. '../Library/hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Transient.lua",
    "PT_Transient Settings", 0)
  return
end

-- ---------------------------------------------------------------- UI ----

local W, H        = 410, 175
local FONT_SIZE   = 16
local FIELD_X     = 18
local FIELD_Y     = 50
local FIELD_W     = W - 36
local FIELD_H     = 32
local LABEL_X     = 18
local LABEL_Y     = 18
local BTN_Y       = 120
local BTN_H       = 36

local buttons = {
  { label = "OK",                action = "save",        x = 18,  w = 100 },
  { label = "Cancel",            action = "cancel",      x = 124, w = 100 },
  { label = "Transient Setting", action = "save_native", x = 230, w = 162 },
}

-- Native-ish light palette
local COL_BG          = {0.93, 0.93, 0.93}
local COL_LABEL       = {0.10, 0.10, 0.10}
local COL_FIELD_BG    = {1.00, 1.00, 1.00}
local COL_FIELD_BORDER= {0.20, 0.50, 0.90}  -- blue accent (focused look)
local COL_FIELD_TEXT  = {0.10, 0.10, 0.10}
local COL_SEL_BG      = {0.20, 0.50, 0.90}  -- selection highlight
local COL_SEL_TEXT    = {1.00, 1.00, 1.00}  -- text colour while selected
local COL_BTN_BG      = {0.97, 0.97, 0.97}
local COL_BTN_HOVER   = {0.85, 0.90, 1.00}
local COL_BTN_BORDER  = {0.55, 0.55, 0.55}
local COL_BTN_TEXT    = {0.10, 0.10, 0.10}
local COL_CURSOR      = {0.10, 0.10, 0.10}

local function set_col(c) gfx.set(c[1], c[2], c[3]) end

local input         = tostring(Tran.get_min_ms())
local caret         = #input -- caret index (0..#input), at end by default
local selected      = true   -- macOS-style: field starts with all text selected
local cursor_blink  = 0
local last_lmb      = false
local exiting       = false

-- REAPER gfx.getchar() codes for special keys
local KEY_LEFT  = 1818584692
local KEY_RIGHT = 1919379572
local KEY_HOME  = 1752132965
local KEY_END   = 6647396
local KEY_DEL   = 6579564

local function in_field(mx, my)
  return mx >= FIELD_X and mx < FIELD_X + FIELD_W
     and my >= FIELD_Y and my < FIELD_Y + FIELD_H
end

local function clamp_input()
  local v = tonumber(input) or 0
  if v < 0   then v = 0   end
  if v > 999 then v = 999 end
  return math.floor(v + 0.5)
end

local function in_button(b, mx, my)
  return mx >= b.x and mx < b.x + b.w
     and my >= BTN_Y and my < BTN_Y + BTN_H
end

local function draw()
  -- Background
  set_col(COL_BG)
  gfx.rect(0, 0, W, H, true)

  -- Label
  gfx.setfont(1, "Helvetica", FONT_SIZE)
  set_col(COL_LABEL)
  gfx.x, gfx.y = LABEL_X, LABEL_Y
  gfx.drawstr("Min gap (ms, 0-999):")

  -- Input field
  set_col(COL_FIELD_BG)
  gfx.rect(FIELD_X, FIELD_Y, FIELD_W, FIELD_H, true)
  -- Double-stroke focus border (blue, ~2px) for clear "this is editable" cue
  set_col(COL_FIELD_BORDER)
  gfx.rect(FIELD_X,     FIELD_Y,     FIELD_W,     FIELD_H,     false)
  gfx.rect(FIELD_X + 1, FIELD_Y + 1, FIELD_W - 2, FIELD_H - 2, false)
  -- Text rendering — invert colours when the field is selected
  local text_y = FIELD_Y + (FIELD_H - FONT_SIZE) // 2
  if selected and #input > 0 then
    local tw = gfx.measurestr(input)
    set_col(COL_SEL_BG)
    gfx.rect(FIELD_X + 10, FIELD_Y + 5, tw + 1, FIELD_H - 10, true)
    set_col(COL_SEL_TEXT)
  else
    set_col(COL_FIELD_TEXT)
  end
  gfx.x, gfx.y = FIELD_X + 10, text_y
  gfx.drawstr(input)

  -- Blinking cursor at the caret position (only when NOT selected)
  if not selected and (cursor_blink % 60) < 30 then
    local before = input:sub(1, caret)
    local cw = gfx.measurestr(before)
    set_col(COL_CURSOR)
    gfx.rect(FIELD_X + 10 + cw, FIELD_Y + 6,
             2, FIELD_H - 12, true)
  end

  -- Buttons
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

local function commit_and_exit(action)
  if exiting then return end
  exiting = true
  if action == "save" or action == "save_native" then
    Tran.set_min_ms(clamp_input())
  end
  gfx.quit()
  if action == "save_native" then
    r.Main_OnCommand(41208, 0)  -- Transient detection sensitivity/threshold: Adjust...
  end
end

local function loop()
  if exiting then return end
  cursor_blink = cursor_blink + 1

  -- Mouse: detect rising-edge of left button
  local lmb = (gfx.mouse_cap & 1) == 1
  if lmb and not last_lmb then
    local mx, my = gfx.mouse_x, gfx.mouse_y
    -- Buttons first
    for _, b in ipairs(buttons) do
      if in_button(b, mx, my) then
        commit_and_exit(b.action)
        return
      end
    end
    -- Click on the input field re-selects all (macOS-style)
    if in_field(mx, my) then
      selected = true
      caret    = #input
    else
      selected = false
    end
  end
  last_lmb = lmb

  -- Keyboard
  local char = gfx.getchar()
  if char == -1 then
    commit_and_exit("cancel")
    return
  end
  if char == 27 then         -- ESC
    commit_and_exit("cancel")
    return
  end
  if char == 13 then         -- Enter
    commit_and_exit("save")
    return
  end
  if char == 8 then                                  -- Backspace
    if selected then
      input    = ""
      caret    = 0
      selected = false
    elseif caret > 0 then
      input = input:sub(1, caret - 1) .. input:sub(caret + 1)
      caret = caret - 1
    end
  elseif char == KEY_DEL then                        -- Delete (forward)
    if selected then
      input    = ""
      caret    = 0
      selected = false
    elseif caret < #input then
      input = input:sub(1, caret) .. input:sub(caret + 2)
    end
  elseif char == KEY_LEFT then
    if selected then
      caret = 0
    elseif caret > 0 then
      caret = caret - 1
    end
    selected = false
  elseif char == KEY_RIGHT then
    if selected then
      caret = #input
    elseif caret < #input then
      caret = caret + 1
    end
    selected = false
  elseif char == KEY_HOME then
    caret    = 0
    selected = false
  elseif char == KEY_END then
    caret    = #input
    selected = false
  elseif char >= 48 and char <= 57 then              -- digits 0-9
    if selected then
      input    = string.char(char)
      caret    = 1
      selected = false
    elseif #input < 3 then
      input = input:sub(1, caret) .. string.char(char) .. input:sub(caret + 1)
      caret = caret + 1
    end
  end

  draw()
  gfx.update()
  r.defer(loop)
end

-- Center the window on the current mouse position (no stock API for
-- screen-size, so this is a reasonable approximation).
local mx_screen, my_screen = r.GetMousePosition()
local win_x = math.floor(mx_screen - W / 2)
local win_y = math.floor(my_screen - H / 2)

gfx.init("PT_Transient — Min Gap", W, H, 0, win_x, win_y)
gfx.setfont(1, "Helvetica", FONT_SIZE)
loop()
