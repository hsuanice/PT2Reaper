--[[
@description hsuanice_PT_Grid - Grid Library
@version 26.1118.1726
@author hsuanice
@noindex
@changelog
  - Release: Frame grid read and switched through projgridframe - the Grid no longer stays on Frame on REAPER 7.86 (tested in REAPER).
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Library for grid mode handling, parallel to hsuanice_PT_Nudge.lua.
  Reads grid mode and preset from hsuanice_Grid Nudge Panel ExtState.

  Modes (parallel to Nudge):
    Measure     - REAPER native bar divisions (no tempo dependence)
    Min:Secs    - simulated via tempo: secs * BPM / 240 = grid_div
    Timecode    - simulated via tempo + project FPS
    Feet+Frames - simulated via tempo + project FPS (1 foot = 16 frames)
    Samples     - simulated via tempo + project sample rate

  Simulated modes assume constant project tempo. ensure_tempo() prompts
  the user to set BPM to 120 (or proceed at current BPM, or cancel).

  "1 frame" presets in Timecode and Feet+Frames are flagged native_frame:
  they engage REAPER's built-in Frame grid (command 40904) instead of
  tempo simulation, so they're exact regardless of tempo. The panel still
  shows the TC string (e.g. "00:00:00:01.00") — the difference is
  internal only.
--]]

local r = reaper
local EXT = 'hsuanice_GridNudgePanel'

local GRID_MODES = {'Measure', 'Min:Secs', 'Timecode', 'Feet+Frames', 'Samples'}

-- Presets are ordered LARGEST -> SMALLEST so increase = idx-1, decrease = idx+1
-- (matches hsuanice_PT_Nudge.lua convention)
local GRID_PRESETS = {
  ['Measure'] = {
    -- Note: REAPER's native "Metronome" dropdown entry isn't a distinct API
    -- state (it just clears Frame/Measure flags back to the last beat
    -- grid_div), so we can't sync it from our side. Use a specific beat
    -- preset (e.g. 1/4) for the same effect.
    {label='4 bars',  div=4},
    {label='2 bars',  div=2},
    {label='1 bar',   div=1},
    {label='1/2',     div=1/2},
    {label='1/4',     div=1/4},
    {label='1/4T',    div=1/(4*1.5)},
    {label='1/8',     div=1/8},
    {label='1/8T',    div=1/(8*1.5)},
    {label='1/16',    div=1/16},
    {label='1/16T',   div=1/(16*1.5)},
    {label='1/32',    div=1/32},
    {label='1/32T',   div=1/(32*1.5)},
    {label='1/64',    div=1/64},
    {label='1/128',   div=1/128},
  },
  ['Min:Secs'] = {
    {label='1 second', unit=1, value=1},
    {label='500 msec', unit=0, value=500},
    {label='100 msec', unit=0, value=100},
    {label='10 msec',  unit=0, value=10},
    {label='1 msec',   unit=0, value=1},
  },
  ['Timecode'] = {
    {label='1 second',    unit=1,  value=1},
    {label='6 frames',    unit=18, value=6},
    {label='1 frame',     unit=18, value=1, native_frame=true},
    {label='1/2 frame',   unit=18, value=0.5},
    {label='1/4 frame',   unit=18, value=0.25},
    {label='1 sub frame', unit=18, value=0.01},
  },
  ['Feet+Frames'] = {
    {label='1 foot',      unit=18, value=16},
    {label='1 frame',     unit=18, value=1, native_frame=true},
    {label='1/4 frame',   unit=18, value=0.25},
    {label='1 sub frame', unit=18, value=0.01},
  },
  ['Samples'] = {
    {label='10000 samples', unit=17, value=10000},
    {label='1000 samples',  unit=17, value=1000},
    {label='100 samples',   unit=17, value=100},
  },
}

