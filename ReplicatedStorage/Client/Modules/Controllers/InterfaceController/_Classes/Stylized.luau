--!strict


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Modules.Utility.Config)
local StylizedConfig = Config.Manifests.Interface.Stylized

local Icon = require(ReplicatedStorage.Client.Modules.Packages.Icon)

local SoundServicePlus = require(ReplicatedStorage.Client.Modules.Services["SoundService+"])

local ClientAssets = ReplicatedStorage:WaitForChild("Client").Assets
local SoundAssets = ClientAssets.Sounds.SoundEffects.Interface.Interaction

-- Resolve glow template from the moved asset directory
local GlowTemplate = ClientAssets.Interface.Templates.Masks.Glow

local Sounds = {
	Click      = SoundAssets:FindFirstChild("Click"),
	Selected   = SoundAssets:FindFirstChild("Selected"),
	Deselected = SoundAssets:FindFirstChild("Deselected"),
	View       = SoundAssets:FindFirstChild("View"),
}

local function playSound(sound: Sound?)
	if not sound then return end
	SoundServicePlus:playSound(sound, StylizedConfig.SoundVolume)
end

local function createGlowFrame(glowColor: Color3?): Frame
	local GlowFrame = GlowTemplate:Clone()
	local GlowGradient = GlowFrame:FindFirstChild("Glow") :: UIGradient

	if GlowGradient then
		GlowGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, glowColor or StylizedConfig.Glow.DefaultColor),
			ColorSequenceKeypoint.new(1, StylizedConfig.Glow.FadeColor),
		})
	end

	return GlowFrame
end

local listTheme  = StylizedConfig.ListTheme
local childTheme = StylizedConfig.ChildTheme

local Stylized = {}

function Stylized:newList(): (Icon.Icon, {any}, {any})
	local newList = Icon.new()
	newList:modifyTheme(listTheme)
	newList:modifyChildTheme(childTheme)
	return newList, listTheme, childTheme
end

function Stylized:setChildIcon(newIcon: Icon.Icon, ImageID: number)
	local IconInstance = newIcon:getInstance("IconSpot") :: Frame
	local newImage = newIcon:getInstance("IconImage") :: ImageLabel

	local newImageFrame = Instance.new("Frame")
	newImageFrame.Name = "newImageFrame"
	newImageFrame.Size = StylizedConfig.Image.FrameSize
	newImageFrame.Position = StylizedConfig.Image.FramePosition
	newImageFrame.BackgroundTransparency = 1
	newImageFrame.Parent = IconInstance

	newImage.Name = "newImage"
	newImage.Image = "rbxassetid://" .. ImageID
	newImage.BackgroundTransparency = 1
	newImage.Parent = newImageFrame
end

function Stylized:setChildOutline(newIcon: Icon.Icon, parent: Icon.Icon, outlineColor: Color3?): UIStroke
	local IconInstance = newIcon:getInstance("IconSpot") :: Frame
	local OutlineConfig = StylizedConfig.Outline

	local Outline = (IconInstance:FindFirstChild("IconOutline") or Instance.new("UIStroke")) :: UIStroke
	Outline.Name = "IconOutline"
	Outline.Color = outlineColor or OutlineConfig.DefaultColor
	Outline.Thickness = OutlineConfig.DefaultThickness
	Outline.Transparency = 1
	Outline.Enabled = false
	Outline.Parent = IconInstance:WaitForChild("Glow", OutlineConfig.GlowFrameWaitTimeout) or IconInstance

	parent:bindEvent("selected", function()
		Outline.Enabled = true
		TweenService:Create(Outline, TweenInfo.new(OutlineConfig.FadeInDuration), {Transparency = 0}):Play()
		task.wait(OutlineConfig.FadeInWait)
	end)

	parent:bindEvent("deselected", function()
		Outline.Enabled = false
		TweenService:Create(Outline, TweenInfo.new(OutlineConfig.FadeOutDuration), {Transparency = 1}):Play()
		task.wait()
	end)

	return Outline
end

function Stylized:killChildOutline(newIcon: Icon.Icon, parent: Icon.Icon)
	local IconInstance = newIcon:getInstance("IconSpot") :: Frame
	local Outline = IconInstance:FindFirstChild("IconOutline") or IconInstance.Glow.IconOutline :: UIStroke
	Outline:Destroy()
end

function Stylized:setChildGleam(newIcon: Icon.Icon, parent: Icon.Icon, glowColor: Color3?, fadeTrans: {Start: number, End: number}?): UIGradient
	local IconInstance = newIcon:getInstance("IconSpot") :: Frame
	local GleamConfig = StylizedConfig.Gleam

	local newGlow = (IconInstance:FindFirstChild("GlowFrame") or createGlowFrame(glowColor)) :: Frame
	local Glow = newGlow:FindFirstChild("Glow") :: UIGradient

	if glowColor and Glow then
		Glow.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, glowColor),
			ColorSequenceKeypoint.new(1, GleamConfig.FadeColor or StylizedConfig.Glow.FadeColor),
		})
	end

	task.wait()

	newGlow.Visible = false
	newGlow.Parent = IconInstance
	newGlow.ZIndex = -1
	newGlow.Size = UDim2.new(1, 0, GleamConfig.GlowSizeY, 0)

	parent:bindEvent("selected", function()
		if not newGlow.Parent then return end
		newGlow.Visible = true
		TweenService:Create(newGlow, TweenInfo.new(GleamConfig.FadeDuration), {Transparency = 0}):Play()
	end)

	parent:bindEvent("deselected", function()
		if not newGlow.Parent then return end
		TweenService:Create(newGlow, TweenInfo.new(GleamConfig.FadeDuration), {Transparency = 1}):Play()
		task.delay(GleamConfig.HideDelay, function()
			newGlow.Visible = false
		end)
	end)

	local padding = IconInstance:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
	padding.Parent = IconInstance
	padding.PaddingTop = UDim.new(0, GleamConfig.PaddingValue)
	padding.PaddingBottom = UDim.new(0, GleamConfig.PaddingValue)
	padding.PaddingLeft = UDim.new(0, GleamConfig.PaddingValue)
	padding.PaddingRight = UDim.new(0, GleamConfig.PaddingValue)

	return Glow
end

function Stylized:setBackground(_icon: Icon.Icon)
	-- reserved for future background styling
end

function Stylized:newListChild(parent: Icon.Icon): Icon.Icon
	local newChild = Icon.new()
	newChild:joinDropdown(parent)
	return newChild
end

function Stylized:bindIconToSounds(newIcon: Icon.Icon, oneClick: boolean?)
	if oneClick then
		newIcon:bindEvent("toggled", function()
			playSound(Sounds.Click)
		end)
	else
		newIcon:bindEvent("selected", function()
			playSound(Sounds.Selected)
		end)
		newIcon:bindEvent("deselected", function()
			playSound(Sounds.Deselected)
		end)
	end

	newIcon:bindEvent("viewingStarted", function()
		playSound(Sounds.View)
	end)
end

function Stylized:toggleCoreGui(coreGuiType: Enum.CoreGuiType, enabled: boolean)
	StarterGui:SetCoreGuiEnabled(coreGuiType, enabled)
end

return Stylized