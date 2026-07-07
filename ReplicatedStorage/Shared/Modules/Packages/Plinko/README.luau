--[[
	# Plinko

	A cache / global-table library with **optional cross-context syncing**.

	A Plinko cache is a schema'd `key → value` store. It comes in two shapes, chosen **once**
	at define time and never reinterpreted per context — a call means the same thing on the
	server and the client:

	| shape | records | grab it with |
	| --- | --- | --- |
	| `global` | one shared record ("the global table") | `cache:global()` |
	| `player` (default) | one record per `Player`, auto-managed on join/leave | `cache:view(player)` / `cache:mine()` |

	You never juggle argument positions. You grab a **View** — a handle bound to one record —
	and every method on it is **field-first, everywhere**.

	## Why the revamp

	The old Plinko reinterpreted its arguments based on `RunService:IsServer()`:
	`cache:get(a, b)` meant one thing on the server and something else on the client, and
	`watch` shifted its parameters too. It also bundled a 36 KB `Promise` and an entire unused
	`Schema/` library. This version:

	- makes the API **context-symmetric** via Views — no `IS_SERVER` arg-shifting;
	- promotes the **global table** to a first-class shape (`key = "global"`);
	- keeps sync **optional** and server-authoritative;
	- builds on the ecosystem's **Accede** (like Moody / Mixit / Network) instead of a
	  bundled promise, and drops the dead `Schema/`.

	## Define

	```lua
	local Plinko = require(Packages.Plinko)

	local cache = Plinko.define(name, {
	    schema     = { Kills = 0, Volume = 50 },      -- field -> default (required)
	    key        = "player",                        -- "player" (default) | "global"
	    replicate  = { Kills = "all", Volume = "owner" }, -- optional sync, per field
	    middleware = { Volume = function(v) return math.clamp(v, 0, 100) end },
	    standalone = false,                           -- true = local-only, writable either side
	    visibility = "public",                        -- "private" records start hidden from "all"
	    save       = { interval = 60, onLeave = true },
	    onLoad     = function(id) return loadFromStore(id) end, -- merged over schema
	    onSave     = function(id, dirty) writeToStore(id, dirty) end, -- -> Accede
	})
	```

	## Views

	```lua
	-- global cache
	local round = Plinko.define("Round", { key = "global", schema = { Phase = "lobby", Timer = 0 } })
	round:global():set("Phase", "fight"):increment("Timer", 5)
	round:global():watch("Phase", function(new, old) print(old, "->", new) end)

	-- per-player cache
	local stats = Plinko.define("Stats", { schema = { Kills = 0 }, replicate = { Kills = "all" } })
	stats:view(player):increment("Kills")   -- server writes
	stats:mine():get("Kills")               -- client reads its own mirror
	```

	Every View method (`get`, `getAll`, `set`, `patch`, `increment`, `toggle`, `reset`,
	`watch`, `onChange`, `onFlush`, `dirty`, `isDirty`, `clearDirty`, `flush`, `snapshot`,
	`diff`, `restore`, `dropSnapshot`, `hide`/`show`, `lock`/`unlock`) is field-first and
	identical on both contexts. Setters chain.

	Flat cache-level sugar exists too — always **id-first**, both contexts:
	`cache:get(id, field)`, `cache:set(id, field, value)`, `cache:patch(id, delta)`,
	`cache:increment(id, field, n)`, `cache:watch(id, field, fn)`.

	## Syncing

	Declare `replicate = { field = scope }`:

	- `"owner"` — only the player whose record it is receives the field (per-player caches).
	- `"all"` — every client receives it.

	The **server is authoritative**: it pushes replicated fields down one RemoteEvent
	(`ReplicatedStorage/PlinkoRemotes/Plinko_<name>`), and clients mirror them **read-only**.
	Joining players are bootstrapped with everything they may see. Route write *requests*
	(client → server) through your own network layer — Plinko caches state, it is not a
	networking framework. A `standalone` cache has no remote and is writable from either side.

	## Collections & persistence

	`cache:ids()`, `:each(fn)`, `:find(fn)`, `:some(fn)`, `:count(fn?)`, `:setAll(field, v)`,
	`:patchAll(delta)`. Dirty fields flush through `onSave`: `cache:flush(id)` /
	`cache:flushAll()` return Accede thenables, and `save.interval` / `save.onLeave` automate
	it for per-player caches.

	Signals: `cache.onAdded(id, data)`, `.onRemoving(id, data)`, `.onFlush(id, dirty)`,
	`.onError(id, err)`.
]]