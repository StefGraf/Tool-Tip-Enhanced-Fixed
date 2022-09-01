--[[
    https://us.forums.blizzard.com/en/wow/t/wow-classic-ui-api-change-for-unithealth/446596
    https://www.townlong-yak.com/framexml/37176/GlobalStrings.lua/RU
    https://en.wikipedia.org/wiki/International_System_of_Units#Prefixes
    https://stackoverflow.com/questions/9461621/format-a-number-as-2-5k-if-a-thousand-or-more-otherwise-900
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/GameTooltip.lua#L94-L157
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/SharedXML/SharedColorConstants.lua#L73-L82
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/UIParent.lua#L5351-L5362
]]

local _, addonTable = ...
local _p = addonTable.projects
local _c = addonTable.config
local db = {} -- local database

-- Some units do not return UnitID in certain cases
-- For example, the mage's spell "Mirror Image" or the monk's spell "Storm, Earth and Fire"
local function fixGetUnit(tooltip)
    local unit = select(2, tooltip:GetUnit())

    -- When the mouse is over a UnitFrame
    if not unit then
        local frame = GetMouseFocus()
        unit = frame and frame.GetAttribute and frame:GetAttribute('unit') -- fix the issue
    end

    -- When the mouse is over a WorldFrame and nameplates are not displayed
    if not unit and UnitExists('mouseover') then
        unit = 'mouseover' -- fix the issue
    end
    return unit
end

local function insertLine(tooltip, position, text, color)
    tooltip:AddLine(text, 1, 1, 1) -- text and color do not matter at this step
    tooltip:Show() -- update frame size

    local numLines = tooltip:NumLines()
    local position = math.min(math.max(position, 2), numLines) -- math.clamp()
    local color = color or CreateColor(1, 1, 1)

    for i = numLines, position, -1 do
        local currLine = _G[tooltip:GetName() .. 'TextLeft' .. i]
        local nextLine = _G[tooltip:GetName() .. 'TextLeft' .. i - 1]

        if i == position then
            currLine:SetText( text )
            currLine:SetTextColor( color.r, color.g, color.b )
            return -- stop the loop and exit the function
        end
        currLine:SetText( nextLine:GetText() )
        currLine:SetTextColor( nextLine:GetTextColor() ) -- RESURRECTABLE is green
    end
end

-- Add missing lines to make the tooltip look like the Retail version
local function addMissingLines(tooltip, data)
    if _p.isRetail or not data.unitIsPlayer then return end

    if _p.isClassic and data.unitGuildInfo[1] then
        insertLine( tooltip, 2, data.unitGuildInfo[4] and (data.unitGuildInfo[1] .. '-' .. data.unitGuildInfo[4]) or data.unitGuildInfo[1] ) -- TBC
    end
    insertLine( tooltip, data.unitGuildInfo[1] and 4 or 3, data.unitFaction ) -- MoP
end

local function colorizeLines(tooltip, data)
    if not data.unitIsPlayer or (not _c.enableClassColor and not _c.enableGuildColor) then return end

    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. 'TextLeft' .. i]
        local lineText = line:GetText()

        -- Name line
        -- SetTextColor() does not work with UnitFrame name line
        if i == 1 and _c.enableClassColor then
            line:SetText( '|c' .. data.unitClassColor.colorStr .. lineText .. '|r' ) -- fix the issue

        -- Guild line
        elseif i == 2 and data.unitGuildInfo[1] and _c.enableGuildColor then
            line:SetTextColor( 0.251, 1, 0.251 ) -- ChatTypeInfo['GUILD']

        -- Faction line
        elseif lineText == data.unitFaction then
            if data.unitFaction ~= select(2, UnitFactionGroup('player')) and _c.enableClassColor then
                line:SetTextColor( unpack(data.unitReactionColor) )
            end
            return
        end
    end
end

-- Health obfuscation in the Classic version
-- Health values for NPCs
-- Health percentages for players or the units they summon (totems, guardians, etc. are considered NPCs)
local function shouldKnowUnitHealth(data)
    return (not data.unitIsPlayer and not data.unitIsPet) or data.unitIsMine or data.unitInGroup
end

-- Custom function instead of the original AbbreviateLargeNumbers()
-- Currently not used
local function abbreviateLargeNumbers(number)
    if number >= 1e9 then return string.format('%.1fG', number / 1e9) -- 1.6G, 61.8G
    elseif number >= 1e8 then return string.format('%.0fM', number / 1e6) -- 128M
    elseif number >= 1e6 then return string.format('%.1fM', number / 1e6) -- 1.6M, 61.8M
    elseif number >= 1e5 then return string.format('%.0fk', number / 1e3) -- 128k
    elseif number >= 1e3 then return string.format('%.1fk', number / 1e3) -- 1.6k, 61.8k
    elseif number > 0 then return tostring(number)
    else return '0'
    end
