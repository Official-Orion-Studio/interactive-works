local framework = require(game:GetService("ReplicatedStorage").lib)

local component
do
	component = {
		tag = "second",

		defaults = {
			text = "Hello, World!",
		},
	}

	local function constructor(self) end

	component.constructor = constructor

	local function onStart(self)
		print(`Second has started for {self.instance:GetFullName()}!`)
		print(`Default text is: {self.attributes.text}`, getmetatable(self.attributes))
	end

	component.onStart = onStart
end

return framework.createComponent(component)
