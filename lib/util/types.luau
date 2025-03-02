export type Singleton = {
    name: string,
    loadOrder: number?,

    constructor: ((self: Singleton) -> nil)?,
    onTick: ((self: Singleton, dt: number) -> nil)?,
    onPhysics: ((self: Singleton, dt: number) -> nil)?,
    onRender: ((self: Singleton, dt: number) -> nil)?,
    onInit: ((self: Singleton) -> nil)?,
    onStart: ((self: Singleton) -> nil)?,
}

export type SingletonConfig = {
	name: string,
	loadOrder: number?,
}

return {}