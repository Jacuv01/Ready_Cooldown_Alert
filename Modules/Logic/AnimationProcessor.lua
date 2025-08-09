local AnimationProcessor = {}

local currentAnimation = nil
local animationQueue = {}
local runtimer = 0

local fadeInTime = 0.3
local fadeOutTime = 0.7
local maxAlpha = 0.7
local animScale = 1.5
local iconSize = 75
local holdTime = 0
local showSpellName = true
local petOverlay = {1, 1, 1}

AnimationProcessor.uiCallbacks = {}
AnimationProcessor.completionCallbacks = {}

function AnimationProcessor:RegisterUICallback(callback)
    table.insert(self.uiCallbacks, callback)
end

function AnimationProcessor:RegisterCompletionCallback(callback)
    table.insert(self.completionCallbacks, callback)
end

function AnimationProcessor:RefreshConfig()
    if ReadyCooldownAlertDB then
        fadeInTime = ReadyCooldownAlertDB.fadeInTime or 0.3
        fadeOutTime = ReadyCooldownAlertDB.fadeOutTime or 0.7
        maxAlpha = ReadyCooldownAlertDB.maxAlpha or 0.7
        animScale = ReadyCooldownAlertDB.animScale or 1.5
        iconSize = ReadyCooldownAlertDB.iconSize or 75
        holdTime = ReadyCooldownAlertDB.holdTime or 0
        showSpellName = ReadyCooldownAlertDB.showSpellName ~= false
        petOverlay = ReadyCooldownAlertDB.petOverlay or {1, 1, 1}
    end
end

function AnimationProcessor:QueueAnimation(texture, isPet, name, uniqueId)
    local TextureValidator = rawget(_G, "TextureValidator")
    local validTexture = texture
    
    if TextureValidator then
        validTexture = TextureValidator:GetValidTexture(texture, "AnimationProcessor_QueueAnimation")
    end
    
    local animation = {
        texture = validTexture,
        isPet = isPet,
        name = name,
        uniqueId = uniqueId,
        timestamp = GetTime()
    }
    
    table.insert(animationQueue, animation)
    
    if not currentAnimation then
        self:StartNextAnimation()
    end
end

function AnimationProcessor:StartNextAnimation()
    if #animationQueue > 0 then
        currentAnimation = table.remove(animationQueue, 1)
        runtimer = 0
        
        self:NotifyUIStart(currentAnimation)
        self:StartOnUpdate()
    else
        currentAnimation = nil
        self:StopOnUpdate()
    end
end

function AnimationProcessor:NotifyUIStart(animation)
    for _, callback in ipairs(self.uiCallbacks) do
        callback("start", animation)
    end
end

function AnimationProcessor:NotifyUIUpdate(animationData)
    for _, callback in ipairs(self.uiCallbacks) do
        callback("update", animationData)
    end
end

function AnimationProcessor:NotifyUIEnd()
    for _, callback in ipairs(self.uiCallbacks) do
        callback("end", nil)
    end
end

function AnimationProcessor:StartOnUpdate()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    if not self.frame:GetScript("OnUpdate") then
        self.frame:SetScript("OnUpdate", function(_, update)
            self:OnUpdate(update)
        end)
    end
end

function AnimationProcessor:StopOnUpdate()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
end

function AnimationProcessor:OnUpdate(update)
    if not currentAnimation then
        self:StartNextAnimation()
        return
    end
    
    runtimer = runtimer + update
    
    local selectedAnimationId = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    local totalTime = fadeInTime + holdTime + fadeOutTime
    
    local AnimationData = rawget(_G, "AnimationData")
    if AnimationData then
        local animationConfig = AnimationData:GetAnimationConfig(selectedAnimationId)
        if animationConfig then
            totalTime = animationConfig.fadeInTime + animationConfig.holdTime + animationConfig.fadeOutTime
        end
    end
    
    if runtimer > totalTime then
        local completedUniqueId = currentAnimation.uniqueId
        self:NotifyUIEnd()
        
        if completedUniqueId then
            for _, callback in ipairs(self.completionCallbacks) do
                callback(completedUniqueId)
            end
        end
        
        currentAnimation = nil
        runtimer = 0
        self:StartNextAnimation()
    else
        local animationData = self:CalculateAnimationState(runtimer, totalTime)
        if animationData then
            self:NotifyUIUpdate(animationData)
        end
    end
end

