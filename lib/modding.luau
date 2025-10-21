-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Bindables = require(script.Parent.Parent.Bindables)
local Promise = require(script.Parent.Parent.Promise)

-- Constants
local Singletons = {}
local ListenerAddedEvents = {}
local LifecycleEvents = {}

local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--[=[
	@interface ConnectionLike
	@within Modding

	.disconnect () -> nil -- Disconnects the connection.
	.connected boolean -- Whether the connection is connected or not.
]=]
type ConnectionLike = {
	disconnect: () -> nil,
	connected: boolean,
}

--[=[
	@class Modding

	Modding is a module that allows you to register singletons and components
	into the game. It also allows you to listen to lifecycle events and other
	events that are triggered by the module.
]=]
local Modding = {}

--[=[
	Preloads a module and returns the constructed object.

	@param module -- The module to preload.
	@return SingletonConfig
]=]
function Modding.preload(module: ModuleScript): any
	assert(
		module:IsA("ModuleScript"),
		`[{PREFIX}:Modding]: Can't preload a non-ModuleScript object.`
	)

	local start = os.clock()
	local success, value = Promise.new(function(resolve)
		return resolve(require(module))
	end)
		:catch(function(err)
			warn(
				`[{PREFIX}:Modding]: Error on preloading ${module:GetFullName()}. More information: {err}`
			)
		end)
		:await()

	local endTime = math.floor((os.clock() - start) * 1000)

	if not success then
		error(
			module:GetFullName()
				.. (" failed to preload (" .. (tostring(endTime) .. "ms): " .. tostring(value)))
		)
	end

	-- If it isn't a table, we can't register it.
	if typeof(value) ~= "table" then
		return nil
	end

	if not value.constructor then
		return value
	end

	value:constructor() --> Firstly construct the service/controller

	return value
end

--[=[
	Registeres a singleton into the Modding module.

	@param ctor -- The constructed object
	@param module? -- An optional module from where the source is coming from.
]=]
function Modding.registerSingleton(ctor: any, module: ModuleScript?): nil
	assert(
		typeof(ctor) == "table",
		`[{PREFIX}:Modding]: Can't register a dependency which doesn't return a table. {module and "Error on" .. module:GetFullName()}`
	)

	local id = ctor.name
	if not id then
		return -- This might not be a service, and if it wasn't we can't register it without a name
	end

	-- Modifies the load order if there isn't any.
	ctor.loadOrder = ctor.loadOrder or math.huge

	table.insert(Singletons, ctor)

	return nil
end

--[=[
	Registers a component into the Modding module.

	@param ctor -- The constructed object
	@param module? -- An optional module from where the source is coming from.
]=]
function Modding.registerComponent(ctor: any, module: ModuleScript): nil
	assert(
		typeof(ctor) == "table",
		`[{PREFIX}:Modding]: Can't register a dependency which doesn't return a table. {module and "Error on" .. module:GetFullName()}`
	)

	local id = ctor.tag
	if not id then
		return -- This might not be a component.
	end

	-- Modifies the load order if there isn't any.
	ctor.loadOrder = ctor.loadOrder or math.huge

	table.insert(Singletons, ctor)

	return nil
end

--[=[
	Constructs a new binding to a deferred constructor.

	:::note
	This is only used in components at the moment.
	:::

	@param ctor SingletonConfig -- The constructor to bind.
]=]
function Modding.getDeferredConstructor(ctor)
	local obj = setmetatable({
		instance = nil,
		attributes = {},
	}, { __index = ctor })

	return {
		obj,
		function(...)
			local result
			do
				result = obj.constructor ~= nil and obj:constructor(...) or nil
			end
			assert(result == nil or result == obj, "Constructors should return nil.")
		end,
	}
end

--[=[
	Returns all the registered singletons so far.
	
	@return { SingletonConfig } -- All singletons.
]=]
function Modding.getSingletons(): typeof(Singletons)
	return Singletons
end

--[=[
	Returns a singleton by its id.
	
	@param id -- The id of the singleton.
	@return SingletonConfig -- The singleton.
]=]
function Modding.getSingleton(id: string)
	local singleton
	for _, s in Singletons do
		if s.name == id then
			singleton = s

			break
		end
	end

	return singleton
end

--[=[
	Adds a new listener for the given lifecycle.

	@param ctor -- The constructor to bind.
	@param lifecycleId -- The lifecycle id to listen against.
]=]
function Modding.addListener(ctor: any, lifecycleId: string): nil
	assert(
		typeof(lifecycleId) == "string",
		`[{PREFIX}:Modding]: Can't add a listener for a non-string identifier.`
	)

	local lifecycleListener = ListenerAddedEvents[lifecycleId]
	if not lifecycleListener then
		if not LifecycleEvents[lifecycleId] then
			LifecycleEvents[lifecycleId] = {}
		end

		table.insert(LifecycleEvents[lifecycleId], ctor)

		return nil
	end

	return lifecycleListener:fire(ctor, lifecycleId)
end

--[=[
	Used for metadata listeners, mostly for lifecycle events. But 
	it can be used to hear for other listeners.
	
	@param fn -- The function to bind.
	@param id -- The id to listen against.
	@return ConnectionLike 
]=]
function Modding.onListenerAdded(fn: (any) -> any, id: string): RBXScriptSignal
	assert(
		typeof(id) == "string",
		`[{PREFIX}:Modding]: Can't listen to additions on listeners for a non-string identifier.`
	)

	local listenerAddedEvent = ListenerAddedEvents[id]
	if not listenerAddedEvent then
		listenerAddedEvent = Bindables.new()
		ListenerAddedEvents[id] = listenerAddedEvent
	end

	--> For already existing listeners.
	if LifecycleEvents[id] then
		for _, listener in LifecycleEvents[id] do
			task.spawn(fn, listener, id)
		end
	end

	return listenerAddedEvent:connect(fn)
end

return Modding
