--> Services
local RunService = game:GetService("RunService")

--> Dependencies
local Bindables = require(script.Parent.util.bindable)

--> Constants
local Singletons = {}
local ListenerAddedEvents = {}
local LifecycleEvents = {}

local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--> Module
local Modding = {}

--[[
	Registeres a singleton into the Modding module.

	@param ctor - The constructed object
	@param module? - An optional module from where the source is coming from.
]]
function Modding.registerSingleton(ctor: any, module: ModuleScript?): nil
	assert(typeof(ctor) == "table", `[{PREFIX}:Modding]: Can't register a dependency which doesn't return a table. {module and "Error on" .. module:GetFullName()}`)
	
	local id = ctor.name or (module and module.Name)
	assert(id ~= nil, `[{PREFIX}:Modding]: Id seems to be invalid. {module and "Script: " .. module:GetFullName()}`)
	
	--> Modifies the load order if there isn't any.
	ctor.loadOrder = ctor.loadOrder or math.huge
	
	table.insert(Singletons, ctor)
	
	return nil
end

--[[
	Returns all the registered singletons so far.
	
	@returns - All singletons.
]]
function Modding.getSingletons(): typeof(Singletons)
	return Singletons
end

--[[
	Adds a new listener for the given lifecycle.
]]
function Modding.addListener(ctor: any, lifecycleId: string): nil
	assert(typeof(lifecycleId) == "string", `[{PREFIX}:Modding]: Can't add a listener for a non-string identifier.`)
	
	local lifecycleListener = ListenerAddedEvents[lifecycleId]
	if not lifecycleListener then
		LifecycleEvents[lifecycleId] = ctor
		
		return nil
	end
	
	return lifecycleListener:Fire(ctor, lifecycleId)
end

--[[
	Used for metadata listeners, mostly for lifecycle events. But 
	it can be used to hear for other listeners.
	
	@param fn - The function to bind.
	@param id - The id to listen against.
	@returns - A signal-like object.
]]
function Modding.onListenerAdded(fn: (any) -> any, id: string): RBXScriptSignal
	assert(typeof(id) == "string", `[{PREFIX}:Modding]: Can't listen to additions on listeners for a non-string identifier.`)

	local listenerAddedEvent = ListenerAddedEvents[id]
	if not listenerAddedEvent then
		listenerAddedEvent = Bindables.new()
		ListenerAddedEvents[id] = listenerAddedEvent
	end
	
	--> For already existing listeners.
	if LifecycleEvents[id] then
		task.spawn(fn, LifecycleEvents[id], id)
	end
	
	return listenerAddedEvent:connect(fn)
end

return Modding
