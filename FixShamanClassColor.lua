--[[
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/SharedXML/ColorUtil.lua

    Convert RGB(%) to Hex:
    string.format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, text)
]]

local _, addonTable = ...
local _p = addonTable.projects

if not _p.isClassic then
    return -- ignore the code below
end

-- In the Classic version, the shaman class color was the same as that of the paladin (pink)
-- This color was changed from pink to blue in TBC
RAID_CLASS_COLORS['SHAMAN'] = CreateColor(0, 0.4392147064209, 0.86666476726532)
RAID_CLASS_COLORS['SHAMAN'].colorStr = RAID_CLASS_COLORS['SHAMAN']:GenerateHexColor() -- #006fdc