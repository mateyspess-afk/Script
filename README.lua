-- FAKE VR + NEXUS VR + ANIMAÇÃO DE CAMINHADA VR + MOVIMENTO AJUSTADO + BRAÇOS/CABEÇA ALINHADOS + OTIMIZADO
local remote = game:GetService("ReplicatedStorage").NexusVRCharacterModel.UpdateInputs
local plr = game:GetService("Players").LocalPlayer
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- Notificar servidor que está pronto
game:GetService("ReplicatedStorage").NexusVRCharacterModel.ReplicationReady:FireServer()

-- Variáveis de controle
local leftJoyMove = Vector2.new(0, 0)
local rightJoyMove = Vector2.new(0, 0)
local leftZMove = 0
local rightZMove = 0
local leftLargeDragging = false
local rightLargeDragging = false

-- Otimização de rede
local tAnterior = 0
local TASA_ENVIO = 1 / 30
local LERP_SUAVE = 0.12

-- Posições sincronizadas
local headCF = CFrame.new()
local leftHandCF = CFrame.new()
local rightHandCF = CFrame.new()

-- Sistema de GUI seguro
local ParentGui
local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
if gethui then
    ParentGui = gethui()
elseif success and coreGui and coreGui:FindFirstChild("RobloxGui") then
    ParentGui = coreGui:FindFirstChild("RobloxGui")
else
    ParentGui = plr:WaitForChild("PlayerGui")
end

