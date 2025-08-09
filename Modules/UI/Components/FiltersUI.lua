local FiltersUI = {}

local filtersFrame = nil
local invertCheckbox = nil
local addInput = nil
local addButton = nil
local filtersList = nil
local scrollFrame = nil
local scrollChild = nil
local clearAllButton = nil
local suggestionsFrame = nil
local suggestionsScrollFrame = nil
local suggestionsScrollChild = nil
local suggestionButtons = {}
local currentSuggestions = {}
local filterItems = {}
local isInitialized = false
local selectedSuggestionIndex = 0

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        return false
    end
    return success, result
end

function FiltersUI:Cleanup()
    SafeCall(function()
        self:HideSuggestions()
        if addInput then
            addInput:SetText("")
        end
        for i = 1, #suggestionButtons do
            if suggestionButtons[i] then
                suggestionButtons[i]:Hide()
            end
        end
    end)
end

function FiltersUI:Initialize(parentFrame)
    if isInitialized then
        return
    end
    
    SafeCall(function()
        filtersFrame = parentFrame
        self:CreateAddInput()
        self:CreateAddButton()
        self:CreateHelpNote()
        self:CreateFiltersList()
        self:CreateSuggestionsFrame()
        self:CreateActionButtons()
        self:CreateInvertCheckbox()
        self:RefreshFiltersList()
        isInitialized = true
    end)
end

function FiltersUI:CreateInvertCheckbox()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local pos = layout.invertCheckbox or {x = 20, y = -520}
    
    invertCheckbox = CreateFrame("CheckButton", nil, filtersFrame, "UICheckButtonTemplate")
    invertCheckbox:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", pos.x, pos.y)
    invertCheckbox:SetSize(20, 20)
    
    local label = invertCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", invertCheckbox, "RIGHT", 5, 0)
    label:SetText("Whitelist Mode (only show these spells)")
    
    invertCheckbox:SetScript("OnClick", function()
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.invertIgnored = invertCheckbox:GetChecked()
        end
    end)
    
    if ReadyCooldownAlertDB then
        invertCheckbox:SetChecked(ReadyCooldownAlertDB.invertIgnored)
    end
end

function FiltersUI:CreateAddInput()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local pos = layout.addInput or {x = 20, y = -20, width = 250, height = 25}
    
    addInput = CreateFrame("EditBox", nil, filtersFrame, "InputBoxTemplate")
    addInput:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", pos.x, pos.y)
    addInput:SetSize(pos.width, pos.height)
    addInput:SetAutoFocus(false)
    
    local label = addInput:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", addInput, "TOPLEFT", 0, 5)
    label:SetText("Add Spell/Item (name or ID):")
    
    addInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text:len() > 0 then
            FiltersUI:ShowSuggestions(text)
        else
            FiltersUI:HideSuggestions()
        end
    end)
    
    addInput:SetScript("OnEnterPressed", function()
        FiltersUI:AddFilterFromSuggestion()
    end)
    
    addInput:SetScript("OnKeyDown", function(self, key)
        if key == "DOWN" then
            FiltersUI:NavigateSuggestions(1)
        elseif key == "UP" then
            FiltersUI:NavigateSuggestions(-1)
        elseif key == "ESCAPE" then
            FiltersUI:HideSuggestions()
            self:ClearFocus()
        end
    end)
end

function FiltersUI:CreateSuggestionsFrame()
    suggestionsFrame = CreateFrame("Frame", nil, filtersFrame, "BackdropTemplate")
    suggestionsFrame:SetPoint("TOPLEFT", addInput, "BOTTOMLEFT", 0, -2)
    suggestionsFrame:SetSize(280, 200)
    suggestionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 8, right = 8, top = 8, bottom = 8}
    })
    suggestionsFrame:SetFrameStrata("DIALOG")
    suggestionsFrame:SetFrameLevel(100)
    suggestionsFrame:Hide()
    
    for i = 1, 10 do
        local btn = CreateFrame("Button", nil, suggestionsFrame)
        btn:SetSize(260, 20)
        btn:SetPoint("TOPLEFT", suggestionsFrame, "TOPLEFT", 10, -10 - ((i-1) * 20))
        btn:SetNormalTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
        btn:GetNormalTexture():SetAlpha(0)
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", btn, "LEFT", 2, 0)
        btn.icon = icon
        
        local text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        text:SetJustifyH("LEFT")
        text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        
        btn.text = text
        btn:Hide()
        suggestionButtons[i] = btn
    end
end

