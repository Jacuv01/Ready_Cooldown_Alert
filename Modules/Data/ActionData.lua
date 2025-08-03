local ActionData = {}
local ItemData = require("Modules.Data.ItemData")

-- Callbacks que se ejecutarán cuando se detecte uso de acciones
ActionData.callbacks = {}

-- Registrar callback para cuando se use una acción
function ActionData:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

-- Ejecutar todos los callbacks registrados
function ActionData:TriggerCallbacks(actionType, id, texture, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback(actionType, id, texture, extraData)
    end
end

-- Mapear spell -> item para tracking
function ActionData:TrackItemSpell(itemID)
    local spellID = ItemData:GetItemSpell(itemID)
    if spellID then
        return spellID
    end
    return nil
end

-- Hook para UseAction (barras de acción)
function ActionData:HookUseAction()
    hooksecurefunc("UseAction", function(slot)
        local actionType, itemID = GetActionInfo(slot)
        if actionType == "item" then
            local spellID = self:TrackItemSpell(itemID)
            local texture = GetActionTexture(slot)
            
            self:TriggerCallbacks("item", itemID, texture, {
                spellID = spellID,
                slot = slot,
                source = "actionbar"
            })
        end
    end)
end

-- Hook para UseInventoryItem (inventario equipado)
function ActionData:HookUseInventoryItem()
    hooksecurefunc("UseInventoryItem", function(slot)
        local itemInfo = ItemData:GetInventoryItemInfo(slot)
        if itemInfo then
            local spellID = self:TrackItemSpell(itemInfo.itemID)
            
            self:TriggerCallbacks("item", itemInfo.itemID, itemInfo.texture, {
                spellID = spellID,
                slot = slot,
                source = "inventory"
            })
        end
    end)
end

-- Hook para UseContainerItem (items de bolsas)
function ActionData:HookUseContainerItem()
    hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
        local itemInfo = ItemData:GetContainerItemInfo(bag, slot)
        if itemInfo then
            local spellID = self:TrackItemSpell(itemInfo.itemID)
            
            self:TriggerCallbacks("item", itemInfo.itemID, itemInfo.texture, {
                spellID = spellID,
                bag = bag,
                slot = slot,
                source = "container"
            })
        end
    end)
end

-- Inicializar todos los hooks
function ActionData:Initialize()
    self:HookUseAction()
    self:HookUseInventoryItem()
    self:HookUseContainerItem()
end

return ActionData