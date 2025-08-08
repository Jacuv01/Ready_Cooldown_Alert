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

-- Estado de edición
local isEditing = false

-- Estado de unlock para position e iconSize
local isUnlocked = false

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
    
    -- Finalizar inicialización
    self:FinalizeUIElements()
    
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
    
    -- Nuevos componentes para el sistema de pestañas
    self.tabManager = _G.TabManager
    self.filtersUI = _G.FiltersUI
end

-- Crear frame principal
function OptionsFrame:CreateMainFrame()
    optionsFrame = CreateFrame("MessageFrame", "ReadyCooldownAlertOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(400, 900)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("MEDIUM")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    
    -- Hacer el frame focusable para recibir eventos de teclado, pero sin bloquear movimiento
    optionsFrame:EnableKeyboard(true)
    optionsFrame:SetScript("OnShow", function(self)
        -- No obtener foco automáticamente para permitir movimiento
        -- El foco se manejará solo cuando sea necesario
    end)
    
    -- Manejar clicks para quitar foco y permitir movimiento
    optionsFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:ClearFocus() -- Quitar foco para permitir movimiento
        end
    end)
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    
    -- Permitir cerrar con Escape sin abrir el menú del juego
    -- Método 1: Registrar en UISpecialFrames (método estándar de WoW)
    table.insert(UISpecialFrames, "ReadyCooldownAlertOptionsFrame")
    
    -- Método 2: Handler personalizado que SOLO maneja ESC
    optionsFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            return -- No propagar ESC
        end
        -- Para cualquier otra tecla, propagar al sistema (permite movimiento)
    end)
    optionsFrame:SetPropagateKeyboardInput(true) -- Permitir propagación de otras teclas
    
    -- Título
    optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY")
    optionsFrame.title:SetFontObject("GameFontHighlight")
    optionsFrame.title:SetPoint("CENTER", optionsFrame.TitleBg, "CENTER", 0, 0)
    optionsFrame.title:SetText("Ready Cooldown Alert - Options")
    optionsFrame.title:SetTextColor(1, 0.82, 0, 1) -- Color dorado
end

-- Crear todos los elementos de UI usando los managers
function OptionsFrame:CreateUIElements()
    -- Inicializar sistema de pestañas
    if self.tabManager then
        self.tabManager:Initialize(optionsFrame, layoutManager)
        
        -- Configurar callback para cambios de pestaña
        self.tabManager:SetTabChangedCallback(function(tabKey)
            self:OnTabChanged(tabKey)
        end)
        
        -- Crear contenido de la pestaña General
        self:CreateGeneralTabContent()
        
        -- Crear contenido de la pestaña Filters
        self:CreateFiltersTabContent()
    else
        -- Fallback: crear UI sin pestañas (modo legacy)
        self:CreateLegacyUI()
    end
end

-- Crear contenido de la pestaña General
function OptionsFrame:CreateGeneralTabContent()
    local generalFrame = self.tabManager:GetContentFrame("general")
    if not generalFrame then return end
    
    local sliderCount = #(_G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {})
    
    -- Crear elementos en la pestaña General usando los managers modulares
    if controlsManager then
        local controls = controlsManager:CreateAllControls(generalFrame, sliderCount)
        uiElements.checkboxes = controls.checkboxes
        uiElements.editBoxes = controls.editBoxes
        uiElements.dropdowns = controls.dropdowns
    end
    
    if sliderManager then
        local sliders = sliderManager:CreateSliders(generalFrame)
        uiElements.sliders = sliders
    end
    
    if buttonManager then
        local buttons = buttonManager:CreateButtons(generalFrame, sliderCount)
        uiElements.buttons = buttons
    end
end

-- Crear contenido de la pestaña Filters
function OptionsFrame:CreateFiltersTabContent()
    local filtersFrame = self.tabManager:GetContentFrame("filters")
    if not filtersFrame then return end
    
    -- Inicializar UI de filtros
    if self.filtersUI then
        self.filtersUI:Initialize(filtersFrame, layoutManager)
    end
end

-- Crear UI legacy (sin pestañas) como fallback
function OptionsFrame:CreateLegacyUI()
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
end

-- Callback cuando cambia la pestaña activa
function OptionsFrame:OnTabChanged(tabKey)
    -- Aquí se pueden agregar acciones específicas cuando cambia la pestaña
    if tabKey == "filters" and self.filtersUI then
        -- Actualizar lista de filtros cuando se cambia a la pestaña de filtros
        self.filtersUI:RefreshFiltersList()
    end
