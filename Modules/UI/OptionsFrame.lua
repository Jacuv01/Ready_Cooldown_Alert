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
    self:SetPositionSlidersEnabled(false)
    
    -- Inicialmente oculto
    --optionsFrame:Hide()
end

-- Crear sliders de configuración
function OptionsFrame:CreateSliders()
    local yOffset = -80
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    for i, config in ipairs(sliderConfigs) do
        local slider = CreateFrame("Slider", "RCASlider" .. i, optionsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOP", 0, yOffset)
        
        -- Configurar valores dinámicos usando OptionsLogic
        local minVal, maxVal, defaultVal = _G.OptionsLogic:CalculateDynamicValues(config)
        
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(config.step)
        slider:SetObeyStepOnDrag(true)
        slider:SetWidth(300)
        
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
        
        -- Desactivar sliders de posición por defecto usando OptionsLogic
        if _G.OptionsLogic and _G.OptionsLogic:ShouldSliderBeDisabled(config.key) then
            slider:SetEnabled(false)
            slider:SetAlpha(0.5)
        end
        
        yOffset = yOffset - 50
    end
end

-- Crear checkboxes
function OptionsFrame:CreateCheckboxes()
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    -- Calcular posición debajo de los botones centrados
    -- Los sliders terminan en: -80 - (#sliderConfigs * 50)
    -- Los botones están 30px después: slidersEndPosition - 30
    -- Los checkboxes van 40px después de los botones: slidersEndPosition - 30 - 25 - 40
    local slidersEndPosition = -80 - (#sliderConfigs * 50)
    local yOffset = slidersEndPosition - 30 - 25 - 40 -- Después de sliders, botones y separación
    
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
    
    -- Calcular posición debajo de los checkboxes
    -- Los checkboxes están en: slidersEndPosition - 30 - 25 - 40
    -- Y ocupan 60px (30px cada uno), así que editBoxes van después
    local slidersEndPosition = -80 - (#sliderConfigs * 50)
    local yOffset = slidersEndPosition - 30 - 25 - 40 - 60 -- Después de sliders, botones, checkboxes
    
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
            
            -- Actualizar sliders con configuración específica de la animación seleccionada
            OptionsFrame:UpdateSlidersForAnimation(animation.value)
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
    
    -- Actualizar sliders para la animación seleccionada inicialmente
    self:UpdateSlidersForAnimation(selectedAnimation)
end

-- Crear botones
function OptionsFrame:CreateButtons()
    local buttonHeight = 25
    local buttonWidth = 75
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    -- Calcular posición justo después de los sliders
    -- Los sliders empiezan en -80 y cada uno ocupa 50px de altura
    local slidersEndPosition = -80 - (#sliderConfigs * 50)
    local firstButtonRowY = slidersEndPosition - 30 -- 30px de separación después de los sliders
    
    -- PRIMERA FILA: Test, Unlock, Reset Anim (justo después de los sliders - CENTRADOS)
    
    -- Calcular posición centrada para 3 botones
    local totalButtonsWidth = (buttonWidth * 3) + (10 * 2) -- 3 botones + 2 espacios de separación
    local startX = (400 - totalButtonsWidth) / 2 -- Centrar en la ventana de 400px de ancho
    
    -- Botón Test
    local testButton = CreateFrame("Button", "RCATestButton", optionsFrame, "GameMenuButtonTemplate")
    testButton:SetPoint("TOPLEFT", startX, firstButtonRowY)
    testButton:SetSize(buttonWidth, buttonHeight)
    testButton:SetText("Test")
    testButton:SetScript("OnClick", function()
        OptionsFrame:OnTestClicked()
    end)
    
    -- Botón Unlock/Lock
    local unlockButton = CreateFrame("Button", "RCAUnlockButton", optionsFrame, "GameMenuButtonTemplate")
    unlockButton:SetPoint("TOPLEFT", startX + buttonWidth + 10, firstButtonRowY) -- Después del Test + separación
    unlockButton:SetSize(buttonWidth, buttonHeight)
    unlockButton:SetText("Unlock")
    unlockButton:SetScript("OnClick", function()
        OptionsFrame:OnUnlockClicked()
    end)
    
    -- Botón Reset Animation (restaurar valores de animación actual)
    local resetAnimButton = CreateFrame("Button", "RCAResetAnimButton", optionsFrame, "GameMenuButtonTemplate")
    resetAnimButton:SetPoint("TOPLEFT", startX + (buttonWidth * 2) + 20, firstButtonRowY) -- Después del Unlock + separación
    resetAnimButton:SetSize(buttonWidth, buttonHeight)
    resetAnimButton:SetText("Reset Anim")
    resetAnimButton:SetScript("OnClick", function()
        OptionsFrame:OnResetAnimationClicked()
    end)
    
    -- SEGUNDA FILA: Reset All y Close (en la parte inferior derecha)
    local bottomRightY = -870 -- Cerca del borde inferior de la ventana (altura 900px)
    
    -- Botón Reset All (restaurar todo a valores por defecto)
    local resetAllButton = CreateFrame("Button", "RCAResetAllButton", optionsFrame, "GameMenuButtonTemplate")
    resetAllButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -90, 20) -- 90px desde el borde derecho, 20px desde abajo
    resetAllButton:SetSize(buttonWidth, buttonHeight)
    resetAllButton:SetText("Reset All")
    resetAllButton:SetScript("OnClick", function()
        OptionsFrame:OnResetAllClicked()
    end)
    
    -- Botón Close
    local closeButton = CreateFrame("Button", "RCACloseButton", optionsFrame, "GameMenuButtonTemplate")
    closeButton:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -10, 20) -- 10px desde el borde derecho, 20px desde abajo
    closeButton:SetSize(buttonWidth, buttonHeight)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        OptionsFrame:OnCloseClicked()
    end)
    
    -- Guardar referencias
    sliders.testButton = testButton
    sliders.unlockButton = unlockButton
    sliders.resetAnimButton = resetAnimButton
    sliders.resetAllButton = resetAllButton
    sliders.closeButton = closeButton
end

-- Activar/Desactivar sliders de posición
function OptionsFrame:SetPositionSlidersEnabled(enabled)
    if sliders.positionX then
        sliders.positionX:SetEnabled(enabled)
        -- Cambiar la apariencia visual para mostrar el estado
        if enabled then
            sliders.positionX:SetAlpha(1.0)
        else
            sliders.positionX:SetAlpha(0.5)
        end
    end
    
    if sliders.positionY then
        sliders.positionY:SetEnabled(enabled)
        -- Cambiar la apariencia visual para mostrar el estado
        if enabled then
            sliders.positionY:SetAlpha(1.0)
        else
            sliders.positionY:SetAlpha(0.5)
        end
    end
    
    isEditingPosition = enabled
end

-- Verificar si está en modo de edición de posición
function OptionsFrame:IsEditingPosition()
    return isEditingPosition
end

-- Actualizar sliders según la animación seleccionada
function OptionsFrame:UpdateSlidersForAnimation(animationType)
    if not AnimationData or not _G.OptionsLogic then
        return
    end
    
    -- Obtener la configuración de la animación seleccionada
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData then
        return
    end
    
    -- Obtener configuraciones actuales de sliders
    local sliderConfigs = _G.OptionsLogic:GetSliderConfigs()
    
    -- Actualizar cada slider según si es relevante para esta animación
    for _, config in ipairs(sliderConfigs) do
        local slider = sliders[config.key]
        if slider then
            local isRelevant = self:IsSliderRelevantForAnimation(config.key, animationType)
            
            if isRelevant then
                -- Mostrar slider y actualizar su valor si tiene configuración específica
                slider:Show()
                
                -- Reactivar slider si no es de posición (los de posición se manejan por separado)
                if not _G.OptionsLogic:ShouldSliderBeDisabled(config.key) then
                    slider:SetEnabled(true)
                    slider:SetAlpha(1.0)
                end
                
                -- Si la animación tiene valores específicos para este slider, aplicarlos
                local animationSpecificValue = self:GetAnimationSpecificValue(animationType, config.key)
                if animationSpecificValue then
                    slider:SetValue(animationSpecificValue)
                    if slider.valueText then
                        slider.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, animationSpecificValue))
                    end
                end
                
                -- Actualizar el color del texto para indicar que es específico de la animación
                if slider.Text then
                    if animationSpecificValue then
                        slider.Text:SetTextColor(1, 0.82, 0) -- Dorado para valores específicos
                    else
                        slider.Text:SetTextColor(1, 1, 1) -- Blanco para valores generales
                    end
                end
            else
                -- Desactivar sliders no relevantes para esta animación (excepto posición que tiene su propia lógica)
                if not _G.OptionsLogic:ShouldSliderBeDisabled(config.key) then
                    slider:SetAlpha(0.3)
                    slider:SetEnabled(false)
                else
                    -- Los sliders de posición mantienen su estado actual (controlado por el botón unlock)
                end
            end
        end
    end
