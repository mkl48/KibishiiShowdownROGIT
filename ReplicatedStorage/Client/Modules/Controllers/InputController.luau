local InputController = {}
InputController.Priority = 0

function InputController:Start(c)
	local Context = c._runtime
	local Packages = Context.Packages
	local Utilities = Context.Utilities

	local Switch = Packages.Switch
	local Signal = Packages.Signal

	local Config = Utilities.Config
	local Settings = Config.Settings
	local InputConfig = Config.Manifests.Interface.Input

	local Functions = Config.Functions
	local Controls = Settings.GetNamespace("Controls")
	local Input = c:Local("Input")
	
	local Enums = Switch.Enums
	local Bindings = {}   -- indexed by BOTH enum name ("F") and control name ("Block")

	if not Controls then
		warn("[InputController] Controls namespace not found in Settings")
		return
	end

	for k, v in Controls do
		local Kenum = Functions.ToInputEnum(v.Value)
		if not Kenum then continue end

		local Binding = Switch.Define(k, {
			Bindings = { Kenum },
			Contexts = { InputConfig.Context },
			Driver   = Enums.Driver.UIS,
		})

		local entry = {
			Binding = Binding,
			Keybind = {
				Name = k,
				Enum = Kenum,
			},
		}

		Bindings[Kenum.Name] = entry   -- lookup by Key     -> "F"
		Bindings[k]          = entry   -- lookup by Control -> "Block"

		Binding:Next(Enums.State.Pressed):Then(function()
			Input:Post("Pressed", { Key = Kenum.Name })
		end)

		Binding:Next(Enums.State.Released):Then(function()
			Input:Post("Released", { Key = Kenum.Name })
		end)

		Binding:HoldFor(InputConfig.HoldDuration):Then(function()
			Input:Post("Held", {
				Key = Kenum.Name,
				Released = Binding:Next(Enums.State.Released),
			})
		end)
	end

	Input:Respond("IsHoldingKey", function(payload)
		local id = payload.Key or payload.Control     -- accept either
		if not id then return false end
		local entry = Bindings[id]
		if not entry then return false end
		return entry.Binding:IsHeld()
	end)

	-- IsHolding: lightweight query — takes a key/control name directly
	Input:Respond("IsHolding", function(id)
		if not id then return false end
		local entry = Bindings[id]
		if not entry then return false end
		return entry.Binding:IsHeld()
	end)

	Switch.PushContext(InputConfig.Context)

	-- Cleanup: pop the input context on teardown
	c:OnCleanup(function()
		Switch.PopContext(InputConfig.Context)
	end)
end

return InputController