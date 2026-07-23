-- FAKE VR PARA NEXUS VR v2.0 (script de IKER)
-- Fixes: cam nil, nomes de funções, timer, conexões, Z-input
-- Melhorias: corpo VR (torso + cintura + cabeça), no-clip eficiente

local remoto     = game:GetService("ReplicatedStorage").NexusVRCharacterModel.UpdateInputs
local plr        = game:GetService("Players").LocalPlayer
local cam        = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local Players    = game:GetService("Players")

game:GetService("ReplicatedStorage").NexusVRCharacterModel.ReplicationReady:FireServer()

-- Joystick valores
local leftJoy  = Vector2.new(0, 0)
local rightJoy = Vector2.new(0, 0)
local leftZ    = 0
local rightZ   = 0
local leftArrastando  = false
local rightArrastando = false

-- Otimização de rede
local tAnterior  = 0
local TAXA_ENVIO = 1 / 25

-- Variáveis ponte (RenderStepped -> Stepped)
local headCF      = CFrame.new()
local leftHandCF  = CFrame.new()
local rightHandCF = CFrame.new()

-- Lerp suave para rotação do torso
local torsoYawAtual = 0

-- 1. INTERFACE SEGURA (imune a limpezas de mapa)
local ParentGui
local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
if gethui then
    ParentGui = gethui()
elseif ok and coreGui and coreGui:FindFirstChild("RobloxGui") then
    ParentGui = coreGui:FindFirstChild("RobloxGui")
else
    ParentGui = plr:WaitForChild("PlayerGui")
end

if ParentGui:FindFirstChild("NexusVR_Mobile_Joysticks") then
    ParentGui["NexusVR_Mobile_Joysticks"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "NexusVR_Mobile_Joysticks"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 99999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = ParentGui

-- 2. JOYSTICK PRINCIPAL (eixo X / Y)
local function criarJoystick(nome, posicao, cor)
    local Pad   = Instance.new("Frame")
    local Thumb = Instance.new("ImageButton")

    Pad.Name                   = nome .. "_Pad"
    Pad.Size                   = UDim2.new(0, 125, 0, 125)
    Pad.Position               = posicao
    Pad.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
    Pad.BackgroundTransparency = 0.6
    Pad.BorderSizePixel        = 0
    Pad.Active                 = true
    Pad.Visible                = false
    Pad.Parent                 = ScreenGui
    Instance.new("UICorner", Pad).CornerRadius = UDim.new(1, 0)

    Thumb.Name                   = "Thumb"
    Thumb.Size                   = UDim2.new(0, 50, 0, 50)
    Thumb.Position               = UDim2.new(0.5, -25, 0.5, -25)
    Thumb.BackgroundColor3       = cor
    Thumb.BackgroundTransparency = 0.2
    Thumb.BorderSizePixel        = 0
    Thumb.Parent                 = Pad
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

    local arrastando = false
    local startPos   = Vector2.new()
    local inputAtual = nil

    Thumb.InputBegan:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.Touch
         or inp.UserInputType == Enum.UserInputType.MouseButton1)
         and not arrastando then
            arrastando = true
            startPos   = inp.Position
            inputAtual = inp
            if nome == "Direito" then rightArrastando = true else leftArrastando = true end
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if not arrastando or inp ~= inputAtual then return end
        local delta     = inp.Position - startPos
        local dist      = math.clamp(delta.Magnitude, 0, 45)
        local dir       = delta.Magnitude > 0 and delta.Unit or Vector2.new(0, 0)
        local intensidade = dist / 45

        Thumb.Position = UDim2.new(0.5, -25 + dir.X * dist, 0.5, -25 + dir.Y * dist)

        if nome == "Direito" then
            rightJoy = Vector2.new(dir.X * intensidade, -dir.Y * intensidade)
        else
            leftJoy  = Vector2.new(dir.X * intensidade, -dir.Y * intensidade)
        end
    end)

    UIS.InputEnded:Connect(function(inp)
        if not arrastando or inp ~= inputAtual then return end
        arrastando = false
        inputAtual = nil
        if nome == "Direito" then rightArrastando = false else leftArrastando = false end
    end)
