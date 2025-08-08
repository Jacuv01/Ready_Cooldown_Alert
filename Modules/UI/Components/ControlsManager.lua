local ControlsManager = {}

-- Referencias locales
local checkboxes = {}
local editBoxes = {}
local dropdowns = {}

-- Crear todos los controls (checkboxes, editboxes, dropdowns)
function ControlsManager:CreateAllControls(parentFrame, sliderCount)
    self:CreateDropdowns(parentFrame)
    self:CreateCheckboxes(parentFrame, sliderCount)
    self:CreateEditBoxes(parentFrame, sliderCount)
    
    return {
        checkboxes = checkboxes,
        editBoxes = editBoxes,
        dropdowns = dropdowns
    }
end

-- Crear checkboxes
function ControlsManager:CreateCheckboxes(parentFrame, sliderCount)
    local position = _G.LayoutManager:GetCheckboxesPosition(sliderCount)
    local yOffset = position.startY
    
    -- Checkbox para mostrar nombres de hechizos
    local showNameCB = CreateFrame("CheckButton", "RCAShowNameCheckbox", parentFrame, "ChatConfigCheckButtonTemplate")
    showNameCB:SetPoint("TOPLEFT", position.x, yOffset)
    showNameCB.Text:SetText("Show Spell Names")
    
    -- Configurar valor inicial
    local showSpellName = ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName
    if showSpellName == nil then showSpellName = true end
    showNameCB:SetChecked(showSpellName)
    
    showNameCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.showSpellName = self:GetChecked()
            if _G.OptionsFrame then
                _G.OptionsFrame:OnConfigChanged("showSpellName", self:GetChecked())
            end
        end
    end)
    
    checkboxes.showSpellName = showNameCB
    yOffset = yOffset - position.spacing
    
    -- Checkbox para invertir filtros
    local invertCB = CreateFrame("CheckButton", "RCAInvertFilterCheckbox", parentFrame, "ChatConfigCheckButtonTemplate")
    invertCB:SetPoint("TOPLEFT", position.x, yOffset)
    invertCB.Text:SetText("Invert Filter (Whitelist mode)")
    
    local invertIgnored = ReadyCooldownAlertDB and ReadyCooldownAlertDB.invertIgnored or false
    invertCB:SetChecked(invertIgnored)
    
    invertCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.invertIgnored = self:GetChecked()
            if _G.OptionsFrame then
                _G.OptionsFrame:OnConfigChanged("invertIgnored", self:GetChecked())
            end
        end
    end)
    
    checkboxes.invertIgnored = invertCB
end

-- Crear edit boxes
function ControlsManager:CreateEditBoxes(parentFrame, sliderCount)
    local position = _G.LayoutManager:GetEditBoxesPosition(sliderCount)
    local yOffset = position.startY
    
    -- Label para ignored spells
    local ignoredLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ignoredLabel:SetPoint("TOPLEFT", position.x, yOffset)
    ignoredLabel:SetText("Ignored Spells (comma separated):")
    
    -- EditBox para hechizos ignorados
    local ignoredEditBox = CreateFrame("EditBox", "RCAIgnoredSpellsEditBox", parentFrame, "InputBoxTemplate")
    ignoredEditBox:SetPoint("TOPLEFT", position.x, yOffset - 20)
    ignoredEditBox:SetSize(350, 20)
    ignoredEditBox:SetAutoFocus(false)
    ignoredEditBox:SetMaxLetters(0) -- Sin límite
    
    -- Configurar valor inicial
    local ignoredSpells = ReadyCooldownAlertDB and ReadyCooldownAlertDB.ignoredSpells or ""
    ignoredEditBox:SetText(ignoredSpells)
    
    ignoredEditBox:SetScript("OnEnterPressed", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.ignoredSpells = self:GetText()
            if _G.OptionsFrame then
                _G.OptionsFrame:OnConfigChanged("ignoredSpells", self:GetText())
            end
        end
        self:ClearFocus()
    end)
    
    ignoredEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    editBoxes.ignoredSpells = ignoredEditBox
end

