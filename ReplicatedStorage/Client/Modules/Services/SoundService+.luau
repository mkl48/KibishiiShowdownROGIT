--!strict
--[[
    SoundServicePlus — standalone local sound utility.

    Public API:
      :playSound(soundOrId)              -- play a 2D/local sound
      :playSoundAt(location, soundOrId)  -- play a positional 3D sound at a world point

    `soundOrId` may be a Sound instance (cloned before playing), an asset id
    number, or an "rbxassetid://..." string.
]]

local SoundService = game:GetService("SoundService")

local SoundServicePlus = {}

-- Helpers -------------------------------------------------------------------
local function removeUrl(newString: string): string
	local pattern = "rbxassetid://"
	local url = string.match(newString, pattern)

	if url then
		return newString:gsub(url, "")
	end

	return newString
end

local function handleSoundOrId(soundOrId: Sound | number | string): Sound
	if typeof(soundOrId) == "number" or typeof(soundOrId) == "string" then
		local newSoundInstance = Instance.new("Sound")
		newSoundInstance.SoundId = "rbxassetid://" .. removeUrl(tostring(soundOrId))
		return newSoundInstance
	end

	assert(typeof(soundOrId) == "Instance", `Err: soundOrId is not valid: [{soundOrId}]`)

	return (soundOrId :: Sound):Clone()
end

local function newSoundHost(location: Vector3): Part
	local host = Instance.new("Part")
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Position = location
	host.Parent = workspace
	return host
end

-- Public API ----------------------------------------------------------------
function SoundServicePlus:playSoundAt(location: Vector3, soundOrId: Sound | number)
	assert(typeof(location) == "Vector3", "Err: location is not Valid")

	local Sound = handleSoundOrId(soundOrId)
	local SoundHost = newSoundHost(location)
	Sound.Parent = SoundHost
	Sound:Play()
end

function SoundServicePlus:playSound(soundOrId: Sound | number | string, volume: number?)
	local Sound = handleSoundOrId(soundOrId)
	if volume then
		Sound.Volume = volume
	end
	SoundService:PlayLocalSound(Sound)
end

return SoundServicePlus