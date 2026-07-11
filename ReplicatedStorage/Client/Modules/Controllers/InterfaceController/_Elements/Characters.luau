local TweenService = game:GetService("TweenService")

local Characters = {}

function Characters:Start(Context)
	local Classes  = Context.Classes
	local Services = Context.Services
	local Config   = Context.Config

	local DefaultTheme = Config.Manifests.Game.DefaultTheme
	local CharConfig   = Config.Manifests.Interface.Characters

	local CharacterService = Services.CharacterService
	local Stylized = Classes.Stylized
	local Text     = Classes.Text

	local CharactersIcon = Stylized:newList()
	CharactersIcon:setLabel("Characters")
	CharactersIcon:setDropdown()
	Stylized:bindIconToSounds(CharactersIcon)

	local function setupCharacter(Char)
		local CharIcon = Stylized:newListChild(CharactersIcon)
		CharIcon:setLabel(Char.Name)
		CharIcon:setDropdown()
		CharIcon:oneClick(true)

		local Theme = (Char.Config and Char.Config.Theme) or DefaultTheme

		Stylized:setChildGleam(CharIcon, CharactersIcon, Theme.Gleam)
		Stylized:bindIconToSounds(CharIcon)
		
		local CurrentCharacter = CharacterService.GetCurrent()
		
		local Outline = Stylized:setChildOutline(CharIcon, CharactersIcon, Theme.Secondary)
		if CurrentCharacter ~= Char.Name then
			Stylized:killChildOutline(CharIcon, CharactersIcon)
		end

		CharIcon:bindEvent("viewingStarted", function()
			if not Outline.Parent then return end
			TweenService:Create(Outline, TweenInfo.new(
				CharConfig.ViewTweenDuration,
				CharConfig.ViewEasingStyle,
				CharConfig.ViewEasingDirection
			), {
				Color = Theme.Highlight,
				Thickness = CharConfig.ViewOutlineThickness,
			}):Play()
		end)

		CharIcon:bindEvent("viewingEnded", function()
			if not Outline.Parent then return end
			TweenService:Create(Outline, TweenInfo.new(
				CharConfig.ViewTweenDuration,
				CharConfig.ViewEasingStyle,
				CharConfig.ViewEasingDirection
			), {
				Color = Theme.Secondary,
				Thickness = CharConfig.RestOutlineThickness,
			}):Play()
		end)

		CharIcon:bindEvent("deselected", function()
			CharacterService.SetMoveset(Char.Name)
		end)

		return {
			Icon = CharIcon,
			Obj = Char,
			Outline = Outline,
		}
	end

	local _Loaded = {}

	for _, Char in CharacterService.GetMovesets() do
		_Loaded[Char.Name] = setupCharacter(Char)
	end

	CharactersIcon:bindEvent("selected", function()
		for _, Char in _Loaded do
			local CharIcon = Char.Icon
			local CharObj = Char.Obj
			local Outline = Char.Outline
			local Theme = (CharObj.Config and CharObj.Config.Theme) or DefaultTheme

			local CurrentCharacter = CharacterService.GetCurrent()
			if CurrentCharacter ~= CharObj.Name then continue end
			warn("Valid: Making Changes")
			if Outline:FindFirstChildOfClass("UIGradient") then
				continue
			end

			local Gradient = Instance.new("UIGradient")
			Gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Theme.Gradient[1]),
				ColorSequenceKeypoint.new(1, Theme.Gradient[2]),
			})
			Gradient.Parent = Outline

			task.spawn(function()
				while Gradient.Parent do
					Gradient.Rotation += CharConfig.GradientRotationSpeed
					task.wait()
				end
			end)
		end
	end)

	return CharactersIcon
end

return Characters