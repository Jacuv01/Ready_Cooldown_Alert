local MainFrame = {}

local frame = nil
local texture = nil
local textFrame = nil

function MainFrame:Initialize()
    if frame then
        return
    end
    
    frame = CreateFrame("Frame", "ReadyCooldownAlertMainFrame", UIParent)
    local initialSize = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.iconSize) or 75
    frame:SetSize(initialSize, initialSize)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:SetMovable(false)
    frame:EnableMouse(false)
    
    texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetTexture(nil)
    
    textFrame = frame:CreateFontString(nil, "ARTWORK")
    textFrame:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    textFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, -20)
    textFrame:SetText("")
    
    self:LoadPosition()
    frame:SetAlpha(0)
    frame:Hide()
end

function MainFrame:LoadPosition()
    if not frame or not ReadyCooldownAlertDB then
        return
    end
    
    local x = ReadyCooldownAlertDB.positionX
    local y = ReadyCooldownAlertDB.positionY
    
    if not x then
        x = (GetScreenWidth() or 1920) / 2
        ReadyCooldownAlertDB.positionX = x
    end
    if not y then
        y = (GetScreenHeight() or 1080) / 2
        ReadyCooldownAlertDB.positionY = y
    end
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

function MainFrame:UpdatePosition()
    self:LoadPosition()
end

function MainFrame:UpdateSize()
    if not frame or not ReadyCooldownAlertDB then
        return
    end
    
    local newSize = ReadyCooldownAlertDB.iconSize or 75
    frame:SetSize(newSize, newSize)
    
    if frame:IsShown() then
        self:UpdatePosition()
    end
end

function MainFrame:OnAnimationEvent(eventType, animationData)
    if not frame then
        self:Initialize()
    end
    
    if eventType == "start" then
        self:StartAnimation(animationData)
    elseif eventType == "update" then
        self:UpdateAnimation(animationData)
    elseif eventType == "end" then
        self:EndAnimation()
    end
end

function MainFrame:StartAnimation(animation)
    if not animation then return end
    
    if frame and not frame:IsShown() then
        frame:Show()
    end
    
    if texture then
        local TextureValidator = rawget(_G, "TextureValidator")
        if TextureValidator then
            TextureValidator:SafeSetTexture(texture, animation.texture, "StartAnimation")
        else
            local validTexture = animation.texture or 135808
            texture:SetTexture(validTexture)
        end
    end
    
    if textFrame then
        if animation.name and ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName ~= false then
            textFrame:SetText(animation.name)
        else
            textFrame:SetText("")
        end
    end
    
    if texture then
        if animation.isPet and ReadyCooldownAlertDB and ReadyCooldownAlertDB.petOverlay then
            texture:SetVertexColor(unpack(ReadyCooldownAlertDB.petOverlay))
        else
            texture:SetVertexColor(1, 1, 1)
        end
    end
end

function MainFrame:UpdateAnimation(animationData)
    if not animationData or not frame then return end
    
    if animationData.alpha and frame then
        local validAlpha = math.max(0, math.min(1, animationData.alpha))
        frame:SetAlpha(validAlpha)
    end
    
    if animationData.width and animationData.height and frame then
        frame:SetSize(animationData.width, animationData.height)
    end
    
    if animationData.petOverlay and texture then
        texture:SetVertexColor(unpack(animationData.petOverlay))
    end
end

function MainFrame:EndAnimation()
    if not frame then return end
    
    if texture then
        local TextureValidator = rawget(_G, "TextureValidator")
        if TextureValidator then
            TextureValidator:SafeSetTexture(texture, nil, "EndAnimation", "")
        else
            texture:SetTexture("")
        end
    end
    
    if textFrame then
        textFrame:SetText("")
    end
    
    if texture then
        texture:SetVertexColor(1, 1, 1)
    end
    
    frame:SetAlpha(0)
    frame:Hide()
end

function MainFrame:ShowForPositioning()
    if not frame then
        self:Initialize()
    end
    
    self:UpdateSize()
    
    if frame then
        frame:Show()
        frame:SetAlpha(0.7)
    end
    
    local TextureValidator = rawget(_G, "TextureValidator")
    if TextureValidator and texture then
        TextureValidator:SafeSetTexture(texture, 135808, "ShowForPositioning")
    elseif texture then
        texture:SetTexture(135808)
    end
    
    if textFrame then
        textFrame:SetText("Position Preview")
    end
    
    self:UpdatePosition()
    self:UpdateSize()
end

function MainFrame:HideFromPositioning()
    if not frame then return end
    
    local TextureValidator = rawget(_G, "TextureValidator")
    if TextureValidator and texture then
        TextureValidator:SafeSetTexture(texture, nil, "HideFromPositioning", "")
    elseif texture then
        texture:SetTexture("")
    end
    
    if textFrame then
        textFrame:SetText("")
    end
    
    if texture then
        texture:SetVertexColor(1, 1, 1)
    end
    
    frame:Hide()
end

function MainFrame:TestAnimation()
    local testAnimation = {
        texture = 135808,
        isPet = false,
        name = "Test Spell"
    }
    
    self:StartAnimation(testAnimation)
    
    local testUpdate = {
        alpha = ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha or 0.7,
        width = ReadyCooldownAlertDB and ReadyCooldownAlertDB.iconSize or 100,
        height = ReadyCooldownAlertDB and ReadyCooldownAlertDB.iconSize or 100,
        phase = "hold",
        progress = 0.5
    }
    
    self:UpdateAnimation(testUpdate)
    
    C_Timer.After(2, function()
        self:EndAnimation()
    end)
end

function MainFrame:GetFrameInfo()
    if not frame then
        return nil
    end
    
    return {
        isShown = frame:IsShown(),
        alpha = frame:GetAlpha(),
        width = frame:GetWidth(),
        height = frame:GetHeight(),
        position = {
            x = frame:GetLeft() and (frame:GetLeft() + frame:GetWidth() / 2) or 0,
            y = frame:GetBottom() and (frame:GetBottom() + frame:GetHeight() / 2) or 0
        }
    }
end

function MainFrame:ResetPosition()
    if not frame then
        self:Initialize()
    end
    
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    if ReadyCooldownAlertDB then
        ReadyCooldownAlertDB.positionX = (GetScreenWidth() or 1920) / 2
        ReadyCooldownAlertDB.positionY = (GetScreenHeight() or 1080) / 2
    end
end

_G.MainFrame = MainFrame
return MainFrame
