local SpellHooks = {}

SpellHooks.callbacks = {}

local itemSpells = {}

function SpellHooks:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

function SpellHooks:TriggerCallbacks(spellID, extraData)
    
    for _, callback in ipairs(self.callbacks) do
        local itemID = itemSpells[spellID]
        if itemID then
            callback("item", itemID, extraData.texture, {
                spellID = spellID,
                source = "spellcast"
            })
            itemSpells[spellID] = nil
        else
            callback("spell", spellID, spellID, {
                source = "spellcast"
            })
        end
    end
end

-- TODO: check if this function is affecting trinket double alert
function SpellHooks:AddItemSpellMapping(spellID, itemID)
    itemSpells[spellID] = itemID
end

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

_G.SpellHooks = SpellHooks

return SpellHooks
