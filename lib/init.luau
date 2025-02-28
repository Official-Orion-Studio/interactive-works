--> Dependencies
local interactive = require(script.interactive)
local modding = require(script.modding)
local util = require(script.util.utility)

--> Exports
local InteractiveWork = interactive
InteractiveWork.Modding = modding
InteractiveWork.Util = util

return InteractiveWork