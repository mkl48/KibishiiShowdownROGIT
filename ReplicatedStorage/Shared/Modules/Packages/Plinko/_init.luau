-- Plinko
-- A cache / global-table library with optional cross-context syncing.
--
-- A Plinko cache is a schema'd key -> value store. It comes in two shapes, chosen once
-- at define time -- NOT reinterpreted per context, so a call means the same thing on the
-- server and the client:
--
--   * global  -- one shared record ("the global table").          cache:global()
--   * player  -- one record per Player, auto-managed on join.       cache:view(player)
--
-- You never juggle argument positions. Grab a View (a handle bound to one record) and
-- every method on it is field-first everywhere:
--
--   local settings = Plinko.define("Settings", { key = "global", schema = {...} })
--   settings:global():set("Volume", 80)
--   settings:global():watch("Volume", applyVolume)
--
--   local stats = Plinko.define("Stats", { schema = {...}, replicate = { Kills = "all" } })
--   stats:view(player):increment("Kills")        -- server
--   stats:mine():get("Kills")                     -- client, this player's mirror
--
-- Syncing is optional and server-authoritative. Declare `replicate = { field = scope }`
-- and the server pushes those fields to clients ("owner" = only that player, "all" =
-- everyone). Clients mirror read-only; route write *requests* through your own network
-- layer (Plinko caches state, it is not a networking framework). A `standalone` cache has
-- no remote and can be written from either side -- a plain local table with schema,
-- dirty-tracking, watches and snapshots.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")

local Signal = require(script.GoodSignal)
local Accede = require(script.Parent.Accede)

local IS_SERVER = RunService:IsServer()

-- The single record id used by "global" caches. A stable, unique table so it can never
-- collide with a Player key; a string marker stands in for it over the remote.
local GLOBAL        = newproxy(false)
local GLOBAL_MARKER = "\0Plinko.GLOBAL"

type Scope     = "owner" | "all"
type Kind      = "player" | "global"
type Middleware = (value: any, old: any) -> any

type SaveConfig = {
	interval : number?,
	onLeave  : boolean?,
}

export type Config = {
	schema     : { [string]: any },
	key        : Kind?,                          -- "player" (default) or "global"
	replicate  : { [string]: Scope }?,
	middleware : { [string]: Middleware }?,
	standalone : boolean?,                       -- no remote; writable from either side
	visibility : ("public" | "private")?,        -- private records start hidden from "all"
	save       : SaveConfig?,
	onLoad     : ((id: any) -> any)?,            -- returns a table merged over the schema
	onSave     : ((id: any, dirty: { [string]: any }) -> any)?,
}

type Record = {
	data      : { [string]: any },
	defaults  : { [string]: any },
	dirty     : { [string]: any },
	locked    : boolean,
	hidden    : boolean,
	snapshots : { [string]: { [string]: any } },
	changed   : any,   -- Signal(field, new, old)
	flushed   : any,   -- Signal(dirty)
	watches   : { [string]: { Middleware } },
}

local function deepCopy(t: any): any
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do
		out[k] = type(v) == "table" and deepCopy(v) or v
	end
	return out
end

--============================================================================--
-- View: a handle to a single record. Field-first, identical on both contexts.
--============================================================================--

local View = {}
View.__index = View

local function newView(cache, id): any
	return setmetatable({ _cache = cache, _id = id }, View)
end

function View:_record(): Record?
	return self._cache._records[self._id]
end

-- Read one field, or the whole record table (a copy) when no field is given.
function View:get(field: string?): any
	local rec = self:_record()
	if not rec then return nil end
	if field == nil then return deepCopy(rec.data) end
	return rec.data[field]
end

function View:getAll(): { [string]: any }
	local rec = self:_record()
	return rec and deepCopy(rec.data) or {}
end

function View:exists(): boolean
	return self:_record() ~= nil
end

function View:set(field: string, value: any): any
	self._cache:_write(self._id, field, value, false)
	return self
end

function View:patch(delta: { [string]: any }): any
	for field, value in pairs(delta) do
		self._cache:_write(self._id, field, value, false)
	end
	return self
end

