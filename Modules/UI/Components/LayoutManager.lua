local LayoutManager = {}

-- Constantes de layout
local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 900
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 75
local SLIDER_HEIGHT = 50
local SECTION_SPACING = 40 -- Espaciado entre secciones
local TAB_HEIGHT = 30 -- Altura de las pestañas
local TAB_WIDTH = 120 -- Ancho de cada pestaña

-- PESTAÑAS DEL SISTEMA
function LayoutManager:GetTabsPosition()
    return {
        startY = -30, -- Justo después del título
        tabHeight = TAB_HEIGHT,
        tabWidth = TAB_WIDTH,
        spacing = 5, -- Espaciado entre pestañas
        tabs = {
            {name = "General", key = "general"},
            {name = "Filters", key = "filters"}
        }
    }
end

-- Área de contenido de las pestañas (debajo de las pestañas)
function LayoutManager:GetTabContentArea()
    local tabsPos = self:GetTabsPosition()
    return {
        startY = tabsPos.startY - TAB_HEIGHT - 10, -- 10px después de las pestañas
        contentHeight = WINDOW_HEIGHT - 100 -- Espacio disponible para contenido
    }
end

-- SECCIÓN 1: SLIDERS DE POSICIÓN Y TAMAÑO (Top)
function LayoutManager:GetPositionSlidersPosition()
    local contentArea = self:GetTabContentArea()
    local startY = contentArea.startY -- Comenzar después de las pestañas
    return {
        startY = startY,
        sliderHeight = SLIDER_HEIGHT,
        sliderCount = 3 -- iconSize, positionX, positionY
    }
end

function LayoutManager:GetPositionButtonPosition()
    local positionSection = self:GetPositionSlidersPosition()
    local sectionEndY = positionSection.startY - (positionSection.sliderCount * SLIDER_HEIGHT)
    
    -- Calcular posición para botón Unlock (lado izquierdo)
    local buttonSpacing = 20
    local buttonX = (WINDOW_WIDTH / 2) - (BUTTON_WIDTH / 2) - buttonSpacing
    
    return {
        y = sectionEndY - 15, -- 15px separación después de sliders
        x = buttonX,
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT
    }
end

-- Nueva función para posición del checkbox Show Spell Names (al lado del Unlock)
function LayoutManager:GetShowSpellNamesCheckboxPosition()
    local positionButtonPos = self:GetPositionButtonPosition()
    local checkboxSpacing = 20
    local checkboxX = positionButtonPos.x + BUTTON_WIDTH + checkboxSpacing
    
    return {
        y = positionButtonPos.y,
        x = checkboxX,
        spacing = 30
    }
end

-- SECCIÓN 2: DROPDOWN DE ANIMACIONES (Middle)
function LayoutManager:GetAnimationDropdownPosition()
    local positionButtonPos = self:GetPositionButtonPosition()
    local startY = positionButtonPos.y - BUTTON_HEIGHT - SECTION_SPACING
    
    return {
        startY = startY,
        x = 40
    }
end

-- SECCIÓN 3: SLIDERS DE ANIMACIÓN (Bottom)
function LayoutManager:GetAnimationSlidersPosition(animationSliderCount)
    local dropdownPos = self:GetAnimationDropdownPosition()
    local startY = dropdownPos.startY - 35 -- 35px después del dropdown

    return {
        startY = startY,
        sliderHeight = SLIDER_HEIGHT,
        sliderCount = animationSliderCount
    }
end

function LayoutManager:GetAnimationButtonsPosition(animationSliderCount)
    local slidersPos = self:GetAnimationSlidersPosition(animationSliderCount)
    local sectionEndY = slidersPos.startY - (slidersPos.sliderCount * SLIDER_HEIGHT)
    
    -- Calcular posición centrada para 3 botones (Test, Edit/Save, Reset Anim)
    local totalButtonsWidth = (BUTTON_WIDTH * 3) + (10 * 2) -- 3 botones + 2 espacios
    local startX = (WINDOW_WIDTH - totalButtonsWidth) / 2
    
    return {
        y = sectionEndY - 15, -- 15px separación después de sliders
        startX = startX,
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT,
        spacing = 10
    }
end

-- SECCIÓN 4: CHECKBOXES Y EDITBOXES (Bottom)
function LayoutManager:GetCheckboxesPosition(animationSliderCount)
    local buttonsPos = self:GetAnimationButtonsPosition(animationSliderCount)
    local startY = buttonsPos.y - BUTTON_HEIGHT - SECTION_SPACING
    
    return {
        startY = startY,
        x = 20,
        spacing = 30
    }
end

function LayoutManager:GetEditBoxesPosition(animationSliderCount)
    local buttonsPos = self:GetAnimationButtonsPosition(animationSliderCount)
    local startY = buttonsPos.y - BUTTON_HEIGHT - SECTION_SPACING -- Después de botones
    
    return {
        startY = startY,
        x = 20
    }
end
    
-- Calcular posición de los dropdowns (LEGACY - mantenido para compatibilidad)
function LayoutManager:GetDropdownsPosition()
    -- Ahora usa la nueva función GetAnimationDropdownPosition
    return self:GetAnimationDropdownPosition()
end

-- Calcular posición de botones principales (LEGACY - mantenido para compatibilidad)
function LayoutManager:GetMainButtonsPosition(sliderCount)
    -- Ahora usa la nueva función GetAnimationButtonsPosition
    return self:GetAnimationButtonsPosition(sliderCount or 6)
end

-- Obtener constantes de layout
function LayoutManager:GetConstants()
    return {
        WINDOW_WIDTH = WINDOW_WIDTH,
        WINDOW_HEIGHT = WINDOW_HEIGHT,
        SLIDER_HEIGHT = SLIDER_HEIGHT,
        BUTTON_HEIGHT = BUTTON_HEIGHT,
        BUTTON_WIDTH = BUTTON_WIDTH,
        SECTION_SPACING = SECTION_SPACING,
        TAB_HEIGHT = TAB_HEIGHT,
        TAB_WIDTH = TAB_WIDTH
    }
end

-- PESTAÑA DE FILTROS - Layout específico
function LayoutManager:GetFiltersTabLayout()
    local contentArea = self:GetTabContentArea()
    
    return {
        -- Input para agregar nuevos filtros (ahora al top)
        addInput = {
            x = 20,
            y = contentArea.startY - 20,
            width = 250,
            height = 25,
            label = "Add Spell/Item (name or ID):"
        },
        
        -- Botón para agregar
        addButton = {
            x = 280,
            y = contentArea.startY - 20,
            width = 60,
            height = 25
        },
        
        -- Lista de filtros (scroll frame)
        filtersList = {
            x = 20,
            y = contentArea.startY - 60,
            width = 360,
            height = 400,
            itemHeight = 25,
            spacing = 2
        },
        
        -- Botones de acción
        clearAllButton = {
            x = 20,
            y = contentArea.startY - 480,
            width = 80,
            height = 25
        },
        
        importExportButton = {
            x = 110,
            y = contentArea.startY - 480,
            width = 100,
            height = 25
        },
        
        -- Checkbox de inversión (whitelist mode) - movido después de los botones
        invertCheckbox = {
            x = 20,
            y = contentArea.startY - 520
        }
    }
end
-- Exportar globalmente para WoW addon system
_G.LayoutManager = LayoutManager

return LayoutManager
