local FilterProcessor = {}

local ignoredSpells = {}
local invertIgnored = false

function FilterProcessor:Initialize()
    self:RefreshFilters()
end

function FilterProcessor:RefreshFilters()
    if ReadyCooldownAlertDB and ReadyCooldownAlertDB.ignoredSpells then
        ignoredSpells = {}
        
        local spellString = ReadyCooldownAlertDB.ignoredSpells
        for spellName in string.gmatch(spellString, "([^,]+)") do
            local trimmedName = string.gsub(spellName, "^%s*(.-)%s*$", "%1")
            if trimmedName ~= "" then
                ignoredSpells[trimmedName] = true
            end
        end
        
        invertIgnored = ReadyCooldownAlertDB.invertIgnored or false
    end
end

function FilterProcessor:ShouldFilter(name, id)
    if not name then
        return false
    end
    
    local isInList = ignoredSpells[name] ~= nil
    
    if not isInList and id then
        isInList = ignoredSpells[tostring(id)] ~= nil
    end
    
    if invertIgnored then
        return not isInList
    else
        return isInList
    end
end

function FilterProcessor:AddIgnoredSpell(name)
    if not name or name == "" then
        return false
    end
    
    ignoredSpells[name] = true
    self:SaveFilters()
    return true
end

function FilterProcessor:RemoveIgnoredSpell(name)
    if not name or not ignoredSpells[name] then
        return false
    end
    
    ignoredSpells[name] = nil
    self:SaveFilters()
    return true
end

function FilterProcessor:GetIgnoredSpellsString()
    local spellList = {}
    for name, _ in pairs(ignoredSpells) do
        table.insert(spellList, name)
    end
    
    table.sort(spellList)
    return table.concat(spellList, ", ")
end

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

function FilterProcessor:ToggleInvertIgnored()
    invertIgnored = not invertIgnored
    self:SaveFilters()
    return invertIgnored
end

function FilterProcessor:IsInvertIgnored()
    return invertIgnored
end

function FilterProcessor:SaveFilters()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    ReadyCooldownAlertDB.ignoredSpells = self:GetIgnoredSpellsString()
    ReadyCooldownAlertDB.invertIgnored = invertIgnored
end

function FilterProcessor:ClearAllFilters()
    ignoredSpells = {}
    invertIgnored = false
    self:SaveFilters()
end

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

_G.FilterProcessor = FilterProcessor

return FilterProcessor