function View:increment(field: string, amount: number?): any
	local rec = self:_record()
	if not rec then return self end
	local current = rec.data[field]
	if type(current) ~= "number" then
		warn(`[Plinko] "{self._cache._name}": cannot increment non-number field "{field}"`)
		return self
	end
	self._cache:_write(self._id, field, current + (amount or 1), false)
	return self
end

function View:toggle(field: string): any
	local rec = self:_record()
	if rec then self._cache:_write(self._id, field, not rec.data[field], false) end
	return self
end

function View:reset(field: string): any
	local rec = self:_record()
	if rec then self._cache:_write(self._id, field, rec.defaults[field], false) end
	return self
end

-- Watch one field. Returns a connection with :Disconnect().
function View:watch(field: string, fn: (new: any, old: any) -> ()): any
	local rec = self:_record()
	if not rec then return nil end
	local list = rec.watches[field]
	if not list then list = {}; rec.watches[field] = list end
	table.insert(list, fn)
	return {
		Disconnect = function()
			local idx = table.find(list, fn)
			if idx then table.remove(list, idx) end
		end,
	}
end

-- React to any field on this record changing.
function View:onChange(fn: (field: string, new: any, old: any) -> ()): any
	local rec = self:_record()
	return rec and rec.changed:Connect(fn) or nil
end

function View:onFlush(fn: (dirty: { [string]: any }) -> ()): any
	local rec = self:_record()
	return rec and rec.flushed:Connect(fn) or nil
end

-- Dirty tracking (fields written since the last flush).
function View:dirty(): { [string]: any }
	local rec = self:_record()
	return rec and deepCopy(rec.dirty) or {}
end

function View:isDirty(field: string): boolean
	local rec = self:_record()
	return rec ~= nil and rec.dirty[field] ~= nil
end

function View:clearDirty(): any
	local rec = self:_record()
	if rec then rec.dirty = {} end
	return self
end

function View:flush(): any
	return self._cache:_flush(self._id)
end

-- Named snapshots for diffing / rollback.
function View:snapshot(name: string): any
	local rec = self:_record()
	if rec then rec.snapshots[name] = deepCopy(rec.data) end
	return self
end

function View:getSnapshot(name: string): { [string]: any }?
	local rec = self:_record()
	return rec and rec.snapshots[name] or nil
end

function View:diff(name: string): { [string]: { old: any, new: any } }
	local rec = self:_record()
	if not rec then return {} end
	local snap = rec.snapshots[name]
	if not snap then return {} end
	local out = {}
	for field, current in pairs(rec.data) do
		if snap[field] ~= current then
			out[field] = { old = snap[field], new = current }
		end
	end
	return out
end

-- Roll the record back to a snapshot (fields still fire watches / replicate).
function View:restore(name: string): any
	local rec = self:_record()
	if not rec then return self end
	local snap = rec.snapshots[name]
	if not snap then
		warn(`[Plinko] "{self._cache._name}": no snapshot "{name}"`)
		return self
	end
	self:patch(snap)
	return self
end

function View:dropSnapshot(name: string): any
	local rec = self:_record()
	if rec then rec.snapshots[name] = nil end
	return self
end

-- Visibility gates whether this record's "all"-scoped fields reach other clients.
function View:hide(): any
	local rec = self:_record()
	if rec then rec.hidden = true end
	return self
end

function View:show(): any
	local rec = self:_record()
	if rec then rec.hidden = false end
	return self
end

function View:lock(): any
	local rec = self:_record()
	if rec then rec.locked = true end
	return self
end

function View:unlock(): any
	local rec = self:_record()
	if rec then rec.locked = false end
	return self
end

--============================================================================--
-- Cache
--============================================================================--

local Cache = {}
Cache.__index = Cache

function Cache:_create(id: any, seed: { [string]: any }?): Record
	local data = deepCopy(self._config.schema)
	if seed then
		for k, v in pairs(seed) do data[k] = v end
	end
	local rec: Record = {
		data      = data,
		defaults  = deepCopy(self._config.schema),
		dirty     = {},
		locked    = false,
		hidden    = self._config.visibility == "private",
		snapshots = {},
		changed   = Signal.new(),
		flushed   = Signal.new(),
		watches   = {},
	}
	self._records[id] = rec
	return rec
end

