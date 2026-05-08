--[[
@description hsuanice_PT_GFXInputField — Native-feeling text input for gfx
@version 0.2.0 [260509.0014]
@author hsuanice
@about
  Reusable text input field for REAPER's stock `gfx` library, designed
  to feel close to a native macOS text field:
    - single-click positions the caret at the click point
    - double-click selects all
    - click-drag selects a range
    - Shift + arrow / Home / End extend the selection from a sticky
      anchor; releasing shift collapses the selection
    - Cmd / Ctrl + A select all (also accepts the legacy char-code 1
      that some builds emit for Ctrl+A)
    - Cmd + Left / Right jump to the start / end of the line
    - Option + Left / Right jump by word boundary (handles whitespace
      so for short / single-word inputs this feels like edge-jump)
    - Shift can be combined with any caret-moving key to extend the
      selection from the sticky anchor
    - Backspace / Delete remove the current selection or one character
    - Home / End jump to the start / end of the field
    - Caret-blink phase is reset on every caret movement so the | is
      always visible immediately after it moves
    - Configurable char filter (digits, ASCII printable, or custom)

  ## Usage
    local _info = debug.getinfo(1, 'S')
    local _dir  = _info.source:match('^@(.*[/\\])') or ''
    local IF = dofile(_dir .. 'hsuanice_PT_GFXInputField.lua')

    local field = IF.new{
      x = 18, y = 50, w = 344, h = 32,
      value = "default",
      char_filter = IF.filter_digits,    -- or IF.filter_ascii_print
      max_len = 999,
    }

    -- in your defer loop:
    local char = gfx.getchar()
    local result = field:update(char)
    if result == "enter"  then ... end
    if result == "esc"    then ... end
    if result == "closed" then ... end

    field:draw()

  ## API
    IF.new(opts)         → field instance
      opts: { x, y, w, h, value, char_filter, max_len, font, font_size,
              padding, double_click_s, colors }

    field:update(char)   → "enter" | "esc" | "closed" | nil
    field:draw()
    field:get_value()    → string
    field:set_value(s)   → also selects all
    field:select_all()
    field:set_focus(b)   → controls caret blinking + key consumption
    field:has_focus()    → boolean

  ## Constants
    IF.KEY_LEFT, IF.KEY_RIGHT, IF.KEY_HOME, IF.KEY_END, IF.KEY_DEL

  ## Filters
    IF.filter_digits, IF.filter_ascii_print

@changelog
  0.2.0 [260509.0014] - Add Cmd+Left/Right (jump to line start/end)
                         and Option+Left/Right (jump by word
                         boundary). Both honour Shift for selection
                         extension. Cmd+A select-all also accepts
                         the legacy char-code 1 (Ctrl+A) which some
                         REAPER builds emit on macOS.
  0.1.1 [260509.0010] - Renamed file from hsuanice_GFXInputField.lua
                         to hsuanice_PT_GFXInputField.lua. Moved out of
                         Library/ and into PRO TOOLS/ alongside the
                         other PT_ library scripts (hsuanice_PT_Nudge,
                         hsuanice_PT_Grid). No code change.
  0.1.0 [260509.0005] - Initial release. Extracted from the input
                         field embedded in hsuanice_Pro Tools Rename
                         Clips v0.3.2. Adds Cmd / Ctrl + A select all.
--]]

local r = reaper
local M = {}

-- ---- Public constants ----------------------------------------------------

M.KEY_LEFT  = 1818584692
M.KEY_RIGHT = 1919379572
M.KEY_HOME  = 1752132965
M.KEY_END   = 6647396
M.KEY_DEL   = 6579564

-- ---- Public char filters -------------------------------------------------

M.filter_digits          = function(c) return c >= 48 and c <= 57 end
M.filter_ascii_print     = function(c) return c >= 32 and c <= 126 end

-- ---- Default colours -----------------------------------------------------

M.default_colors = {
  bg       = {1.00, 1.00, 1.00},
  border   = {0.20, 0.50, 0.90},
  text     = {0.10, 0.10, 0.10},
  cursor   = {0.10, 0.10, 0.10},
  sel_bg   = {0.20, 0.50, 0.90},
  sel_text = {1.00, 1.00, 1.00},
}

-- ---- Internal helpers ----------------------------------------------------

local function set_col(c) gfx.set(c[1], c[2], c[3]) end

