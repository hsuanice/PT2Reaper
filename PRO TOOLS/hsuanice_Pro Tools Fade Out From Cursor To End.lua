-- @description hsuanice_Pro Tools Fade Out From Cursor To End
-- @version 0.3.0 [260505.2045]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Fade Out From Cursor To End** (Ctrl+G)
--   Thin wrapper over REAPER native action 40510 "Item: Fade items out
--   from cursor" — for each selected item, sets the fade-out length to
--   (item.fin − cursor). Items with the cursor outside their body are
--   skipped automatically by the native action. REAPER's default fade
--   shape is used.
--   - Tags: Editing, Fades
-- @changelog
--   0.3.0 [260505.2045] - Simplify to a thin wrapper around native
--                          40510. Custom shape-from-ExtState logic
--                          retained below as a NOTE block in case PT-style
--                          shape recall is wanted later.
--   0.2.0 [260505.2030] - First real implementation (custom iteration +
--                          shape from Create Fades ExtState).
--   0.1.0 [260413.1324] - Stub placeholder created.

reaper.Main_OnCommand(40510, 0)  -- Item: Fade items out from cursor

--[[
NOTE — previous v0.2.0 implementation (custom shape from Create Fades' ExtState)
-------------------------------------------------------------------------------
If we ever want PT-style shape recall (use the last fade-out shape set via
Create Fades), revive this. Drops the native 40510 call and iterates manually
so we can apply a specific shape per-item via FADEOUT_CMDS:

  local r = reaper
  local _info = debug.getinfo(1, 'S')
  local _dir  = _info.source:match('^@(.*[/\\])') or ''
  local F = dofile(_dir .. '../Library/hsuanice_PT_Fades.lua')
  if not F then return end

  local EXT_SEC = "hsuanice_PT2Reaper_CreateFades"
  local function read_shape(key, fallback)
    local v = tonumber(r.GetExtState(EXT_SEC, key))
    if v then return F.clamp_shape(math.floor(v)) end
    return fallback
  end

  local fadeout_shape = read_shape("fadeout_shape", 1)
  local cursor        = r.GetCursorPosition()
  local n             = r.CountSelectedMediaItems(0)
  if n == 0 then return end

  local todo = {}
  for i = 0, n-1 do
    local it  = r.GetSelectedMediaItem(0, i)
    local pos = r.GetMediaItemInfo_Value(it, "D_POSITION")
    local fin = pos + r.GetMediaItemInfo_Value(it, "D_LENGTH")
    if cursor > pos + F.EPS and cursor < fin - F.EPS then
      todo[#todo+1] = {item=it, len=fin - cursor}
    end
  end
  if #todo == 0 then return end

  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  F.with_preserved_state(function()
    for _, t in ipairs(todo) do
      F.set_fadeout_shape(t.item, fadeout_shape)
      r.SetMediaItemInfo_Value(t.item, "D_FADEOUTLEN", t.len)
    end
  end)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("Pro Tools: Fade Out From Cursor To End", -1)
--]]
