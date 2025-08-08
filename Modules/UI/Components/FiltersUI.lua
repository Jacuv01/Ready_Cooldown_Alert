local FiltersUI = {}

-- Referencias de UI
local filtersFrame = nil
local invertCheckbox = nil
local addInput = nil
local addButton = nil
local filtersList = nil
local scrollFrame = nil
local scrollChild = nil
local clearAllButton = nil
local importExportButton = nil

-- Sistema de sugerencias
local suggestionsFrame = nil
local suggestionsScrollFrame = nil
local suggestionsScrollChild = nil
local suggestionButtons = {}
local currentSuggestions = {}

-- Estado
local filterItems = {} -- Lista de elementos en la UI
local isInitialized = false
local recentSearches = {} -- Cache de búsquedas recientes

-- Sistema de protección contra conflictos
local protectedMode = false

-- Función auxiliar para operaciones seguras
local function SafeCall(func, ...)
    if protectedMode then return end
    
    local success, result = pcall(func, ...)
    if not success then
        print("|cFFFF0000Ready Cooldown Alert:|r Error in UI operation: " .. tostring(result))
        protectedMode = true
        -- Reactivar después de 1 segundo
        C_Timer.After(1, function() protectedMode = false end)
    end
    return success, result
end

-- Función para limpiar recursos y evitar conflictos
function FiltersUI:Cleanup()
    SafeCall(function()
        -- Ocultar sugerencias
        self:HideSuggestions()
        
        -- Limpiar referencias
        if addInput then
            addInput:SetScript("OnTextChanged", nil)
            addInput:SetScript("OnEditFocusGained", nil)
            addInput:SetScript("OnEditFocusLost", nil)
            addInput:SetScript("OnEnterPressed", nil)
            addInput:SetScript("OnKeyDown", nil)
        end
        
        -- Limpiar botones de sugerencias
        for _, button in pairs(suggestionButtons) do
            if button then
                button:SetScript("OnClick", nil)
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
            end
        end
        
        protectedMode = false
    end)
end

-- Inicializar UI de filtros
function FiltersUI:Initialize(parentFrame, layoutManager)
    if isInitialized then return end
    
    -- Usar SafeCall para evitar conflictos durante la inicialización
    SafeCall(function()
        self.parentFrame = parentFrame
        self.layoutManager = layoutManager
        filtersFrame = parentFrame
        
        -- Crear elementos de UI
        self:CreateAddInput()
        self:CreateSuggestionsFrame()  -- Nuevo frame de sugerencias
        self:CreateAddButton()
        self:CreateFiltersList()
        self:CreateActionButtons()
        self:CreateInvertCheckbox() -- Movido después de los botones de acción
        
        -- Cargar datos actuales
        self:RefreshFiltersList()
        
        isInitialized = true
    end)
end

-- Crear checkbox de inversión (whitelist mode)
function FiltersUI:CreateInvertCheckbox()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    invertCheckbox = CreateFrame("CheckButton", nil, filtersFrame, "UICheckButtonTemplate")
    invertCheckbox:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.invertCheckbox.x, layout.invertCheckbox.y)
    
    -- Texto
    invertCheckbox.text = invertCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    invertCheckbox.text:SetPoint("LEFT", invertCheckbox, "RIGHT", 5, 0)
    invertCheckbox.text:SetText("Whitelist Mode (invert filter)")
    
    -- Funcionalidad
    invertCheckbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        ReadyCooldownAlertDB.invertIgnored = isChecked
        
        -- Actualizar FilterProcessor
        if FilterProcessor then
            FilterProcessor:RefreshFilters()
        end
    end)
    
    -- Cargar estado actual
    if ReadyCooldownAlertDB and ReadyCooldownAlertDB.invertIgnored then
        invertCheckbox:SetChecked(ReadyCooldownAlertDB.invertIgnored)
    end
end

