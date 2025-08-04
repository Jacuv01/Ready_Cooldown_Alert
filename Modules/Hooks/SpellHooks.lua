local SpellHooks = {}

-- Callbacks registrados
SpellHooks.callbacks = {}

-- Variable para mapear spells -> items
local itemSpells = {}

-- Registrar callback
function SpellHooks:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

-- Ejecutar callbacks
function SpellHooks:TriggerCallbacks(spellID, extraData)
    
    for _, callback in ipairs(self.callbacks) do
        -- Verificar si es un item que usa spell
        local itemID = itemSpells[spellID]
        if itemID then
            callback("item", itemID, extraData.texture, {
                spellID = spellID,
                source = "spellcast"
            })
            itemSpells[spellID] = nil -- Limpiar después de usar
        else
            callback("spell", spellID, spellID, {
                source = "spellcast"
            })
        end
    end
end

-- Agregar mapeo spell -> item
function SpellHooks:AddItemSpellMapping(spellID, itemID)
    itemSpells[spellID] = itemID
end

-- Hook para detectar hechizos lanzados
function SpellHooks:HookSpellCast()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    frame:SetScript("OnEvent", function(_, event, unit, lineID, spellID)
        if unit == "player" then
            self:TriggerCallbacks(spellID, {
                lineID = lineID,
                source = "spellcast"
            })
        end
    end)
end

function SpellHooks:Initialize()
    self:HookSpellCast()
end

-- Exportar globalmente para WoW addon system
_G.SpellHooks = SpellHooks

return SpellHooks
