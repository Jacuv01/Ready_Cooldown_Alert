local ActionHooks = {}

ActionHooks.callbacks = {}

function ActionHooks:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function ActionHooks:TriggerCallbacks(actionType, id, texture, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback(actionType, id, texture, extraData)
    end
end

function ActionHooks:GetItemSpellID(itemID)
    if ItemData then
        return ItemData:GetItemSpell(itemID)
    end
    local spellName, spellID = C_Item.GetItemSpell(itemID)
    return spellID
end

function ActionHooks:HookUseAction()
    hooksecurefunc("UseAction", function(slot)
        local actionType, itemID = GetActionInfo(slot)
        
        if actionType == "item" then
            local spellID = self:GetItemSpellID(itemID)
            local texture = GetActionTexture(slot)
            
            if spellID then
                local SpellHooks = rawget(_G, "SpellHooks")
                if SpellHooks and SpellHooks.AddItemSpellMapping then
                    SpellHooks:AddItemSpellMapping(spellID, itemID)
                end
            end
            
        end
    end)
end

function ActionHooks:HookUseInventoryItem()
    hooksecurefunc("UseInventoryItem", function(slot)
        local itemID = GetInventoryItemID("player", slot)

        if itemID then
            local spellID = self:GetItemSpellID(itemID)
            local texture = GetInventoryItemTexture("player", slot)
            
            if spellID then
                local SpellHooks = rawget(_G, "SpellHooks")
                if SpellHooks and SpellHooks.AddItemSpellMapping then
                    SpellHooks:AddItemSpellMapping(spellID, itemID)
                end
            end
            
        end
    end)
end

function ActionHooks:HookUseContainerItem()
    hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
        local itemID = C_Container.GetContainerItemID(bag, slot)
        if itemID then
            local spellID = self:GetItemSpellID(itemID)
            local texture = C_Item.GetItemIconByID(itemID)
            
            if spellID then
                local SpellHooks = rawget(_G, "SpellHooks")
                if SpellHooks and SpellHooks.AddItemSpellMapping then
                    SpellHooks:AddItemSpellMapping(spellID, itemID)
                end
            end


        end
    end)
end

function ActionHooks:Initialize()
    self:HookUseAction()
    self:HookUseInventoryItem()
    self:HookUseContainerItem()
end

_G.ActionHooks = ActionHooks

return ActionHooks
