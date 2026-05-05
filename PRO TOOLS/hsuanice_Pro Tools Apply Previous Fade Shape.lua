-- @description hsuanice_Pro Tools Apply Previous Fade Shape
-- @version 0.3.2 [260505.1530]
-- @author hsuanice
-- @link https://forum.cockos.com/showthread.php?p=2910884#post2910884
-- @about
--   Replicates Pro Tools: **Apply Previous Fade Shape** (Opt+Ctrl+Left)
--   Cycles all fade shapes (fade-in, fade-out, crossfade) in scope to the
--   PREVIOUS shape in the GUI order:
--     7 Sharp S-Curve → 6 Slight S-Curve → 5 Sharp Concave →
--     4 Sharp Convex → 3 Slight Concave → 2 Slight Convex (Eq.P.) → 1 Linear
--   Stops at 1 (no wrap to 7).
--
--   **Scope priority: Razor > Time selection > Item selection.**
--     - Razor: only fades whose region overlaps a razor zone are affected
--     - Time: only fades whose region overlaps the time selection are affected
--     - Items: all fades on selected items are affected
--
--   **Crossfade rule:** a crossfade is only treated as a unit when BOTH items
--   in the pair are in the active set. If only one side is active, just that
--   side's fade-in or fade-out is cycled (the other half of the crossfade
--   stays unchanged).
--
--   All fades in scope receive the SAME new shape. The "current" shape to
--   decrement from is the first detected fade by priority:
--     1) crossfade pair  2) fade-in  3) fade-out
--
--   Razor, time selection, and item selection are preserved after apply.
--   - Tags: Editing, Fades
-- @changelog
--   0.3.2 [260505.1530] - Library v0.2.2: only MANUAL fades on selected
--                          items get cycled as fade-in/fade-out. Auto fades
--                          (which are crossfades) are only cycled when both
--                          xfade items are in the active set, so a single
--                          item from an xfade pair leaves the xfade alone.
--   0.3.1 [260505.1505] - Library v0.2.1: razor edits now preserved across
--                          apply (some fade actions clear them as a side
--                          effect); time-selection mode now requires items
--                          to ALSO be item-selected (matches PT — time
--                          selection alone does not select items, so the
--                          crossfade-needs-both-selected rule applies the
--                          same way as in items-only mode).
--   0.3.0 [260505.1430] - Add Razor > Time > Items scope detection;
--                          xfade only when both items in active set;
--                          per-region fade filtering (razor zone / time range);
--                          preserve item selection + time selection after apply.
--   0.2.0 [260505.1358] - Real implementation. Uses Library/hsuanice_PT_Fades.lua
--                          for shape detection and chunk writing. Supports all
--                          three fade types (in/out/crossfade) in one pass.
--   0.1.0 [260413.1324] - Stub placeholder created

local r = reaper

local _info = debug.getinfo(1, 'S')
local _dir  = _info.source:match('^@(.*[/\\])') or ''
local F = dofile(_dir .. '../Library/hsuanice_PT_Fades.lua')
if not F then
  r.ShowMessageBox("Could not load Library/hsuanice_PT_Fades.lua", "Apply Previous Fade Shape", 0)
  return
end

local DIRECTION = -1

local t = F.gather_fade_targets()
if #t.xfade_pairs == 0 and #t.fadein_items == 0 and #t.fadeout_items == 0 then
  return
end

local anchor
if #t.xfade_pairs > 0 then
  anchor = F.existing_fadeout_shape(t.xfade_pairs[1].left.item)
elseif #t.fadein_items > 0 then
  anchor = F.existing_fadein_shape(t.fadein_items[1])
else
  anchor = F.existing_fadeout_shape(t.fadeout_items[1])
end

local new_shape = math.max(1, math.min(7, anchor + DIRECTION))
if new_shape == anchor then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
F.with_preserved_state(function()
  for _, p in ipairs(t.xfade_pairs) do
    F.apply_xfade_shape(p.left.item, p.right.item, new_shape)
  end
  for _, it in ipairs(t.fadein_items) do
    F.set_fadein_shape(it, new_shape)
  end
  for _, it in ipairs(t.fadeout_items) do
    F.set_fadeout_shape(it, new_shape)
  end
end)
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock("Pro Tools: Apply Previous Fade Shape (" .. F.SHAPE_NAMES[new_shape] .. ")", -1)
