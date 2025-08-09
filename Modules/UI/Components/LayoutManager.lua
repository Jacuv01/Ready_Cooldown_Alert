local LayoutManager = {}

local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 900
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 75
local SLIDER_HEIGHT = 50
local SECTION_SPACING = 40
local TAB_HEIGHT = 30
local TAB_WIDTH = 120

function LayoutManager:GetTabsPosition()
    return {
        startY = -30,
        tabHeight = TAB_HEIGHT,
        tabWidth = TAB_WIDTH,
        spacing = 5,
        tabs = {
            {name = "General", key = "general"},
            {name = "Filters", key = "filters"}
        }
    }
end

function LayoutManager:GetTabContentArea()
    local tabsPos = self:GetTabsPosition()
    return {
        startY = tabsPos.startY - TAB_HEIGHT - 10,
        contentHeight = WINDOW_HEIGHT - 100
    }
end

function LayoutManager:GetPositionSlidersPosition()
    local contentArea = self:GetTabContentArea()
    return {
        startY = contentArea.startY,
        sliderHeight = SLIDER_HEIGHT,
        sliderCount = 3
    }
end

function LayoutManager:GetPositionButtonPosition()
    local positionSection = self:GetPositionSlidersPosition()
    local sectionEndY = positionSection.startY - (positionSection.sliderCount * SLIDER_HEIGHT)
    local buttonX = (WINDOW_WIDTH / 2) - (BUTTON_WIDTH / 2) - 20
    
    return {
        y = sectionEndY - 15,
        x = buttonX,
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT
    }
end

function LayoutManager:GetShowSpellNamesCheckboxPosition()
    local positionButtonPos = self:GetPositionButtonPosition()
    local checkboxX = positionButtonPos.x + BUTTON_WIDTH + 20
    
    return {
        y = positionButtonPos.y,
        x = checkboxX,
        spacing = 30
    }
end

function LayoutManager:GetAnimationDropdownPosition()
    local positionButtonPos = self:GetPositionButtonPosition()
    local startY = positionButtonPos.y - BUTTON_HEIGHT - SECTION_SPACING
    
    return {
        startY = startY,
        x = 40
    }
end

function LayoutManager:GetAnimationSlidersPosition(animationSliderCount)
    local dropdownPos = self:GetAnimationDropdownPosition()
    local startY = dropdownPos.startY - 35
    
    return {
        startY = startY,
        sliderHeight = SLIDER_HEIGHT,
        sliderCount = animationSliderCount
    }
end

function LayoutManager:GetAnimationButtonsPosition(animationSliderCount)
    local slidersPos = self:GetAnimationSlidersPosition(animationSliderCount)
    local sectionEndY = slidersPos.startY - (slidersPos.sliderCount * SLIDER_HEIGHT)
    local totalButtonsWidth = (BUTTON_WIDTH * 3) + (10 * 2)
    local startX = (WINDOW_WIDTH - totalButtonsWidth) / 2
    
    return {
        y = sectionEndY - 15,
        startX = startX,
        buttonWidth = BUTTON_WIDTH,
        buttonHeight = BUTTON_HEIGHT,
        spacing = 10
    }
end

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
    local startY = buttonsPos.y - BUTTON_HEIGHT - SECTION_SPACING
    
    return {
        startY = startY,
        x = 20
    }
end

function LayoutManager:GetDropdownsPosition()
    return self:GetAnimationDropdownPosition()
end

function LayoutManager:GetMainButtonsPosition(sliderCount)
    return self:GetAnimationButtonsPosition(sliderCount or 6)
end

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

function LayoutManager:GetFiltersTabLayout()
    local contentArea = self:GetTabContentArea()
    
    return {
        addInput = {
            x = 20,
            y = contentArea.startY - 20,
            width = 250,
            height = 25,
            label = "Add Spell/Item (name or ID):"
        },
        addButton = {
            x = 280,
            y = contentArea.startY - 20,
            width = 60,
            height = 25
        },
        filtersList = {
            x = 20,
            y = contentArea.startY - 60,
            width = 360,
            height = 400,
            itemHeight = 25,
            spacing = 2
        },
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
        invertCheckbox = {
            x = 20,
            y = contentArea.startY - 520
        }
    }
end

_G.LayoutManager = LayoutManager
return LayoutManager
