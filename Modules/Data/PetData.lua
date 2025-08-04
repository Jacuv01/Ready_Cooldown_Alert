local PetData = {}

-- Obtener información de acción de mascota por índice
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

-- Obtener cooldown de acción de mascota
function PetData:GetPetActionCooldown(index)
    local start, duration, enabled = GetPetActionCooldown(index)
    return {
        start = start,
        duration = duration,
        enabled = enabled
    }
end

-- Buscar índice de acción por nombre (del código original)
function PetData:GetPetActionIndexByName(name)
    for i = 1, NUM_PET_ACTION_SLOTS do
        local actionName = GetPetActionInfo(i)
        if actionName == name then
            return i
        end
    end
    return nil
end

-- Verificar si tiene mascota activa
function PetData:HasActivePet()
    return UnitExists("pet") and not UnitIsDead("pet")
end

-- Obtener todas las acciones disponibles de la mascota
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

-- Exportar globalmente para WoW addon system
_G.PetData = PetData

return PetData