function Cache:_write(id: any, field: string, value: any, fromRemote: boolean)
	local rec = self._records[id]
	if not rec then
		warn(`[Plinko] "{self._name}": no record for {self:_label(id)}`)
		return
	end

	-- Clients cannot author a synced cache; the server owns it. Applying a value that
	-- arrived over the remote (fromRemote) is how the mirror updates -- that is allowed.
	if not fromRemote and not IS_SERVER and not self._standalone then
		warn(`[Plinko] "{self._name}" is server-authoritative; route writes through your network layer`)
		return
	end

	if rec.locked and not fromRemote then
		warn(`[Plinko] "{self._name}" is locked for {self:_label(id)}`)
		return
	end

	local default = self._config.schema[field]
	if default ~= nil and value ~= nil and type(value) ~= type(default) then
		warn(`[Plinko] "{self._name}": type mismatch on "{field}" -- expected {type(default)}, got {type(value)}`)
	end

	local old = rec.data[field]

	-- Middleware transforms authored writes (clamp / sanitize), never mirror writes.
	if not fromRemote then
		local mw = self._config.middleware
		local fn = mw and mw[field]
		if fn then value = fn(value, old) end
	end

	if old == value then return end

	rec.data[field]  = value
	if not fromRemote then rec.dirty[field] = value end

	rec.changed:Fire(field, value, old)
	local list = rec.watches[field]
	if list then
		for _, fn in ipairs(list) do
			task.spawn(fn, value, old)
		end
	end

	if IS_SERVER and self._remote and not fromRemote then
		local scope = self._config.replicate and self._config.replicate[field]
		if scope then self:_push(id, field, value, scope) end
	end
end

function Cache:_label(id: any): string
	if id == GLOBAL then return "<global>" end
	return tostring(id)
end

--============================================================================--
-- Replication (server -> client)
--============================================================================--

function Cache:_wireId(id: any): any
	return id == GLOBAL and GLOBAL_MARKER or id
end

function Cache:_push(id: any, field: string, value: any, scope: Scope)
	if not self._remote then return end
	local wireId = self:_wireId(id)

	if scope == "owner" and typeof(id) == "Instance" and id:IsA("Player") then
		self._remote:FireClient(id, field, value)
	elseif scope == "all" then
		local rec = self._records[id]
		if rec and rec.hidden then return end
		self._remote:FireAllClients(field, value, wireId)
	end
end

-- Send a joining player everything they are allowed to see.
function Cache:_bootstrap(player: Player)
	if not self._remote then return end
	local replicate = self._config.replicate
	if not replicate then return end

	for id, rec in pairs(self._records) do
		for field, scope in pairs(replicate) do
			if scope == "owner" then
				if id == player then
					self._remote:FireClient(player, field, rec.data[field])
				end
			elseif scope == "all" and not rec.hidden then
				self._remote:FireClient(player, field, rec.data[field], self:_wireId(id))
			end
		end
	end
end

-- Client side: fold an incoming value into the local mirror.
function Cache:_receive(field: string, value: any, wireId: any?)
	local id = wireId == nil and Players.LocalPlayer
		or wireId == GLOBAL_MARKER and GLOBAL
		or wireId
	if not self._records[id] then
		self:_create(id)
	end
	self:_write(id, field, value, true)
end

--============================================================================--
-- Views / accessors
--============================================================================--

-- The handle for one record. Creating a fresh view is cheap.
function Cache:view(id: any): any
	return newView(self, id)
end

-- The single record of a "global" cache.
function Cache:global(): any
	assert(self._kind == "global", `[Plinko] "{self._name}" is not a global cache`)
	return newView(self, GLOBAL)
end

-- The local player's record (client) -- the common case for "owner" data.
function Cache:mine(): any
	assert(not IS_SERVER, `[Plinko] :mine() is client-only`)
	return newView(self, Players.LocalPlayer)
end

-- Flat convenience wrappers. Always id-first, both contexts -- no shifting.
function Cache:get(id: any, field: string?): any
	return newView(self, id):get(field)
end
function Cache:set(id: any, field: string, value: any): ()
	newView(self, id):set(field, value)
end
function Cache:patch(id: any, delta: { [string]: any }): ()
	newView(self, id):patch(delta)
end
function Cache:increment(id: any, field: string, amount: number?): ()
	newView(self, id):increment(field, amount)
