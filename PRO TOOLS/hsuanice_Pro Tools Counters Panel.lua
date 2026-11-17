--[[
@description hsuanice_Pro Tools Counters Panel
@version 26.1118.0047pre1
@author hsuanice
@noindex
@changelog
  - Link on: loop points made on their own (dragged in the ruler) clear razor areas that no longer match them (Pro Tools: one selection).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Pro Tools style counters in one dockable window (native gfx), laid out like the
  Pro Tools Edit window counters and transport:

    Edit Selection | Grid / Nudge     | Pre-roll / Post-roll | Timeline Selection
    Start          | Grid   (click)   | Pre-roll  (click)    | Start
    End            | Nudge  (click)   | Post-roll (click)    | End
    Length         | Items:       n   | Tracks:          n   | Length

  - Edit Selection: razor areas, else the time selection (none: the edit cursor).
  - Timeline Selection: the loop points (none: the Time marker (9999) with Link off, else the
    edit cursor). The marker is removed when there are loop points or Link is on.
  - Link on: loop points made on their own (dragged in the ruler) replace the Edit range - razor
    areas that no longer match them are cleared (Pro Tools: one selection).
  - Grid / Nudge: click to choose (same settings as the Grid Nudge Panel and the Nudge actions).
  - Items / Tracks: selected item / track counts. Click either to open / close the item details
    in their own floating window (MIDI / Audio / Empty items, channel counts); computed only
    while open. Hover over them for a reminder.
  - Pre-roll / Post-roll: click the name to turn it on / off (green = on), click the value to
    type a new length. Hover for a reminder. Global setting, used by Play To / From / Through Edit Start / End.
  - Too narrow for one row: the sections wrap onto more rows.
  - Right-click: time format, font size, dock / undock, close. Dock state, position, font size
    and time format are remembered.

  Combines hsuanice's "Grid Nudge Panel" and "Count Items and Tracks - Selection HUD"
  (copied in, so the PT2Reaper set stays self-contained).
  Inspired by the Pro Tools counters and transport. Optional: js_ReaScriptAPI gives the
  keyboard focus back to the arrange view after a click.
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local function load(name)
  local ok, lib = pcall(dofile, DIR .. name)
  if not ok or type(lib) ~= 'table' then
    r.ShowMessageBox('Could not load ' .. name .. '\n\n' .. tostring(lib), 'Counters Panel', 0)
    return nil
  end
  return lib
end
local Grid, Nudge, T = load('hsuanice_PT_Grid.lua'), load('hsuanice_PT_Nudge.lua'), load('hsuanice_PT_Transport.lua')
local SM = load('hsuanice_PT_SelectionMemory.lua') -- Restore Last Selection (Cmd+Opt+Z)
if not (Grid and Nudge and T and SM) then return end

local NS = 'hsuanice_PT_CountersPanel'
local TITLE = 'Pro Tools Counters'

------------------------------------------------------------
-- Settings
------------------------------------------------------------
local function num(k, d) return tonumber(r.GetExtState(NS, k)) or d end
local font_size    = num('font_size', 14)
local time_mode    = num('time_mode', -1) -- format_timestr: -1 ruler, 5 TC, 0 m:s, 2 bars, 3 sec, 4 smp
local dock_state   = num('dock', 0)
local win_x, win_y = num('x', 200), num('y', 200)

local function save_state()
  r.SetExtState(NS, 'font_size', tostring(font_size), true)
  r.SetExtState(NS, 'time_mode', tostring(time_mode), true)
  r.SetExtState(NS, 'dock', tostring(dock_state), true)
  r.SetExtState(NS, 'x', tostring(win_x), true)
  r.SetExtState(NS, 'y', tostring(win_y), true)
end

------------------------------------------------------------
-- Colors / layout
------------------------------------------------------------
local C = {
  bg = { 0.10, 0.10, 0.10 }, sep = { 0.25, 0.25, 0.25 },
  label = { 0.55, 0.55, 0.55 }, value = { 0.00, 0.87, 0.00 }, text = { 0.87, 0.87, 0.87 },
  accent = { 0.60, 0.80, 1.00 }, on_bg = { 0.20, 0.55, 0.15 }, off_txt = { 0.40, 0.40, 0.40 },
}
local PAD, GAP, COLGAP = 8, 10, 14
local function col(c) gfx.set(c[1], c[2], c[3], 1) end
local function setfont() gfx.setfont(1, 'Arial', font_size) end
local function lh() return font_size + 6 end

------------------------------------------------------------
-- Nudge value text (copied from hsuanice_Grid Nudge Panel)
------------------------------------------------------------
local function format_nudge_value(mode, preset)
  if not preset then return '?' end
  local fps = r.TimeMap_curFrameRate(0) -- returns fps first
  if not fps or fps <= 0 then fps = 24 end
  if mode == 'Timecode' then
    if preset.unit == 1 then return '00:00:01:00.00' end
    local frames = preset.value
    local whole_f = math.floor(frames)
    local sub = frames - whole_f
    local secs = math.floor(whole_f / fps)
    local ff = whole_f % fps
    local mm = math.floor(secs / 60); local ss = secs % 60
    local hh = math.floor(mm / 60); mm = mm % 60
    return string.format('%02d:%02d:%02d:%02d.%02d', hh, mm, ss, ff, math.floor(sub * 100 + 0.5))
  elseif mode == 'Feet+Frames' then
    if preset.label == '1 foot' then return '1+00.00' end
    local f = preset.value
    if f < 1 then return string.format('0+00.%02d', math.floor(f * 100)) end
    return string.format('0+%02d.00', math.floor(f))
  elseif mode == 'Min:Secs' then
    local ms = preset.unit == 1 and (preset.value * 1000) or preset.value
    local total_s = math.floor(ms / 1000)
    local rem_ms = math.floor(ms % 1000)
    local mm = math.floor(total_s / 60); local ss = total_s % 60
    return string.format('%02d:%02d.%03d', mm, ss, rem_ms)
  elseif mode == 'Measure' then
    if preset.unit == 16 then
      local bars = math.floor(preset.value)
      if bars >= 1 then return string.format('%d|00|000', bars) end
      return '0|01|000'
    end
    local ticks = ({ [10] = 1920, [9] = 960, [8] = 480, [7] = 240, [6] = 120, [5] = 60 })[preset.unit] or 960
    if ticks >= 960 then return string.format('0|%02d|000', ticks // 960) end
    return string.format('0|00|%03d', ticks)
  elseif mode == 'Samples' then
    return tostring(math.floor(preset.value))
  end
  return preset.label
end

------------------------------------------------------------
-- Data (rescanned only when something changed)
------------------------------------------------------------
local D = { edit = {}, tl = {}, items = 0, tracks = 0 }
local last_key, last_detail_key, next_scan = nil, nil, 0
local last_loop, last_razor, razor_since = nil, nil, 0

-- Link on (Pro Tools: one selection): a new Timeline range made on its own (loop points
-- dragged in the ruler, set by a script) replaces the Edit range - razor areas that no longer
-- match it are cleared. Only when the razor areas did not change just before (a razor drag
-- copied to the loop points by another script is not a new Timeline range).
local function linked_loop_clears_razor(now, ls, le)
  local rs, re = T.razor_range()
  local lk = string.format('%s|%s', ls or '-', le or '-')
  local rk = string.format('%s|%s', rs or '-', re or '-')
  if rk ~= last_razor then razor_since = now end
  if last_loop and lk ~= last_loop and rk == last_razor and rs and T.linked() and now - razor_since > 0.3
    and not (ls and math.abs(ls - rs) < 1e-6 and math.abs(le - re) < 1e-6) then
    r.Main_OnCommand(42406, 0) -- Razor edit: Clear all areas
    rk = '-|-'
  end
  last_loop, last_razor = lk, rk
end

local function pos(t) return r.format_timestr_pos(t, '', time_mode) end
local function len(a, b) return r.format_timestr_len(b - a, '', a, time_mode) end
local function triple(a, b) return { pos(a), pos(b), len(a, b) } end

local function scan(now)
  if now < next_scan then return end
  next_scan = now + 0.1
  SM.watch(now) -- remembers the previous Edit Selection for Restore Last Selection
  local cur = r.GetCursorPosition()
  local ls, le = T.timeline_range()
  linked_loop_clears_razor(now, ls, le)
  local es, ee = T.edit_range()
  local key = table.concat({ r.GetProjectStateChangeCount(0), r.CountSelectedMediaItems(0),
    r.CountSelectedTracks(0), cur, es or '-', ee or '-', ls or '-', le or '-', time_mode,
    r.GetExtState(T.NS, 'preroll'), r.GetExtState(T.NS, 'postroll'),
    r.GetExtState(T.NS, 'preroll_on'), r.GetExtState(T.NS, 'postroll_on'), T.linked() and 1 or 0 }, '|')
  if key == last_key then return end
  last_key = key
  -- the Time marker (Link off, no Timeline Selection) is the Timeline position; with a
  -- Timeline Selection or Link on it is not needed: removed
  local _, tp = T.time_marker()
  if tp and (ls or T.linked()) then T.clear_time_pos(); tp = nil end
  D.items, D.tracks = r.CountSelectedMediaItems(0), r.CountSelectedTracks(0)
  D.edit = es and triple(es, ee) or triple(cur, cur)
  D.tl = ls and triple(ls, le) or triple(tp or cur, tp or cur)
end

------------------------------------------------------------
-- Sections: each = list of rows { label, value, kind, on_label, on_value }
------------------------------------------------------------
local function refocus_main()
  if r.JS_Window_SetFocus then r.JS_Window_SetFocus(r.GetMainHwnd()) end -- js_ReaScriptAPI (optional)
end

local function menu_at(items)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  return gfx.showmenu(table.concat(items, '|'))
end

local function grid_menu()
  local mode, idx = Grid.get_state()
  local presets = Grid.PRESETS[mode] or {}
  local items = {}
  for i, p in ipairs(presets) do items[#items + 1] = (i == idx and '!' or '') .. p.label end
  items[#items + 1] = ''
  for _, m in ipairs(Grid.MODES) do items[#items + 1] = (m == mode and '!' or '') .. m end
  local ret = menu_at(items)
  if ret == 0 then return end
  if ret <= #presets then
    if Grid.ensure_tempo(mode, presets[ret]) then Grid.apply(mode, ret) end
  else
    local m = Grid.MODES[ret - #presets]
    if m and m ~= mode then
      local di = Grid.get_default_idx(m)
      if Grid.ensure_tempo(m, Grid.get_preset(m, di)) then Grid.apply(m, di) end
    end
  end
end

local function nudge_menu()
  local mode, idx = Nudge.get_state()
  local presets = Nudge.PRESETS[mode]
  local items = {}
  for i, p in ipairs(presets) do items[#items + 1] = (i == idx and '!' or '') .. p.label end
  items[#items + 1] = ''
  for _, m in ipairs(Nudge.MODES) do items[#items + 1] = (m == mode and '!' or '') .. m end
  local ret = menu_at(items)
  if ret == 0 then return end
  if ret <= #presets then Nudge.set_state(mode, ret)
  elseif Nudge.MODES[ret - #presets] then Nudge.set_state(Nudge.MODES[ret - #presets], 1) end
end

local function roll_value(which)
  local sec, on = T.roll(which)
  return r.format_timestr_len(sec, '', 0, time_mode), on
end

local function edit_roll(which)
  local sec = T.roll(which)
  local name = which == 'preroll' and 'Pre-roll' or 'Post-roll'
  local ok, v = r.GetUserInputs(name, 1, name .. ' length:,extrawidth=80',
    r.format_timestr_len(sec, '', 0, time_mode))
  if not ok then return end
  local t = r.parse_timestr_len(v, 0, time_mode)
  if t == 0 and tonumber(v) then t = tonumber(v) end -- plain seconds
  if t then T.set_roll(which, t); last_key = nil end
end

local function toggle_roll(which)
  local _, on = T.roll(which)
  T.set_roll(which, nil, not on); last_key = nil
end

-- Selection details (MIDI / Audio / Empty, channel counts) open in their own floating
-- window: hsuanice_PT_Counters Details.lua (runs only while it is open)
local DETAILS_SCRIPT = DIR .. 'hsuanice_PT_Counters Details.lua'
local function details_open()
  local hb = tonumber(r.GetExtState(NS, 'details_hb'))
  return hb ~= nil and r.time_precise() - hb < 1
end
local function toggle_details()
  if details_open() then
    r.SetExtState(NS, 'details_close', '1', false)
  else
    r.SetExtState(NS, 'details_close', '', false)
    local cmd = r.AddRemoveReaScript(true, 0, DETAILS_SCRIPT, true)
    if cmd and cmd ~= 0 then r.Main_OnCommand(cmd, 0) end
  end
end

local function sections()
  local S = {}
  S[#S + 1] = { { 'Start', D.edit[1] }, { 'End', D.edit[2] }, { 'Length', D.edit[3] } }
  local mode, idx = Nudge.get_state()
  S[#S + 1] = {
    { 'Grid', Grid.get_text(), nil, grid_menu, grid_menu, 'grid' },
    { 'Nudge', format_nudge_value(mode, Nudge.get_preset(mode, idx)), nil, nudge_menu, nudge_menu, 'nudge' },
    { 'Items:', tostring(D.items), 'count', toggle_details, toggle_details },
  }
  local pre, pre_on = roll_value('preroll')
  local post, post_on = roll_value('postroll')
  S[#S + 1] = {
    { 'Pre-roll', pre, pre_on and 'on' or 'off', function() toggle_roll('preroll') end, function() edit_roll('preroll') end, 'preroll' },
    { 'Post-roll', post, post_on and 'on' or 'off', function() toggle_roll('postroll') end, function() edit_roll('postroll') end, 'postroll' },
    { 'Tracks:', tostring(D.tracks), 'count', toggle_details, toggle_details },
  }
  S[#S + 1] = { { 'Start', D.tl[1] }, { 'End', D.tl[2] }, { 'Length', D.tl[3] } }
  return S
end

------------------------------------------------------------
-- Layout + draw (sections wrap onto more rows when the window is narrow)
------------------------------------------------------------
local hits = {} -- { x, y, w, h, fn }

local function measure(sec)
  local lw, vw, cw = 0, 0, 0
  for i = 1, 3 do
    local row = sec[i]
    if row then
      if row[3] == 'count' then
        -- counts span the column (name left, number right) and do not set its width:
        -- the number grows to the left, nothing moves. Room for 5 digits.
        cw = math.max(cw, gfx.measurestr(row[1]) + GAP + gfx.measurestr('88888'))
      else
        lw = math.max(lw, gfx.measurestr(row[1]))
        vw = math.max(vw, gfx.measurestr(row[2]))
      end
    end
  end
  return lw, vw, math.max(lw + GAP + vw, cw)
end

local function layout(S)
  local out, x, y, band_h = {}, PAD, PAD, 3 * lh()
  for _, sec in ipairs(S) do
    local lw, vw, w = measure(sec)
    if x > PAD and x + w > gfx.w - PAD then x = PAD; y = y + band_h + PAD end
    out[#out + 1] = { sec = sec, x = x, y = y, lw = lw, vw = vw, w = w }
    x = x + w + COLGAP
  end
  return out, y + band_h + PAD
end

local function want_size()
  setfont()
  local S = sections()
  local w = PAD
  for _, sec in ipairs(S) do local _, _, sw = measure(sec); w = w + sw + COLGAP end
  return w - COLGAP + PAD, PAD * 2 + 3 * lh()
end

local function draw()
  setfont()
  col(C.bg); gfx.rect(0, 0, gfx.w, gfx.h, 1)
  hits = {}
  local L = layout(sections())
  local h = lh()
  for k, b in ipairs(L) do
    if k > 1 and L[k - 1].y == b.y then
      col(C.sep); gfx.rect(b.x - COLGAP // 2 - 1, b.y, 1, 3 * h - 4, 1)
    end
    for i = 1, 3 do
      local row = b.sec[i]
      if row then
        local y = b.y + (i - 1) * h
        local label, value, kind = row[1], row[2], row[3]
        if kind == 'count' then
          -- own zone: a line above it (separates it from Grid / Nudge, Pre / Post-roll)
          col(C.sep); gfx.rect(b.x - COLGAP // 2, y - 3, b.w + COLGAP, 1, 1)
          col(C.text); gfx.x, gfx.y = b.x, y; gfx.drawstr(label)
          gfx.x = b.x + b.w - gfx.measurestr(value); gfx.drawstr(value)
        else
          if kind == 'on' then
            local tw = gfx.measurestr(label)
            col(C.on_bg); gfx.rect(b.x - 3, y - 1, tw + 6, h - 4, 1)
            col({ 0.92, 1, 0.88 })
          elseif kind == 'off' then col(C.off_txt)
          else col(C.label) end
          gfx.x, gfx.y = b.x, y; gfx.drawstr(label)
          col(kind == 'detail' and C.text or kind == 'off' and C.off_txt or C.value)
          gfx.x = b.x + b.w - gfx.measurestr(value); gfx.drawstr(value)
        end
        local f_label, f_value = row[4], row[5]
        if kind == 'count' then
          hits[#hits + 1] = { b.x, y, b.w, h, f_label, 'details' }
        else
          local tip = row[6] -- hover info key (Grid, Nudge, Pre-roll, Post-roll)
          if f_label then hits[#hits + 1] = { b.x, y, b.lw + GAP // 2, h, f_label, tip and (tip .. ':name') } end
          if f_value then hits[#hits + 1] = { b.x + b.lw + GAP // 2, y, b.w - b.lw - GAP // 2, h, f_value, tip and (tip .. ':value') } end
        end
      end
    end
  end
end

------------------------------------------------------------
-- Window
------------------------------------------------------------
local cur_w, cur_h = 0, 0
local function fit_floating()
  if gfx.dock(-1) ~= 0 then return end
  local w, h = want_size()
  if w == cur_w and h == cur_h then return end
  cur_w, cur_h = w, h
  local _, x, y = gfx.dock(-1, 0, 0, 0, 0) -- window position as gfx.init wants it
  gfx.init(TITLE, w, h, 0, x, y)
end

local function context_menu()
  local function m(v, cur) return v == cur and '!' or '' end
  local docked = gfx.dock(-1) ~= 0
  local items = {
    m(-1, time_mode) .. 'Time: Follow ruler', m(5, time_mode) .. 'Time: Timecode',
    m(0, time_mode) .. 'Time: Min:Secs', m(2, time_mode) .. 'Time: Measures.Beats',
    m(3, time_mode) .. 'Time: Seconds', m(4, time_mode) .. 'Time: Samples', '',
    m(12, font_size) .. 'Font: Small', m(14, font_size) .. 'Font: Medium',
    m(16, font_size) .. 'Font: Large', m(20, font_size) .. 'Font: XL', '',
    docked and 'Undock' or 'Dock', 'Close',
  }
  local ret = menu_at(items)
  local modes = { -1, 5, 0, 2, 3, 4 }
  local fonts = { 12, 14, 16, 20 }
  if ret >= 1 and ret <= 6 then time_mode = modes[ret]; last_key = nil; cur_w = 0
  elseif ret >= 7 and ret <= 10 then font_size = fonts[ret - 6]; cur_w = 0
  elseif ret == 11 then
    if docked then gfx.dock(0) else gfx.dock(1) end
    cur_w = 0
  elseif ret == 12 then return true end
end

-- Hover info (native tooltip, shown outside the window - not cut by a short docker)
local tip_zone, tip_since, tip_shown = nil, 0, nil
local function hover_tip()
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local zone
  for _, hz in ipairs(hits) do
    if hz[6] and mx >= hz[1] and mx < hz[1] + hz[3] and my >= hz[2] and my < hz[2] + hz[4] then zone = hz[6]; break end
  end
  if zone ~= tip_zone then tip_zone, tip_since = zone, r.time_precise() end
  local text
  if zone and r.time_precise() - tip_since > 0.5 then
    if zone == 'details' then
      text = details_open() and 'Click to close the item details window'
        or 'Click to open the item details window\n(MIDI / Audio / Empty items, channel counts).\nClick again to close it.'
    elseif zone:match('^grid:') then
      text = 'Click to choose the Grid value or mode\n(the same Grid as the Pro Tools Grid actions).'
    elseif zone:match('^nudge:') then
      text = 'Click to choose the Nudge value or mode\n(used by the Pro Tools Nudge actions).'
    else
      local which, part = zone:match('^(%a+):(%a+)$')
      local name = which == 'preroll' and 'Pre-roll' or 'Post-roll'
      local _, on = T.roll(which)
      if part == 'name' then
        text = 'Click to turn ' .. name .. ' ' .. (on and 'off' or 'on') .. '\n(now ' .. (on and 'on' or 'off')
          .. '; green = on).\nUsed by Play To / From / Through Edit Start / End.'
      else
        text = 'Click to type the ' .. name .. ' length.'
      end
    end
  end
  if text ~= tip_shown then
    if text then
      local sx, sy = gfx.clienttoscreen(mx + 12, my + 16)
      r.TrackCtl_SetToolTip(text, sx, sy, true)
    else
      r.TrackCtl_SetToolTip('', 0, 0, true)
    end
    tip_shown = text
  end
end

-- A project was opened / another project tab chosen (or REAPER started): REAPER loads the
-- grid stored in that project; put the Grid the user chose back (Pro Tools: the Grid
-- follows the user). Only when it differs.
local last_proj
local function follow_project()
  local proj, fn = r.EnumProjects(-1)
  local key = tostring(proj) .. '|' .. (fn or '')
  if key == last_proj then return end
  last_proj = key
  SM.reset() -- the remembered Edit Selections belong to the other project
  if Grid.restore_saved() then last_key = nil end
end

local prev_cap = 0
local function loop()
  local char = gfx.getchar()
  if char == -1 then return end
  follow_project()
  scan(r.time_precise())
  fit_floating()
  draw()

  local cap = gfx.mouse_cap
  if cap & 1 == 0 and prev_cap & 1 == 1 then -- left click (on release)
    local mx, my = gfx.mouse_x, gfx.mouse_y
    for _, hz in ipairs(hits) do
      if mx >= hz[1] and mx < hz[1] + hz[3] and my >= hz[2] and my < hz[2] + hz[4] then
        hz[5](); last_key = nil
        break
      end
    end
    refocus_main()
  end
  if cap & 2 == 0 and prev_cap & 2 == 2 then -- right click
    if context_menu() then gfx.quit(); return end
    refocus_main()
  end
  prev_cap = cap & 3
  hover_tip()

  -- remember where the window is: docked (dock state) or floating (position)
  dock_state = gfx.dock(-1)
  if dock_state == 0 then local _, x, y = gfx.dock(-1, 0, 0, 0, 0); win_x, win_y = x, y end
  gfx.update()
  r.defer(loop)
end

local _, _, sec, cmd = r.get_action_context()
r.SetToggleCommandState(sec, cmd, 1)
r.RefreshToolbar2(sec, cmd)
r.atexit(function()
  save_state()
  r.SetToggleCommandState(sec, cmd, 0)
  r.RefreshToolbar2(sec, cmd)
end)

T.refresh_follows_button() -- after a restart the N / Cmd+K buttons show the saved state again
T.refresh_rolls_button()
gfx.init(TITLE, 600, PAD * 2 + 3 * lh(), dock_state, win_x, win_y)
loop()
