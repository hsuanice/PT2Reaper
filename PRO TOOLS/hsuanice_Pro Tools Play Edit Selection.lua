-- @description hsuanice_Pro Tools Play Edit Selection
-- @version 0.9.4 [260510.1134]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Play Edit Selection** (Ctrl+[ / Opt+[ /
--   Commands Focus + [)
--
--   Plays the current "Edit Selection" range, with PT-style fallback:
--   - **Razor present** → plays the union of all track-level razor
--     zones (GUID == "").
--   - **No razor** → plays the union of (time selection) ∪ (selected
--     items bounds). Either alone is also OK.
--   - Neither → plain play/stop toggle.
--
--   ## Behaviour
--   - Press semantics (PT-style replay):
--     - Always seeks to range start and ensures playback is running.
--     - Pressing the SAME scope while playing → REPLAY from start
--       (does not stop). Use the regular Stop key / spacebar to stop.
--     - Pressing a DIFFERENT scope while playing → take over (seek,
--       no stop/restart) — small audio delay only.
--   - When playback reaches the union end:
--     - **Loop ON**  → seek back to union start (continuous loop).
--     - **Loop OFF** → stop.
--   - The scope hand-off is co-ordinated via ExtState namespace
--     `hsuanice_PT_PlayScope`, key `scope` (`"razor"` / `"timeline"` /
--     empty), shared with Play Timeline Selection.
--
--   - Tags : Editing, Selection, Transport
-- @changelog
--   0.9.4 [260510.1134] - Setup notice flag is now per-script (own
--                          ExtState namespace) instead of shared with
--                          Play Timeline Selection. Users may bind only
--                          one of the two scripts and still need the
--                          warning when they first run that script.
--   0.9.3 [260510.1128] - Setup notice translated to English. All
--                          debug logging removed. Restored after an
--                          accidental file revert.
--   0.9.2 [260509.2120] - One-time setup notice on first run (shared
--                          flag with Play Timeline Selection — only
--                          shows once total). Tells the user to
--                          tick "Remember my answer for this script"
--                          + "New instance" when REAPER's task
--                          control dialog appears.
--   0.9.1 [260509.2114] - Remove `set_action_options(1)` and the
--                          self-recall hack. The set_action_options
--                          call was the source of REAPER dropping
--                          rapid-fire invocations (~50% loss). The
--                          per-script "Remember my answer = New
--                          instance" preference delivers every press
--                          reliably.
--   0.9.0 [260509.1958] - Self-recall reliability hack (later removed).
--   0.8.x [260509.1*]   - Diagnostic builds + iterations.
--   0.7.0 [260509.1436] - Repeat-press REPLAYS instead of stopping.
--                          Generation-counter watcher coordination.
--   0.6.0 [260509.1429] - Fallback when no razor: union of time
--                          selection + selected-item bounds.
--   0.5.0 [260509.1423] - Cross-scope hand-off with Play Timeline
--                          Selection.
--   0.4.0 [260509.1408] - Honour Loop toggle: ON → seek back to
--                          razor start. Use 40044 throughout.
--   0.3.0 [260509.1404] - Re-target to RAZOR range (PT semantics).
--   0.2.0 [260509.1245] - First implementation; played from TS / item.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local EPS = 1e-9

local SCOPE_NS  = "hsuanice_PT_PlayScope"
local SCOPE_KEY = "scope"
local MY_SCOPE  = "razor"

-- One-time setup notice (per-script flag; users may bind only some
-- of the PT scripts, so each script needs to warn on its own first run).
do
  local NOTICE_NS = "hsuanice_PT_PlayEditSelection"
  local KEY = "setup_notice_seen"
  if r.GetExtState(NOTICE_NS, KEY) ~= "1" then
    r.SetExtState(NOTICE_NS, KEY, "1", true)  -- persist across REAPER restarts
    r.ShowMessageBox(
      "Pro Tools Play Edit Selection — One-time Setup\n\n" ..
      "When you press this script repeatedly, REAPER may pop a\n" ..
      "\"ReaScript task control\" dialog asking whether to terminate\n" ..
      "the previous instance.\n\n" ..
      "Please configure it once like this:\n" ..
      "  1. Tick \"Remember my answer for this script\"\n" ..
      "  2. Click \"New instance\"\n\n" ..
      "After that, REAPER will not pop the dialog again, and the\n" ..
      "script will replay reliably on every press.\n\n" ..
      "(This notice will only appear once for this script.)",
      "PT Play Edit Selection — Setup", 0)
  end
end

-- NOTE: deliberately NOT calling set_action_options(1). REAPER drops
-- ~50% of rapid-fire invocations under that flag; the per-script
-- "Remember my answer = New instance" preference (above) delivers
-- every press reliably.

-- 1. Razor union (track-level zones only — guid == "")
local play_s, play_e = math.huge, -math.huge
for ti = 0, r.CountTracks(0) - 1 do
  local _, str = r.GetSetMediaTrackInfo_String(r.GetTrack(0, ti),
    "P_RAZOREDITS", "", false)
  if str and str ~= "" then
    for s_str, e_str, guid in str:gmatch("(%S+)%s+(%S+)%s+(%S+)") do
      if guid == '""' then
        local sn = tonumber(s_str); local en = tonumber(e_str)
        if sn and en and en > sn then
          if sn < play_s then play_s = sn end
          if en > play_e then play_e = en end
        end
      end
    end
  end
end
local has_razor = (play_s ~= math.huge) and (play_e > play_s + EPS)

-- 2. Fallback if no razor: union of (time selection) ∪ (selected items)
if not has_razor then
  play_s, play_e = math.huge, -math.huge
  -- Time selection (NOT loop points — that's Play Timeline Selection)
  local ts_s, ts_e = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_e > ts_s + EPS then
    play_s = ts_s
    play_e = ts_e
  end
  -- Items bounds
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if pos < play_s then play_s = pos end
    if fin > play_e then play_e = fin end
  end
end

local has_range = (play_s ~= math.huge) and (play_e > play_s + EPS)

if not has_range then
  -- Nothing to play → fall through to native play/stop, clear scope.
  r.Main_OnCommand(40044, 0)
  r.SetExtState(SCOPE_NS, SCOPE_KEY, "", false)
  return
end

local loop_on    = (r.GetSetRepeat(-1) == 1)
local ps         = r.GetPlayState()
local is_playing = (ps & 1) ~= 0
local prev_gen   = tonumber(r.GetExtState(SCOPE_NS, "gen")) or 0

-- Bump generation so any previous watcher exits.
local GEN_KEY = "gen"
local my_gen  = prev_gen + 1
r.SetExtState(SCOPE_NS, GEN_KEY,   tostring(my_gen), false)
r.SetExtState(SCOPE_NS, SCOPE_KEY, MY_SCOPE,         false)

-- Force stop + play via CSurf direct calls (avoids Main_OnCommand
-- TOGGLE race condition + Smooth-Seek deferral on seek-while-playing).
if is_playing then
  r.CSurf_OnStop()
end
r.SetEditCurPos(play_s, false, false)
r.CSurf_OnPlay()

local target_s = play_s
local target_e = play_e
local function watch()
  -- Bail out if a newer invocation has superseded us, or scope changed.
  if (tonumber(r.GetExtState(SCOPE_NS, GEN_KEY)) or 0) ~= my_gen then return end
  if r.GetExtState(SCOPE_NS, SCOPE_KEY) ~= MY_SCOPE then return end
  local p = r.GetPlayState()
  if (p & 1) == 0 then
    r.SetExtState(SCOPE_NS, SCOPE_KEY, "", false)
    return
  end
  local cur = r.GetPlayPosition()
  if cur >= target_e - EPS then
    if loop_on then
      r.SetEditCurPos(target_s, false, true)
    else
      r.Main_OnCommand(40044, 0)
      r.SetExtState(SCOPE_NS, SCOPE_KEY, "", false)
      return
    end
  end
  r.defer(watch)
end
r.defer(watch)
