local TextureValidator = {}

-- Textura de fallback por defecto (Pyroblast - icono confiable)
local FALLBACK_TEXTURE = 135808

-- Cache para evitar spam de logs repetidos
local loggedErrors = {}

-- Validar si una textura es válida
function TextureValidator:ValidateTexture(textureValue, context)
    context = context or "unknown"
    
    -- Verificar nil
    if textureValue == nil then
        self:LogTextureError("nil", context)
        return false, "Texture is nil"
    end
    
    -- Verificar cadena vacía
    if textureValue == "" then
        self:LogTextureError("empty", context)
        return false, "Texture is empty string"
    end
    
    -- Verificar tipo válido (number o string)
    local textureType = type(textureValue)
    if textureType ~= "number" and textureType ~= "string" then
        self:LogTextureError("invalid_type", context)
        return false, "Texture type is " .. textureType .. ", expected number or string"
    end
    
    -- Verificar que sea un número positivo si es numérico
    if textureType == "number" and textureValue <= 0 then
        self:LogTextureError("invalid_number", context)
        return false, "Texture ID must be positive, got " .. textureValue
    end
    
    return true, "Valid texture"
end

-- Obtener textura con fallback automático
function TextureValidator:GetValidTexture(textureValue, context, customFallback)
    local isValid, reason = self:ValidateTexture(textureValue, context)
    
    if isValid then
        return textureValue
    else
        local fallback = customFallback or FALLBACK_TEXTURE
        return fallback
    end
end

-- Establecer textura de forma segura en un frame texture
function TextureValidator:SafeSetTexture(textureFrame, textureValue, context, customFallback)
    if not textureFrame then
        return false
    end
    
    local validTexture = self:GetValidTexture(textureValue, context, customFallback)
    textureFrame:SetTexture(validTexture)
    
    return true
end

-- Sistema de logging para evitar spam
function TextureValidator:LogTextureError(errorType, context)
    local logKey = errorType .. "_" .. (context or "unknown")
    
    -- Solo logear el primer error de cada tipo por contexto
    if not loggedErrors[logKey] then
        loggedErrors[logKey] = true
        -- Silencioso - solo registramos sin imprimir
    end
end

-- Limpiar cache de logs (útil para testing)
function TextureValidator:ClearLogCache()
    loggedErrors = {}
end

-- Verificar si una textura necesita fallback
function TextureValidator:NeedsFallback(textureValue)
    local isValid, _ = self:ValidateTexture(textureValue, "check")
    return not isValid
end

-- Obtener la textura de fallback configurada
function TextureValidator:GetFallbackTexture()
    return FALLBACK_TEXTURE
end

-- Configurar una textura de fallback personalizada
function TextureValidator:SetFallbackTexture(newFallback)
    if self:ValidateTexture(newFallback, "fallback_config") then
        FALLBACK_TEXTURE = newFallback
    else
        -- Mantener textura actual si la nueva no es válida
    end
end

-- Exportar globalmente para el sistema de addons de WoW
_G.TextureValidator = TextureValidator

return TextureValidator