-- Crear input para agregar filtros
function FiltersUI:CreateAddInput()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    -- Label
    local label = filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.addInput.x, layout.addInput.y + 20)
    label:SetText(layout.addInput.label)
    
    -- Input field
    addInput = CreateFrame("EditBox", nil, filtersFrame, "InputBoxTemplate")
    addInput:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.addInput.x, layout.addInput.y)
    addInput:SetSize(layout.addInput.width, layout.addInput.height)
    addInput:SetAutoFocus(false)
    addInput:SetMaxLetters(50)
    
    -- Status label para feedback en tiempo real
    local statusLabel = filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("TOPLEFT", addInput, "BOTTOMLEFT", 0, -5)
    statusLabel:SetText("")
    self.statusLabel = statusLabel -- Guardar referencia para uso global
    
    -- Placeholder text
    addInput:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Enter spell name or ID..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
        statusLabel:SetText("") -- Limpiar status al enfocar
    end)
    
    addInput:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Enter spell name or ID...")
            self:SetTextColor(0.5, 0.5, 0.5, 1)
            statusLabel:SetText("") -- Limpiar status al desenfocar
        end
    end)
    
    -- Validación en tiempo real mientras escribe
    addInput:SetScript("OnTextChanged", function(self, userChanged)
        if not userChanged then return end -- Ignorar cambios programáticos
        
        local text = self:GetText()
        if text == "" or text == "Enter spell name or ID..." then
            statusLabel:SetText("")
            FiltersUI:HideSuggestions()
            return
        end
        
        -- Mostrar sugerencias mientras escribe
        FiltersUI:ShowSuggestions(text)
        
        -- Validar en tiempo real
        local isValid, message = FiltersUI:ValidateInput(text)
        if isValid then
            if message:find("✅") then
                statusLabel:SetText("|cFF00FF00" .. message .. "|r") -- Verde para válido
            elseif message:find("⚠️") then
                statusLabel:SetText("|cFFFFAA00" .. message .. "|r") -- Amarillo para warning
            else
                statusLabel:SetText("|cFF00FF00Ready to add|r") -- Verde por defecto
            end
        else
            statusLabel:SetText("|cFFFF0000" .. message .. "|r") -- Rojo para error
        end
    end)
    
    -- Ocultar sugerencias al perder foco
    addInput:SetScript("OnEditFocusLost", function(self)
        -- Pequeño delay para permitir clicks en sugerencias
        C_Timer.After(0.1, function()
            FiltersUI:HideSuggestions()
        end)
        
        if self:GetText() == "" then
            self:SetText("Enter spell name or ID...")
            self:SetTextColor(0.5, 0.5, 0.5, 1)
            statusLabel:SetText("") -- Limpiar status al desenfocar
        end
    end)
    
    -- Enter para agregar
    addInput:SetScript("OnEnterPressed", function(self)
        FiltersUI:HideSuggestions()
        FiltersUI:AddFilter()
    end)
    
    -- Navegación con teclas en sugerencias
    addInput:SetScript("OnKeyDown", function(self, key)
        if key == "DOWN" and suggestionsFrame and suggestionsFrame:IsShown() then
            FiltersUI:NavigateSuggestions(1)
        elseif key == "UP" and suggestionsFrame and suggestionsFrame:IsShown() then
            FiltersUI:NavigateSuggestions(-1)
        elseif key == "ESCAPE" then
            FiltersUI:HideSuggestions()
        end
    end)
    
    -- Establecer placeholder inicial
    addInput:SetText("Enter spell name or ID...")
    addInput:SetTextColor(0.5, 0.5, 0.5, 1)
end

-- Crear frame de sugerencias
function FiltersUI:CreateSuggestionsFrame()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    -- Frame principal de sugerencias
    suggestionsFrame = CreateFrame("Frame", nil, filtersFrame, "BackdropTemplate")
    suggestionsFrame:SetSize(layout.addInput.width, 200) -- 200px de altura máxima
    suggestionsFrame:SetPoint("TOPLEFT", addInput, "BOTTOMLEFT", 0, -2)
    suggestionsFrame:SetFrameStrata("DIALOG")
    suggestionsFrame:SetFrameLevel(100)
    
    -- Backdrop
    suggestionsFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    suggestionsFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.95)
    suggestionsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- ScrollFrame para sugerencias
    suggestionsScrollFrame = CreateFrame("ScrollFrame", nil, suggestionsFrame, "UIPanelScrollFrameTemplate")
    suggestionsScrollFrame:SetPoint("TOPLEFT", suggestionsFrame, "TOPLEFT", 8, -8)
    suggestionsScrollFrame:SetPoint("BOTTOMRIGHT", suggestionsFrame, "BOTTOMRIGHT", -25, 8)
    
    -- ScrollChild
    suggestionsScrollChild = CreateFrame("Frame", nil, suggestionsScrollFrame)
    suggestionsScrollChild:SetSize(layout.addInput.width - 33, 200)
    suggestionsScrollFrame:SetScrollChild(suggestionsScrollChild)
    
    -- Ocultar inicialmente
    suggestionsFrame:Hide()
