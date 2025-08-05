local OptionsFrame = {}

-- Frame del panel de opciones
local optionsFrame = nil

-- Referencias a los managers de componentes
local layoutManager = nil
local sliderManager = nil
local buttonManager = nil
local controlsManager = nil

-- Referencias a elementos de UI
local uiElements = {}

-- Estado de edición de posición
local isEditingPosition = false

-- Inicializar panel de opciones
function OptionsFrame:Initialize()
    if optionsFrame then
        return
    end
    
    -- Cargar componentes
    self:LoadComponents()
    
    -- Crear frame principal
    self:CreateMainFrame()
    
    -- Crear todos los elementos de UI
    self:CreateUIElements()
    
    -- Inicializar estado
    self:InitializeState()
end

-- Cargar componentes modulares
function OptionsFrame:LoadComponents()
    -- Los componentes se cargan automáticamente por el sistema de addons de WoW
    layoutManager = _G.LayoutManager
    sliderManager = _G.SliderManager
    buttonManager = _G.ButtonManager
    controlsManager = _G.ControlsManager
end

-- Crear frame principal
function OptionsFrame:CreateMainFrame()
    optionsFrame = CreateFrame("MessageFrame", "ReadyCooldownAlertOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(400, 900)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    
    -- Título
    optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY")
    optionsFrame.title:SetFontObject("GameFontHighlight")
    optionsFrame.title:SetPoint("CENTER", optionsFrame.TitleBg, "CENTER", 0, 0)
    optionsFrame.title:SetText("Ready Cooldown Alert - Options")
    optionsFrame.title:SetTextColor(1, 0.82, 0, 1) -- Color dorado
end

-- Crear todos los elementos de UI usando los managers
function OptionsFrame:CreateUIElements()
    local sliderCount = #(_G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {})
    
    -- Crear elementos usando los managers modulares
    if controlsManager then
        local controls = controlsManager:CreateAllControls(optionsFrame, sliderCount)
        uiElements.checkboxes = controls.checkboxes
        uiElements.editBoxes = controls.editBoxes
        uiElements.dropdowns = controls.dropdowns
    end
    
    if sliderManager then
        local sliders = sliderManager:CreateSliders(optionsFrame)
        uiElements.sliders = sliders
    end
    
    if buttonManager then
        local buttons = buttonManager:CreateButtons(optionsFrame, sliderCount)
        uiElements.buttons = buttons
    end
    
    -- Actualizar sliders para la animación seleccionada inicialmente
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    if sliderManager then
        sliderManager:UpdateSlidersForAnimation(selectedAnimation)
    end
end

-- Inicializar estado
function OptionsFrame:InitializeState()
    isEditingPosition = false
    if sliderManager then
        sliderManager:SetPositionSlidersEnabled(false)
    end
end

-- Activar/Desactivar sliders de posición
function OptionsFrame:SetPositionSlidersEnabled(enabled)
    if sliderManager then
        sliderManager:SetPositionSlidersEnabled(enabled)
    end
    isEditingPosition = enabled
end

-- Verificar si está en modo de edición de posición
function OptionsFrame:IsEditingPosition()
    return isEditingPosition
end

-- Actualizar sliders según la animación seleccionada
function OptionsFrame:UpdateSlidersForAnimation(animationType)
    if sliderManager then
        sliderManager:UpdateSlidersForAnimation(animationType)
    end
end

-- Mostrar/Ocultar panel de opciones
function OptionsFrame:Toggle()
    if not optionsFrame then
        self:Initialize()
    end
    
    if optionsFrame and optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        self:RefreshValues()
        if optionsFrame then
            optionsFrame:Show()
        end
    end
end

-- Actualizar valores en la interfaz
function OptionsFrame:RefreshValues()
    if sliderManager then
        sliderManager:RefreshValues()
    end
    if controlsManager then
        controlsManager:RefreshValues()
    end
end

-- Callback cuando cambia la configuración
function OptionsFrame:OnConfigChanged(key, value)
    -- Delegar toda la lógica a OptionsLogic
    if _G.OptionsLogic then
        return _G.OptionsLogic:OnConfigChanged(key, value)
    end
end

-- Manejar click en botón Test
function OptionsFrame:OnTestClicked()
    if _G.OptionsLogic then
        _G.OptionsLogic:OnTestClicked()
    end
end

-- Manejar click en botón Unlock/Lock
function OptionsFrame:OnUnlockClicked()
    local button = buttonManager and buttonManager:GetButton("unlockButton")
    if not button or not _G.OptionsLogic then return end
    
    -- Usar OptionsLogic para manejar la lógica
    local newState = _G.OptionsLogic:OnUnlockClicked(isEditingPosition)
    isEditingPosition = newState
    
    -- Actualizar interfaz
    if buttonManager then
        buttonManager:UpdateUnlockButton(isEditingPosition)
    end
    self:SetPositionSlidersEnabled(isEditingPosition)
end

-- Manejar click en botón Reset Animation
function OptionsFrame:OnResetAnimationClicked()
    -- Obtener la animación actualmente seleccionada
    local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    
    -- Delegar a OptionsLogic para restaurar valores de la animación actual
    if _G.OptionsLogic then
        _G.OptionsLogic:RestoreAnimationDefaults(currentAnimation)
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- Actualizar sliders específicamente para la animación actual
    self:UpdateSlidersForAnimation(currentAnimation)
end

-- Manejar click en botón Reset All (restaurar todo)
function OptionsFrame:OnResetAllClicked()
    -- Delegar a OptionsLogic para restaurar TODOS los valores
    if _G.OptionsLogic then
        _G.OptionsLogic:RestoreDefaults()
    end
    
    -- Actualizar interfaz
    self:RefreshValues()
    
    -- La animación habrá cambiado a "pulse", actualizar sliders
    local newAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    self:UpdateSlidersForAnimation(newAnimation)
end

-- Mantener función legacy para compatibilidad
function OptionsFrame:OnDefaultsClicked()
    -- Redirigir a la nueva función de reset de animación
    self:OnResetAnimationClicked()
end

-- Manejar click en botón Close
function OptionsFrame:OnCloseClicked()
    -- Si está en modo edición (unlocked), hacer lock primero
    if isEditingPosition and _G.OptionsLogic then
        local newState = _G.OptionsLogic:OnCloseClicked(isEditingPosition)
        isEditingPosition = newState
        
        -- Actualizar el botón unlock para mostrar el estado correcto
        if buttonManager then
            buttonManager:UpdateUnlockButton(false)
        end
        self:SetPositionSlidersEnabled(false)
    end
    
    -- Cerrar la ventana
    if optionsFrame then
        optionsFrame:Hide()
    end
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
