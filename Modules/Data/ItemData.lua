local ItemData = {}

-- Obtener información básica del item
function ItemData:GetItemInfo(itemID)
    local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
    return {
        name = name,
        texture = texture,
        itemID = itemID
    }
end

-- Obtener cooldown del item
function ItemData:GetItemCooldown(itemID)
    local start, duration, enabled = C_Container.GetItemCooldown(itemID)
    return {
        start = start,
        duration = duration,
        enabled = enabled
    }
end

-- Obtener el spell que ejecuta un item (si tiene)
function ItemData:GetItemSpell(itemID)
    local spellName, spellID = GetItemSpell(itemID)
    return spellID, spellName
end

-- Obtener item del inventario equipado
function ItemData:GetInventoryItemInfo(slot)
    local itemID = GetInventoryItemID("player", slot)
    if itemID then
        return {
            itemID = itemID,
            texture = GetInventoryItemTexture("player", slot),
            name = GetItemInfo(itemID)
        }
    end
    return nil
end

-- Obtener item de bolsa
function ItemData:GetContainerItemInfo(bag, slot)
    local itemID = C_Container.GetContainerItemID(bag, slot)
    if itemID then
        local texture = select(10, GetItemInfo(itemID))
        return {
            itemID = itemID,
            texture = texture,
            name = GetItemInfo(itemID)
        }
    end
    return nil
end

return ItemData