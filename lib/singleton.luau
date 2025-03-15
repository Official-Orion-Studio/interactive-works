-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.modding)
local Reflect = require(script.Parent.reflect)

--[=[
	@interface SingletonConfig
	.name string,
	.loadOrder? number,
	.constructor? () -> (),
	.onInit? (servicesBag) -> (),
	.onStart? () -> (),
	.onPostSimulation? (dt: number) -> (),
	.onPreSimulation? (dt: number) -> (),
	@within Singleton

	Represents a singleton's configuration.
]=]
export type SingletonConfig = {
	name: string,
	loadOrder: number?,
	constructor: ((self: SingletonConfig) -> nil)?,
	onPostSimulation: ((self: SingletonConfig, dt: number) -> nil)?,
	onPreSimulation: ((self: SingletonConfig, dt: number) -> nil)?,
	onPreRender: ((self: SingletonConfig, dt: number) -> nil)?,
	onInit: ((self: SingletonConfig) -> nil)?,
	onStart: ((self: SingletonConfig) -> nil)?,
}

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

-- Constants
local Objects = {}
local FromObject = {}

--[=[
	@class Singleton

	Singletons are objects that are instantiated only once and can be accessed from a single 
	point of the application. They are useful for managing global state, functionality
	and keeping logic where it belongs. 

	Singletons should hold logic to only one system at a time, making sure that
	separate logic or functionality not-related to the main system is kept in a separate
	singleton.

	Here's an example of a singleton:

	```lua title="src/server/services/service.luau"
	local framework = require(...)
	local service = {
		name = "Service",
	}

	function service:onInit(servicesBag)
		...
	end

	function service:onStart()
		...
	end

	return framework.createService(service)
	```
]=]
local Singleton = {}

--[=[
	Checks and registers a singleton. Making sure to bind its lifecycles as well.

	Lifecycle methods are methods that are called at a specific time during the singleton's lifecycle,
	and these are called by another singletons that may have setup such lifecycles. All lifecycles
	should start with `on...`, as it's currently the only way to differentiate from methods.

	```lua
	local singleton = {
		name = "Singleton",
		onInit = function(self, servicesBag)
			...
		end,
		onStart = function(self)
			...
		end,
		onLifecycle = function(self)
			... -- This will be called sometime in execution.
		end
	}
	```


	@within Singleton
	@param config -- The singleton's config.
]=]
function Singleton.create(config: SingletonConfig): SingletonConfig
	assert(
		typeof(config) == "table",
		`[{PREFIX}:Singleton]: Can't create a singleton without a table.`
	)
	assert(
		typeof(config.name) == "string",
		`[{PREFIX}:Singleton]: Can't create a singleton without a name.`
	)
	assert(#config.name > 0, `[{PREFIX}:Singleton]: Can't create a singleton with an empty name.`)
	assert(
		not Objects[config.name],
		`[{PREFIX}:Singleton]: Singleton with name {config.name} already exists.`
	)

	for prop, value in config do
		local isLifecycle = string.find(prop, "on") ~= nil
		local isInitial = prop == "onInit" or prop == "onStart"
		local isFn = typeof(value) == "function"

		if isLifecycle and not isInitial and isFn then
			Modding.addListener(config, prop)
		end
	end

	Objects[config.name] = config
	FromObject[config] = config.name

	Reflect.attachMetadata(
		config,
		{ identifier = "@singleton", ["s:loadOrder"] = config.loadOrder or math.huge }
	)

	return config :: any
end

--[=[
	Returns a singleton by its name. If the singleton hasn't been initialized, it will be
	initialized and returned.

	@within Singleton
	@param key
	@return SingletonConfig
]=]
Singleton.get = function(key: string): SingletonConfig
	local initialized = Objects[key]
	if initialized then
		return initialized
	end

	local singleton = Modding.getSingleton(key :: string)
	if not singleton then
		error(`[{PREFIX}:Singleton]: Singleton with name {key} doesn't exist.`)
	end

	local initializedSingleton = Singleton.create(singleton)

	return initializedSingleton
end

--[=[
	Creates a service on the server.
	
	@server
	@within Singleton

	@param config
]=]
Singleton.createService = function(config: SingletonConfig): SingletonConfig
	assert(IS_SERVER, `[{PREFIX}:Singleton]: Can't create a service in the client.`)

	if config.onPreRender then
		error(`[{PREFIX}:Singleton]: Can't bind onRender lifecycle on the server.`)
	end

	return Singleton.create(config)
end

--[=[
	Creates a controller on the client.
	
	@client
	@within Singleton

	@param config
]=]
Singleton.createController = function(config: SingletonConfig): SingletonConfig
	assert(not IS_SERVER, `[{PREFIX}:Singleton]: Can't create a controller on the server.`)

	return Singleton.create(config)
end

--[=[
	Returns a service by its name. This method should only be called by the server.

	@server
	@within Singleton

	@param key
]=]
Singleton.getService = function(key: string): SingletonConfig
	if not IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a service on the client.`)
	end

	return Singleton.get(key)
end

--[=[
	Returns a controller by its name.

	@client
	@within Singleton

	@param key
]=]
Singleton.getController = function(key: string): SingletonConfig
	if IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a controller on the server.`)
	end

	return Singleton.get(key)
end

return Singleton
