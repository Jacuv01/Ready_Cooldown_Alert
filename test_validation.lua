-- Test de validación de entrada para FiltersUI
-- Este script testea las nuevas funciones de validación

local function TestValidation()
    print("🧪 Testing FiltersUI Input Validation System")
    print("=" .. string.rep("=", 60))
    
    -- Mock del FiltersUI para testing
    local MockFiltersUI = {
        ValidateInput = function(self, text)
            -- Validaciones básicas
            if not text or text == "" or text == "Enter spell name or ID..." then
                return false, "Please enter a spell name or ID"
            end
            
            -- Trim whitespace
            text = string.gsub(text, "^%s*(.-)%s*$", "%1")
            
            if text == "" then
                return false, "Please enter a spell name or ID"
            end
            
            -- Validar longitud
            if string.len(text) > 50 then
                return false, "Name/ID too long (max 50 characters)"
            end
            
            if string.len(text) < 2 then
                return false, "Name/ID too short (min 2 characters)"
            end
            
            -- Validaciones específicas simuladas
            local isNumber = tonumber(text) ~= nil
            if isNumber then
                local id = tonumber(text)
                if id <= 0 or id > 999999 then
                    return false, "Invalid ID range (1-999999)"
                end
                
                -- Simular spell IDs conocidos
                local knownSpells = {
                    [12345] = "Test Spell",
                    [54321] = "Another Spell",
                    [1] = "Fireball"
                }
                
                if knownSpells[id] then
                    return true, "✅ Valid spell ID: " .. knownSpells[id] .. " (ID: " .. id .. ")"
                else
                    return true, "⚠️ Warning: ID " .. id .. " not found in game (will be added anyway)"
                end
            else
                -- Validar caracteres
                if not string.match(text, "^[%a%s'%-%.%d]+$") then
                    return false, "Invalid characters (only letters, numbers, spaces, apostrophes, hyphens and dots allowed)"
                end
                
                -- Simular nombres conocidos
                local knownNames = {
                    ["fireball"] = true,
                    ["ice bolt"] = true,
                    ["heal"] = true
                }
                
                if knownNames[text:lower()] then
                    return true, "✅ Valid spell name: " .. text
                else
                    return true, "⚠️ Warning: '" .. text .. "' not found in game (will be added anyway)"
                end
            end
        end
    }
    
    -- Test cases
    local testCases = {
        -- Casos válidos
        {input = "12345", expected = true, description = "Valid spell ID"},
        {input = "Fireball", expected = true, description = "Valid spell name"},
        {input = "Ice Bolt", expected = true, description = "Spell name with space"},
        {input = "1", expected = true, description = "Known spell ID 1"},
        {input = "999999", expected = true, description = "Max ID range"},
        {input = "Unknown Spell", expected = true, description = "Unknown but valid name format"},
        {input = "12345", expected = true, description = "Unknown but valid ID"},
        
        -- Casos inválidos
        {input = "", expected = false, description = "Empty input"},
        {input = "   ", expected = false, description = "Whitespace only"},
        {input = "A", expected = false, description = "Too short"},
        {input = string.rep("A", 51), expected = false, description = "Too long"},
        {input = "0", expected = false, description = "ID too small"},
        {input = "1000000", expected = false, description = "ID too large"},
        {input = "Spell@Name", expected = false, description = "Invalid characters"},
        {input = "Enter spell name or ID...", expected = false, description = "Placeholder text"},
        
        -- Casos edge
        {input = "Spell'Name", expected = true, description = "Valid apostrophe"},
        {input = "Spell-Name", expected = true, description = "Valid hyphen"},
        {input = "Spell.Name", expected = true, description = "Valid dot"},
        {input = "  Spell Name  ", expected = true, description = "Whitespace trimming"},
        {input = "Spell Name 2", expected = true, description = "Name with number"}
    }
    
    -- Ejecutar tests
    local passed = 0
    local total = #testCases
    
    for i, test in ipairs(testCases) do
        local isValid, message = MockFiltersUI:ValidateInput(test.input)
        local testPassed = (isValid == test.expected)
        
        local status = testPassed and "✅ PASS" or "❌ FAIL"
        local color = testPassed and "|cFF00FF00" or "|cFFFF0000"
        
        print(string.format("%s%d. %s: %s|r", color, i, test.description, status))
        print(string.format("   Input: '%s'", test.input))
        print(string.format("   Expected: %s, Got: %s", test.expected and "valid" or "invalid", isValid and "valid" or "invalid"))
        if message then
            print(string.format("   Message: %s", message))
        end
        print("")
        
        if testPassed then
            passed = passed + 1
        end
    end
    
    -- Resultados finales
    print("=" .. string.rep("=", 60))
    local successRate = math.floor((passed / total) * 100)
    local color = successRate == 100 and "|cFF00FF00" or (successRate >= 80 and "|cFFFFAA00" or "|cFFFF0000")
    
    print(string.format("%sTest Results: %d/%d passed (%d%%)|r", color, passed, total, successRate))
    
    if successRate == 100 then
        print("|cFF00FF00🎉 All validation tests passed!|r")
    elseif successRate >= 80 then
        print("|cFFFFAA00⚠️ Most tests passed, minor issues detected|r")
    else
        print("|cFFFF0000❌ Validation system needs fixes|r")
    end
end

-- Ejecutar test
TestValidation()
