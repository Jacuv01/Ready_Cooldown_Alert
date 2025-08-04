local HookManager = {}

-- Callbacks centralizados
HookManager.callbacks = {}

-- Registrar callback que recibirá todas las acciones
function HookManager:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

-- Distribuir evento a todos los callbacks
function HookManager:OnActionDetected(actionType, id, texture, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback(actionType, id, texture, extraData)
    end
end

-- Inicializar todos los sistemas de hooks
function HookManager:Initialize()
    -- Note: En WoW addons, usamos dofile o LoadAddOn en lugar de require
    -- Por ahora, asumimos que los hooks se cargan en el orden correcto desde el TOC
    
    -- Si ActionHooks está disponible
    if ActionHooks then
        ActionHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        ActionHooks:Initialize()
    end
    
    -- Si SpellHooks está disponible
    if SpellHooks then
        SpellHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        SpellHooks:Initialize()
    end
    
    -- Si CombatHooks está disponible
    if CombatHooks then
        CombatHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        CombatHooks:Initialize()
    end
end

-- Exportar globalmente para WoW addon system
_G.HookManager = HookManager

return HookManager
