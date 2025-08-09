local OptionsFrame = {}

local WINDOW_WIDTH = 400
local WINDOW_HEIGHT = 780
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 75
local SLIDER_HEIGHT = 50
local SECTION_SPACING = 40
local TAB_HEIGHT = 30
local TAB_WIDTH = 120

local optionsFrame = nil
local layoutManager = nil
local sliderManager = nil
local buttonManager = nil
local controlsManager = nil
local uiElements = {}
local isEditing = false
local isUnlocked = false
function OptionsFrame:Initialize()
    if optionsFrame then
        return
    end
    
    self:LoadComponents()
    self:CreateMainFrame()
    self:CreateUIElements()
    self:FinalizeUIElements()
    self:InitializeState()
end
function OptionsFrame:LoadComponents()
    layoutManager = rawget(_G, "LayoutManager")
    sliderManager = rawget(_G, "SliderManager")
    buttonManager = rawget(_G, "ButtonManager")
    controlsManager = rawget(_G, "ControlsManager")
    
    self.tabManager = rawget(_G, "TabManager")
    self.filtersUI = rawget(_G, "FiltersUI")
end
function OptionsFrame:CreateMainFrame()
    optionsFrame = CreateFrame("MessageFrame", "ReadyCooldownAlertOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("MEDIUM")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    
    optionsFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local focusedFrame = GetCurrentKeyBoardFocus()
            if focusedFrame and focusedFrame.ClearFocus then
                focusedFrame:ClearFocus()
            end
        end
    end)
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    
    optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY")
    optionsFrame.title:SetFontObject("GameFontHighlight")
    optionsFrame.title:SetPoint("CENTER", optionsFrame.TitleBg, "CENTER", 0, 0)
    optionsFrame.title:SetText("Ready Cooldown Alert - Options")
    optionsFrame.title:SetTextColor(1, 0.82, 0, 1)
end
function OptionsFrame:CreateUIElements()
    if self.tabManager then
        self.tabManager:Initialize(optionsFrame, layoutManager)
        
        self.tabManager:SetTabChangedCallback(function(tabKey)
            self:OnTabChanged(tabKey)
        end)
        
        self:CreateGeneralTabContent()
        self:CreateFiltersTabContent()
    else
        self:CreateLegacyUI()
    end
end
function OptionsFrame:CreateGeneralTabContent()
    local generalFrame = self.tabManager:GetContentFrame("general")
    if not generalFrame then return end
    
    local sliderCount = #(_G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {})
    
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
function OptionsFrame:CreateFiltersTabContent()
    local filtersFrame = self.tabManager:GetContentFrame("filters")
    if not filtersFrame then return end
    
    if self.filtersUI then
        self.filtersUI:Initialize(filtersFrame, layoutManager)
    end
end
function OptionsFrame:CreateLegacyUI()
    local sliderCount = #(_G.OptionsLogic and _G.OptionsLogic:GetSliderConfigs() or {})
    
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
function OptionsFrame:OnTabChanged(tabKey)
    if tabKey == "filters" and self.filtersUI then
        self.filtersUI:RefreshFiltersList()
    end
end
function OptionsFrame:FinalizeUIElements()
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    if sliderManager then
        sliderManager:UpdateSlidersForAnimation(selectedAnimation)
    end
end
function OptionsFrame:InitializeState()
    isEditing = false
    isUnlocked = false
    
    if sliderManager then
        sliderManager:SetAnimationSlidersEnabled(false)
        sliderManager:SetPositionAndSizeSlidersEnabled(false)
    end
    
    if optionsFrame then
        optionsFrame:Hide()
    end
end
function OptionsFrame:SetAnimationSlidersEnabled(enabled)
    if sliderManager then
        sliderManager:SetAnimationSlidersEnabled(enabled)
    end
    isEditing = enabled
end

function OptionsFrame:SetPositionAndSizeSlidersEnabled(enabled)
    if sliderManager then
        sliderManager:SetPositionAndSizeSlidersEnabled(enabled)
    end
    isUnlocked = enabled
end

function OptionsFrame:IsEditing()
    return isEditing
end

function OptionsFrame:UpdateSlidersForAnimation(animationType)
    if sliderManager then
        sliderManager:UpdateSlidersForAnimation(animationType)
    end
end
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

function OptionsFrame:RefreshValues()
    if sliderManager then
        sliderManager:RefreshValues()
    end
    if controlsManager then
        controlsManager:RefreshValues()
    end
end

function OptionsFrame:OnConfigChanged(key, value)
    if _G.OptionsLogic then
        return _G.OptionsLogic:OnConfigChanged(key, value)
    end
end

function OptionsFrame:OnTestClicked()
    if _G.OptionsLogic then
        _G.OptionsLogic:OnTestClicked()
    end
end
function OptionsFrame:OnEditSaveClicked()
    if not buttonManager or not _G.OptionsLogic then return end
    
    if isEditing then
        local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
        _G.OptionsLogic:SaveAnimationConfiguration(currentAnimation)
        
        isEditing = false
        self:SetAnimationSlidersEnabled(false)
        buttonManager:UpdateEditButton(false)
    else
        local currentAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
        
        isEditing = true
        self:SetAnimationSlidersEnabled(true)
        buttonManager:UpdateEditButton(true)
        
        self:RefreshValues()
    end
end
function OptionsFrame:OnUnlockClicked()
    if not buttonManager or not _G.OptionsLogic then return end
    
    if isUnlocked then
        isUnlocked = false
        self:SetPositionAndSizeSlidersEnabled(false)
        buttonManager:UpdateUnlockButton(false)
        
        local MainFrame = rawget(_G, "MainFrame")
        if MainFrame then
            MainFrame:HideFromPositioning()
        end
    else
        isUnlocked = true
        self:SetPositionAndSizeSlidersEnabled(true)
        buttonManager:UpdateUnlockButton(true)
        
        local MainFrame = rawget(_G, "MainFrame")
        if MainFrame then
            MainFrame:ShowForPositioning()
        end
    end
end

function OptionsFrame:GetConstants()
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

_G.OptionsFrame = OptionsFrame

return OptionsFrame
