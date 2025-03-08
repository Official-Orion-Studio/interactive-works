local framework = require(game:GetService("ReplicatedStorage").lib)

do
	local st = os.clock()

	framework.addPath("ServerScriptService/server") -- Add the paths to the singletons
	framework.init()

	print("[SERVER] Loaded all singletons in " .. math.floor((os.clock() - st) * 1000) .. "ms")
end
