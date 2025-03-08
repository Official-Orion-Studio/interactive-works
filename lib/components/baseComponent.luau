-- Module
local BaseComponent = {}
BaseComponent.__tostring = function(self)
	return self.tag
end

--[[
    Extends a component constructor from the BaseComponent class.

    @param t - The constructor.
]]
function BaseComponent.extend(t: any)
	t.super = BaseComponent -- The super class if it is required.

	return setmetatable(t, BaseComponent)
end

--[[
    Constructs a new BaseComponent.

    @returns - The new BaseComponent.
]]
function BaseComponent:constructor()
	self.instance = nil
	self.attributes = {}
end

--[[
    Initializes the component's instance and attributes.

    @param instance - The component's instance.
    @param attributes - The component's attributes.
]]
function BaseComponent:setInstance(
	component: any,
	instance: Instance,
	attributes: { [string]: any }
)
	component.instance = instance
	component.attributes = attributes
end

--[[
    Destroys the component.
]]
function BaseComponent:destroy()
	setmetatable(self, nil)

	self = nil
end

-- Export
return BaseComponent
