--[[
@description hsuanice_PT_Counters Details - selected items in detail (PT2Reaper Counters Panel)
@version 26.1116.1945pre1
@author hsuanice
@noindex
@changelog
  - First version.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Floating window opened / closed by clicking Items / Tracks in the Counters Panel:
  selected items by type (MIDI / Audio / Empty) and by channel count.
  Counts only while open (closed: nothing is computed). Remembers its position and size.
  Based on hsuanice's "Count Items and Tracks - Selection HUD".
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local NS = 'hsuanice_PT_CountersPanel' -- shared with the Counters Panel
local TITLE = 'Pro Tools Counters - Details'

-- launched again while open: end (no "task control" dialog)
if r.set_action_options then r.set_action_options(1) end

local function num(k, d) return tonumber(r.GetExtState(NS, k)) or d end
local font_size = num('font_size', 14)
local x0, y0 = num('details_x', 300), num('details_y', 300)
local PAD = 8
local function lh() return font_size + 6 end

local data = { items = 0, types = { midi = 0, audio = 0, empty = 0 }, channels = {} }
local last_key, next_scan = nil, 0

local function scan(now)
  if now < next_scan then return end
  next_scan = now + 0.15
  local n = r.CountSelectedMediaItems(0)
  local key = r.GetProjectStateChangeCount(0) .. '|' .. n
  if key == last_key then return end
  last_key = key
  local types, chs = { midi = 0, audio = 0, empty = 0 }, {}
  for i = 0, n - 1 do
    local take = r.GetActiveTake(r.GetSelectedMediaItem(0, i))
    if not take then
      types.empty = types.empty + 1
    else
      local src = r.GetMediaItemTake_Source(take)
      local st = r.GetMediaSourceType(src, '')
      if st == 'MIDI' or st == 'REX' then types.midi = types.midi + 1 else types.audio = types.audio + 1 end
      local ch = r.GetMediaSourceNumChannels(src) or 0
      if ch > 0 then chs[ch] = (chs[ch] or 0) + 1 end
    end
  end
  data = { items = n, types = types, channels = chs }
end

local function rows()
  local out = {
    { 'MIDI', data.types.midi }, { 'Audio', data.types.audio }, { 'Empty', data.types.empty },
    { '' }, { 'Channel count', nil, true },
  }
  local chl = {}
  for ch, n in pairs(data.channels) do chl[#chl + 1] = { ch, n } end
  table.sort(chl, function(a, b) return a[1] < b[1] end)
  for _, e in ipairs(chl) do
    out[#out + 1] = { e[1] == 1 and 'Mono' or e[1] == 2 and 'Stereo' or (e[1] .. '-Ch'), e[2] }
  end
  if #chl == 0 then out[#out + 1] = { '-' } end
  return out
end

local cur_w, cur_h = 0, 0
local function fit(R)
  if gfx.dock(-1) ~= 0 then return end
  local w = 160
  for _, row in ipairs(R) do
    w = math.max(w, gfx.measurestr(row[1]) + 20 + (row[2] and gfx.measurestr(tostring(row[2])) or 0))
  end
  w = w + PAD * 2
  local h = PAD * 2 + #R * lh()
  if w == cur_w and h == cur_h then return end
  cur_w, cur_h = w, h
  local x, y = gfx.clienttoscreen(0, 0)
  gfx.init(TITLE, w, h, 0, x, y)
end

local function draw(R)
  gfx.set(0.10, 0.10, 0.10, 1); gfx.rect(0, 0, gfx.w, gfx.h, 1)
  for i, row in ipairs(R) do
    local y = PAD + (i - 1) * lh()
    if row[3] then gfx.set(1, 1, 1, 1) else gfx.set(0.55, 0.55, 0.55, 1) end
    gfx.x, gfx.y = PAD, y; gfx.drawstr(row[1])
    if row[2] then
      local v = tostring(row[2])
      gfx.set(0.87, 0.87, 0.87, 1)
      gfx.x = gfx.w - PAD - gfx.measurestr(v); gfx.drawstr(v)
    end
  end
end

local px, py = x0, y0 -- last known position (the window may already be gone at exit)
local function save()
  r.SetExtState(NS, 'details_x', tostring(px), true); r.SetExtState(NS, 'details_y', tostring(py), true)
end

local function loop()
  if gfx.getchar() < 0 or r.GetExtState(NS, 'details_close') == '1' then
    save(); gfx.quit(); return
  end
  r.SetExtState(NS, 'details_hb', string.format('%.3f', r.time_precise()), false)
  if gfx.dock(-1) == 0 then px, py = gfx.clienttoscreen(0, 0) end
  font_size = num('font_size', 14)
  gfx.setfont(1, 'Arial', font_size)
  scan(r.time_precise())
  local R = rows()
  fit(R)
  draw(R)
  if gfx.mouse_cap & 2 == 2 then save(); gfx.quit(); return end -- right-click closes
  gfx.update()
  r.defer(loop)
end

r.atexit(function()
  r.SetExtState(NS, 'details_hb', '', false)
  r.SetExtState(NS, 'details_close', '', false)
end)
r.SetExtState(NS, 'details_close', '', false)
gfx.init(TITLE, 180, 200, 0, x0, y0)
loop()