end

-- Crear botón de agregar
function FiltersUI:CreateAddButton()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    addButton = CreateFrame("Button", nil, filtersFrame, "UIPanelButtonTemplate")
    addButton:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.addButton.x, layout.addButton.y)
    addButton:SetSize(layout.addButton.width, layout.addButton.height)
    addButton:SetText("Add")
    
    addButton:SetScript("OnClick", function()
        FiltersUI:AddFilter()
    end)
end

-- Crear lista scrollable de filtros
function FiltersUI:CreateFiltersList()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    -- Scroll frame
    scrollFrame = CreateFrame("ScrollFrame", nil, filtersFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.filtersList.x, layout.filtersList.y)
    scrollFrame:SetSize(layout.filtersList.width, layout.filtersList.height)
    
    -- Scroll child
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(layout.filtersList.width - 15, layout.filtersList.height)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Background
    local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(scrollFrame)
    bg:SetColorTexture(0, 0, 0, 0.3)
    
    filtersList = scrollChild
end

-- Crear botones de acción
function FiltersUI:CreateActionButtons()
    local layout = self.layoutManager:GetFiltersTabLayout()
    
    -- Clear All button
    clearAllButton = CreateFrame("Button", nil, filtersFrame, "UIPanelButtonTemplate")
    clearAllButton:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.clearAllButton.x, layout.clearAllButton.y)
    clearAllButton:SetSize(layout.clearAllButton.width, layout.clearAllButton.height)
    clearAllButton:SetText("Clear All")
    
    clearAllButton:SetScript("OnClick", function()
        FiltersUI:ClearAllFilters()
    end)
    
    -- Import/Export button
    importExportButton = CreateFrame("Button", nil, filtersFrame, "UIPanelButtonTemplate")
    importExportButton:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", layout.importExportButton.x, layout.importExportButton.y)
    importExportButton:SetSize(layout.importExportButton.width, layout.importExportButton.height)
    importExportButton:SetText("Import/Export")
    
    importExportButton:SetScript("OnClick", function()
        FiltersUI:ShowImportExportDialog()
    end)
end

-- Validar entrada antes de agregar a filtros
function FiltersUI:ValidateInput(text)
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
    
    -- Permitir nombres/IDs más cortos, solo verificar que no esté vacío
    if string.len(text) < 1 then
        return false, "Name/ID cannot be empty"
    end
    
    -- Verificar si ya existe
    if FilterProcessor then
        local existingFilters = FilterProcessor:GetIgnoredSpellsString()
        if existingFilters and existingFilters ~= "" then
            for filter in string.gmatch(existingFilters, "([^,]+)") do
                local trimmed = string.gsub(filter, "^%s*(.-)%s*$", "%1")
                if trimmed:lower() == text:lower() then
                    return false, "Filter already exists: " .. trimmed
                end
            end
        end
    end
    
    -- Detectar tipo de entrada y validar
    local inputType, id, name = self:DetectInputType(text)
    
    if inputType == "spell_id" then
        return true, "✅ Valid spell ID: " .. name .. " (ID: " .. id .. ")", text
    elseif inputType == "item_id" then
        return true, "✅ Valid item ID: " .. name .. " (ID: " .. id .. ")", text
    elseif inputType == "spell_name" then
        return true, "✅ Valid spell name: " .. name .. " (ID: " .. id .. ")", text
    elseif inputType == "item_name" then
        return true, "✅ Valid item name: " .. name .. " (ID: " .. id .. ")", text
    elseif inputType == "unknown_id" then
        -- ID numérico pero no encontrado
        local numId = tonumber(text)
        if numId <= 0 or numId > 999999 then
            return false, "Invalid ID range (1-999999)"
        end
        return true, "⚠️ Warning: ID " .. text .. " not found in game (will be added anyway)", text
    elseif inputType == "unknown_name" then
        -- Nombre no encontrado, validar caracteres
        if not string.match(text, "^[%a%s'%-%.%d]+$") then
            return false, "Invalid characters (only letters, numbers, spaces, apostrophes, hyphens and dots allowed)"
        end
        return true, "⚠️ Warning: '" .. text .. "' not found in game (will be added anyway)", text
    end
    
    return false, "Unknown validation error"
end

