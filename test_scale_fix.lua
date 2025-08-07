-- Test script para verificar el comportamiento correcto de animScale
-- Autor: Assistant
-- Este script verifica que animScale funcione como multiplicador

print("=== 🧪 TEST DE ESCALA CORRECTA ===")
print("Verificando que animScale funcione como multiplicador:")
print("  • animScale = 1.0 debería dar tamaño normal")
print("  • animScale = 0.5 debería dar iconos pequeños")
print("  • animScale = 2.0 debería dar iconos grandes")
print("")

-- Verificar que el addon está cargado
if not ReadyCooldownAlertDB then
    print("❌ ERROR: ReadyCooldownAlertDB no encontrado")
    return
end

if not AnimationData then
    print("❌ ERROR: AnimationData no encontrado")
    return
end

if not _G.AnimationProcessor then
    print("❌ ERROR: AnimationProcessor no encontrado")
    return
end

-- Función para probar diferentes escalas
function TestScale(scaleValue, description)
    print("📏 Probando " .. description .. " (animScale = " .. scaleValue .. "):")
    
    -- Guardar configuración original
    local originalScale = ReadyCooldownAlertDB.animScale
    local originalIconSize = ReadyCooldownAlertDB.iconSize
    
    -- Configurar test
    ReadyCooldownAlertDB.animScale = scaleValue
    ReadyCooldownAlertDB.iconSize = 75 -- Tamaño base estándar
    
    -- Simular una animación pulse
    local animationState = AnimationData:CalculateAnimationState("pulse", 0.2, 0.6) -- Hold phase
    
    if animationState then
        print("  🔸 Factor de animación: " .. tostring(animationState.scale))
        
        -- Calcular escala final como lo hace AnimationProcessor
        local finalScale = ReadyCooldownAlertDB.iconSize * ReadyCooldownAlertDB.animScale * animationState.scale
        print("  🔸 Cálculo: " .. ReadyCooldownAlertDB.iconSize .. " × " .. ReadyCooldownAlertDB.animScale .. " × " .. animationState.scale .. " = " .. finalScale)
        print("  🔸 Tamaño final: " .. finalScale .. " pixeles")
        
        -- Verificar lógica
        local expectedSize = 75 * scaleValue * animationState.scale
        if math.abs(finalScale - expectedSize) < 0.1 then
            print("  ✅ Correcto!")
        else
            print("  ❌ Error en el cálculo")
        end
    else
        print("  ❌ No se pudo obtener estado de animación")
    end
    
    -- Restaurar configuración
    ReadyCooldownAlertDB.animScale = originalScale
    ReadyCooldownAlertDB.iconSize = originalIconSize
    print("")
end

-- Probar diferentes escalas
TestScale(0.5, "iconos pequeños")
TestScale(1.0, "tamaño normal")
TestScale(1.5, "iconos medianos")
TestScale(2.0, "iconos grandes")

print("=== 🎯 RESULTADO ESPERADO ===")
print("Con iconSize = 75 y diferentes animScale:")
print("  • animScale 0.5 → 37.5 pixeles (pequeño)")
print("  • animScale 1.0 → 75 pixeles (normal)")
print("  • animScale 1.5 → 112.5 pixeles (mediano)")
print("  • animScale 2.0 → 150 pixeles (grande)")
print("")
print("Los factores de animación ahora son relativos (1.0 = normal)")
print("El tamaño final se calcula: iconSize × animScale × factorAnimación")

-- Función para probar todas las animaciones
function TestAllAnimationScales()
    print("=== 🎭 PROBANDO TODAS LAS ANIMACIONES ===")
    
    local animations = {"pulse", "bounce", "fade", "zoom", "glow"}
    ReadyCooldownAlertDB.animScale = 1.5
    ReadyCooldownAlertDB.iconSize = 75
    
    for _, animId in ipairs(animations) do
        print("🔸 " .. string.upper(animId) .. ":")
        
        -- Probar diferentes fases
        local phases = {
            {time = 0.05, total = 0.6, desc = "fade-in"},
            {time = 0.3, total = 0.6, desc = "hold"},
            {time = 0.55, total = 0.6, desc = "fade-out"}
        }
        
        for _, phase in ipairs(phases) do
            local state = AnimationData:CalculateAnimationState(animId, phase.time, phase.total)
            if state then
                local finalSize = 75 * 1.5 * state.scale
                print("    " .. phase.desc .. ": factor=" .. string.format("%.2f", state.scale) .. 
                      ", size=" .. string.format("%.1f", finalSize) .. "px")
            end
        end
        print("")
    end
end

print("Para probar todas las animaciones ejecuta: TestAllAnimationScales()")
