local OptionsFrame = {}

-- Frame del panel de opciones
local optionsFrame = nil
local sliders = {}
local checkboxes = {}
local editBoxes = {}
local dropdowns = {}

-- Estado de edición de posición
local isEditingPosition = false

-- Configuración de sliders
local sliderConfigs = {
    {
        key = "fadeInTime",
        label = "Fade In Time",
        min = 0,
        max = 2,
        step = 0.1,
        default = 0.3
    },
    {
        key = "fadeOutTime", 
        label = "Fade Out Time",
        min = 0,
        max = 2,
        step = 0.1,
        default = 0.7
    },
    {
        key = "maxAlpha",
        label = "Max Alpha",
        min = 0,
        max = 1,
        step = 0.1,
        default = 0.7
    },
    {
        key = "animScale",
        label = "Animation Scale",
        min = 0.5,
        max = 3,
        step = 0.1,
        default = 1.5
    },
    {
        key = "iconSize",
        label = "Icon Size",
        min = 32,
        max = 256,
        step = 1,
        default = 75
    },
    {
        key = "holdTime",
        label = "Hold Time",
        min = 0,
        max = 5,
        step = 0.1,
        default = 0
    },
    {
        key = "remainingCooldownWhenNotified",
        label = "Alert When (seconds left)",
        min = 0.1,
        max = 10,
        step = 0.1,
        default = 1.0
    },
    {
        key = "positionX",
        label = "Position X",
        min = 0,
        max = 0, -- Se calculará dinámicamente
        step = 1,
        default = 0, -- Se calculará como centro de pantalla
        isDynamic = true
    },
    {
        key = "positionY", 
        label = "Position Y",
        min = 0,
        max = 0, -- Se calculará dinámicamente
        step = 1,
        default = 0, -- Se calculará como centro de pantalla
        isDynamic = true
    }
}

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
    optionsFrame.title:SetPoint("LEFT", optionsFrame.TitleBg, "LEFT", 5, 0)
    optionsFrame.title:SetText("Ready Cooldown Alert - Options")
    
    -- Crear sliders
    self:CreateSliders()
    
    -- Crear checkboxes
    self:CreateCheckboxes()
    
    -- Crear edit boxes
    self:CreateEditBoxes()
    
    -- Crear dropdowns
    self:CreateDropdowns()
    
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
    local yOffset = -40
    
    for i, config in ipairs(sliderConfigs) do
        local slider = CreateFrame("Slider", "RCASlider" .. i, optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, yOffset)
        
        -- Configurar valores dinámicos para posición
        local minVal = config.min
        local maxVal = config.max
        local defaultVal = config.default
        
        if config.isDynamic then
            if config.key == "positionX" then
                maxVal = GetScreenWidth() or 1920
                defaultVal = maxVal / 2 -- Centro de pantalla
            elseif config.key == "positionY" then
                maxVal = GetScreenHeight() or 1080
                defaultVal = maxVal / 2 -- Centro de pantalla
            end
        end
        
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
        
        -- Configurar valor (usar defaultVal calculado para posiciones)
        local currentValue = (ReadyCooldownAlertDB and ReadyCooldownAlertDB[config.key]) or defaultVal
        slider:SetValue(currentValue)
        
        -- Formatear texto según el tipo de slider
        if config.key == "positionX" or config.key == "positionY" then
            slider.valueText:SetText(tostring(math.floor(currentValue)))
        else
            slider.valueText:SetText(string.format("%.1f", currentValue))
        end
        
        -- Script de cambio
        slider:SetScript("OnValueChanged", function(self, value)
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB[config.key] = value
                
                -- Formatear texto según el tipo
                if config.key == "positionX" or config.key == "positionY" then
                    self.valueText:SetText(tostring(math.floor(value)))
                else
                    self.valueText:SetText(string.format("%.1f", value))
                end
                
                -- Notificar cambio de configuración
                OptionsFrame:OnConfigChanged(config.key, value)
            end
        end)
        
        -- Habilitar scroll del mouse
        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel", function(self, delta)
            local currentValue = self:GetValue()
            local step = config.step
            
            -- Para sliders de posición, usar pasos más grandes
            if config.key == "positionX" or config.key == "positionY" then
                step = 5 -- Mover 5 píxeles por scroll
            end
            
            local newValue = currentValue + (delta * step)
            
            -- Aplicar límites
            local minVal, maxVal = self:GetMinMaxValues()
            newValue = math.max(minVal, math.min(maxVal, newValue))
            
            self:SetValue(newValue)
        end)
        
        sliders[config.key] = slider
        
        -- Ocultar sliders de posición por defecto
        if config.key == "positionX" or config.key == "positionY" then
            slider:Hide()
        end
        
        yOffset = yOffset - 60
    end
end

-- Crear checkboxes
function OptionsFrame:CreateCheckboxes()
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

