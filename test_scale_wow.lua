-- Test rápido de escala en WoW
-- /run dofile("Interface/AddOns/Ready_Cooldown_Alert/test_scale_wow.lua")

print("🔧 PRUEBA DE ESCALA - Ready Cooldown Alert")

-- Verificar que esté cargado
if not ReadyCooldownAlertDB then
    print("❌ Addon no cargado")
    return
end

if not _G.AnimationProcessor then
    print("❌ AnimationProcessor no encontrado")
    return
end

-- Mostrar configuración actual
print("⚙️ Configuración actual:")
print("  iconSize: " .. (ReadyCooldownAlertDB.iconSize or "no definido"))
print("  animScale: " .. (ReadyCooldownAlertDB.animScale or "no definido"))
print("")

-- Función para probar una escala específica
local function TestSpecificScale(scale, description)
    print("📏 Probando " .. description .. " (animScale = " .. scale .. ")")
    
    local oldScale = ReadyCooldownAlertDB.animScale
    ReadyCooldownAlertDB.animScale = scale
    
    -- Refrescar configuración
    _G.AnimationProcessor:RefreshConfig()
    
    -- Ejecutar test
    _G.AnimationProcessor:TestAnimation()
    
    print("  ✅ Ejecutado - Tamaño esperado con iconSize " .. (ReadyCooldownAlertDB.iconSize or 75) .. ": " .. 
          ((ReadyCooldownAlertDB.iconSize or 75) * scale) .. " pixeles")
    
    -- Restaurar después de 3 segundos
    C_Timer.After(3, function()
        ReadyCooldownAlertDB.animScale = oldScale
        _G.AnimationProcessor:RefreshConfig()
        print("🔄 Escala restaurada a " .. oldScale)
    end)
end

print("🎯 Para probar escalas específicas:")
print("  /run TestSpecificScale(0.5, 'iconos pequeños')")
print("  /run TestSpecificScale(1.0, 'tamaño normal')")  
print("  /run TestSpecificScale(2.0, 'iconos grandes')")
print("")

-- Hacer las funciones globales para poder usarlas desde el chat
_G.TestSpecificScale = TestSpecificScale

-- Test automático
print("🚀 Iniciando test automático en 2 segundos...")
C_Timer.After(2, function()
    TestSpecificScale(1.0, "tamaño normal - BASELINE")
end)