if ParentGui:FindFirstChild("NexusVR_Mobile_Joysticks") then
    ParentGui["NexusVR_Mobile_Joysticks"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusVR_Mobile_Joysticks"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 99999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = ParentGui

-- CRIAR JOYSTICKS PRINCIPAIS (X,Y)
local function criarJoystick(nome, posicion, cor)
    local Painel = Instance.new("Frame")
    local Botao = Instance.new("ImageButton")
    
    Painel.Name = nome.."_Painel"
    Painel.Size = UDim2.new(0, 130, 0, 130)
    Painel.Position = posicion
    Painel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    Painel.BackgroundTransparency = 0.65
    Painel.BorderSizePixel = 0
    Painel.Active = true
    Painel.Visible = false
    Painel.Parent = ScreenGui
    
    Instance.new("UICorner", Painel).CornerRadius = UDim.new(1,0)
    
    Botao.Name = "Controle"
    Botao.Size = UDim2.new(0, 55, 0, 55)
    Botao.Position = UDim2.new(0.5, -27.5, 0.5, -27.5)
    Botao.BackgroundColor3 = cor
    Botao.BackgroundTransparency = 0.15
    Botao.BorderSizePixel = 0
    Botao.Parent = Painel
    
    Instance.new("UICorner", Botao).CornerRadius = UDim.new(1,0)

    local arrastando = false
    local posInicial = Vector2.new()
    local entradaAtual = nil
    
    Botao.InputBegan:Connect(function(entrada)
        if (entrada.UserInputType == Enum.UserInputType.Touch or entrada.UserInputType == Enum.UserInputType.MouseButton1) and not arrastando then
            arrastando = true
            posInicial = entrada.Position
            entradaAtual = entrada
            if nome == "Direito" then rightLargeDragging = true else leftLargeDragging = true end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(entrada)
        if arrastando and entrada == entradaAtual then
            local delta = entrada.Position - posInicial
            local distancia = math.clamp(delta.Magnitude, 0, 50)
            local direcao = delta.Magnitude > 0 and delta.Unit or Vector2.zero
            
            Botao.Position = UDim2.new(0.5, -27.5 + direcao.X * distancia, 0.5, -27.5 + direcao.Y * distancia)
            local forca = distancia / 50
            
            if nome == "Direito" then
                rightJoyMove = Vector2.new(direcao.X * forca, -direcao.Y * forca)
            else
                leftJoyMove = Vector2.new(direcao.X * forca, -direcao.Y * forca)
            end
        end
    end)
    
    local function pararArrasto(entrada)
        if arrastando and entrada == entradaAtual then
            arrastando = false
            entradaAtual = nil
            if nome == "Direito" then rightLargeDragging = false else leftLargeDragging = false end
        end
    end
    UserInputService.InputEnded:Connect(pararArrasto)
end

-- CRIAR JOYSTICKS DE Z (EXTENSÃO DOS BRAÇOS)
local function criarJoystickZ(nome, posicion, cor)
    local Painel = Instance.new("Frame")
    local Botao = Instance.new("ImageButton")
    
    Painel.Name = nome.."_Z_Painel"
    Painel.Size = UDim2.new(0, 80, 0, 80)
    Painel.Position = posicion
    Painel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    Painel.BackgroundTransparency = 0.65
    Painel.BorderSizePixel = 0
    Painel.Active = true
    Painel.Visible = false
    Painel.Parent = ScreenGui
    
    Instance.new("UICorner", Painel).CornerRadius = UDim.new(1,0)
    
    Botao.Name = "Controle"
    Botao.Size = UDim2.new(0, 32, 0, 32)
    Botao.Position = UDim2.new(0.5, -16, 0.5, -16)
    Botao.BackgroundColor3 = cor
    Botao.BackgroundTransparency = 0.15
    Botao.BorderSizePixel = 0
    Botao.Parent = Painel
    
    Instance.new("UICorner", Botao).CornerRadius = UDim.new(1,0)

    local arrastando = false
    local entradaAtual = nil
    local LIMITE_Z = 28
    
    local function atualizarZ(entrada)
        local centroY = Painel.AbsolutePosition.Y + Painel.AbsoluteSize.Y/2
        local desvio = math.clamp(entrada.Position.Y - centroY, -LIMITE_Z, LIMITE_Z)
        Botao.Position = UDim2.new(0.5, -16, 0.5, -16 + desvio)
        if nome == "Direito" then rightZMove = -desvio / LIMITE_Z else leftZMove = -desvio / LIMITE_Z end
    end
    
    Botao.InputBegan:Connect(function(entrada)
        if (entrada.UserInputType == Enum.UserInputType.Touch or entrada.UserInputType == Enum.UserInputType.MouseButton1) and not arrastando then
            arrastando = true
            entradaAtual = entrada
            atualizarZ(entrada)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(entrada)
        if arrastando and entrada == entradaAtual then atualizarZ(entrada) end
    end)
    
    UserInputService.InputEnded:Connect(function(entrada)
        if arrastando and entrada == entradaAtual then arrastando = false; entradaAtual = nil end
    end)
end

-- CRIAR TODOS OS CONTROLES
criarJoystick("Esquerdo", UDim2.new(0, 35, 1, -180), Color3.fromRGB(255, 70, 70))
criarJoystickZ("Esquerdo", UDim2.new(0, 190, 1, -150), Color3.fromRGB(255, 150, 150))
criarJoystick("Direito", UDim2.new(1, -175, 1, -180), Color3.fromRGB(70, 150, 255))
criarJoystickZ("Direito", UDim2.new(1, -265, 1, -150), Color3.fromRGB(150, 200, 255))

-- BOTÃO MOSTRAR/OCULTAR
local BotaoAlternar = Instance.new("TextButton")
BotaoAlternar.Name = "AlternarVR"
BotaoAlternar.Size = UDim2.new(0, 130, 0, 38)
BotaoAlternar.Position = UDim2.new(0.5, -65, 0, 35)
BotaoAlternar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
BotaoAlternar.BackgroundTransparency = 0.4
BotaoAlternar.Text = "Esconder Controles"
BotaoAlternar.TextColor3 = Color3.new(1,1,1)
BotaoAlternar.TextSize = 14
BotaoAlternar.Font = Enum.Font.GothamBold
BotaoAlternar.Visible = false
BotaoAlternar.Parent = ScreenGui
Instance.new("UICorner", BotaoAlternar).CornerRadius = UDim.new(0,8)

local visivel = true
BotaoAlternar.MouseButton1Click:Connect(function()
    visivel = not visivel
    BotaoAlternar.Text = visivel and "Esconder Controles" or "Mostrar Controles"
    for _,nome in next,{"Esquerdo_Painel","Esquerdo_Z_Painel","Direito_Painel","Direito_Z_Painel"} do
        local p = ScreenGui:FindFirstChild(nome)
        if p then p.Visible = visivel end
    end
end)

-- INTRO ÉPICA
local Intro = Instance.new("Frame")
Intro.Size = UDim2.new(1,0,1,0)
Intro.BackgroundColor3 = Color3.fromRGB(8,8,12)
Intro.Parent = ScreenGui
local TextoIntro = Instance.new("TextLabel")
TextoIntro.Size = UDim2.new(0, 420, 0, 110)
TextoIntro.Position = UDim2.new(0.5,-210,0.5,-55)
TextoIntro.BackgroundTransparency = 1
TextoIntro.Text = "SCRIPT BY IKER • VR MOBILE"
TextoIntro.TextColor3 = Color3.new(1,1,1)
TextoIntro.TextSize = 36
TextoIntro.Font = Enum.Font.FredokaOne
TextoIntro.TextTransparency = 1
TextoIntro.Parent = Intro
local Traco = Instance.new("UIStroke")
Traco.Color = Color3.fromRGB(0, 200, 255)
Traco.Thickness = 3.5
Traco.Transparency = 1
Traco.Parent = TextoIntro

task.spawn(function()
    task.wait(0.4)
    TweenService:Create(TextoIntro, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency=0}):Play()
    TweenService:Create(Traco, TweenInfo.new(1.2), {Transparency=0.1}):Play()
    task.wait(2)
    TweenService:Create(TextoIntro, TweenInfo.new(1), {TextTransparency=1}):Play()
    TweenService:Create(Traco, TweenInfo.new(1), {Transparency=1}):Play()
    TweenService:Create(Intro, TweenInfo.new(1), {BackgroundTransparency=1}):Play()
    Intro.Destroying:Wait()
    for _,nome in next,{"Esquerdo_Painel","Esquerdo_Z_Painel","Direito_Painel","Direito_Z_Painel"} do
        local p = ScreenGui:FindFirstChild(nome)
        if p then p.Visible = true end
    end
    BotaoAlternar.Visible = true
end)

