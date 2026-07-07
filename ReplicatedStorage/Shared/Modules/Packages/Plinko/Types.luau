-- Plinko public types.

local Types = {}

export type Scope      = "owner" | "all"
export type Kind       = "player" | "global"
export type Middleware = (value: any, old: any) -> any

export type SaveConfig = {
	interval : number?,
	onLeave  : boolean?,
}

export type Config = {
	schema     : { [string]: any },
	key        : Kind?,
	replicate  : { [string]: Scope }?,
	middleware : { [string]: Middleware }?,
	standalone : boolean?,
	visibility : ("public" | "private")?,
	save       : SaveConfig?,
	onLoad     : ((id: any) -> any)?,
	onSave     : ((id: any, dirty: { [string]: any }) -> any)?,
}

export type Connection = { Disconnect: (Connection) -> () }

-- A handle bound to one record. Every method is field-first, on both contexts.
export type View = {
	get         : (self: View, field: string?) -> any,
	getAll      : (self: View) -> { [string]: any },
	exists      : (self: View) -> boolean,

	set         : (self: View, field: string, value: any) -> View,
	patch       : (self: View, delta: { [string]: any }) -> View,
	increment   : (self: View, field: string, amount: number?) -> View,
	toggle      : (self: View, field: string) -> View,
	reset       : (self: View, field: string) -> View,

	watch       : (self: View, field: string, fn: (new: any, old: any) -> ()) -> Connection?,
	onChange    : (self: View, fn: (field: string, new: any, old: any) -> ()) -> any,
	onFlush     : (self: View, fn: (dirty: { [string]: any }) -> ()) -> any,

	dirty       : (self: View) -> { [string]: any },
	isDirty     : (self: View, field: string) -> boolean,
	clearDirty  : (self: View) -> View,
	flush       : (self: View) -> any,

	snapshot    : (self: View, name: string) -> View,
	getSnapshot : (self: View, name: string) -> { [string]: any }?,
	diff        : (self: View, name: string) -> { [string]: { old: any, new: any } },
	restore     : (self: View, name: string) -> View,
	dropSnapshot: (self: View, name: string) -> View,

	hide        : (self: View) -> View,
	show        : (self: View) -> View,
	lock        : (self: View) -> View,
	unlock      : (self: View) -> View,
}

export type Cache = {
	onAdded    : any,
	onRemoving : any,
	onFlush    : any,
	onError    : any,

	view       : (self: Cache, id: any) -> View,
	global     : (self: Cache) -> View,
	mine       : (self: Cache) -> View,

	get        : (self: Cache, id: any, field: string?) -> any,
	set        : (self: Cache, id: any, field: string, value: any) -> (),
	patch      : (self: Cache, id: any, delta: { [string]: any }) -> (),
	increment  : (self: Cache, id: any, field: string, amount: number?) -> (),
	watch      : (self: Cache, id: any, field: string, fn: (new: any, old: any) -> ()) -> Connection?,

	create     : (self: Cache, id: any, seed: { [string]: any }?) -> View,
	exists     : (self: Cache, id: any) -> boolean,
	release    : (self: Cache, id: any) -> (),
	await      : (self: Cache, id: any?) -> any,

	ids        : (self: Cache) -> { any },
	each       : (self: Cache, fn: (id: any, data: { [string]: any }) -> ()) -> (),
	find       : (self: Cache, fn: (id: any, data: { [string]: any }) -> boolean) -> { [any]: { [string]: any } },
	some       : (self: Cache, fn: (id: any, data: { [string]: any }) -> boolean) -> boolean,
	count      : (self: Cache, fn: ((id: any, data: { [string]: any }) -> boolean)?) -> number,
	setAll     : (self: Cache, field: string, value: any) -> (),
	patchAll   : (self: Cache, delta: { [string]: any }) -> (),

	flush      : (self: Cache, id: any) -> any,
	flushAll   : (self: Cache) -> any,

	destroy    : (self: Cache) -> (),
}

return Types