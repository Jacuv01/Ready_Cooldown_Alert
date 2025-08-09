local OptionsLogic = {}

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
        max = 0,
        step = 1,
        default = 0,
        isDynamic = true
    },
    {
        key = "positionY", 
        label = "Position Y",
        min = 0,
        max = 0,
        step = 1,
        default = 0,
        isDynamic = true
    }
}

function OptionsLogic:GetSliderConfigs()
    return sliderConfigs
end

function OptionsLogic:CalculateDynamicValues(config)
    local minVal = config.min
    local maxVal = config.max
    local defaultVal = config.default
    
    if config.isDynamic then
        if config.key == "positionX" then
            maxVal = GetScreenWidth() or 1920
            defaultVal = maxVal / 2
        elseif config.key == "positionY" then
            maxVal = GetScreenHeight() or 1080
            defaultVal = maxVal / 2
        end
    end
    
    return minVal, maxVal, defaultVal
end

function OptionsLogic:ValidateConfigChange(key, value)
    if key == "remainingCooldownWhenNotified" and value <= 0 then
        return 0.1, true
    end
    
    return value, false
end

function OptionsLogic:OnConfigChanged(key, value)
    local validatedValue, wasModified = self:ValidateConfigChange(key, value)
    
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB[key] = validatedValue
    end
    
    local processors = {"AnimationProcessor", "FilterProcessor"}
    for _, processorName in ipairs(processors) do
        local processor = rawget(_G, processorName)
        if processor then
            if processorName == "AnimationProcessor" and processor.RefreshConfig then
                processor:RefreshConfig()
            elseif processorName == "FilterProcessor" and processor.RefreshFilters then
                processor:RefreshFilters()
            end
        end
    end
    
    if key == "positionX" or key == "positionY" or key == "iconSize" then
        local MainFrame = rawget(_G, "MainFrame")
        local OptionsFrame = rawget(_G, "OptionsFrame")
        
        if MainFrame then
            if key == "positionX" or key == "positionY" then
                MainFrame:UpdatePosition()
            elseif key == "iconSize" then
                MainFrame:UpdateSize()
            end
            
            if OptionsFrame and OptionsFrame:IsEditing() then
                MainFrame:ShowForPositioning()
            end
        end
    end
    
    return validatedValue, wasModified
end

function OptionsLogic:OnTestClicked()
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    local MainFrame = rawget(_G, "MainFrame")
    
    if AnimationProcessor then
        AnimationProcessor:TestAnimation()
    elseif MainFrame then
        MainFrame:TestAnimation()
    end
end

function OptionsLogic:OnResetClicked()
    if not ReadyCooldownAlertDB then
        return
    end
    
    for _, config in ipairs(sliderConfigs) do
        if not config.isDynamic then
            ReadyCooldownAlertDB[config.key] = config.default
        else
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            ReadyCooldownAlertDB[config.key] = defaultVal
        end
    end
    
    if ReadyCooldownAlertDB.selectedAnimation then
        ReadyCooldownAlertDB.selectedAnimation = "pulse"
    end
    if ReadyCooldownAlertDB.animationConfigs then
        ReadyCooldownAlertDB.animationConfigs = {}
    end
    
    local modules = {"OptionsFrame", "SliderManager", "ControlsManager"}
    for _, moduleName in ipairs(modules) do
        local module = rawget(_G, moduleName)
        if module and module.RefreshValues then
            module:RefreshValues()
        end
    end
    
    self:OnConfigChanged("reset", "all")
end

function OptionsLogic:ShouldSliderBeDisabled(key)
    return key == "positionX" or key == "positionY"
end

function OptionsLogic:GetConfigValue(key)
    for _, config in ipairs(sliderConfigs) do
        if config.key == key then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            local dbValue = ReadyCooldownAlertDB and ReadyCooldownAlertDB[key]
            return dbValue or defaultVal
        end
    end
    
    return ReadyCooldownAlertDB and ReadyCooldownAlertDB[key]
