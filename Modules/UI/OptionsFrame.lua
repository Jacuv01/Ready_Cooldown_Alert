local OptionsFrame = {}

-- Frame del panel de opciones
local optionsFrame = nil
local sliders = {}
local checkboxes = {}
local editBoxes = {}
local dropdowns = {}

-- Estado de edición de posición
local isEditingPosition = false

-- Inicializar panel de opciones
function OptionsFrame:Initialize()
    if optionsFrame then
        return
    end
    
    -- Crear frame principal
    optionsFrame = CreateFrame("MessageFrame", "ReadyCooldownAlertOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(400, 900)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    
    -- Título
    optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY")
    optionsFrame.title:SetFontObject("GameFontHighlight")
    optionsFrame.title:SetPoint("CENTER", optionsFrame.TitleBg, "CENTER", 0, 0)
    optionsFrame.title:SetText("Ready Cooldown Alert - Options")
    optionsFrame.title:SetTextColor(1, 0.82, 0, 1) -- Color dorado

        -- Crear dropdowns
    self:CreateDropdowns()
    
    -- Crear sliders
    self:CreateSliders()
    
    -- Crear checkboxes
    self:CreateCheckboxes()
    
    -- Crear edit boxes
    self:CreateEditBoxes()
    

    
    -- Crear botones
    self:CreateButtons()
    
    -- Inicializar estado de edición de posición
    isEditingPosition = false
    self:SetPositionSlidersVisible(false)
    
    -- Inicialmente oculto
    --optionsFrame:Hide()
end

-- Crear sliders de configuración
function OptionsFrame:CreateSliders()
    local yOffset = -200
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    for i, config in ipairs(sliderConfigs) do
        local slider = CreateFrame("Slider", "RCASlider" .. i, optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, yOffset)
        
        -- Configurar valores dinámicos usando OptionsLogic
        local minVal, maxVal, defaultVal = _G.OptionsLogic:CalculateDynamicValues(config)
        
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(config.step)
        slider:SetObeyStepOnDrag(true)
        slider:SetWidth(200)
        
        -- Texto del slider
        slider.Text:SetText(config.label)
        slider.Low:SetText(math.floor(minVal))
        slider.High:SetText(math.floor(maxVal))
        
        -- Valor actual
        slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        
        -- Configurar valor actual
        local currentValue = _G.OptionsLogic:GetConfigValue(config.key)
        slider:SetValue(currentValue)
        
        -- Formatear texto usando OptionsLogic
        slider.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, currentValue))
        
        -- Script de cambio
        slider:SetScript("OnValueChanged", function(self, value)
            if _G.OptionsLogic then
                local validatedValue, wasModified = _G.OptionsLogic:OnConfigChanged(config.key, value)
                
                -- Si el valor fue modificado, actualizar el slider
                if wasModified then
                    self:SetValue(validatedValue)
                end
                
                -- Actualizar texto mostrado
                self.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, validatedValue))
            end
        end)
        
        -- Habilitar scroll del mouse
        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel", function(self, delta)
            local currentValue = self:GetValue()
            local step = _G.OptionsLogic and _G.OptionsLogic:GetMouseWheelStep(config.key) or 0.1
            local newValue = currentValue + (delta * step)
            
            -- Aplicar límites
            local minVal, maxVal = self:GetMinMaxValues()
            newValue = math.max(minVal, math.min(maxVal, newValue))
            
            self:SetValue(newValue)
        end)
        
        sliders[config.key] = slider
        
        -- Ocultar sliders de posición por defecto usando OptionsLogic
        if _G.OptionsLogic and _G.OptionsLogic:ShouldSliderBeHidden(config.key) then
            slider:Hide()
        end
        
        yOffset = yOffset - 60
    end
end

-- Crear checkboxes
function OptionsFrame:CreateCheckboxes()
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    local yOffset = -40 - (#sliderConfigs * 60)
    
    -- Checkbox para mostrar nombres de hechizos
    local showNameCB = CreateFrame("CheckButton", "RCAShowNameCheckbox", optionsFrame, "ChatConfigCheckButtonTemplate")
    showNameCB:SetPoint("TOPLEFT", 20, yOffset)
    showNameCB.Text:SetText("Show Spell Names")
    
    -- Configurar valor inicial
    local showSpellName = ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName
    if showSpellName == nil then showSpellName = true end
    showNameCB:SetChecked(showSpellName)
    
    showNameCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.showSpellName = self:GetChecked()
            OptionsFrame:OnConfigChanged("showSpellName", self:GetChecked())
        end
    end)
    
    checkboxes.showSpellName = showNameCB
    yOffset = yOffset - 30
    
    -- Checkbox para invertir filtros
    local invertCB = CreateFrame("CheckButton", "RCAInvertFilterCheckbox", optionsFrame, "ChatConfigCheckButtonTemplate")
    invertCB:SetPoint("TOPLEFT", 20, yOffset)
    invertCB.Text:SetText("Invert Filter (Whitelist mode)")
    
    local invertIgnored = ReadyCooldownAlertDB and ReadyCooldownAlertDB.invertIgnored or false
    invertCB:SetChecked(invertIgnored)
    
    invertCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.invertIgnored = self:GetChecked()
            OptionsFrame:OnConfigChanged("invertIgnored", self:GetChecked())
        end
    end)
    
    checkboxes.invertIgnored = invertCB
