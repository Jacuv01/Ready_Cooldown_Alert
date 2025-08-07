-- Script de test para verificar todas las animaciones
-- Usar: /run dofile("Interface/AddOns/Ready_Cooldown_Alert/test_animations.lua")

print("🎬 Testing All Animation Types")

local function TestAnimation(animationType)
    if not _G.AnimationProcessor or not ReadyCooldownAlertDB then
        print("❌ AnimationProcessor or DB not loaded")
        return
    end
    
    -- Cambiar a la animación especificada
    local oldAnimation = ReadyCooldownAlertDB.selectedAnimation
    ReadyCooldownAlertDB.selectedAnimation = animationType
    _G.AnimationProcessor:RefreshConfig()
    
    print("🎭 Testing animation: " .. animationType)
    print("  Settings: maxAlpha=" .. (ReadyCooldownAlertDB.maxAlpha or 0.7) .. 
          ", animScale=" .. (ReadyCooldownAlertDB.animScale or 1.5) ..
          ", iconSize=" .. (ReadyCooldownAlertDB.iconSize or 75))
    
    -- Ejecutar test
    _G.AnimationProcessor:TestAnimation()
    
    return oldAnimation
end

local function TestAllAnimations()
    print("\n🚀 Testing all animation types...")
    print("🔧 ESCALA CORREGIDA: animScale ahora es multiplicador (1.0=normal, 0.5=pequeño, 2.0=grande)")
    print("Current user settings will be applied to all animations")
    print("Each animation has unique dynamic effects (factores relativos):")
    print("  🔴 Pulse: Grows from 0.8 to 1.0 (normal size) during fade-in")
    print("  🟠 Bounce: Bounces from 0.5 to 1.0, continuous bouncing during hold")
    print("  🟡 Fade: Stays at 1.0 (normal size) - pure opacity animation")
    print("  🟢 Zoom: Explosive growth from 0.1 to 1.0, shrinks during fade-out")
    print("  🔵 Glow: Stays at 1.0 but pulses between 1.0-1.2 during hold phase")
    
    local animations = {"pulse", "bounce", "fade", "zoom", "glow"}
    local currentIndex = 1
    
    local function testNext()
        if currentIndex <= #animations then
            local animType = animations[currentIndex]
            TestAnimation(animType)
            currentIndex = currentIndex + 1
            
            -- Test siguiente después de 4 segundos
            C_Timer.After(4, testNext)
        else
            print("✅ All animation tests complete!")
            -- Volver a pulse como default
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB.selectedAnimation = "pulse"
                _G.AnimationProcessor:RefreshConfig()
                print("🔄 Reset to pulse animation")
            end
        end
    end
    
    testNext()
end

local function TestGlowSpecific()
    print("\n✨ Testing Glow animation specifically...")
    local oldAnim = TestAnimation("glow")
    
    print("🔍 Glow should show:")
    print("  - Stays at normal size (factor 1.0)")
    print("  - PULSING effect: grows/shrinks AND fades in/out during hold")
    print("  - Alpha pulses between 70% and 100% of your maxAlpha")
    print("  - Scale pulses between 1.0 and 1.2 (20% size variation)")
    print("  - Final size = iconSize × animScale × pulseFactor")
    
    C_Timer.After(5, function()
        if ReadyCooldownAlertDB and oldAnim then
            ReadyCooldownAlertDB.selectedAnimation = oldAnim
            _G.AnimationProcessor:RefreshConfig()
            print("🔄 Restored previous animation: " .. oldAnim)
        end
    end)
end

local function QuickSettingsTest()
    print("\n⚡ Quick settings test with Glow animation...")
    
    if not ReadyCooldownAlertDB then
        print("❌ ReadyCooldownAlertDB not available")
        return
    end
    
    -- Guardar settings originales
    local originalAlpha = ReadyCooldownAlertDB.maxAlpha
    local originalScale = ReadyCooldownAlertDB.animScale
    local originalAnim = ReadyCooldownAlertDB.selectedAnimation
    
    -- Test 1: Alpha bajo, escala normal
    print("1️⃣ Low alpha (0.3), normal scale (1.0)")
    ReadyCooldownAlertDB.maxAlpha = 0.3
    ReadyCooldownAlertDB.animScale = 1.0
    TestAnimation("glow")
    
    C_Timer.After(4, function()
        -- Test 2: Alpha alto, escala grande
        print("2️⃣ High alpha (1.0), large scale (2.0)")
        ReadyCooldownAlertDB.maxAlpha = 1.0
        ReadyCooldownAlertDB.animScale = 2.0
        TestAnimation("glow")
        
        C_Timer.After(4, function()
            -- Restaurar settings
            print("3️⃣ Restoring original settings")
            ReadyCooldownAlertDB.maxAlpha = originalAlpha
            ReadyCooldownAlertDB.animScale = originalScale
            ReadyCooldownAlertDB.selectedAnimation = originalAnim
            _G.AnimationProcessor:RefreshConfig()
            print("✅ Settings restored")
        end)
    end)
end

-- Hacer funciones globales
_G.TestAnimation = TestAnimation
_G.TestAllAnimations = TestAllAnimations
_G.TestGlowSpecific = TestGlowSpecific
_G.QuickSettingsTest = QuickSettingsTest

print("✅ Animation test functions loaded!")
print("Commands:")
print("  /run TestAnimation('glow')     -- Test specific animation")
print("  /run TestGlowSpecific()        -- Test glow with current settings")
print("  /run TestAllAnimations()       -- Test all animations sequentially")
print("  /run QuickSettingsTest()       -- Test glow with different settings")

-- Test automático de glow
TestGlowSpecific()
