-- Services
local CollectionService = game:GetService("CollectionService")

-- Dependencies
local BaseComponent = require(script.baseComponent)
local ComponentsUtil = require(script.util)
local Janitor = require(script.Parent.Parent.Janitor)
local Modding = require(script.Parent.modding)
local Reflect = require(script.Parent.reflect)
local Singleton = require(script.Parent.singleton)

local merge = require(script.merge)
local safeCall = require(script.safeCall)

-- Module
local Components = {
	name = "components",
}

--[[ @ignore ]]
function Components:onInit(servicesBag)
	self.servicesBag = servicesBag

	self.activeComponents = {}
	self.cleanupComponents = {}
end

--[[ @ignore ]]
function Components:onStart()
	local components = ComponentsUtil.getComponents()

	table.sort(components, function(a, b)
		local aOrder = Reflect.getAttachedMetadata(a, "s:loadOrder")
		local bOrder = Reflect.getAttachedMetadata(b, "s:loadOrder")

		return aOrder < bOrder
	end)

	for _, ctor in ipairs(components) do
		local tag = ctor.tag
		if not tag then
			warn(
				`[Components]: Can't register a dependency which doesn't has a tag. {module and "Error on" .. module:GetFullName()}`
			)

			continue
		end

		local identifier = Reflect.getAttachedMetadata(ctor, "identifier")
		if identifier ~= "@component" then
			warn(
				`[Components]: Can't register a dependency which isn't a component. {module and "Error on" .. module:GetFullName()}`
			)

			continue
		end

		local predicate = ctor.instanceGuard
			or function(instance)
				return CollectionService:HasTag(instance, tag)
			end

		local instanceAdded = function(instance: Instance)
			warn("The instance is being registered?")

			if predicate and not predicate(instance) then
				warn(
					`[Components]: Instance {instance:GetFullName()} doesn't comply with the instance guard provided {tag}.`
				)

				return
			end

			self:addComponent(instance, ctor)
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(instanceAdded)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			self:removeComponent(instance, ctor)
		end)

		for _, instance in CollectionService:GetTagged(tag) do
			safeCall({
				"[Components] Failed to instantiate '" .. (tostring(ctor) .. "' for"),
				instance,
				"[" .. (instance:GetFullName() .. "]"),
			}, function()
				return instanceAdded(instance)
			end)
		end
	end
end

--[[
	Adds a component to an instance.

	@param instance - The instance to add the component to.
	@param ctor - The component's constructor.
]]
function Components:addComponent(instance: Instance, ctor: any)
	warn("The component is being added?")

	local attributes = self:getAttributes(instance, ctor)

	local activeComponents = self.activeComponents[instance]
	if not activeComponents then
		activeComponents = {}
		self.activeComponents[instance] = activeComponents
	else
		return
	end

	activeComponents[ctor] = true

	self:setupComponent(instance, attributes, table.unpack(Modding.getDeferredConstructor(ctor)))
end

--[[
	Setups a component, finally running its lifecycles and constructing it
	with the given instance.
]]
function Components:setupComponent(
	instance: Instance,
	attributes: { [string]: any },
	component: any,
	construct: () -> ()
)
	BaseComponent:setInstance(component, instance, attributes)
	construct()

	warn("The component is being setup?")

	if component.onStart then
		safeCall({
			"[Components] Failed to start '" .. (tostring(ctor) .. "' for"),
			instance,
			"[" .. (instance:GetFullName() .. "]"),
		}, function()
			return component.onStart(component, self.servicesBag)
		end)
	end

	self.cleanupComponents[component] = Janitor.new()

	for attribute in attributes do
		self.cleanupComponents[component]:Add(
			instance:GetAttributeChangedSignal(attribute):Connect(function()
				local value = instance:GetAttribute(attribute)

				safeCall({
					"[Components] Failed to update '" .. (tostring(ctor) .. "' for"),
					instance,
					"[" .. (instance:GetFullName() .. "]"),
				}, function()
					if component.onAttributeChanged then
						return component:onAttributeChanged(attribute, value)
					end
				end)
			end)
		)
	end
end

--[[
	Returns the attributes of an instance.

	@param instance - The instance to get the attributes from.
	@param ctor - The component's constructor.
]]
function Components:getAttributes(instance: Instance, ctor)
	local attributes = instance:GetAttributes()
	local _attributes = {}

	local defaults = ctor.defaults or {}

	local merged = merge(defaults, attributes)
	for key, value in merged do
		local attribute = instance:GetAttribute(key)
		if not attribute and value ~= attribute then
			instance:SetAttribute(key, value)
		end
	end

	return merge(defaults, attributes)
end

--[[
	Removes a component from an instance.

	@param instance - The instance to remove the component from.
	@param ctor - The component's constructor.
]]
function Components:removeComponent(instance, ctor) end

-- Export
local singleton
do
	singleton = Singleton.create(Components)
	Modding.registerSingleton(singleton, script)
end

return singleton
