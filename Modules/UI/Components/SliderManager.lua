local SliderManager = {}

-- Referencias locales
local sliders = {}

-- Crear todos los sliders
function SliderManager:CreateSliders(parentFrame)
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    local constants = _G.LayoutManager:GetConstants()
    local yOffset = constants.SLIDER_START_Y
    
    for i, config in ipairs(sliderConfigs) do
        local slider = self:CreateSingleSlider(parentFrame, config, i, yOffset)
        sliders[config.key] = slider
        yOffset = yOffset - constants.SLIDER_HEIGHT
    end
    
    return sliders
end

-- Crear un slider individual
function SliderManager:CreateSingleSlider(parentFrame, config, index, yOffset)
    local slider = CreateFrame("Slider", "RCASlider" .. index, parentFrame, "OptionsSliderTemplate")
    slider:SetPoint("TOP", 0, yOffset)
    
    -- Configurar valores dinámicos usando OptionsLogic
    local minVal, maxVal, defaultVal = _G.OptionsLogic:CalculateDynamicValues(config)
    
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(config.step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(300)
    
    -- Configurar textos del slider
    self:SetupSliderTexts(slider, config, minVal, maxVal)
    
    -- Configurar valor actual
    self:SetupSliderValue(slider, config)
    
    -- Configurar eventos
    self:SetupSliderEvents(slider, config)
    
    -- Desactivar sliders de posición por defecto
    if _G.OptionsLogic and _G.OptionsLogic:ShouldSliderBeDisabled(config.key) then
        slider:SetEnabled(false)
        slider:SetAlpha(0.5)
    end
    
    return slider
end

-- Configurar textos del slider
function SliderManager:SetupSliderTexts(slider, config, minVal, maxVal)
    -- Texto del slider
    slider.Text:SetText(config.label)
    slider.Low:SetText(math.floor(minVal))
    slider.High:SetText(math.floor(maxVal))
    
    -- Valor actual
    slider.valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
end

-- Configurar valor inicial del slider
function SliderManager:SetupSliderValue(slider, config)
    local currentValue = _G.OptionsLogic:GetConfigValue(config.key)
    slider:SetValue(currentValue)
    
    -- Formatear texto usando OptionsLogic
    slider.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, currentValue))
end

-- Configurar eventos del slider
function SliderManager:SetupSliderEvents(slider, config)
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
end

-- Actualizar sliders según la animación seleccionada
function SliderManager:UpdateSlidersForAnimation(animationType)
    if not _G.AnimationData or not _G.OptionsLogic then
        return
    end
    
    -- Obtener la configuración de la animación seleccionada
    local animationData = _G.AnimationData:GetAnimation(animationType)
    if not animationData then
        return
    end
    
    -- Obtener configuraciones actuales de sliders
    local sliderConfigs = _G.OptionsLogic:GetSliderConfigs()
    
    -- Actualizar cada slider según si es relevante para esta animación
    for _, config in ipairs(sliderConfigs) do
        local slider = sliders[config.key]
        if slider then
            self:UpdateSliderForAnimation(slider, config, animationType)
        end
    end
end

-- Actualizar un slider individual para una animación
function SliderManager:UpdateSliderForAnimation(slider, config, animationType)
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

-- Verificar si un slider es relevante para una animación específica
function SliderManager:IsSliderRelevantForAnimation(sliderKey, animationType)
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
function SliderManager:GetAnimationSpecificValue(animationType, sliderKey)
    if not _G.AnimationData then
        return nil
    end
    
    local animationData = _G.AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return nil
    end
    
    return animationData.defaultValues[sliderKey]
end

-- Activar/Desactivar sliders de posición
function SliderManager:SetPositionSlidersEnabled(enabled)
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
end

-- Actualizar valores en la interfaz
function SliderManager:RefreshValues()
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
end

-- Obtener referencia de sliders
function SliderManager:GetSliders()
    return sliders
end

-- Exportar globalmente para WoW addon system
_G.SliderManager = SliderManager

return SliderManager
