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
        print("|cff00ff00RCA Debug|r: Saved to DB -", key, "=", validatedValue)
    else
        print("|cffFF0000RCA Debug|r: ReadyCooldownAlertDB is nil!")
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
        if OptionsFrame and OptionsFrame:IsEditing() then
            MainFrame:ShowForPositioning()
        end
    end
    
    -- Actualizar tamaño del MainFrame si cambió iconSize
    if key == "iconSize" and MainFrame then
        MainFrame:UpdateSize()
        
        -- Si estamos en modo de edición, asegurar que el icono siga visible
        if OptionsFrame and OptionsFrame:IsEditing() then
            MainFrame:ShowForPositioning()
        end
    end
    
    return validatedValue, wasModified
end

-- Manejar click en botón Test
function OptionsLogic:OnTestClicked()
    print("|cff00ffff RCA Debug|r: Test button clicked")
    
    -- Verificar que tenemos la animación seleccionada
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    print("|cff00ffff RCA Debug|r: Selected animation:", selectedAnimation)
    
    -- Priorizar AnimationProcessor
    if _G.AnimationProcessor then
        print("|cff00ff00RCA Debug|r: Using AnimationProcessor:TestAnimation()")
        _G.AnimationProcessor:TestAnimation()
    elseif _G.MainFrame then
        print("|cff00ff00RCA Debug|r: Using MainFrame:TestAnimation()")
        _G.MainFrame:TestAnimation()
    else
        print("|cffFF0000RCA Debug|r: Neither AnimationProcessor nor MainFrame available!")
        -- Fallback: mostrar mensaje al usuario
        print("|cffFF0000RCA Error|r: Animation system not available. Try reloading the addon.")
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

-- Manejar click en botón Close
function OptionsLogic:OnCloseClicked(isCurrentlyUnlocked)
    -- Si está unlocked, hacer lock primero
    if isCurrentlyUnlocked then
        if MainFrame then
            MainFrame:HideFromPositioning()
        end
    end
    
    -- Devolver que debe estar locked (false = locked)
    return false
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

-- Restaurar valores por defecto de la animación actual
function OptionsLogic:RestoreAnimationDefaults(animationType)
    if not ReadyCooldownAlertDB or not AnimationData then
        return
    end
    
    -- Obtener la configuración de la animación seleccionada
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        return
    end
    
    -- Restaurar solo los valores específicos de esta animación
    for key, defaultValue in pairs(animationData.defaultValues) do
        ReadyCooldownAlertDB[key] = defaultValue
        -- Notificar cambio individual
        self:OnConfigChanged(key, defaultValue)
    end
    
    -- No cambiar la animación seleccionada, mantener la actual
    -- No cambiar otros valores como showSpellName, invertIgnored, etc.
end

-- Obtener valor actual de configuración con fallback a default
function OptionsLogic:GetConfigValue(key)
    -- Buscar la configuración del slider
    for _, config in ipairs(sliderConfigs) do
        if config.key == key then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            local dbValue = ReadyCooldownAlertDB and ReadyCooldownAlertDB[key]
            local finalValue = dbValue or defaultVal
            
            -- Debug para iconSize específicamente
            if key == "iconSize" then
                print("|cff00ffff RCA Debug|r: GetConfigValue for iconSize - DB value:", dbValue, "Default:", defaultVal, "Final:", finalValue)
            end
            
            return finalValue
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

-- Verificar si un slider debe estar desactivado por defecto
function OptionsLogic:ShouldSliderBeDisabled(key)
    return key == "positionX" or key == "positionY"
end

-- Inicializar configuración por defecto si no existe
function OptionsLogic:InitializeDefaultConfig()
    print("|cff00ffff RCA Debug|r: InitializeDefaultConfig called")
    
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
        print("|cff00ffff RCA Debug|r: Created new ReadyCooldownAlertDB")
    else
        print("|cff00ffff RCA Debug|r: ReadyCooldownAlertDB exists")
    end
    
    -- Solo inicializar valores que no existen
    for _, config in ipairs(sliderConfigs) do
        if ReadyCooldownAlertDB[config.key] == nil then
            local _, _, defaultVal = self:CalculateDynamicValues(config)
            ReadyCooldownAlertDB[config.key] = defaultVal
            print("|cffffff00RCA Debug|r: InitializeDefaultConfig - Set", config.key, "=", defaultVal, "(was nil)")
        else
            print("|cff00ffff RCA Debug|r: InitializeDefaultConfig - Keeping", config.key, "=", ReadyCooldownAlertDB[config.key], "(already exists)")
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

