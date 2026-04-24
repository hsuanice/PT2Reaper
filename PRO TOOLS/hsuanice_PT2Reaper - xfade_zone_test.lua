-- hsuanice_PT2Reaper - xfade_zone_test.lua
-- Test script: inspect crossfade detection and zone boundaries on selected items.
-- Detects both manual fades (D_FADEINLEN/D_FADEOUTLEN) and
-- auto-crossfade fades (D_FADEINLEN_AUTO/D_FADEOUTLEN_AUTO).
-- Auto values override manual when non-zero (REAPER behaviour).

local r   = reaper
local EPS = 1e-4

local function f(n) return string.format('%.5f', n) end

-- Effective fade lengths: AUTO overrides manual when non-zero
local function get_fi(item)
  local auto = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO')
  local man  = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
  return auto > EPS and auto or man, man, auto
end

local function get_fo(item)
  local auto = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO')
  local man  = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
  return auto > EPS and auto or man, man, auto
end

-- ── detection (mirrors NudgeEdge — using effective fades) ────────────────────

local function find_left_xfade(track, item)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local item_e = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local best, best_end = nil, -math.huge
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local other = r.GetTrackMediaItem(track, i)
    if other ~= item then
      local op    = r.GetMediaItemInfo_Value(other, 'D_POSITION')
      local oe    = op + r.GetMediaItemInfo_Value(other, 'D_LENGTH')
      local o_fo  = get_fo(other)  -- effective fo_len
      if op < pos - EPS and oe > pos + EPS and oe < item_e - EPS and o_fo > EPS then
        if oe > best_end then best = other; best_end = oe end
      end
    end
  end
  return best
end

local function find_right_xfade(track, item)
  local pos    = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len    = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local fo_len = get_fo(item)  -- effective fo_len
  local item_e    = pos + len
  local fo_start  = item_e - fo_len
  local search_from = fo_len > EPS and fo_start or pos
  local best, best_pos = nil, math.huge
  for i = 0, r.CountTrackMediaItems(track) - 1 do
    local other = r.GetTrackMediaItem(track, i)
    if other ~= item then
      local op = r.GetMediaItemInfo_Value(other, 'D_POSITION')
      local oe = op + r.GetMediaItemInfo_Value(other, 'D_LENGTH')
      if op >= search_from - EPS and op < item_e - EPS and oe > item_e - EPS then
        if op < best_pos then best = other; best_pos = op end
      end
    end
  end
  return best
end

-- ── helpers ──────────────────────────────────────────────────────────────────

local function item_label(item)
  local take = r.GetActiveTake(item)
  if take then
    local _, name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
    if name and name ~= '' then return '"' .. name .. '"' end
  end
  return '(no name)'
end

local function track_label(track)
  local _, name = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
  return (name and name ~= '') and ('"' .. name .. '"') or '(unnamed)'
end

local function selected_mark(item)
  return r.IsMediaItemSelected(item) and ' [SELECTED]' or ''
end

local function fade_str(eff, man, auto)
  if auto > EPS and man > EPS then
    return string.format('%s  (manual=%s  AUTO=%s ← active)', f(eff), f(man), f(auto))
  elseif auto > EPS then
    return string.format('%s  (AUTO)', f(eff))
  elseif man > EPS then
    return string.format('%s  (manual)', f(eff))
  else
    return '0.00000  (none)'
  end
end

-- ── main ─────────────────────────────────────────────────────────────────────

local n = r.CountSelectedMediaItems(0)
if n == 0 then
  r.ShowConsoleMsg('No items selected.\n')
  return
end

