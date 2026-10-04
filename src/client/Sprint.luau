-- Hold Left Shift to sprint. Speeds / FOV live in TycoonConfig.Sprint.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Missing ReplicatedStorage.Shared")

local TycoonConfig = require(Shared:WaitForChild("TycoonConfig", 10))

local Sprint = {}

local player = Players.LocalPlayer
local isSprinting = false
local shiftHeld = false

local function getHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	if not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	return humanoid
end

local function tweenFov(fov: number, duration: number, style: Enum.EasingStyle)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	TweenService:Create(camera, TweenInfo.new(duration, style, Enum.EasingDirection.Out), {
		FieldOfView = fov,
	}):Play()
end

local function tweenWalkSpeed(humanoid: Humanoid, speed: number)
	local cfg = TycoonConfig.Sprint
	TweenService:Create(humanoid, TweenInfo.new(cfg.SpeedTween, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		WalkSpeed = speed,
	}):Play()
end

local function stopSprinting()
	if not isSprinting then
		return
	end
	isSprinting = false
	local cfg = TycoonConfig.Sprint
	tweenFov(cfg.NormalFov, cfg.FovOutTween, Enum.EasingStyle.Back)
	local humanoid = getHumanoid()
	if humanoid then
		tweenWalkSpeed(humanoid, cfg.NormalSpeed)
	end
end

local function startSprinting()
	if isSprinting then
		return
	end
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	isSprinting = true
	local cfg = TycoonConfig.Sprint
	tweenFov(cfg.SprintFov, cfg.FovInTween, Enum.EasingStyle.Quad)
	tweenWalkSpeed(humanoid, cfg.SprintSpeed)
end

local function onCharacter(character: Model)
	isSprinting = false
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	humanoid.WalkSpeed = TycoonConfig.Sprint.NormalSpeed
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = TycoonConfig.Sprint.NormalFov
	end
	humanoid.Died:Connect(function()
		shiftHeld = false
		stopSprinting()
	end)
	-- If shift is still held after respawn, pick sprint back up.
	if shiftHeld then
		startSprinting()
	end
end

function Sprint.start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			shiftHeld = true
			startSprinting()
		end
	end)

	-- Always stop on release even if chat ate the event mid-sprint.
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			shiftHeld = false
			stopSprinting()
		end
	end)

	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return Sprint