-- Crear dropdowns
function OptionsFrame:CreateDropdowns()
    local yOffset = -40 - (#sliderConfigs * 60) - 120
    
    -- Label para animación
    local animationLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    animationLabel:SetPoint("TOPLEFT", 20, yOffset)
    animationLabel:SetText("Animation Type:")
    
    -- Crear dropdown para tipo de animación
    local animationDropdown = CreateFrame("Frame", "RCAAnimationDropdown", optionsFrame, "UIDropDownMenuTemplate")
    animationDropdown:SetPoint("TOPLEFT", 20, yOffset - 25)
    UIDropDownMenu_SetWidth(animationDropdown, 200)
    UIDropDownMenu_SetText(animationDropdown, "Select Animation")
    
    -- Función para poblar el dropdown
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
                UIDropDownMenu_SetSelectedValue(animationDropdown, animation.value)
                UIDropDownMenu_SetText(animationDropdown, animation.text)
                
                -- Guardar selección
                if ReadyCooldownAlertDB then
                    ReadyCooldownAlertDB.selectedAnimation = animation.value
                    OptionsFrame:OnConfigChanged("selectedAnimation", animation.value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
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
            
            if config then
                -- Recalcular valores dinámicos
                local defaultVal = config.default
                if config.isDynamic then
                    if config.key == "positionX" then
                        defaultVal = (GetScreenWidth() or 1920) / 2
                        -- Actualizar límites del slider también
                        slider:SetMinMaxValues(0, GetScreenWidth() or 1920)
                        slider.High:SetText(tostring(math.floor(GetScreenWidth() or 1920)))
                    elseif config.key == "positionY" then
                        defaultVal = (GetScreenHeight() or 1080) / 2
                        -- Actualizar límites del slider también
                        slider:SetMinMaxValues(0, GetScreenHeight() or 1080)
                        slider.High:SetText(tostring(math.floor(GetScreenHeight() or 1080)))
                    end
                end
                
                local value = (ReadyCooldownAlertDB and ReadyCooldownAlertDB[config.key]) or defaultVal
                slider:SetValue(value)
                if slider.valueText then
                    if config.key == "positionX" or config.key == "positionY" then
                        slider.valueText:SetText(tostring(math.floor(value)))
                    else
                        slider.valueText:SetText(string.format("%.1f", value))
                    end
                end
            end
        end
    end
    
    -- Actualizar checkboxes
    if checkboxes.showSpellName then
        local showSpellName = ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName
        if showSpellName == nil then showSpellName = true end
        checkboxes.showSpellName:SetChecked(showSpellName)
    end
    
    if checkboxes.invertIgnored then
        local invertIgnored = ReadyCooldownAlertDB and ReadyCooldownAlertDB.invertIgnored or false
        checkboxes.invertIgnored:SetChecked(invertIgnored)
    end
    
    -- Actualizar edit boxes
    if editBoxes.ignoredSpells then
        local ignoredSpells = ReadyCooldownAlertDB and ReadyCooldownAlertDB.ignoredSpells or ""
        editBoxes.ignoredSpells:SetText(ignoredSpells)
    end
    
    -- Actualizar dropdowns
    if dropdowns.animationType then
        local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
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
    -- Validación especial para remainingCooldownWhenNotified
    if key == "remainingCooldownWhenNotified" and value <= 0 then
        -- Corregir valor a mínimo permitido
        ReadyCooldownAlertDB.remainingCooldownWhenNotified = 0.1
        if sliders[key] then
            sliders[key]:SetValue(0.1)
        end
        return
    end
    
    -- Notificar a otros módulos que la configuración cambió
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
    end
    if FilterProcessor then
        FilterProcessor:RefreshFilters()
    end
    
    -- Actualizar posición del MainFrame si cambió positionX o positionY
    if (key == "positionX" or key == "positionY") and MainFrame then
        MainFrame:UpdatePosition()
        
        -- Si estamos en modo de edición, asegurar que el icono siga visible
        if isEditingPosition then
            MainFrame:ShowForPositioning()
        end
    end
end

-- Manejar click en botón Test
function OptionsFrame:OnTestClicked()
    if AnimationProcessor then
        AnimationProcessor:TestAnimation()
    elseif MainFrame then
        MainFrame:TestAnimation()
    end
end

-- Manejar click en botón Unlock/Lock
function OptionsFrame:OnUnlockClicked()
    local button = sliders.unlockButton
    if not button then return end
    
    -- Cambiar estado de edición
    isEditingPosition = not isEditingPosition
    
    -- Actualizar texto del botón
    if isEditingPosition then
        button:SetText("Lock")
        self:SetPositionSlidersVisible(true)
        
        -- Mostrar icono para posicionamiento
        if MainFrame then
            MainFrame:ShowForPositioning()
        end
    else
        button:SetText("Unlock")
        self:SetPositionSlidersVisible(false)
        
        -- Ocultar icono
        if MainFrame then
            MainFrame:HideFromPositioning()
        end
    end
end

-- Manejar click en botón Defaults
function OptionsFrame:OnDefaultsClicked()
    -- Restaurar valores por defecto
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    for _, config in ipairs(sliderConfigs) do
        local defaultVal = config.default
        -- Calcular valores dinámicos para posición
        if config.isDynamic then
            if config.key == "positionX" then
                defaultVal = (GetScreenWidth() or 1920) / 2
            elseif config.key == "positionY" then
                defaultVal = (GetScreenHeight() or 1080) / 2
            end
        end
        ReadyCooldownAlertDB[config.key] = defaultVal
    end
    
    ReadyCooldownAlertDB.showSpellName = true
    ReadyCooldownAlertDB.invertIgnored = false
    ReadyCooldownAlertDB.ignoredSpells = ""
    ReadyCooldownAlertDB.selectedAnimation = "pulse"
    
    -- Validar que remainingCooldownWhenNotified no sea cero
    if ReadyCooldownAlertDB.remainingCooldownWhenNotified and ReadyCooldownAlertDB.remainingCooldownWhenNotified <= 0 then
        ReadyCooldownAlertDB.remainingCooldownWhenNotified = 1.0
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- Notificar cambios
    self:OnConfigChanged("defaults", true)
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
