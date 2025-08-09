local CooldownProcessor = {}

local watching = {}
local cooldowns = {}
local animating = {}
local lastAlertTime = {}

local WATCH_DURATION = 0.5
local MIN_COOLDOWN_DURATION = 2.0
local ALERT_COOLDOWN = 2.0

local elapsed = 0
local runtimer = 0

CooldownProcessor.animationCallbacks = {}

function CooldownProcessor:RegisterAnimationCallback(callback)
    table.insert(self.animationCallbacks, callback)
end

function CooldownProcessor:TriggerAnimation(cooldownDetails)
    for _, callback in ipairs(self.animationCallbacks) do
        callback(cooldownDetails.texture, cooldownDetails.isPet, cooldownDetails.name, cooldownDetails.uniqueId)
    end
end

function CooldownProcessor:OnAnimationComplete(uniqueId)
    for i = #animating, 1, -1 do
        if animating[i].uniqueId == uniqueId then
            table.remove(animating, i)
            break
        end
    end
end

function CooldownProcessor:AddToWatching(actionType, id, texture, extraData)
    watching[id] = {
        timestamp = GetTime(),
        actionType = actionType,
        texture = texture,
        extraData = extraData
    }
    
    self:StartOnUpdate()
end

function CooldownProcessor:IsAnimatingCooldownById(id)
    for _, animation in ipairs(animating) do
        if animation.uniqueId == id then
            return true
        end
    end
    return false
end

function CooldownProcessor:StartOnUpdate()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    if not self.frame:GetScript("OnUpdate") then
        self.frame:SetScript("OnUpdate", function(_, update)
            self:OnUpdate(update)
        end)
    end
end

function CooldownProcessor:StopOnUpdate()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
end

function CooldownProcessor:OnUpdate(update)
    elapsed = elapsed + update
    if elapsed > 0.05 then
        
        for id, watchData in pairs(watching) do
            if GetTime() >= watchData.timestamp + WATCH_DURATION then
                self:ProcessWatchedAction(id, watchData)
                watching[id] = nil
            end
        end
        
        local alertCandidates = {}
        
        for id, getCooldownDetails in pairs(cooldowns) do
            local cooldownDetails = getCooldownDetails()
            if cooldownDetails and cooldownDetails.start and cooldownDetails.duration then
                local currentTime = GetTime()
                local start = cooldownDetails.start
                local duration = cooldownDetails.duration
                
                if start > 0 and duration > 0 then
                    local remaining = duration - (currentTime - start)
                    
                    local remainingThreshold = ReadyCooldownAlertDB and ReadyCooldownAlertDB.remainingCooldownWhenNotified or 0
                    
                    if remainingThreshold <= 0 then
                        remainingThreshold = 0.1
                    end
                    
                    if remaining <= remainingThreshold and remaining >= -1 then
                        local alertId = cooldownDetails.name .. "_" .. id
                        local currentTime = GetTime()
                        
                        if not lastAlertTime[alertId] or (currentTime - lastAlertTime[alertId]) >= ALERT_COOLDOWN then
                            if not self:IsAnimatingCooldownById(id) then
                                table.insert(alertCandidates, {
                                    id = id,
                                    alertId = alertId,
                                    cooldownDetails = cooldownDetails,
                                    remaining = remaining,
                                    currentTime = currentTime
                                })
                            end
                        end
                    elseif remaining < -1 then
                        cooldowns[id] = nil
                        local alertId = cooldownDetails.name .. "_" .. id
                        lastAlertTime[alertId] = nil
                    end
                else
                    cooldowns[id] = nil
                end
            else
                cooldowns[id] = nil
            end
        end
        
        if #alertCandidates > 0 then
            table.sort(alertCandidates, function(a, b)
                return a.remaining < b.remaining
            end)
            
            local maxSimultaneousAlerts = 3
            local alertsToShow = math.min(#alertCandidates, maxSimultaneousAlerts)
            
            for i = 1, alertsToShow do
                local candidate = alertCandidates[i]
                
                local animationData = candidate.cooldownDetails
                animationData.uniqueId = candidate.id
                
                table.insert(animating, animationData)
                self:TriggerAnimation(animationData)
                lastAlertTime[candidate.alertId] = candidate.currentTime
                
                cooldowns[candidate.id] = nil
            end
        end
        
        elapsed = 0
        
        local watchCount = 0
        for _ in pairs(watching) do watchCount = watchCount + 1 end
        local cooldownCount = 0
        for _ in pairs(cooldowns) do cooldownCount = cooldownCount + 1 end
        
        if #animating == 0 and watchCount == 0 and cooldownCount == 0 then
            self:StopOnUpdate()
            return
        end
    end
end

function CooldownProcessor:ProcessWatchedAction(id, watchData)
    if CooldownData then
        local cooldownDetails = CooldownData:GetCooldownDetails(id, watchData.actionType, watchData.extraData)
        
        if cooldownDetails then
            if rawget(_G, "FilterProcessor") and rawget(_G, "FilterProcessor"):ShouldFilter(cooldownDetails.name, id) then
                return
            end
            
            if CooldownData:IsValidForTracking(cooldownDetails, MIN_COOLDOWN_DURATION) then
                local function memoizedGetCooldownDetails()
                    return CooldownData:GetCooldownDetails(id, watchData.actionType, watchData.extraData)
                end
                
                cooldowns[id] = memoizedGetCooldownDetails
            end
        end
    end
end

function CooldownProcessor:ClearAll()
    watching = {}
    cooldowns = {}
    animating = {}
    lastAlertTime = {}
    self:StopOnUpdate()
end

function CooldownProcessor:ClearCooldowns()
    watching = {}
    cooldowns = {}
    lastAlertTime = {}
end

function CooldownProcessor:GetStatus()
    local watchCount = 0
    for _ in pairs(watching) do watchCount = watchCount + 1 end
    local cooldownCount = 0
    for _ in pairs(cooldowns) do cooldownCount = cooldownCount + 1 end
    local alertCount = 0
    for _ in pairs(lastAlertTime) do alertCount = alertCount + 1 end
    
    return {
        watching = watchCount,
        cooldowns = cooldownCount,
        animating = #animating,
        alertsTracked = alertCount,
        isOnUpdateActive = self.frame and self.frame:GetScript("OnUpdate") ~= nil
    }
end

_G.CooldownProcessor = CooldownProcessor

return CooldownProcessor
