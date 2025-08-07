local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "first",
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self)
		print(`First has started for {self.instance:GetFullName()}!`)
	end

	component.onStart = onStart
end

return framework.createComponent(component)
