local SpellData = {}

function SpellData:GetSpellInfo(spellID)
    return {
        name = C_Spell.GetSpellName(spellID),
        texture = C_Spell.GetSpellTexture(spellID),
        spellID = spellID
    }
end

function SpellData:GetSpellCooldown(spellID)
    local cooldown = C_Spell.GetSpellCooldown(spellID)
    return {
        start = cooldown.startTime,
        duration = cooldown.duration,
        enabled = cooldown.isEnabled,
        modRate = cooldown.modRate or 1
    }
end

function SpellData:IsSpellKnown(spellID)
    return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
end

function SpellData:GetRemainingCooldown(spellID)
    local cooldown = self:GetSpellCooldown(spellID)
    if cooldown.start and cooldown.duration > 0 then
        return cooldown.duration - (GetTime() - cooldown.start)
    end
    return 0
end

_G.SpellData = SpellData

return SpellData