local AnimationData = {}

-- Definición de tipos de animación disponibles
AnimationData.animations = {
    {
        id = "pulse",
        name = "Pulse",
        description = "Classic pulsing animation",
        defaultValues = {
            fadeInTime = 0.1,
            holdTime = 0.3,
            fadeOutTime = 0.2,
            maxAlpha = 0.7,
            animScale = 1.5,
            iconSize = 75,
            remainingCooldownWhenNotified = 1.0
        },
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
                -- Obtener configuración del usuario desde ReadyCooldownAlertDB
                local userMaxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.7
                local fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.1
                local holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.3
                local fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.2
                
                local phase = "hold"
                local alpha = userMaxAlpha
                local scale = 1.0 -- Factor relativo: 1.0 = tamaño normal del usuario
                
                if currentTime <= fadeInTime then
                    -- Fade In - crece de 0.8 hasta 1.0 (tamaño normal)
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = userMaxAlpha * fadeProgress
                    -- Escala desde 0.8 hasta 1.0 (factor relativo)
                    local scaleStart = 0.8
                    scale = scaleStart + ((1.0 - scaleStart) * fadeProgress)
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold - mantiene el tamaño normal (1.0)
                    phase = "hold"
                    alpha = userMaxAlpha
                    scale = 1.0
                else
                    -- Fade Out - mantiene el tamaño normal
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = userMaxAlpha * (1 - fadeProgress)
                    scale = 1.0
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
        defaultValues = {
            fadeInTime = 0.2,
            holdTime = 0.4,
            fadeOutTime = 0.3,
            maxAlpha = 0.8,
            animScale = 2.0,
            iconSize = 80,
            remainingCooldownWhenNotified = 1.5
        },
        config = {
            fadeInTime = 0.2,
            holdTime = 0.4,
            fadeOutTime = 0.3,
            scaleStart = 0.5,
            scaleEnd = 2.0,
            alphaStart = 0,
            alphaEnd = 0.8,
            updateFunction = function(progress, totalTime, currentTime)
                -- Obtener configuración del usuario
                local userMaxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.8
                local fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.2
                local holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.4
                local fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.3
                
                local phase = "hold"
                local alpha = userMaxAlpha
                local scale = 1.0 -- Factor relativo: 1.0 = tamaño normal del usuario
                
                if currentTime <= fadeInTime then
                    -- Fade In con bounce - crece de 0.5 hasta 1.0 con rebote
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = userMaxAlpha * fadeProgress
                    -- Efecto bounce en la escala (factor relativo)
                    local bounceScale = math.sin(fadeProgress * math.pi * 2) * 0.3
                    local scaleStart = 0.5
                    scale = scaleStart + ((1.0 - scaleStart) * fadeProgress) + bounceScale
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold con pequeño bounce continuo
                    phase = "hold"
                    alpha = userMaxAlpha
                    local holdProgress = (currentTime - fadeInTime) / holdTime
                    local bounce = math.sin(holdProgress * math.pi * 4) * 0.1
                    scale = 1.0 + bounce -- Factor relativo con bounce
                else
                    -- Fade Out - reduce escala gradualmente
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = userMaxAlpha * (1 - fadeProgress)
                    scale = 1.0 * (1 - fadeProgress * 0.5) -- Reducir gradualmente a la mitad
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
        defaultValues = {
            fadeInTime = 0.3,
            holdTime = 0.5,
            fadeOutTime = 0.4,
            maxAlpha = 0.9,
            animScale = 1.2,
            iconSize = 70,
            remainingCooldownWhenNotified = 0.8
        },
        config = {
            fadeInTime = 0.3,
            holdTime = 0.5,
            fadeOutTime = 0.4,
            scaleStart = 1.0,
            scaleEnd = 1.2,
            alphaStart = 0,
            alphaEnd = 0.9,
            updateFunction = function(progress, totalTime, currentTime)
                -- Obtener configuración del usuario
                local userMaxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.9
                local fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.3
                local holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.5
                local fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.4
                
                local phase = "hold"
                local alpha = userMaxAlpha
                local scale = 1.0 -- Factor relativo: 1.0 = tamaño normal del usuario
                
                if currentTime <= fadeInTime then
                    -- Fade In suave - mantiene tamaño normal (1.0)
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = userMaxAlpha * fadeProgress
                    -- Sin crecimiento de escala, mantiene factor 1.0
                    scale = 1.0
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold estable
                    phase = "hold"
                    alpha = userMaxAlpha
                    scale = 1.0
                else
                    -- Fade Out suave - mantiene el tamaño
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = userMaxAlpha * (1 - fadeProgress)
                    scale = 1.0
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
        defaultValues = {
            fadeInTime = 0.15,
            holdTime = 0.2,
            fadeOutTime = 0.15,
            maxAlpha = 0.6,
            animScale = 2.5,
            iconSize = 90,
            remainingCooldownWhenNotified = 2.0
        },
        config = {
            fadeInTime = 0.15,
            holdTime = 0.2,
            fadeOutTime = 0.15,
            scaleStart = 0.1,
            scaleEnd = 2.5,
            alphaStart = 0,
            alphaEnd = 0.6,
            updateFunction = function(progress, totalTime, currentTime)
                -- Obtener configuración del usuario
                local userMaxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.6
                local fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.15
                local holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.2
                local fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.15
                
                local phase = "hold"
                local alpha = userMaxAlpha
                local scale = 1.0 -- Factor relativo: 1.0 = tamaño normal del usuario
                
                if currentTime <= fadeInTime then
                    -- Zoom rápido - explota desde 0.1 hasta 1.0 (tamaño normal)
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    -- Curva de aceleración para el zoom
                    local easedProgress = fadeProgress * fadeProgress
                    alpha = userMaxAlpha * easedProgress
                    -- Zoom dramático desde 0.1 hasta 1.0 (factor relativo)
                    local scaleStart = 0.1
                    scale = scaleStart + ((1.0 - scaleStart) * easedProgress)
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold - mantiene tamaño normal (1.0)
                    phase = "hold"
                    alpha = userMaxAlpha
                    scale = 1.0
                else
                    -- Zoom out rápido - se encoge gradualmente
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = userMaxAlpha * (1 - fadeProgress)
                    -- Se encoge al 20% del tamaño normal durante el fade out
                    scale = 1.0 * (1 - fadeProgress * 0.8)
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
        defaultValues = {
            fadeInTime = 0.25,
            holdTime = 0.6,
            fadeOutTime = 0.35,
            maxAlpha = 0.85,
            animScale = 1.3,
            iconSize = 65,
            remainingCooldownWhenNotified = 0.5
        },
        config = {
            fadeInTime = 0.25,
            holdTime = 0.6,
            fadeOutTime = 0.35,
            scaleStart = 1.0,
            scaleEnd = 1.3,
            alphaStart = 0,
            alphaEnd = 0.85,
            updateFunction = function(progress, totalTime, currentTime)
                -- Obtener configuración del usuario
                local userMaxAlpha = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha) or 0.85
                local fadeInTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeInTime) or 0.25
                local holdTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.holdTime) or 0.6
                local fadeOutTime = (ReadyCooldownAlertDB and ReadyCooldownAlertDB.fadeOutTime) or 0.35
                
                local phase = "hold"
                local alpha = userMaxAlpha
                local scale = 1.0 -- Factor relativo: 1.0 = tamaño normal del usuario
                
                if currentTime <= fadeInTime then
                    -- Fade In - crece suavemente hasta tamaño normal (1.0)
                    phase = "fadeIn"
                    local fadeProgress = currentTime / fadeInTime
                    alpha = userMaxAlpha * fadeProgress
                    scale = 1.0 -- Mantiene factor normal
                elseif currentTime <= fadeInTime + holdTime then
                    -- Hold con pulsing glow dinámico - ¡ESTE ES EL EFECTO PRINCIPAL!
                    phase = "hold"
                    local holdProgress = (currentTime - fadeInTime) / holdTime
                    -- Efecto pulsing que pulsa entre tamaños y transparencias
                    local pulseFrequency = 3 -- 3 pulsos durante el hold
                    local pulseValue = math.sin(holdProgress * math.pi * pulseFrequency)
                    
                    -- Alpha pulsa entre 70% y 100% del maxAlpha del usuario
                    local alphaPulseIntensity = 0.3 -- 30% de variación
                    alpha = userMaxAlpha * (1.0 - alphaPulseIntensity + (alphaPulseIntensity * (pulseValue + 1) / 2))
                    
                    -- Scale pulsa entre 1.0 y 1.2 (20% más grande que el tamaño normal)
                    local scalePulseIntensity = 0.2 -- 20% de variación en escala
                    scale = 1.0 + scalePulseIntensity * (pulseValue + 1) / 2
                else
                    -- Fade Out - se desvanece manteniendo el tamaño normal
                    phase = "fadeOut"
                    local fadeProgress = (currentTime - fadeInTime - holdTime) / fadeOutTime
                    alpha = userMaxAlpha * (1 - fadeProgress)
                    scale = 1.0
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