function AnimationProcessor:CalculateAnimationState(currentTime, totalTime)
    if not currentAnimation then
        return nil
    end
    
    local selectedAnimationId = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    
    local AnimationData = rawget(_G, "AnimationData")
    if AnimationData then
        local animationState = AnimationData:CalculateAnimationState(selectedAnimationId, currentTime, totalTime)
        if animationState then
            local userScale = animScale or 1.0
            local animationScaleFactor = animationState.scale or 1.0
            local finalScale = iconSize * userScale * animationScaleFactor
            local finalAlpha = (animationState.alpha or 1.0) * maxAlpha
            
            local TextureValidator = rawget(_G, "TextureValidator")
            local validTexture = currentAnimation.texture
            if TextureValidator then
                validTexture = TextureValidator:GetValidTexture(currentAnimation.texture, "AnimationProcessor_CalculateState")
            end
            
            return {
                texture = validTexture,
                isPet = currentAnimation.isPet or false,
                name = showSpellName and currentAnimation.name or nil,
                alpha = finalAlpha,
                scale = finalScale,
                width = finalScale,
                height = finalScale,
                phase = animationState.phase,
                progress = currentTime / totalTime,
                petOverlay = currentAnimation.isPet and petOverlay or nil
            }
        end
    end
    
    local alpha = maxAlpha
    local phase = "hold"
    
    if currentTime < fadeInTime then
        alpha = maxAlpha * (currentTime / fadeInTime)
        phase = "fadeIn"
    elseif currentTime >= fadeInTime + holdTime then
        alpha = maxAlpha - (maxAlpha * ((currentTime - holdTime - fadeInTime) / fadeOutTime))
        phase = "fadeOut"
    end
    
    local userScale = animScale or 1.0
    local finalScale = iconSize * userScale
    
    local TextureValidator = rawget(_G, "TextureValidator")
    local validTexture = currentAnimation.texture
    if TextureValidator then
        validTexture = TextureValidator:GetValidTexture(currentAnimation.texture, "AnimationProcessor_CalculateState_Fallback")
    end
    
    return {
        texture = validTexture,
        isPet = currentAnimation.isPet or false,
        name = showSpellName and currentAnimation.name or nil,
        alpha = alpha,
        scale = finalScale,
        width = finalScale,
        height = finalScale,
        phase = phase,
        progress = currentTime / totalTime,
        petOverlay = currentAnimation.isPet and petOverlay or nil
    }
end

function AnimationProcessor:TestAnimation()
    local testTexture = "Interface\\Icons\\Spell_Fire_FlameBolt"
    self:QueueAnimation(testTexture, false, "Test Animation", "test_" .. GetTime())
end

function AnimationProcessor:IsAnimatingSpellName(name)
    if currentAnimation and currentAnimation.name == name then
        return true
    end
    
    for _, animation in ipairs(animationQueue) do
        if animation and animation.name == name then
            return true
        end
    end
    
    return false
end

function AnimationProcessor:ClearQueue()
    animationQueue = {}
    if currentAnimation then
        self:NotifyUIEnd()
        currentAnimation = nil
        self:StopOnUpdate()
    end
end

function AnimationProcessor:ClearAll()
    currentAnimation = nil
    animationQueue = {}
    runtimer = 0
    self:StopOnUpdate()
    self:NotifyUIEnd()
end

function AnimationProcessor:GetStatus()
    return {
        hasCurrentAnimation = currentAnimation ~= nil,
        queueLength = #animationQueue,
        currentAnimationName = currentAnimation and currentAnimation.name or nil,
        isOnUpdateActive = self.frame and self.frame:GetScript("OnUpdate") ~= nil,
        currentTime = runtimer,
        totalTime = fadeInTime + holdTime + fadeOutTime
    }
end

function AnimationProcessor:GetQueueSize()
    return #animationQueue + (currentAnimation and 1 or 0)
end

function AnimationProcessor:GetCurrentAnimation()
    return currentAnimation
end

function AnimationProcessor:IsAnimating()
    return currentAnimation ~= nil
end

function AnimationProcessor:GetAnimationStats()
    return {
        queued = #animationQueue,
        current = currentAnimation and 1 or 0,
        isActive = self:IsAnimating()
    }
end

function AnimationProcessor:RemoveAnimationById(uniqueId)
    if currentAnimation and currentAnimation.uniqueId == uniqueId then
        self:NotifyUIEnd()
        self:StartNextAnimation()
        return true
    end
    
    for i = #animationQueue, 1, -1 do
        if animationQueue[i].uniqueId == uniqueId then
            table.remove(animationQueue, i)
            return true
        end
    end
    
    return false
end

function AnimationProcessor:HasPendingAnimations()
    return #animationQueue > 0 or currentAnimation ~= nil
end

function AnimationProcessor:GetConfig()
    return {
        fadeInTime = fadeInTime,
        fadeOutTime = fadeOutTime,
        maxAlpha = maxAlpha,
        animScale = animScale,
        iconSize = iconSize,
        holdTime = holdTime,
        showSpellName = showSpellName,
        petOverlay = petOverlay
    }
end

_G.AnimationProcessor = AnimationProcessor
return AnimationProcessor