-- Smart default preset per mode (used when switching mode via the panel).
-- Prefers native_frame where available so the user lands on a tempo-free
-- preset by default (no tempo prompt on mode switch).
local DEFAULT_IDX = {
  ['Measure']     = 5,  -- "1/4"
  ['Min:Secs']    = 1,  -- "1 second"
  ['Timecode']    = 3,  -- "1 frame"   (native_frame)
  ['Feet+Frames'] = 2,  -- "1 frame"   (native_frame)
  ['Samples']     = 2,  -- "1000 samples"
}

local M = {}

-- REAPER's Frame grid. Read from the project setting "projgridframe" (bit 1): on REAPER
-- 7.86+dev command 40904 is "Grid: Set framerate grid" - it only turns it ON, and its toggle
-- state stays ON (hsuanice's debug log 261118). Turned off by writing the setting (SWS
-- SNM_SetIntConfigVar); without SWS, command 40904 as before.
local function frame_cfg()
  if not r.get_config_var_string then return nil end
  local ok, v = r.get_config_var_string('projgridframe')
  if ok then return tonumber(v) end
end
function M.frame_on()
  local v = frame_cfg()
  if v then return v & 1 == 1 end
  return r.GetToggleCommandState(40904) == 1
end
function M.set_frame(on)
  if M.frame_on() == on then return end
  local v = frame_cfg()
  if v and r.SNM_SetIntConfigVar then
    r.SNM_SetIntConfigVar('projgridframe', on and (v | 1) or (v & ~1))
    r.UpdateTimeline()
    if M.frame_on() == on then return end
  end
  r.Main_OnCommand(40904, 0) -- set / toggle (older REAPER)
end
M.MODES       = GRID_MODES
M.PRESETS     = GRID_PRESETS
M.DEFAULT_IDX = DEFAULT_IDX

function M.get_default_idx(mode)
  return DEFAULT_IDX[mode] or 1
end

-- ============================================================
-- DEBUG LOGGING (gated by ExtState "debug" = "1")
-- Toggle via the Grid Nudge Panel's right-click menu, or:
--   reaper.SetExtState('hsuanice_GridNudgePanel', 'debug', '1', false)
-- Output goes to the ReaScript console (View → Show ReaScript console).
-- ============================================================
local function dbg_enabled()
  return r.GetExtState(EXT, 'debug') == '1'
end

function M.set_debug(on)
  r.SetExtState(EXT, 'debug', on and '1' or '0', false)
  if on then
    r.ShowConsoleMsg('[hsuanice_PT_Grid] debug ON\n')
  end
end

function M.is_debug()
  return dbg_enabled()
end

local function snapshot()
  local frame_on = M.frame_on()
  local _, gd, sw = r.GetSetProjectGrid(0, 0)
  local bpm = r.GetProjectTimeSignature2(0) or 0
  return string.format('frame=%s (projgridframe=%s 40904=%s) grid_div=%.6f swing=%d bpm=%.2f',
    frame_on and 'ON' or 'OFF', tostring(frame_cfg()), r.GetToggleCommandState(40904) == 1 and 'ON' or 'OFF',
    gd or 0, sw or 0, bpm)
end

local function dbg(fmt, ...)
  if not dbg_enabled() then return end
  r.ShowConsoleMsg('[Grid] ' .. string.format(fmt, ...) .. '\n')
end

local function is_valid_mode(m)
  for _, v in ipairs(GRID_MODES) do if v == m then return true end end
  return false
end

function M.get_state()
  local mode = r.GetExtState(EXT, 'grid_mode')
  -- Migrate old key from earlier 0.3.0 design (Native/Timecode dichotomy)
  if mode == 'Native' then mode = 'Measure' end
  if not is_valid_mode(mode) then mode = 'Measure' end
  local presets = GRID_PRESETS[mode]
  local idx = tonumber(r.GetExtState(EXT, 'grid_preset_idx')) or 1
  if idx < 1 then idx = 1 elseif idx > #presets then idx = #presets end
  return mode, idx
end

function M.set_state(mode, idx)
  r.SetExtState(EXT, 'grid_mode',       mode,          true)
  r.SetExtState(EXT, 'grid_preset_idx', tostring(idx), true)