-- SISTEMA PRINCIPAL + ANIMAÇÃO VR DE CAMINHADA
RunService.RenderStepped:Connect(function()
    -- Suavizar retorno dos controles
    if not leftLargeDragging then
        leftJoyMove = leftJoyMove:Lerp(Vector2.zero, LERP_SUAVE)
        local p = ScreenGui:FindFirstChild("Esquerdo_Painel")
        if p and p.Controle then p.Controle.Position = p.Controle.Position:Lerp(UDim2.new(0.5,-27.5,0.5,-27.5), LERP_SUAVE) end
    end
    if not rightLargeDragging then
        rightJoyMove = rightJoyMove:Lerp(Vector2.zero, LERP_SUAVE)
        local p = ScreenGui:FindFirstChild("Direito_Painel")
        if p and p.Controle then p.Controle.Position = p.Controle.Position:Lerp(UDim2.new(0.5,-27.5,0.5,-27.5), LERP_SUAVE) end
    end

    local personagem = plr.Character
    if not personagem or not personagem:FindFirstChild("HumanoidRootPart") then return end
    local raiz = personagem.HumanoidRootPart
    local hum = personagem:FindFirstChild("Humanoid")
    local anguloX, anguloY = cam.CFrame:ToEulerAnglesXYZ()
    anguloX = math.clamp(anguloX, -math.rad(80), math.rad(80))

    -- ✅ CABEÇA PERFEITAMENTE ALINHADA
    headCF = CFrame.new(raiz.Position + Vector3.new(0, 2.1, 0)) * CFrame.Angles(anguloX, anguloY, 0)

    -- ✅ ANIMAÇÃO VR AUTOMÁTICA: só funciona quando você anda
    local velocidadeAndar = leftJoyMove.Magnitude
    local tempo = os.clock() * (3 + velocidadeAndar * 4) -- Mais rápido = mais rápido o balanço
    local balancoEsq = math.sin(tempo) * 0.18 * velocidadeAndar
    local balancoDir = math.sin(tempo + math.pi) * 0.18 * velocidadeAndar
    local subirEsq = math.abs(math.sin(tempo)) * 0.12 * velocidadeAndar
    local subirDir = math.abs(math.sin(tempo + math.pi)) * 0.12 * velocidadeAndar

    -- ✅ BRAÇOS COM ANIMAÇÃO NATURAL DE CAMINHADA
    local profundidadeEsq = math.clamp(-1.1 - (leftZMove * 1.3), -2.3, -0.4)
    local profundidadeDir = math.clamp(-1.1 - (rightZMove * 1.3), -2.3, -0.4)

    -- Mão ESQUERDA
    leftHandCF = raiz.CFrame
        * CFrame.new(-1.1 + leftJoyMove.X * 1.5 + balancoEsq, 0.6 + leftJoyMove.Y * 1.3 + subirEsq, profundidadeEsq)
        * CFrame.Angles(anguloX + math.rad(leftJoyMove.Y * 35), anguloY + math.rad(-leftJoyMove.X * 25), math.rad(-leftJoyMove.X * 15))

    -- Mão DIREITA
    rightHandCF = raiz.CFrame
        * CFrame.new(1.1 + rightJoyMove.X * 1.5 + balancoDir, 0.6 + rightJoyMove.Y * 1.3 + subirDir, profundidadeDir)
        * CFrame.Angles(anguloX + math.rad(rightJoyMove.Y * 35), anguloY + math.rad(-rightJoyMove.X * 25), math.rad(rightJoyMove.X * 15))

    -- Enviar dados ao servidor
    local agora = os.clock()
    if agora - tAnterior >= TASA_ENVIO then
        remote:FireServer(headCF, leftHandCF, rightHandCF)
        tAnterior = agora
    end
end)

