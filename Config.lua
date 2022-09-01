--[[
    https://wowpedia.fandom.com/wiki/Using_the_AddOn_namespace
    https://wowpedia.fandom.com/wiki/WOW_PROJECT_ID
    https://github.com/Stanzilla/WoWUIBugs/issues/68#issuecomment-830351390
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/SharedXML/SharedColorConstants.lua
]]

local _, addonTable = ...

addonTable.projects = {
    isRetail      = ( WOW_PROJECT_ID == WOW_PROJECT_MAINLINE ),
    isClassic     = ( WOW_PROJECT_ID == WOW_PROJECT_CLASSIC ),
    isClassic_TBC = ( WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC ), -- WOTLK will reuse WOW_PROJECT_BURNING_CRUSADE_CLASSIC

    -- isRetail      = false,
    -- isClassic     = true,
    -- isClassic_TBC = true,
}

addonTable.config = {
    enableClassColor  = true,
    enableGuildColor  = true,
    hideUnitTitle     = true,
    showUnitHealth    = true,
    healthFontSize    = 13, -- 12, 13, 14

    attachToCursor    = true,
    attachToCursorAlt = false, -- WorldFrame only
    detachInCombat    = true,
    useCustomPosition = false,
    point             = 'BOTTOMRIGHT',
    relativeFrame     = UIParent,
    relativePoint     = 'BOTTOMRIGHT',
    offsetX           = -CONTAINER_OFFSET_X - 23,
    offsetY           = CONTAINER_OFFSET_Y,

    showSpellID       = false,
    spellIDText       = 'Spell ID:',
    spellIDTextColor  = CreateColor(1, 0.50196, 0), -- LEGENDARY_ORANGE_COLOR
}