-- Buscar spell por nombre (helper function)
function FiltersUI:FindSpellByName(spellName)
    -- Usar búsqueda segura como en SearchPlayerSpells
    local spellIndex = 1
    while true do
        local name, spellID
        
        -- Intentar diferentes métodos para obtener spell info
        if C_SpellBook and C_SpellBook.GetSpellBookItemName then
            -- API moderna disponible
            name = C_SpellBook.GetSpellBookItemName(spellIndex, Enum.SpellBookSpellBank.Player)
            if name then
                -- Usar C_Spell para obtener ID por nombre
                local spellInfo = C_Spell.GetSpellInfo(name)
                if spellInfo then
                    spellID = spellInfo.spellID
                end
            end
        elseif _G.GetSpellBookItemName then
            -- API clásica si está disponible
            name = _G.GetSpellBookItemName(spellIndex, "spell")
            if name then
                -- Intentar obtener ID del spellbook
                if _G.GetSpellLink then
                    local spellLink = _G.GetSpellLink(spellIndex, "spell")
                    if spellLink then
                        spellID = tonumber(spellLink:match("spell:(%d+)"))
                    end
                end
                -- Fallback: usar GetSpellInfo si está disponible
                if not spellID and _G.GetSpellInfo then
                    spellID = select(7, _G.GetSpellInfo(name))
                end
            end
        else
            -- No hay APIs disponibles, usar método alternativo
            break
        end
        
        if not name then break end
        
        -- Verificar coincidencia
        if name:lower() == spellName:lower() then
            return spellID
        end
        
        spellIndex = spellIndex + 1
        
        -- Límite de seguridad
        if spellIndex > 1000 then break end
    end
    
    return nil
end

-- Validar si es un item ID válido
function FiltersUI:ValidateItemID(itemID)
    local itemName = C_Item.GetItemInfo(itemID)
    return itemName ~= nil, itemName
end

-- Buscar item por nombre
function FiltersUI:FindItemByName(itemName)
    -- Para items es más complejo ya que no hay una API directa
    -- Intentaremos con items equipados o en bags si es posible
    
    -- Verificar items equipados
    for slot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local name = GetItemInfo(itemLink)
            if name and name:lower() == itemName:lower() then
                local itemID = GetItemInfoFromHyperlink(itemLink)
                return itemID
            end
        end
    end
    
    return nil
end

-- Detectar tipo de entrada (spell, item, nombre)
function FiltersUI:DetectInputType(text)
    local isNumber = tonumber(text) ~= nil
    
    if isNumber then
        local id = tonumber(text)
        
        -- Intentar como spell ID primero
        local spellName = C_Spell.GetSpellName(id)
        if spellName then
            return "spell_id", id, spellName
        end
        
        -- Intentar como item ID
        local itemValid, itemName = self:ValidateItemID(id)
        if itemValid then
            return "item_id", id, itemName
        end
        
        return "unknown_id", id, nil
    else
        -- Es texto, intentar determinar si es spell o item
        local spellID = self:FindSpellByName(text)
        if spellID then
            return "spell_name", spellID, text
        end
        
        local itemID = self:FindItemByName(text)
        if itemID then
            return "item_name", itemID, text
        end
        
        return "unknown_name", nil, text
    end
end

-- Mostrar mensaje de validación al usuario
function FiltersUI:ShowValidationMessage(message, isError)
    local color = isError and "|cFFFF0000" or "|cFF00FF00" -- Rojo para error, verde para éxito
    print(color .. "[Ready Cooldown Alert] " .. message .. "|r")
    
    -- TODO: Mostrar mensaje en tooltip o frame de status
end

-- Agregar nuevo filtro con validación
function FiltersUI:AddFilter(skipValidation)
    local text = addInput:GetText()
    
    -- Si skipValidation es true, saltar la validación (usado para sugerencias)
    if not skipValidation then
        -- Validar entrada
        local isValid, message, validatedText = self:ValidateInput(text)
        
        if not isValid then
            -- Mostrar error
            self:ShowValidationMessage(message, true)
            return
        end
        
        -- Usar texto validado o texto original
        text = validatedText or text
        
        -- Mostrar mensaje de validación (si hay)
        if message and message ~= "Input accepted" then
            self:ShowValidationMessage(message, false)
        end
    end
    
    local finalText = string.gsub(text, "^%s*(.-)%s*$", "%1") -- Trim final
    
    -- Agregar a FilterProcessor
    if FilterProcessor then
        local success = FilterProcessor:AddIgnoredSpell(finalText)
        if success then
            self:ShowValidationMessage("Filter added: " .. finalText, false)
            
            -- Limpiar input
            addInput:SetText("")
            addInput:ClearFocus()
            
            -- Restore placeholder
            addInput:SetText("Enter spell name or ID...")
            addInput:SetTextColor(0.5, 0.5, 0.5, 1)
            
            -- Actualizar lista
            self:RefreshFiltersList()
        else
            self:ShowValidationMessage("Failed to add filter", true)
        end
    end
