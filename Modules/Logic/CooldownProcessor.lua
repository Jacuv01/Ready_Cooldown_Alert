local CooldownProcessor = {}

-- Tablas de estado
local watching = {}      -- Buffer temporal de acciones (0.5s)
local cooldowns = {}     -- Cooldowns activos >2s
local animating = {}     -- Cola de animaciones pendientes
local lastAlertTime = {} -- Tracker de cuándo se mostró la última alerta por hechizo

-- Configuración
local WATCH_DURATION = 0.5      -- Tiempo en watching antes de procesar
local MIN_COOLDOWN_DURATION = 2.0  -- Mínimo cooldown para trackear
local ALERT_COOLDOWN = 2.0      -- Mínimo tiempo entre alertas del mismo hechizo (en segundos)

-- OnUpdate variables
local elapsed = 0
local runtimer = 0

-- Callbacks para animaciones
CooldownProcessor.animationCallbacks = {}

-- Registrar callback para cuando se deba animar un cooldown
function CooldownProcessor:RegisterAnimationCallback(callback)
    table.insert(self.animationCallbacks, callback)
end

-- Ejecutar callbacks de animación
function CooldownProcessor:TriggerAnimation(cooldownDetails)
    for _, callback in ipairs(self.animationCallbacks) do
        callback(cooldownDetails.texture, cooldownDetails.isPet, cooldownDetails.name, cooldownDetails.uniqueId)
    end
end

-- Callback para cuando una animación termina (llamado por AnimationProcessor)
function CooldownProcessor:OnAnimationComplete(uniqueId)
    -- Buscar y eliminar la animación de la tabla animating
    for i = #animating, 1, -1 do
        if animating[i].uniqueId == uniqueId then
            table.remove(animating, i)
            break
        end
    end
end

-- Añadir acción al buffer de watching
function CooldownProcessor:AddToWatching(actionType, id, texture, extraData)
    
    watching[id] = {
        timestamp = GetTime(),
        actionType = actionType,
        texture = texture,
        extraData = extraData
    }
    
    -- Activar OnUpdate si no está activo
    self:StartOnUpdate()
end

-- Verificar si ya hay una animación para este ID específico de hechizo
function CooldownProcessor:IsAnimatingCooldownById(id)
    for _, animation in ipairs(animating) do
        if animation.uniqueId == id then
            return true
        end
    end
    return false
end

-- Iniciar el motor OnUpdate
function CooldownProcessor:StartOnUpdate()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    if not self.frame:GetScript("OnUpdate") then
        self.frame:SetScript("OnUpdate", function(_, update)
            self:OnUpdate(update)
        end)
    end
end

-- Detener el motor OnUpdate
function CooldownProcessor:StopOnUpdate()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
end

