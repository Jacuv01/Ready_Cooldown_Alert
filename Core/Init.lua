-- Ready Cooldown Alert - Inicializador Principal
local addonName, addonTable = ...

-- Crear namespace global para el addon
ReadyCooldownAlert = ReadyCooldownAlert or {}
local RCA = ReadyCooldownAlert

-- Variables de estado
RCA.isLoaded = false
RCA.modules = {}Loaded = false
RCA.modules = {}

-- Frame principal para eventos
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

-- Cargar configuración específica de la animación al inicializar
local function InitializeAnimationConfiguration()
    if not ReadyCooldownAlertDB or not _G.OptionsLogic then
        print("|cffFF0000RCA Debug|r: InitializeAnimationConfiguration - Missing dependencies")
        return
    end
    
    -- Primero, asegurar que la configuración básica esté inicializada
    _G.OptionsLogic:InitializeDefaultConfig()
    
    -- Obtener la animación seleccionada
    local selectedAnimation = ReadyCooldownAlertDB.selectedAnimation or "pulse"
    
    -- Cargar configuración específica de esta animación (esto cargará los valores guardados o usará defaults)
    _G.OptionsLogic:LoadAnimationConfiguration(selectedAnimation)
    
    print("|cff00ff00RCA|r: Configuración cargada para animación:", selectedAnimation)
end

-- Inicializar SavedVariables por defecto
local function InitializeDatabase()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    -- Solo inicializar estructura básica si no existe
    local structureDefaults = {
        selectedAnimation = "pulse",
        animationConfigs = {},
        showSpellName = true,
        ignoredSpells = "",
        invertIgnored = false,
        petOverlay = {1, 1, 1}
    }
    
    -- Aplicar solo estructura básica si no existe
    for key, value in pairs(structureDefaults) do
        if ReadyCooldownAlertDB[key] == nil then
            ReadyCooldownAlertDB[key] = value
        end
    end
    
    -- Asegurar que valores importantes no se sobrescriban con nils
    -- (los valores de sliders se manejan en OptionsLogic:InitializeDefaultConfig)
    print("|cff00ffff RCA Debug|r: InitializeDatabase completed - iconSize is", ReadyCooldownAlertDB.iconSize)
end

-- Inicializar todos los módulos
local function InitializeModules()
    print("|cff00ff00Ready Cooldown Alert|r: Inicializando módulos...")
    
    -- Inicializar Logic modules
    if FilterProcessor then
        print("|cff00ff00RCA|r: Inicializando FilterProcessor...")
        FilterProcessor:Initialize()
        RCA.modules.FilterProcessor = FilterProcessor
        print("|cff00ff00RCA|r: FilterProcessor inicializado [OK]")
    else
        print("|cffFF0000RCA|r: FilterProcessor NO disponible [ERROR]")
    end
    
    if AnimationProcessor then
        print("|cff00ff00RCA|r: Inicializando AnimationProcessor...")
        AnimationProcessor:RefreshConfig()
        RCA.modules.AnimationProcessor = AnimationProcessor
        print("|cff00ff00RCA|r: AnimationProcessor inicializado [OK]")
    else
        print("|cffFF0000RCA|r: AnimationProcessor NO disponible [ERROR]")
    end
    
    if LogicManager then
        print("|cff00ff00RCA|r: Inicializando LogicManager...")
        LogicManager:Initialize()
        RCA.modules.LogicManager = LogicManager
        print("|cff00ff00RCA|r: LogicManager inicializado [OK]")
    else
        print("|cffFF0000RCA|r: LogicManager NO disponible [ERROR]")
    end
    
    -- Inicializar UI modules
    if MainFrame then
        print("|cff00ff00RCA|r: Inicializando MainFrame...")
        MainFrame:Initialize()
        RCA.modules.MainFrame = MainFrame
        print("|cff00ff00RCA|r: MainFrame inicializado [OK]")
    else
        print("|cffFF0000RCA|r: MainFrame NO disponible [ERROR]")
    end
    
    if OptionsFrame then
        print("|cff00ff00RCA|r: Inicializando OptionsFrame...")
        OptionsFrame:Initialize()
        RCA.modules.OptionsFrame = OptionsFrame
        print("|cff00ff00RCA|r: OptionsFrame inicializado [OK]")
    else
        print("|cffFF0000RCA|r: OptionsFrame NO disponible [ERROR]")
    end
    
    -- Inicializar Hook system
    if HookManager then
        print("|cff00ff00RCA|r: Inicializando HookManager...")
        -- Registrar callback para procesar acciones detectadas
        HookManager:RegisterCallback(function(actionType, id, texture, extraData)
            if LogicManager then
                LogicManager:ProcessAction(actionType, id, texture, extraData)
            end
        end)
        
        HookManager:Initialize()
        RCA.modules.HookManager = HookManager
        print("|cff00ff00RCA|r: HookManager inicializado correctamente")
    else
        print("|cffFF0000RCA|r: ERROR - HookManager no disponible")
    end
    
    -- Conectar AnimationProcessor con MainFrame
    if AnimationProcessor and MainFrame then
        AnimationProcessor:RegisterUICallback(function(eventType, animationData)
            MainFrame:OnAnimationEvent(eventType, animationData)
        end)
    end
    
    print("|cff00ff00Ready Cooldown Alert|r: Módulos inicializados correctamente")
    
    -- Cargar configuración específica de la animación seleccionada
    -- InitializeAnimationConfiguration() -- Removido - ahora se maneja en el dropdown
    
    -- Debug: Mostrar módulos cargados
    local moduleCount = 0
    for name, module in pairs(RCA.modules) do
        moduleCount = moduleCount + 1
        print("|cff888888RCA Debug|r: Módulo cargado:", name)
    end
    print("|cff888888RCA Debug|r: Total módulos cargados:", moduleCount)