-- Cargar configuración específica de una animación
function OptionsLogic:LoadAnimationConfiguration(animationType)
    if not ReadyCooldownAlertDB or not AnimationData then
        print("|cffFF0000RCA Debug|r: LoadAnimationConfiguration - Missing dependencies")
        return
    end
    
    -- Obtener la configuración de la animación seleccionada
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        print("|cffFF0000RCA Debug|r: LoadAnimationConfiguration - No animation data for:", animationType)
        return
    end
    
    -- Verificar si hay configuración guardada para esta animación
    local savedConfig = ReadyCooldownAlertDB.animationConfigs and ReadyCooldownAlertDB.animationConfigs[animationType]
    
    if savedConfig then
        print("|cff00ff00RCA Debug|r: Loading saved config for", animationType)
    else
        print("|cffffff00RCA Debug|r: No saved config for", animationType, "- using defaults")
    end
    
    -- Cargar los valores específicos de esta animación en ReadyCooldownAlertDB
    -- EXCLUIR valores de posición e iconSize que deben ser compartidos entre animaciones
    for key, defaultValue in pairs(animationData.defaultValues) do
        -- Saltar sliders de posición e iconSize - estos se comparten entre animaciones
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" then
            if savedConfig and savedConfig[key] ~= nil then
                -- Usar valor guardado si existe
                ReadyCooldownAlertDB[key] = savedConfig[key]
                print("|cff00ff00RCA Debug|r: Loaded", key, "=", savedConfig[key], "(saved)")
            else
                -- Si no hay configuración guardada, usar el default específico de esta animación
                ReadyCooldownAlertDB[key] = defaultValue
                print("|cffffff00RCA Debug|r: Set", key, "=", defaultValue, "(animation default)")
            end
        else
            print("|cffff8000RCA Debug|r: Skipping shared value", key, "- current value:", ReadyCooldownAlertDB[key])
        end
    end
    
    -- Notificar cambios (sin disparar refresh inmediato)
    -- self:OnConfigChanged("animationLoaded", animationType)
    print("|cff00ff00RCA Debug|r: LoadAnimationConfiguration completed for", animationType)
    
    -- El refresh de la interfaz ahora se maneja desde el dropdown para mejor timing
    -- if _G.SliderManager then
    --     _G.SliderManager:RefreshValues()
    -- end
end

-- Guardar configuración actual para una animación específica
function OptionsLogic:SaveAnimationConfiguration(animationType)
    if not ReadyCooldownAlertDB or not AnimationData then
        print("|cffFF0000RCA Debug|r: SaveAnimationConfiguration - Missing dependencies")
        return
    end
    
    -- Obtener la configuración de la animación seleccionada
    local animationData = AnimationData:GetAnimation(animationType)
    if not animationData or not animationData.defaultValues then
        print("|cffFF0000RCA Debug|r: SaveAnimationConfiguration - No animation data for:", animationType)
        return
    end
    
    -- Crear una nueva estructura para almacenar configuraciones por animación
    if not ReadyCooldownAlertDB.animationConfigs then
        ReadyCooldownAlertDB.animationConfigs = {}
    end
    
    -- Guardar la configuración actual para esta animación (SOLO valores específicos de animación)
    ReadyCooldownAlertDB.animationConfigs[animationType] = {}
    print("|cff00ff00RCA Debug|r: Saving config for", animationType)
    
    for key, _ in pairs(animationData.defaultValues) do
        -- Saltar sliders de posición e iconSize - estos se comparten entre animaciones
        if key ~= "positionX" and key ~= "positionY" and key ~= "iconSize" and ReadyCooldownAlertDB[key] ~= nil then
            ReadyCooldownAlertDB.animationConfigs[animationType][key] = ReadyCooldownAlertDB[key]
            print("|cff00ff00RCA Debug|r: Saved", key, "=", ReadyCooldownAlertDB[key])
        end
    end
    
    -- IMPORTANTE: Los valores compartidos (iconSize, positionX, positionY) ya están guardados
    -- en ReadyCooldownAlertDB directamente, no necesitan guardarse por animación
    print("|cff00ff00RCA Debug|r: Shared values (iconSize, positionX, positionY) remain in global DB")
    print("|cff00ff00RCA Debug|r: Current iconSize in DB:", ReadyCooldownAlertDB.iconSize)
    
    -- Notificar cambios
    self:OnConfigChanged("animationSaved", animationType)
end

-- Exportar globalmente para WoW addon system
_G.OptionsLogic = OptionsLogic

return OptionsLogic
