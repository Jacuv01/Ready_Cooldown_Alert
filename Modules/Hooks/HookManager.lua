local HookManager = {}

HookManager.callbacks = {}

function HookManager:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function HookManager:OnActionDetected(actionType, id, texture, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback(actionType, id, texture, extraData)
    end
end

function HookManager:Initialize()
    if ActionHooks then
        ActionHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        ActionHooks:Initialize()
    end

    if rawget(_G, "SpellHooks") then
        SpellHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        SpellHooks:Initialize()
    end
    
    if CombatHooks then
        CombatHooks:RegisterCallback(function(actionType, id, texture, extraData)
            self:OnActionDetected(actionType, id, texture, extraData)
        end)
        CombatHooks:Initialize()
    end
end

_G.HookManager = HookManager

return HookManager
