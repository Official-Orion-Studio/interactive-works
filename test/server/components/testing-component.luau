local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "testing",
		defaults = {
			something = "this is a default",
		},
		ancestors = { workspace },
		ignoreFlags = true,
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self)
		print(`TestingComponent has started for {self.instance:GetFullName()}!`)
		print("It's attributes are: ", self.attributes)
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
