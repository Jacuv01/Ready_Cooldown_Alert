local ActionHooks = {}

-- Callbacks registrados
ActionHooks.callbacks = {}

-- Registrar callback para acciones detectadas
function ActionHooks:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

-- Ejecutar callbacks cuando se detecte una acción
function ActionHooks:TriggerCallbacks(actionType, id, texture, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback(actionType, id, texture, extraData)
    end
end

-- Detectar spell de un item
function ActionHooks:GetItemSpellID(itemID)
    if ItemData then
        return ItemData:GetItemSpell(itemID)
    end
    local spellName, spellID = C_Item.GetItemSpell(itemID)
    return spellID
end

-- Hook UseAction (barras de acción)
function ActionHooks:HookUseAction()
    
    hooksecurefunc("UseAction", function(slot)
        local actionType, itemID = GetActionInfo(slot)
        
        if actionType == "item" then
            local spellID = self:GetItemSpellID(itemID)
            local texture = GetActionTexture(slot)
            
            self:TriggerCallbacks("item", itemID, texture, {
                spellID = spellID,
                slot = slot,
                source = "actionbar"
            })
        end
    end)
end

-- Hook UseInventoryItem (inventario)
function ActionHooks:HookUseInventoryItem()

    hooksecurefunc("UseInventoryItem", function(slot)
        local itemID = GetInventoryItemID("player", slot)

        if itemID then
            local spellID = self:GetItemSpellID(itemID)
            local texture = GetInventoryItemTexture("player", slot)
            
            self:TriggerCallbacks("item", itemID, texture, {
                spellID = spellID,
                slot = slot,
                source = "inventory"
            })
        end
    end)
end

-- Hook UseContainerItem (bolsas)
function ActionHooks:HookUseContainerItem()
    hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
        local itemID = C_Container.GetContainerItemID(bag, slot)
        if itemID then
            local spellID = self:GetItemSpellID(itemID)
            local texture = C_Item.GetItemIconByID(itemID)
            
            self:TriggerCallbacks("item", itemID, texture, {
                spellID = spellID,
                bag = bag,
                slot = slot,
                source = "container"
            })
        end
    end)
end

-- Inicializar todos los hooks
function ActionHooks:Initialize()
    self:HookUseAction()
    self:HookUseInventoryItem()
    self:HookUseContainerItem()
end

-- Exportar globalmente para WoW addon system
_G.ActionHooks = ActionHooks

return ActionHooks
