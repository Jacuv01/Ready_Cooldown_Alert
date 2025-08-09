local TextureValidator = {}

local FALLBACK_TEXTURE = 135808
local loggedErrors = {}

function TextureValidator:ValidateTexture(textureValue, context)
    context = context or "unknown"
    
    if textureValue == nil then
        self:LogTextureError("nil", context)
        return false, "Texture is nil"
    end
    
    if textureValue == "" then
        self:LogTextureError("empty", context)
        return false, "Texture is empty string"
    end
    
    local textureType = type(textureValue)
    if textureType ~= "number" and textureType ~= "string" then
        self:LogTextureError("invalid_type", context)
        return false, "Texture type is " .. textureType .. ", expected number or string"
    end
    
    if textureType == "number" and textureValue <= 0 then
        self:LogTextureError("invalid_number", context)
        return false, "Texture ID must be positive, got " .. textureValue
    end
    
    return true, "Valid texture"
end

function TextureValidator:GetValidTexture(textureValue, context, customFallback)
    local isValid, reason = self:ValidateTexture(textureValue, context)
    
    if isValid then
        return textureValue
    else
        return customFallback or FALLBACK_TEXTURE
    end
end

function TextureValidator:SafeSetTexture(textureFrame, textureValue, context, customFallback)
    if not textureFrame then
        return false
    end
    
    local validTexture = self:GetValidTexture(textureValue, context, customFallback)
    textureFrame:SetTexture(validTexture)
    
    return true
end

function TextureValidator:LogTextureError(errorType, context)
    local logKey = errorType .. "_" .. (context or "unknown")
    
    if not loggedErrors[logKey] then
        loggedErrors[logKey] = true
    end
end

function TextureValidator:ClearLogCache()
    loggedErrors = {}
end

function TextureValidator:NeedsFallback(textureValue)
    local isValid, _ = self:ValidateTexture(textureValue, "check")
    return not isValid
end

function TextureValidator:GetFallbackTexture()
    return FALLBACK_TEXTURE
end

function TextureValidator:SetFallbackTexture(newFallback)
    if self:ValidateTexture(newFallback, "fallback_config") then
        FALLBACK_TEXTURE = newFallback
    end
end

_G.TextureValidator = TextureValidator

return TextureValidator
