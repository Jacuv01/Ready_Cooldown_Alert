local SliderManager = {}
local sliders = {}

function SliderManager:CreateSliders(parentFrame)
    local OptionsLogic = rawget(_G, "OptionsLogic")
    local sliderConfigs = OptionsLogic and OptionsLogic:GetSliderConfigs() or {}
    
    self:CreatePositionAndSizeSliders(parentFrame, sliderConfigs)
    self:CreateAnimationSliders(parentFrame, sliderConfigs)
    
    return sliders
end

function SliderManager:CreatePositionAndSizeSliders(parentFrame, sliderConfigs)
    local positionOrder = {"iconSize", "positionX", "positionY"}
    local LayoutManager = rawget(_G, "LayoutManager")
    local layoutInfo = LayoutManager:GetPositionSlidersPosition()
    local yOffset = layoutInfo.startY
    
    for i, sliderKey in ipairs(positionOrder) do
        for _, config in ipairs(sliderConfigs) do
            if config.key == sliderKey then
                local slider = self:CreateSingleSlider(parentFrame, config, i, yOffset)
                sliders[config.key] = slider
                yOffset = yOffset - layoutInfo.sliderHeight
                break
            end
        end
    end
end

function SliderManager:CreateAnimationSliders(parentFrame, sliderConfigs)
    local animationConfigs = {}
    
    for _, config in ipairs(sliderConfigs) do
        if config.key ~= "iconSize" and config.key ~= "positionX" and config.key ~= "positionY" then
            table.insert(animationConfigs, config)
        end
    end
    
    local LayoutManager = rawget(_G, "LayoutManager")
    local layoutInfo = LayoutManager:GetAnimationSlidersPosition(#animationConfigs)
    local yOffset = layoutInfo.startY
    
    for i, config in ipairs(animationConfigs) do
        local slider = self:CreateSingleSlider(parentFrame, config, i + 3, yOffset)
        sliders[config.key] = slider
        yOffset = yOffset - layoutInfo.sliderHeight
    end
end

function SliderManager:CreateSingleSlider(parentFrame, config, index, yOffset)
    local slider = CreateFrame("Slider", "RCASlider" .. index, parentFrame, "OptionsSliderTemplate")
    slider:SetPoint("TOP", 0, yOffset)
    
    local OptionsLogic = rawget(_G, "OptionsLogic")
    local minVal, maxVal, defaultVal = OptionsLogic:CalculateDynamicValues(config)
    
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(config.step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(300)
    
    self:SetupSliderTexts(slider, config, minVal, maxVal)
    self:SetupSliderValue(slider, config)
    self:SetupSliderEvents(slider, config)
    
    slider:SetEnabled(false)
    slider:SetAlpha(0.5)
    
    return slider
end

function SliderManager:SetupSliderTexts(slider, config, minVal, maxVal)
    slider.Text:SetText(config.label)
    slider.Low:SetText(math.floor(minVal))
    slider.High:SetText(math.floor(maxVal))
    
    slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
end

function SliderManager:SetupSliderValue(slider, config)
    local OptionsLogic = rawget(_G, "OptionsLogic")
    local currentValue = OptionsLogic:GetConfigValue(config.key)
    slider:SetValue(currentValue)
    slider.valueText:SetText(OptionsLogic:FormatSliderValue(config.key, currentValue))
end

function SliderManager:SetupSliderEvents(slider, config)
    slider:SetScript("OnValueChanged", function(self, value)
        local OptionsLogic = rawget(_G, "OptionsLogic")
        if OptionsLogic then
            local validatedValue, wasModified = OptionsLogic:OnConfigChanged(config.key, value)
            
            if wasModified then
                self:SetValue(validatedValue)
            end
            
            self.valueText:SetText(OptionsLogic:FormatSliderValue(config.key, validatedValue))
        end
    end)
    
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        if not self:IsEnabled() then
            return
        end
        
        local OptionsLogic = rawget(_G, "OptionsLogic")
        local currentValue = self:GetValue()
        local step = OptionsLogic and OptionsLogic:GetMouseWheelStep(config.key) or 0.1
        local newValue = currentValue + (delta * step)
        
        local minVal, maxVal = self:GetMinMaxValues()
        newValue = math.max(minVal, math.min(maxVal, newValue))
        
        self:SetValue(newValue)
    end)
end

function SliderManager:UpdateSlidersForAnimation(animationType)
    local AnimationData = rawget(_G, "AnimationData")
    local OptionsLogic = rawget(_G, "OptionsLogic")
    
    if not AnimationData or not OptionsLogic then
        return
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData then
        return
    end
    
    local sliderConfigs = OptionsLogic:GetSliderConfigs()
    
    for _, config in ipairs(sliderConfigs) do
        local slider = sliders[config.key]
        if slider then
            self:UpdateSliderForAnimation(slider, config, animationType)
        end
    end
end

function SliderManager:UpdateSliderForAnimation(slider, config, animationType)
    local isRelevant = self:IsSliderRelevantForAnimation(config.key, animationType)
    
    if isRelevant then
        slider:Show()
        
        local animationSpecificValue = self:GetAnimationSpecificValue(animationType, config.key)
        if animationSpecificValue then
            slider:SetValue(animationSpecificValue)
            if slider.valueText then
                local OptionsLogic = rawget(_G, "OptionsLogic")
                slider.valueText:SetText(OptionsLogic:FormatSliderValue(config.key, animationSpecificValue))
            end
        end
        
        if slider.Text then
            if animationSpecificValue then
                slider.Text:SetTextColor(1, 0.82, 0)
            else
                slider.Text:SetTextColor(1, 1, 1)
            end
        end
    else
        slider:Hide()
    end
end

function SliderManager:IsSliderRelevantForAnimation(sliderKey, animationType)
    if sliderKey == "iconSize" or sliderKey == "positionX" or sliderKey == "positionY" then
        return true
    end
    
    local AnimationData = rawget(_G, "AnimationData")
    if not AnimationData then
        return true
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return true
    end
    
    return animationData.defaultValues[sliderKey] ~= nil
end

function SliderManager:GetAnimationSpecificValue(animationType, sliderKey)
    if not ReadyCooldownAlertDB or not ReadyCooldownAlertDB.animationConfigs then
        return nil
    end
    
    local savedConfig = ReadyCooldownAlertDB.animationConfigs[animationType]
    return savedConfig and savedConfig[sliderKey]
end

function SliderManager:SetAllSlidersEnabled(enabled)
    local alpha = enabled and 1.0 or 0.5
    for _, slider in pairs(sliders) do
        slider:SetEnabled(enabled)
        slider:SetAlpha(alpha)
    end
end

function SliderManager:SetAnimationSlidersEnabled(enabled)
    local alpha = enabled and 1.0 or 0.5
    for key, slider in pairs(sliders) do
        if key ~= "iconSize" and key ~= "positionX" and key ~= "positionY" then
            slider:SetEnabled(enabled)
            slider:SetAlpha(alpha)
        end
    end
end

function SliderManager:SetPositionAndSizeSlidersEnabled(enabled)
    local alpha = enabled and 1.0 or 0.5
    for key, slider in pairs(sliders) do
        if key == "iconSize" or key == "positionX" or key == "positionY" then
            slider:SetEnabled(enabled)
            slider:SetAlpha(alpha)
        end
    end
end

function SliderManager:SetPositionSlidersEnabled(enabled)
    local alpha = enabled and 1.0 or 0.5
    for key, slider in pairs(sliders) do
        if key == "positionX" or key == "positionY" then
            slider:SetEnabled(enabled)
            slider:SetAlpha(alpha)
        end
    end
end

function SliderManager:RefreshValues()
    local OptionsLogic = rawget(_G, "OptionsLogic")
    if not OptionsLogic then
        return
    end
    
    local sliderConfigs = OptionsLogic:GetSliderConfigs()
    for _, config in ipairs(sliderConfigs) do
        local slider = sliders[config.key]
        if slider then
            local value = OptionsLogic:GetConfigValue(config.key)
            if value then
                slider:SetValue(value)
                if slider.valueText then
                    slider.valueText:SetText(OptionsLogic:FormatSliderValue(config.key, value))
                end
            end
        end
    end
end

function SliderManager:GetSliders()
    return sliders
end

_G.SliderManager = SliderManager
return SliderManager
