local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = {}

-- Find the Junky package wherever it lives.
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

-- Inject every top-level package under a folder by its own name.
local function injectPackages(container, into)
	if not container then return end
	for _, module in container:GetChildren() do
		if module:IsA("ModuleScript") then
			into[module.Name] = require(module)
		end
	end
end

-- Auto-scans module roots, requires them safely, and builds priority maps
-- in the format Junky's Priority.Order expects:
--   ClassPriority:      { [tier: number]: { string } }  for Controllers/Managers
--   StandalonePriority: { [name: string]: number }        for Services
local function buildPriorities(moduleRoots)
	local classMap = {}
	local standaloneMap = {}

	for _, root in ipairs(moduleRoots) do
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("ModuleScript") then
				-- Safely require to check for a Priority key
				local success, result = pcall(require, desc)
				if success and type(result) == "table" then
					-- Wrap in pcall: some modules (e.g. Signal) have strict
					-- metatables that error on unknown key access.
					local ps, priority = pcall(function() return result.Priority end)
					if ps and priority then
						if desc.Name:match("Controller$") or desc.Name:match("Manager$") then
							-- Tiered: group module names by their priority tier
							if not classMap[priority] then
								classMap[priority] = {}
							end
							table.insert(classMap[priority], desc.Name)
						elseif desc.Name:match("Service$") then
							-- Flat: map module name directly to its priority value
							standaloneMap[desc.Name] = priority
						end
					end
				end
			end
		end
	end

	return classMap, standaloneMap
end

-- Configure this side.
function Bootstrap.Configure(moduleRoots: { Instance })
	local Junky = findJunky()
	local sharedModules = ReplicatedStorage:WaitForChild("Shared").Modules
	local Config = require(sharedModules.Utility.Config)

	local inject = {}
	injectPackages(sharedModules:FindFirstChild("Packages"), inject)

	if RunService:IsClient() then
		local clientModules = ReplicatedStorage:WaitForChild("Client").Modules
		injectPackages(clientModules:FindFirstChild("Packages"), inject)
	else
		local serverModules = game:GetService("ServerStorage"):WaitForChild("Modules")
		injectPackages(serverModules:FindFirstChild("Packages"), inject)
	end

	-- Dynamically generate our boot order
	local scannedClassPriority, scannedStandalonePriority = buildPriorities(moduleRoots)

	local app = Junky.Configure({
		Junction = Config.Junction,
		Manifest = Config.Manifests,
		ClassPriority = scannedClassPriority,
		StandalonePriority = scannedStandalonePriority,
		Inject = inject,
		Modules = moduleRoots,
	})

	--print(("[Jinki Ketsu] booted (%s)"):format(if RunService:IsServer() then "Server" else "Client"))
	return app
end

return Bootstrap