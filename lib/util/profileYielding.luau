-- Services
local RunService = game:GetService("RunService")

-- Constants
local IS_STUDIO = RunService:IsStudio()

--[[
    Profiles a function if we are on Studio.
    
    @param func - The function to profile.
    @param identifier - The identifier for the profile.
]]
return function(func, identifier)
	if IS_STUDIO then
		return function()
			-- We profile it if we are on Studio.
			debug.profilebegin(identifier)
			debug.setmemorycategory(identifier)
			
			func()
			
			debug.resetmemorycategory()
		end
	else
		return func
	end
end