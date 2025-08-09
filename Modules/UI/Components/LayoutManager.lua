local LayoutManager = {}

local function GetUIConstants()
    local OptionsFrame = rawget(_G, "OptionsFrame")
    if OptionsFrame and OptionsFrame.GetConstants then
        return OptionsFrame:GetConstants()
    end
    
    return {
        WINDOW_WIDTH = 400,
        WINDOW_HEIGHT = 900,
        BUTTON_HEIGHT = 25,
        BUTTON_WIDTH = 75,
        SLIDER_HEIGHT = 50,
        SECTION_SPACING = 40,
        TAB_HEIGHT = 30,
        TAB_WIDTH = 120
    }
end

function LayoutManager:GetTabsPosition()
    local constants = GetUIConstants()
    return {
        startY = -30,
        tabHeight = constants.TAB_HEIGHT,
        tabWidth = constants.TAB_WIDTH,
        spacing = 5,
        tabs = {
            {name = "General", key = "general"},
            {name = "Filters", key = "filters"}
        }
    }
end

function LayoutManager:GetTabContentArea()
    local constants = GetUIConstants()
    local tabsPos = self:GetTabsPosition()
    return {
        startY = tabsPos.startY - constants.TAB_HEIGHT - 10,
        contentHeight = constants.WINDOW_HEIGHT - 100
    }
end

function LayoutManager:GetPositionSlidersPosition()
    local constants = GetUIConstants()
    local contentArea = self:GetTabContentArea()
    return {
        startY = contentArea.startY,
        sliderHeight = constants.SLIDER_HEIGHT,
        sliderCount = 3
    }
end

function LayoutManager:GetPositionButtonPosition()
    local constants = GetUIConstants()
    local positionSection = self:GetPositionSlidersPosition()
    local sectionEndY = positionSection.startY - (positionSection.sliderCount * constants.SLIDER_HEIGHT)
    local buttonX = (constants.WINDOW_WIDTH / 2) - (constants.BUTTON_WIDTH / 2) - 20
    
    return {
        y = sectionEndY - 15,
        x = buttonX,
        buttonWidth = constants.BUTTON_WIDTH,
        buttonHeight = constants.BUTTON_HEIGHT
    }
end

function LayoutManager:GetShowSpellNamesCheckboxPosition()
    local constants = GetUIConstants()
    local positionButtonPos = self:GetPositionButtonPosition()
    local checkboxX = positionButtonPos.x + constants.BUTTON_WIDTH + 20
    
    return {
        y = positionButtonPos.y,
        x = checkboxX,
        spacing = 30
    }
end

function LayoutManager:GetAnimationDropdownPosition()
    local constants = GetUIConstants()
    local positionButtonPos = self:GetPositionButtonPosition()
    local startY = positionButtonPos.y - constants.BUTTON_HEIGHT - constants.SECTION_SPACING
    
    return {
        startY = startY,
        x = 40
    }
end

function LayoutManager:GetAnimationSlidersPosition(animationSliderCount)
    local constants = GetUIConstants()
    local dropdownPos = self:GetAnimationDropdownPosition()
    local startY = dropdownPos.startY - 35
    
    return {
        startY = startY,
        sliderHeight = constants.SLIDER_HEIGHT,
        sliderCount = animationSliderCount
    }
end

function LayoutManager:GetAnimationButtonsPosition(animationSliderCount)
    local constants = GetUIConstants()
    local slidersPos = self:GetAnimationSlidersPosition(animationSliderCount)
    local sectionEndY = slidersPos.startY - (slidersPos.sliderCount * constants.SLIDER_HEIGHT)
    local totalButtonsWidth = (constants.BUTTON_WIDTH * 3) + (10 * 2)
    local startX = (constants.WINDOW_WIDTH - totalButtonsWidth) / 2
    
    return {
        y = sectionEndY - 15,
        startX = startX,
        buttonWidth = constants.BUTTON_WIDTH,
        buttonHeight = constants.BUTTON_HEIGHT,
        spacing = 10
    }
end

function LayoutManager:GetCheckboxesPosition(animationSliderCount)
    local constants = GetUIConstants()
    local buttonsPos = self:GetAnimationButtonsPosition(animationSliderCount)
    local startY = buttonsPos.y - constants.BUTTON_HEIGHT - constants.SECTION_SPACING
    
    return {
        startY = startY,
        x = 20,
        spacing = 30
    }
end

function LayoutManager:GetEditBoxesPosition(animationSliderCount)
    local constants = GetUIConstants()
    local buttonsPos = self:GetAnimationButtonsPosition(animationSliderCount)
    local startY = buttonsPos.y - constants.BUTTON_HEIGHT - constants.SECTION_SPACING
    
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
    return GetUIConstants()
end

function LayoutManager:GetFiltersTabLayout()
    local constants = GetUIConstants()
    local contentArea = self:GetTabContentArea()
    local centerX = constants.WINDOW_WIDTH / 2
    
    return {
        addInput = {
            x = centerX - 155,
            y = contentArea.startY - 20,
            width = 250,
            height = 25,
            label = "Add Spell/Item (name or ID):"
        },
        addButton = {
            x = centerX + 95,
            y = contentArea.startY - 20,
            width = 60,
            height = 25
        },
        helpNote = {
            x = centerX - 155,
            y = contentArea.startY - 50,
            width = 360,
            text = "Tip: If you can't find a spell in suggestions, try using its Spell ID instead"
        },
        filtersList = {
            x = centerX - 180,
            y = contentArea.startY - 75,
            width = 340,
            height = 385,
            itemHeight = 25,
            spacing = 2
        },
        clearAllButton = {
            x = centerX - 180,
            y = contentArea.startY - 480,
            width = 80,
            height = 25
        },
        invertCheckbox = {
            x = centerX - 180,
            y = contentArea.startY - 520
        }
    }
end

_G.LayoutManager = LayoutManager
return LayoutManager