end

-- 3. JOYSTICK Z (profundidade dos braços)
local function criarJoystickZ(nome, posicao, cor)
    local Pad   = Instance.new("Frame")
    local Thumb = Instance.new("ImageButton")

    Pad.Name                   = nome .. "_Z_Pad"
    Pad.Size                   = UDim2.new(0, 75, 0, 75)
    Pad.Position               = posicao
    Pad.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
    Pad.BackgroundTransparency = 0.6
    Pad.BorderSizePixel        = 0
    Pad.Active                 = true
    Pad.Visible                = false
    Pad.Parent                 = ScreenGui
    Instance.new("UICorner", Pad).CornerRadius = UDim.new(1, 0)

    Thumb.Name                   = "Thumb"
    Thumb.Size                   = UDim2.new(0, 30, 0, 30)
    Thumb.Position               = UDim2.new(0.5, -15, 0.5, -15)
    Thumb.BackgroundColor3       = cor
    Thumb.BackgroundTransparency = 0.2
    Thumb.BorderSizePixel        = 0
    Thumb.Parent                 = Pad
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

    local arrastando = false
    local inputAtual = nil
    local distMax    = 25

    local function atualizarZ(inp)
        local centerY  = Pad.AbsolutePosition.Y + Pad.AbsoluteSize.Y / 2
        local relY     = inp.Position.Y - centerY
        local clampY   = math.clamp(relY, -distMax, distMax)
        Thumb.Position = UDim2.new(0.5, -15, 0.5, -15 + clampY)
        local intensidade = -clampY / distMax
        if nome == "Direito" then rightZ = intensidade else leftZ = intensidade end
    end

    Thumb.InputBegan:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.Touch
         or inp.UserInputType == Enum.UserInputType.MouseButton1)
         and not arrastando then
            arrastando = true
            inputAtual = inp
            atualizarZ(inp)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if arrastando and inp == inputAtual then atualizarZ(inp) end
    end)

    UIS.InputEnded:Connect(function(inp)
        if arrastando and inp == inputAtual then
            arrastando = false
            inputAtual = nil
            if nome == "Direito" then rightZ = 0 else leftZ = 0 end
            Thumb.Position = UDim2.new(0.5, -15, 0.5, -15)
        end
    end)
end

-- Criação dos 4 controles
criarJoystick ("Esquerdo", UDim2.new(0,  40,  1, -170), Color3.fromRGB(255,  60,  60))
criarJoystickZ("Esquerdo", UDim2.new(0, 180,  1, -145), Color3.fromRGB(255, 140, 140))
criarJoystick ("Direito",  UDim2.new(1, -165, 1, -170), Color3.fromRGB( 60, 130, 255))
criarJoystickZ("Direito",  UDim2.new(1, -255, 1, -145), Color3.fromRGB(140, 190, 255))

-- 4. BOTÃO OCULTAR / MOSTRAR
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name                   = "ToggleVR_UI"
ToggleBtn.Size                   = UDim2.new(0, 120, 0, 35)
ToggleBtn.Position               = UDim2.new(0.5, -60, 0, 40)
ToggleBtn.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
ToggleBtn.BackgroundTransparency = 0.4
ToggleBtn.Text                   = "Controles ocultos"
ToggleBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize               = 13
ToggleBtn.Font                   = Enum.Font.SourceSansBold
ToggleBtn.Visible                = false
ToggleBtn.Parent                 = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local uiVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    ToggleBtn.Text = uiVisible and "Ocultar Controles" or "Mostrar Controles"
    for _, nome in ipairs({"Esquerdo_Pad","Esquerdo_Z_Pad","Direito_Pad","Direito_Z_Pad"}) do
        local pad = ScreenGui:FindFirstChild(nome)
        if pad then pad.Visible = uiVisible end
    end
end)