local out = {}
local function p(s) out[#out+1] = s end

p('╔══════════════════════════════════════════════════════════════════╗')
p('  XFADE ZONE TEST  (effective fades: AUTO overrides manual)')
p('╚══════════════════════════════════════════════════════════════════╝')

local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
if ts_e > ts_s + EPS then
  p(string.format('\nTime selection  : %s → %s  (len=%s)',
    f(ts_s), f(ts_e), f(ts_e - ts_s)))
else
  p('\nTime selection  : none')
end

local razor_tracks = {}
for ti = 0, r.CountTracks(0) - 1 do
  local tr = r.GetTrack(0, ti)
  local _, s = r.GetSetMediaTrackInfo_String(tr, 'P_RAZOREDITS', '', false)
  if s and s ~= '' then
    local rs, re = s:match('(%S+)%s+(%S+)%s+""')
    if rs and re then razor_tracks[tr] = { s = tonumber(rs), e = tonumber(re) } end
  end
end

p('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
p(string.format('Selected items: %d', n))
p('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

for i = 0, n - 1 do
  local item  = r.GetSelectedMediaItem(0, i)
  local track = r.GetMediaItemTrack(item)
  local pos   = r.GetMediaItemInfo_Value(item, 'D_POSITION')
  local len   = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local item_e = pos + len

  local fi_eff, fi_man, fi_auto = get_fi(item)
  local fo_eff, fo_man, fo_auto = get_fo(item)
  local fi_end   = pos + fi_eff
  local fo_start = item_e - fo_eff

  p(string.format('\n[Item %d] %s  (track %s)', i+1, item_label(item), track_label(track)))
  p(string.format('  pos=%s  end=%s  len=%s', f(pos), f(item_e), f(len)))
  p(string.format('  fade-in  : %s', fade_str(fi_eff, fi_man, fi_auto)))
  p(string.format('  fade-out : %s', fade_str(fo_eff, fo_man, fo_auto)))
  p(string.format('  fi_end=%s  fo_start=%s', f(fi_end), f(fo_start)))

  -- Zone boundaries using effective fades
  p(string.format('  Zone P1 (pos)      = %s', f(pos)))
  if fi_eff > EPS then
    p(string.format('  Zone P2 (fi_end)   = %s  [fi=%s]', f(fi_end), f(fi_eff)))
  else
    p(string.format('  Zone P2 (fi_end)   = %s  [no fade-in]', f(fi_end)))
  end
  if fo_eff > EPS then
    p(string.format('  Zone P3 (fo_start) = %s  [fo=%s]', f(fo_start), f(fo_eff)))
  else
    p(string.format('  Zone P3 (fo_start) = %s  [no fade-out → Zone C disabled]', f(fo_start)))
  end

  local rz = razor_tracks[track]
  if rz then
    p(string.format('  Razor  : %s → %s', f(rz.s), f(rz.e)))
    local label
    if     rz.s <= pos      + EPS then label = '→ at/before P1 (pos)'
    elseif rz.s <= fi_end   + EPS then label = '→ in fade-in zone (P1..P2)'
    elseif rz.s <= fo_start + EPS then label = '→ in clip body (P2..P3)'
    elseif rz.s <  item_e   - EPS then label = '→ inside fade-out zone (past P3)'
    else                                label = '→ at/past item end'
    end
    p(string.format('  Razor start : %s', label))
  else
    p('  Razor  : none')
  end

  -- Left xfade (using effective fo_len via find_left_xfade)
  local lxf = find_left_xfade(track, item)
  if lxf then
    local lxf_pos = r.GetMediaItemInfo_Value(lxf, 'D_POSITION')
    local lxf_len = r.GetMediaItemInfo_Value(lxf, 'D_LENGTH')
    local lxf_fo  = get_fo(lxf)
    local lxf_e   = lxf_pos + lxf_len
    local lxf_fos = lxf_e - lxf_fo
    local overlap = lxf_e - pos
    p(string.format('  ◀ LEFT XFADE : %s%s', item_label(lxf), selected_mark(lxf)))
    p(string.format('      A fo_len=%s  A fo_start=%s  overlap=%s', f(lxf_fo), f(lxf_fos), f(overlap)))
    if math.abs(lxf_fos - pos) < EPS then
      p('      fo_start_A ≈ pos_B ✓')
    else
      p(string.format('      fo_start_A %s pos_B by %.5f s',
        lxf_fos < pos and '<' or '>', math.abs(lxf_fos - pos)))
    end
  else
    p('  ◀ LEFT XFADE : none')
    p('      (need: other item ends inside this item AND effective fo_len > 0)')
  end

  -- Right xfade
  local rxf = find_right_xfade(track, item)
  if rxf then
    local rxf_pos = r.GetMediaItemInfo_Value(rxf, 'D_POSITION')
    local rxf_fi  = get_fi(rxf)
    local overlap = item_e - rxf_pos
    p(string.format('  ▶ RIGHT XFADE: %s%s', item_label(rxf), selected_mark(rxf)))
    p(string.format('      B pos=%s  B fi_len=%s  overlap=%s', f(rxf_pos), f(rxf_fi), f(overlap)))
    if math.abs(fo_start - rxf_pos) < EPS then
      p('      fo_start_A ≈ pos_B ✓')
    elseif fo_eff < EPS then
      p(string.format('      fo_len_A=0 (bare overlap): Zone C disabled, right item P1 handles boundary'))
    else
      p(string.format('      fo_start_A %s pos_B by %.5f s',
        fo_start < rxf_pos and '<' or '>', math.abs(fo_start - rxf_pos)))
    end
  else
    p('  ▶ RIGHT XFADE: none')
    if fo_eff < EPS then
      p('      (fo_len=0: searching full item range for overlapping right item — none found)')
    else
      p('      (need: other item starts in fo_start..item_e AND extends past item_e)')
    end
  end
end

-- ── crossfade pair summary ────────────────────────────────────────────────────

p('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
p('CROSSFADE PAIRS')
p('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local pair_count = 0
for i = 0, n - 1 do
  local item  = r.GetSelectedMediaItem(0, i)
  local track = r.GetMediaItemTrack(item)
  local rxf   = find_right_xfade(track, item)
  if rxf then
    pair_count = pair_count + 1
    local pos_A  = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len_A  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local fo_A   = get_fo(item)
    local item_e_A = pos_A + len_A
    local fo_st_A  = item_e_A - fo_A
    local pos_B  = r.GetMediaItemInfo_Value(rxf, 'D_POSITION')
    local fi_B   = get_fi(rxf)
    local overlap = item_e_A - pos_B

    p(string.format('\nPair %d:', pair_count))
    p(string.format('  A (left)  : %s%s', item_label(item), selected_mark(item)))
    p(string.format('  B (right) : %s%s', item_label(rxf),  selected_mark(rxf)))
    p(string.format('  Overlap   : %s → %s  (len=%s)', f(pos_B), f(item_e_A), f(overlap)))
    p(string.format('  A fo_len  : %s   fo_start_A = %s', f(fo_A), f(fo_st_A)))
    p(string.format('  B fi_len  : %s   fi_end_B   = %s', f(fi_B), f(pos_B + fi_B)))

    if fo_A > EPS then
      if math.abs(fo_st_A - pos_B) < EPS then
        p('  → Zone C at fo_start_A = pos_B ✓  full crossfade, atomic nudge ready')
      else
        p(string.format('  → Zone C at fo_start_A=%s  pos_B=%s  (partial fade)', f(fo_st_A), f(pos_B)))
      end
    else
      p('  → fo_len_A = 0: bare overlap — Zone C disabled, B\'s P1 handles boundary')
    end
  end
end

if pair_count == 0 then
  p('\n  No crossfade pairs found.')
  p('  Items must: overlap on the same track, with left item having effective fo_len > 0.')
end

p('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
p('END')
p('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

r.ShowConsoleMsg(table.concat(out, '\n') .. '\n')