function FiltersUI:CreateAddButton()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local pos = layout.addButton or {x = 280, y = -20, width = 60, height = 25}
    
    addButton = CreateFrame("Button", nil, filtersFrame, "UIPanelButtonTemplate")
    addButton:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", pos.x, pos.y)
    addButton:SetSize(pos.width, pos.height)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        FiltersUI:AddFilterFromSuggestion()
    end)
end

function FiltersUI:CreateHelpNote()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local pos = layout.helpNote or {x = 20, y = -52, width = 360}
    
    if not filtersFrame then return end
    
    local helpFrame = CreateFrame("Frame", nil, filtersFrame)
    helpFrame:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", pos.x, pos.y)
    helpFrame:SetSize(pos.width, 15)
    
    local helpNote = helpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    helpNote:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 0, 0)
    helpNote:SetWidth(pos.width)
    helpNote:SetJustifyH("LEFT")
    helpNote:SetTextColor(0.7, 0.7, 0.7, 1)
    helpNote:SetText(pos.text or "Tip: If you can't find a spell in suggestions, try using its Spell ID instead")
end

function FiltersUI:CreateFiltersList()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local pos = layout.filtersList or {x = 20, y = -60, width = 360, height = 400}
    
    scrollFrame = CreateFrame("ScrollFrame", nil, filtersFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", pos.x, pos.y)
    scrollFrame:SetSize(pos.width, pos.height)
    
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(pos.width - 20, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    filtersList = scrollChild
end

function FiltersUI:CreateActionButtons()
    local layout = rawget(_G, "LayoutManager") and _G.LayoutManager:GetFiltersTabLayout() or {}
    local clearPos = layout.clearAllButton or {x = 20, y = -480, width = 80, height = 25}
    
    clearAllButton = CreateFrame("Button", nil, filtersFrame, "UIPanelButtonTemplate")
    clearAllButton:SetPoint("TOPLEFT", filtersFrame, "TOPLEFT", clearPos.x, clearPos.y)
    clearAllButton:SetSize(clearPos.width, clearPos.height)
    clearAllButton:SetText("Clear All")
    clearAllButton:SetScript("OnClick", function()
        FiltersUI:ClearAllFilters()
    end)
end

function FiltersUI:AddFilterFromSuggestion()
    if selectedSuggestionIndex > 0 and currentSuggestions[selectedSuggestionIndex] then
        local suggestion = currentSuggestions[selectedSuggestionIndex]
        self:AddValidatedFilter(suggestion.name, suggestion.id)
        if addInput then
            addInput:SetText("")
        end
        self:HideSuggestions()
    end
end

function FiltersUI:AddValidatedFilter(name, spellId)
    if not ReadyCooldownAlertDB then
        return
    end
    
    local currentFilters = self:ParseIgnoredSpells()
    local filterKey = name .. ":" .. spellId
    
    for _, existingFilter in ipairs(currentFilters) do
        if existingFilter == filterKey then
            return
        end
    end
    
    table.insert(currentFilters, filterKey)
    ReadyCooldownAlertDB.ignoredSpells = table.concat(currentFilters, ",")
    self:RefreshFiltersList()
end

function FiltersUI:ShowSuggestions(searchText)
    if not searchText or searchText:len() < 2 then
        self:HideSuggestions()
        return
    end
    
    local suggestions = self:FindSuggestions(searchText)
    currentSuggestions = suggestions
    selectedSuggestionIndex = 0
    
    if #suggestions == 0 then
        self:HideSuggestions()
        return
    end
    
    for i = 1, #suggestionButtons do
        suggestionButtons[i]:Hide()
    end
    
    local maxVisible = math.min(#suggestions, 10)
    for i = 1, maxVisible do
        local btn = suggestionButtons[i]
        local suggestion = suggestions[i]
        
        if btn and suggestion then
            local typeIcon = suggestion.type == "item" and "[I]" or "[S]"
            btn.text:SetText(typeIcon .. " " .. suggestion.name .. " (" .. suggestion.id .. ")")
            
            if suggestion.texture then
                btn.icon:SetTexture(suggestion.texture)
                btn.icon:Show()
            else
                local defaultTexture = suggestion.type == "item" 
                    and "Interface\\Icons\\INV_Misc_QuestionMark"
                    or "Interface\\Icons\\Spell_Magic_LesserInvisibilty"
                btn.icon:SetTexture(defaultTexture)
                btn.icon:Show()
            end
            
            btn:SetScript("OnClick", function()
                if addInput then
                    addInput:SetText(suggestion.name)
                end
                selectedSuggestionIndex = i
                FiltersUI:AddFilterFromSuggestion()
                FiltersUI:HideSuggestions()
            end)
            
            btn:Show()
        end
    end
    
    if suggestionsFrame then
        suggestionsFrame:Show()
    end
end

function FiltersUI:HideSuggestions()
    if suggestionsFrame then
        suggestionsFrame:Hide()
    end
    selectedSuggestionIndex = 0
end

function FiltersUI:NavigateSuggestions(direction)
    if #currentSuggestions == 0 then
        return
    end
    
    selectedSuggestionIndex = selectedSuggestionIndex + direction
    if selectedSuggestionIndex < 1 then
        selectedSuggestionIndex = #currentSuggestions
    elseif selectedSuggestionIndex > #currentSuggestions then
        selectedSuggestionIndex = 1
    end
    
    for i = 1, #suggestionButtons do
        if suggestionButtons[i]:IsShown() then
            if i == selectedSuggestionIndex then
                suggestionButtons[i]:GetNormalTexture():SetAlpha(0.3)
            else
                suggestionButtons[i]:GetNormalTexture():SetAlpha(0)
            end
        end
    end
end

function FiltersUI:FindSuggestions(searchText)
    local suggestions = {}
    local searchLower = searchText:lower()
    
    if tonumber(searchText) then
        local spellID = tonumber(searchText)
        local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
        if spellName then
            local spellTexture = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
            table.insert(suggestions, {
                name = spellName, 
                id = spellID, 
                texture = spellTexture,
                type = "spell"
            })
        end
    end
    
    self:SearchPlayerSpellbook(searchLower, suggestions)
    
    return suggestions
end

function FiltersUI:SearchPlayerSpellbook(searchLower, suggestions)
    if not C_SpellBook then return end
    
    for i = 1, 1000 do
        if #suggestions >= 15 then break end
        
        local spellBookItemInfo = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        if spellBookItemInfo and spellBookItemInfo.spellID then
            local spellName = spellBookItemInfo.name
            if spellName and spellName:lower():find(searchLower, 1, true) then
                local found = false
                for _, existing in ipairs(suggestions) do
                    if existing.id == spellBookItemInfo.spellID then
                        found = true
                        break
                    end
                end
                
                if not found then
                    local spellTexture = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellBookItemInfo.spellID)
                    table.insert(suggestions, {
                        name = spellName,
                        id = spellBookItemInfo.spellID,
                        texture = spellTexture,
                        type = "spell"
                    })
                end
            end
        end
    end
end

function FiltersUI:ParseIgnoredSpells()
    if not ReadyCooldownAlertDB or not ReadyCooldownAlertDB.ignoredSpells then
        return {}
    end
    
    local filters = {}
    for filter in ReadyCooldownAlertDB.ignoredSpells:gmatch("[^,]+") do
        local trimmed = filter:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(filters, trimmed)
        end
    end
    return filters
end

function FiltersUI:RefreshFiltersList()
    if not filtersList then
        return
    end
    
    for _, item in pairs(filterItems) do
        if item.frame then
            item.frame:Hide()
        end
    end
    filterItems = {}
    
    local filters = self:ParseIgnoredSpells()
    for i, filterStr in ipairs(filters) do
        self:CreateFilterItem(filterStr, i)
    end
end

function FiltersUI:CreateFilterItem(filterStr, index)
    local frame = CreateFrame("Frame", nil, filtersList)
    frame:SetSize(340, 25)
    frame:SetPoint("TOPLEFT", 0, -(index-1) * 27)
    
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", 5, 0)
    text:SetText(filterStr)
    
    local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(60, 20)
    deleteBtn:SetPoint("RIGHT", -5, 0)
    deleteBtn:SetText("Remove")
    deleteBtn:SetScript("OnClick", function()
        FiltersUI:RemoveFilter(index)
    end)
    
    filterItems[index] = {frame = frame, text = text, deleteBtn = deleteBtn}
end

function FiltersUI:RemoveFilter(index)
    if not ReadyCooldownAlertDB then
        return
    end
    
    local filters = self:ParseIgnoredSpells()
    table.remove(filters, index)
    ReadyCooldownAlertDB.ignoredSpells = table.concat(filters, ",")
    self:RefreshFiltersList()
end

function FiltersUI:ClearAllFilters()
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB.ignoredSpells = ""
        self:RefreshFiltersList()
    end
end

function FiltersUI:RefreshValues()
    if invertCheckbox and ReadyCooldownAlertDB then
        invertCheckbox:SetChecked(ReadyCooldownAlertDB.invertIgnored)
    end
    self:RefreshFiltersList()
end

_G.FiltersUI = FiltersUI
return FiltersUI
