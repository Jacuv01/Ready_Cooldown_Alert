local PetData = {}

function PetData:GetPetActionInfo(index)
    local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(index)
    return {
        name = name,
        texture = texture,
        isToken = isToken,
        isActive = isActive,
        autoCastAllowed = autoCastAllowed,
        autoCastEnabled = autoCastEnabled,
        index = index
    }
end

function PetData:GetPetActionCooldown(index)
    local start, duration, enabled = GetPetActionCooldown(index)
    return {
        start = start,
        duration = duration,
        enabled = enabled
    }
end

function PetData:GetPetActionIndexByName(name)
    for i = 1, NUM_PET_ACTION_SLOTS do
        local actionName = GetPetActionInfo(i)
        if actionName == name then
            return i
        end
    end
    return nil
end

function PetData:HasActivePet()
    return UnitExists("pet") and not UnitIsDead("pet")
end

function PetData:GetAllPetActions()
    local actions = {}
    if not self:HasActivePet() then
        return actions
    end
    
    for i = 1, NUM_PET_ACTION_SLOTS do
        local info = self:GetPetActionInfo(i)
        if info.name then
            actions[i] = info
        end
    end
    return actions
end

_G.PetData = PetData

return PetData