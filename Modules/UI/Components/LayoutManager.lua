local LayoutManager = {}

-- Constantes de layout
local WINDOW_WIDTH = 400
local SLIDER_START_Y = -80
local SLIDER_HEIGHT = 50
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 75

-- Calcular posición final de los sliders
function LayoutManager:GetSlidersEndPosition(sliderCount)
    return SLIDER_START_Y - (sliderCount * SLIDER_HEIGHT)
end

-- Calcular posición de los botones principales (centrados)
function LayoutManager:GetMainButtonsPosition(sliderCount)
    local slidersEndPosition = self:GetSlidersEndPosition(sliderCount)
    local buttonRowY = slidersEndPosition - 30 -- 30px de separación después de los sliders
    
    -- Calcular posición centrada para 3 botones
    local totalButtonsWidth = (BUTTON_WIDTH * 3) + (10 * 2) -- 3 botones + 2 espacios de separación
    local startX = (WINDOW_WIDTH - totalButtonsWidth) / 2 -- Centrar en la ventana
    
    return {
        y = buttonRowY,
        startX = startX,
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT,
        spacing = 10
    }
end

-- Calcular posición de los checkboxes
function LayoutManager:GetCheckboxesPosition(sliderCount)
    local slidersEndPosition = self:GetSlidersEndPosition(sliderCount)
    local yOffset = slidersEndPosition - 30 - 25 - 40 -- Después de sliders, botones y separación
    
    return {
        startY = yOffset,
        x = 20,
        spacing = 30
    }
end

-- Calcular posición de los edit boxes
function LayoutManager:GetEditBoxesPosition(sliderCount)
    local slidersEndPosition = self:GetSlidersEndPosition(sliderCount)
    local yOffset = slidersEndPosition - 30 - 25 - 40 - 60 -- Después de sliders, botones, checkboxes
    
    return {
        startY = yOffset,
        x = 20
    }
end

-- Calcular posición de los dropdowns
function LayoutManager:GetDropdownsPosition()
    return {
        startY = -40,
        x = 20
    }
end

-- Obtener constantes de layout
function LayoutManager:GetConstants()
    return {
        WINDOW_WIDTH = WINDOW_WIDTH,
        SLIDER_START_Y = SLIDER_START_Y,
        SLIDER_HEIGHT = SLIDER_HEIGHT,
        BUTTON_HEIGHT = BUTTON_HEIGHT,
        BUTTON_WIDTH = BUTTON_WIDTH
    }
end

-- Exportar globalmente para WoW addon system
_G.LayoutManager = LayoutManager

return LayoutManager