end

-- Finalizar inicialización de elementos (legacy compatibility)
function OptionsFrame:FinalizeUIElements()
    -- Actualizar sliders para la animación seleccionada inicialmente
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    if sliderManager then
        sliderManager:UpdateSlidersForAnimation(selectedAnimation)
    end
end

-- Inicializar estado
function OptionsFrame:InitializeState()
    isEditing = false
    isUnlocked = false
    
    if sliderManager then
        -- Deshabilitar todos los sliders por defecto
        sliderManager:SetAnimationSlidersEnabled(false)
        sliderManager:SetPositionAndSizeSlidersEnabled(false)
    end
    
    -- Asegurar que la ventana inicie oculta
    if optionsFrame then
        optionsFrame:Hide()
    end
end

-- Activar/Desactivar sliders de animación (Edit/Save)
function OptionsFrame:SetAnimationSlidersEnabled(enabled)
    if sliderManager then
        sliderManager:SetAnimationSlidersEnabled(enabled)
    end
    isEditing = enabled
end

-- Activar/Desactivar sliders de posición e iconSize (Unlock/Lock)
function OptionsFrame:SetPositionAndSizeSlidersEnabled(enabled)
    if sliderManager then
        sliderManager:SetPositionAndSizeSlidersEnabled(enabled)
    end
    isUnlocked = enabled
end

-- Verificar si está en modo de edición
function OptionsFrame:IsEditing()
    return isEditing
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

-- Manejar click en botón Edit/Save (solo para sliders de animación)
function OptionsFrame:OnEditSaveClicked()
    if not buttonManager or not _G.OptionsLogic then return end
    
    if isEditing then
        -- Modo Save: Guardar configuración actual de la animación seleccionada
        local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
        _G.OptionsLogic:SaveAnimationConfiguration(currentAnimation)
        
        -- Salir del modo edición
        isEditing = false
        self:SetAnimationSlidersEnabled(false)
        buttonManager:UpdateEditButton(false)
    else
        -- Modo Edit: Habilitar sliders de animación para edición
        local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
        
        -- Entrar en modo edición
        isEditing = true
        self:SetAnimationSlidersEnabled(true)
        buttonManager:UpdateEditButton(true)
        
        -- SOLO actualizar la interfaz sin recargar la configuración
        -- No llamar a LoadAnimationConfiguration para mantener valores actuales
        self:RefreshValues()
        -- No llamar a UpdateSlidersForAnimation aquí ya que RefreshValues es suficiente
    end
end

-- Manejar click en botón Unlock/Lock (para position e iconSize)
function OptionsFrame:OnUnlockClicked()
    if not buttonManager or not _G.OptionsLogic then return end
    
    if isUnlocked then
        -- Modo Lock: Deshabilitar sliders de posición e iconSize
        isUnlocked = false
        self:SetPositionAndSizeSlidersEnabled(false)
        buttonManager:UpdateUnlockButton(false)
        
        -- Ocultar el icono de posicionamiento
        if _G.MainFrame then
            _G.MainFrame:HideFromPositioning()
        end
    else
        -- Modo Unlock: Habilitar sliders de posición e iconSize
        isUnlocked = true
        self:SetPositionAndSizeSlidersEnabled(true)
        buttonManager:UpdateUnlockButton(true)
        
        -- Mostrar el icono para posicionamiento
        if _G.MainFrame then
            _G.MainFrame:ShowForPositioning()
        end
    end
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
    -- Si está en modo edición, salir del modo edición
    if isEditing and buttonManager then
        isEditing = false
        buttonManager:UpdateEditButton(false)
        self:SetAnimationSlidersEnabled(false)
    end
    
    -- Si está en modo unlocked, salir del modo unlocked
    if isUnlocked and buttonManager then
        isUnlocked = false
        buttonManager:UpdateUnlockButton(false)
        self:SetPositionAndSizeSlidersEnabled(false)
        
        -- Ocultar el icono de posicionamiento
        if _G.MainFrame then
            _G.MainFrame:HideFromPositioning()
        end
    end
    
    -- Cerrar la ventana
    if optionsFrame then
        optionsFrame:Hide()
    end
end

-- Exportar globalmente para WoW addon system
_G.OptionsFrame = OptionsFrame

return OptionsFrame
