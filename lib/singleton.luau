-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.modding)
local Reflect = require(script.Parent.reflect)

local Promise = require(script.Parent.Parent.Promise)

local profileYielding = require(script.Parent.util.profileYielding)
local reuseThread = require(script.Parent.util.reuseThread)

-- Types
export type Singleton = {
	constructor: ((self: Singleton) -> nil)?,
	onTick: ((self: Singleton, dt: number) -> nil)?,
	onPhysics: ((self: Singleton, dt: number) -> nil)?,
	onRender: ((self: Singleton, dt: number) -> nil)?,
	onInit: ((self: Singleton) -> nil)?,
	onStart: ((self: Singleton) -> nil)?,
}

export type SingletonConfig = {
	name: string,
	loadOrder: number?,
}

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
function Singleton.create(t: SingletonConfig): Singleton
	assert(typeof(t) == "table", `[{PREFIX}:Singleton]: Can't create a singleton without a table.`)
	assert(
		typeof(t.name) == "string",
		`[{PREFIX}:Singleton]: Can't create a singleton without a name.`
	)
	assert(#t.name > 0, `[{PREFIX}:Singleton]: Can't create a singleton with an empty name.`)
	assert(
		not Objects[t.name],
		`[{PREFIX}:Singleton]: Singleton with name {t.name} already exists.`
	)

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

	Reflect.attachMetadata(
		t,
		{ identifier = "@singleton", ["s:loadOrder"] = t.loadOrder or math.huge }
	)

	return t :: any
end

--[[
	Returns a singleton by its name.

	@param key - The singleton's name.
]]
Singleton.get = function(key: string): Singleton
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

--[[
	Returns a service by its name.

	@param key - The service's name.
]]
Singleton.getService = function(key: string | Instance): Singleton
	if not IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a service on the client.`)
	end

	return Singleton.get(key)
end

--[[
	Returns a controller by its name.

	@param key - The controller's name.
]]
Singleton.getController = function(key: string): Singleton
	if IS_SERVER then
		error(`[{PREFIX}:Singleton]: Can't get a controller on the server.`)
	end

	return Singleton.get(key)
end

--[[
	Creates a controller on the client.
	
	@param config - The controller config.
]]
Singleton.createController = function(t: SingletonConfig): Singleton
	assert(not IS_SERVER, `[{PREFIX}:Singleton]: Can't create a controller on the server.`)

	return Singleton.create(t)
end

--[[
	Creates a service on the server.
	
	@param config - The service config.
]]
Singleton.createService = function(t: SingletonConfig): Singleton
	assert(IS_SERVER, `[{PREFIX}:Singleton]: Can't create a service in the client.`)

	if t.onRender then
		error(`[{PREFIX}:Singleton]: Can't bind onRender lifecycle on the server.`)
	end

	return Singleton.create(t)
end

return Singleton
