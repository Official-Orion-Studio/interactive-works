local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "TestingComponent",
		instanceGuard = function(instance)
			-- Here you can typecheck the instance structure
			return true
		end,
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self, servicesBag)
		local playerService = servicesBag.getService("playerService")

		print(`TestingComponent has started for {self.instance:GetFullName()}!`)

		task.delay(5, function()
			self.instance:SetAttribute("Test", "Hello, World!")
		end)
	end

	component.onStart = onStart

	local function onPlayerAdded(self, player)
		print(`{player} has been added to the server (Component)!`)
	end

	component.onPlayerAdded = onPlayerAdded

	local function onAttributeChanged(self, attribute, value)
		print(`{self.instance:GetFullName()} has changed {attribute} to {value}!`)
	end

	component.onAttributeChanged = onAttributeChanged
end

return framework.createComponent(component)