end

-- Remover filtro
function FiltersUI:RemoveFilter(filterName)
    if FilterProcessor then
        FilterProcessor:RemoveIgnoredSpell(filterName)
        self:RefreshFiltersList()
    end
end

-- Actualizar lista de filtros
function FiltersUI:RefreshFiltersList()
    if not filtersList then return end
    
    -- Limpiar items existentes
    for _, item in ipairs(filterItems) do
        item:Hide()
        item:SetParent(nil)
    end
    filterItems = {}
    
    -- Obtener filtros actuales
    local filters = {}
    if FilterProcessor then
        local filterString = FilterProcessor:GetIgnoredSpellsString()
        if filterString and filterString ~= "" then
            for filter in string.gmatch(filterString, "([^,]+)") do
                local trimmed = string.gsub(filter, "^%s*(.-)%s*$", "%1")
                if trimmed ~= "" then
                    table.insert(filters, trimmed)
                end
            end
        end
    end
    
    -- Crear items de UI
    local layout = self.layoutManager:GetFiltersTabLayout()
    for i, filterName in ipairs(filters) do
        local item = self:CreateFilterItem(filterName, i - 1, layout)
        table.insert(filterItems, item)
    end
    
    -- Actualizar tamaño del scroll child
    local totalHeight = #filters * (layout.filtersList.itemHeight + layout.filtersList.spacing)
    scrollChild:SetHeight(math.max(totalHeight, layout.filtersList.height))
end

-- Crear item individual de filtro
function FiltersUI:CreateFilterItem(filterName, index, layout)
    local item = CreateFrame("Frame", nil, scrollChild)
    local yOffset = -(index * (layout.filtersList.itemHeight + layout.filtersList.spacing))
    
    item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
    item:SetSize(layout.filtersList.width - 20, layout.filtersList.itemHeight)
    
    -- Background
    local bg = item:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(item)
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Text
    local text = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", item, "LEFT", 10, 0)
    text:SetText(filterName)
    text:SetTextColor(1, 1, 1, 1)
    
    -- Remove button
    local removeBtn = CreateFrame("Button", nil, item, "UIPanelCloseButton")
    removeBtn:SetPoint("RIGHT", item, "RIGHT", -5, 0)
    removeBtn:SetSize(16, 16)
    
    removeBtn:SetScript("OnClick", function()
        FiltersUI:RemoveFilter(filterName)
    end)
    
    return item
end

-- Limpiar todos los filtros
function FiltersUI:ClearAllFilters()
    if FilterProcessor then
        FilterProcessor:SetIgnoredSpellsString("")
        self:RefreshFiltersList()
    end
end

-- Mostrar diálogo de import/export
function FiltersUI:ShowImportExportDialog()
    -- TODO: Implementar diálogo de import/export
    print("Import/Export dialog - TODO")
end

