-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.Parent.modding)
local Promise = require(script.Parent.Parent.Parent.Promise)

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--[=[
	@class Utility

	Utility is a module that contains utility functions that can be used
	across the project. Tries to expose a set of functions that can be
	used to simplify the development process, and perhaps make it easier
	to understand and maintain.
]=]
local InteractiveUtil = {}

--[=[
	Set ups a lifecycle for a given array of listeners data.

	@within Utility
	@param t -- The listeners table.
	@param lifecycle -- The lifecycle to listen for.
	@return ()
]=]
function InteractiveUtil.setupLifecycle(t: { any }, lifecycle: string): nil
	assert(
		lifecycle and lifecycle ~= "" and #lifecycle > 0,
		`[{PREFIX}:InteractiveUtil]: The lifecycle identifier can't be nullish.`
	)

	Modding.onListenerAdded(function(object)
		local _object = {}
		local id = object.name or 1

		_object.id = id
		_object.event = object
		_object.loadOrder = object.loadOrder or math.huge

		table.insert(t, _object)
	end, lifecycle)

	table.sort(t, function(a, b)
		return a.loadOrder > b.loadOrder
	end)

	return nil
end

--[=[
	Initializes a lifecycle for a given function.

	@within Utility
	@param t -- The object to initialize the lifecycle for.
	@param lifecycle -- The lifecycle to initialize.
	@param ... -- The arguments to pass to the function.
	@return ()
]=]
function InteractiveUtil.initLifecycle<U...>(t: { any }, lifecycle: string, ...: U...): nil
	local promises = {}
	local args = { ... }

	for _, object in t do
		table.insert(
			promises,
			Promise.defer(function(resolve)
				resolve(object.event[lifecycle](object.event, table.unpack(args)))
			end)
		)
	end

	Promise.all(promises)

	return nil
end

return InteractiveUtil
