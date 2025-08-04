-- Test de validación de estructura modular
-- Este archivo sirve para verificar que todos los módulos se cargan correctamente

local function TestModuleStructure()
    print("=== Ready Cooldown Alert - Test de Estructura ===")
    
    -- Test Data modules
    print("\n--- Testing Data Modules ---")
    if SpellData then
        print("✓ SpellData cargado")
        if SpellData.GetSpellInfo then print("  ✓ GetSpellInfo disponible") end
        if SpellData.GetSpellCooldown then print("  ✓ GetSpellCooldown disponible") end
    else
        print("✗ SpellData NO cargado")
    end
    
    if ItemData then
        print("✓ ItemData cargado")
        if ItemData.GetItemInfo then print("  ✓ GetItemInfo disponible") end
        if ItemData.GetItemCooldown then print("  ✓ GetItemCooldown disponible") end
    else
        print("✗ ItemData NO cargado")
    end
    
    if PetData then
        print("✓ PetData cargado")
        if PetData.GetPetActionInfo then print("  ✓ GetPetActionInfo disponible") end
    else
        print("✗ PetData NO cargado")
    end
    
    if CooldownData then
        print("✓ CooldownData cargado")
        if CooldownData.GetCooldownDetails then print("  ✓ GetCooldownDetails disponible") end
        if CooldownData.IsValidForTracking then print("  ✓ IsValidForTracking disponible") end
    else
        print("✗ CooldownData NO cargado")
    end
    
    -- Test Hook modules
    print("\n--- Testing Hook Modules ---")
    if ActionHooks then
        print("✓ ActionHooks cargado")
        if ActionHooks.Initialize then print("  ✓ Initialize disponible") end
    else
        print("✗ ActionHooks NO cargado")
    end
    
    if SpellHooks then
        print("✓ SpellHooks cargado")
    else
        print("✗ SpellHooks NO cargado")
    end
    
    if CombatHooks then
        print("✓ CombatHooks cargado")
    else
        print("✗ CombatHooks NO cargado")
    end
    
    if HookManager then
        print("✓ HookManager cargado")
        if HookManager.Initialize then print("  ✓ Initialize disponible") end
    else
        print("✗ HookManager NO cargado")
    end
    
    -- Test Logic modules
    print("\n--- Testing Logic Modules ---")
    if FilterProcessor then
        print("✓ FilterProcessor cargado")
        if FilterProcessor.ShouldFilter then print("  ✓ ShouldFilter disponible") end
    else
        print("✗ FilterProcessor NO cargado")
    end
    
    if AnimationProcessor then
        print("✓ AnimationProcessor cargado")
        if AnimationProcessor.QueueAnimation then print("  ✓ QueueAnimation disponible") end
    else
        print("✗ AnimationProcessor NO cargado")
    end
    
    if CooldownProcessor then
        print("✓ CooldownProcessor cargado")
        if CooldownProcessor.AddToWatching then print("  ✓ AddToWatching disponible") end
    else
        print("✗ CooldownProcessor NO cargado")
    end
    
    if LogicManager then
        print("✓ LogicManager cargado")
        if LogicManager.ProcessAction then print("  ✓ ProcessAction disponible") end
    else
        print("✗ LogicManager NO cargado")
    end
    
    -- Test UI modules
    print("\n--- Testing UI Modules ---")
    if MainFrame then
        print("✓ MainFrame cargado")
        if MainFrame.Initialize then print("  ✓ Initialize disponible") end
        if MainFrame.TestAnimation then print("  ✓ TestAnimation disponible") end
    else
        print("✗ MainFrame NO cargado")
    end
    
    if OptionsFrame then
        print("✓ OptionsFrame cargado")
        if OptionsFrame.Toggle then print("  ✓ Toggle disponible") end
    else
        print("✗ OptionsFrame NO cargado")
    end
    
    -- Test SavedVariables
    print("\n--- Testing SavedVariables ---")
    if ReadyCooldownAlertDB then
        print("✓ ReadyCooldownAlertDB disponible")
        print("  Configuraciones encontradas:", table.getn and table.getn(ReadyCooldownAlertDB) or "N/A")
    else
        print("✗ ReadyCooldownAlertDB NO disponible")
    end
    
    -- Test addon namespace
    print("\n--- Testing Addon Namespace ---")
    if ReadyCooldownAlert then
        print("✓ ReadyCooldownAlert namespace disponible")
        if ReadyCooldownAlert.isLoaded then print("  ✓ isLoaded:", ReadyCooldownAlert.isLoaded) end
        if ReadyCooldownAlert.version then print("  ✓ version:", ReadyCooldownAlert.version) end
    else
        print("✗ ReadyCooldownAlert namespace NO disponible")
    end
    
    print("\n=== Test Completado ===")
end

-- Registrar comando de test
SLASH_RCATEST1 = "/rcatest"
SlashCmdList["RCATEST"] = function()
    TestModuleStructure()
end

print("|cff00ff00Ready Cooldown Alert|r: Usa |cffFFFFFF/rcatest|r para validar la estructura modular")
