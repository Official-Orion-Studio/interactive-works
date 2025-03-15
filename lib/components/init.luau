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

--[=[
	@interface ComponentConfig
	.tag string,
	.defaults? { [string]: any },
	.instanceGuard? (instance: Instance) -> boolean,
	.constructor? () -> (),
	.onStart? (singletonsBag: any) -> (),
	.onAttributeChanged? (attribute: string, value: any) -> (),
	.onTick? (dt: number) -> (),
	.onPhysics? (dt: number) -> (),
	.onRender? (dt: number) -> (),

	@within Components

	The interface for a ComponentConfig. The initial state of a component.
]=]
type ComponentConfig = {
	tag: string,
	defaults: { [string]: any },
	instanceGuard: ((instance: Instance) -> boolean)?,
	constructor: (() -> ())?,
	onStart: ((singletonsBag: any) -> ())?,
	onAttributeChanged: ((attribute: string, value: any) -> ())?,
	onTick: ((dt: number) -> ())?,
	onPhysics: ((dt: number) -> ())?,
	onRender: ((dt: number) -> ())?,
}

--[=[
	@interface Component
	.instance Instance -- The instance of the component.
	.attributes { [string]: any } -- The attributes of the component.

	@within Components

	The interface for a Component.
]=]
type Component = {
	instance: Instance,
	attributes: { [string]: any },
}

--[=[
	@class Components

	Manages all components in the game, listening for new instances to be added
	and cleaning their references them when they are removed.

	Components are a powerful tool to create modular and reusable code in your game,
	which will depend on instances being added/removed.

	They can also include lifecycles made by services, and also add lifecycles 
	that could be used by other components or singletons in the game.

	This is an example usage of components:
	```lua title="src/server/components/myComponent.luau"
	local framework = require("...")

	local component = {
		tag = "MyComponent",
	}

	function component:constructor()
		...
	end

	function component:onStart(singletonsBag)
		...
	end

	function component:onAttributeChanged(attribute: string, value: any)
		...
	end

	function component:onLifecycle(...)
		...
	end

	return framework.createComponent(component)
	```
]=]
local Components = {
	name = "_componentsService",
}

--[[ @ignore ]]
function Components:onInit(servicesBag)
	self.servicesBag = servicesBag

	self.activeComponents = {}
	self.cleanupComponents = {}
end

--[=[
	Registers all components and listens for new instances to be added
	to the game.

	@ignore
]=]
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

--[=[
	Adds a component to an instance linked by the created object. This
	will register the component, start its lifecycles, bind callbacks to the
	required listeners and setup their attributes and properties.
		
	:::note
	This function can be called upon a component that is yet to be registered, though
	it is not recommended. Best practice is to rely on `framework.createComponent`,
	as it is guaranteed to initialize the component correctly.

	This method should only be used for debugging purposes when isolating a single 
	component.
	:::

	@within Components
	@param instance -- The instance to add the component to.
	@param ctor ComponentConfig -- The component's constructor.
]=]
function Components:addComponent(instance: Instance, ctor: any)
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

--[=[
	Setups a component, finally running its lifecycles and constructing it
	with the given instance.

	In the most raw form, this function is responsible for setting up a component
	and running its lifecycle methods. Can be used to quickly debug a component structure.
	```lua title="/lib/components/init.luau"
	local frameworkComponents = require(...)
	local component = {}

	function component:constructor()
		print("Hello, world!")
	end

	function component:onStart()
		print("I have started!")
	end

	frameworkComponents:setupComponent(<Instance>, { ... }, component, function()
		component:constructor()
	end)
	```

	:::warning
	You should not call this function directly, instead, use `framework.createComponent`.
	:::

	@param instance -- The instance to add the component to.
	@param attributes -- The attributes of the instance.
	@param component ComponentConfig -- The component to setup.
	@param construct -- The constructor of the component, sometimes this may be a deferred constructor.
]=]
function Components:setupComponent(
	instance: Instance,
	attributes: { [string]: any },
	component: any,
	construct: () -> ()
)
	BaseComponent:setInstance(component, instance, attributes)
	construct()

	if component.onStart then
		safeCall({
			"[Components] Failed to start '" .. (tostring(ctor) .. "' for"),
			instance,
			"[" .. (instance:GetFullName() .. "]"),
		}, function()
			return component:onStart(self.servicesBag)
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

--[=[
	Returns the attributes of an instance.

	@param instance -- The instance to get the attributes from.
	@param ctor -- The component's constructor.

	@ignore
]=]
function Components:getAttributes(instance: Instance, ctor: any)
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

--[=[
	Removes a component from an instance.

	@param instance -- The instance to remove the component from.
	@param ctor -- The component's constructor.

	@ignore
]=]
function Components:removeComponent(instance: Instance, ctor: any) end

-- Export
local singleton
do
	singleton = Singleton.create(Components)
	Modding.registerSingleton(singleton, script)
end

return singleton
