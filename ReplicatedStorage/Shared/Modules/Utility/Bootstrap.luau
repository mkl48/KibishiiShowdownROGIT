-- Kibishii Showdown
-- Shared/Modules/Utility/Bootstrap.luau
--
-- The one place boot happens. It locates Junky, reads everything from Utility.Config,
-- auto-injects the side's packages (so modules reach them via context:GetPackage),
-- and calls Junky.Configure. The ServerBootstrap / ClientBootstrap entry scripts do
-- nothing but hand it the folders to discover modules under.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = {}

-- Find the Junky package wherever it lives (recommended layout first, then fallbacks).
local function findJunky()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local modules = shared and shared:FindFirstChild("Modules")
	local packages = modules and modules:FindFirstChild("Packages")
	if packages and packages:FindFirstChild("Junky") then
		return require(packages.Junky)
	end
	local flat = ReplicatedStorage:FindFirstChild("Packages")
	if flat and flat:FindFirstChild("Junky") then
		return require(flat.Junky)
	end
	return require(ReplicatedStorage:WaitForChild("Junky"))
end

-- Inject the direct-child ModuleScripts of `container` into the `into` map, keyed by
-- name. Direct children only -- never descends into a package. Each require is isolated:
-- a module that errors on load (e.g. a UI lib missing a child) is skipped with a warning
-- instead of crashing the whole bootstrap. The running Bootstrap skips itself so folding
-- in the Utility folder can't trigger a recursive require of this module.
local function injectFrom(container, into)
	if not container then
		return
	end
	for _, module in container:GetChildren() do
		if module:IsA("ModuleScript") and module ~= script then
			local ok, result = pcall(require, module)
			if ok then
				into[module.Name] = result
			else
				warn(("[Bootstrap] '%s' failed to load -- skipped: %s"):format(module.Name, tostring(result)))
			end
		end
	end
end

-- Configure this side. `moduleRoots` = the folders Junky discovers modules under.
--
-- Injection is split into two namespaces so things aren't all crammed under packages:
--   Packages folders -> context:GetPackage(name)   (Plinko, Accede, Substance, ...)
--   Utility  folders -> context:GetUtility(name)   (Config, MemoryManifest, ...)
-- Controllers / Managers / Services are NOT injected -- Junky discovers those from
-- `moduleRoots` and they're reached via GetService or the Network/Junction.
function Bootstrap.Configure(moduleRoots: { Instance })
	local Junky = findJunky()
	local sharedModules = ReplicatedStorage:WaitForChild("Shared").Modules
	local Config = require(sharedModules.Utility.Config)

	local packages, utilities = {}, {}
	injectFrom(sharedModules:FindFirstChild("Packages"), packages)
	injectFrom(sharedModules:FindFirstChild("Utility"), utilities)

	if RunService:IsClient() then
		local clientModules = ReplicatedStorage:WaitForChild("Client").Modules
		injectFrom(clientModules:FindFirstChild("Packages"), packages)
		injectFrom(clientModules:FindFirstChild("Utility"), utilities)
	else
		local serverModules = game:GetService("ServerStorage"):WaitForChild("Modules")
		injectFrom(serverModules:FindFirstChild("Packages"), packages)
		injectFrom(serverModules:FindFirstChild("Utility"), utilities)
	end

	local app = Junky.Configure({
		Junction = Config.Junction,
		Manifest = Config.Manifest,
		ClassPriority = Config.ClassPriority,
		StandalonePriority = Config.StandalonePriority,
		Inject = packages,
		Utilities = utilities,
		Modules = moduleRoots,
	})

	print(("[Kibishii] booted (%s)"):format(if RunService:IsServer() then "Server" else "Client"))
	return app
end

return Bootstrap