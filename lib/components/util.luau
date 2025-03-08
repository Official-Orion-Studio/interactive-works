-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Modding = require(script.Parent.Parent.modding)
local Reflect = require(script.Parent.Parent.reflect)

-- Types
export type Component = {
	instance: Instance,

	onTick: ((self: Component, dt: number) -> nil)?,
	onPhysics: ((self: Component, dt: number) -> nil)?,
	onRender: ((self: Component, dt: number) -> nil)?,
}

export type ComponentConfig = {
	tag: string,
	loadOrder: number?,

	constructor: ((self: ComponentConfig) -> nil)?,
	onStart: ((self: Component) -> nil)?,
}

-- Constants
local Objects = {}

local IS_SERVER = RunService:IsServer()
local PREFIX = IS_SERVER and "Server" or "Client"

-- Module
local ComponentsUtil = {}

--[[
    Creates a Component.

    @param config - The component's config.
]]
function ComponentsUtil.createComponent(t: ComponentConfig): Component
	assert(typeof(t) == "table", `[{PREFIX}:component]: Can't create a component without a table.`)
	assert(
		typeof(t.tag) == "string",
		`[{PREFIX}:Component]: Can't create a component without a name.`
	)
	assert(#t.tag > 0, `[{PREFIX}:Component]: Can't create a component with an empty name.`)
	assert(not Objects[t.tag], `[{PREFIX}:Component]: Component with tag {t.tag} already exists.`)

	for prop, value in t do
		local isLifecycle = string.find(prop, "on") ~= nil
		local isInitial = prop == "onInit" or prop == "onStart"
		local isFn = typeof(value) == "function"

		if isLifecycle and not isInitial and isFn then
			Modding.addListener(t, prop)
		end
	end

	Reflect.attachMetadata(
		t,
		{ identifier = "@component", ["s:loadOrder"] = t.loadOrder or math.huge }
	)

	table.insert(Objects, t)

	return t :: any
end

--[[
    Gets all components.

    @returns All components.
]]
function ComponentsUtil.getComponents(): typeof(Objects)
	return Objects
end

return ComponentsUtil