-- SINCRONIZAÇÃO FÍSICA + NOCLIP
RunService.Stepped:Connect(function()
    -- No-clip otimizado
    for _,jogador in next,Players:GetPlayers() do
        if jogador ~= plr and jogador.Character then
            for _,parte in next,jogador.Character:GetChildren() do
                if parte:IsA("BasePart") then parte.CanCollide = false end
            end
        end
    end

    -- ALINHAMENTO DAS ARTICULAÇÕES
    local p = plr.Character
    if not p then return end
    local pescoco = p:FindFirstChild("Neck", true)
    local ombroEsq = p:FindFirstChild("Left Shoulder", true) or p:FindFirstChild("LeftShoulder", true)
    local ombroDir = p:FindFirstChild("Right Shoulder", true) or p:FindFirstChild("RightShoulder", true)

    if pescoco and pescoco.Part0 then
        pescoco.Transform = pescoco.C0:Inverse() * pescoco.Part0.CFrame:Inverse() * headCF * pescoco.C1
    end
    if ombroEsq and ombroEsq.Part0 then
        ombroEsq.Transform = ombroEsq.C0:Inverse() * ombroEsq.Part0.CFrame:Inverse() * leftHandCF * ombroEsq.C1
    end
    if ombroDir and ombroDir.Part0 then
        ombroDir.Transform = ombroDir.C0:Inverse() * ombroDir.Part0.CFrame:Inverse() * rightHandCF * ombroDir.C1
    end

    -- Configurações para manter o estilo VR
    local hum = p:FindFirstChild("Humanoid")
    if hum then
        hum.AutoRotate = false
        hum.BreakJointsOnDeath = false
    end
end)

-- MANTER PERSONAGEM NO CHÃO
RunService.Heartbeat:Connect(function()
    local p = plr.Character
    if p and p:FindFirstChild("Humanoid") and not p.Humanoid.PlatformStand then
        p.Humanoid.PlatformStand = true
    end
end)