end

function M.get_preset(mode, idx)
  local p = GRID_PRESETS[mode]
  if not p then return nil end
  return p[idx]
end

function M.preset_to_seconds(preset)
  if not preset or not preset.unit then return 0 end
  if preset.unit == 0 then return preset.value / 1000 end
  if preset.unit == 1 then return preset.value end
  if preset.unit == 17 then
    local sr = r.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
    if not sr or sr <= 0 then sr = 48000 end
    return preset.value / sr
  end
  if preset.unit == 18 then
    local fps = r.TimeMap_curFrameRate(0)  -- returns (fps, isdrop)
    if not fps or fps <= 0 then fps = 24 end
    return preset.value / fps
  end
  return 0
end

function M.preset_to_div(mode, preset)
  if not preset then return 1 end
  if mode == 'Measure' then return preset.div end
  local secs = M.preset_to_seconds(preset)
  local bpm  = r.GetProjectTimeSignature2(0)
  if not bpm or bpm <= 0 then bpm = 120 end
  -- 1 bar at 4/4 = 240/BPM seconds → bar_div = secs * BPM / 240
  return secs * bpm / 240
end

-- True when REAPER's project grid is the saved preset (the grid is stored in each project,
-- the preset is global).
function M.in_sync()
  local mode, idx = M.get_state()
  local p = M.get_preset(mode, idx)
  if not p then return true end
  local frame_on = M.frame_on()
  if p.native_frame then return frame_on end
  if frame_on then return false end
  local _, div = r.GetSetProjectGrid(0, 0)
  if div ~= div then return false end
  local expected = M.preset_to_div(mode, p)
  if mode == 'Measure' then return math.abs(div - expected) < 1e-8 end
  return math.abs(div - expected) / math.max(math.abs(expected), 1e-9) < 1e-2
end

-- Pro Tools: the Grid follows the user, not the project. Puts the saved preset back when
-- the current project has another grid (it was saved with it). Writes only on a difference.
-- Returns true when it changed the grid.
function M.restore_saved()
  if M.in_sync() then return false end
  local mode, idx = M.get_state()
  dbg('restore_saved -> %s/%d | %s', mode, idx, snapshot())
  M.apply(mode, idx)
  return true
end

function M.format_value(mode, preset)
  if not preset then return '?' end

  if mode == 'Measure' then return preset.label end

  if mode == 'Timecode' then
    local fps = r.TimeMap_curFrameRate(0)  -- returns (fps, isdrop)
    if not fps or fps <= 0 then fps = 24 end
    if preset.unit == 1 then return '00:00:01:00.00' end
    local frames = preset.value
    local whole_f = math.floor(frames)
    local sub = frames - whole_f
    local secs = math.floor(whole_f / fps)
    local ff = whole_f % fps
    local mm = math.floor(secs / 60); local ss = secs % 60
    local hh = math.floor(mm / 60);   mm = mm % 60
    return string.format('%02d:%02d:%02d:%02d.%02d',
      hh, mm, ss, ff, math.floor(sub * 100 + 0.5))
  end

  if mode == 'Feet+Frames' then
    if preset.label == '1 foot' then return '1+00.00' end
    local f = preset.value
    if f < 1 then return string.format('0+00.%02d', math.floor(f*100)) end
    return string.format('0+%02d.00', math.floor(f))
  end

  if mode == 'Min:Secs' then
    local ms = preset.unit == 1 and (preset.value * 1000) or preset.value
    local total_s = math.floor(ms / 1000)
    local rem_ms  = math.floor(ms % 1000)
    local mm = math.floor(total_s / 60); local ss = total_s % 60
    if rem_ms > 0 then return string.format('%02d:%02d.%03d', mm, ss, rem_ms) end
    return string.format('%02d:%02d.000', mm, ss)
  end

  if mode == 'Samples' then
    return tostring(math.floor(preset.value))
  end

  return preset.label
end

