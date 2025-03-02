-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.modding)
local Reflect = require(script.Parent.reflect)
local Types = require(script.Parent.util.types)

local Promise = require(script.Parent.Parent.Promise)

local reuseThread = require(script.Parent.util.reuseThread)
local profileYielding = require(script.Parent.util.profileYielding)

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

-- Constants
local Objects = {}
local FromObject = {}

-- Module
local Singleton = {}

--[[
	Creates a Singleton.

	@param config - The singleton's config.
]]
function Singleton.create(t: Types.SingletonConfig): Types.Singleton
	assert(typeof(t) == "table", `[{PREFIX}:Singleton]: Can't create a singleton without a table.`)
	assert(typeof(t.name) == "string", `[{PREFIX}:Singleton]: Can't create a singleton without a name.`)
	assert(#t.name > 0, `[{PREFIX}:Singleton]: Can't create a singleton with an empty name.`)
	assert(not Objects[t.name], `[{PREFIX}:Singleton]: Singleton with name {t.name} already exists.`)

	for prop, value in t do
		local isLifecycle = string.find(prop, "on") ~= nil
		local isInitial = prop == "onInit" or prop == "onStart"
		local isFn = typeof(value) == "function"
		
		if isLifecycle and not isInitial and isFn then
			Modding.addListener(t, prop)
		end
	end

	Objects[t.name] = t
	FromObject[t] = t.name
	
	return t :: Types.Singleton
end

--[[
	Resolves a singleton by its constructor.

	@param ctor - The constructor.
	@returns - A resolved singleton.
]]
function Singleton.resolveSingleton(ctor: Types.Singleton): Types.Singleton
	assert(typeof(ctor) == "table", `[{PREFIX}:Modding]: Can't resolve a dependency which doesn't return a table.`)

	-- It already exists
	if Reflect.getMetadata(ctor, "_initialized") then
		return ctor
	end

	-- Attaches the _initialized tag
	Reflect.attachMetadata(ctor, { _initialized = true })

	local id = ctor.name

	-- Firstly initializes the singleton
	if ctor.onInit then
		debug.setmemorycategory(id)
			
		Promise.try(ctor.onInit, ctor, Singleton):expect()
	
		debug.resetmemorycategory()
	end

	-- Secondly, starts the singleton
	if ctor.onStart then
		reuseThread(
			profileYielding(function() ctor.onStart(ctor) end, id)
		)
	end

	return ctor
end

--[[
	Returns a singleton by its name.

	@param key - The singleton's name.
]]
Singleton.get = function(key: string | Instance): Types.Singleton
	if typeof(key) == "Instance" then
		assert(key:IsA("ModuleScript"), `[{PREFIX}:Singleton]: Can't get a singleton from a non-ModuleScript instance.`)
		
		-- Resolves the dependency
		key = Singleton.resolveSingleton(Modding.preload(key)) :: any

		-- This is true, as when resolved it will be registered on the table
		key = FromObject[key]

		print(key)
	end

	local initialized = Objects[key]
	if initialized then
		return initialized
	end

	local singleton = Modding.getSingleton(key :: string)
	if not singleton then
		error(
			`[{PREFIX}:Singleton]: Singleton with name {key} doesn't exist.`
		)
	end

	local initializedSingleton = Singleton.create(singleton)

	return initializedSingleton
end

--[[
	Returns a service by its name.

	@param key - The service's name.
]]
Singleton.getService = function(key: string | Instance): Types.Singleton
	if not IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a service on the client.`)
	end
	
	return Singleton.get(key)
end

--[[
	Returns a controller by its name.

	@param key - The controller's name.
]]
Singleton.getController = function(key: string): Types.Singleton
	if IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a controller on the server.`)
	end
	
	return Singleton.get(key)
end

--[[
	Creates a controller on the client.
	
	@param config - The controller config.
]]
Singleton.createController = function(t: Types.SingletonConfig): Types.Singleton
	assert(not IS_SERVER, `[{PREFIX}:Singleton]: Can't create a controller on the server.`)
	
	return Singleton.create(t)
end

--[[
	Creates a service on the server.
	
	@param config - The service config.
]]
Singleton.createService = function(t: Types.SingletonConfig): Types.Singleton
	assert(IS_SERVER, `[{PREFIX}:Singleton]: Can't create a service in the client.`)
	
	if t.onRender then
		error(
			`[{PREFIX}:Singleton]: Can't bind onRender lifecycle on the server.`
		)
	end
	
	return Singleton.create(t)
end

return Singleton