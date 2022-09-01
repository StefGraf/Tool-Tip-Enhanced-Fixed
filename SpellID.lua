--[[
    ... links and notes should be here ...
]]

local _, addonTable = ...
local _c = addonTable.config

if not _c.showSpellID then
    return -- ignore the code below
end

local spellIDText = GetLocale() == 'ruRU' and 'ID заклинания:' or _c.spellIDText
local spellIDTextColor = _c.spellIDTextColor:GenerateHexColor()

local function addLine(tooltip, id)
    if not id then return end

    tooltip:AddLine('|c' .. spellIDTextColor .. spellIDText .. '|r ' .. id, 1, 1, 1)
    tooltip:Show() -- update frame size
end

-- BuffFrame, UnitFrame
local function setUnitAura(self, unit, index, filter)
    local id = select(10, UnitAura(unit, index, filter))

    addLine(self, id)
end

-- SpellBookFrame, PlayerTalentFrame, ...
local function onTooltipSetSpell(self)
    local id = select(2, self:GetSpell())

    -- A duplicate line appears in PlayerTalentFrame
    for i = self:NumLines(), 3, -1 do
        local lineText = _G[self:GetName() .. 'TextLeft' .. i]:GetText()

        -- If "Spell ID" line is found
        if string.match(lineText, spellIDText) then
            return -- fix the issue
        end
    end
    addLine(self, id)
end

hooksecurefunc(GameTooltip, 'SetUnitAura', setUnitAura)
hooksecurefunc(GameTooltip, 'SetUnitBuff', setUnitAura)
hooksecurefunc(GameTooltip, 'SetUnitDebuff', setUnitAura)
GameTooltip:HookScript('OnTooltipSetSpell', onTooltipSetSpell)