end

-- Manejador de eventos
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            InitializeDatabase()
            
            -- Registrar comando slash
            SLASH_READYCOOLDOWNALERT1 = "/rca"
            SLASH_READYCOOLDOWNALERT2 = "/readycooldownalert"
            SlashCmdList["READYCOOLDOWNALERT"] = function(msg)
                RCA:HandleSlashCommand(msg)
            end
            
            print("|cff00ff00Ready Cooldown Alert|r: Addon cargado. Usa /rca para abrir opciones.")
        end
        
    elseif event == "PLAYER_LOGIN" then
        -- Inicializar módulos después del login
        InitializeModules()
        
        -- Cargar configuración específica de la animación seleccionada después de que todos los módulos estén listos
        InitializeAnimationConfiguration()
        
        RCA.isLoaded = true
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        if LogicManager then
            LogicManager:OnPlayerEnteringWorld()
        end
        
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if LogicManager then
            LogicManager:OnPlayerSpecializationChanged()
        end
        
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if LogicManager then
            LogicManager:OnSpellUpdateCooldown()
        end
    end
end)

-- Manejar comandos slash
function RCA:HandleSlashCommand(msg)
    msg = string.trim(msg or "")
    
    if msg == "" or msg == "options" or msg == "config" then
        -- Abrir panel de opciones
        if OptionsFrame then
            OptionsFrame:Toggle()
        else
            print("|cffff0000Error:|r Panel de opciones no disponible")
        end
        
    elseif msg == "test" then
        -- Ejecutar animación de prueba
        if AnimationProcessor then
            AnimationProcessor:TestAnimation()
        elseif MainFrame then
            MainFrame:TestAnimation()
        else
            print("|cffff0000Error:|r Sistema de animación no disponible")
        end
        
    elseif msg == "testchain" then
        -- Probar toda la cadena de procesamiento
        print("|cff00ff00RCA Test Chain|r: Probando cadena completa...")
        
        if LogicManager then
            print("|cff00ff00RCA Test Chain|r: Enviando acción de prueba a LogicManager...")
            LogicManager:ProcessAction("spell", 12345, "Interface\\Icons\\Spell_Holy_Heal", { source = "test" })
        else
            print("|cffff0000Error:|r LogicManager no disponible")
        end
        
    elseif string.match(msg, "^threshold%s+(%d+)$") then
        -- Cambiar threshold de notificación
        local threshold = tonumber(string.match(msg, "^threshold%s+(%d+)$"))
        if threshold then
            ReadyCooldownAlertDB = ReadyCooldownAlertDB or {}
            ReadyCooldownAlertDB.remainingCooldownWhenNotified = threshold
            print("|cff00ff00RCA|r: Threshold cambiado a", threshold, "segundos")
            print("|cff888888Info|r: Ahora las alertas aparecerán cuando falten", threshold, "segundos")
        end
        
    elseif msg == "animinfo" then
        -- Mostrar información de configuración de animaciones
        print("|cff00ff00RCA Animation Info:|r")
        if ReadyCooldownAlertDB then
            local fadeIn = ReadyCooldownAlertDB.fadeInTime or 0.3
            local fadeOut = ReadyCooldownAlertDB.fadeOutTime or 0.7
            local hold = ReadyCooldownAlertDB.holdTime or 0
            local total = fadeIn + hold + fadeOut
            
            print("  Fade In:", fadeIn, "s")
            print("  Hold Time:", hold, "s") 
            print("  Fade Out:", fadeOut, "s")
            print("  Tiempo Total:", total, "s")
            
            if AnimationProcessor then
                print("  AnimationProcessor: disponible")
                print("  Animaciones en cola: (verificar con debug)")
            end
        end
        
    elseif msg == "tracking" then
        -- Mostrar qué cooldowns están siendo trackeados actualmente
        print("|cff00ff00RCA Tracking Info:|r")
        if LogicManager then
            local status = LogicManager:GetStatus()
            if status.cooldownProcessor then
                print("  Watching:", status.cooldownProcessor.watching or 0)
                print("  Cooldowns activos:", status.cooldownProcessor.cooldowns or 0)
                print("  Animando:", status.cooldownProcessor.animating or 0)
                

            end
        end
        
    elseif msg == "unlock" then
        -- Desbloquear frame para mover
        if MainFrame then
            MainFrame:SetLocked(false)
            print("|cff00ff00Ready Cooldown Alert:|r Frame desbloqueado. Arrastra para mover.")
        else
            print("|cffff0000Error:|r MainFrame no disponible")
        end
        
    elseif msg == "lock" then
        -- Bloquear frame
        if MainFrame then
            MainFrame:SetLocked(true)
            print("|cff00ff00Ready Cooldown Alert:|r Frame bloqueado.")
        else
            print("|cffff0000Error:|r MainFrame no disponible")
        end
        
    elseif msg == "status" then
        -- Mostrar estado del addon
        print("|cff00ff00Ready Cooldown Alert - Estado:|r")
        print("  Cargado:", RCA.isLoaded and "Sí" or "No")
        
        -- Contar módulos correctamente
        local moduleCount = 0
        for _ in pairs(RCA.modules) do
            moduleCount = moduleCount + 1
        end
        print("  Módulos activos:", moduleCount)
        
        -- Listar módulos cargados
        for name, module in pairs(RCA.modules) do
            print("    [CARGADO]", name)
        end
        
        if LogicManager then
            local status = LogicManager:GetStatus()
            if status.cooldownProcessor then
                print("  CooldownProcessor: disponible")
                -- Nota: estos campos pueden no estar inicializados aún
                local watching = status.cooldownProcessor.watching
                local cooldowns = status.cooldownProcessor.cooldowns  
                local animating = status.cooldownProcessor.animating
                
                print("  Cooldowns monitoreados:", (watching and type(watching) == "table" and #watching) or 0)
                print("  Cooldowns activos:", (cooldowns and type(cooldowns) == "table" and #cooldowns) or 0)
                print("  Animaciones en cola:", (animating and type(animating) == "table" and #animating) or 0)
            else
                print("  CooldownProcessor: no disponible")
            end
        end
        
    elseif msg == "reset" then
        -- Resetear posición del frame
        if MainFrame then
            MainFrame:ResetPosition()
            print("|cff00ff00Ready Cooldown Alert:|r Posición reseteada al centro.")
        else
            print("|cffff0000Error:|r MainFrame no disponible")
        end
        
    elseif msg == "debug" then
        -- Alternar modo debug
        if not ReadyCooldownAlertDB then ReadyCooldownAlertDB = {} end
        ReadyCooldownAlertDB.debug = not ReadyCooldownAlertDB.debug
        print("|cff00ff00Ready Cooldown Alert:|r Debug", ReadyCooldownAlertDB.debug and "ACTIVADO" or "DESACTIVADO")
        
        -- También mostrar estado de hooks cuando se activa debug
        if ReadyCooldownAlertDB.debug then
            print("|cff888888RCA Debug|r: Estado de hooks:")
            print("  ActionHooks disponible:", ActionHooks and "SI" or "NO")
            print("  SpellHooks disponible:", SpellHooks and "SI" or "NO")
            print("  CombatHooks disponible:", CombatHooks and "SI" or "NO")
            print("  HookManager disponible:", HookManager and "SI" or "NO")
            print("|cffFFFF00Info|r: Ahora puedes:")
            print("  - Usar hechizos desde barras de acción")
            print("  - Usar habilidades y teclas de acceso rápido")
            print("  - Usar items desde inventario/bolsas")
            print("  - Ver mensajes detallados en el chat")
            print("|cff888888RCA Debug|r: Usa una habilidad ahora para ver si se detecta...")
        end
        
    else
        -- Mostrar ayuda
        print("|cff00ff00Ready Cooldown Alert - Comandos:|r")
        print("  |cffFFFFFF/rca|r - Mostrar esta ayuda")
        print("  |cffFFFFFF/rca status|r - Ver estado de módulos")
        print("  |cffFFFFFF/rca debug|r - Activar/desactivar debug")
        print("  |cffFFFFFF/rca test|r - Probar animación")
        print("  |cffFFFFFF/rca testchain|r - Probar cadena completa")
        print("  |cffFFFFFF/rca threshold X|r - Cambiar alerta a X segundos")
        print("  |cffFFFFFF/rca animinfo|r - Ver info de animaciones")
        print("  |cffFFFFFF/rca tracking|r - Ver cooldowns trackeados")
        print("  |cffFFFFFF/rca reset|r - Reiniciar configuración")
        print("  |cffFFFFFF/rca unlock|r - Desbloquear para mover")
        print("  |cffFFFFFF/rca lock|r - Bloquear posición")
        print("|cff888888Nota:|r Si el addon no funciona, usa '/rca debug' y prueba usar una habilidad")
    end
end

-- Función de debug para desarrollo
function RCA:Debug(...)

end

-- Versión del addon
RCA.version = "1.0.0"

print("|cff00ff00Ready Cooldown Alert|r v" .. RCA.version .. " iniciando...")