end
function Cache:watch(id: any, field: string, fn: (new: any, old: any) -> ()): any
	return newView(self, id):watch(field, fn)
end

--============================================================================--
-- Record lifecycle + collection ops
--============================================================================--

function Cache:create(id: any, seed: { [string]: any }?): any
	if not self._records[id] then
		self:_create(id, seed)
		self.onAdded:Fire(id, self._records[id].data)
		if IS_SERVER then self:_bootstrapAll(id) end
	end
	return newView(self, id)
end

-- Push a newly created record's replicated fields to the players who may see it.
function Cache:_bootstrapAll(id: any)
	if not self._remote then return end
	local replicate = self._config.replicate
	if not replicate then return end
	local rec = self._records[id]
	if not rec then return end
	for field, scope in pairs(replicate) do
		self:_push(id, field, rec.data[field], scope)
	end
end

function Cache:exists(id: any): boolean
	return self._records[id] ~= nil
end

function Cache:release(id: any)
	local rec = self._records[id]
	if not rec then return end
	self.onRemoving:Fire(id, rec.data)
	rec.changed:DisconnectAll()
	rec.flushed:DisconnectAll()
	self._records[id] = nil
end

function Cache:ids(): { any }
	local out = {}
	for id in pairs(self._records) do table.insert(out, id) end
	return out
end

function Cache:each(fn: (id: any, data: { [string]: any }) -> ())
	for id, rec in pairs(self._records) do fn(id, rec.data) end
end

function Cache:find(fn: (id: any, data: { [string]: any }) -> boolean): { [any]: { [string]: any } }
	local out = {}
	for id, rec in pairs(self._records) do
		if fn(id, rec.data) then out[id] = rec.data end
	end
	return out
end

function Cache:some(fn: (id: any, data: { [string]: any }) -> boolean): boolean
	for id, rec in pairs(self._records) do
		if fn(id, rec.data) then return true end
	end
	return false
end

function Cache:count(fn: ((id: any, data: { [string]: any }) -> boolean)?): number
	local n = 0
	for id, rec in pairs(self._records) do
		if not fn or fn(id, rec.data) then n += 1 end
	end
	return n
end

function Cache:setAll(field: string, value: any)
	for id in pairs(self._records) do self:_write(id, field, value, false) end
end

function Cache:patchAll(delta: { [string]: any })
	for id in pairs(self._records) do newView(self, id):patch(delta) end
end

--============================================================================--
-- Persistence (dirty -> onSave), powered by Accede
--============================================================================--

function Cache:_flush(id: any): any
	local rec = self._records[id]
	if not rec then return Accede.resolve() end

	local dirty = rec.dirty
	if next(dirty) == nil then return Accede.resolve() end
	rec.dirty = {}

	rec.flushed:Fire(dirty)
	self.onFlush:Fire(id, dirty)

	local onSave = self._config.onSave
	if onSave and IS_SERVER then
		return Accede.wrap(onSave)(id, dirty):toss(function(err)
			self.onError:Fire(id, err)
		end)
	end
	return Accede.resolve()
end

function Cache:flush(id: any): any
	return self:_flush(id)
end

function Cache:flushAll(): any
	local list = {}
	for id in pairs(self._records) do
		table.insert(list, self:_flush(id))
	end
	return Accede.all(list)
end

function Cache:await(id: any?): any
	local key = id
	if key == nil then
		key = self._kind == "global" and GLOBAL
			or (not IS_SERVER and Players.LocalPlayer)
			or nil
	end
	if key == nil then return Accede.reject("[Plinko] await: no id") end

	if self._records[key] then
		return Accede.resolve(newView(self, key))
	end
	return Accede.new(function(resolve)
		local conn
		conn = self.onAdded:Connect(function(added)
			if added == key then
				conn:Disconnect()
				resolve(newView(self, key))
			end
		end)
	end)
end

--============================================================================--
-- Auto player management (server, kind == "player", not standalone)
--============================================================================--

