--[[
@description hsuanice_PT_Transient Settings
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Settings entry point for the shared Pro Tools transient helpers.

  Custom dialog (hsuanice_PT_GFXInputField + stock gfx) with three
  buttons:
  - **OK**                — saves min_ms, closes.
  - **Cancel**             — closes without saving (Esc / window close
                             also map here).
  - **Transient Setting**  — saves min_ms, closes our dialog, then
                             opens REAPER's native transient detection
                             panel via action 41208 so you can adjust
                             sensitivity / threshold without our modal
                             dialog blocking it.

  The min-gap value is stored in ExtState namespace
  `hsuanice_PT_Transient`, key `min_ms`, via
  Library/hsuanice_PT_Transient.lua.

  Input field behaviour is provided by hsuanice_GFXInputField:
  single-click positions the caret, double-click selects all,
  click-drag selects a range, Shift+arrow/Home/End extend the
  selection, Cmd/Ctrl+A select all.

  ## Dependencies
  - `Library/hsuanice_PT_Transient.lua`
  - `PRO TOOLS/hsuanice_PT_GFXInputField.lua`

  - Tags: Editing, Settings, Transient
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''

local Tran = dofile(_dir .. 'hsuanice_PT_Transient.lua')
if not Tran then
  r.ShowMessageBox("Could not load hsuanice_PT_Transient.lua",
    "PT_Transient Settings", 0)
  return
end

local IF = dofile(_dir .. 'hsuanice_PT_GFXInputField.lua')
if not IF then
  r.ShowMessageBox("Could not load PRO TOOLS/hsuanice_PT_GFXInputField.lua",
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

local COL_BG          = {0.93, 0.93, 0.93}
local COL_LABEL       = {0.10, 0.10, 0.10}
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
  value       = tostring(Tran.get_min_ms()),
  char_filter = IF.filter_digits,
  max_len     = 3,
  font        = "Helvetica",
  font_size   = FONT_SIZE,
}

-- ---------------------------------------------------------------- state ----

local last_lmb = false
local exiting  = false

local function in_button(b, mx, my)
  return mx >= b.x and mx < b.x + b.w
     and my >= BTN_Y and my < BTN_Y + BTN_H
end

local function clamp_value()
  local v = tonumber(field:get_value()) or 0
  if v < 0   then v = 0   end
  if v > 999 then v = 999 end
  return math.floor(v + 0.5)
end

local function commit_and_exit(action)
  if exiting then return end
  exiting = true
  if action == "save" or action == "save_native" then
    Tran.set_min_ms(clamp_value())
  end
  gfx.quit()
  if action == "save_native" then
    r.Main_OnCommand(41208, 0)  -- Transient detection sensitivity/threshold: Adjust...
  end
end

-- ---------------------------------------------------------------- draw ----

local function draw()
  set_col(COL_BG)
  gfx.rect(0, 0, W, H, true)

  gfx.setfont(1, "Helvetica", FONT_SIZE)
  set_col(COL_LABEL)
  gfx.x, gfx.y = LABEL_X, LABEL_Y
  gfx.drawstr("Min gap (ms, 0-999):")

  field:draw()

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

local function loop()
  if exiting then return end

  local lmb = (gfx.mouse_cap & 1) == 1
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local char = gfx.getchar()

  -- Button clicks first (rising-edge of LMB)
  if lmb and not last_lmb then
    for _, b in ipairs(buttons) do
      if in_button(b, mx, my) then
        commit_and_exit(b.action)
        return
      end
    end
  end
  last_lmb = lmb

  local result = field:update(char)
  if result == "closed" or result == "esc" then
    commit_and_exit("cancel")
    return
  elseif result == "enter" then
    commit_and_exit("save")
    return
  end

  draw()
  gfx.update()
  r.defer(loop)
end

-- Center on mouse
local mx_screen, my_screen = r.GetMousePosition()
local win_x = math.floor(mx_screen - W / 2)
local win_y = math.floor(my_screen - H / 2)

gfx.init("PT_Transient — Min Gap", W, H, 0, win_x, win_y)
gfx.setfont(1, "Helvetica", FONT_SIZE)
loop()
