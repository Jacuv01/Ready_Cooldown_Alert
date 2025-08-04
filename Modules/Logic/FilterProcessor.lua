local FilterProcessor = {}

-- Configuración de filtros
local ignoredSpells = {}
local invertIgnored = false

-- Inicializar filtros desde la configuración guardada
function FilterProcessor:Initialize()
    self:RefreshFilters()
end

-- Actualizar filtros desde SavedVariables
function FilterProcessor:RefreshFilters()
    if ReadyCooldownAlertDB and ReadyCooldownAlertDB.ignoredSpells then
        ignoredSpells = {}
        
        -- Parsear string de hechizos ignorados
        local spellString = ReadyCooldownAlertDB.ignoredSpells
        for spellName in string.gmatch(spellString, "([^,]+)") do
            local trimmedName = string.gsub(spellName, "^%s*(.-)%s*$", "%1") -- trim whitespace
            if trimmedName ~= "" then
                ignoredSpells[trimmedName] = true
            end
        end
        
        invertIgnored = ReadyCooldownAlertDB.invertIgnored or false
    end
end

-- Verificar si un hechizo/item debe ser filtrado
function FilterProcessor:ShouldFilter(name, id)
    if not name then
        return false
    end
    
    -- Verificar por nombre
    local isInList = ignoredSpells[name] ~= nil
    
    -- Verificar por ID (convertido a string)
    if not isInList and id then
        isInList = ignoredSpells[tostring(id)] ~= nil
    end
    
    -- Aplicar lógica de inversión
    if invertIgnored then
        -- Si está invertido, filtrar todo EXCEPTO los de la lista
        return not isInList
    else
        -- Normal: filtrar los que están en la lista
        return isInList
    end
end

-- Añadir hechizo a la lista de ignorados
function FilterProcessor:AddIgnoredSpell(name)
    if not name or name == "" then
        return false
    end
    
    ignoredSpells[name] = true
    self:SaveFilters()
    return true
end

-- Remover hechizo de la lista de ignorados
function FilterProcessor:RemoveIgnoredSpell(name)
    if not name or not ignoredSpells[name] then
        return false
    end
    
    ignoredSpells[name] = nil
    self:SaveFilters()
    return true
end

-- Obtener lista de hechizos ignorados como string
function FilterProcessor:GetIgnoredSpellsString()
    local spellList = {}
    for name, _ in pairs(ignoredSpells) do
        table.insert(spellList, name)
    end
    
    table.sort(spellList)
    return table.concat(spellList, ", ")
end

-- Establecer lista de hechizos ignorados desde string
function FilterProcessor:SetIgnoredSpellsString(spellString)
    ignoredSpells = {}
    
    if spellString and spellString ~= "" then
        for spellName in string.gmatch(spellString, "([^,]+)") do
            local trimmedName = string.gsub(spellName, "^%s*(.-)%s*$", "%1")
            if trimmedName ~= "" then
                ignoredSpells[trimmedName] = true
            end
        end
    end
    
    self:SaveFilters()
end

-- Alternar modo invertido
function FilterProcessor:ToggleInvertIgnored()
    invertIgnored = not invertIgnored
    self:SaveFilters()
    return invertIgnored
end

-- Obtener estado actual del modo invertido
function FilterProcessor:IsInvertIgnored()
    return invertIgnored
end

-- Guardar configuración de filtros
function FilterProcessor:SaveFilters()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    ReadyCooldownAlertDB.ignoredSpells = self:GetIgnoredSpellsString()
    ReadyCooldownAlertDB.invertIgnored = invertIgnored
end

-- Limpiar todos los filtros
function FilterProcessor:ClearAllFilters()
    ignoredSpells = {}
    invertIgnored = false
    self:SaveFilters()
end

-- Obtener estadísticas de filtros
function FilterProcessor:GetFilterStats()
    local count = 0
    for _ in pairs(ignoredSpells) do
        count = count + 1
    end
    
    return {
        ignoredCount = count,
        isInverted = invertIgnored,
        ignoredSpells = ignoredSpells
    }
end

-- Exportar globalmente para WoW addon system
_G.FilterProcessor = FilterProcessor

return FilterProcessor