-- Motor principal de procesamiento
function CooldownProcessor:OnUpdate(update)
    elapsed = elapsed + update
    if elapsed > 0.05 then  -- Ejecutar cada 50ms
        
        -- FASE 1: Procesar tabla "watching"
        for id, watchData in pairs(watching) do
            if GetTime() >= watchData.timestamp + WATCH_DURATION then
                self:ProcessWatchedAction(id, watchData)
                watching[id] = nil
            end
        end
        
        -- FASE 2: Procesar tabla "cooldowns" - Recopilar candidatos para animación
        local alertCandidates = {}
        
        for id, getCooldownDetails in pairs(cooldowns) do
            local cooldownDetails = getCooldownDetails()
            if cooldownDetails and cooldownDetails.start and cooldownDetails.duration then
                -- Validar que los valores sean razonables
                local currentTime = GetTime()
                local start = cooldownDetails.start
                local duration = cooldownDetails.duration
                
                -- Verificar que start no sea 0 y duration sea > 0
                if start > 0 and duration > 0 then
                    local remaining = duration - (currentTime - start)
                    
                    -- Si está listo para alertar
                    local remainingThreshold = ReadyCooldownAlertDB and ReadyCooldownAlertDB.remainingCooldownWhenNotified or 0
                    if remaining <= remainingThreshold and remaining >= -1 then -- Permitir pequeña tolerancia negativa
                        local alertId = cooldownDetails.name .. "_" .. id
                        local currentTime = GetTime()
                        
                        -- Solo considerar para alerta si han pasado al menos ALERT_COOLDOWN segundos desde la última
                        if not lastAlertTime[alertId] or (currentTime - lastAlertTime[alertId]) >= ALERT_COOLDOWN then
                            if not self:IsAnimatingCooldownById(id) then
                                -- Agregar a candidatos con prioridad basada en tiempo restante
                                table.insert(alertCandidates, {
                                    id = id,
                                    alertId = alertId,
                                    cooldownDetails = cooldownDetails,
                                    remaining = remaining,
                                    currentTime = currentTime
                                })
                            end
                        end
                    elseif remaining < -1 then
                        cooldowns[id] = nil
                        local alertId = cooldownDetails.name .. "_" .. id
                        lastAlertTime[alertId] = nil
                    end
                else
                    -- start = 0 o duration = 0, cooldown no activo
                    cooldowns[id] = nil
                end
            else
                cooldowns[id] = nil -- Cooldown inválido
            end
        end
        
        -- FASE 2.5: Priorizar y mostrar alertas por tiempo restante (menor tiempo = mayor prioridad)
        if #alertCandidates > 0 then
            -- Ordenar por tiempo restante ascendente (el que menos tiempo le queda primero)
            table.sort(alertCandidates, function(a, b)
                return a.remaining < b.remaining
            end)
            
            -- Determinar cuántas alertas mostrar (máximo 3 simultáneas para no saturar)
            local maxSimultaneousAlerts = 3
            local alertsToShow = math.min(#alertCandidates, maxSimultaneousAlerts)
            
            -- Mostrar las alertas más urgentes
            for i = 1, alertsToShow do
                local candidate = alertCandidates[i]
                
                -- Añadir uniqueId para tracking individual
                local animationData = candidate.cooldownDetails
                animationData.uniqueId = candidate.id
                
                table.insert(animating, animationData)
                self:TriggerAnimation(animationData)
                lastAlertTime[candidate.alertId] = candidate.currentTime
                
                -- IMPORTANTE: Eliminar el cooldown de tracking después de mostrar la alerta
                -- Esto evita múltiples alertas para el mismo cooldown
                cooldowns[candidate.id] = nil
            end
        end
        
        elapsed = 0
        
        -- Detener OnUpdate si no hay nada que procesar
        local watchCount = 0
        for _ in pairs(watching) do watchCount = watchCount + 1 end
        local cooldownCount = 0
        for _ in pairs(cooldowns) do cooldownCount = cooldownCount + 1 end
        
        if #animating == 0 and watchCount == 0 and cooldownCount == 0 then
            self:StopOnUpdate()
            return
        end
    end
end

-- Procesar una acción del buffer watching
function CooldownProcessor:ProcessWatchedAction(id, watchData)

    
    -- Obtener detalles del cooldown usando CooldownData
    if CooldownData then
        local cooldownDetails = CooldownData:GetCooldownDetails(id, watchData.actionType, watchData.extraData)
        
        if cooldownDetails then

            
            -- Aplicar filtros
            if FilterProcessor and FilterProcessor:ShouldFilter(cooldownDetails.name, id) then
                return -- Filtrado, no procesar
            end
            
            -- Solo trackear cooldowns largos
            if CooldownData:IsValidForTracking(cooldownDetails, MIN_COOLDOWN_DURATION) then

                
                -- Crear función memoizada para obtener detalles
                local function memoizedGetCooldownDetails()
                    return CooldownData:GetCooldownDetails(id, watchData.actionType, watchData.extraData)
                end
                
                cooldowns[id] = memoizedGetCooldownDetails
            end
        end
    end
end

-- Limpiar todas las tablas (para eventos como entrar en arena)
function CooldownProcessor:ClearAll()
    watching = {}
    cooldowns = {}
    animating = {}
    lastAlertTime = {}
    self:StopOnUpdate()
end

-- Limpiar solo cooldowns y watching (cambio de especialización)
function CooldownProcessor:ClearCooldowns()
    watching = {}
    cooldowns = {}
    lastAlertTime = {}
    -- Mantener animating para que terminen las animaciones actuales
end

-- Obtener estado actual para debugging
function CooldownProcessor:GetStatus()
    local watchCount = 0
    for _ in pairs(watching) do watchCount = watchCount + 1 end
    local cooldownCount = 0
    for _ in pairs(cooldowns) do cooldownCount = cooldownCount + 1 end
    local alertCount = 0
    for _ in pairs(lastAlertTime) do alertCount = alertCount + 1 end
    
    return {
        watching = watchCount,
        cooldowns = cooldownCount,
        animating = #animating,
        alertsTracked = alertCount,
        isOnUpdateActive = self.frame and self.frame:GetScript("OnUpdate") ~= nil
    }
end

-- Exportar globalmente para WoW addon system
_G.CooldownProcessor = CooldownProcessor

return CooldownProcessor
