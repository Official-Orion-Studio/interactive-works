local framework = require(game:GetService("ReplicatedStorage").lib)

local service
do
	service = {
		name = "secondService",
	}

	local function onInit(self, servicesBag)
		self.playerService = servicesBag.getService("playerService")
	end

	service.onInit = onInit

	local function onPlayerAdded(self, player)
		print(`{player} is being added to the server 2!`)
	
		self.playerService:doSomething()
	end

	service.onPlayerAdded = onPlayerAdded
	
	local function onPlayerRemoved(self, player)
		print(`{player} is being removed from the server!`)
	end

	service.onPlayerRemoved = onPlayerRemoved

	local function onTick(self, dt)
		print(`[SecondService]: Tick!`)
	end

	service.onTick = onTick

	local function printSomething(self, ...)
		print("[SecondService]: ", ...)
	end

	service.printSomething = printSomething
end

return framework.createService(service)