-- Returns: ok (true to proceed, false to cancel)
-- For non-Measure / non-native_frame presets, prompts user if BPM != 120.
-- "Yes"    → sets BPM to 120 then proceeds (accurate).
-- "No"     → proceeds at current BPM (may drift).
-- "Cancel" → abort.
function M.ensure_tempo(mode, preset)
  if mode == 'Measure' then return true end
  if preset and preset.native_frame then return true end
  local bpm = r.GetProjectTimeSignature2(0)
  if bpm and math.abs(bpm - 120) <= 0.01 then return true end

  local msg = string.format(
    'Project tempo is %.2f BPM (not 120).\n\n' ..
    'The "%s" grid is simulated via tempo calculation.\n' ..
    'Spacing is exact at 120 BPM and may drift if tempo changes.\n\n' ..
    'Set project tempo to 120 BPM now?\n\n' ..
    '  Yes    - set BPM to 120 and apply the grid\n' ..
    '  No     - apply the grid at current BPM (may drift)\n' ..
    '  Cancel - abort',
    bpm or 0, mode)
  local ret = r.MB(msg, 'Grid: Tempo Mismatch', 3)  -- 3 = Yes/No/Cancel
  if ret == 6 then  -- Yes
    r.SetCurrentBPM(0, 120, true)
    return true
  elseif ret == 7 then  -- No
    return true
  end
  return false  -- Cancel (2) or window closed
end

-- Set grid_div, normalising swing=3 (Measure) to 0 if needed.
local function write_grid_div(div, swing)
  if swing == 3 then
    r.GetSetProjectGrid(0, 1, div, 0)
  else
    r.GetSetProjectGrid(0, 1, div)
  end
end

-- Defensive: walks defer iterations to keep enforcing 40904=OFF in case
-- some external REAPER state re-engages Frame grid after our toggle.
-- Observed trigger: user opens Snap/Grid Settings, sets the dropdown to
-- "Frame", adjusts Frame's "minimum: N pixels" field, hits Enter — REAPER
-- then re-applies Frame across our changes for several event loops.
-- Each iteration checks 40904; if it has come back ON we toggle it off,
-- then schedule another check on the next event loop. Stops once 40904
-- stays OFF, or after `remaining` iterations.
local function ensure_frame_off_chain(remaining)
  if remaining <= 0 then return end
  if not M.frame_on() then return end  -- already off
  M.set_frame(false)
  if M.is_debug() then
    r.ShowConsoleMsg(string.format(
      '[Grid]   (defer) Frame grid off again (retries left: %d) | %s\n',
      remaining - 1, snapshot()))
  end
  r.defer(function() ensure_frame_off_chain(remaining - 1) end)
end

