local LogicManager = {}

function LogicManager:Initialize()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    local FilterProcessor = rawget(_G, "FilterProcessor")
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    local OptionsLogic = rawget(_G, "OptionsLogic")

    if OptionsLogic then
        OptionsLogic:InitializeDefaultConfig()
    end
    
    if FilterProcessor then
        FilterProcessor:Initialize()
    end
    
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
    end
    
    if CooldownProcessor and AnimationProcessor then
        CooldownProcessor:RegisterAnimationCallback(function(texture, isPet, name, uniqueId)
            AnimationProcessor:QueueAnimation(texture, isPet, name, uniqueId)
        end)
    end
    
    if AnimationProcessor and rawget(_G, "MainFrame") then
        AnimationProcessor:RegisterUICallback(function(eventType, animationData)
            rawget(_G, "MainFrame"):OnAnimationEvent(eventType, animationData)
        end)
    end
    
    if AnimationProcessor and CooldownProcessor then
        AnimationProcessor:RegisterCompletionCallback(function(uniqueId)
            CooldownProcessor:OnAnimationComplete(uniqueId)
        end)
    end
end

function LogicManager:ProcessAction(actionType, id, texture, extraData)
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    if CooldownProcessor then
        CooldownProcessor:AddToWatching(actionType, id, texture, extraData)
    end
end

function LogicManager:OnPlayerEnteringWorld()
    local inArena = C_PvP.IsArena()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    if inArena and CooldownProcessor then
        CooldownProcessor:ClearAll()
    end
end

function LogicManager:OnPlayerSpecializationChanged()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    if CooldownProcessor then
        CooldownProcessor:ClearCooldowns()
    end
end

function LogicManager:OnSpellUpdateCooldown()
end

function LogicManager:GetStatus()
    local CooldownProcessor = rawget(_G, "CooldownProcessor")
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    local FilterProcessor = rawget(_G, "FilterProcessor")
    return {
        cooldownProcessor = CooldownProcessor and CooldownProcessor:GetStatus() or nil,
        animationProcessor = AnimationProcessor and AnimationProcessor:GetStatus() or nil,
        filterProcessor = FilterProcessor and FilterProcessor:GetFilterStats() or nil
    }
end

_G.LogicManager = LogicManager

return LogicManager
