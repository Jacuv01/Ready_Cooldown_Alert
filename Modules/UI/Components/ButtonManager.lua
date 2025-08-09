local ButtonManager = {}

local buttons = {}

function ButtonManager:CreateButtons(parentFrame, sliderCount)
    self:CreatePositionButton(parentFrame)
    self:CreateAnimationButtons(parentFrame, sliderCount)
    return buttons
end

function ButtonManager:CreatePositionButton(parentFrame)
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager and LayoutManager:GetPositionButtonPosition() or {buttonWidth = 100, buttonHeight = 25}
    
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

function ButtonManager:CreateAnimationButtons(parentFrame, sliderCount)
    local animationSliderCount = sliderCount - 3
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager and LayoutManager:GetAnimationButtonsPosition(animationSliderCount) or 
                    {startX = 10, y = 100, buttonWidth = 80, buttonHeight = 25, spacing = 10}
    
    local startX = position.startX
    local buttonY = position.y
    local buttonWidth = position.buttonWidth
    local buttonHeight = position.buttonHeight
    local spacing = position.spacing
    
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
    buttons.resetAnimButton = resetAnimButton
end

function ButtonManager:UpdateUnlockButton(isUnlocked)
    local button = buttons.unlockButton
    if button then
        button:SetText(isUnlocked and "Lock" or "Unlock")
    end
end

function ButtonManager:UpdateEditButton(isEditing)
    local button = buttons.editSaveButton
    if button then
        button:SetText(isEditing and "Save" or "Edit")
    end
    self:UpdateTestButton(isEditing)
end

function ButtonManager:UpdateTestButton(isEditing)
    local button = buttons.testButton
    if button then
        button:SetEnabled(not isEditing)
        button:SetAlpha(isEditing and 0.5 or 1.0)
    end
end

function ButtonManager:GetButtons()
    return buttons
end

function ButtonManager:GetButton(buttonName)
    return buttons[buttonName]
end

_G.ButtonManager = ButtonManager
return ButtonManager
