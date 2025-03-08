-- Dependencies
local componentsUtil = require(script.components.util)
local interactive = require(script.interactive)
local modding = require(script.modding)
local singleton = require(script.singleton)
local util = require(script.util.utility)

-- Types
type Interactive = {
	modding: typeof(modding),
	util: typeof(util),

	init: () -> nil,
	addPath: (path: string | Instance) -> nil,
	setLogLevel: (level: "verbose" | "top-level") -> nil,

	createComponent: typeof(componentsUtil.createComponent),

	createService: typeof(singleton.createService),
	createController: typeof(singleton.createController),
	getService: typeof(singleton.getService),
	getController: typeof(singleton.getController),
}

-- Export
local Interactive = {}

Interactive.init = interactive.init
Interactive.addPath = interactive.addPath
Interactive.setLogLevel = interactive.setLogLevel
Interactive.createService = singleton.createService
Interactive.createController = singleton.createController
Interactive.getService = singleton.getService
Interactive.getController = singleton.getController
Interactive.createComponent = componentsUtil.createComponent

Interactive.components = components
Interactive.modding = modding
Interactive.util = util

return Interactive :: Interactive