function M.apply(mode, idx)
  local preset = M.get_preset(mode, idx)
  if not preset then return end

  dbg('apply(%s,%d)=%s native=%s | START %s',
    mode, idx, preset.label, tostring(preset.native_frame == true), snapshot())

  if preset.native_frame then
    if not M.frame_on() then
      M.set_frame(true)
      dbg('  Frame grid ON | %s', snapshot())
    end
    M.set_state(mode, idx)
    dbg('apply END (native_frame) | %s', snapshot())
    return
  end

  -- Non-native_frame: write grid_div, BEFORE and AFTER toggling Frame grid
  -- off, plus once more on the next event loop. This is defensive against
  -- REAPER's command 40904 resetting grid_div as a side-effect when going
  -- from Frame-grid-on to Frame-grid-off (observed: first attempt at a
  -- new Timecode preset displays the previous grid value; second attempt
  -- works).
  local _, _, swing = r.GetSetProjectGrid(0, 0)
  local div = M.preset_to_div(mode, preset)
  dbg('  computed div=%.6f swing=%d', div, swing or 0)

  -- 1) Pre-toggle write (in case REAPER reads grid_div during the toggle)
  write_grid_div(div, swing)
  dbg('  step1 (pre-toggle write) | %s', snapshot())

  -- 2) Toggle Frame grid off if currently on
  if M.frame_on() then
    M.set_frame(false)
    dbg('  step2 (Frame grid OFF) | %s', snapshot())
  end

  -- 3) Post-toggle write (clobber any side-effect reset from the toggle)
  write_grid_div(div, swing)
  dbg('  step3 (post-toggle write) | %s', snapshot())

  M.set_state(mode, idx)
  dbg('apply END (sync) | %s', snapshot())

  -- 4) Deferred re-write — runs on the next event loop iteration, after
  -- REAPER has fully processed the toggle and any internal grid refresh.
  r.defer(function()
    -- Only re-apply if the user is still on the same preset (could have
    -- changed mode/idx via a fast keyboard repeat).
    local cur_mode, cur_idx = M.get_state()
    if cur_mode == mode and cur_idx == idx then
      local _, _, sw = r.GetSetProjectGrid(0, 0)
      write_grid_div(div, sw)
      dbg('  step4 (deferred write) | %s', snapshot())
      -- 5) Persistent enforcement: if some other REAPER state re-engages
      -- Frame grid (e.g. Snap/Grid Settings dialog with Frame selected),
      -- keep toggling 40904 off across a few event loops.
      ensure_frame_off_chain(5)
    else
      dbg('  step4 SKIPPED (state moved to %s/%d)', cur_mode, cur_idx)
    end
  end)
end

