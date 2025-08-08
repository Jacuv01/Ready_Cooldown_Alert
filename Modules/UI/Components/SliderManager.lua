local SliderManager = {}

-- Referencias locales
local sliders = {}

-- Crear todos los sliders en el nuevo orden: Primero posición/tamaño, luego animación
function SliderManager:CreateSliders(parentFrame)
    local sliderConfigs = _G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {}
    
    -- SECCIÓN 1: Crear sliders de posición y tamaño primero
    self:CreatePositionAndSizeSliders(parentFrame, sliderConfigs)
    
    -- SECCIÓN 2: Crear sliders de animación después
    self:CreateAnimationSliders(parentFrame, sliderConfigs)
    
    return sliders
end

-- Crear sliders de posición y tamaño (iconSize, positionX, positionY)
function SliderManager:CreatePositionAndSizeSliders(parentFrame, sliderConfigs)
    local positionOrder = {"iconSize", "positionX", "positionY"}
    local layoutInfo = _G.LayoutManager:GetPositionSlidersPosition()
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

-- Crear sliders de animación (todos excepto posición y tamaño)
function SliderManager:CreateAnimationSliders(parentFrame, sliderConfigs)
    local animationConfigs = {}
    
    -- Filtrar solo configuraciones de animación
    for _, config in ipairs(sliderConfigs) do
        if config.key ~= "iconSize" and config.key ~= "positionX" and config.key ~= "positionY" then
            table.insert(animationConfigs, config)
        end
    end
    
    local layoutInfo = _G.LayoutManager:GetAnimationSlidersPosition(#animationConfigs)
    local yOffset = layoutInfo.startY
    
    for i, config in ipairs(animationConfigs) do
        local slider = self:CreateSingleSlider(parentFrame, config, i + 3, yOffset) -- +3 porque ya creamos 3 sliders de posición
        sliders[config.key] = slider
        yOffset = yOffset - layoutInfo.sliderHeight
    end
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
    
    -- Desactivar TODOS los sliders por defecto (se habilitan solo en modo edición)
    slider:SetEnabled(false)
    slider:SetAlpha(0.5)
    
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
        -- Solo permitir scroll si el slider está habilitado
        if not self:IsEnabled() then
            return
        end
        
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
        -- Mostrar slider
        slider:Show()
        
        -- NO cambiar el estado enabled/disabled aquí - eso se controla por el modo de edición
        -- Solo actualizar valores si la animación tiene configuración específica
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
        -- Ocultar sliders no relevantes para esta animación
        slider:Hide()
    end
end

-- Verificar si un slider es relevante para una animación específica
function SliderManager:IsSliderRelevantForAnimation(sliderKey, animationType)
    -- Los sliders de posición e iconSize siempre son relevantes para todas las animaciones
    if sliderKey == "positionX" or sliderKey == "positionY" or sliderKey == "iconSize" then
        return true
    end
    
    -- Mapeo de qué sliders son relevantes para cada animación
    local animationRelevantSliders = {
        pulse = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        bounce = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        fade = {"fadeInTime", "fadeOutTime", "maxAlpha", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        zoom = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"},
        glow = {"fadeInTime", "fadeOutTime", "maxAlpha", "animScale", "iconSize", "holdTime", "remainingCooldownWhenNotified"}
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

-- Activar/Desactivar todos los sliders
function SliderManager:SetAllSlidersEnabled(enabled)
    for key, slider in pairs(sliders) do
        slider:SetEnabled(enabled)
        -- Cambiar la apariencia visual para mostrar el estado
        if enabled then
            slider:SetAlpha(1.0)
        else
            slider:SetAlpha(0.5)
        end
    end
end

-- Activar/Desactivar solo sliders de animación (NO position e iconSize)
function SliderManager:SetAnimationSlidersEnabled(enabled)
    for key, slider in pairs(sliders) do
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" then
            slider:SetEnabled(enabled)
            if enabled then
                slider:SetAlpha(1.0)
            else
                slider:SetAlpha(0.5)
            end
        end
    end
end

-- Activar/Desactivar sliders de posición e iconSize
function SliderManager:SetPositionAndSizeSlidersEnabled(enabled)
    local positionSliders = {"positionX", "positionY", "iconSize"}
    
    for _, key in ipairs(positionSliders) do
        local slider = sliders[key]
        if slider then
            slider:SetEnabled(enabled)
            if enabled then
                slider:SetAlpha(1.0)
            else
                slider:SetAlpha(0.5)
            end
        end
    end
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
                
                print("|cff00ffff RCA Debug|r: RefreshValues - Updating slider", config.key, "to", value)
                
                -- Deshabilitar temporalmente el OnValueChanged para evitar recursión
                local originalScript = slider:GetScript("OnValueChanged")
                slider:SetScript("OnValueChanged", nil)
                
                slider:SetValue(value)
                
                -- Actualizar el texto manualmente
                if slider.valueText then
                    slider.valueText:SetText(_G.OptionsLogic:FormatSliderValue(config.key, value))
                end
                
                -- Restaurar el script OnValueChanged
                slider:SetScript("OnValueChanged", originalScript)
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
