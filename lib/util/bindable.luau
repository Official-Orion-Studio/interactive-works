--> Services
local RunService = game:GetService("RunService")

--> Constants
local Objects = {}

local IS_STUDIO = RunService:IsStudio() -- Debugging purposes really

--> Module
local Bindable = {}
Bindable.__index = Bindable

--> util functions
local freeRunnerThread = nil

--[[
	Acquires the currently idle handler runner thread. (based from Signal/FastSpawn solution)
	
	@param fn - The function to execute.
]]
local function acquireRunnerThreadAndCallEventHandler(fn, ...): nil
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	
	--> The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
	
	return nil
end

--[[
	Coroutine runner that creates coroutines off itself. The coroutine can be repeatedly 
	resumed with functions to run followed by the argument to run them with.
	
	@param args - The arguments.
]]
local function runEventHandlerInFreeThread(...): nil
	acquireRunnerThreadAndCallEventHandler(...)
	
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
	
	return nil
end

--> Methods

--[[
	Creates a new bindable object to interact with.

	@param identifier - The bindable's identifier.
]]
function Bindable.new(identifier: string?): Bindable
	local self = setmetatable({}, Bindable)

	self.name = identifier

	self._onInvoke = nil

	self._connections = {}
	self._middlewares = {}

	if identifier ~= nil then
		Objects[identifier] = self
	end

	return self
end

--[[
	Does a direct lookup for the existing bindable. Creates a new one 
	if one didn't already existed.
]]
function Bindable.from(identifier: string): Bindable
	assert(typeof(identifier) == "string", `[Network:Bindables]: Identifiers must be strings. Identifier passed down: {identifier}`)
	
	local object = Objects[identifier]
	
	if object == nil then
		object = Bindable.new(identifier)
	end
	
	return object
end

--[[
	Invokes all connected listeners.

	@param args - The arguments to pass onto the listeners.
]]
function Bindable:fire(...: any): nil
	local connections = self._connections
	
	for _, connection in connections do
		if connection.connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			
			task.spawn(freeRunnerThread, connection._fn, ...)
		end
	end
	
	return nil
end

--[[
	Waits until the bindable fires an event and returns the passed arguments.
	
	@return ... - The arguments passed when the bindable fired.
]]
function Bindable:wait(): ...any
	local thread = coroutine.running()
	assert(thread, "[Network:Bindables]: :Wait() must be called from a coroutine.")

	local connection
	connection = self:event(function(...)
		connection.disconnect() --> Disconnect after the first call
		coroutine.resume(thread, ...) --> Resume the coroutine with the arguments
	end)

	return coroutine.yield() --> Yield until the coroutine is resumed
end

--[[
	Invokes for a result from the callback previously binded to such event. If
	there was an error, the error message is also returned.
	
	@param args - The arguments to pass onto the listener.
]]
function Bindable:invoke<T>(...: any): T
	local fn = coroutine.wrap(
		function(...)
			local onInvoke = self._onInvoke
			
			if not onInvoke then
				error(
					`[Network:Bindables]: There seems to be a unintended invoke from [{self.name}] before a callback is binded.`
				)
			end
			
			return onInvoke(...)
		end
	)

	return fn(...)
end

--[[
	Connects a function to listen for any invokes on the Bindable.
	
	@param fn - The function to connect.
	@return Connection - A connection object.
]]
function Bindable:event<U...>(fn: (U...) -> unknown): { disconnect: () -> nil, connected: boolean }
	assert(
		type(fn) == "function", 
		`[Network:Bindables]: Can't connect anything that is not a function.`
	)

	local connection
	connection = {
		disconnect = function()
			if not connection.connected then
				if IS_STUDIO then print(debug.traceback(`[DEBUG]: Can't disconnect an already connected function.`)) end

				return
			end

			connection.connected = false

			table.remove(self._connections, table.find(self._connections, fn))
		end,
		
		connected = true,
		
		--> Wraps around for middlewares.
		_fn = function(...: any): nil
			--> We check for the middlewares connected to the remote.
			local middlewares = self._middlewares

			if #middlewares == 0 then
				fn(...)
				
				return nil
			end

			local result
			for _, fn in middlewares do
				if result ~= nil then
					local final = { fn(table.unpack(result)) }
					if #final == 0 then
						continue
					end

					result = final
				else
					result = { fn(...) }
				end
			end
			
			return nil
		end,
	}
	
	table.insert(self._connections, connection)

	return connection
end

--[[
	Connects a bindable once and then destroys the connection.

	@param fn - The function to call once.
]]
function Bindable:once<U...>(fn: (U...) -> unknown): nil
	local connection

	connection = self:connect(
		function(...)
			connection:disconnect()

			fn(...)
		end
	)

	return nil
end

--[[
	Binds a function for when bindable is invoked.

	@param fn - The function to bind.
]]
function Bindable:onInvoke<U...>(fn: (U...) -> unknown): nil
	self._onInvoke = function(...)
		local success, returns = pcall(
			function(...)
				return { fn(...) }
			end,
			...
		)

		if success then
			return table.unpack(returns)
		end
		
		return returns
	end
	
	return nil
end

--[[
	Bindables can also hold middlewares, they work the same as in the network 
	middlewares.
	
	@param fn - The middleware's function.
]]
function Bindable:middleware<U...>(fn: (U...) -> unknown): nil
	table.insert(self._middlewares, fn)
	
	return nil
end

--[[
	Destroys itself. Freeing all the memory attached to it.
]]
function Bindable:destroy(): nil
	setmetatable(self, nil)
	self = nil
	
	return nil
end

--> These are also valid
Bindable.Connect = Bindable.event
Bindable.connect = Bindable.Connect

--> Types export
export type ConnectionLike = <U...>(self: Bindable, fn: (U...) -> unknown) -> { disconnect: () -> nil, connected: boolean }

export type Bindable = {
	fire: (self: Bindable, ...any) -> nil,
	wait: (self: Bindable) -> ...any,
	invoke: <T>(self: Bindable, ...any) -> T,
	
	event: ConnectionLike,
	connect: ConnectionLike,
	Connect: ConnectionLike,
	
	once: <U...>(self: Bindable, fn: (U...) -> unknown) -> nil,
	onInvoke: <U...>(self: Bindable, fn: (U...) -> unknown) -> nil,
	middleware: <U...>(self: Bindable, fn: (U...) -> unknown) -> nil
}

--> Export
return Bindable