end

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function updateStatusBar(statusBar, data)
    local currHealth = statusBar:GetValue()
    local maxHealth = select(2, statusBar:GetMinMaxValues())
	
    -- Status bar text
    if not _c.showUnitHealth or not data.unitExists then
        statusBar.healthText:SetText( nil ) -- prevent text snapshotting
    elseif currHealth <= 0 or data.unitIsDead then
        statusBar.healthText:SetText( DEAD )
    elseif (_p.isClassic or _p.isClassic_TBC) and not shouldKnowUnitHealth(data) then
        statusBar.healthText:SetText( math.ceil(currHealth/maxHealth * 100) .. '%' ) -- the same rounding as in the game
    else
        statusBar.healthText:SetText( AbbreviateLargeNumbers(currHealth) .. ' / ' .. AbbreviateLargeNumbers(maxHealth) )
    end

    -- Status bar color
    if _c.enableClassColor and data.unitExists and data.unitIsPlayer then
        statusBar:SetStatusBarColor( data.unitClassColor.r, data.unitClassColor.g, data.unitClassColor.b )
    else
        statusBar:SetStatusBarColor( 0, 1, 0 )
    end
end

-- This script is called before and after OnTooltipSetUnit script (twice)
local function onValueChanged(self)
    updateStatusBar(self, db)
end

-- This script is called after OnValueChanged script
local function onTooltipSetUnit(self)
    -- Hold LMB or RMB but do not rotate the camera, just move your character
    -- The cursor should not disappear from the screen at this moment, it will follow the movement of your character
    -- Thus, as long as the cursor is following your character's movement, GetUnit() will always return nil
    if IsMouseButtonDown('LeftButton') or IsMouseButtonDown('RightButton') then
        return self:Hide() -- fix the issue
    end

    local unit = fixGetUnit(self)

    -- Prevent incorrect results in updateStatusBar() due to OnValueChanged script
    -- Because OnValueChanged script is called before and after OnTooltipSetUnit script (twice)
    db.unitExists = unit

    if unit then
        -- Collect data about current unit and then (re)use it
        db.unitType = UnitGUID(unit):match('^(.-)%-'):lower()
        db.unitIsPlayer = db.unitType == 'player'
        db.unitIsPet = db.unitType == 'pet'
		db.unitIsDead = UnitIsDeadOrGhost(unit)
        db.unitIsMine = UnitIsUnit(unit, 'player') or UnitIsUnit(unit, 'pet') -- me or my pet
        db.unitInGroup = UnitPlayerOrPetInRaid(unit) or UnitPlayerOrPetInParty(unit)
        db.unitFaction = select(2, UnitFactionGroup(unit))
        db.unitReactionColor = { GameTooltip_UnitColor(unit) } -- { r, g, b }
        db.unitGuildInfo = db.unitIsPlayer and { GetGuildInfo(unit) } -- { name, rankName, rankIndex, realmName }
        db.unitClassColor = db.unitIsPlayer and RAID_CLASS_COLORS[ select(2, UnitClass(unit)) ]

        -- Due to the issue with fixGetUnit(), name line is outside UnitIsPlayer() condition
        -- Because these units (player clones) are of the "creature" type, not the "player" type
        if not _p.isClassic and _c.hideUnitTitle then
            -- In the Classic version there are only Rank 1-14 PvP titles
            -- There is no need to hide these titles because they might be useful
            _G[self:GetName() .. 'TextLeft1']:SetText( GetUnitName(unit, true) ) -- no title
        end

        addMissingLines(self, db)
        colorizeLines(self, db)
    end
	
	-- Update status bar AFTER updating the unit
	updateStatusBar(GameTooltipStatusBar, db)
	
end

GameTooltipStatusBar.healthText = GameTooltipStatusBar:CreateFontString(nil, 'OVERLAY')
GameTooltipStatusBar.healthText:SetFont(STANDARD_TEXT_FONT, _c.healthFontSize, 'OUTLINE')
GameTooltipStatusBar.healthText:SetPoint('CENTER')

GameTooltip:HookScript('OnTooltipSetUnit', onTooltipSetUnit)
GameTooltipStatusBar:HookScript('OnValueChanged', onValueChanged)