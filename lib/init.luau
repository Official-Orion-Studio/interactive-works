-- Dependencies
local interactive = require(script.interactive)
local modding = require(script.modding)
local util = require(script.util.utility)
local singleton = require(script.singleton)

-- Types
type InteractiveWorks = {
    modding: typeof(modding),
    util: typeof(util),

    init: () -> nil,
    addPath: (path: string | Instance) -> nil,
    setLogLevel: (level: "verbose" | "top-level") -> nil,

    createService: typeof(singleton.createService),
    createController: typeof(singleton.createController),
    getService: typeof(singleton.getService),
    getController: typeof(singleton.getController),
}

-- Export
local InteractiveWork = interactive
InteractiveWork.modding = modding
InteractiveWork.util = util

return InteractiveWork :: InteractiveWorks