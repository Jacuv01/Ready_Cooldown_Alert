local ControlsManager = {}

-- Referencias locales
local checkboxes = {}
local dropdowns = {}

-- Crear todos los controls (checkboxes, dropdowns) - whitelist movido a FiltersUI
function ControlsManager:CreateAllControls(parentFrame, sliderCount)
    self:CreateDropdowns(parentFrame)
    self:CreateCheckboxes(parentFrame, sliderCount)
    
    return {
        checkboxes = checkboxes,
        dropdowns = dropdowns
    }
end

-- Crear checkboxes
function ControlsManager:CreateCheckboxes(parentFrame, sliderCount)
    local position = _G.LayoutManager:GetCheckboxesPosition(sliderCount)
    local yOffset = position.startY
    
    -- Checkbox para mostrar nombres de hechizos
    local showNameCB = CreateFrame("CheckButton", "RCAShowNameCheckbox", parentFrame, "ChatConfigCheckButtonTemplate")
    showNameCB:SetPoint("TOPLEFT", position.x, yOffset)
    showNameCB.Text:SetText("Show Spell Names")
    
    -- Configurar valor inicial
    local showSpellName = ReadyCooldownAlertDB and ReadyCooldownAlertDB.showSpellName
    if showSpellName == nil then showSpellName = true end
    showNameCB:SetChecked(showSpellName)
    
    showNameCB:SetScript("OnClick", function(self)
        if ReadyCooldownAlertDB then
            ReadyCooldownAlertDB.showSpellName = self:GetChecked()
            if _G.OptionsFrame then
                _G.OptionsFrame:OnConfigChanged("showSpellName", self:GetChecked())
            end
        end
    end)
    
    checkboxes.showSpellName = showNameCB
    yOffset = yOffset - position.spacing
    
    -- NOTA: Whitelist/Filter checkbox movido a FiltersUI en pestaña separada
end

-- NOTA: CreateEditBoxes removido - funcionalidad movida a FiltersUI

-- Función para poblar el dropdown de animaciones
local function InitializeAnimationDropdown(self, level)
    if not _G.AnimationData then
        return
    end
    
    local animationList = _G.AnimationData:GetAnimationList()
    for _, animation in ipairs(animationList) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = animation.text
        info.value = animation.value
        info.tooltipTitle = animation.text
        info.tooltipText = animation.tooltip
        info.func = function()
            UIDropDownMenu_SetSelectedValue(dropdowns.animationType, animation.value)
            UIDropDownMenu_SetText(dropdowns.animationType, animation.text)
            
            -- PRIMERO: Guardar configuración actual ANTES de cambiar (si hay una animación previa)
            local previousAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation
            if previousAnimation and previousAnimation ~= animation.value and _G.OptionsLogic then
                _G.OptionsLogic:SaveAnimationConfiguration(previousAnimation)
                print("|cff00ff00RCA Debug|r: Guardando configuración de", previousAnimation, "antes de cambiar a", animation.value)
            end
            
            -- SEGUNDO: Guardar nueva selección
            if ReadyCooldownAlertDB then
                ReadyCooldownAlertDB.selectedAnimation = animation.value
                print("|cff00ff00RCA Debug|r: Updated selectedAnimation to", animation.value)
                if _G.OptionsFrame then
                    _G.OptionsFrame:OnConfigChanged("selectedAnimation", animation.value)
                end
            end
            
            -- TERCERO: Cargar configuración específica de la nueva animación seleccionada
            if _G.OptionsLogic then
                _G.OptionsLogic:LoadAnimationConfiguration(animation.value)
            end
            
            -- CUARTO: Refrescar valores en la interfaz DESPUÉS de cargar (con pequeño delay para timing)
            C_Timer.After(0.05, function()
                if _G.OptionsFrame then
                    _G.OptionsFrame:RefreshValues()
                end
                if _G.SliderManager then
                    _G.SliderManager:RefreshValues()
                end
                print("|cff00ff00RCA Debug|r: UI refreshed for animation", animation.value)
            end)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Crear dropdowns
function ControlsManager:CreateDropdowns(parentFrame)
    if not parentFrame then
        return
    end
    
    local position = _G.LayoutManager:GetDropdownsPosition()
    local yOffset = position.startY
    
    -- Label para animación
    local animationLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    animationLabel:SetPoint("TOPLEFT", position.x, yOffset)
    animationLabel:SetText("Animation Type:")
    
    -- Crear dropdown para tipo de animación
    local animationDropdown = CreateFrame("Frame", "RCAAnimationDropdown", parentFrame, "UIDropDownMenuTemplate")
    animationDropdown:SetPoint("LEFT", animationLabel, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(animationDropdown, 200)
    UIDropDownMenu_SetText(animationDropdown, "Select Animation")
    
    -- Inicializar dropdown con la función externa
    UIDropDownMenu_Initialize(animationDropdown, InitializeAnimationDropdown)
    
    -- Configurar valor inicial
    local selectedAnimation = ReadyCooldownAlertDB and ReadyCooldownAlertDB.selectedAnimation or "pulse"
    UIDropDownMenu_SetSelectedValue(animationDropdown, selectedAnimation)
    
    -- Obtener el nombre de la animación para mostrar
    if _G.AnimationData then
        local animationData = _G.AnimationData:GetAnimation(selectedAnimation)
        if animationData then
            UIDropDownMenu_SetText(animationDropdown, animationData.name)
        end
    end
    
    dropdowns.animationType = animationDropdown
end

-- Actualizar valores en la interfaz
function ControlsManager:RefreshValues()
    -- Actualizar checkboxes
    if checkboxes.showSpellName and _G.OptionsLogic then
        local showSpellName = _G.OptionsLogic:GetConfigValue("showSpellName")
        if showSpellName == nil then showSpellName = true end
        checkboxes.showSpellName:SetChecked(showSpellName and true or false)
    end
    
    -- NOTA: invertIgnored y ignoredSpells ahora se manejan en FiltersUI
    
    -- Actualizar dropdowns
    if dropdowns.animationType and _G.OptionsLogic then
        local selectedAnimation = _G.OptionsLogic:GetConfigValue("selectedAnimation") or "pulse"
        UIDropDownMenu_SetSelectedValue(dropdowns.animationType, selectedAnimation)
        
        -- Actualizar texto mostrado
        if _G.AnimationData then
            local animationData = _G.AnimationData:GetAnimation(selectedAnimation)
            if animationData then
                UIDropDownMenu_SetText(dropdowns.animationType, animationData.name)
            end
        end
    end
end

-- Obtener referencias de controls
function ControlsManager:GetControls()
    return {
        checkboxes = checkboxes,
        dropdowns = dropdowns
        -- NOTA: editBoxes removido - funcionalidad en FiltersUI
    }
end

-- Exportar globalmente para WoW addon system
_G.ControlsManager = ControlsManager

return ControlsManager
