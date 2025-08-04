local OptionsLogic = {}

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
        min = 0.1,
        max = 10,
        step = 0.1,
        default = 1.0
    },
    {
        key = "positionX",
        label = "Position X",
        min = 0,
        max = 0, -- Se calculará dinámicamente
        step = 1,
        default = 0, -- Se calculará como centro de pantalla
        isDynamic = true
    },
    {
        key = "positionY", 
        label = "Position Y",
        min = 0,
        max = 0, -- Se calculará dinámicamente
        step = 1,
        default = 0, -- Se calculará como centro de pantalla
        isDynamic = true
    }
}

-- Obtener configuración de sliders
function OptionsLogic:GetSliderConfigs()
    return sliderConfigs
end

-- Calcular valores dinámicos para sliders de posición
function OptionsLogic:CalculateDynamicValues(config)
    local minVal = config.min
    local maxVal = config.max
    local defaultVal = config.default
    
    if config.isDynamic then
        if config.key == "positionX" then
            maxVal = GetScreenWidth() or 1920
            defaultVal = maxVal / 2 -- Centro de pantalla
        elseif config.key == "positionY" then
            maxVal = GetScreenHeight() or 1080
            defaultVal = maxVal / 2 -- Centro de pantalla
        end
    end
    
    return minVal, maxVal, defaultVal
end

-- Validar y procesar cambios de configuración
function OptionsLogic:ValidateConfigChange(key, value)
    -- Validación especial para remainingCooldownWhenNotified
    if key == "remainingCooldownWhenNotified" and value <= 0 then
        -- Corregir valor a mínimo permitido
        return 0.1, true -- valor corregido, fue modificado
    end
    
    return value, false -- valor original, no fue modificado
end

-- Callback cuando cambia la configuración
function OptionsLogic:OnConfigChanged(key, value)
    -- Validar el valor primero
    local validatedValue, wasModified = self:ValidateConfigChange(key, value)
    
    -- Actualizar la base de datos
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB[key] = validatedValue
    end
    
    -- Notificar a otros módulos que la configuración cambió
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
    end
    if FilterProcessor then
        FilterProcessor:RefreshFilters()
    end
    
    -- Actualizar posición del MainFrame si cambió positionX o positionY
    if (key == "positionX" or key == "positionY") and MainFrame then
        MainFrame:UpdatePosition()
        
        -- Si estamos en modo de edición, asegurar que el icono siga visible
        if OptionsFrame and OptionsFrame:IsEditingPosition() then
            MainFrame:ShowForPositioning()
        end
    end
    
    return validatedValue, wasModified
end

-- Manejar click en botón Test
function OptionsLogic:OnTestClicked()
    if AnimationProcessor then
        AnimationProcessor:TestAnimation()
    elseif MainFrame then
        MainFrame:TestAnimation()
    end
end

-- Manejar lógica del botón Unlock/Lock
function OptionsLogic:OnUnlockClicked(currentState)
    local newState = not currentState
    
    -- Mostrar/ocultar icono según el estado
    if newState then
        -- Modo unlock: mostrar icono para posicionamiento
        if MainFrame then
            MainFrame:ShowForPositioning()
        end
    else
        -- Modo lock: ocultar icono
        if MainFrame then
            MainFrame:HideFromPositioning()
        end
    end
    
    return newState
end

-- Restaurar valores por defecto
function OptionsLogic:RestoreDefaults()
    -- Inicializar base de datos si no existe
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    -- Restaurar valores de sliders
    for _, config in ipairs(sliderConfigs) do
        local _, _, defaultVal = self:CalculateDynamicValues(config)
        ReadyCooldownAlertDB[config.key] = defaultVal
    end
    
    -- Restaurar otros valores
    ReadyCooldownAlertDB.showSpellName = true
    ReadyCooldownAlertDB.invertIgnored = false
    ReadyCooldownAlertDB.ignoredSpells = ""
    ReadyCooldownAlertDB.selectedAnimation = "pulse"
    
    -- Validar que remainingCooldownWhenNotified no sea cero
    if ReadyCooldownAlertDB.remainingCooldownWhenNotified and ReadyCooldownAlertDB.remainingCooldownWhenNotified <= 0 then
        ReadyCooldownAlertDB.remainingCooldownWhenNotified = 1.0
    end
    
    -- Notificar cambios
    self:OnConfigChanged("defaults", true)
end

-- Obtener valor actual de configuración con fallback a default
function OptionsLogic:GetConfigValue(key)
    -- Buscar la configuración del slider
    for _, config in ipairs(sliderConfigs) do
        if config.key == key then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            return (ReadyCooldownAlertDB and ReadyCooldownAlertDB[key]) or defaultVal
        end
    end
    
    -- Para valores no dinámicos, devolver valor de DB o nil
    return ReadyCooldownAlertDB and ReadyCooldownAlertDB[key]
end

-- Formatear texto de valor para sliders
function OptionsLogic:FormatSliderValue(key, value)
    if key == "positionX" or key == "positionY" then
        return tostring(math.floor(value))
    else
        return string.format("%.1f", value)
    end
end

-- Calcular step size para mouse wheel en sliders
function OptionsLogic:GetMouseWheelStep(key)
    -- Para sliders de posición, usar pasos más grandes
    if key == "positionX" or key == "positionY" then
        return 5 -- Mover 5 píxeles por scroll
    end
    
    -- Buscar el step configurado para otros sliders
    for _, config in ipairs(sliderConfigs) do
        if config.key == key then
            return config.step
        end
    end
    
    return 0.1 -- Default step
end

-- Verificar si un slider debe estar oculto por defecto
function OptionsLogic:ShouldSliderBeHidden(key)
    return key == "positionX" or key == "positionY"
end

-- Inicializar configuración por defecto si no existe
function OptionsLogic:InitializeDefaultConfig()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    -- Solo inicializar valores que no existen
    for _, config in ipairs(sliderConfigs) do
        if ReadyCooldownAlertDB[config.key] == nil then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            ReadyCooldownAlertDB[config.key] = defaultVal
        end
    end
    
    -- Inicializar otros valores si no existen
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

-- Exportar globalmente para WoW addon system
_G.OptionsLogic = OptionsLogic

return OptionsLogic
