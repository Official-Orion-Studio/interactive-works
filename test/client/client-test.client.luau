local framework = require(game:GetService("ReplicatedStorage").lib)

do
    local st = os.clock()

    framework.setLogLevel("verbose")
    framework.addPath("StarterPlayer/StarterPlayerScripts/client/singletons") -- Add the paths to the singletons
    framework.init()

    print(
        "[CLIENT] Loaded all singletons in " .. math.floor((os.clock() - st) * 1000) .. "ms"
    )
end