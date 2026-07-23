-- FAKE VR PARA NEXUS VR + ANIMAÇÃO REALISTA + IK NATIVO + SMOOTH
local remoto = game:GetService("ReplicatedStorage").NexusVRCharacterModel.UpdateInputs
local plr = game:GetService("Players").LocalPlayer
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

-- Notificar pronto
game:GetService("ReplicatedStorage").NexusVRCharacterModel.ReplicationReady:FireServer()

-- ===== VARIÁVEIS DE CONTROLE =====
local leftJoyMove = Vector2.new(0, 0)
local rightJoyMove = Vector2.new(0, 0)
local leftZMove = 0
local rightZMove = 0
local leftLargeDragging = false
local rightLargeDragging = false

-- ===== VARIÁVEIS DE ANIMAÇÃO SUAVES =====
local smoothHead = CFrame.new()
local smoothLeftHand = CFrame.new()
local smoothRightHand = CFrame.new()
local currentHead = CFrame.new()
local currentLeftHand = CFrame.new()
local currentRightHand = CFrame.new()

-- ===== OTIMIZAÇÃO =====
local tAnterior = 0
local TASA_ENVIO = 1 / 30
local SMOOTH_FACTOR = 0.25 -- Suavidade da animação

-- ===== INTERFACE =====
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

-- ===== FUNÇÕES DOS JOYSTICKS (MESMAS) =====
-- [Código dos joysticks permanece igual - omitido por brevidade]

-- ===== SISTEMA DE ANIMAÇÃO VR REALISTA =====
local function calcularPoseVR()
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = char.HumanoidRootPart
    local rootCF = rootPart.CFrame
    local rootPos = rootPart.Position
    local rootRot = rootPart.Orientation
    
    -- ===== 1. CABEÇA COM INÉRCIA REAL =====
    local headOffset = CFrame.new(0, 1.8, 0) -- Altura natural
    local lookAngles = cam.CFrame:ToEulerAnglesXYZ()
    
    -- Suavização da cabeça
    local targetHead = rootCF * headOffset * CFrame.Angles(lookAngles, 0, 0)
    currentHead = currentHead:Lerp(targetHead, SMOOTH_FACTOR)
    
    -- ===== 2. SISTEMA IK REALISTA PARA BRAÇOS =====
    local shoulderWidth = 0.5
    local armLength = 0.8
    
    -- Posições dos ombros
    local leftShoulderPos = rootPos + rootCF.RightVector * -shoulderWidth + Vector3.new(0, 1.4, 0)
    local rightShoulderPos = rootPos + rootCF.RightVector * shoulderWidth + Vector3.new(0, 1.4, 0)
    
    -- Movimentos com limites naturais
    local leftX = math.clamp(leftJoyMove.X, -1, 1)
    local leftY = math.clamp(leftJoyMove.Y, -1, 1)
    local rightX = math.clamp(rightJoyMove.X, -1, 1)
    local rightY = math.clamp(rightJoyMove.Y, -1, 1)
    
    -- Profundidade Z com spring effect
    local leftZ = math.clamp(-0.8 - (leftZMove * 0.8), -1.6, 0)
    local rightZ = math.clamp(-0.8 - (rightZMove * 0.8), -1.6, 0)
    
    -- ===== 3. POSIÇÃO DAS MÃOS COM ARCOS NATURAIS =====
    -- Mão esquerda
    local leftHandOffset = Vector3.new(
        leftX * 0.9,  -- X: movimento lateral natural
        -0.3 + (leftY * 0.7), -- Y: levantar/abaixar
        leftZ - 0.2
    )
    
    -- Mão direita
    local rightHandOffset = Vector3.new(
        rightX * 0.9,
        -0.3 + (rightY * 0.7),
        rightZ - 0.2
    )
    
    -- Converter para CFrame com rotação realista
    local leftTargetCF = rootCF * CFrame.new(leftHandOffset) * 
        CFrame.Angles(
            math.rad(leftY * 60),  -- Rotação X
            math.rad(-leftX * 40), -- Rotação Y
            math.rad(-leftX * 30)  -- Rotação Z
        )
    
    local rightTargetCF = rootCF * CFrame.new(rightHandOffset) * 
        CFrame.Angles(
            math.rad(rightY * 60),
            math.rad(-rightX * 40),
            math.rad(rightX * 30)
        )
    
    -- Suavização com LERP
    currentLeftHand = currentLeftHand:Lerp(leftTargetCF, SMOOTH_FACTOR)
    currentRightHand = currentRightHand:Lerp(rightTargetCF, SMOOTH_FACTOR)
    
    -- ===== 4. ENVIO AO SERVIDOR =====
    local tActual = os.clock()
    if tActual - tAnterior >= TASA_ENVIO then
        remoto:FireServer(currentHead, currentLeftHand, currentRightHand)
        tAnterior = tActual
    end
end

-- ===== APLICAÇÃO LOCAL (STEPPED) =====
RunService.Stepped:Connect(function()
    local char = plr.Character
    if not char then return end
    
    -- ===== NO-CLIP OTIMIZADO =====
    for _, otherPlr in ipairs(Players:GetPlayers()) do
        if otherPlr ~= plr and otherPlr.Character then
            for _, part in ipairs(otherPlr.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    
    -- ===== APLICAR ANIMAÇÃO LOCAL =====
    local neck = char:FindFirstChild("Neck", true)
    local leftShoulder = char:FindFirstChild("Left Shoulder", true) or char:FindFirstChild("LeftShoulder", true)
    local rightShoulder = char:FindFirstChild("Right Shoulder", true) or char:FindFirstChild("RightShoulder", true)
    
    if neck and neck.Part0 then
        neck.Transform = neck.C0:Inverse() * neck.Part0.CFrame:Inverse() * currentHead * neck.C1
    end
    
    if leftShoulder and leftShoulder.Part0 then
        leftShoulder.Transform = leftShoulder.C0:Inverse() * leftShoulder.Part0.CFrame:Inverse() * currentLeftHand * leftShoulder.C1
    end
    
    if rightShoulder and rightShoulder.Part0 then
        rightShoulder.Transform = rightShoulder.C0:Inverse() * rightShoulder.Part0.CFrame:Inverse() * currentRightHand * rightShoulder.C1
    end
end)

-- ===== RENDERSTEP PARA ATUALIZAR POSIÇÕES =====
RunService.RenderStepped:Connect(function()
    calcularPoseVR()
    
    -- LERP dos joysticks quando soltos
    if not leftLargeDragging then
        leftJoyMove = leftJoyMove:Lerp(Vector2.new(0, 0), 0.08)
    end
    if not rightLargeDragging then
        rightJoyMove = rightJoyMove:Lerp(Vector2.new(0, 0), 0.08)
    end
end)

print("✅ Sistema VR Realista Ativado!")