-- Función para poblar el dropdown de animaciones
local function InitializeAnimationDropdown(self, level)
    if not _G.AnimationData then
        return
    end
    
    local animationList = _G.AnimationData:GetAnimationList()
    for _, animation in ipairs(animationList) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = animation.text
        info.value = animation.value
        info.tooltipTitle = animation.text
        info.tooltipText = animation.tooltip
        info.func = function()
            UIDropDownMenu_SetSelectedValue(dropdowns.animationType, animation.value)
            UIDropDownMenu_SetText(dropdowns.animationType, animation.text)
            
            -- PRIMERO: Guardar configuración actual ANTES de cambiar (si hay una animación previa)
            local previousAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation
            if previousAnimation and previousAnimation ~= animation.value and _G.OptionsLogic then
                _G.OptionsLogic:SaveAnimationConfiguration(previousAnimation)
                print("|cff00ff00RCA Debug|r: Guardando configuración de", previousAnimation, "antes de cambiar a", animation.value)
            end
            
            -- SEGUNDO: Guardar nueva selección
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB.selectedAnimation = animation.value
                print("|cff00ff00RCA Debug|r: Updated selectedAnimation to", animation.value)
                if _G.OptionsFrame then
                    _G.OptionsFrame:OnConfigChanged("selectedAnimation", animation.value)
                end
            end
            
            -- TERCERO: Cargar configuración específica de la nueva animación seleccionada
            if _G.OptionsLogic then
                _G.OptionsLogic:LoadAnimationConfiguration(animation.value)
            end
            
            -- CUARTO: Refrescar valores en la interfaz DESPUÉS de cargar (con pequeño delay para timing)
            C_Timer.After(0.05, function()
                if _G.OptionsFrame then
                    _G.OptionsFrame:RefreshValues()
                end
                if _G.SliderManager then
                    _G.SliderManager:RefreshValues()
                end
                print("|cff00ff00RCA Debug|r: UI refreshed for animation", animation.value)
            end)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Crear dropdowns
function ControlsManager:CreateDropdowns(parentFrame)
    if not parentFrame then
        return
    end
    
    local position = _G.LayoutManager:GetDropdownsPosition()
    local yOffset = position.startY
    
    -- Label para animación
    local animationLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    animationLabel:SetPoint("TOPLEFT", position.x, yOffset)
    animationLabel:SetText("Animation Type:")
    
    -- Crear dropdown para tipo de animación
    local animationDropdown = CreateFrame("Frame", "RCAAnimationDropdown", parentFrame, "UIDropDownMenuTemplate")
    animationDropdown:SetPoint("LEFT", animationLabel, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(animationDropdown, 200)
    UIDropDownMenu_SetText(animationDropdown, "Select Animation")
    
    -- Inicializar dropdown con la función externa
    UIDropDownMenu_Initialize(animationDropdown, InitializeAnimationDropdown)
    
    -- Configurar valor inicial
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    UIDropDownMenu_SetSelectedValue(animationDropdown, selectedAnimation)
    
    -- Obtener el nombre de la animación para mostrar
    if _G.AnimationData then
        local animationData = _G.AnimationData:GetAnimation(selectedAnimation)
        if animationData then
            UIDropDownMenu_SetText(animationDropdown, animationData.name)
        end
    end
    
    dropdowns.animationType = animationDropdown
end

-- Actualizar valores en la interfaz
function ControlsManager:RefreshValues()
    -- Actualizar checkboxes
    if checkboxes.showSpellName and _G.OptionsLogic then
        local showSpellName = _G.OptionsLogic:GetConfigValue("showSpellName")
        if showSpellName == nil then showSpellName = true end
        checkboxes.showSpellName:SetChecked(showSpellName and true or false)
    end
    
    if checkboxes.invertIgnored and _G.OptionsLogic then
        local invertIgnored = _G.OptionsLogic:GetConfigValue("invertIgnored") or false
        checkboxes.invertIgnored:SetChecked(invertIgnored and true or false)
    end
    
    -- Actualizar edit boxes
    if editBoxes.ignoredSpells and _G.OptionsLogic then
        local ignoredSpells = _G.OptionsLogic:GetConfigValue("ignoredSpells") or ""
        editBoxes.ignoredSpells:SetText(tostring(ignoredSpells))
    end
    
    -- Actualizar dropdowns
    if dropdowns.animationType and _G.OptionsLogic then
        local selectedAnimation = _G.OptionsLogic:GetConfigValue("selectedAnimation") or "pulse"
        UIDropDownMenu_SetSelectedValue(dropdowns.animationType, selectedAnimation)
        
        -- Actualizar texto mostrado
        if _G.AnimationData then
            local animationData = _G.AnimationData:GetAnimation(selectedAnimation)
            if animationData then
                UIDropDownMenu_SetText(dropdowns.animationType, animationData.name)
            end
        end
    end
end

-- Obtener referencias de controls
function ControlsManager:GetControls()
    return {
        checkboxes = checkboxes,
        editBoxes = editBoxes,
        dropdowns = dropdowns
    }
end

-- Exportar globalmente para WoW addon system
_G.ControlsManager = ControlsManager

return ControlsManager
