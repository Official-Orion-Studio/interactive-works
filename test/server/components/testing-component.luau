local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "TestingComponent",
		defaults = {
			something = "this is a default",
		},
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self)
		print(`TestingComponent has started for {self.instance:GetFullName()}!`)
		print("It's attributes are: ", self.attributes)

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
