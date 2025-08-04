local MainFrame = {}

-- Frame principal para las animaciones
local frame = nil
local texture = nil
local textFrame = nil

-- Inicializar el frame principal
function MainFrame:Initialize()
    if frame then
        return -- Ya inicializado
    end
    
    -- Crear frame principal
    frame = CreateFrame("Frame", "ReadyCooldownAlertMainFrame", UIParent)
    frame:SetSize(75, 75) -- Tamaño por defecto
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    
    -- El frame ya no es movible por drag and drop
    frame:SetMovable(false)
    frame:EnableMouse(false)
    
    -- Crear textura para el icono
    texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetTexture(nil) -- Inicialmente sin textura
    
    -- Crear texto para el nombre del hechizo
    textFrame = frame:CreateFontString(nil, "ARTWORK")
    textFrame:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    textFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, -20)
    textFrame:SetText("")
    
    -- Cargar posición guardada
    self:LoadPosition()
    
    -- Inicialmente oculto
    frame:SetAlpha(0)
    frame:Hide()
end

-- Cargar posición guardada
function MainFrame:LoadPosition()
    if not frame or not ReadyCooldownAlertDB then
        return
    end
    
    -- Usar coordenadas de los sliders si están disponibles
    local x = ReadyCooldownAlertDB.positionX
    local y = ReadyCooldownAlertDB.positionY
    
    -- Si no hay posición configurada, usar centro de pantalla
    if not x then
        x = (GetScreenWidth() or 1920) / 2
        ReadyCooldownAlertDB.positionX = x
    end
    if not y then
        y = (GetScreenHeight() or 1080) / 2
        ReadyCooldownAlertDB.positionY = y
    end
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

-- Actualizar posición desde sliders (llamado cuando cambian los sliders)
function MainFrame:UpdatePosition()
    self:LoadPosition()
end

-- Manejar eventos de animación del AnimationProcessor
function MainFrame:OnAnimationEvent(eventType, animationData)
    if not frame then
        self:Initialize()
    end
    
    if eventType == "start" then
        self:StartAnimation(animationData)
    elseif eventType == "update" then
        self:UpdateAnimation(animationData)
    elseif eventType == "end" then
        self:EndAnimation()
    end
end

-- Iniciar una animación
function MainFrame:StartAnimation(animation)
    if not animation then return end
    
    -- Asegurar que el frame esté disponible para animaciones normales
    if not frame:IsShown() then
        frame:Show()
    end
    
    -- Configurar textura
    if animation.texture then
        texture:SetTexture(animation.texture)
    end
    
    -- Configurar texto del nombre
    if animation.name and ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName ~= false then
        textFrame:SetText(animation.name)
    else
        textFrame:SetText("")
    end
    
    -- Aplicar color overlay para mascotas
    if animation.isPet and ReadyCooldownAlertDB and ReadyCooldownAlertDB.petOverlay then
        texture:SetVertexColor(unpack(ReadyCooldownAlertDB.petOverlay))
    else
        texture:SetVertexColor(1, 1, 1)
    end
end

-- Actualizar animación en curso
function MainFrame:UpdateAnimation(animationData)
    if not animationData or not frame then return end
    
    -- Actualizar alpha
    if animationData.alpha then
        frame:SetAlpha(animationData.alpha)
    end
    
    -- Actualizar escala
    if animationData.width and animationData.height then
        frame:SetSize(animationData.width, animationData.height)
    end
    
    -- Aplicar color overlay si es mascota
    if animationData.petOverlay then
        texture:SetVertexColor(unpack(animationData.petOverlay))
    end
end

-- Terminar animación
function MainFrame:EndAnimation()
    if not frame then return end
    
    -- Limpiar contenido
    texture:SetTexture(nil)
    textFrame:SetText("")
    texture:SetVertexColor(1, 1, 1)
    
    -- Ocultar frame
    frame:SetAlpha(0)
    frame:Hide()
end

-- Mostrar frame para posicionamiento
function MainFrame:ShowForPositioning()
    if not frame then
        self:Initialize()
    end
    
    -- Mostrar frame con textura de ejemplo
    frame:Show()
    frame:SetAlpha(0.7)
    texture:SetTexture(135808) -- Textura de ejemplo (Pyroblast)
    textFrame:SetText("Position Preview")
    
    -- Actualizar posición desde sliders
    self:UpdatePosition()
end

-- Ocultar frame del posicionamiento
function MainFrame:HideFromPositioning()
    if not frame then return end
    
    -- Limpiar contenido
    texture:SetTexture(nil)
    textFrame:SetText("")
    texture:SetVertexColor(1, 1, 1)
    
    -- Ocultar frame completamente
    frame:Hide()
    -- Nota: No modificamos el alpha aquí para no interferir con futuras animaciones
end

-- Mostrar animación de prueba
function MainFrame:TestAnimation()
    -- Simular datos de animación de prueba
    local testAnimation = {
        texture = 135808, -- Pyroblast
        isPet = false,
        name = "Test Spell"
    }
    
    self:StartAnimation(testAnimation)
    
    -- Simular actualización con valores de prueba
    local testUpdate = {
        alpha = ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha or 0.7,
        width = ReadyCooldownAlertDB and ReadyCooldownAlertDB.iconSize or 100,
        height = ReadyCooldownAlertDB and ReadyCooldownAlertDB.iconSize or 100,
        phase = "hold",
        progress = 0.5
    }
    
    self:UpdateAnimation(testUpdate)
    
    -- Terminar después de 2 segundos
    C_Timer.After(2, function()
        self:EndAnimation()
    end)
end

-- Obtener información del frame
function MainFrame:GetFrameInfo()
    if not frame then
        return nil
    end
    
    return {
        isShown = frame:IsShown(),
        alpha = frame:GetAlpha(),
        width = frame:GetWidth(),
        height = frame:GetHeight(),
        position = {
            x = frame:GetLeft() and (frame:GetLeft() + frame:GetWidth() / 2) or 0,
            y = frame:GetBottom() and (frame:GetBottom() + frame:GetHeight() / 2) or 0
        }
    }
end

-- Resetear posición al centro
function MainFrame:ResetPosition()
    if not frame then
        self:Initialize()
    end
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Actualizar configuración
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB.positionX = (GetScreenWidth() or 1920) / 2
        ReadyCooldownAlertDB.positionY = (GetScreenHeight() or 1080) / 2
    end
end

-- Exportar globalmente para WoW addon system
_G.MainFrame = MainFrame

return MainFrame
