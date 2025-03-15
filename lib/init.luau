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

--[=[
	@class Interactive

	Interactive is a library that allows you to create services, controllers, and components
	in a modular way. It also provides a way to interact with the game's services and controllers
	without having to worry about the implementation details. Everything done for you, and by you 
	at the same time!

	There's some points to take in consideration:
	- `Interactive.addPath()` must be called before Interactive.init() to add the paths where the library
	will look for services, controllers, and components.

	- `Interactive.init()` must be called before any other method, as it initializes the library.

	- `Interactive.createService()`, `Interactive.createController()`, and `Interactive.createComponent()`
	are the methods used to create services, controllers, and components, respectively. All of these should
	be used after entirely defining singleton/component structure, as it will take the current structure of 
	the object at the time of invoke.

	You can also retrieve singletons (retrieving Components is not supported *yet*) by using
	`Interactive.getService()` and `Interactive.getController()`, in the client and the server respectively.

	If a dependency hasn't been resolved, it will be resolved at run-time when requiring the `getSingleton`
	method. For example:

	```lua title="src/server/services/service1.luau"
	local service2 = {
		name = "Service2",
	}

	function service2:method(...)
		...
	end
	```
	```lua title="src/server/services/service2.luau"
	local service1 = {
		name = "Service1",
	}

	function service1:onInit(servicesBag)
		self.service2 = servicesBag.getService("Service2")
		self.service2:method()
	end
	```
	If `Service1` is resolved before `Service2`, it will be resolved at run-time when 
	`Service2` is required. So no need to worry about any dependency order if it's not
	necessary at its core.

	Here's an example on how to initialize the framework.
	```lua title="src/server/init.luau"
	local Interactive = require(...)

	Interactive.addPath("src/server/services")
	Interactive.init()
	```
]=]
local Interactive = {}

--[=[
	@within Interactive
	@function init

	Initializes the library, allowing you to create services, controllers, and components. 
	This stage is the most important, since it will be constructing services, controllers, and
	components based on the structure you've defined.

	:::danger
	This method **MUST** be called before any other method in the library and only **ONCE** throughout
	the environment (server and client).
	:::

	@return nil 
]=]
Interactive.init = interactive.init

--[=[
	@within Interactive
	@function addPath

	Adds a path where the library will look for services, controllers, and components. 
	This method should be called before `Interactive.init()`.

	@param path string
	@return nil
]=]
Interactive.addPath = interactive.addPath

--[=[
	@within Interactive
	@function setLogLevel

	Sets the log level of the Interactive framework. There's internal 
	debugging and this function determinates how much debugging should be shown.

	@param level "top-level" | "verbose"
	@return nil
]=]
Interactive.setLogLevel = interactive.setLogLevel
--[=[
	Creates a service on the server.
	
	@server
	@within Interactive
	@function createService

	@param config SingletonConfig
]=]
Interactive.createService = singleton.createService

--[=[
	Creates a controller on the client.
	
	@client
	@within Interactive
	@function createController

	@param config SingletonConfig
]=]
Interactive.createController = singleton.createController

--[=[
	Returns a service by its name. This method should only be called by the server.

	@server
	@within Interactive
	@function getService

	@param key string
]=]
Interactive.getService = singleton.getService

--[=[
	Returns a controller by its name.

	@client
	@within Interactive
	@function getController

	@param key string
]=]
Interactive.getController = singleton.getController

--[=[
	@within Interactive
	@function createComponent

	Creates a component based on the structure defined. Returns a component object.

	@param component ComponentConfig
	@return Component
]=]
Interactive.createComponent = componentsUtil.createComponent

Interactive.components = components

--[=[
	@within Interactive
	@prop modding Modding

	Interactive also provides a way to interact with the modding utility.
]=]
Interactive.modding = modding

--[=[
	@within Interactive
	@prop util Utility

	Interactive also provides a util library for common utility functions.
]=]
Interactive.util = util

return Interactive :: Interactive