end

-- Crear edit boxes
function OptionsFrame:CreateEditBoxes()
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    local yOffset = -40 - (#sliderConfigs * 60) - 80
    
    -- Label para ignored spells
    local ignoredLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ignoredLabel:SetPoint("TOPLEFT", 20, yOffset)
    ignoredLabel:SetText("Ignored Spells (comma separated):")
    
    -- EditBox para hechizos ignorados
    local ignoredEditBox = CreateFrame("EditBox", "RCAIgnoredSpellsEditBox", optionsFrame, "InputBoxTemplate")
    ignoredEditBox:SetPoint("TOPLEFT", 20, yOffset - 20)
    ignoredEditBox:SetSize(350, 20)
    ignoredEditBox:SetAutoFocus(false)
    ignoredEditBox:SetMaxLetters(0) -- Sin límite
    
    -- Configurar valor inicial
    local ignoredSpells = ReadyCooldownAlertDB and ReadyCooldownAlertDB.ignoredSpells or ""
    ignoredEditBox:SetText(ignoredSpells)
    
    ignoredEditBox:SetScript("OnEnterPressed", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.ignoredSpells = self:GetText()
            OptionsFrame:OnConfigChanged("ignoredSpells", self:GetText())
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
    if not AnimationData then
        return
    end
    
    local animationList = AnimationData:GetAnimationList()
    for _, animation in ipairs(animationList) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = animation.text
        info.value = animation.value
        info.tooltipTitle = animation.text
        info.tooltipText = animation.tooltip
        info.func = function()
            UIDropDownMenu_SetSelectedValue(dropdowns.animationType, animation.value)
            UIDropDownMenu_SetText(dropdowns.animationType, animation.text)
            
            -- Guardar selección
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB.selectedAnimation = animation.value
                OptionsFrame:OnConfigChanged("selectedAnimation", animation.value)
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Crear dropdowns
function OptionsFrame:CreateDropdowns()
    if not optionsFrame then
        return
    end
    
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    local yOffset = -40
    
    -- Label para animación
    local animationLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    animationLabel:SetPoint("TOPLEFT", 20, yOffset)
    animationLabel:SetText("Animation Type:")
    
    -- Crear dropdown para tipo de animación
    local animationDropdown = CreateFrame("Frame", "RCAAnimationDropdown", optionsFrame, "UIDropDownMenuTemplate")
    animationDropdown:SetPoint("LEFT", animationLabel, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(animationDropdown, 200)
    UIDropDownMenu_SetText(animationDropdown, "Select Animation")
    
    -- Inicializar dropdown con la función externa
    UIDropDownMenu_Initialize(animationDropdown, InitializeAnimationDropdown)
    
    -- Configurar valor inicial
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    UIDropDownMenu_SetSelectedValue(animationDropdown, selectedAnimation)
    
    -- Obtener el nombre de la animación para mostrar
    if AnimationData then
        local animationData = AnimationData:GetAnimation(selectedAnimation)
        if animationData then
            UIDropDownMenu_SetText(animationDropdown, animationData.name)
        end
    end
    
    dropdowns.animationType = animationDropdown
end

-- Crear botones
function OptionsFrame:CreateButtons()
    local buttonHeight = 25
    local buttonWidth = 80
    local yOffset = -650
    
    -- Botón Test
    local testButton = CreateFrame("Button", "RCATestButton", optionsFrame, "GameMenuButtonTemplate")
    testButton:SetPoint("TOPLEFT", 20, yOffset)
    testButton:SetSize(buttonWidth, buttonHeight)
    testButton:SetText("Test")
    testButton:SetScript("OnClick", function()
        OptionsFrame:OnTestClicked()
    end)
    
    -- Botón Unlock/Lock
    local unlockButton = CreateFrame("Button", "RCAUnlockButton", optionsFrame, "GameMenuButtonTemplate")
    unlockButton:SetPoint("TOPLEFT", 110, yOffset)
    unlockButton:SetSize(buttonWidth, buttonHeight)
    unlockButton:SetText("Unlock")
    unlockButton:SetScript("OnClick", function()
        OptionsFrame:OnUnlockClicked()
    end)
    
    -- Botón Defaults
    local defaultsButton = CreateFrame("Button", "RCADefaultsButton", optionsFrame, "GameMenuButtonTemplate")
    defaultsButton:SetPoint("TOPLEFT", 200, yOffset)
    defaultsButton:SetSize(buttonWidth, buttonHeight)
    defaultsButton:SetText("Defaults")
    defaultsButton:SetScript("OnClick", function()
        OptionsFrame:OnDefaultsClicked()
    end)
    
    -- Botón Close
    local closeButton = CreateFrame("Button", "RCACloseButton", optionsFrame, "GameMenuButtonTemplate")
    closeButton:SetPoint("TOPLEFT", 290, yOffset)
    closeButton:SetSize(buttonWidth, buttonHeight)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
    
    -- Guardar referencias
    sliders.testButton = testButton
    sliders.unlockButton = unlockButton
    sliders.defaultsButton = defaultsButton
    sliders.closeButton = closeButton
end

-- Mostrar/Ocultar sliders de posición
function OptionsFrame:SetPositionSlidersVisible(visible)
    if sliders.positionX then
        if visible then
            sliders.positionX:Show()
        else
            sliders.positionX:Hide()
        end
    end
    
    if sliders.positionY then
        if visible then
            sliders.positionY:Show()
        else
            sliders.positionY:Hide()
        end
    end
    
    isEditingPosition = visible
end

-- Verificar si está en modo de edición de posición
function OptionsFrame:IsEditingPosition()
    return isEditingPosition
end

-- Mostrar/Ocultar panel de opciones
function OptionsFrame:Toggle()
    if not optionsFrame then
        self:Initialize()
    end
    
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        self:RefreshValues()
        optionsFrame:Show()
    end
end

-- Actualizar valores en la interfaz
function OptionsFrame:RefreshValues()
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    -- Actualizar sliders
    for key, slider in pairs(sliders) do
        if type(slider) == "table" and slider.SetValue then
            local config = nil
            for _, c in ipairs(sliderConfigs) do
                if c.key == key then
                    config = c
                    break
                end
            end
            
            if config and _G.OptionsLogic then
                -- Recalcular valores dinámicos usando OptionsLogic
                local minVal, maxVal, defaultVal = _G.OptionsLogic:CalculateDynamicValues(config)
                
                -- Actualizar límites del slider
                slider:SetMinMaxValues(minVal, maxVal)
                slider.Low:SetText(tostring(math.floor(minVal)))
                slider.High:SetText(tostring(math.floor(maxVal)))
                
                local value = _G.OptionsLogic:GetConfigValue(config.key)
                slider:SetValue(value)
                if slider.valueText then
                    slider.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, value))
                end
            end
        end
    end
    
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
        if AnimationData then
            local animationData = AnimationData:GetAnimation(selectedAnimation)
            if animationData then
                UIDropDownMenu_SetText(dropdowns.animationType, animationData.name)
            end
        end
    end
end

-- Callback cuando cambia la configuración
function OptionsFrame:OnConfigChanged(key, value)
    -- Delegar toda la lógica a OptionsLogic
    if _G.OptionsLogic then
        return _G.OptionsLogic:OnConfigChanged(key, value)
    end
end

-- Manejar click en botón Test
function OptionsFrame:OnTestClicked()
    if _G.OptionsLogic then
        _G.OptionsLogic:OnTestClicked()
    end
end

-- Manejar click en botón Unlock/Lock
function OptionsFrame:OnUnlockClicked()
    local button = sliders.unlockButton
    if not button or not _G.OptionsLogic then return end
    
    -- Usar OptionsLogic para manejar la lógica
    local newState = _G.OptionsLogic:OnUnlockClicked(isEditingPosition)
    isEditingPosition = newState
    
    -- Actualizar interfaz
    if isEditingPosition then
        button:SetText("Lock")
        self:SetPositionSlidersVisible(true)
    else
        button:SetText("Unlock")
        self:SetPositionSlidersVisible(false)
    end
end

-- Manejar click en botón Defaults
function OptionsFrame:OnDefaultsClicked()
    -- Delegar a OptionsLogic
    if _G.OptionsLogic then
        _G.OptionsLogic:RestoreDefaults()
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