function Cache:_load(id: any)
	local onLoad = self._config.onLoad
	Accede.wrap(function()
		return onLoad and onLoad(id) or nil
	end)():next(function(seed)
		if self._records[id] then return end
		self:_create(id, seed)
		self.onAdded:Fire(id, self._records[id].data)
		if typeof(id) == "Instance" and id:IsA("Player") then
			self:_bootstrap(id)   -- give the joiner their existing world
		end
		self:_bootstrapAll(id)    -- and tell everyone about the new record
	end):toss(function(err)
		self.onError:Fire(id, err)
	end)
end

function Cache:_hookPlayers()
	self._conns = {
		Players.PlayerAdded:Connect(function(p) self:_load(p) end),
		Players.PlayerRemoving:Connect(function(p) self:_unload(p) end),
	}
	for _, p in ipairs(Players:GetPlayers()) do
		self:_load(p)
	end
end

function Cache:_unload(player: Player)
	local rec = self._records[player]
	if not rec then return end

	local keep = self._config.save
	local saveOnLeave = not (keep and keep.onLeave == false)
	if saveOnLeave then
		rec.locked = true
		self:_flush(player):conclude(function()
			self:release(player)
		end)
	else
		self:release(player)
	end
end

function Cache:_startTimer()
	local interval = self._config.save and self._config.save.interval
	if not interval or interval <= 0 then return end
	task.spawn(function()
		while self._records do
			task.wait(interval)
			if not self._records then break end
			self:flushAll():toss(function(err)
				self.onError:Fire(nil, err)
			end)
		end
	end)
end

function Cache:destroy()
	self:flushAll():conclude(function()
		for _, conn in ipairs(self._conns or {}) do conn:Disconnect() end
		for id in pairs(self._records) do self:release(id) end
		self._records = nil :: any
		self.onAdded:DisconnectAll()
		self.onRemoving:DisconnectAll()
		self.onFlush:DisconnectAll()
		self.onError:DisconnectAll()
		if self._remote and IS_SERVER then
			self._remote:Destroy()
		end
	end)
end

--============================================================================--
-- Plinko entry point
--============================================================================--

local Plinko = { GLOBAL = GLOBAL }

local function remoteFolder(): Folder
	local folder = RepStorage:FindFirstChild("PlinkoRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PlinkoRemotes"
		folder.Parent = RepStorage
	end
	return folder :: Folder
end

function Plinko.define(name: string, config: Config): any
	assert(type(name) == "string" and #name > 0, "[Plinko] name must be a non-empty string")
	assert(type(config) == "table",               "[Plinko] config must be a table")
	assert(type(config.schema) == "table",         "[Plinko] config.schema must be a table")

	local kind: Kind = config.key or "player"
	assert(kind == "player" or kind == "global", `[Plinko] config.key must be "player" or "global"`)

	local self = setmetatable({}, Cache)
	self._name       = name
	self._config     = config
	self._kind       = kind
	self._records    = {}
	self._standalone = config.standalone == true
	self._remote     = nil
	self._conns      = nil

	self.onAdded    = Signal.new()   -- (id, data)
	self.onRemoving = Signal.new()   -- (id, data)
	self.onFlush    = Signal.new()   -- (id, dirty)
	self.onError    = Signal.new()   -- (id, err)

	-- Wire the sync remote (only when fields replicate and it is not a local-only cache).
	if config.replicate and not self._standalone then
		local remoteName = "Plinko_" .. name
		if IS_SERVER then
			local remote = Instance.new("RemoteEvent")
			remote.Name   = remoteName
			remote.Parent = remoteFolder()
			self._remote  = remote
		else
			-- Seed the local mirror with schema defaults so :mine()/:global() resolve
			-- (and early watches attach) before the first replicated value lands.
			self:_create(kind == "global" and GLOBAL or Players.LocalPlayer)

			local remote = remoteFolder():WaitForChild(remoteName, 10)
			if remote then
				self._remote = remote
				remote.OnClientEvent:Connect(function(field, value, wireId)
					self:_receive(field, value, wireId)
				end)
			else
				warn(`[Plinko] remote "{remoteName}" not found -- syncing disabled for "{name}"`)
			end
		end
	end

	-- A global cache has exactly one record; create it up front on the server.
	if kind == "global" then
		if IS_SERVER then self:_load(GLOBAL) end
	elseif IS_SERVER and not self._standalone then
		self:_hookPlayers()
		self:_startTimer()
	end

	return self
end

return Plinko