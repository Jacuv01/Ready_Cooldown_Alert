local ButtonManager = {}

-- Referencias locales
local buttons = {}

-- Crear todos los botones en el nuevo layout
function ButtonManager:CreateButtons(parentFrame, sliderCount)
    -- Crear botón de posición (Unlock/Lock) en la sección superior
    self:CreatePositionButton(parentFrame)
    
    -- Crear botones de animación (Test, Edit/Save, Reset) en la sección inferior
    self:CreateAnimationButtons(parentFrame, sliderCount)
    
    return buttons
end

-- Crear botón Unlock/Lock para la sección de posición
function ButtonManager:CreatePositionButton(parentFrame)
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager and LayoutManager:GetPositionButtonPosition() or {buttonWidth = 100, buttonHeight = 25}
    
    -- Botón Unlock/Lock (para position e iconSize)
    local unlockButton = CreateFrame("Button", "RCAUnlockButton", parentFrame, "GameMenuButtonTemplate")
    unlockButton:SetPoint("TOPLEFT", position.x, position.y)
    unlockButton:SetSize(position.buttonWidth, position.buttonHeight)
    unlockButton:SetText("Unlock")
    unlockButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnUnlockClicked()
        end
    end)
    buttons.unlockButton = unlockButton
end

-- Crear botones de animación (Test, Edit/Save, Reset Anim)
function ButtonManager:CreateAnimationButtons(parentFrame, sliderCount)
    local animationSliderCount = sliderCount - 3 -- Restar los 3 sliders de posición
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager and LayoutManager:GetAnimationButtonsPosition(animationSliderCount) or 
                    {startX = 10, y = 100, buttonWidth = 80, buttonHeight = 25, spacing = 10}
    
    local startX = position.startX
    local buttonY = position.y
    local buttonWidth = position.buttonWidth
    local buttonHeight = position.buttonHeight
    local spacing = position.spacing
    
    -- Botón Test
    local testButton = CreateFrame("Button", "RCATestButton", parentFrame, "GameMenuButtonTemplate")
    testButton:SetPoint("TOPLEFT", startX, buttonY)
    testButton:SetSize(buttonWidth, buttonHeight)
    testButton:SetText("Test")
    testButton:SetScript("OnClick", function()
        if _G.OptionsLogic then
            _G.OptionsLogic:OnTestClicked()
        end
    end)
    buttons.testButton = testButton
    
    -- Botón Edit/Save
    local editSaveButton = CreateFrame("Button", "RCAEditSaveButton", parentFrame, "GameMenuButtonTemplate")
    editSaveButton:SetPoint("TOPLEFT", startX + (buttonWidth + spacing) * 1, buttonY)
    editSaveButton:SetSize(buttonWidth, buttonHeight)
    editSaveButton:SetText("Edit")
    editSaveButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnEditSaveClicked()
        end
    end)
    buttons.editSaveButton = editSaveButton
    
    -- Botón Reset Anim
    local resetAnimButton = CreateFrame("Button", "RCAResetAnimButton", parentFrame, "GameMenuButtonTemplate")
    resetAnimButton:SetPoint("TOPLEFT", startX + (buttonWidth + spacing) * 2, buttonY)
    resetAnimButton:SetSize(buttonWidth, buttonHeight)
    resetAnimButton:SetText("Reset Anim")
    resetAnimButton:SetScript("OnClick", function()
        local animationType = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
        if animationType and _G.OptionsLogic then
            _G.OptionsLogic:RestoreAnimationDefaults(animationType)
        end
    end)
    resetAnimButton:SetAttribute("confirmationText", "This will reset the selected animation to default values. Continue?")
    buttons.resetAnimButton = resetAnimButton
end

-- Actualizar estado del botón unlock/lock
function ButtonManager:UpdateUnlockButton(isUnlocked)
    local button = buttons.unlockButton
    if button then
        if isUnlocked then
            button:SetText("Lock")
        else
            button:SetText("Unlock")
        end
    end
end

-- Actualizar estado del botón edit/save
function ButtonManager:UpdateEditButton(isEditing)
    local button = buttons.editSaveButton -- Cambiar de editButton a editSaveButton
    if button then
        if isEditing then
            button:SetText("Save")
        else
            button:SetText("Edit")
        end
    end
    
    -- También actualizar el estado del botón Test
    self:UpdateTestButton(isEditing)
end

-- Actualizar estado del botón Test (deshabilitar durante edición)
function ButtonManager:UpdateTestButton(isEditing)
    local button = buttons.testButton
    if button then
        if isEditing then
            -- Deshabilitar el botón durante la edición
            button:SetEnabled(false)
            button:SetAlpha(0.5)
        else
            -- Habilitar el botón fuera de edición
            button:SetEnabled(true)
            button:SetAlpha(1.0)
        end
    end
end

-- Obtener referencia de botones
function ButtonManager:GetButtons()
    return buttons
end

-- Obtener botón específico
function ButtonManager:GetButton(buttonName)
    return buttons[buttonName]
end

-- Exportar globalmente para WoW addon system
_G.ButtonManager = ButtonManager

return ButtonManager
