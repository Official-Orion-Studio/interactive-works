-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Dependencies
local Modding  = require(script.Parent.modding)
local Singleton = require(script.Parent.singleton)
local Reflect = require(script.Parent.reflect)

local Promise = require(script.Parent.Parent.Promise)

local logVerbose = require(script.Parent.util.logVerbose)
local reuseThread = require(script.Parent.util.reuseThread)
local profileYielding = require(script.Parent.util.profileYielding)

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

-- Variables
local hasStarted = false

-- Module
local Interactive = {
	logLevel = "top-level"
}

--[[
	Initializes all the processes, modules and paths that were added
	before this stage.
	
	It also initializes all lifecycle events, and resolve dependencies if 
	any were required.
]]
function Interactive.init(): nil
	if hasStarted then
		error("Interactive.init() can't be called twice.")
	end
	
	logVerbose(Interactive.logLevel, "Interactive.init() has been started.")
	
	local dependencies = Modding.getSingletons()
	
	--> Sorting for order
	table.sort(dependencies, function(a, b)
		return a.loadOrder < b.loadOrder
	end)
	
	do
		Modding.onListenerAdded(function(ctor, id) 
			RunService.Heartbeat:Connect(function(dt)
				reuseThread(
					profileYielding(function() ctor:onTick(dt) end, id)
				)
			end)
		end, "onTick")
	
		Modding.onListenerAdded(function(ctor, id)
			RunService.Stepped:Connect(function(_, dt)
				reuseThread(
					profileYielding(function() ctor:onPhysics(dt) end, id)
				)
			end)
		end, "onPhysics")
	
		if not IS_SERVER then
			Modding.onListenerAdded(function(ctor, id) 
				RunService.RenderStepped:Connect(function(dt)
					reuseThread(
						profileYielding(function() ctor:onRender(dt) end, id)
					)
				end)
			end, "onRender")
		end
	end
	
	local init = {}
	local start = {}
	
	for index, dependency in dependencies do
		local obj = { dependency, tostring(dependency) or index }
		
		if dependency.onInit then
			table.insert(init, obj)
		end
		
		if dependency.onStart then
			table.insert(start, obj)
		end
	end
	
	-- onInit method, at this point all singletons should be equally solved
	local promises = {}
	for _, bind in init do
		local dependency = bind[1]
		local id = bind[2]

		-- Has been already resolved by another script
		if Reflect.getMetadata(dependency, "_initialized") then
			continue
		end
		
		debug.setmemorycategory(id)
		logVerbose(Interactive.logLevel, "onInit " .. id)
		
		Reflect.attachMetadata(dependency, { _initialized = true })

		table.insert(promises, Promise.try(dependency.onInit, dependency, Interactive))
	end
	
	-- Waits for all onInit methods to be executed.
	Promise.all(promises):expect()
	
	debug.resetmemorycategory()
	
	-- onStart method, at this point all singletons should already exist and
	-- interdepending dependencies should all be available
	for _, bind in start do
		local dependency = bind[1]
		local id = bind[2]
		
		logVerbose(Interactive.logLevel, "onStart " .. id)
		
		reuseThread(
			profileYielding(function() dependency:onStart() end, id)
		)
	end
	
	return nil
end

--[[
	Adds a path where to look into for modules to load.
	
	@param path - Either a string or an instance.
]]
function Interactive.addPath(path: string | Instance): nil
	assert(not hasStarted, `[{PREFIX}:Interactive]: Can't add a path after the initialization.`)

	local preloadPaths
	local currentPath

	if typeof(path) == "string" then
		preloadPaths = string.split(path, "/")
		if #preloadPaths <= 0 then return end

		local service = table.remove(preloadPaths, 1)
		currentPath = game:GetService(service)

		if service == "StarterPlayer" then
			if preloadPaths[1] ~= "StarterPlayerScripts" then
				error(
					`StarterPlayer only supports StarterPlayerScripts.`
				)
			end

			if IS_SERVER then
				error(
					`The server can not load StarterPlayer content.`
				)
			end

			currentPath = Players.LocalPlayer:WaitForChild("PlayerScripts")

			table.remove(preloadPaths, 1)
		end

		--> Find the latest child
		for _, arg in preloadPaths do
			currentPath = currentPath:WaitForChild(arg)
		end
	else
		assert(path.ClassName ~= nil, "The path needs to be a string or an instance.")

		currentPath = path
	end

	for _, instance in currentPath:GetDescendants() do
		if instance:IsA("ModuleScript") then
			local preloaded = Modding.preload(instance)
			if not preloaded then
				continue
			end

			Modding.registerSingleton(preloaded, instance)
		end
	end

	return nil
end

--[[
	Sets the log level of the Interactive framework.
	
	@param level - The log level.
]]
function Interactive.setLogLevel(level: "verbose" | "top-level"): nil
	assert(typeof(level) == "string", `[{PREFIX}:Interactive]: The verbose level can't be any other than a string.`)
	
	Interactive.logLevel = level
	
	return nil
end

--[[
	Creates a service on the server.
	
	@param config - The service config.
]]
Interactive.createService = Singleton.createService

--[[
	Creates a controller on the client.
	
	@param config - The controller config.
]]
Interactive.createController = Singleton.createController

--[[
	Returns a service by its name.
	
	@param key - The service's name.
]]
Interactive.getService = Singleton.getService

--[[
	Returns a controller by its name.
	
	@param key - The controller's name.
]]
Interactive.getController = Singleton.getController

return Interactive