--[[
@description hsuanice_Pro Tools Mute Unmute Clip
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Mute Unmute Clip** (Cmd+M)

  Toggles the mute state of selected items, uniformising mixed
  selections (PT behavior).

  ## Behavior
  - Single item: normal toggle.
  - Multiple items:
    - Mixed mute states → unify to UNMUTE.
    - Uniform state     → toggle all.

  - Tags: Editing, Clips
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper

local function get_selected_items()
  local t = {}
  local proj = 0
  local cnt = r.CountSelectedMediaItems(proj)
  for i = 0, cnt-1 do
    t[#t+1] = r.GetSelectedMediaItem(proj, i)
  end
  return t
end

local function is_item_muted(item)
  -- B_MUTE: bool (1 muted / 0 not muted)
  return r.GetMediaItemInfo_Value(item, "B_MUTE") > 0.5
end

local function set_item_muted(item, muted)
  -- Setting B_MUTE will also clear C_MUTE_SOLO per API behavior.
  r.SetMediaItemInfo_Value(item, "B_MUTE", muted and 1 or 0)
end

local function main()
  local items = get_selected_items()
  if #items == 0 then return end

  local muted_count, unmuted_count = 0, 0
  for _, it in ipairs(items) do
    if is_item_muted(it) then
      muted_count = muted_count + 1
    else
      unmuted_count = unmuted_count + 1
    end
  end

  local desc = "Item Mute Toggle (uniformize mixed->unmute)"
  r.Undo_BeginBlock()

  if #items == 1 then
    -- Single item: regular toggle
    local it = items[1]
    local target = not is_item_muted(it)
    set_item_muted(it, target)
  else
    if muted_count > 0 and unmuted_count > 0 then
      -- Mixed states: unify to UNMUTE
      for _, it in ipairs(items) do
        set_item_muted(it, false)
      end
    else
      -- Uniform: toggle all
      local currently_muted = (muted_count == #items)
      local target = not currently_muted
      for _, it in ipairs(items) do
        set_item_muted(it, target)
      end
    end
  end

  r.UpdateArrange()
  r.Undo_EndBlock(desc, -1)
end

main()
