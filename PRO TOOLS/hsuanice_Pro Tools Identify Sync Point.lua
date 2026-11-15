--[[
@description hsuanice_Pro Tools Identify Sync Point
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Replicates Pro Tools: **Identify Sync Point** (Cmd+Comma)
  Thin wrapper over REAPER native action 40541 "Item: Set snap offset to
  cursor" — sets the sync point (D_SNAPOFFSET) of each selected item to
  the position under the edit cursor.
  - Tags: Clips, Editing
@links
  https://forum.cockos.com/showthread.php?p=2910884#post2910884
--]]

reaper.Main_OnCommand(40541, 0)  -- Item: Set snap offset to cursor
