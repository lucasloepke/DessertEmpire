-- Money HUD: reads the server-replicated Cash attribute; never writes money.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local Format = require(Shared:WaitForChild("Format", 10))

local Hud = {}

local MONEY_GREEN = Color3.fromRGB(90, 235, 100)

local function stroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
end

local function corner(parent: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

function Hud.start(options: {
	getMusicVolume: (() -> number)?,
	setMusicVolume: ((number) -> ())?,
}?)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10)
	assert(playerGui, "Missing PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "TycoonHud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Money"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 16, 0.5, 0)
	frame.Size = UDim2.fromOffset(230, 58)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui
	corner(frame, UDim.new(0, 12))
	stroke(frame, 2.5, Enum.ApplyStrokeMode.Border)

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 7, 0.5, 0)
	icon.Size = UDim2.fromOffset(44, 44)
	icon.BackgroundColor3 = Color3.fromRGB(50, 180, 70)
	icon.Text = "$"
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextSize = 30
	icon.Font = Enum.Font.GothamBold
	icon.Parent = frame
	corner(icon, UDim.new(1, 0))
	stroke(icon, 2)

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.BackgroundTransparency = 1
	amount.Position = UDim2.fromOffset(60, 0)
	amount.Size = UDim2.new(1, -70, 1, 0)
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Text = "$0"
	amount.TextColor3 = MONEY_GREEN
	amount.TextSize = 30
	amount.Font = Enum.Font.GothamBold
	amount.Parent = frame
	stroke(amount, 2)

	if options and options.getMusicVolume and options.setMusicVolume then
		local UserInputService = game:GetService("UserInputService")

		local box = Instance.new("Frame")
		box.Name = "MusicVolume"
		box.AnchorPoint = Vector2.new(1, 1)
		box.Position = UDim2.new(1, -16, 1, -16)
		box.Size = UDim2.fromOffset(52, 52)
		box.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
		box.BackgroundTransparency = 0.1
		box.Active = true
		box.ClipsDescendants = true
		box.Parent = gui
		corner(box, UDim.new(0, 12))
		stroke(box, 2.5, Enum.ApplyStrokeMode.Border)

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.AnchorPoint = Vector2.new(0.5, 1)
		fill.Position = UDim2.fromScale(0.5, 1)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
		fill.BackgroundTransparency = 0.25
		fill.BorderSizePixel = 0
		fill.ZIndex = 1
		fill.Parent = box

		local note = Instance.new("TextLabel")
		note.Name = "Note"
		note.BackgroundTransparency = 1
		note.Size = UDim2.fromScale(1, 1)
		note.ZIndex = 2
		note.Text = "♪"
		note.TextColor3 = Color3.new(1, 1, 1)
		note.TextSize = 22
		note.Font = Enum.Font.GothamBold
		note.Parent = box
		stroke(note, 2)

		local function refreshFill()
			local level = math.clamp(options.getMusicVolume(), 0, 1)
			fill.Size = UDim2.fromScale(1, level)
			note.TextTransparency = if level <= 0.001 then 0.45 else 0
		end

		local function volumeFromY(screenY: number)
			local top = box.AbsolutePosition.Y
			local height = box.AbsoluteSize.Y
			if height <= 0 then
				return 0
			end
			-- Top of box = 1, bottom = 0.
			return math.clamp(1 - (screenY - top) / height, 0, 1)
		end

		local dragging = false
		local function setFromInput(input: InputObject)
			options.setMusicVolume(volumeFromY(input.Position.Y))
			refreshFill()
		end

		box.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				setFromInput(input)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				setFromInput(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)

		refreshFill()
	end

	local function popGain(gain: number)
		local boxWidth = frame.Size.X.Offset
		local startX = math.random(16, math.max(16, boxWidth - 16))

		local popup = Instance.new("TextLabel")
		popup.Name = "Gain"
		popup.BackgroundTransparency = 1
		popup.AnchorPoint = Vector2.new(0.5, 1)
		popup.Position = UDim2.fromOffset(startX, 4)
		popup.Size = UDim2.fromOffset(120, 28)
		popup.TextXAlignment = Enum.TextXAlignment.Center
		popup.Text = "+" .. Format.cash(gain)
		popup.TextColor3 = MONEY_GREEN
		popup.TextSize = 24
		popup.Font = Enum.Font.GothamBold
		popup.ZIndex = 5
		popup.Parent = frame

		local outline = Instance.new("UIStroke")
		outline.Thickness = 2
		outline.Color = Color3.new(0, 0, 0)
		outline.Parent = popup

		local hold = 0.5
		local fade = 0.9
		local riseInfo = TweenInfo.new(hold + fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeInfo = TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, hold)
		TweenService:Create(popup, riseInfo, {
			Position = UDim2.fromOffset(startX, -44),
		}):Play()
		TweenService:Create(popup, fadeInfo, {
			TextTransparency = 1,
		}):Play()
		TweenService:Create(outline, fadeInfo, {
			Transparency = 1,
		}):Play()
		task.delay(hold + fade, function()
			popup:Destroy()
		end)

		scale.Scale = 1.08
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end

	local lastCash: number? = nil
	local function onCashChanged()
		local cash = player:GetAttribute("Cash")
		if typeof(cash) ~= "number" then
			return
		end
		amount.Text = Format.cash(cash)
		if lastCash and cash > lastCash then
			popGain(cash - lastCash)
		end
		lastCash = cash
	end

	player:GetAttributeChangedSignal("Cash"):Connect(onCashChanged)
	onCashChanged()
end

return Hud