-- 5. INTRO ÉPICA
local IntroFrame = Instance.new("Frame")
IntroFrame.Size                   = UDim2.new(1, 0, 1, 0)
IntroFrame.BackgroundColor3       = Color3.fromRGB(10, 10, 12)
IntroFrame.BackgroundTransparency = 0
IntroFrame.BorderSizePixel        = 0
IntroFrame.Parent                 = ScreenGui

local IntroText = Instance.new("TextLabel")
IntroText.Size                   = UDim2.new(0, 400, 0, 100)
IntroText.Position               = UDim2.new(0.5, -200, 0.5, -50)
IntroText.BackgroundTransparency = 1
IntroText.Text                   = "Script de IKER"
IntroText.TextColor3             = Color3.fromRGB(255, 255, 255)
IntroText.TextSize               = 34
IntroText.Font                   = Enum.Font.FredokaOne
IntroText.TextTransparency       = 1
IntroText.Parent                 = IntroFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color        = Color3.fromRGB(0, 180, 255)
UIStroke.Thickness    = 3
UIStroke.Transparency = 1
UIStroke.Parent       = IntroText

task.spawn(function()
    task.wait(0.5)
    IntroText.Size     = UDim2.new(0, 360, 0, 90)
    IntroText.Position = UDim2.new(0.5, -180, 0.5, -45)

    local infoIn = TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenSvc:Create(IntroText, infoIn, {
        TextTransparency = 0,
        Size     = UDim2.new(0, 420, 0, 110),
        Position = UDim2.new(0.5, -210, 0.5, -55)
    }):Play()
    TweenSvc:Create(UIStroke, infoIn, {Transparency = 0.2}):Play()
    task.wait(2.7)

    local infoOut = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    TweenSvc:Create(IntroText, infoOut, {TextTransparency = 1}):Play()
    TweenSvc:Create(UIStroke,  infoOut, {Transparency = 1}):Play()
    local frameTween = TweenSvc:Create(IntroFrame, infoOut, {BackgroundTransparency = 1})
    frameTween:Play()
    frameTween.Completed:Wait()

    IntroFrame:Destroy()
    ToggleBtn.Visible = true
    for _, nome in ipairs({"Esquerdo_Pad","Esquerdo_Z_Pad","Direito_Pad","Direito_Z_Pad"}) do
        local pad = ScreenGui:FindFirstChild(nome)
        if pad then pad.Visible = true end
    end
end)

-- 6. NO-CLIP OTIMIZADO (CharacterAdded + DescendantAdded, zero custo por frame)
local function aplicarNoClip(char)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") then p.CanCollide = false end
    end)
end

for _, outro in ipairs(Players:GetPlayers()) do
    if outro ~= plr then
        if outro.Character then aplicarNoClip(outro.Character) end
        outro.CharacterAdded:Connect(aplicarNoClip)
    end
end
Players.PlayerAdded:Connect(function(outro)
    if outro ~= plr then
        outro.CharacterAdded:Connect(aplicarNoClip)
    end
end)

