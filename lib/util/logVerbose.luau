-- Services
local RunService = game:GetService("RunService")

-- Constants
local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

--[[
    Logs a message to the console if the log level is set to verbose.

    @param logLevel - The log level.
    @param ... - The message to log.
]]
return function(logLevel: string, ...): nil
	if logLevel == "verbose" then
		print(`[{PREFIX}:Interactive (verbose)]`, ...)
	end

	return nil
end