-- Find closest preset to current grid_div (for Measure resync after the
-- user changed grid externally via REAPER's native UI).
local function closest_idx(mode, grid_div)
  local presets = GRID_PRESETS[mode]
  if not presets then return 1 end
  local best_i, best_d = 1, math.huge
  for i, p in ipairs(presets) do
    local pd = (mode == 'Measure') and p.div or M.preset_to_div(mode, p)
    local d = math.abs(grid_div - pd)
    if d < best_d then best_d = d; best_i = i end
  end
  return best_i
end

-- True when REAPER's Frame grid is engaged but our saved state isn't a
-- native_frame preset — signals user enabled Frame grid externally and we
-- shouldn't override their intent from a keyboard shortcut.
local function frame_grid_external(mode, idx)
  if not M.frame_on() then return false end
  local preset = M.get_preset(mode, idx)
  return not (preset and preset.native_frame)
end

function M.increase()
  local mode, idx = M.get_state()
  if frame_grid_external(mode, idx) then return mode, idx end
  if mode == 'Measure' then
    local _, grid_div = r.GetSetProjectGrid(0, 0)
    idx = closest_idx(mode, grid_div)
  end
  local new_idx = math.max(1, idx - 1)
  if new_idx ~= idx or mode == 'Measure' then
    M.apply(mode, new_idx)
  end
  return mode, new_idx
end

function M.decrease()
  local mode, idx = M.get_state()
  if frame_grid_external(mode, idx) then return mode, idx end
  if mode == 'Measure' then
    local _, grid_div = r.GetSetProjectGrid(0, 0)
    idx = closest_idx(mode, grid_div)
  end
  local presets = GRID_PRESETS[mode]
  local new_idx = math.min(#presets, idx + 1)
  if new_idx ~= idx or mode == 'Measure' then
    M.apply(mode, new_idx)
  end
  return mode, new_idx
end

local _last_dbg_sig
local function get_text_inner()
  local mode, idx = M.get_state()
  local preset = M.get_preset(mode, idx)
  local frame_on = M.frame_on()

  -- Saved preset is native_frame: TC display when Frame grid is on
  if preset and preset.native_frame and frame_on then
    return M.format_value(mode, preset), 'native_frame+frame_on'
  end

  -- Frame grid on but saved preset isn't native_frame → external state
  if frame_on then return 'Frame', 'frame_on,not_native' end

  local _, grid_div, swing = r.GetSetProjectGrid(0, 0)
  if grid_div ~= grid_div then grid_div = 1 end

  if mode == 'Measure' then
    if swing == 3 then return 'Measure', 'measure_swing' end
    if preset and math.abs(grid_div - preset.div) < 1e-8 then
      return preset.label, 'measure_preset_match'
    end
    -- Auto-sync: in Measure mode, if grid_div changed externally (REAPER's
    -- native grid menu), find the closest matching preset and update
    -- preset_idx so the menu's check-mark stays accurate.
    local best_i, best_d = nil, math.huge
    for i, p in ipairs(GRID_PRESETS['Measure']) do
      local d = math.abs(grid_div - p.div)
      if d < best_d then best_d = d; best_i = i end
    end
    if best_i and best_i ~= idx and best_d < 1e-8 then
      M.set_state('Measure', best_i)
      return GRID_PRESETS['Measure'][best_i].label, 'measure_synced'
    end
    if grid_div >= 1 then
      return string.format('%d bar', math.floor(grid_div+0.5)), 'measure_bar'
    end
    local denom = math.floor(1/grid_div + 0.5)
    return '1/' .. denom, 'measure_div'
  end

  -- Simulated mode: validate against saved (non-native_frame) preset
  -- Tolerance is 1% (1e-2) — generous for fine grids like 1/4800 where
  -- REAPER's float storage may round slightly. (No per-frame log here —
  -- the wrapper rate-limits on text/why transition.)
  if preset and not preset.native_frame then
    local expected = M.preset_to_div(mode, preset)
    local denom = math.max(math.abs(expected), 1e-9)
    if math.abs(grid_div - expected) / denom < 1e-2 then
      return M.format_value(mode, preset), 'sim_match'
    end
  end

  -- Mismatch (user changed grid externally): show fallback text WITHOUT
  -- auto-reverting the saved mode, so the menu still shows the user's
  -- chosen mode and presets — they can pick one to re-align.
  if swing == 3 then return 'Measure', 'fallback_measure' end
  if grid_div >= 1 then
    return string.format('%d bar', math.floor(grid_div+0.5)), 'fallback_bar'
  end
  local denom = math.floor(1/grid_div + 0.5)
  return '1/' .. denom, 'fallback_div'
end

-- Re-apply the current preset when project fps or BPM changes, so
-- simulated grids (Timecode/Feet+Frames/Min:Secs/Samples) follow the
-- new environment instead of jumping to a fallback display.
-- Only fires when the change is real and the current preset depends
-- on the changed parameter.
local _last_fps, _last_bpm
local function maybe_resync_env()
  local fps = r.TimeMap_curFrameRate(0)
  local bpm = r.GetProjectTimeSignature2(0)
  if not _last_fps then
    _last_fps, _last_bpm = fps, bpm
    return
  end
  local fps_changed = fps and (fps ~= _last_fps)
  local bpm_changed = bpm and _last_bpm and (math.abs(bpm - _last_bpm) > 1e-3)
  if fps_changed or bpm_changed then
    local mode, idx = M.get_state()
    local preset = M.get_preset(mode, idx)
    if preset and mode ~= 'Measure' and not preset.native_frame then
      -- fps only matters for frame-unit presets (unit==18)
      local should = bpm_changed or (fps_changed and preset.unit == 18)
      if should then
        if dbg_enabled() then
          dbg('  env change → resync %s/%d (fps %s→%s, bpm %s→%s)',
            mode, idx,
            tostring(_last_fps), tostring(fps),
            tostring(_last_bpm), tostring(bpm))
        end
        M.apply(mode, idx)
      end
    end
  end
  _last_fps, _last_bpm = fps, bpm
end

function M.get_text()
  maybe_resync_env()
  local text, why = get_text_inner()
  if dbg_enabled() then
    -- Log on transition (text or "why" branch changed) to avoid frame-rate spam.
    local sig = (text or '') .. '|' .. (why or '')
    if sig ~= _last_dbg_sig then
      dbg('get_text -> "%s" (%s) | %s', text or '?', why or '?', snapshot())
      _last_dbg_sig = sig
    end
  end
  return text
end

return M
