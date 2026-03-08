--==================================================
-- GTA 5 YAGO | ANDROID + PC FIXED UI
-- Aimbot + ESP + Infinite Jump + Speed
--==================================================

-- SERVIÃ‡OS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local AIM_PART = "Head"
local AIM_SMOOTH = 0.8
local SPEED_VALUE = 30

-- ESTADOS
local AimbotON = false
local ESPON = false
local InfiniteJumpON = false
local SpeedON = false

--==================================================
-- GUI (VERMELHA / NÃƒO FECHA)
--==================================================
local gui = Instance.new("ScreenGui")
gui.Name = "GTA5YAGO_UI"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 300)
frame.Position = UDim2.new(0.5, -160, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(120,0,0)
frame.BorderSizePixel = 0
frame.Active = true

-- TÃTULO
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.BackgroundColor3 = Color3.fromRGB(160,0,0)
title.Text = "DarkMatter Hub ðŸ‰"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 30

-- CRÃ‰DITO
local credit = Instance.new("TextLabel", frame)
credit.Size = UDim2.new(1,0,0,30)
credit.Position = UDim2.new(0,0,1,-30)
credit.Text = "Criador: YouTube GTA 5 Yago"
credit.TextColor3 = Color3.fromRGB(220,220,220)
credit.BackgroundTransparency = 1
credit.Font = Enum.Font.Gotham
credit.TextSize = 20

--==================================================
-- DRAG ANDROID + PC
--==================================================
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

--==================================================
-- FUNÃ‡ÃƒO DE BOTÃƒO
--==================================================
local function Button(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0.9,0,0,40)
	b.Position = UDim2.new(0.05,0,0,y)
	b.BackgroundColor3 = Color3.fromRGB(180,0,0)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 20
	b.BorderSizePixel = 0
	b.Text = text
	return b
end

-- BOTÃ•ES
local btnAimbot = Button("AIMBOT: OFF", 50)
local btnESP = Button("ESP: OFF", 100)
local btnJump = Button("PULO INFINITO: OFF", 150)
local btnSpeed = Button("SPEED: OFF", 200)

btnAimbot.MouseButton1Click:Connect(function()
	AimbotON = not AimbotON
	btnAimbot.Text = "AIMBOTðŸ‰: " .. (AimbotON and "ON" or "OFF")
end)

btnESP.MouseButton1Click:Connect(function()
	ESPON = not ESPON
	btnESP.Text = "ESP: " .. (ESPON and "ON" or "OFF")
end)

btnJump.MouseButton1Click:Connect(function()
	InfiniteJumpON = not InfiniteJumpON
	btnJump.Text = "PULO INFINITO: " .. (InfiniteJumpON and "ON" or "OFF")
end)

btnSpeed.MouseButton1Click:Connect(function()
	SpeedON = not SpeedON
	btnSpeed.Text = "SPEED: " .. (SpeedON and "ON" or "OFF")
end)

--==================================================
-- AIMBOT FORTE
--==================================================
local function closestPlayer()
	local c, d = nil, math.huge
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(AIM_PART) then
			local pos, v = Camera:WorldToViewportPoint(p.Character[AIM_PART].Position)
			if v then
				local dist = (Vector2.new(pos.X,pos.Y) -
					Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
				if dist < d then
					d = dist
					c = p
				end
			end
		end
	end
	return c
end

RunService.RenderStepped:Connect(function()
	if AimbotON then
		local t = closestPlayer()
		if t and t.Character then
			Camera.CFrame = Camera.CFrame:Lerp(
				CFrame.new(Camera.CFrame.Position, t.Character[AIM_PART].Position),
				AIM_SMOOTH == 0 and 1 or AIM_SMOOTH
			)
		end
	end
end)

--==================================================
-- ESP BOX + LINHA
--==================================================
local function ESP(player)
	local box = Drawing.new("Square")
	box.Thickness = 2
	box.Filled = false
	box.Color = Color3.fromRGB(255,0,0)

	local line = Drawing.new("Line")
	line.Thickness = 2
	line.Color = Color3.fromRGB(0,255,0)

	RunService.RenderStepped:Connect(function()
		if ESPON and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
			if vis then
				box.Size = Vector2.new(45,65)
				box.Position = Vector2.new(pos.X-22,pos.Y-32)
				box.Visible = true
				line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
				line.To = Vector2.new(pos.X,pos.Y)
				line.Visible = true
			else
				box.Visible = false
				line.Visible = false
			end
		else
			box.Visible = false
			line.Visible = false
		end
	end)
end

for _,p in pairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then ESP(p) end
end

Players.PlayerAdded:Connect(function(p)
	task.wait(1)
	ESP(p)
end)

--==================================================
-- PULO INFINITO
--==================================================
UserInputService.JumpRequest:Connect(function()
	if InfiniteJumpON and LocalPlayer.Character then
		local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

--==================================================
-- SPEED (NÃƒO RESETA)
--==================================================
local function applySpeed()
	if LocalPlayer.Character then
		local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if h then
			h.WalkSpeed = SpeedON and SPEED_VALUE or 16
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	applySpeed()
end)

RunService.Heartbeat:Connect(function()
	if SpeedON then
		applySpeed()
	end
end)
