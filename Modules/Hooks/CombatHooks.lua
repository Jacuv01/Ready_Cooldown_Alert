local CombatHooks = {}

-- Callbacks registrados
CombatHooks.callbacks = {}

-- Registrar callback
function CombatHooks:RegisterCallback(callback)
    table.insert(self.callbacks, callback)
end

-- Ejecutar callbacks
function CombatHooks:TriggerCallbacks(spellID, extraData)
    for _, callback in ipairs(self.callbacks) do
        callback("pet", spellID, extraData.texture, extraData)
    end
end

-- Hook para eventos de combate (mascotas)
function CombatHooks:HookCombatLog()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", function()
        local _, event, _, _, _, sourceFlags, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        
        if event == "SPELL_CAST_SUCCESS" then
            -- Verificar si es mascota propia
            if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PET) == COMBATLOG_OBJECT_TYPE_PET and 
               bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE then
                
                local name = C_Spell.GetSpellName(spellID)
                if name then
                    -- Buscar índice de la acción de mascota
                    for i = 1, NUM_PET_ACTION_SLOTS do
                        local petActionName = GetPetActionInfo(i)
                        if petActionName == name then
                            -- Solo si no es pasiva
                            local _, _, _, _, _, isAutocast = GetPetActionInfo(i)
                            if not isAutocast then
                                local _, texture = GetPetActionInfo(i)
                                self:TriggerCallbacks(spellID, {
                                    index = i,
                                    texture = texture,
                                    source = "pet_combat"
                                })
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

function CombatHooks:Initialize()
    self:HookCombatLog()
end

-- Exportar globalmente para WoW addon system
_G.CombatHooks = CombatHooks

return CombatHooks
