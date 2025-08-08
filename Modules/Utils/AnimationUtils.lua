local AnimationUtils = {}

local ANIMATION_CONSTANTS = {
    MIN_SCALE = 0.1,
    MAX_ALPHA = 1.0,
    MIN_ALPHA = 0.0,
    BOUNCE_INTENSITY = 0.3,
    PULSE_FREQUENCY = 3,
    GLOW_ALPHA_VARIATION = 0.3,
    ZOOM_ACCELERATION = 2,
    FADE_OUT_SCALE_REDUCTION = 0.8,
    PULSE_SCALE_START = 0.8,
    BOUNCE_SCALE_START = 0.5,
    ZOOM_SCALE_START = 0.1
}

function AnimationUtils:getUserConfig()
    return {
        maxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.7,
        fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.1,
        holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.3,
        fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.2,
        animScale = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.animScale) or 1.5
    }
end

function AnimationUtils:calculateFadeProgress(currentTime, phaseTime)
    return math.max(0, math.min(1, currentTime / phaseTime))
end

function AnimationUtils:getCurrentPhase(currentTime, fadeInTime, holdTime)
    if currentTime <= fadeInTime then
        return "fadeIn", currentTime / fadeInTime
    elseif currentTime <= fadeInTime + holdTime then
        return "hold", (currentTime - fadeInTime) / holdTime
    else
        return "fadeOut", currentTime - fadeInTime - holdTime
    end
end

function AnimationUtils:easeInOut(progress)
    return progress * progress * (3 - 2 * progress)
end

function AnimationUtils:easeInQuad(progress)
    return progress * progress
end

function AnimationUtils:bounceEffect(progress, intensity)
    return math.sin(progress * math.pi * 2) * intensity
end

function AnimationUtils:pulseEffect(progress, frequency)
    return math.sin(progress * math.pi * frequency)
end

function AnimationUtils:clampResult(alpha, scale)
    return {
        alpha = math.max(ANIMATION_CONSTANTS.MIN_ALPHA, math.min(ANIMATION_CONSTANTS.MAX_ALPHA, alpha)),
        scale = math.max(ANIMATION_CONSTANTS.MIN_SCALE, scale)
    }
end

function AnimationUtils:getConstants()
    return ANIMATION_CONSTANTS
end

