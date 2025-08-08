local AnimationData = {}

-- Importar utilidades de animación desde Utils/
-- En WoW, las dependencias se cargan automáticamente si están en _G
local AnimationUtils = _G.AnimationUtils

-- Verificar que AnimationUtils esté disponible
if not AnimationUtils then
    error("AnimationUtils not found! Make sure AnimationUtils.lua is loaded before AnimationData.lua in the .toc file")
end

-- Obtener constantes desde AnimationUtils
local ANIMATION_CONSTANTS = AnimationUtils:getConstants()

-- Obtener factories desde AnimationUtils
local AnimationFactories = AnimationUtils:getAnimationFactories()

-- Definición limpia y concisa de animaciones
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
            remainingCooldownWhenNotified = 1.0
        },
        config = {
            fadeInTime = 0.1,
            holdTime = 0.3,
            fadeOutTime = 0.2,
            scaleStart = ANIMATION_CONSTANTS.PULSE_SCALE_START,
            scaleEnd = 1.5,
            alphaStart = 0,
            alphaEnd = 0.7,
            updateFunction = AnimationFactories.pulse()
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
            animScale = 1.4,
            remainingCooldownWhenNotified = 1.5
        },
        config = {
            fadeInTime = 0.2,
            holdTime = 0.4,
            fadeOutTime = 0.3,
            scaleStart = ANIMATION_CONSTANTS.BOUNCE_SCALE_START,
            scaleEnd = 2.0,
            alphaStart = 0,
            alphaEnd = 0.8,
            updateFunction = AnimationFactories.bounce()
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
            updateFunction = AnimationFactories.fade()
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
            remainingCooldownWhenNotified = 2.0
        },
        config = {
            fadeInTime = 0.15,
            holdTime = 0.2,
            fadeOutTime = 0.15,
            scaleStart = ANIMATION_CONSTANTS.ZOOM_SCALE_START,
            scaleEnd = 2.5,
            alphaStart = 0,
            alphaEnd = 0.6,
            updateFunction = AnimationFactories.zoom()
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
            updateFunction = AnimationFactories.glow()
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
