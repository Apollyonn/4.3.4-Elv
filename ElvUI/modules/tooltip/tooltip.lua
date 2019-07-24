local E, L, V, P, G = unpack(select(2, ...))
local TT = E:GetModule("Tooltip")

local _G = _G
local unpack, tonumber, select, pairs = unpack, tonumber, select, pairs
local twipe, tinsert, tconcat = table.wipe, table.insert, table.concat
local floor = math.floor
local find, format, match = string.find, string.format, string.match

local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitGUID = UnitGUID
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local GetInventoryItemLink = GetInventoryItemLink
local GetInventorySlotInfo = GetInventorySlotInfo
local UnitExists = UnitExists
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local GetMouseFocus = GetMouseFocus
local UnitLevel = UnitLevel
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitName = UnitName
local GetGuildInfo = GetGuildInfo
local UnitPVPName = UnitPVPName
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitRace = UnitRace
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitReaction = UnitReaction
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitIsPVP = UnitIsPVP
local UnitHasVehicleUI = UnitHasVehicleUI
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitIsUnit = UnitIsUnit
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetItemCount = GetItemCount
local UnitAura = UnitAura
local SetTooltipMoney = SetTooltipMoney
local GameTooltip_ClearMoney = GameTooltip_ClearMoney
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local LOCALE = {
	AFK = AFK,
	DND = DND,
	BOSS = BOSS,
	ITEM_QUALITY3_DESC = ITEM_QUALITY3_DESC,
	ITEM_QUALITY3_DESC = ITEM_QUALITY3_DESC,
	PVP = PVP,
	FACTION_HORDE = FACTION_HORDE,
	FOREIGN_SERVER_LABEL = FOREIGN_SERVER_LABEL,
	ID = ID,
	TARGET = TARGET,
	DEAD = DEAD,
	FACTION_ALLIANCE = FACTION_ALLIANCE,
	NONE = NONE,
	ROLE = ROLE,
	HEALER = HEALER,
	TANK = TANK,

	-- Custom to find LEVEL string on tooltip
	LEVEL1 = TOOLTIP_UNIT_LEVEL:gsub("%s?%%s%s?%-?", ""),
	LEVEL2 = TOOLTIP_UNIT_LEVEL_CLASS:gsub("^%%2$s%s?(.-)%s?%%1$s", "%1"):gsub("^%-?г?о?%s?", ""):gsub("%s?%%s%s?%-?", "")
}

local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]
local S_ITEM_LEVEL = ITEM_LEVEL:gsub("%%d", "(%%d+)")
local targetList, inspectCache = {}, {}
local TAPPED_COLOR = {r = 0.6, g = 0.6, b = 0.6}
local AFK_LABEL = " |cffFFFFFF[|r|cffE7E716"..LOCALE.AFK.."|r|cffFFFFFF]|r"
local DND_LABEL = " |cffFFFFFF[|r|cffFF0000"..LOCALE.DND.."|r|cffFFFFFF]|r"
local keybindFrame

local classification = {
	worldboss = format("|cffAF5050 %s|r", LOCALE.BOSS),
	rareelite = format("|cffAF5050+ %s|r", LOCALE.ITEM_QUALITY3_DESC),
	elite = "|cffAF5050+|r",
	rare = format("|cffAF5050 %s|r", LOCALE.ITEM_QUALITY3_DESC)
}

local SlotName = {
	"Head",
	"Neck",
	"Shoulder",
	"Back",
	"Chest",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"Finger0",
	"Finger1",
	"Trinket0",
	"Trinket1",
	"MainHand",
	"SecondaryHand",
	"Ranged"
}