-- Mostrar sugerencias basadas en el texto ingresado
function FiltersUI:ShowSuggestions(searchText)
    if protectedMode then return end
    
    SafeCall(function()
        if not suggestionsFrame or not searchText or searchText == "" or searchText == "Enter spell name or ID..." then
            self:HideSuggestions()
            return
        end
        
        -- Limpiar sugerencias previas
        for _, button in pairs(suggestionButtons) do
            if button then
                button:Hide()
            end
        end
        
        -- Buscar coincidencias de forma segura
        local success, suggestions = pcall(function()
            return self:FindSuggestions(searchText)
        end)
        
        if not success or not suggestions or #suggestions == 0 then
            self:HideSuggestions()
            return
        end
        
        -- Mostrar las primeras 8 sugerencias
        local maxSuggestions = math.min(8, #suggestions)
        local buttonHeight = 25
        local totalHeight = maxSuggestions * buttonHeight
        
        -- Ajustar altura del frame
        suggestionsFrame:SetHeight(totalHeight + 16) -- +16 para padding
        if suggestionsScrollChild then
            suggestionsScrollChild:SetHeight(totalHeight)
        end
    
    -- Crear/actualizar botones de sugerencias
    for i = 1, maxSuggestions do
        local suggestion = suggestions[i]
        local button = suggestionButtons[i]
        
        if not button then
            button = CreateFrame("Button", nil, suggestionsScrollChild)
            if suggestionsScrollChild and suggestionsScrollChild.GetWidth then
                local width = suggestionsScrollChild:GetWidth()
                button:SetSize(width - 10, buttonHeight - 2)
            else
                button:SetSize(190, buttonHeight - 2) -- Fallback width
            end
            suggestionButtons[i] = button
            
            -- Fondo del botón
            button.bg = button:CreateTexture(nil, "BACKGROUND")
            button.bg:SetAllPoints()
            button.bg:SetColorTexture(0.2, 0.2, 0.3, 0.3)
            
            -- Texto principal
            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.text:SetPoint("LEFT", button, "LEFT", 5, 3)
            button.text:SetJustifyH("LEFT")
            
            -- Texto de tipo/categoría
            button.typeText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.typeText:SetPoint("LEFT", button, "LEFT", 5, -8)
            button.typeText:SetJustifyH("LEFT")
            
            -- Hover effects
            button:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.3, 0.3, 0.4, 0.8)
            end)
            
            button:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0.2, 0.2, 0.3, 0.3)
            end)
        end
        
        -- Posicionar botón
        button:SetPoint("TOPLEFT", suggestionsScrollChild, "TOPLEFT", 5, -(i-1) * buttonHeight)
        
        -- Configurar texto y funcionalidad
        local displayText = suggestion.name
        if suggestion.id then
            displayText = displayText .. " |cFF888888(ID: " .. suggestion.id .. ")|r"
        end
        button.text:SetText(displayText)
        
        -- Texto de categoría con color
        local typeColor = suggestion.type == "spell" and "|cFF64B5F6" or "|cFFFFA726"
        button.typeText:SetText(typeColor .. string.upper(suggestion.type) .. "|r")
        
        -- Click handler
        button:SetScript("OnClick", function()
            local finalText = suggestion.preferredName or suggestion.name
            
            -- Agregar directamente sin validación (ya está validado en sugerencias)
            if FilterProcessor then
                local success = FilterProcessor:AddIgnoredSpell(finalText)
                if success then
                    -- Mostrar mensaje de éxito
                    if FiltersUI.statusLabel then
                        FiltersUI.statusLabel:SetText("|cFF00FF00Filter added: " .. finalText .. "|r")
                        C_Timer.After(3, function()
                            if FiltersUI.statusLabel then
                                FiltersUI.statusLabel:SetText("")
                            end
                        end)
                    end
                    
                    -- Limpiar input y restaurar placeholder
                    if addInput then
                        addInput:SetText("Enter spell name or ID...")
                        addInput:SetTextColor(0.5, 0.5, 0.5, 1)
                        addInput:ClearFocus()
                    end
                    
                    -- Actualizar lista
                    self:RefreshFiltersList()
                    
                    -- Agregar a búsquedas recientes
                    self:AddToRecentSearches(finalText)
                end
            end
            
            self:HideSuggestions()
        end)
        
        button:Show()
    end
    
    currentSuggestions = suggestions
    suggestionsFrame:Show()
    end) -- Cierre de SafeCall
end

-- Ocultar sugerencias
function FiltersUI:HideSuggestions()
    if suggestionsFrame then
        suggestionsFrame:Hide()
    end
    currentSuggestions = {}
end

-- Navegar sugerencias con teclado
function FiltersUI:NavigateSuggestions(direction)
    -- Esta función se puede implementar después para navegación con teclado
    -- Por ahora solo funcionan los clicks
end

-- Buscar coincidencias difusas
function FiltersUI:FindSuggestions(searchText)
    local suggestions = {}
    local searchLower = string.lower(searchText)
    
    -- Buscar en hechizos conocidos del jugador
    self:SearchPlayerSpells(searchLower, suggestions)
    
    -- Buscar en hechizos comunes/importantes
    self:SearchCommonSpells(searchLower, suggestions)
    
    -- Buscar en items equipados/bags
    self:SearchPlayerItems(searchLower, suggestions)
    
    -- Buscar en búsquedas recientes
    self:SearchRecentSearches(searchLower, suggestions)
    
    -- Ordenar por relevancia
    table.sort(suggestions, function(a, b)
        return a.relevance > b.relevance
    end)
    
    return suggestions
