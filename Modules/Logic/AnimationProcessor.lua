local AnimationProcessor = {}

-- Estado de animaciones
local currentAnimation = nil
local animationQueue = {}

-- Configuración de animación (se carga desde SavedVariables)
local fadeInTime = 0.3
local fadeOutTime = 0.7
local maxAlpha = 0.7
local animScale = 1.5
local iconSize = 75
local holdTime = 0
local showSpellName = true
local petOverlay = {1, 1, 1}

-- Variables de timing
local runtimer = 0

-- Callbacks para actualizar UI
AnimationProcessor.uiCallbacks = {}
AnimationProcessor.completionCallbacks = {}

-- Registrar callback para actualizaciones de UI
function AnimationProcessor:RegisterUICallback(callback)
    table.insert(self.uiCallbacks, callback)
end

-- Registrar callback para cuando se completa una animación
function AnimationProcessor:RegisterCompletionCallback(callback)
    table.insert(self.completionCallbacks, callback)
end

-- Actualizar configuración desde SavedVariables
function AnimationProcessor:RefreshConfig()
    if ReadyCooldownAlertDB then
        fadeInTime = ReadyCooldownAlertDB.fadeInTime or 0.3
        fadeOutTime = ReadyCooldownAlertDB.fadeOutTime or 0.7
        maxAlpha = ReadyCooldownAlertDB.maxAlpha or 0.7
        animScale = ReadyCooldownAlertDB.animScale or 1.5
        iconSize = ReadyCooldownAlertDB.iconSize or 75
        holdTime = ReadyCooldownAlertDB.holdTime or 0
        showSpellName = ReadyCooldownAlertDB.showSpellName ~= false
        petOverlay = ReadyCooldownAlertDB.petOverlay or {1, 1, 1}
    end
end

-- Añadir animación a la cola
function AnimationProcessor:QueueAnimation(texture, isPet, name, uniqueId)
    
    -- Validar textura usando TextureValidator
    local validTexture = texture
    if _G.TextureValidator then
        validTexture = _G.TextureValidator:GetValidTexture(texture, "AnimationProcessor_QueueAnimation")
    end
    
    local animation = {
        texture = validTexture,
        isPet = isPet,
        name = name,
        uniqueId = uniqueId,
        timestamp = GetTime()
    }
    
    table.insert(animationQueue, animation)
    
    -- Iniciar procesamiento si no hay animación actual
    if not currentAnimation then
        self:StartNextAnimation()
    end
end

-- Iniciar la siguiente animación en la cola
function AnimationProcessor:StartNextAnimation()
    
    if #animationQueue > 0 then
        currentAnimation = table.remove(animationQueue, 1)
        runtimer = 0
        
        -- Notificar a la UI que inicie la animación
        self:NotifyUIStart(currentAnimation)
        
        -- Iniciar OnUpdate
        self:StartOnUpdate()
    else
        currentAnimation = nil
        self:StopOnUpdate()
    end
end

-- Notificar a la UI que inicie una animación
function AnimationProcessor:NotifyUIStart(animation)
    for _, callback in ipairs(self.uiCallbacks) do
        callback("start", animation)
    end
end

-- Notificar a la UI de actualización de animación
function AnimationProcessor:NotifyUIUpdate(animationData)
    for _, callback in ipairs(self.uiCallbacks) do
        callback("update", animationData)
    end
end

-- Notificar a la UI que termine la animación
function AnimationProcessor:NotifyUIEnd()
    for _, callback in ipairs(self.uiCallbacks) do
        callback("end", nil)
    end
end

-- Iniciar motor OnUpdate
function AnimationProcessor:StartOnUpdate()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    if not self.frame:GetScript("OnUpdate") then
        self.frame:SetScript("OnUpdate", function(_, update)
            self:OnUpdate(update)
        end)
    end
end

-- Detener motor OnUpdate
function AnimationProcessor:StopOnUpdate()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
end

-- Motor de animación
function AnimationProcessor:OnUpdate(update)
    if not currentAnimation then
        self:StartNextAnimation()
        return
    end
    
    runtimer = runtimer + update
    
    -- Obtener configuración de animación seleccionada
    local selectedAnimationId = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    local totalTime = fadeInTime + holdTime + fadeOutTime
    
    -- Usar AnimationData si está disponible para calcular tiempos personalizados
    if AnimationData then
        local animationConfig = AnimationData:GetAnimationConfig(selectedAnimationId)
        if animationConfig then
            totalTime = animationConfig.fadeInTime + animationConfig.holdTime + animationConfig.fadeOutTime
        end
    end
    
    if runtimer > totalTime then
        -- Notificar finalización con uniqueId
        local completedUniqueId = currentAnimation.uniqueId
        self:NotifyUIEnd()
        
        -- Llamar callbacks de finalización
        if completedUniqueId then
            for _, callback in ipairs(self.completionCallbacks) do
                callback(completedUniqueId)
            end
        end
        
        currentAnimation = nil
        runtimer = 0
        
        -- Iniciar siguiente animación
        self:StartNextAnimation()
    else
        -- Calcular estado actual de la animación
        local animationData = self:CalculateAnimationState(runtimer, totalTime)
        if animationData then
            self:NotifyUIUpdate(animationData)
        end
    end
end