end

-- Verificar si un slider es relevante para una animación específica
function OptionsFrame:IsSliderRelevantForAnimation(sliderKey, animationType)
    -- Mapeo de qué sliders son relevantes para cada animación
    local animationRelevantSliders = {
        pulse = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        bounce = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        fade = {"fadeInTime", "fadeOutTime", "maxAlpha", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        zoom = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        glow = {"fadeInTime", "fadeOutTime", "maxAlpha", "iconSize", "holdTime", "remainingCooldownWhenNotified"}
    }
    
    local relevantSliders = animationRelevantSliders[animationType]
    if not relevantSliders then
        return true -- Si no hay mapeo específico, mostrar todos
    end
    
    -- Verificar si el slider está en la lista de relevantes
    for _, relevantSlider in ipairs(relevantSliders) do
        if relevantSlider == sliderKey then
            return true
        end
    end
    
    return false
end

-- Obtener valor específico de una animación para un slider
function OptionsFrame:GetAnimationSpecificValue(animationType, sliderKey)
    if not AnimationData then
        return nil
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return nil
    end
    
    return animationData.defaultValues[sliderKey]
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
        self:SetPositionSlidersEnabled(true)
    else
        button:SetText("Unlock")
        self:SetPositionSlidersEnabled(false)
    end
end

-- Manejar click en botón Defaults (ahora Reset Animation)
function OptionsFrame:OnResetAnimationClicked()
    -- Obtener la animación actualmente seleccionada
    local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    
    -- Delegar a OptionsLogic para restaurar valores de la animación actual
    if _G.OptionsLogic then
        _G.OptionsLogic:RestoreAnimationDefaults(currentAnimation)
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- Actualizar sliders específicamente para la animación actual
    self:UpdateSlidersForAnimation(currentAnimation)
end

-- Manejar click en botón Reset All (restaurar todo)
function OptionsFrame:OnResetAllClicked()
    -- Delegar a OptionsLogic para restaurar TODOS los valores
    if _G.OptionsLogic then
        _G.OptionsLogic:RestoreDefaults()
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- La animación habrá cambiado a "pulse", actualizar sliders
    local newAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    self:UpdateSlidersForAnimation(newAnimation)
end

-- Mantener función legacy para compatibilidad
function OptionsFrame:OnDefaultsClicked()
    -- Redirigir a la nueva función de reset de animación
    self:OnResetAnimationClicked()
end

-- Manejar click en botón Close
function OptionsFrame:OnCloseClicked()
    -- Si está en modo edición (unlocked), hacer lock primero
    if isEditingPosition and _G.OptionsLogic then
        local newState = _G.OptionsLogic:OnCloseClicked(isEditingPosition)
        isEditingPosition = newState
        
        -- Actualizar el botón unlock para mostrar el estado correcto
        local unlockButton = sliders.unlockButton
        if unlockButton then
            unlockButton:SetText("Unlock")
            self:SetPositionSlidersEnabled(false)
        end
    end
    
    -- Cerrar la ventana
    if optionsFrame then
        optionsFrame:Hide()
    end
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
