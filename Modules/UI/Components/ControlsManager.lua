local ControlsManager = {}

local checkboxes = {}
local dropdowns = {}

function ControlsManager:CreateAllControls(parentFrame, sliderCount)
    self:CreateDropdowns(parentFrame)
    self:CreateCheckboxes(parentFrame, sliderCount)
    
    return {
        checkboxes = checkboxes,
        dropdowns = dropdowns
    }
end

function ControlsManager:CreateCheckboxes(parentFrame, sliderCount)
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager:GetShowSpellNamesCheckboxPosition()
    
    local showNameCB = CreateFrame("CheckButton", "RCAShowNameCheckbox", parentFrame, "ChatConfigCheckButtonTemplate")
    showNameCB:SetPoint("TOPLEFT", position.x, position.y)
    showNameCB.Text:SetText("Show Spell Names")
    
    local showSpellName = ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName
    if showSpellName == nil then showSpellName = true end
    showNameCB:SetChecked(showSpellName)
    
    showNameCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.showSpellName = self:GetChecked()
            local OptionsFrame = rawget(_G, "OptionsFrame")
            if OptionsFrame then
                OptionsFrame:OnConfigChanged("showSpellName", self:GetChecked())
            end
        end
    end)
    
    checkboxes.showSpellName = showNameCB
end

local function InitializeAnimationDropdown(self, level)
    local AnimationData = rawget(_G, "AnimationData")
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
            
            local OptionsLogic = rawget(_G, "OptionsLogic")
            local previousAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation
            
            if previousAnimation and previousAnimation ~= animation.value and OptionsLogic then
                OptionsLogic:SaveAnimationConfiguration(previousAnimation)
            end
            
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB.selectedAnimation = animation.value
                local OptionsFrame = rawget(_G, "OptionsFrame")
                if OptionsFrame then
                    OptionsFrame:OnConfigChanged("selectedAnimation", animation.value)
                end
            end
            
            if OptionsLogic then
                OptionsLogic:LoadAnimationConfiguration(animation.value)
            end
            
            C_Timer.After(0.05, function()
                local OptionsFrame = rawget(_G, "OptionsFrame")
                local SliderManager = rawget(_G, "SliderManager")
                
                if OptionsFrame then
                    OptionsFrame:RefreshValues()
                end
                if SliderManager then
                    SliderManager:RefreshValues()
                end
            end)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

function ControlsManager:CreateDropdowns(parentFrame)
    if not parentFrame then
        return
    end
    
    local LayoutManager = rawget(_G, "LayoutManager")
    local position = LayoutManager:GetDropdownsPosition()
    local yOffset = position.startY
    
    local animationLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    animationLabel:SetPoint("TOPLEFT", position.x, yOffset)
    animationLabel:SetText("Animation Type:")
    
    local animationDropdown = CreateFrame("Frame", "RCAAnimationDropdown", parentFrame, "UIDropDownMenuTemplate")
    animationDropdown:SetPoint("LEFT", animationLabel, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(animationDropdown, 200)
    UIDropDownMenu_SetText(animationDropdown, "Select Animation")
    
    UIDropDownMenu_Initialize(animationDropdown, InitializeAnimationDropdown)
    
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    UIDropDownMenu_SetSelectedValue(animationDropdown, selectedAnimation)
    
    local AnimationData = rawget(_G, "AnimationData")
    if AnimationData then
        local animationData = AnimationData:GetAnimation(selectedAnimation)
        if animationData then
            UIDropDownMenu_SetText(animationDropdown, animationData.name)
        end
    end
    
    dropdowns.animationType = animationDropdown
end

function ControlsManager:RefreshValues()
    if checkboxes.showSpellName then
        local OptionsLogic = rawget(_G, "OptionsLogic")
        local showSpellName = OptionsLogic and OptionsLogic:GetConfigValue("showSpellName")
        if showSpellName == nil then showSpellName = true end
        checkboxes.showSpellName:SetChecked(showSpellName and true or false)
    end
    
    if dropdowns.animationType then
        local OptionsLogic = rawget(_G, "OptionsLogic")
        local selectedAnimation = (OptionsLogic and OptionsLogic:GetConfigValue("selectedAnimation")) or "pulse"
        UIDropDownMenu_SetSelectedValue(dropdowns.animationType, selectedAnimation)
        
        local AnimationData = rawget(_G, "AnimationData")
        if AnimationData then
            local animationData = AnimationData:GetAnimation(selectedAnimation)
            if animationData then
                UIDropDownMenu_SetText(dropdowns.animationType, animationData.name)
            end
        end
    end
end

function ControlsManager:GetControls()
    return {
        checkboxes = checkboxes,
        dropdowns = dropdowns
    }
end

_G.ControlsManager = ControlsManager
return ControlsManager
