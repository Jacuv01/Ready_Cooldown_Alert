local ItemData = {}

-- Obtener información básica del item
function ItemData:GetItemInfo(itemID)
    local itemName = C_Item.GetItemNameByID(itemID)
    local itemIcon = C_Item.GetItemIconByID(itemID)
    return {
        name = itemName,
        texture = itemIcon,
        itemID = itemID
    }
end

-- Obtener cooldown del item
function ItemData:GetItemCooldown(itemID)
    local start, duration, enabled = C_Item.GetItemCooldown(itemID)
    return {
        start = start,
        duration = duration,
        enabled = enabled
    }
end

-- Obtener el spell que ejecuta un item (si tiene)
function ItemData:GetItemSpell(itemID)
    local spellName = C_Item.GetItemSpell(itemID)
    local spellID = nil
    if spellName then
        -- Usar C_Spell para obtener información del spell
        spellID = C_Spell.GetSpellIDForSpellIdentifier(spellName)
    end
    return spellID, spellName
end

-- Obtener item del inventario equipado
function ItemData:GetInventoryItemInfo(slot)
    local itemID = GetInventoryItemID("player", slot)
    if itemID then
        return {
            itemID = itemID,
            texture = GetInventoryItemTexture("player", slot),
            name = C_Item.GetItemNameByID(itemID)
        }
    end
    return nil
end

-- Obtener item de bolsa
function ItemData:GetContainerItemInfo(bag, slot)
    local itemID = C_Container.GetContainerItemID(bag, slot)
    if itemID then
        local texture = C_Item.GetItemIconByID(itemID)
        return {
            itemID = itemID,
            texture = texture,
            name = C_Item.GetItemNameByID(itemID)
        }
    end
    return nil
end

-- Exportar globalmente para WoW addon system
_G.ItemData = ItemData

return ItemData