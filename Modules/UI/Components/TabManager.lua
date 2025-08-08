local TabManager = {}

-- Estado del sistema de pestañas
local tabs = {}
local activeTab = "general"
local tabButtons = {}
local contentFrames = {}

-- Inicializar sistema de pestañas
function TabManager:Initialize(parentFrame, layoutManager)
    self.parentFrame = parentFrame
    self.layoutManager = layoutManager
    
    -- Crear pestañas
    self:CreateTabs()
    
    -- Crear frames de contenido
    self:CreateContentFrames()
    
    -- Mostrar pestaña inicial
    self:ShowTab("general")
end

-- Crear botones de pestañas
function TabManager:CreateTabs()
    local tabsLayout = self.layoutManager:GetTabsPosition()
    
    for i, tabInfo in ipairs(tabsLayout.tabs) do
        local tabButton = CreateFrame("Button", nil, self.parentFrame, "UIPanelButtonTemplate")
        
        -- Posición y tamaño
        local x = (i - 1) * (tabsLayout.tabWidth + tabsLayout.spacing) + 20
        tabButton:SetPoint("TOPLEFT", self.parentFrame, "TOPLEFT", x, tabsLayout.startY)
        tabButton:SetSize(tabsLayout.tabWidth, tabsLayout.tabHeight)
        
        -- Texto
        tabButton:SetText(tabInfo.name)
        tabButton:SetNormalFontObject("GameFontNormal")
        
        -- Funcionalidad
        tabButton:SetScript("OnClick", function()
            self:ShowTab(tabInfo.key)
        end)
        
        -- Guardar referencia
        tabButtons[tabInfo.key] = tabButton
        tabs[tabInfo.key] = tabInfo
    end
end

-- Crear frames de contenido para cada pestaña
function TabManager:CreateContentFrames()
    local contentArea = self.layoutManager:GetTabContentArea()
    
    for tabKey, _ in pairs(tabs) do
        local contentFrame = CreateFrame("Frame", nil, self.parentFrame)
        contentFrame:SetPoint("TOPLEFT", self.parentFrame, "TOPLEFT", 0, contentArea.startY)
        contentFrame:SetSize(400, contentArea.contentHeight)
        contentFrame:Hide() -- Ocultar por defecto
        
        contentFrames[tabKey] = contentFrame
    end
end

-- Mostrar una pestaña específica
function TabManager:ShowTab(tabKey)
    if not tabs[tabKey] then
        return
    end
    
    -- Ocultar todas las pestañas
    for key, frame in pairs(contentFrames) do
        frame:Hide()
    end
    
    -- Actualizar botones
    for key, button in pairs(tabButtons) do
        if key == tabKey then
            button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab-BGSelected")
            button:SetText("|cFFFFFF00" .. tabs[key].name .. "|r") -- Amarillo para activo
        else
            button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab-BGInactive")
            button:SetText("|cFFAAAAAA" .. tabs[key].name .. "|r") -- Gris para inactivo
        end
    end
    
    -- Mostrar pestaña activa
    contentFrames[tabKey]:Show()
    activeTab = tabKey
    
    -- Notificar cambio de pestaña
    self:OnTabChanged(tabKey)
end

-- Callback cuando cambia la pestaña activa
function TabManager:OnTabChanged(tabKey)
    -- Disparar evento personalizado para que otros componentes reaccionen
    if self.onTabChangedCallback then
        self.onTabChangedCallback(tabKey)
    end
end

-- Establecer callback para cambios de pestaña
function TabManager:SetTabChangedCallback(callback)
    self.onTabChangedCallback = callback
end

-- Obtener frame de contenido de una pestaña
function TabManager:GetContentFrame(tabKey)
    return contentFrames[tabKey]
end

-- Obtener pestaña activa
function TabManager:GetActiveTab()
    return activeTab
end

-- Agregar contenido a una pestaña específica
function TabManager:AddContentToTab(tabKey, contentCreationFunction)
    local contentFrame = self:GetContentFrame(tabKey)
    if contentFrame and contentCreationFunction then
        contentCreationFunction(contentFrame)
    end
end

-- Exportar globalmente para WoW addon system
_G.TabManager = TabManager

return TabManager
