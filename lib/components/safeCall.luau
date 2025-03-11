--[[
    SafeCall is a function that wraps a function call in an xpcall 
    and prints the error if it occurs. This is also done
    asynchronously.
]]
return function(message: { string }, func: () -> (), printStack: boolean?)
	if printStack == nil then
		printStack = true
	end

	task.spawn(function()
		xpcall(func, function(err)
			local condition = type(err) == "string"

			if condition then
				condition = printStack
			end

			if condition then
				local stack = debug.traceback(err, 2)

				warn(unpack(message))
				warn(stack)
			else
				warn(unpack(message))
				warn(err)

				if printStack then
					warn(debug.traceback(nil, 2))
				end
			end
		end)
	end)
end