end

function OptionsLogic:FormatSliderValue(key, value)
    local formatters = {
        positionX = function(v) return tostring(math.floor(v)) end,
        positionY = function(v) return tostring(math.floor(v)) end,
        iconSize = function(v) return tostring(math.floor(v)) end,
        animScale = function(v) return string.format("%.1fx", v) end,
        maxAlpha = function(v) return string.format("%.1f", v) end
    }
    
    local formatter = formatters[key]
    return formatter and formatter(value) or string.format("%.1fs", value)
end

function OptionsLogic:GetMouseWheelStep(key)
    for _, config in ipairs(sliderConfigs) do
        if config.key == key then
            return config.step * 5
        end
    end
    return 0.1
end

function OptionsLogic:InitializeDefaultConfig()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    for _, config in ipairs(sliderConfigs) do
        if ReadyCooldownAlertDB[config.key] == nil then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            ReadyCooldownAlertDB[config.key] = defaultVal
        end
    end
    
    if ReadyCooldownAlertDB.showSpellName == nil then
        ReadyCooldownAlertDB.showSpellName = true
    end
    if ReadyCooldownAlertDB.invertIgnored == nil then
        ReadyCooldownAlertDB.invertIgnored = false
    end
    if ReadyCooldownAlertDB.ignoredSpells == nil then
        ReadyCooldownAlertDB.ignoredSpells = ""
    end
    if ReadyCooldownAlertDB.selectedAnimation == nil then
        ReadyCooldownAlertDB.selectedAnimation = "pulse"
    end
end

function OptionsLogic:LoadAnimationConfiguration(animationType)
    local AnimationData = rawget(_G, "AnimationData")
    if not ReadyCooldownAlertDB or not AnimationData then
        return
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return
    end
    
    local savedConfig = ReadyCooldownAlertDB.animationConfigs and ReadyCooldownAlertDB.animationConfigs[animationType]
    
    for key, defaultValue in pairs(animationData.defaultValues) do
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" then
            if savedConfig and savedConfig[key] ~= nil then
                ReadyCooldownAlertDB[key] = savedConfig[key]
            else
                ReadyCooldownAlertDB[key] = defaultValue
            end
        end
    end
end

function OptionsLogic:SaveAnimationConfiguration(animationType)
    local AnimationData = rawget(_G, "AnimationData")
    if not ReadyCooldownAlertDB or not AnimationData then
        return
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return
    end
    
    if not ReadyCooldownAlertDB.animationConfigs then
        ReadyCooldownAlertDB.animationConfigs = {}
    end
    
    ReadyCooldownAlertDB.animationConfigs[animationType] = {}
    
    for key, _ in pairs(animationData.defaultValues) do
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" and ReadyCooldownAlertDB[key] ~= nil then
            ReadyCooldownAlertDB.animationConfigs[animationType][key] = ReadyCooldownAlertDB[key]
        end
    end
    
    self:OnConfigChanged("animationSaved", animationType)
end

function OptionsLogic:RestoreAnimationDefaults(animationType)
    local AnimationData = rawget(_G, "AnimationData")
    if not ReadyCooldownAlertDB or not AnimationData then
        return
    end
    
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return
    end
    
    for key, defaultValue in pairs(animationData.defaultValues) do
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" then
            ReadyCooldownAlertDB[key] = defaultValue
        end
    end
    
    if ReadyCooldownAlertDB.animationConfigs and ReadyCooldownAlertDB.animationConfigs[animationType] then
        ReadyCooldownAlertDB.animationConfigs[animationType] = nil
    end
    
    local modules = {"OptionsFrame", "SliderManager"}
    for _, moduleName in ipairs(modules) do
        local module = rawget(_G, moduleName)
        if module and module.RefreshValues then
            module:RefreshValues()
        end
    end
    
    self:OnConfigChanged("animationRestored", animationType)
end

_G.OptionsLogic = OptionsLogic
return OptionsLogic
