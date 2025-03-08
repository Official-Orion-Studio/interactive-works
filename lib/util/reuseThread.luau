local inactiveThread

--[[
    Spawns a reusable thread.
    
    @param func - The function to run.
]]
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

--[[
    Spawns a thread.
    
    @param func - The function to run.
]]
return function(func)
	if inactiveThread then
		task.spawn(inactiveThread, func)
	else
		task.spawn(reusableThread, func)
	end
end
