-- @description hsuanice_Pro Tools Nudge Clip Contents Earlier By Grid
-- @version 0.3.0 [260504.1230]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Nudge Clip Contents Earlier By Grid**
--   Nudges the contents (audio offset) of selected items earlier in time —
--   STARTOFFS increases by delta * playrate. Item position / length unchanged.
--   Uses nudge value from hsuanice_Grid Nudge Panel.
--   Source-bound clamp: if shifting would push the played source range past the file's
--   end, that item silently doesn't move (no warning popup, just stops at the boundary).
--   - Tags: Editing
-- @changelog
--   0.3.0 [260504.1230] - Bypass r.ApplyNudge; do per-item D_STARTOFFS shift with
--                          source-bound check (silent skip when out of range).
--   0.2.0 [260418.1931] - Rewrite: use ApplyNudge with hsuanice_PT_Nudge library

local r = reaper
local info = debug.getinfo(1,'S')
local dir  = info.source:match('^@(.+)[\\/]') or ''
local ok, Nudge = pcall(dofile, dir .. '/hsuanice_PT_Nudge.lua')
if not ok then
  r.ShowMessageBox('Could not load hsuanice_PT_Nudge.lua\n' .. tostring(Nudge), 'Error', 0)
  return
end

local mode, idx = Nudge.get_state()
local preset = Nudge.get_preset(mode, idx)
if not preset then return end
local delta = Nudge.calc_delta_sec(preset, false)  -- positive magnitude
if math.abs(delta) < 1e-10 then return end

-- Contents Earlier: source content shifts earlier in time → STARTOFFS increases by delta*playrate
local function shift_one(item)
  local take = r.GetActiveTake(item)
  if not take then return end
  local source = r.GetMediaItemTake_Source(take)
  if not source then return end
  local src_len, is_qn = r.GetMediaSourceLength(source)
  if is_qn then return end  -- MIDI source — no offset semantics here
  local pr = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
  if pr <= 0 then pr = 1 end
  local len  = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local offs = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
  local new_offs = offs + delta * pr
  -- Source-bound clamp: 0 <= new_offs <= src_len - len*pr. Out of range → don't move.
  if new_offs < -1e-4 then return end
  if new_offs + len * pr > src_len + 1e-4 then return end
  if new_offs < 0 then new_offs = 0 end
  r.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', new_offs)
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
for i = 0, r.CountSelectedMediaItems(0) - 1 do
  shift_one(r.GetSelectedMediaItem(0, i))
end
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Nudge Clip Contents Earlier By Grid', -1)
