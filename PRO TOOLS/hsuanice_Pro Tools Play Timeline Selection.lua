-- @description hsuanice_Pro Tools Play Timeline Selection
-- @version 0.9.1 [260510.1134]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Play Timeline Selection** (Ctrl+] / Opt+] /
--   Commands Focus + ])
--
--   Plays REAPER's **loop point range** (PT's "Timeline" maps to
--   loop points, not the time selection — they can be unlinked).
--
--   ## Behaviour
--   - Press semantics (PT-style replay):
--     - Always seeks to loop_start and ensures playback is running.
--     - Pressing the SAME scope while playing → REPLAY from start
--       (does not stop). Use the regular Stop key / spacebar to stop.
--     - Pressing a DIFFERENT scope while playing → take over (seek,
--       no stop/restart) — small audio delay only.
--   - When playback reaches loop_end:
--     - **Loop ON**  → seek back to loop_start (continuous loop).
--     - **Loop OFF** → stop.
--   - The scope hand-off is co-ordinated via ExtState namespace
--     `hsuanice_PT_PlayScope`, key `scope` (`"razor"` / `"timeline"` /
--     empty), shared with Play Edit Selection.
--
--   - Tags : Editing, Selection, Transport
-- @changelog
--   0.9.1 [260510.1134] - Setup notice flag is now per-script (own
--                          ExtState namespace) instead of shared with
--                          Play Edit Selection. Users may bind only
--                          one of the two scripts and still need the
--                          warning when they first run that script.
--   0.9.0 [260510.1128] - Restored after an accidental file revert.
--                          Now matches Play Edit Selection patterns:
--                          English one-time setup notice (shared flag),
--                          cross-scope hand-off via ExtState, generation
--                          counter to retire stale watchers, CSurf_OnStop
--                          + SetEditCurPos + CSurf_OnPlay for reliable
--                          replay (avoids smooth-seek deferral and
--                          Main_OnCommand TOGGLE race), repeat-press
--                          REPLAYS instead of stopping.
--   0.5.0 [260509.1415] - Fix: was reading time selection instead of
--                          loop points. Switch second arg of
--                          GetSet_LoopTimeRange to `true`. Also pass
--                          seekplay=true to SetEditCurPos so the
--                          transport's play head follows the cursor.
--   0.4.0 [260509.1408] - Switch to action 40044 throughout. Honour
--                          Loop toggle for seek-back-on-end.
--   0.3.0 [260509.1404] - Defer watcher to stop at TS_end.
--   0.2.0 [260509.1245] - First implementation; played time selection.
--   0.1.0 [260413.1324] - Stub placeholder created.

local r = reaper
local EPS = 1e-9

local SCOPE_NS  = "hsuanice_PT_PlayScope"
local SCOPE_KEY = "scope"
local MY_SCOPE  = "timeline"

-- One-time setup notice (per-script flag; users may bind only some
-- of the PT scripts, so each script needs to warn on its own first run).
do
  local NOTICE_NS = "hsuanice_PT_PlayTimelineSelection"
  local KEY = "setup_notice_seen"
  if r.GetExtState(NOTICE_NS, KEY) ~= "1" then
    r.SetExtState(NOTICE_NS, KEY, "1", true)  -- persist across REAPER restarts
    r.ShowMessageBox(
      "Pro Tools Play Timeline Selection — One-time Setup\n\n" ..
      "When you press this script repeatedly, REAPER may pop a\n" ..
      "\"ReaScript task control\" dialog asking whether to terminate\n" ..
      "the previous instance.\n\n" ..
      "Please configure it once like this:\n" ..
      "  1. Tick \"Remember my answer for this script\"\n" ..
      "  2. Click \"New instance\"\n\n" ..
      "After that, REAPER will not pop the dialog again, and the\n" ..
      "script will replay reliably on every press.\n\n" ..
      "(This notice will only appear once for this script.)",
      "PT Play Timeline Selection — Setup", 0)
  end
end

-- NOTE: deliberately NOT calling set_action_options(1). REAPER drops
-- ~50% of rapid-fire invocations under that flag; the per-script
-- "Remember my answer = New instance" preference (above) delivers
-- every press reliably.

-- Loop point range (NOT the time selection — second arg = true)
local lp_s, lp_e = r.GetSet_LoopTimeRange(false, true, 0, 0, false)
local has_range  = (lp_e > lp_s + EPS)

if not has_range then
  -- No loop range → plain play/stop toggle, clear scope.
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
r.SetEditCurPos(lp_s, false, false)
r.CSurf_OnPlay()

local target_s = lp_s
local target_e = lp_e
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