-- Word-boundary navigation. Mirrors macOS Option+Arrow behaviour:
-- skip any whitespace adjacent to the caret, then skip the run of
-- non-whitespace characters in the same direction.
local function word_left(s, c)
  while c > 0 and s:sub(c, c):match("%s")     do c = c - 1 end
  while c > 0 and not s:sub(c, c):match("%s") do c = c - 1 end
  return c
end

local function word_right(s, c)
  local len = #s
  while c < len and s:sub(c + 1, c + 1):match("%s")     do c = c + 1 end
  while c < len and not s:sub(c + 1, c + 1):match("%s") do c = c + 1 end
  return c
end

local Field = {}
Field.__index = Field

-- ---- Constructor ---------------------------------------------------------

function M.new(opts)
  opts = opts or {}
  local f = setmetatable({}, Field)
  f.x              = opts.x or 0
  f.y              = opts.y or 0
  f.w              = opts.w or 200
  f.h              = opts.h or 32
  f.value          = opts.value or ""
  f.char_filter    = opts.char_filter or M.filter_ascii_print
  f.max_len        = opts.max_len or 9999
  f.font           = opts.font or "Helvetica"
  f.font_size      = opts.font_size or 16
  f.padding        = opts.padding or 10
  f.double_click_s = opts.double_click_s or 0.4
  f.colors         = opts.colors or M.default_colors

  f.caret          = #f.value
  f.sel_anchor     = 0           -- start fully selected (macOS-like)
  f.cursor_blink   = 0
  f.last_lmb       = false
  f.dragging       = false
  f.last_click_t   = -1
  f.focused        = true
  return f
end

-- ---- Selection helpers ---------------------------------------------------

function Field:has_selection()
  return self.sel_anchor and self.sel_anchor ~= self.caret
end

function Field:selection_range()
  if not self:has_selection() then return nil, nil end
  local a, b = self.sel_anchor, self.caret
  if a > b then a, b = b, a end
  return a, b
end

function Field:clear_selection()
  self.sel_anchor = nil
end

function Field:select_all()
  self.sel_anchor = 0
  self.caret      = #self.value
  self.cursor_blink = 0
end

function Field:delete_selection()
  local a, b = self:selection_range()
  if not a then return false end
  self.value = self.value:sub(1, a) .. self.value:sub(b + 1)
  self.caret = a
  self:clear_selection()
  return true
end

-- ---- Getters / setters ---------------------------------------------------

function Field:get_value()  return self.value end
function Field:has_focus()  return self.focused end
function Field:set_focus(b) self.focused = b and true or false end

function Field:set_value(s)
  self.value = s or ""
  self:select_all()
end

-- ---- Geometry helpers ----------------------------------------------------

function Field:caret_from_x(px)
  local rel = px - (self.x + self.padding)
  if rel <= 0 then return 0 end
  gfx.setfont(1, self.font, self.font_size)
  local prev_w = 0
  for i = 1, #self.value do
    local w = gfx.measurestr(self.value:sub(1, i))
    if w >= rel then
      if (rel - prev_w) <= (w - rel) then return i - 1 end
      return i
    end
    prev_w = w
  end
  return #self.value
end

function Field:in_field(mx, my)
  return mx >= self.x and mx < self.x + self.w
     and my >= self.y and my < self.y + self.h
end

-- ---- Per-frame update ----------------------------------------------------
-- Returns "enter", "esc", "closed", or nil.