-- Calcular el estado actual de la animación
function AnimationProcessor:CalculateAnimationState(currentTime, totalTime)
    if not currentAnimation then
        return nil
    end
    
    local selectedAnimationId = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    
    -- Usar AnimationData si está disponible
    if AnimationData then
        local animationState = AnimationData:CalculateAnimationState(selectedAnimationId, currentTime, totalTime)
        if animationState then
            -- Calcular escala correctamente: tamaño base * escala de animación * escala del usuario
            -- animScale actúa como multiplicador directo: 1.0 = tamaño normal, 0.5 = mitad, 2.0 = doble
            -- animationState.scale es el factor relativo de la animación (ej: 0.8, 1.0, 1.5)
            local userScale = animScale or 1.0
            local animationScaleFactor = animationState.scale or 1.0
            local finalScale = iconSize * userScale * animationScaleFactor
            
            -- Aplicar maxAlpha a la animación - el alpha de la animación se multiplica por maxAlpha
            local finalAlpha = (animationState.alpha or 1.0) * maxAlpha
            
            -- Validar textura usando TextureValidator
            local validTexture = currentAnimation.texture
            if _G.TextureValidator then
                validTexture = _G.TextureValidator:GetValidTexture(currentAnimation.texture, "AnimationProcessor_CalculateState")
            end
            
            return {
                texture = validTexture,
                isPet = currentAnimation.isPet or false,
                name = showSpellName and currentAnimation.name or nil,
                alpha = finalAlpha,
                scale = finalScale,
                width = finalScale,
                height = finalScale,
                phase = animationState.phase,
                progress = currentTime / totalTime,
                petOverlay = currentAnimation.isPet and petOverlay or nil
            }
        end
    end
    
    -- Fallback al comportamiento original
    local alpha = maxAlpha
    local phase = "hold"
    
    if currentTime < fadeInTime then
        -- Fase: Fade In
        alpha = maxAlpha * (currentTime / fadeInTime)
        phase = "fadeIn"
    elseif currentTime >= fadeInTime + holdTime then
        -- Fase: Fade Out
        alpha = maxAlpha - (maxAlpha * ((currentTime - holdTime - fadeInTime) / fadeOutTime))
        phase = "fadeOut"
    end
    -- Fase Hold: alpha = maxAlpha (sin cambios)
    
    -- Calcular escala correctamente: tamaño base * escala del usuario
    -- animScale actúa como multiplicador directo: 1.0 = tamaño normal, 0.5 = mitad, 2.0 = doble
    local userScale = animScale or 1.0
    local finalScale = iconSize * userScale
    
    -- Validar textura usando TextureValidator
    local validTexture = currentAnimation.texture
    if _G.TextureValidator then
        validTexture = _G.TextureValidator:GetValidTexture(currentAnimation.texture, "AnimationProcessor_CalculateState_Fallback")
    end
    
    return {
        texture = validTexture,
        isPet = currentAnimation.isPet or false,
        name = showSpellName and currentAnimation.name or nil,
        alpha = alpha,
        scale = finalScale,
        width = finalScale,
        height = finalScale,
        phase = phase,
        progress = currentTime / totalTime,
        petOverlay = currentAnimation.isPet and petOverlay or nil
    }
end

-- Verificar si hay una animación activa para un nombre específico
function AnimationProcessor:IsAnimatingSpellName(name)
    if currentAnimation and currentAnimation.name == name then
        return true
    end
    
    for _, animation in ipairs(animationQueue) do
        if animation and animation.name == name then
            return true
        end
    end
    
    return false
end

-- Limpiar todas las animaciones
function AnimationProcessor:ClearAll()
    currentAnimation = nil
    animationQueue = {}
    runtimer = 0
    self:StopOnUpdate()
    self:NotifyUIEnd()
end

-- Obtener estado actual
function AnimationProcessor:GetStatus()
    return {
        hasCurrentAnimation = currentAnimation ~= nil,
        queueLength = #animationQueue,
        currentAnimationName = currentAnimation and currentAnimation.name or nil,
        isOnUpdateActive = self.frame and self.frame:GetScript("OnUpdate") ~= nil,
        currentTime = runtimer,
        totalTime = fadeInTime + holdTime + fadeOutTime
    }
end

-- Forzar animación de prueba
function AnimationProcessor:TestAnimation()
    -- Usar textura de Pyroblast como ejemplo
    local testTexture = 135808
    self:QueueAnimation(testTexture, false, "Test Animation")
end

-- Debug: Mostrar configuración actual
function AnimationProcessor:DebugConfig()
    print("=== AnimationProcessor Config ===")
    print("fadeInTime: " .. tostring(fadeInTime))
    print("fadeOutTime: " .. tostring(fadeOutTime)) 
    print("maxAlpha: " .. tostring(maxAlpha))
    print("animScale: " .. tostring(animScale))
    print("iconSize: " .. tostring(iconSize))
    print("holdTime: " .. tostring(holdTime))
    print("showSpellName: " .. tostring(showSpellName))
    print("================================")
end

-- Obtener configuración actual
function AnimationProcessor:GetConfig()
    return {
        fadeInTime = fadeInTime,
        fadeOutTime = fadeOutTime,
        maxAlpha = maxAlpha,
        animScale = animScale,
        iconSize = iconSize,
        holdTime = holdTime,
        showSpellName = showSpellName,
        petOverlay = petOverlay
    }
end

-- Exportar globalmente para WoW addon system
_G.AnimationProcessor = AnimationProcessor

return AnimationProcessor
