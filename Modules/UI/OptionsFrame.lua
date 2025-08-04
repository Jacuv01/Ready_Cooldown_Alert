local OptionsFrame = {}

-- Frame del panel de opciones
local optionsFrame = nil
local sliders = {}
local checkboxes = {}
local editBoxes = {}

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
        min = 0,
        max = 10,
        step = 0.1,
        default = 0
    }
}

-- Inicializar panel de opciones
function OptionsFrame:Initialize()
    if optionsFrame then
        return
    end
    
    -- Crear frame principal
    optionsFrame = CreateFrame("Frame", "ReadyCooldownAlertOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(400, 600)
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
    
    -- Crear botones
    self:CreateButtons()
    
    -- Inicialmente oculto
    optionsFrame:Hide()
end

-- Crear sliders de configuración
function OptionsFrame:CreateSliders()
    local yOffset = -40
    
    for i, config in ipairs(sliderConfigs) do
        local slider = CreateFrame("Slider", "RCASlider" .. i, optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, yOffset)
        slider:SetMinMaxValues(config.min, config.max)
        slider:SetValueStep(config.step)
        slider:SetObeyStepOnDrag(true)
        slider:SetWidth(200)
        
        -- Texto del slider
        slider.Text:SetText(config.label)
        slider.Low:SetText(config.min)
        slider.High:SetText(config.max)
        
        -- Valor actual
        slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
        
        -- Configurar valor
        local currentValue = (ReadyCooldownAlertDB and ReadyCooldownAlertDB[config.key]) or config.default
        slider:SetValue(currentValue)
        slider.valueText:SetText(string.format("%.1f", currentValue))
        
        -- Script de cambio
        slider:SetScript("OnValueChanged", function(self, value)
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB[config.key] = value
                self.valueText:SetText(string.format("%.1f", value))
                
                -- Notificar cambio de configuración
                OptionsFrame:OnConfigChanged(config.key, value)
            end
        end)
        
        sliders[config.key] = slider
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

-- Crear botones
function OptionsFrame:CreateButtons()
    local buttonHeight = 25
    local buttonWidth = 80
    local yOffset = -550
    
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
                local value = (ReadyCooldownAlertDB and ReadyCooldownAlertDB[config.key]) or config.default
                slider:SetValue(value)
                if slider.valueText then
                    slider.valueText:SetText(string.format("%.1f", value))
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
end

-- Callback cuando cambia la configuración
function OptionsFrame:OnConfigChanged(key, value)
    -- Notificar a otros módulos que la configuración cambió
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
    end
    if FilterProcessor then
        FilterProcessor:RefreshFilters()
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
    if MainFrame then
        local isLocked = MainFrame:IsLocked()
        MainFrame:SetLocked(not isLocked)
        
        local button = sliders.unlockButton
        if button then
            button:SetText(isLocked and "Lock" or "Unlock")
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
        ReadyCooldownAlertDB[config.key] = config.default
    end
    
    ReadyCooldownAlertDB.showSpellName = true
    ReadyCooldownAlertDB.invertIgnored = false
    ReadyCooldownAlertDB.ignoredSpells = ""
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- Notificar cambios
    self:OnConfigChanged("defaults", true)
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