function Field:update(char)
  if not self.focused then
    self.last_lmb = (gfx.mouse_cap & 1) == 1
    return nil
  end

  self.cursor_blink = self.cursor_blink + 1

  -- ---- Mouse ----
  local lmb = (gfx.mouse_cap & 1) == 1
  local mx, my = gfx.mouse_x, gfx.mouse_y

  if lmb and not self.last_lmb then
    if self:in_field(mx, my) then
      local now = r.time_precise and r.time_precise() or os.clock()
      if (now - self.last_click_t) < self.double_click_s then
        self:select_all()
        self.dragging = false
      else
        local pos = self:caret_from_x(mx)
        self.caret      = pos
        self.sel_anchor = pos
        self.dragging   = true
      end
      self.last_click_t = now
      self.cursor_blink = 0
    else
      self:clear_selection()
    end
  elseif lmb and self.last_lmb and self.dragging then
    self.caret = self:caret_from_x(mx)
    self.cursor_blink = 0
  elseif not lmb and self.last_lmb then
    self.dragging = false
    if self.sel_anchor == self.caret then
      self:clear_selection()
    end
  end
  self.last_lmb = lmb

  -- ---- Keyboard ----
  if char == nil or char == 0 then return nil end
  if char == -1 then return "closed" end
  if char == 27 then return "esc"    end
  if char == 13 then return "enter"  end

  local mc    = gfx.mouse_cap
  local cmd   = (mc & 4)  ~= 0
  local shift = (mc & 8)  ~= 0
  local opt   = (mc & 16) ~= 0

  -- Cmd / Ctrl + A → select all. Also accept the legacy ASCII control
  -- code 1 (Ctrl+A) which some REAPER builds emit on macOS.
  if char == 1 or (cmd and (char == 65 or char == 97)) then
    self:select_all()
    return nil
  end

  local function move_caret(new_caret)
    if shift then
      if not self.sel_anchor then self.sel_anchor = self.caret end
    else
      self:clear_selection()
    end
    self.caret = new_caret
    self.cursor_blink = 0
  end

  if char == 8 then                                  -- Backspace
    if not self:delete_selection() then
      if self.caret > 0 then
        self.value = self.value:sub(1, self.caret - 1) .. self.value:sub(self.caret + 1)
        self.caret = self.caret - 1
      end
    end
    self.cursor_blink = 0
  elseif char == M.KEY_DEL then                      -- Forward Delete
    if not self:delete_selection() then
      if self.caret < #self.value then
        self.value = self.value:sub(1, self.caret) .. self.value:sub(self.caret + 2)
      end
    end
    self.cursor_blink = 0
  elseif char == M.KEY_LEFT then
    local new_caret
    if cmd then
      new_caret = 0
    elseif opt then
      new_caret = word_left(self.value, self.caret)
    elseif self:has_selection() and not shift then
      local a = self:selection_range()
      new_caret = a or self.caret
    else
      new_caret = math.max(0, self.caret - 1)
    end
    move_caret(new_caret)
  elseif char == M.KEY_RIGHT then
    local new_caret
    if cmd then
      new_caret = #self.value
    elseif opt then
      new_caret = word_right(self.value, self.caret)
    elseif self:has_selection() and not shift then
      local _, b = self:selection_range()
      new_caret = b or self.caret
    else
      new_caret = math.min(#self.value, self.caret + 1)
    end
    move_caret(new_caret)
  elseif char == M.KEY_HOME then
    move_caret(0)
  elseif char == M.KEY_END then
    move_caret(#self.value)
  elseif (not cmd) and self.char_filter(char) then   -- printable, filtered
    self:delete_selection()
    if #self.value < self.max_len then
      self.value = self.value:sub(1, self.caret) .. string.char(char) .. self.value:sub(self.caret + 1)
      self.caret = self.caret + 1
    end
    self.cursor_blink = 0
  end

  return nil
end

-- ---- Draw ----------------------------------------------------------------

function Field:draw()
  local C = self.colors

  -- Background + double-stroke focus border
  set_col(C.bg)
  gfx.rect(self.x, self.y, self.w, self.h, true)
  set_col(C.border)
  gfx.rect(self.x,     self.y,     self.w,     self.h,     false)
  gfx.rect(self.x + 1, self.y + 1, self.w - 2, self.h - 2, false)

  gfx.setfont(1, self.font, self.font_size)
  local text_y = self.y + (self.h - self.font_size) // 2

  local sel_a, sel_b = self:selection_range()

  -- Selection highlight rect
  if sel_a then
    local x_a = gfx.measurestr(self.value:sub(1, sel_a))
    local x_b = gfx.measurestr(self.value:sub(1, sel_b))
    set_col(C.sel_bg)
    gfx.rect(self.x + self.padding + x_a, self.y + 5,
             (x_b - x_a) + 1, self.h - 10, true)
  end

  -- Text (two-tone if selected)
  if sel_a then
    set_col(C.text)
    gfx.x, gfx.y = self.x + self.padding, text_y
    gfx.drawstr(self.value:sub(1, sel_a))
    set_col(C.sel_text)
    gfx.drawstr(self.value:sub(sel_a + 1, sel_b))
    set_col(C.text)
    gfx.drawstr(self.value:sub(sel_b + 1))
  else
    set_col(C.text)
    gfx.x, gfx.y = self.x + self.padding, text_y
    gfx.drawstr(self.value)
  end

  -- Caret
  if not sel_a and self.focused and (self.cursor_blink % 60) < 30 then
    local cw = gfx.measurestr(self.value:sub(1, self.caret))
    set_col(C.cursor)
    gfx.rect(self.x + self.padding + cw, self.y + 6,
             2, self.h - 12, true)
  end
end

return M
