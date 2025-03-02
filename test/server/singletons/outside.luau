local framework = require(game:GetService("ReplicatedStorage").lib)
local service = framework.getService(script.Parent.second)

service:printSomething("Hello world!")

return {}