-- 7. HILO 1 — ENTRADAS, LERP E REDE (RenderStepped)
RunService.RenderStepped:Connect(function()

    -- Lerp suave dos joysticks ao soltar
    if not leftArrastando then
        leftJoy = leftJoy:Lerp(Vector2.new(0, 0), 0.07)
        local t = ScreenGui:FindFirstChild("Esquerdo_Pad") and ScreenGui["Esquerdo_Pad"]:FindFirstChild("Thumb")
        if t then t.Position = t.Position:Lerp(UDim2.new(0.5,-25,0.5,-25), 0.07) end
    end
    if not rightArrastando then
        rightJoy = rightJoy:Lerp(Vector2.new(0, 0), 0.07)
        local t = ScreenGui:FindFirstChild("Direito_Pad") and ScreenGui["Direito_Pad"]:FindFirstChild("Thumb")
        if t then t.Position = t.Position:Lerp(UDim2.new(0.5,-25,0.5,-25), 0.07) end
    end

    local char = plr.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return end

    local rootCF = char.HumanoidRootPart.CFrame
    local camCF  = cam.CFrame

    -- Extrair ângulos da câmera
    local pitchCam, yawCam, rollCam = camCF:ToEulerAnglesXYZ()

    -- Lerp suave do yaw do torso
    torsoYawAtual = torsoYawAtual + (yawCam - torsoYawAtual) * 0.12

    -- Base do torso com inclinação leve ao olhar para cima/baixo
    local leanPitch = math.clamp(pitchCam * 0.35, -0.3, 0.3)
    local torsoCF = CFrame.new(rootCF.Position)
        * CFrame.Angles(0, torsoYawAtual, 0)
        * CFrame.Angles(leanPitch, 0, 0)

    -- Cabeça: rastreamento completo da câmera (6 DoF)
    headCF = CFrame.new(rootCF.Position + Vector3.new(0, 2.2, 0))
        * CFrame.Angles(pitchCam, yawCam, rollCam)

    -- Mãos relativas ao torso orientado
    local zEsq = math.clamp(-1.2 - leftZ  * 1.3, -2.4, -0.2)
    local zDir = math.clamp(-1.2 - rightZ * 1.3, -2.4, -0.2)

    leftHandCF = torsoCF
        * CFrame.new(
            -1.2 + math.clamp(leftJoy.X * 1.5, -1.5, 1.5),
             0.5 + math.clamp(leftJoy.Y * 1.5, -1.5, 1.5),
             zEsq
          )
        * CFrame.Angles(
            math.rad(leftJoy.Y  *  55),
            math.rad(-leftJoy.X *  35),
            math.rad(-leftJoy.X *  25)
          )

    rightHandCF = torsoCF
        * CFrame.new(
             1.2 + math.clamp(rightJoy.X * 1.5, -1.5, 1.5),
             0.5 + math.clamp(rightJoy.Y * 1.5, -1.5, 1.5),
             zDir
          )
        * CFrame.Angles(
            math.rad(rightJoy.Y  *  55),
            math.rad(-rightJoy.X *  35),
            math.rad( rightJoy.X *  25)
          )

    -- Envio à rede (limitado a 25/s)
    local tAtual = os.clock()
    if tAtual - tAnterior >= TAXA_ENVIO then
        pcall(function()
            remoto:FireServer(headCF, leftHandCF, rightHandCF)
        end)
        tAnterior = tAtual
    end
end)

-- 8. HILO 2 — ESPELHO LOCAL + CORPO VR (Stepped)
RunService.Stepped:Connect(function()
    local char = plr.Character
    if not char then return end

    -- Rotacionar o corpo para seguir a câmera
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(hrp.Position)
            * CFrame.Angles(0, torsoYawAtual, 0)
    end

    -- Articulações sobrepõem as animações do jogo com posições VR
    local neck = char:FindFirstChild("Neck", true)
    local lSho = char:FindFirstChild("Left Shoulder", true)
             or char:FindFirstChild("LeftShoulder",   true)
    local rSho = char:FindFirstChild("Right Shoulder", true)
             or char:FindFirstChild("RightShoulder",   true)

    if neck and neck.Part0 then
        neck.Transform = neck.C0:Inverse() * neck.Part0.CFrame:Inverse() * headCF * neck.C1
    end
    if lSho and lSho.Part0 then
        lSho.Transform = lSho.C0:Inverse() * lSho.Part0.CFrame:Inverse() * leftHandCF * lSho.C1
    end
    if rSho and rSho.Part0 then
        rSho.Transform = rSho.C0:Inverse() * rSho.Part0.CFrame:Inverse() * rightHandCF * rSho.C1
    end

    -- Cintura (R15): inclina o torso superior ao olhar para cima/baixo
    local waist = char:FindFirstChild("Waist", true)
    if waist then
        local pitchCam = cam.CFrame:ToEulerAnglesXYZ()
        local lean = math.clamp(pitchCam * 0.4, -0.35, 0.35)
        waist.Transform = CFrame.Angles(lean, 0, 0)
    end
end)
