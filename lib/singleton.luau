--> Services
local RunService = game:GetService("RunService")

--> Dependencies
local Modding = require(script.Parent.modding)

--> Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--> Types
type ServiceConfig = {
	name: string,
	loadOrder: number?,
	
	onInit: (() -> unknown?)?,
	onStart: (() -> unknown?)?,
	onTick: ((dt: number) -> unknown?)?,
	onPhysics: ((dt: number) -> unknown?)?,
}

type ControllerConfig = ServiceConfig & { onRender: ((dt: number) -> unknown)? }

--> Module
local Singleton = {}

--[[
	Creates a Singleton.

	@param config - The singleton's config.
]]
function Singleton.create(t: ServiceConfig): Singleton
	local singleton = t
	
	for prop, value in singleton do
		local isLifecycle = string.find(prop, "on") ~= nil
		local isInitial = prop == "onInit" or prop == "onStart"
		local isFn = typeof(value) == "function"
		
		if isLifecycle and not isInitial and isFn then
			Modding.addListener(singleton, prop)
		end
	end
	
	return singleton
end

--[[
	Creates a controller on the client.
	
	@param config - The controller config.
]]
Singleton.createController = function(t: ControllerConfig): Singleton
	assert(not IS_SERVER, `[{PREFIX}:Singleton]: Can't create a controller on the server.`)
	
	return Singleton.create(t)
end

--[[
	Creates a service on the server.
	
	@param config - The service config.
]]
Singleton.createService = function(t: ServiceConfig): Singleton
	assert(IS_SERVER, `[{PREFIX}:Singleton]: Can't create a service in the client.`)
	
	if t.onRender then
		error(
			`[{PREFIX}:Singleton]: Can't bind onRender lifecycle on the server.`
		)
	end
	
	return Singleton.create(t)
end

--> Types exports
export type Singleton = typeof(Singleton.create({}))

return Singleton