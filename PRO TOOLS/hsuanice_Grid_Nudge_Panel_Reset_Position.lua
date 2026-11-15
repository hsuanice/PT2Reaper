--[[
@description hsuanice_Grid Nudge Panel - Reset Position
@version 26.1115.1407
@author hsuanice
@noindex
@changelog
  - First release of the PT2Reaper package (all Pro Tools actions in one package).
  - File names have no brackets any more: "Name [X]" is now "Name - X", "Clip[s]" is "Clips".
  - Full history: Changelogs/ in the repository (https://github.com/hsuanice/PT2Reaper/tree/master/Changelogs)
@about
  Run this to reset the Grid Nudge Panel position back to default.
--]]

local EXT = 'hsuanice_GridNudgePanel'
reaper.DeleteExtState(EXT, 'screen_x', true)
reaper.DeleteExtState(EXT, 'screen_y', true)
reaper.DeleteExtState(EXT, 'bm_x', true)
reaper.DeleteExtState(EXT, 'bm_y', true)
reaper.DeleteExtState(EXT, 'attach_title', true)
reaper.ShowMessageBox('Position reset! Restart Grid Nudge Panel to see changes.', 'Reset', 0)
