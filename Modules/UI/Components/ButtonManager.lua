local ButtonManager = {}

-- Referencias locales
local buttons = {}

-- Crear todos los botones
function ButtonManager:CreateButtons(parentFrame, sliderCount)
    local mainButtonsPos = _G.LayoutManager:GetMainButtonsPosition(sliderCount)
    
    -- Crear botones principales (centrados)
    self:CreateMainButtons(parentFrame, mainButtonsPos)
    
    -- Crear botones inferiores (esquina inferior derecha)
    self:CreateBottomButtons(parentFrame)
    
    return buttons
end

-- Crear botones principales (Test, Unlock, Reset Anim)
function ButtonManager:CreateMainButtons(parentFrame, position)
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
        if _G.OptionsFrame then
            _G.OptionsFrame:OnTestClicked()
        end
    end)
    buttons.testButton = testButton
    
    -- Botón Unlock/Lock
    local unlockButton = CreateFrame("Button", "RCAUnlockButton", parentFrame, "GameMenuButtonTemplate")
    unlockButton:SetPoint("TOPLEFT", startX + buttonWidth + spacing, buttonY)
    unlockButton:SetSize(buttonWidth, buttonHeight)
    unlockButton:SetText("Unlock")
    unlockButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnUnlockClicked()
        end
    end)
    buttons.unlockButton = unlockButton
    
    -- Botón Reset Animation
    local resetAnimButton = CreateFrame("Button", "RCAResetAnimButton", parentFrame, "GameMenuButtonTemplate")
    resetAnimButton:SetPoint("TOPLEFT", startX + (buttonWidth * 2) + (spacing * 2), buttonY)
    resetAnimButton:SetSize(buttonWidth, buttonHeight)
    resetAnimButton:SetText("Reset Anim")
    resetAnimButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnResetAnimationClicked()
        end
    end)
    buttons.resetAnimButton = resetAnimButton
end

-- Crear botones inferiores (Reset All, Close)
function ButtonManager:CreateBottomButtons(parentFrame)
    local buttonWidth = _G.LayoutManager:GetConstants().BUTTON_WIDTH
    local buttonHeight = _G.LayoutManager:GetConstants().BUTTON_HEIGHT
    
    -- Botón Reset All (restaurar todo a valores por defecto)
    local resetAllButton = CreateFrame("Button", "RCAResetAllButton", parentFrame, "GameMenuButtonTemplate")
    resetAllButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -90, 20) -- 90px desde el borde derecho, 20px desde abajo
    resetAllButton:SetSize(buttonWidth, buttonHeight)
    resetAllButton:SetText("Reset All")
    resetAllButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnResetAllClicked()
        end
    end)
    buttons.resetAllButton = resetAllButton
    
    -- Botón Close
    local closeButton = CreateFrame("Button", "RCACloseButton", parentFrame, "GameMenuButtonTemplate")
    closeButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -10, 20) -- 10px desde el borde derecho, 20px desde abajo
    closeButton:SetSize(buttonWidth, buttonHeight)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        if _G.OptionsFrame then
            _G.OptionsFrame:OnCloseClicked()
        end
    end)
    buttons.closeButton = closeButton
end

-- Actualizar estado del botón unlock
function ButtonManager:UpdateUnlockButton(isEditingPosition)
    local button = buttons.unlockButton
    if button then
        if isEditingPosition then
            button:SetText("Lock")
        else
            button:SetText("Unlock")
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
