local CooldownData = {}

function CooldownData:GetCooldownDetails(id, actionType, extraData)
    if actionType == "spell" then
        return self:GetSpellCooldownDetails(id)
    elseif actionType == "item" then
        return self:GetItemCooldownDetails(id, extraData)
    elseif actionType == "pet" then
        return self:GetPetCooldownDetails(id, extraData)
    end
    return nil
end

function CooldownData:GetSpellCooldownDetails(spellID)
    local SpellData = rawget(_G, "SpellData")
    local spellInfo = SpellData and SpellData:GetSpellInfo(spellID) or {
        name = C_Spell.GetSpellName(spellID),
        texture = C_Spell.GetSpellTexture(spellID)
    }

    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    local start = cooldownInfo.startTime
    local duration = cooldownInfo.duration
    local enabled = cooldownInfo.isEnabled

    return {
        name = spellInfo.name,
        texture = spellInfo.texture,
        start = start,
        duration = duration,
        enabled = enabled,
        type = "spell",
        id = spellID
    }
end

function CooldownData:GetItemCooldownDetails(itemID, extraData)
    local ItemData = rawget(_G, "ItemData")
    local itemInfo = ItemData and ItemData:GetItemInfo(itemID) or {
        name = C_Item.GetItemInfo(itemID),
        texture = C_Item.GetItemIconByID(itemID)
    }
    
    local start, duration, enabled = C_Item.GetItemCooldown(itemID)
    
    return {
        name = itemInfo.name,
        texture = extraData and extraData.texture or itemInfo.texture,
        start = start,
        duration = duration,
        enabled = enabled,
        type = "item",
        id = itemID
    }
end

function CooldownData:GetPetCooldownDetails(spellID, extraData)
    local PetData = rawget(_G, "PetData")
    local index = extraData and extraData.index
    if not index then
        local spellName = C_Spell.GetSpellName(spellID)
        if PetData then
            index = PetData:GetPetActionIndexByName(spellName)
        else
            for i = 1, NUM_PET_ACTION_SLOTS do
                local actionName = GetPetActionInfo(i)
                if actionName == spellName then
                    index = i
                    break
                end
            end
        end
    end
    
    if index then
        local petInfo = PetData and PetData:GetPetActionInfo(index) or {
            name = GetPetActionInfo(index),
            texture = select(2, GetPetActionInfo(index))
        }
        local cooldown = PetData and PetData:GetPetActionCooldown(index) or {}
        local start, duration, enabled = GetPetActionCooldown(index)
        
        return {
            name = petInfo.name,
            texture = petInfo.texture,
            start = start,
            duration = duration,
            enabled = enabled,
            type = "pet",
            id = spellID,
            index = index,
            isPet = true
        }
    end
    
    return nil
end

function CooldownData:IsValidForTracking(cooldownDetails, minDuration)
    minDuration = minDuration or 2.0
    
    return cooldownDetails and 
           cooldownDetails.enabled and cooldownDetails.enabled ~= 0 and
           cooldownDetails.duration and cooldownDetails.duration > minDuration and
           cooldownDetails.texture
end

_G.CooldownData = CooldownData

return CooldownData