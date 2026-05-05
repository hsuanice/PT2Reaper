-- @description hsuanice_Pro Tools Delete Fades
-- @version 0.2.1 [260505.1635]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Delete Fades**
--   Removes fade-in / fade-out / crossfade from items in scope.
--
--   **Crossfade behavior (PT-style):** when removing a crossfade, the two
--   items are snapped to TOUCH at the crossfade MIDPOINT — not left as
--   overlapping with their fades stripped. This matches PT (and avoids the
--   amagalma "Remove fades" + 41193 combo which leaves the items overlapping).
--
--   **Scope priority: Razor > Time selection > Item selection** (same as
--   Apply Next/Previous). Crossfade requires both items in the active set
--   for the pair-snap behavior; otherwise only manual fades on the active
--   side are cleared, leaving the xfade itself intact.
--
--   Razor, time selection, and item selection are preserved after delete.
--   - Tags: Editing, Fades
-- @changelog
--   0.2.1 [260505.1635] - Fix razor priority: when an xfade pair is processed,
--                          only the xfade-side fades are cleared (left's
--                          fade-out + right's fade-in). The OTHER side's
--                          fades (left's fade-in, right's fade-out) are no
--                          longer touched. So razor on just the crossfade
--                          region now correctly deletes only the crossfade
--                          and snaps to midpoint, leaving any unrelated
--                          fade-in/out on those items intact.
--   0.2.0 [260505.1608] - Real implementation. Uses Library/hsuanice_PT_Fades.lua
--                          for scope detection. Snap-to-midpoint for xfades.
--                          Manual fades cleared by zeroing D_FADEIN/OUTLEN.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local F = dofile(_dir .. '../Library/hsuanice_PT_Fades.lua')
if not F then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Fades.lua", "Delete Fades", 0)
  return
end

-- Clear ONLY the xfade-side fades on an xfade pair: left's fade-out and
-- right's fade-in (both manual and auto). The opposite-edge fades on each
-- item are left alone — they'll be processed separately via fadein_items /
-- fadeout_items only when they're actually in scope.
local function clear_xfade_side(left_item, right_item)
  r.SetMediaItemInfo_Value(left_item,  "D_FADEOUTLEN",      0)
  r.SetMediaItemInfo_Value(left_item,  "D_FADEOUTLEN_AUTO", 0)
  r.SetMediaItemInfo_Value(right_item, "D_FADEINLEN",       0)
  r.SetMediaItemInfo_Value(right_item, "D_FADEINLEN_AUTO",  0)
end

-- Snap an xfade pair to TOUCH at the crossfade midpoint (PT-style delete).
-- Left's right edge moves to midpoint; right's left edge moves to midpoint
-- (with D_STARTOFFS shifted to keep audio aligned).
local function snap_xfade_to_midpoint(left_item, left_pos, left_fin, right_item, right_pos, right_fin)
  local mid = (left_fin + right_pos) / 2

  -- Left: shrink to end at midpoint
  r.SetMediaItemInfo_Value(left_item, "D_LENGTH", mid - left_pos)

  -- Right: push start to midpoint, shrink length, shift D_STARTOFFS to keep
  -- audio aligned. Apply to ALL takes so multi-take items stay in sync.
  local delta = mid - right_pos  -- positive amount the right item moves RIGHT
  r.SetMediaItemInfo_Value(right_item, "D_POSITION", mid)
  r.SetMediaItemInfo_Value(right_item, "D_LENGTH",   right_fin - mid)
  for ti = 0, r.CountTakes(right_item) - 1 do
    local t = r.GetTake(right_item, ti)
    if t and not r.TakeIsMIDI(t) then
      local o  = r.GetMediaItemTakeInfo_Value(t, "D_STARTOFFS") or 0
      local pr = r.GetMediaItemTakeInfo_Value(t, "D_PLAYRATE")  or 1.0
      if pr <= 0 then pr = 1.0 end
      r.SetMediaItemTakeInfo_Value(t, "D_STARTOFFS", o + delta * pr)
    end
  end
end

local t = F.gather_fade_targets()
if #t.xfade_pairs == 0 and #t.fadein_items == 0 and #t.fadeout_items == 0 then
  return
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
F.with_preserved_state(function()
  -- Process xfade pairs first: snap to midpoint, then clear all fades on both.
  -- Capture geometry BEFORE mutating because snap_xfade_to_midpoint mutates
  -- the items, and the next pair's geometry could shift if items share edges
  -- (rare but possible in chained xfades on the same track).
  for _, p in ipairs(t.xfade_pairs) do
    snap_xfade_to_midpoint(
      p.left.item,  p.left.pos,  p.left.fin,
      p.right.item, p.right.pos, p.right.fin)
    clear_xfade_side(p.left.item, p.right.item)
  end

  -- Manual fade-in items: clear manual fade-in (and auto for safety).
  for _, it in ipairs(t.fadein_items) do
    r.SetMediaItemInfo_Value(it, "D_FADEINLEN",      0)
    r.SetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO", 0)
  end

  -- Manual fade-out items: clear manual fade-out (and auto for safety).
  for _, it in ipairs(t.fadeout_items) do
    r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN",      0)
    r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN_AUTO", 0)
  end
end)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Delete Fades", -1)
