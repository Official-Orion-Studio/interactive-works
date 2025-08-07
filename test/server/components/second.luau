local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "second",
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self)
		print(`Second has started for {self.instance:GetFullName()}!`)
	end

	component.onStart = onStart
end

return framework.createComponent(component)
