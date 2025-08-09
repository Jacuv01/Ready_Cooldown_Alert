local TabManager = {}

local tabs = {}
local activeTab = "general"
local tabButtons = {}
local contentFrames = {}

function TabManager:Initialize(parentFrame, layoutManager)
    self.parentFrame = parentFrame
    self.layoutManager = layoutManager
    self:CreateTabs()
    self:CreateContentFrames()
    self:ShowTab("general")
end

function TabManager:CreateTabs()
    local tabsLayout = self.layoutManager:GetTabsPosition()
    
    local totalTabsWidth = (#tabsLayout.tabs * tabsLayout.tabWidth) + ((#tabsLayout.tabs - 1) * tabsLayout.spacing)
    local startX = -totalTabsWidth / 2 + tabsLayout.tabWidth / 2
    
    for i, tabInfo in ipairs(tabsLayout.tabs) do
        local tabButton = CreateFrame("Button", nil, self.parentFrame, "UIPanelButtonTemplate")
        local x = startX + (i - 1) * (tabsLayout.tabWidth + tabsLayout.spacing)
        
        tabButton:SetPoint("TOP", self.parentFrame, "TOP", x, tabsLayout.startY)
        tabButton:SetSize(tabsLayout.tabWidth, tabsLayout.tabHeight)
        tabButton:SetText(tabInfo.name)
        tabButton:SetNormalFontObject("GameFontNormal")
        tabButton:SetScript("OnClick", function()
            self:ShowTab(tabInfo.key)
        end)
        
        tabButtons[tabInfo.key] = tabButton
        tabs[tabInfo.key] = tabInfo
    end
end

function TabManager:CreateContentFrames()
    local contentArea = self.layoutManager:GetTabContentArea()
    
    for tabKey, _ in pairs(tabs) do
        local contentFrame = CreateFrame("Frame", nil, self.parentFrame)
        contentFrame:SetPoint("TOPLEFT", self.parentFrame, "TOPLEFT", 0, contentArea.startY)
        contentFrame:SetSize(400, contentArea.contentHeight)
        contentFrame:Hide()
        contentFrames[tabKey] = contentFrame
    end
end

function TabManager:ShowTab(tabKey)
    if not tabs[tabKey] then
        return
    end
    
    for key, frame in pairs(contentFrames) do
        frame:Hide()
    end
    
    for key, button in pairs(tabButtons) do
        if key == tabKey then
            button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab-BGSelected")
            button:SetText("|cFFFFFF00" .. tabs[key].name .. "|r")
        else
            button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab-BGInactive")
            button:SetText("|cFFAAAAAA" .. tabs[key].name .. "|r")
        end
    end
    
    contentFrames[tabKey]:Show()
    activeTab = tabKey
    self:OnTabChanged(tabKey)
end

function TabManager:OnTabChanged(tabKey)
    if self.onTabChangedCallback then
        self.onTabChangedCallback(tabKey)
    end
end

function TabManager:SetTabChangedCallback(callback)
    self.onTabChangedCallback = callback
end

function TabManager:GetContentFrame(tabKey)
    return contentFrames[tabKey]
end

function TabManager:GetActiveTab()
    return activeTab
end

function TabManager:AddContentToTab(tabKey, contentCreationFunction)
    local contentFrame = self:GetContentFrame(tabKey)
    if contentFrame and contentCreationFunction then
        contentCreationFunction(contentFrame)
    end
end

_G.TabManager = TabManager
return TabManager
