local Players = game:GetService("Players")

local framework = require(game:GetService("ReplicatedStorage").lib)
local util = framework.util

local service
do
	service = {
		name = "playerService",

		addedSignals = {},
		removedSignals = {},
	}

	local function onInit(self)
		util.setupLifecycle(self.addedSignals, "onPlayerAdded")
		util.setupLifecycle(self.removedSignals, "onPlayerRemoved")
	end

	service.onInit = onInit
	
	local function onStart(self)
		for _, player in Players:GetPlayers() do
			self:playerAdd(player)
		end
	
		Players.PlayerAdded:Connect(function(player)
			self:playerAdd(player)
		end)
	
		Players.PlayerRemoving:Connect(function(player)
			self:playerRemove(player)
		end)
	end

	service.onStart = onStart
	
	local function playerAdd(self, player)
		print(self.addedSignals)

		util.initLifecycle(self.addedSignals, "onPlayerAdded", player)
	end

	service.playerAdd = playerAdd
	
	local function playerRemove(self, player)
		print(self.removedSignals)

		util.initLifecycle(self.removedSignals, "onPlayerRemoved", player)
	end

	service.playerRemove = playerRemove
	
	local function doSomething(self, player)
		print(`We are now doing something with {player}!`)
	end

	service.doSomething = doSomething
end

return framework.createService(service)
