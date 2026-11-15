--[[
@description hsuanice_Pro Tools Time Lock Clip
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Time Lock Clip** (Opt+Ctrl+L) — toggles time
  lock on selected items. REAPER's per-item lock (C_LOCK) is a single
  flag covering both edit and time lock — so this script is functionally
  identical to "Edit Lock Clip" in REAPER.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local n = r.CountSelectedMediaItems(0)
if n == 0 then return end
local first_locked = r.GetMediaItemInfo_Value(r.GetSelectedMediaItem(0,0), "C_LOCK") > 0
local new_state = first_locked and 0 or 1
r.Undo_BeginBlock()
for i = 0, n-1 do
  r.SetMediaItemInfo_Value(r.GetSelectedMediaItem(0, i), "C_LOCK", new_state)
end
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Time Lock Clip", -1)
