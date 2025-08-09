local LogicManager = {}

-- Inicializar todos los módulos de lógica
function LogicManager:Initialize()
    -- Obtener referencias a los módulos globales
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    local FilterProcessor = rawget(_G, "FilterProcessor")
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    local OptionsLogic = rawget(_G, "OptionsLogic")

    -- Inicializar OptionsLogic
    if OptionsLogic then
        OptionsLogic:InitializeDefaultConfig()
    end
    
    -- Inicializar FilterProcessor
    if FilterProcessor then
        FilterProcessor:Initialize()
    end
    
    -- Inicializar AnimationProcessor
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
    end
    
    -- Conectar CooldownProcessor con AnimationProcessor
    if CooldownProcessor and AnimationProcessor then

        CooldownProcessor:RegisterAnimationCallback(function(texture, isPet, name, uniqueId)

            AnimationProcessor:QueueAnimation(texture, isPet, name, uniqueId)
        end)
    end
    
    -- Conectar AnimationProcessor con MainFrame
    if AnimationProcessor and rawget(_G, "MainFrame") then

        AnimationProcessor:RegisterUICallback(function(eventType, animationData)

            rawget(_G, "MainFrame"):OnAnimationEvent(eventType, animationData)
        end)
    end
    
    -- Conectar AnimationProcessor con CooldownProcessor para callback de finalización
    if AnimationProcessor and CooldownProcessor then

        AnimationProcessor:RegisterCompletionCallback(function(uniqueId)

            CooldownProcessor:OnAnimationComplete(uniqueId)
        end)
    end
end

-- Procesar acción detectada por los hooks
function LogicManager:ProcessAction(actionType, id, texture, extraData)

    
    -- Obtener referencia fresca al CooldownProcessor
    local CooldownProcessor = rawget(_G, "CooldownProcessor")

    if CooldownProcessor then

        CooldownProcessor:AddToWatching(actionType, id, texture, extraData)
    end
end

-- Manejar eventos especiales del juego
function LogicManager:OnPlayerEnteringWorld()
    -- Verificar si está en arena y limpiar todo
    local inArena = C_PvP.IsArena()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    if inArena and CooldownProcessor then
        CooldownProcessor:ClearAll()
    end
end

function LogicManager:OnPlayerSpecializationChanged()
    -- Limpiar cooldowns al cambiar especialización
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    if CooldownProcessor then
        CooldownProcessor:ClearCooldowns()
    end
end

function LogicManager:OnSpellUpdateCooldown()
    -- Resetear cualquier caché de cooldowns si existe
    -- Por ahora no hay caché específico que resetear
end

-- Obtener estado de todos los módulos
function LogicManager:GetStatus()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    local FilterProcessor = rawget(_G, "FilterProcessor")
    local status = {
        cooldownProcessor = CooldownProcessor and CooldownProcessor:GetStatus() or nil,
        animationProcessor = AnimationProcessor and AnimationProcessor:GetStatus() or nil,
        filterProcessor = FilterProcessor and FilterProcessor:GetFilterStats() or nil
    }
    
    return status
end

-- Exportar globalmente para WoW addon system
_G.LogicManager = LogicManager

return LogicManager
