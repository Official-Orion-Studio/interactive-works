-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.Parent.modding)
local Reflect = require(script.Parent.Parent.reflect)

-- Types
export type Component = {
	instance: Instance,

	onPostSimulation: ((self: Component, dt: number) -> nil)?,
	onPreSimulation: ((self: Component, dt: number) -> nil)?,
	onPreRender: ((self: Component, dt: number) -> nil)?,
}

export type ComponentConfig = {
	tag: string,
	loadOrder: number?,
	defaults: { [string]: any }?,
	instanceGuard: ((instance: Instance) -> boolean)?,
	ancestors: { Instance }?,
	ignoreFlags: boolean?,

	constructor: ((self: ComponentConfig) -> nil)?,
	onStart: ((self: Component) -> nil)?,
}

-- Constants
local Objects = {}

local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

local AVOID_LIFECYCLES = {
	"onStart",
	"onInit",
	"onPostSimulation",
	"onPreRender",
	"onPreSimulation",
}

--[=[
	@class ComponentUtil
	
	ComponentUtil is a utility module that allows you to create components, do not
	use this module directly, use the `Interactive.createComponent()` method instead.
]=]
local ComponentsUtil = {}

--[=[
	Creates a Component.

	@within ComponentUtil
	@param config ComponentConfig -- The component's config.
]=]
function ComponentsUtil.createComponent(config: any): Component
	assert(
		typeof(config) == "table",
		`[{PREFIX}:component]: Can't create a component without a table.`
	)
	assert(
		typeof(config.tag) == "string",
		`[{PREFIX}:Component]: Can't create a component without a name.`
	)
	assert(#config.tag > 0, `[{PREFIX}:Component]: Can't create a component with an empty name.`)
	assert(
		not Objects[config.tag],
		`[{PREFIX}:Component]: Component with tag {config.tag} already exists.`
	)

	for prop, value in config do
		local isLifecycle = string.find(prop, "on") ~= nil
		local isInitial = table.find(AVOID_LIFECYCLES, prop) ~= nil
		local isFn = typeof(value) == "function"

		if isLifecycle and not isInitial and isFn then
			Modding.addListener(config, prop)
		end
	end

	Reflect.attachMetadata(
		config,
		{ identifier = "@component", ["s:loadOrder"] = config.loadOrder or math.huge }
	)

	table.insert(Objects, config)

	return config :: any
end

--[=[
	Gets all components.

	@within ComponentUtil
	@return { ComponentConfig } -- All components.
]=]
function ComponentsUtil.getComponents(): typeof(Objects)
	return Objects
end

return ComponentsUtil
