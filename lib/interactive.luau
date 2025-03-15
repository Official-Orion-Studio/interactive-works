-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Dependencies
local Components = require(script.Parent.components)
local Modding = require(script.Parent.modding)
local Reflect = require(script.Parent.reflect)
local Singleton = require(script.Parent.singleton)

local Promise = require(script.Parent.Parent.Promise)

local logVerbose = require(script.Parent.util.logVerbose)
local profileYielding = require(script.Parent.util.profileYielding)
local reuseThread = require(script.Parent.util.reuseThread)

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

-- Variables
local hasStarted = false

-- Module
local Interactive = {
	logLevel = "top-level",
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

	logVerbose("Interactive.init() has been started.")

	local dependencies = Modding.getSingletons()

	-- Sorting for order
	table.sort(dependencies, function(a, b)
		local aOrder = Reflect.getAttachedMetadata(a, "s:loadOrder")
		local bOrder = Reflect.getAttachedMetadata(b, "s:loadOrder")

		return aOrder < bOrder
	end)

	local ticks = {}
	local render = {}
	local physics = {}

	Modding.onListenerAdded(function(ctor, id)
		ticks[ctor] = id
	end, "onPostSimulation")

	Modding.onListenerAdded(function(ctor, id)
		render[ctor] = id
	end, "onPreRender")

	Modding.onListenerAdded(function(ctor, id)
		physics[ctor] = id
	end, "onPreSimulation")

	local init = {}
	local start = {}

	for index, dependency in dependencies do
		local identifier = Reflect.getAttachedMetadata(dependency, "identifier")
		if identifier ~= "@singleton" then
			warn(
				`[{PREFIX}:Interactive]: The dependency ${tostring(dependency)} is not a singleton.`
			)

			continue
		end

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

		debug.setmemorycategory(id)

		logVerbose("onInit " .. id)

		table.insert(promises, Promise.try(dependency.onInit, dependency, Interactive))
	end

	-- Waits for all onInit methods to be executed.
	Promise.all(promises)
		:catch(function(err)
			warn(
				`[{PREFIX}:Interactive]: An error occurred while initializing the dependencies. ${tostring(
					err
				)}`
			)
		end)
		:await()

	table.clear(promises)

	debug.resetmemorycategory()

	-- The rendering events
	do
		RunService.PostSimulation:Connect(function(dt)
			for dependency, id in ticks do
				reuseThread(profileYielding(function()
					dependency:onPostSimulation(dt)
				end, id))
			end
		end)

		RunService.PreSimulation:Connect(function(dt)
			for dependency, id in physics do
				reuseThread(profileYielding(function()
					dependency:onPreSimulation(dt)
				end, id))
			end
		end)

		if not IS_SERVER then
			RunService.PreRender:Connect(function(dt)
				for dependency, id in render do
					reuseThread(profileYielding(function()
						dependency:onPreRender(dt)
					end, id))
				end
			end)
		end
	end

	for _, bind in start do
		local dependency = bind[1]
		local id = bind[2]

		logVerbose("onStart " .. id)

		table.insert(
			promises,
			Promise.try(function()
				reuseThread(profileYielding(function()
					dependency:onStart()
				end, id))
			end)
		)
	end

	Promise.all(promises)
		:catch(function(err)
			warn(
				`[{PREFIX}:Interactive]: An error occurred while starting the dependencies. ${tostring(
					err
				)}`
			)
		end)
		:await()

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
		if #preloadPaths <= 0 then
			return
		end

		local service = table.remove(preloadPaths, 1)
		currentPath = game:GetService(service)

		if service == "StarterPlayer" then
			if preloadPaths[1] ~= "StarterPlayerScripts" then
				error(`StarterPlayer only supports StarterPlayerScripts.`)
			end

			if IS_SERVER then
				error(`The server can not load StarterPlayer content.`)
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
	assert(
		typeof(level) == "string",
		`[{PREFIX}:Interactive]: The verbose level can't be any other than a string.`
	)

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