end

-- Buscar en hechizos del jugador
function FiltersUI:SearchPlayerSpells(searchText, suggestions)
    -- Spellbook del jugador - usar APIs compatibles
    local spellIndex = 1
    while true do
        local spellName, spellID
        
        -- Intentar diferentes métodos para obtener spell info
        if C_SpellBook and C_SpellBook.GetSpellBookItemName then
            -- API moderna disponible
            spellName = C_SpellBook.GetSpellBookItemName(spellIndex, Enum.SpellBookSpellBank.Player)
            if spellName then
                -- Usar C_Spell para obtener ID por nombre
                local spellInfo = C_Spell.GetSpellInfo(spellName)
                if spellInfo then
                    spellID = spellInfo.spellID
                end
            end
        elseif _G.GetSpellBookItemName then
            -- API clásica con verificación adicional
            spellName = _G.GetSpellBookItemName(spellIndex, "spell")
            if spellName then
                -- Usar C_Spell.GetSpellInfo si está disponible (más confiable)
                if C_Spell and C_Spell.GetSpellInfo then
                    local spellInfo = C_Spell.GetSpellInfo(spellName)
                    if spellInfo and spellInfo.spellID then
                        spellID = spellInfo.spellID
                    end
                end
                
                -- Fallback solo si no obtuvimos ID con C_Spell
                if not spellID then
                    -- Intentar obtener ID del spellbook
                    if _G.GetSpellLink then
                        local spellLink = _G.GetSpellLink(spellIndex, "spell")
                        if spellLink then
                            spellID = tonumber(spellLink:match("spell:(%d+)"))
                        end
                    end
                    -- Último fallback: usar GetSpellInfo si está disponible
                    if not spellID and _G.GetSpellInfo then
                        spellID = select(7, _G.GetSpellInfo(spellName))
                    end
                end
            end
        else
            -- No hay APIs disponibles, salir
            break
        end
        
        if not spellName then break end
        
        -- Agregar a sugerencias si coincide (con o sin ID)
        if self:MatchesSearch(spellName, searchText) then
            local relevance = self:CalculateRelevance(spellName, searchText)
            table.insert(suggestions, {
                name = spellName,
                id = spellID, -- Puede ser nil, está bien
                type = "spell",
                relevance = relevance + 10, -- Bonus por ser spell conocido
                preferredName = spellName
            })
        end
        spellIndex = spellIndex + 1
        
        -- Límite de seguridad para evitar loops infinitos
        if spellIndex > 1000 then break end
    end
end

-- Buscar en hechizos comunes
function FiltersUI:SearchCommonSpells(searchText, suggestions)
    local commonSpells = {
        -- Algunos hechizos comunes que la gente suele filtrar
        {name = "Fireball", id = 133},
        {name = "Frostbolt", id = 116},
        {name = "Lightning Bolt", id = 188443},
        {name = "Heal", id = 2054},
        {name = "Flash Heal", id = 2061},
        {name = "Renew", id = 139},
        {name = "Shadow Word: Pain", id = 589},
        {name = "Corruption", id = 172},
        -- Agregar más según necesidades
    }
    
    for _, spell in ipairs(commonSpells) do
        if self:MatchesSearch(spell.name, searchText) then
            local relevance = self:CalculateRelevance(spell.name, searchText)
            table.insert(suggestions, {
                name = spell.name,
                id = spell.id,
                type = "spell",
                relevance = relevance,
                preferredName = spell.name
            })
        end
    end
end

-- Buscar en items del jugador
function FiltersUI:SearchPlayerItems(searchText, suggestions)
    -- Simplificar búsqueda de items para evitar errores de API
    -- En lugar de buscar en bags, usar una lista de items comunes
    local commonItems = {
        {name = "Healing Potion", id = 929},
        {name = "Mana Potion", id = 2455},
        {name = "Food", id = 4540},
        {name = "Water", id = 159},
        {name = "Bandage", id = 1251},
        -- Se puede expandir esta lista
    }
    
    for _, item in ipairs(commonItems) do
        if self:MatchesSearch(item.name, searchText) then
            local relevance = self:CalculateRelevance(item.name, searchText)
            table.insert(suggestions, {
                name = item.name,
                id = item.id,
                type = "item",
                relevance = relevance,
                preferredName = item.name
            })
        end
    end
    
    -- Opcional: Intentar buscar en bags solo si las APIs están disponibles
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID then
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            if numSlots and numSlots > 0 then
                for slot = 1, numSlots do
                    local itemID = C_Container.GetContainerItemID(bag, slot)
                    if itemID then
                        local itemName = C_Item.GetItemInfo(itemID)
                        if itemName and self:MatchesSearch(itemName, searchText) then
                            local relevance = self:CalculateRelevance(itemName, searchText)
                            table.insert(suggestions, {
                                name = itemName,
                                id = itemID,
                                type = "item",
                                relevance = relevance + 5, -- Bonus por tener el item
                                preferredName = itemName
                            })
                        end
                    end
                end
            end
        end
    end
