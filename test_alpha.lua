-- Script de test para verificar maxAlpha
-- Usar: /run dofile("Interface/AddOns/Ready_Cooldown_Alert/test_alpha.lua")

print("🔧 Testing MaxAlpha Functionality")

local function TestAlpha()
    if not _G.AnimationProcessor then
        print("❌ AnimationProcessor not loaded")
        return
    end
    
    -- Mostrar configuración actual
    _G.AnimationProcessor:DebugConfig()
    
    -- Refrescar configuración
    _G.AnimationProcessor:RefreshConfig()
    print("📊 Configuration refreshed")
    
    -- Test con diferentes valores de alpha
    print("\n🧪 Testing animation with current alpha settings...")
    _G.AnimationProcessor:TestAnimation()
    
    print("✅ Test animation queued - check screen for icon opacity")
    print("📏 Expected behavior:")
    print("  - maxAlpha = 1.0 → Icon fully opaque")
    print("  - maxAlpha = 0.5 → Icon half transparent")  
    print("  - maxAlpha = 0.2 → Icon very transparent")
    print("  - Current maxAlpha: " .. (ReadyCooldownAlertDB and ReadyCooldownAlertDB.maxAlpha or 0.7))
end

-- Test modificar alpha en tiempo real
local function TestAlphaChange(newAlpha)
    if ReadyCooldownAlertDB then
        local oldAlpha = ReadyCooldownAlertDB.maxAlpha or 0.7
        ReadyCooldownAlertDB.maxAlpha = newAlpha
        _G.AnimationProcessor:RefreshConfig()
        
        print("🔄 Alpha changed from " .. oldAlpha .. " to " .. newAlpha)
        _G.AnimationProcessor:TestAnimation()
        print("📺 Check screen - icon should have " .. (newAlpha * 100) .. "% opacity")
        
        if newAlpha == 1.0 then
            print("   (This should be fully opaque)")
        elseif newAlpha >= 0.8 then
            print("   (This should be mostly opaque)")
        elseif newAlpha >= 0.5 then
            print("   (This should be semi-transparent)")
        else
            print("   (This should be very transparent)")
        end
    else
        print("❌ ReadyCooldownAlertDB not available")
    end
end

-- Tests rápidos de alpha
local function QuickAlphaTests()
    print("\n🚀 Running quick alpha tests...")
    
    -- Test alpha completo
    print("\n1️⃣ Testing full opacity (maxAlpha = 1.0)")
    TestAlphaChange(1.0)
    
    C_Timer.After(3, function()
        print("\n2️⃣ Testing half opacity (maxAlpha = 0.5)")
        TestAlphaChange(0.5)
        
        C_Timer.After(3, function()
            print("\n3️⃣ Testing low opacity (maxAlpha = 0.2)")
            TestAlphaChange(0.2)
            
            C_Timer.After(3, function()
                print("\n4️⃣ Back to default (maxAlpha = 0.7)")
                TestAlphaChange(0.7)
                print("\n✅ Quick alpha tests complete!")
            end)
        end)
    end)
end

-- Hacer funciones globales
_G.TestAlpha = TestAlpha
_G.TestAlphaChange = TestAlphaChange
_G.QuickAlphaTests = QuickAlphaTests

print("✅ Alpha test functions loaded!")
print("Commands:")
print("  /run TestAlpha()  -- Test current settings")
print("  /run TestAlphaChange(1.0)  -- Full opacity")
print("  /run TestAlphaChange(0.5)  -- Half opacity")  
print("  /run TestAlphaChange(0.2)  -- Very transparent")
print("  /run QuickAlphaTests()     -- Run automated sequence")

-- Ejecutar test automáticamente
TestAlpha()
