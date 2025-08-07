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
    if frame and not frame:IsShown() then
        frame:Show()
    end
    
    -- Configurar textura usando TextureValidator
    if texture then
        if _G.TextureValidator then
            _G.TextureValidator:SafeSetTexture(texture, animation.texture, "StartAnimation")
        else
            -- Fallback básico si TextureValidator no está disponible
            local validTexture = animation.texture or 135808
            texture:SetTexture(validTexture)
        end
    end
    
    -- Configurar texto del nombre
    if textFrame then
        if animation.name and ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName ~= false then
            textFrame:SetText(animation.name)
        else
            textFrame:SetText("")
        end
    end
    
    -- Aplicar color overlay para mascotas
    if texture then
        if animation.isPet and ReadyCooldownAlertDB and ReadyCooldownAlertDB.petOverlay then
            texture:SetVertexColor(unpack(ReadyCooldownAlertDB.petOverlay))
        else
            texture:SetVertexColor(1, 1, 1)
        end
    end
end

-- Actualizar animación en curso
function MainFrame:UpdateAnimation(animationData)
    if not animationData or not frame then return end
    
    -- Actualizar alpha con validación
    if animationData.alpha and frame then
        -- Asegurar que alpha esté entre 0 y 1
        local validAlpha = math.max(0, math.min(1, animationData.alpha))
        frame:SetAlpha(validAlpha)
    end
    
    -- Actualizar escala
    if animationData.width and animationData.height and frame then
        frame:SetSize(animationData.width, animationData.height)
    end
    
    -- Aplicar color overlay si es mascota
    if animationData.petOverlay and texture then
        texture:SetVertexColor(unpack(animationData.petOverlay))
    end
end

-- Terminar animación
function MainFrame:EndAnimation()
    if not frame then return end
    
    -- Limpiar contenido usando TextureValidator
    if texture then
        if _G.TextureValidator then
            _G.TextureValidator:SafeSetTexture(texture, nil, "EndAnimation", "")
        else
            texture:SetTexture("")
        end
    end
    
    if textFrame then
        textFrame:SetText("")
    end
    
    if texture then
        texture:SetVertexColor(1, 1, 1)
    end
    
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
    if frame then
        frame:Show()
        frame:SetAlpha(0.7)
    end
    
    -- Configurar textura de ejemplo usando TextureValidator
    if _G.TextureValidator and texture then
        _G.TextureValidator:SafeSetTexture(texture, 135808, "ShowForPositioning")
    elseif texture then
        texture:SetTexture(135808) -- Textura de ejemplo (Pyroblast)
    end
    
    if textFrame then
        textFrame:SetText("Position Preview")
    end
    
    -- Actualizar posición desde sliders
    self:UpdatePosition()
end

-- Ocultar frame del posicionamiento
function MainFrame:HideFromPositioning()
    if not frame then return end
    
    -- Limpiar contenido usando TextureValidator
    if _G.TextureValidator and texture then
        _G.TextureValidator:SafeSetTexture(texture, nil, "HideFromPositioning", "")
    elseif texture then
        texture:SetTexture("")
    end
    
    if textFrame then
        textFrame:SetText("")
    end
    
    if texture then
        texture:SetVertexColor(1, 1, 1)
    end
    
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
    
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    -- Actualizar configuración
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB.positionX = (GetScreenWidth() or 1920) / 2
        ReadyCooldownAlertDB.positionY = (GetScreenHeight() or 1080) / 2
    end
end

-- Exportar globalmente para WoW addon system
_G.MainFrame = MainFrame

return MainFrame
