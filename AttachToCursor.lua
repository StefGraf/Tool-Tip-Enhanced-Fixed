--[[
    https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/GameTooltip.lua#L159-L162
]]

local _, addonTable = ...
local _c = addonTable.config

local function setDefaultAnchor(self, parent)
    self:SetOwner(parent, 'ANCHOR_NONE')
    self:ClearAllPoints()

    if _c.useCustomPosition then
        self:SetPoint(_c.point, _c.relativeFrame, _c.relativePoint, _c.offsetX, _c.offsetY)
    else
        self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y)
    end

    -- In this case, SetOwner() must be below SetPoint()
    if _c.attachToCursor
        and ( ( _c.attachToCursorAlt and GetMouseFocus() == WorldFrame ) or not _c.attachToCursorAlt )
        and ( ( _c.detachInCombat and not InCombatLockdown() ) or not _c.detachInCombat ) then

        self:SetOwner(parent, _c.showUnitHealth and 'ANCHOR_CURSOR_LEFT' or 'ANCHOR_CURSOR')
    end

    -- This will flag the tooltip as having been anchored using the default anchor
    self.default = 1 -- deprecated but still exists in the classic version
end

hooksecurefunc('GameTooltip_SetDefaultAnchor', setDefaultAnchor)