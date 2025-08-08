local LayoutManager = {}

-- Constantes de layout
local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 900
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 75
local SLIDER_HEIGHT = 50
local SECTION_SPACING = 40 -- Espaciado entre secciones

-- SECCIÓN 1: SLIDERS DE POSICIÓN Y TAMAÑO (Top)
function LayoutManager:GetPositionSlidersPosition()
    local startY = -60 -- Comenzar después del título
    return {
        startY = startY,
        sliderHeight = SLIDER_HEIGHT,
        sliderCount = 3 -- iconSize, positionX, positionY
    }
end

function LayoutManager:GetPositionButtonPosition()
    local positionSection = self:GetPositionSlidersPosition()
    local sectionEndY = positionSection.startY - (positionSection.sliderCount * SLIDER_HEIGHT)
    
    return {
        y = sectionEndY - 15, -- 15px separación después de sliders
        x = (WINDOW_WIDTH - BUTTON_WIDTH) / 2, -- Centrado
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT
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
    local checkboxPos = self:GetCheckboxesPosition(animationSliderCount)
    local startY = checkboxPos.startY - 80 -- Después de checkboxes
    
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
        SECTION_SPACING = SECTION_SPACING
    }
end

-- Calcular posición de botones inferiores (Reset All, Close)
function LayoutManager:GetBottomButtonsPosition()
    return {
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT
    }
end

-- Exportar globalmente para WoW addon system
_G.LayoutManager = LayoutManager

return LayoutManager
