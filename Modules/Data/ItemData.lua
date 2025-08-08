local ItemData = {}

function ItemData:GetItemInfo(itemID)
    local itemName = C_Item.GetItemNameByID(itemID)
    local itemIcon = C_Item.GetItemIconByID(itemID)
    return {
        name = itemName,
        texture = itemIcon,
        itemID = itemID
    }
end

function ItemData:GetItemCooldown(itemID)
    local start, duration, enabled = C_Item.GetItemCooldown(itemID)
    return {
        start = start,
        duration = duration,
        enabled = enabled
    }
end

function ItemData:GetItemSpell(itemID)
    local spellName = C_Item.GetItemSpell(itemID)
    local spellID = nil
    if spellName then
        spellID = C_Spell.GetSpellIDForSpellIdentifier(spellName)
    end
    return spellID, spellName
end

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

_G.ItemData = ItemData

return ItemData