local AnimationData = {}

-- Definición de tipos de animación disponibles
AnimationData.animations = {
    {
        id = "pulse",
        name = "Pulse",
        description = "Classic pulsing animation",
        config = {
            fadeInTime = 0.1,
            holdTime = 0.3,
            fadeOutTime = 0.2,
            scaleStart = 0.8,
            scaleEnd = 1.5,
            alphaStart = 0,
            alphaEnd = 0.7,
            -- Función de animación personalizada
            updateFunction = function(progress, totalTime, currentTime)
                local phase = "hold"
                local alpha = 0.7
                local scale = 1.5
                
                local fadeInTime = 0.1
                local holdTime = 0.3
                local fadeOutTime = 0.2
                
                if currentTime <= fadeInTime then
                    -- Fade In
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = 0.7 * fadeProgress
                    scale = 0.8 + (0.7 * fadeProgress) -- 0.8 a 1.5
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold
                    phase = "hold"
                    alpha = 0.7
                    scale = 1.5
                else
                    -- Fade Out
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = 0.7 * (1 - fadeProgress)
                    scale = 1.5
                end
                
                return {
                    alpha = alpha,
                    scale = scale,
                    phase = phase
                }
            end
        }
    },
    {
        id = "bounce",
        name = "Bounce",
        description = "Bouncing scale animation",
        config = {
            fadeInTime = 0.2,
            holdTime = 0.4,
            fadeOutTime = 0.3,
            scaleStart = 0.5,
            scaleEnd = 2.0,
            alphaStart = 0,
            alphaEnd = 0.8,
            updateFunction = function(progress, totalTime, currentTime)
                local phase = "hold"
                local alpha = 0.8
                local scale = 1.0
                
                local fadeInTime = 0.2
                local holdTime = 0.4
                local fadeOutTime = 0.3
                
                if currentTime <= fadeInTime then
                    -- Fade In con bounce
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = 0.8 * fadeProgress
                    -- Efecto bounce en la escala
                    local bounceScale = math.sin(fadeProgress * math.pi * 2) * 0.3
                    scale = 0.5 + (1.5 * fadeProgress) + bounceScale
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold con pequeño bounce continuo
                    phase = "hold"
                    alpha = 0.8
                    local holdProgress = (currentTime - fadeInTime) / holdTime
                    local bounce = math.sin(holdProgress * math.pi * 4) * 0.1
                    scale = 2.0 + bounce
                else
                    -- Fade Out
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = 0.8 * (1 - fadeProgress)
                    scale = 2.0 * (1 - fadeProgress * 0.5) -- Reducir gradualmente
                end
                
                return {
                    alpha = alpha,
                    scale = scale,
                    phase = phase
                }
            end
        }
    },
    {
        id = "fade",
        name = "Fade",
        description = "Simple fade in/out",
        config = {
            fadeInTime = 0.3,
            holdTime = 0.5,
            fadeOutTime = 0.4,
            scaleStart = 1.0,
            scaleEnd = 1.2,
            alphaStart = 0,
            alphaEnd = 0.9,
            updateFunction = function(progress, totalTime, currentTime)
                local phase = "hold"
                local alpha = 0.9
                local scale = 1.2
                
                local fadeInTime = 0.3
                local holdTime = 0.5
                local fadeOutTime = 0.4
                
                if currentTime <= fadeInTime then
                    -- Fade In suave
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = 0.9 * fadeProgress
                    scale = 1.0 + (0.2 * fadeProgress)
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold estable
                    phase = "hold"
                    alpha = 0.9
                    scale = 1.2
                else
                    -- Fade Out suave
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = 0.9 * (1 - fadeProgress)
                    scale = 1.2
                end
                
                return {
                    alpha = alpha,
                    scale = scale,
                    phase = phase
                }
            end
        }
    },
    {
        id = "zoom",
        name = "Zoom",
        description = "Fast zoom in/out effect",
        config = {
            fadeInTime = 0.15,
            holdTime = 0.2,
            fadeOutTime = 0.15,
            scaleStart = 0.1,
            scaleEnd = 2.5,
            alphaStart = 0,
            alphaEnd = 0.6,
            updateFunction = function(progress, totalTime, currentTime)
                local phase = "hold"
                local alpha = 0.6
                local scale = 2.5
                
                local fadeInTime = 0.15
                local holdTime = 0.2
                local fadeOutTime = 0.15
                
                if currentTime <= fadeInTime then
                    -- Zoom rápido
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    -- Curva de aceleración para el zoom
                    local easedProgress = fadeProgress * fadeProgress
                    alpha = 0.6 * easedProgress
                    scale = 0.1 + (2.4 * easedProgress)
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold
                    phase = "hold"
                    alpha = 0.6
                    scale = 2.5
                else
                    -- Zoom out rápido
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = 0.6 * (1 - fadeProgress)
                    scale = 2.5 * (1 - fadeProgress * 0.8) -- Reducir escala gradualmente
                end
                
                return {
                    alpha = alpha,
                    scale = scale,
                    phase = phase
                }
            end
        }
    },
    {
        id = "glow",
        name = "Glow",
        description = "Glowing pulsing effect",
        config = {
            fadeInTime = 0.25,
            holdTime = 0.6,
            fadeOutTime = 0.35,
            scaleStart = 1.0,
            scaleEnd = 1.3,
            alphaStart = 0,
            alphaEnd = 0.85,
            updateFunction = function(progress, totalTime, currentTime)
                local phase = "hold"
                local alpha = 0.85
                local scale = 1.3
                
                local fadeInTime = 0.25
                local holdTime = 0.6
                local fadeOutTime = 0.35
                
                if currentTime <= fadeInTime then
                    -- Fade In
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = 0.85 * fadeProgress
                    scale = 1.0 + (0.3 * fadeProgress)
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold con pulsing glow
                    phase = "hold"
                    local holdProgress = (currentTime - fadeInTime) / holdTime
                    local pulse = math.sin(holdProgress * math.pi * 3) * 0.15 + 0.85
                    alpha = pulse
                    local scalePulse = math.sin(holdProgress * math.pi * 3) * 0.1 + 1.3
                    scale = scalePulse
                else
                    -- Fade Out
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = 0.85 * (1 - fadeProgress)
                    scale = 1.3
                end
                
                return {
                    alpha = alpha,
                    scale = scale,
                    phase = phase
                }
            end
        }
    }
}

-- Obtener animación por ID
function AnimationData:GetAnimation(animationId)
    for _, animation in ipairs(self.animations) do
        if animation.id == animationId then
            return animation
        end
    end
    return self.animations[1] -- Default a pulse si no se encuentra
end

-- Obtener lista de animaciones para dropdown
function AnimationData:GetAnimationList()
    local list = {}
    for _, animation in ipairs(self.animations) do
        table.insert(list, {
            value = animation.id,
            text = animation.name,
            tooltip = animation.description
        })
    end
    return list
end

-- Obtener configuración de animación
function AnimationData:GetAnimationConfig(animationId)
    local animation = self:GetAnimation(animationId)
    return animation and animation.config or self.animations[1].config
end

-- Calcular estado de animación
function AnimationData:CalculateAnimationState(animationId, currentTime, totalTime)
    local animation = self:GetAnimation(animationId)
    if animation and animation.config.updateFunction then
        local progress = currentTime / totalTime
        return animation.config.updateFunction(progress, totalTime, currentTime)
    end
    
    -- Fallback al comportamiento por defecto
    return {
        alpha = 0.7,
        scale = 1.5,
        phase = "hold"
    }
end

-- Exportar globalmente para WoW addon system
_G.AnimationData = AnimationData

return AnimationData
