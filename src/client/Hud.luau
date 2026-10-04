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
	isMusicMuted: (() -> boolean)?,
	toggleMusicMute: (() -> boolean)?,
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

	if options and options.toggleMusicMute and options.isMusicMuted then
		local mute = Instance.new("TextButton")
		mute.Name = "MuteMusic"
		mute.AnchorPoint = Vector2.new(1, 1)
		mute.Position = UDim2.new(1, -16, 1, -16)
		mute.Size = UDim2.fromOffset(52, 52)
		mute.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
		mute.BackgroundTransparency = 0.1
		mute.AutoButtonColor = true
		mute.Text = "♪"
		mute.TextColor3 = Color3.new(1, 1, 1)
		mute.TextSize = 26
		mute.Font = Enum.Font.GothamBold
		mute.Parent = gui
		corner(mute, UDim.new(0, 12))
		stroke(mute, 2.5, Enum.ApplyStrokeMode.Border)

		local function refreshMute()
			local muted = options.isMusicMuted()
			mute.Text = if muted then "OFF" else "♪"
			mute.TextSize = if muted then 16 else 26
			mute.TextTransparency = if muted then 0.15 else 0
			mute.BackgroundColor3 = if muted then Color3.fromRGB(55, 40, 40) else Color3.fromRGB(30, 30, 36)
		end

		mute.Activated:Connect(function()
			options.toggleMusicMute()
			refreshMute()
		end)
		refreshMute()
	end

	local function popGain(gain: number)
		local popup = Instance.new("TextLabel")
		popup.Name = "Gain"
		popup.BackgroundTransparency = 1
		popup.AnchorPoint = Vector2.new(0, 1)
		popup.Position = UDim2.new(0, 76, 0.5, -30)
		popup.Size = UDim2.fromOffset(160, 30)
		popup.TextXAlignment = Enum.TextXAlignment.Left
		popup.Text = "+" .. Format.cash(gain)
		popup.TextColor3 = MONEY_GREEN
		popup.TextSize = 24
		popup.Font = Enum.Font.GothamBold
		popup.Parent = gui
		stroke(popup, 2)

		local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(popup, info, {
			Position = popup.Position - UDim2.fromOffset(0, 40),
			TextTransparency = 1,
		}):Play()
		task.delay(info.Time, function()
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