end

-- Buscar en búsquedas recientes
function FiltersUI:SearchRecentSearches(searchText, suggestions)
    for _, recent in ipairs(recentSearches) do
        if self:MatchesSearch(recent, searchText) then
            local relevance = self:CalculateRelevance(recent, searchText)
            table.insert(suggestions, {
                name = recent,
                id = nil,
                type = "recent",
                relevance = relevance + 15, -- Bonus alto por ser búsqueda reciente
                preferredName = recent
            })
        end
    end
end

-- Verificar si un texto coincide con la búsqueda
function FiltersUI:MatchesSearch(text, searchText)
    local textLower = string.lower(text)
    local searchLower = string.lower(searchText)
    
    -- Coincidencia exacta al inicio
    if string.find(textLower, "^" .. searchLower) then
        return true
    end
    
    -- Coincidencia en cualquier parte
    if string.find(textLower, searchLower) then
        return true
    end
    
    -- Coincidencia difusa (cada carácter de búsqueda existe en orden)
    local searchIndex = 1
    for i = 1, string.len(textLower) do
        if searchIndex <= string.len(searchLower) then
            local char = string.sub(textLower, i, i)
            local searchChar = string.sub(searchLower, searchIndex, searchIndex)
            if char == searchChar then
                searchIndex = searchIndex + 1
            end
        end
    end
    
    return searchIndex > string.len(searchLower)
end

-- Calcular relevancia de coincidencia
function FiltersUI:CalculateRelevance(text, searchText)
    local textLower = string.lower(text)
    local searchLower = string.lower(searchText)
    
    -- Coincidencia exacta = alta relevancia
    if textLower == searchLower then
        return 100
    end
    
    -- Coincidencia al inicio = alta relevancia
    if string.find(textLower, "^" .. searchLower) then
        return 80 + (string.len(searchLower) / string.len(textLower)) * 20
    end
    
    -- Coincidencia en palabra completa
    if string.find(textLower, "%f[%a]" .. searchLower .. "%f[%A]") then
        return 60 + (string.len(searchLower) / string.len(textLower)) * 20
    end
    
    -- Coincidencia parcial
    if string.find(textLower, searchLower) then
        return 40 + (string.len(searchLower) / string.len(textLower)) * 20
    end
    
    -- Coincidencia difusa
    return 20
end

-- Agregar a búsquedas recientes
function FiltersUI:AddToRecentSearches(searchText)
    -- Remover si ya existe
    for i, recent in ipairs(recentSearches) do
        if recent == searchText then
            table.remove(recentSearches, i)
            break
        end
    end
    
    -- Agregar al inicio
    table.insert(recentSearches, 1, searchText)
    
    -- Mantener solo las últimas 10
    if #recentSearches > 10 then
        table.remove(recentSearches, 11)
    end
end

-- Exportar globalmente para WoW addon system
_G.FiltersUI = FiltersUI

-- Frame para manejar eventos y prevenir conflictos
local eventFrame = CreateFrame("Frame")

-- Manejar eventos de sistema para prevenir conflictos
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Ready_Cooldown_Alert" then
            -- Verificar si hay conflictos potenciales
            if _G.Cell_UnitFrames then
                print("|cFFFFAA00Ready Cooldown Alert:|r Detected Cell_UnitFrames addon. Using protected mode for compatibility.")
                protectedMode = true
                C_Timer.After(2, function() protectedMode = false end)
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Limpiar recursos al salir
        if FiltersUI and FiltersUI.Cleanup then
            FiltersUI:Cleanup()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Activar modo protegido temporalmente durante cambios de especialización
        protectedMode = true
        C_Timer.After(1, function() protectedMode = false end)
    end
end)

return FiltersUI