function AnimationUtils:getAnimationFactories()
    return {
        pulse = function()
            return function(progress, totalTime, currentTime)
                local config = self:getUserConfig()
                local phase, phaseProgress = self:getCurrentPhase(
                    currentTime, config.fadeInTime, config.holdTime
                )
                
                local alpha, scale = config.maxAlpha, 1.0
                
                if phase == "fadeIn" then
                    alpha = config.maxAlpha * phaseProgress
                    scale = ANIMATION_CONSTANTS.PULSE_SCALE_START + ((1.0 - ANIMATION_CONSTANTS.PULSE_SCALE_START) * phaseProgress)
                elseif phase == "hold" then
                    alpha = config.maxAlpha
                    scale = 1.0
                else -- fadeOut
                    local fadeProgress = self:calculateFadeProgress(
                        phaseProgress, config.fadeOutTime
                    )
                    alpha = config.maxAlpha * (1 - fadeProgress)
                    scale = 1.0
                end
                
                local result = self:clampResult(alpha, scale)
                return {
                    alpha = result.alpha,
                    scale = result.scale,
                    phase = phase
                }
            end
        end,
        
        bounce = function()
            return function(progress, totalTime, currentTime)
                local config = self:getUserConfig()
                local phase, phaseProgress = self:getCurrentPhase(
                    currentTime, config.fadeInTime, config.holdTime
                )
                
                local alpha, scale = config.maxAlpha, 1.0
                
                if phase == "fadeIn" then
                    alpha = config.maxAlpha * phaseProgress
                    local bounceEffect = self:bounceEffect(phaseProgress, ANIMATION_CONSTANTS.BOUNCE_INTENSITY)
                    scale = ANIMATION_CONSTANTS.BOUNCE_SCALE_START + ((1.0 - ANIMATION_CONSTANTS.BOUNCE_SCALE_START) * phaseProgress) + bounceEffect
                elseif phase == "hold" then
                    alpha = config.maxAlpha
                    local bounce = self:bounceEffect(phaseProgress, 0.1)
                    scale = 1.0 + bounce
                else
                    local fadeProgress = self:calculateFadeProgress(
                        phaseProgress, config.fadeOutTime
                    )
                    alpha = config.maxAlpha * (1 - fadeProgress)
                    scale = 1.0 * (1 - fadeProgress * 0.5)
                end
                
                local result = self:clampResult(alpha, scale)
                return {
                    alpha = result.alpha,
                    scale = result.scale,
                    phase = phase
                }
            end
        end,
        
        fade = function()
            return function(progress, totalTime, currentTime)
                local config = self:getUserConfig()
                local phase, phaseProgress = self:getCurrentPhase(
                    currentTime, config.fadeInTime, config.holdTime
                )
                
                local alpha, scale = config.maxAlpha, 1.0
                
                if phase == "fadeIn" then
                    alpha = config.maxAlpha * phaseProgress
                    scale = 1.0
                elseif phase == "hold" then
                    alpha = config.maxAlpha
                    scale = 1.0
                else
                    local fadeProgress = self:calculateFadeProgress(
                        phaseProgress, config.fadeOutTime
                    )
                    alpha = config.maxAlpha * (1 - fadeProgress)
                    scale = 1.0
                end
                
                local result = self:clampResult(alpha, scale)
                return {
                    alpha = result.alpha,
                    scale = result.scale,
                    phase = phase
                }
            end
        end,
        
        zoom = function()
            return function(progress, totalTime, currentTime)
                local config = self:getUserConfig()
                local phase, phaseProgress = self:getCurrentPhase(
                    currentTime, config.fadeInTime, config.holdTime
                )
                
                local alpha, scale = config.maxAlpha, 1.0
                
                if phase == "fadeIn" then
                    local easedProgress = self:easeInQuad(phaseProgress)
                    alpha = config.maxAlpha * easedProgress
                    scale = ANIMATION_CONSTANTS.ZOOM_SCALE_START + ((1.0 - ANIMATION_CONSTANTS.ZOOM_SCALE_START) * easedProgress)
                elseif phase == "hold" then
                    alpha = config.maxAlpha
                    scale = 1.0
                else
                    local fadeProgress = self:calculateFadeProgress(
                        phaseProgress, config.fadeOutTime
                    )
                    alpha = config.maxAlpha * (1 - fadeProgress)
                    scale = 1.0 * (1 - fadeProgress * ANIMATION_CONSTANTS.FADE_OUT_SCALE_REDUCTION)
                end
                
                local result = self:clampResult(alpha, scale)
                return {
                    alpha = result.alpha,
                    scale = result.scale,
                    phase = phase
                }
            end
        end,
        
        glow = function()
            return function(progress, totalTime, currentTime)
                local config = self:getUserConfig()
                local phase, phaseProgress = self:getCurrentPhase(
                    currentTime, config.fadeInTime, config.holdTime
                )
                
                local alpha, scale = config.maxAlpha, 1.0
                
                if phase == "fadeIn" then
                    alpha = config.maxAlpha * phaseProgress
                    scale = 1.0
                elseif phase == "hold" then
                    local pulseValue = self:pulseEffect(phaseProgress, ANIMATION_CONSTANTS.PULSE_FREQUENCY)
                    
                    local alphaPulse = ANIMATION_CONSTANTS.GLOW_ALPHA_VARIATION
                    alpha = config.maxAlpha * (1.0 - alphaPulse + (alphaPulse * (pulseValue + 1) / 2))
                    
                    scale = 1.0 + ((config.animScale - 1.0) * (pulseValue + 1) / 2)
                else
                    local fadeProgress = self:calculateFadeProgress(
                        phaseProgress, config.fadeOutTime
                    )
                    alpha = config.maxAlpha * (1 - fadeProgress)
                    scale = 1.0
                end
                
                local result = self:clampResult(alpha, scale)
                return {
                    alpha = result.alpha,
                    scale = result.scale,
                    phase = phase
                }
            end
        end
    }
end

_G.AnimationUtils = AnimationUtils

return AnimationUtils
