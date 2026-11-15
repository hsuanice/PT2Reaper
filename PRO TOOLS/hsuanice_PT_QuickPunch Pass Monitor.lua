--[[
@description hsuanice_PT_QuickPunch Pass Monitor (internal: started by Play/Stop / Record Punch)
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Runs during a QuickPunch pass: punches in / out at the auto-punch range boundaries,
  grows the red "recording" placeholders while punched in and, once the transport has
  stopped, finishes the pass. Not meant to be run by hand.
  Copied from Beta Testing/QuickPunch/hsuanice_QuickPunch - QP Pass Monitor.lua (26.1114).
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
--]]

local r = reaper
local C = dofile((debug.getinfo(1, "S").source:match("^@(.*[/\\])") or "") .. "hsuanice_PT_QuickPunch.lua")

-- a new pass relaunches the monitor: the old instance ends instead of asking
if r.set_action_options then r.set_action_options(1 | 2) end

local pass_id = C.get("pass_id")
local t0 = r.time_precise()
local started = false
local stopped_cycles = 0
local ph_rev, ph_items = nil, {}
local last_log = 0
C.log("monitor start pass_id", pass_id)

local function loop()
  -- the pass ended elsewhere (finished by the next pass) or another pass started
  if not C.pass_active() or C.get("pass_id") ~= pass_id then
    C.log("monitor exit: pass_active", C.pass_active(), "pass_id", C.get("pass_id"), "mine", pass_id)
    return
  end
  local st = r.GetPlayState()

  if not started then
    if (st & 4) == 4 then
      started = true
    elseif r.time_precise() - t0 > 3 then
      C.finalize() -- recording never started: restore everything
      return
    end
  else
    if st == 0 then
      stopped_cycles = stopped_cycles + 1
      if stopped_cycles >= 2 then -- give REAPER a cycle to add the recorded items
        C.finalize()
        return
      end
    else
      stopped_cycles = 0
      -- auto punch in / out at the auto-punch range boundaries
      C.auto_step(r.GetPlayPosition())
      -- grow the red "recording" placeholders with the play cursor
      local rev = C.get("ph_rev")
      if rev ~= ph_rev then
        ph_rev = rev; ph_items = C.active_placeholders()
        C.log("monitor ph_rev", rev, "placeholders", #ph_items)
      end
      if #ph_items > 0 then
        C.extend_placeholders(ph_items, r.GetPlayPosition())
        r.UpdateArrange()
        if r.time_precise() - last_log > 1 then
          last_log = r.time_precise()
          local it = ph_items[1]
          C.log("monitor extend: valid", r.ValidatePtr2(0, it, "MediaItem*"),
            "pos", r.ValidatePtr2(0, it, "MediaItem*") and r.GetMediaItemInfo_Value(it, "D_POSITION"),
            "len", r.ValidatePtr2(0, it, "MediaItem*") and r.GetMediaItemInfo_Value(it, "D_LENGTH"),
            "playpos", r.GetPlayPosition())
        end
      end
    end
  end
  r.defer(loop)
end

loop()
