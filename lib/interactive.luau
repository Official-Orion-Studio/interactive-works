--> Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--> Dependencies
local Modding  = require(script.Parent.modding)
local Singleton = require(script.Parent.singleton)

local Promise = require(script.Parent.Parent.Promise)

--> Constants
local IS_STUDIO = RunService:IsStudio()
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--> Variables
local hasStarted = false
local inactiveThread

--> Module
local Interactive = {
	logLevel = "top-level"
}

--> Utility functions
local function logVerbose(...): nil
	if Interactive.logLevel == "verbose" then
		print(`[{PREFIX}:Interactive (verbose)]`, ...)
	end

	return nil
end

local function reusableThread(func)
	local thread = coroutine.running()
	while true do
		if inactiveThread == thread then
			inactiveThread = nil
		end
		
		func()

		if inactiveThread ~= nil then
			break
		end
		
		inactiveThread = thread
		func = coroutine.yield()
	end
end

local function profileYielding(func, identifier)
	if IS_STUDIO then
		return function()
			--> We profile it if we are on Studio.
			debug.profilebegin(identifier)
			debug.setmemorycategory(identifier)
			
			func()
			
			debug.resetmemorycategory()
		end
	else
		return func
	end
end

local function reuseThread(func)
	if inactiveThread then
		task.spawn(inactiveThread, func)
	else
		task.spawn(reusableThread, func)
	end
end

--> Methods

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
	
	--> Sorting for order
	table.sort(dependencies, function(a, b)
		return a.loadOrder < b.loadOrder
	end)
	
	local ticks = {}
	local render = {}
	local physics = {}
	
	Modding.onListenerAdded(function(ctor, id) ticks[ctor] = id end, "onTick")
	Modding.onListenerAdded(function(ctor, id) render[ctor] = id end, "onRender")
	Modding.onListenerAdded(function(ctor, id) physics[ctor] = id end, "onPhysics")
	
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
	
	--> onInit method, at this point all singletons should be equally solved
	local promises = {}
	for _, bind in init do
		local dependency = bind[1]
		local id = bind[2]
		
		debug.setmemorycategory(id)
		
		logVerbose("onInit " .. id)
		
		table.insert(promises, Promise.try(dependency.onInit, dependency))
	end
	
	--> Waits for all onInit methods to be executed.
	Promise.all(promises):expect()
	
	debug.resetmemorycategory()
	
	--> The rendering events
	do
		RunService.Heartbeat:Connect(function(dt)
			for id, dependency in ticks do
				reuseThread(
					profileYielding(function() dependency:onTick(dt) end, id)
				)
			end
		end)
		
		RunService.Stepped:Connect(function(_, dt)
			for dependency, id in physics do
				reuseThread(
					profileYielding(function() dependency:onPhysics(dt) end, id)
				)
			end
		end)
		
		if not IS_SERVER then
			RunService.RenderStepped:Connect(function(dt)
				for id, dependency in render do
					reuseThread(
						profileYielding(function() dependency:onRender(dt) end, id)
					)
				end
			end)
		end
	end
	
	--> onStart method, at this point all singletons should already exist and
	--> interdepending dependencies should all be available
	for _, bind in start do
		local dependency = bind[1]
		local id = bind[2]
		
		logVerbose("onStart " .. id)
		
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

	local preload = function(module: ModuleScript)
		local start = os.clock()
		local success, value = pcall(function()
			return require(module)
		end)

		local endTime = math.floor((os.clock() - start) * 1000)

		if not success then
			error(
				module:GetFullName() .. (" failed to preload (" .. (tostring(endTime) .. "ms): " .. tostring(value)))
			)
		end
		
		if not value.constructor then
			return value
		end
		
		value:constructor() --> Firstly construct the service/controller
		
		return value
	end

	for _, instance in currentPath:GetDescendants() do
		if instance:IsA("ModuleScript") then
			Modding.registerSingleton(preload(instance), instance)
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

return Interactive