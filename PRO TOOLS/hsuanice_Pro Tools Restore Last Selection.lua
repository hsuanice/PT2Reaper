--[[
@description hsuanice_Pro Tools Restore Last Selection
@version 26.1117.2043pre1
@author hsuanice
@noindex
@changelog
  - Pro Tools behaviour: swaps the Edit Selection with the one before it (remembered by the Counters Panel); no Selection Set any more.
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Restore Last Selection**
  (PT key: Command+Option+Z)

  Goes back to the Edit Selection before the current one; pressing it again goes forward
  again (one level, as Pro Tools). The Edit Selection is a range on tracks (razor areas) or a
  position on tracks (edit cursor + selected tracks). The Timeline Selection (loop points)
  is not part of it.
  The selections are remembered by the Counters Panel (it must be open): a selection counts
  once it has stayed the same for half a second with the mouse button up.

  Self-contained: uses hsuanice_PT_SelectionMemory.lua and hsuanice_PT_MouseSelect.lua
  (same folder).
  - Tags : Editing, Selection
  Built with AI: written with Claude Code (Anthropic); designed and tested by hsuanice.
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

local r = reaper
local DIR = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or ''
local ok, SM = pcall(dofile, DIR .. 'hsuanice_PT_SelectionMemory.lua')
if not ok or type(SM) ~= 'table' then
  r.ShowMessageBox('Could not load hsuanice_PT_SelectionMemory.lua\n\n' .. tostring(SM), 'Error', 0)
  return
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)
local res = SM.restore()
r.PreventUIRefresh(-1)
r.UpdateArrange()
r.Undo_EndBlock('Pro Tools: Restore Last Selection', -1)

if res == 'not_watching' then
  r.ShowMessageBox('Restore Last Selection needs the Pro Tools Counters Panel to be open:\n'
    .. 'it remembers the selections.', 'Restore Last Selection', 0)
end