function TT:GameTooltip_SetDefaultAnchor(tt, parent)
	if E.private.tooltip.enable ~= true then return end
	if not self.db.visibility then return end

	if tt:GetAnchorType() ~= "ANCHOR_NONE" then return end
	if InCombatLockdown() and self.db.visibility.combat then
		local modifier = self.db.visibility.combatOverride
		if (not(
				(modifier == "SHIFT" and IsShiftKeyDown())
				or
				(modifier == "CTRL" and IsControlKeyDown())
				or
				(modifier == "ALT" and IsAltKeyDown())
		)) then
			tt:Hide()
			return
		end
	end

	local ownerName = tt:GetOwner() and tt:GetOwner().GetName and tt:GetOwner():GetName()
	if self.db.visibility.actionbars ~= "NONE" and ownerName and (strfind(ownerName, "ElvUI_Bar") or strfind(ownerName, "MultiBar") or strfind(ownerName, "ElvUI_StanceBar") or strfind(ownerName, "PetAction")) and not keybindFrame.active then
		local modifier = self.db.visibility.actionbars

		if modifier == "ALL" or not ((modifier == "SHIFT" and IsShiftKeyDown()) or (modifier == "CTRL" and IsControlKeyDown()) or (modifier == "ALT" and IsAltKeyDown())) then
			tt:Hide()
			return
		end
	end

	if GameTooltipStatusBar then
		if self.db.healthBar.statusPosition == "BOTTOM" then
			if GameTooltipStatusBar.anchoredToTop then
				GameTooltipStatusBar:ClearAllPoints()
				GameTooltipStatusBar:Point("TOPLEFT", GameTooltip, "BOTTOMLEFT", E.Border, -(E.Spacing * 3))
				GameTooltipStatusBar:Point("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -E.Border, -(E.Spacing * 3))
				GameTooltipStatusBar.text:Point("CENTER", GameTooltipStatusBar, 0, 0)
				GameTooltipStatusBar.anchoredToTop = nil
			end
		else
			if not GameTooltipStatusBar.anchoredToTop then
				GameTooltipStatusBar:ClearAllPoints()
				GameTooltipStatusBar:Point("BOTTOMLEFT", GameTooltip, "TOPLEFT", E.Border, (E.Spacing * 3))
				GameTooltipStatusBar:Point("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -E.Border, (E.Spacing * 3))
				GameTooltipStatusBar.text:Point("CENTER", GameTooltipStatusBar, 0, 3)
				GameTooltipStatusBar.anchoredToTop = true
			end
		end
	end

	if parent then
		if self.db.cursorAnchor then
			tt:SetOwner(parent, self.db.cursorAnchorType, self.db.cursorAnchorX, self.db.cursorAnchorY)
			return
		else
			tt:SetOwner(parent, "ANCHOR_NONE")
		end
	end

	local _, anchor = tt:GetPoint()
	if anchor == nil or (ElvUI_ContainerFrame and anchor == ElvUI_ContainerFrame) or anchor == RightChatPanel or anchor == TooltipMover or anchor == UIParent or anchor == E.UIParent then
		tt:ClearAllPoints()
		if not E:HasMoverBeenMoved("TooltipMover") then
			if ElvUI_ContainerFrame and ElvUI_ContainerFrame:IsShown() then
				tt:Point("BOTTOMRIGHT", ElvUI_ContainerFrame, "TOPRIGHT", 0, 18)
			elseif RightChatPanel:GetAlpha() == 1 and RightChatPanel:IsShown() then
				tt:Point("BOTTOMRIGHT", RightChatPanel, "TOPRIGHT", 0, 18)
			else
				tt:Point("BOTTOMRIGHT", RightChatPanel, "BOTTOMRIGHT", 0, 18)
			end
 		else
			local point = E:GetScreenQuadrant(TooltipMover)
			if point == "TOPLEFT" then
				tt:Point("TOPLEFT", TooltipMover, "BOTTOMLEFT", 1, -4)
			elseif point == "TOPRIGHT" then
				tt:Point("TOPRIGHT", TooltipMover, "BOTTOMRIGHT", -1, -4)
			elseif point == "BOTTOMLEFT" or point == "LEFT" then
				tt:Point("BOTTOMLEFT", TooltipMover, "TOPLEFT", 1, 18)
			else
				tt:Point("BOTTOMRIGHT", TooltipMover, "TOPRIGHT", -1, 18)
			end
 		end
	end
end

function TT:GetAvailableTooltip()
	for i = 1, #GameTooltip.shoppingTooltips do
		if not GameTooltip.shoppingTooltips[i]:IsShown() then
			return GameTooltip.shoppingTooltips[i]
		end
	end
end

function TT:ScanForItemLevel(itemLink)
	local tooltip = self:GetAvailableTooltip()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetHyperlink(itemLink)
	tooltip:Show()

	local itemLevel = 0
	for i = 2, tooltip:NumLines() do
		local text = _G[ tooltip:GetName() .."TextLeft"..i]:GetText()
		if text and text ~= "" then
			local value = tonumber(text:match(S_ITEM_LEVEL))
			if value then
				itemLevel = value
			end
		end
	end

	tooltip:Hide()
	return itemLevel
end

function TT:GetItemLvL(unit)
	local total, item = 0, 0
	for i = 1, #SlotName do
		local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo(("%sSlot"):format(SlotName[i])))
		if itemLink ~= nil then
			local itemLevel = self:ScanForItemLevel(itemLink)
			if itemLevel and itemLevel > 0 then
				item = item + 1
				total = total + itemLevel
			end
		end
	end

	if total < 1 or item < 15 then return end

	return floor(total / item)
end

function TT:RemoveTrashLines(tt)
	for i = 3, tt:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()

		if linetext == LOCALE.PVP or linetext == LOCALE.FACTION_ALLIANCE or linetext == LOCALE.FACTION_HORDE then
			tiptext:SetText(nil)
			tiptext:Hide()
		end
	end
end

function TT:GetLevelLine(tt, offset)
	for i = offset, tt:NumLines() do
		local tipLine = _G["GameTooltipTextLeft"..i]
		local tipText = tipLine and tipLine.GetText and tipLine:GetText()
		if tipText and (tipText:find(LOCALE.LEVEL1) or tipText:find(LOCALE.LEVEL2)) then
			return tipLine
		end
	end
end

local tree = {}
function TT:GetTalentSpec(unit, isInspect)
	local group = GetActiveTalentGroup(isInspect)
	local primaryTree = 1
	for i = 1, 3 do
		local _, _, _, _, pointsSpent = GetTalentTabInfo(i, isInspect, nil, group)
		tree[i] = pointsSpent
		if (tree[i] > tree[primaryTree]) then
			primaryTree = i
		end
	end

	local _, name, _, icon = GetTalentTabInfo(primaryTree, isInspect, nil, group)
	icon = icon and "|T"..icon..":12:12:0:0:64:64:5:59:5:59|t " or ""
	return name and icon..name
end

function TT:INSPECT_READY()
	local GUID = UnitGUID("mouseover")
	if self.lastGUID ~= GUID then return end

	local unit = "mouseover"
	if UnitExists(unit) then
		local itemLevel = self:GetItemLvL(unit)
		local talentName = self:GetTalentSpec(unit, 1)
		inspectCache[GUID] = {time = GetTime()}

		if talentName then
			inspectCache[GUID].talent = talentName
		end

		if itemLevel then
			inspectCache[GUID].itemLevel = itemLevel
		end

		GameTooltip:SetUnit(unit)
	end
	self:UnregisterEvent("INSPECT_READY")
end

function TT:ShowInspectInfo(tt, unit, level, r, g, b, numTries)
	local canInspect = CanInspect(unit)
	if not canInspect or level < 10 or numTries > 1 then return end

	local GUID = UnitGUID(unit)
	if GUID == E.myguid then
		tt:AddDoubleLine(L["Talent Specialization:"], self:GetTalentSpec(unit), nil, nil, nil, r, g, b)
		tt:AddDoubleLine(L["Item Level:"], self:GetItemLvL("player"), nil, nil, nil, 1, 1, 1)
	elseif inspectCache[GUID] then
		local talent = inspectCache[GUID].talent
		local itemLevel = inspectCache[GUID].itemLevel

		if ((GetTime() - inspectCache[GUID].time) > 900) or not talent or not itemLevel then
			inspectCache[GUID] = nil

			return self:ShowInspectInfo(tt, unit, level, r, g, b, numTries + 1)
		end

		tt:AddDoubleLine(L["Talent Specialization:"], talent, nil, nil, nil, r, g, b)
		tt:AddDoubleLine(L["Item Level:"], itemLevel, nil, nil, nil, 1, 1, 1)
	else
		if (not canInspect) or (InspectFrame and InspectFrame:IsShown()) then return end
		self.lastGUID = GUID
		NotifyInspect(unit)
		self:RegisterEvent("INSPECT_READY")
	end
end

function TT:GameTooltip_OnTooltipSetUnit(tt)
	local unit = select(2, tt:GetUnit())
	if (tt:GetOwner() ~= UIParent) and (self.db.visibility and self.db.visibility.unitFrames ~= "NONE") then
		local modifier = self.db.visibility.unitFrames

		if modifier == "ALL" or not ((modifier == "SHIFT" and IsShiftKeyDown()) or (modifier == "CTRL" and IsControlKeyDown()) or (modifier == "ALT" and IsAltKeyDown())) then
			tt:Hide()
			return
		end
	end

	if not unit then
		local GMF = GetMouseFocus()
		if GMF and GMF.GetAttribute and GMF:GetAttribute("unit") then
			unit = GMF:GetAttribute("unit")
		end

		if not unit or not UnitExists(unit) then return end
	end

	self:RemoveTrashLines(tt)
	local level = UnitLevel(unit)
	local isShiftKeyDown = IsShiftKeyDown()

	local color
	if UnitIsPlayer(unit) then
		local localeClass, class = UnitClass(unit)
		if not localeClass or not class then return end

		local name, realm = UnitName(unit)
		local guildName, guildRankName = GetGuildInfo(unit)
		local pvpName = UnitPVPName(unit)

		color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]

		if not color then
			color = RAID_CLASS_COLORS.PRIEST
		end

		if self.db.playerTitles and pvpName then
			name = pvpName
		end

		if realm and realm ~= "" then
			if isShiftKeyDown then
				name = name.."-"..realm
			else
				name = name..LOCALE.FOREIGN_SERVER_LABEL
			end
		end

		if UnitIsAFK(unit) then
			name = name..AFK_LABEL
		elseif UnitIsDND(unit) then
			name = name..DND_LABEL
		end

		GameTooltipTextLeft1:SetFormattedText("%s%s", E:RGBToHex(color.r, color.g, color.b), name)

		local lineOffset = 2
		if guildName then
			if self.db.guildRanks then
				GameTooltipTextLeft2:SetFormattedText("<|cff00ff10%s|r> [|cff00ff10%s|r]", guildName, guildRankName)
			else
				GameTooltipTextLeft2:SetFormattedText("<|cff00ff10%s|r>", guildName)
			end
			lineOffset = 3
		end

		local levelLine = self:GetLevelLine(tt, lineOffset)
		if levelLine then
			local diffColor = GetQuestDifficultyColor(level)
			local race = UnitRace(unit)
			levelLine:SetFormattedText("|cff%02x%02x%02x%s|r %s %s%s|r", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", race or "", E:RGBToHex(color.r, color.g, color.b), localeClass)
		end

		if E.db.tooltip.role then
			local r, g, b, role = 1, 1, 1, UnitGroupRolesAssigned(unit)
			local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
			if (numParty > 0 or numRaid > 0) and (UnitInParty(unit) or UnitInRaid(unit)) and (role ~= "NONE") then
				if role == "HEALER" then
					role, r, g, b = LOCALE.HEALER, 0, 1, 0.59
				elseif role == "TANK" then
					role, r, g, b = LOCALE.TANK, 0.16, 0.31, 0.61
				elseif role == "DAMAGER" then
					role, r, g, b = L["DPS"], 0.77, 0.12, 0.24
				end

				GameTooltip:AddDoubleLine(LOCALE.ROLE, role, nil, nil, nil, r, g, b)
			end
		end

		--High CPU usage, restricting it to shift key down only.
		if self.db.inspectInfo and isShiftKeyDown then
			twipe(tree)
			self:ShowInspectInfo(tt, unit, level, color.r, color.g, color.b, 0)
		end
	else
		if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
			color = TAPPED_COLOR
		else
			color = E.db.tooltip.useCustomFactionColors and E.db.tooltip.factionColors[UnitReaction(unit, "player")] or FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		end

		if not color then
			color = RAID_CLASS_COLORS.PRIEST
		end

		local levelLine = self:GetLevelLine(tt, 2)
		if levelLine then
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			local pvpFlag = ""
			local diffColor = GetQuestDifficultyColor(level)

			if UnitIsPVP(unit) then
				pvpFlag = format(" (%s)", LOCALE.PVP)
			end

			levelLine:SetFormattedText("|cff%02x%02x%02x%s|r%s %s%s", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", classification[creatureClassification] or "", creatureType or "", pvpFlag)
		end
	end

	local unitTarget = unit.."target"
	if self.db.targetInfo and unit ~= "player" and UnitExists(unitTarget) then
		local targetColor
		if UnitIsPlayer(unitTarget) and not UnitHasVehicleUI(unitTarget) then
			local _, class = UnitClass(unitTarget)
			targetColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		else
			local reaction = UnitReaction(unitTarget, "player") or 4
			targetColor = E.db.tooltip.useCustomFactionColors and E.db.tooltip.factionColors[reaction] or FACTION_BAR_COLORS[reaction]
		end

		GameTooltip:AddDoubleLine(format("%s:", LOCALE.TARGET), format("|cff%02x%02x%02x%s|r", targetColor.r * 255, targetColor.g * 255, targetColor.b * 255, UnitName(unitTarget)))
	end

	local numParty, numRaid = GetNumPartyMembers(), GetNumRaidMembers()
	if self.db.targetInfo and (numParty > 0 or numRaid > 0) then
		for i = 1, (numRaid > 0 and numRaid or numParty) do
			local groupUnit = (numRaid > 0 and "raid"..i or "party"..i)
			if (UnitIsUnit(groupUnit.."target", unit)) and (not UnitIsUnit(groupUnit,"player")) then
				local _, class = UnitClass(groupUnit)
				local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
				tinsert(targetList, format("%s%s", E:RGBToHex(color.r, color.g, color.b), UnitName(groupUnit)))
			end
		end
		local numList = #targetList
		if numList > 0 then
			GameTooltip:AddLine(format("%s (|cffffffff%d|r): %s", L["Targeted By:"], numList, tconcat(targetList, ", ")), nil, nil, nil, true)
			twipe(targetList)
		end
	end

	if color then
		GameTooltipStatusBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		GameTooltipStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
	end

	local textWidth = GameTooltipStatusBar.text:GetStringWidth()
	if textWidth then
		tt:SetMinimumWidth(textWidth)
	end
end

function TT:GameTooltipStatusBar_OnValueChanged(tt, value)
	if not value or not self.db.healthBar.text or not tt.text then return end

	local unit = select(2, tt:GetParent():GetUnit())
	if not unit then
		local GMF = GetMouseFocus()
		if GMF and GMF.GetAttribute and GMF:GetAttribute("unit") then
			unit = GMF:GetAttribute("unit")
		end
	end

	local _, max = tt:GetMinMaxValues()
	if value > 0 and max == 1 then
		tt.text:SetFormattedText("%d%%", floor(value * 100))
		tt:SetStatusBarColor(TAPPED_COLOR.r, TAPPED_COLOR.g, TAPPED_COLOR.b) --most effeciant?
	elseif value == 0 or (unit and UnitIsDeadOrGhost(unit)) then
		tt.text:SetText(LOCALE.DEAD)
	else
		tt.text:SetText(E:ShortValue(value).." / "..E:ShortValue(max))
	end
end

function TT:GameTooltip_OnTooltipCleared(tt)
	tt.itemCleared = nil
end

function TT:GameTooltip_OnTooltipSetItem(tt)
	local ownerName = tt:GetOwner() and tt:GetOwner().GetName and tt:GetOwner():GetName()
	if self.db.visibility and self.db.visibility.bags ~= "NONE" and ownerName and (find(ownerName, "ElvUI_Container") or find(ownerName, "ElvUI_BankContainer")) then
		local modifier = self.db.visibility.bags

		if modifier == "ALL" or not ((modifier == "SHIFT" and IsShiftKeyDown()) or (modifier == "CTRL" and IsControlKeyDown()) or (modifier == "ALT" and IsAltKeyDown())) then
			tt.itemCleared = true
			tt:Hide()
			return
		end
	end

	if not tt.itemCleared then
		local _, link = tt:GetItem()
		local num = GetItemCount(link)
		local numall = GetItemCount(link, true)
		local left = " "
		local right = " "
		local bankCount = " "

		if link ~= nil and self.db.spellID then
			local id = tonumber(match(link, ":(%w+)"))
			left = (("|cFFCA3C3C%s|r %s"):format(LOCALE.ID, id))
		end

		if self.db.itemCount == "BAGS_ONLY" then
			right = ("|cFFCA3C3C%s|r %d"):format(L["Count"], num)
		elseif self.db.itemCount == "BANK_ONLY" then
			bankCount = ("|cFFCA3C3C%s|r %d"):format(L["Bank"], (numall - num))
		elseif self.db.itemCount == "BOTH" then
			right = ("|cFFCA3C3C%s|r %d"):format(L["Count"], num)
			bankCount = ("|cFFCA3C3C%s|r %d"):format(L["Bank"], (numall - num))
		end

		if left ~= " " or right ~= " " then
			tt:AddLine(" ")
			tt:AddDoubleLine(left, right)
		end

		if bankCount ~= " " then
			tt:AddDoubleLine(" ", bankCount)
		end

		tt.itemCleared = true
	end
end

function TT:GameTooltip_ShowStatusBar(tt)
	local statusBar = _G[tt:GetName().."StatusBar"..tt.shownStatusBars]

	if statusBar and not statusBar.skinned then
		statusBar:StripTextures()
		statusBar:SetStatusBarTexture(E.media.normTex)
		E:RegisterStatusBar(statusBar)
		statusBar:CreateBackdrop("Default")

		statusBar.skinned = true
	end
end

function TT:CheckBackdropColor()
	if not GameTooltip:IsShown() then return end

	local r, g, b = GameTooltip:GetBackdropColor()
	if r and g and b then
		r = E:Round(r, 1)
		g = E:Round(g, 1)
		b = E:Round(b, 1)
		local red, green, blue = unpack(E.media.backdropfadecolor)
		if r ~= red or g ~= green or b ~= blue then
			GameTooltip:SetBackdropColor(red, green, blue, self.db.colorAlpha)
		end
	end
end

function TT:SetStyle(tt)
	if not tt then return end

	tt:SetTemplate("Transparent", nil, true) --ignore updates

	local r, g, b = tt:GetBackdropColor()
	tt:SetBackdropColor(r, g, b, self.db.colorAlpha)
end

function TT:MODIFIER_STATE_CHANGED(_, key)
	if (key == "LSHIFT" or key == "RSHIFT") and UnitExists("mouseover") then
		GameTooltip:SetUnit("mouseover")
	end
end

function TT:SetUnitAura(tt, ...)
	local _, _, _, _, _, _, _, caster, _, _, id = UnitAura(...)
	if id and self.db.spellID then
		if caster then
			local name = UnitName(caster)
			local _, class = UnitClass(caster)
			local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
			if not color then color = RAID_CLASS_COLORS.PRIEST end
			tt:AddDoubleLine(("|cFFCA3C3C%s|r %d"):format(LOCALE.ID, id), format("%s%s", E:RGBToHex(color.r, color.g, color.b), name))
		else
			tt:AddLine(("|cFFCA3C3C%s|r %d"):format(LOCALE.ID, id))
		end

		tt:Show()
	end
end

function TT:GameTooltip_OnTooltipSetSpell(tt)
	local id = select(3, tt:GetSpell())
	if not id or not self.db.spellID then return end

	local displayString = ("|cFFCA3C3C%s|r %d"):format(LOCALE.ID, id)
	local lines = tt:NumLines()
	local isFound
	for i = 1, lines do
		local line = _G[("GameTooltipTextLeft%d"):format(i)]
		if line and line:GetText() and line:GetText():find(displayString) then
			isFound = true
			break
		end
	end

	if not isFound then
		tt:AddLine(displayString)
		tt:Show()
	end
end

function TT:SetItemRef(link)
	if self.db.spellID and (find(link, "^spell:") or find(link, "^item:")) then
		local id = tonumber(match(link, "(%d+)"))
		ItemRefTooltip:AddLine(format("|cFFCA3C3C%s|r %d", LOCALE.ID, id))
		ItemRefTooltip:Show()
	end
end

function TT:RepositionBNET(frame, _, anchor)
	if anchor ~= BNETMover then
		frame:ClearAllPoints()
		frame:SetPoint(BNETMover.anchorPoint or "TOPLEFT", BNETMover, BNETMover.anchorPoint or "TOPLEFT")
	end
end

function TT:SetTooltipFonts()
	local font = E.Libs.LSM:Fetch("font", E.db.tooltip.font)
	local fontOutline = E.db.tooltip.fontOutline
	local headerSize = E.db.tooltip.headerFontSize
	local textSize = E.db.tooltip.textFontSize
	local smallTextSize = E.db.tooltip.smallTextFontSize

	GameTooltipHeaderText:SetFont(font, headerSize, fontOutline)
	GameTooltipText:SetFont(font, textSize, fontOutline)
	GameTooltipTextSmall:SetFont(font, smallTextSize, fontOutline)
	if GameTooltip.hasMoney then
		for i = 1, GameTooltip.numMoneyFrames do
			_G["GameTooltipMoneyFrame"..i.."PrefixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SuffixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."GoldButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SilverButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."CopperButtonText"]:SetFont(font, textSize, fontOutline)
		end
	end

	--These show when you compare items ("Currently Equipped", name of item, item level)
	--Since they appear at the top of the tooltip, we set it to use the header font size.
	ShoppingTooltip1TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight4:SetFont(font, headerSize, fontOutline)
end

--This changes the growth direction of the toast frame depending on position of the mover
local function PostBNToastMove(mover)
	local x, y = mover:GetCenter()
	local screenHeight = E.UIParent:GetTop()
	local screenWidth = E.UIParent:GetRight()

	local anchorPoint
	if y > (screenHeight / 2) then
		anchorPoint = (x > (screenWidth/2)) and "TOPRIGHT" or "TOPLEFT"
	else
		anchorPoint = (x > (screenWidth/2)) and "BOTTOMRIGHT" or "BOTTOMLEFT"
	end
	mover.anchorPoint = anchorPoint

	BNToastFrame:ClearAllPoints()
	BNToastFrame:Point(anchorPoint, mover)
end

function TT:Initialize()
	self.db = E.db.tooltip

	BNToastFrame:Point("TOPRIGHT", MMHolder, "BOTTOMRIGHT", 0, -10)
	E:CreateMover(BNToastFrame, "BNETMover", L["BNet Frame"], nil, nil, PostBNToastMove)
	self:SecureHook(BNToastFrame, "SetPoint", "RepositionBNET")

	if E.private.tooltip.enable ~= true then return end
	self.Initialized = true

	GameTooltipStatusBar:Height(self.db.healthBar.height)
	GameTooltipStatusBar:SetScript("OnValueChanged", nil) -- Do we need to unset this?
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY")
	GameTooltipStatusBar.text:Point("CENTER", GameTooltipStatusBar, 0, -3)
	GameTooltipStatusBar.text:FontTemplate(E.Libs.LSM:Fetch("font", self.db.healthBar.font), self.db.healthBar.fontSize, self.db.healthBar.fontOutline)

	--Tooltip Fonts
	if not GameTooltip.hasMoney then
		--Force creation of the money lines, so we can set font for it
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		GameTooltip_ClearMoney(GameTooltip)
	end
	self:SetTooltipFonts()

	local GameTooltipAnchor = CreateFrame("Frame", "GameTooltipAnchor", E.UIParent)
	GameTooltipAnchor:Point("BOTTOMRIGHT", RightChatToggleButton, "BOTTOMRIGHT")
	GameTooltipAnchor:Size(130, 20)
	GameTooltipAnchor:SetFrameLevel(GameTooltipAnchor:GetFrameLevel() + 50)
	E:CreateMover(GameTooltipAnchor, "TooltipMover", L["Tooltip"], nil, nil, nil, nil, nil, "tooltip,general")

	self:SecureHook("GameTooltip_SetDefaultAnchor")
	self:SecureHook("SetItemRef")
	self:SecureHook(GameTooltip, "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitBuff", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitDebuff", "SetUnitAura")
	self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "GameTooltip_OnTooltipSetSpell")
	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "GameTooltip_OnTooltipCleared")
	self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "GameTooltip_OnTooltipSetItem")
	self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "GameTooltip_OnTooltipSetUnit")
	self:SecureHookScript(GameTooltipStatusBar, "OnValueChanged", "GameTooltipStatusBar_OnValueChanged")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")

	--Variable is localized at top of file, then set here when we're sure the frame has been created
	--Used to check if keybinding is active, if so then don't hide tooltips on actionbars
	keybindFrame = ElvUI_KeyBinder
end

local function InitializeCallback()
	TT:Initialize()
end

E:RegisterModule(TT:GetName(), InitializeCallback)