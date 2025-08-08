-- Ready Cooldown Alert - Inicializador Principal
local addonName, addonTable = ...

-- Crear namespace global para el addon
ReadyCooldownAlert = ReadyCooldownAlert or {}
local RCA = ReadyCooldownAlert

-- Variables de estado
RCA.isLoaded = false
RCA.modules = {}

-- Frame principal para eventos
local eventFrame = CreateFrame("Frame")
local events = {
    "ADDON_LOADED",
    "PLAYER_LOGIN", 
    "PLAYER_ENTERING_WORLD",
    "PLAYER_SPECIALIZATION_CHANGED",
    "SPELL_UPDATE_COOLDOWN"
}

for _, event in ipairs(events) do
    eventFrame:RegisterEvent(event)
end

-- Configurar animaciones
local function InitializeAnimationConfiguration()
    local OptionsLogic = rawget(_G, "OptionsLogic")
    if not ReadyCooldownAlertDB or not OptionsLogic then
        return
    end
    
    OptionsLogic:InitializeDefaultConfig()
    local selectedAnimation = ReadyCooldownAlertDB.selectedAnimation or "pulse"
    OptionsLogic:LoadAnimationConfiguration(selectedAnimation)
end

-- Inicializar SavedVariables por defecto
local function InitializeDatabase()
    if not ReadyCooldownAlertDB then
        ReadyCooldownAlertDB = {}
    end
    
    local structureDefaults = {
        selectedAnimation = "pulse",
        animationConfigs = {},
        showSpellName = true,
        ignoredSpells = "",
        invertIgnored = false,
        petOverlay = {1, 1, 1}
    }
    
    for key, value in pairs(structureDefaults) do
        if ReadyCooldownAlertDB[key] == nil then
            ReadyCooldownAlertDB[key] = value
        end
    end
end

local function InitializeModules()
    local FilterProcessor = rawget(_G, "FilterProcessor")
    if FilterProcessor then
        FilterProcessor:Initialize()
        RCA.modules.FilterProcessor = FilterProcessor
    end
    
    local AnimationProcessor = rawget(_G, "AnimationProcessor")
    if AnimationProcessor then
        AnimationProcessor:RefreshConfig()
        RCA.modules.AnimationProcessor = AnimationProcessor
    end
    
    local LogicManager = rawget(_G, "LogicManager")
    if LogicManager then
        LogicManager:Initialize()
        RCA.modules.LogicManager = LogicManager
    end
    
    local MainFrame = rawget(_G, "MainFrame")
    if MainFrame then
        MainFrame:Initialize()
        RCA.modules.MainFrame = MainFrame
    end
    
    local OptionsFrame = rawget(_G, "OptionsFrame")
    if OptionsFrame then
        OptionsFrame:Initialize()
        RCA.modules.OptionsFrame = OptionsFrame
    end
    
    local HookManager = rawget(_G, "HookManager")
    if HookManager then
        HookManager:RegisterCallback(function(actionType, id, texture, extraData)
            if RCA.modules.LogicManager then
                RCA.modules.LogicManager:ProcessAction(actionType, id, texture, extraData)
            end
        end)
        
        HookManager:Initialize()
        RCA.modules.HookManager = HookManager
    end
    
    if RCA.modules.AnimationProcessor and RCA.modules.MainFrame then
        RCA.modules.AnimationProcessor:RegisterUICallback(function(eventType, animationData)
            RCA.modules.MainFrame:OnAnimationEvent(eventType, animationData)
        end)
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            InitializeDatabase()
            
            SLASH_READYCOOLDOWNALERT1 = "/rca"
            SlashCmdList["READYCOOLDOWNALERT"] = function()
                if RCA.modules.OptionsFrame then
                    RCA.modules.OptionsFrame:Toggle()
                end
            end
        end
        
    elseif event == "PLAYER_LOGIN" then
        InitializeModules()
        InitializeAnimationConfiguration()
        RCA.isLoaded = true
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        if RCA.modules.LogicManager then
            RCA.modules.LogicManager:OnPlayerEnteringWorld()
        end
        
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if RCA.modules.LogicManager then
            RCA.modules.LogicManager:OnPlayerSpecializationChanged()
        end
        
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if RCA.modules.LogicManager then
            RCA.modules.LogicManager:OnSpellUpdateCooldown()
        end
    end
end)
