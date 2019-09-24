local E, L, V, P, G = unpack(select(2, ...))
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

local _G = _G
local select, unpack, pairs, tonumber = select, unpack, pairs, tonumber
local format, find, gsub, match = string.format, string.find, string.gsub, string.match
local twipe = table.wipe

local CreateFrame = CreateFrame
local GetBattlefieldScore = GetBattlefieldScore
local GetNumBattlefieldScores = GetNumBattlefieldScores
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local SetCVar = SetCVar
local WorldFrame = WorldFrame
local WorldGetChildren = WorldFrame.GetChildren
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local numChildren, hasTarget = 0
local OVERLAY = [=[Interface\TargetingFrame\UI-TargetingFrame-Flash]=]
local FSPAT = "%s*"..(gsub(gsub(_G.FOREIGN_SERVER_LABEL, "^%s", ""), "[%*()]", "%%%1")).."$"

local RaidIconCoordinate = {
	[0] = {[0] = "STAR", [0.25] = "MOON"},
	[0.25] = {[0] = "CIRCLE", [0.25] = "SQUARE"},
	[0.5] = {[0] = "DIAMOND", [0.25] = "CROSS"},
	[0.75] = {[0] = "TRIANGLE", [0.25] = "SKULL"}
}

NP.CreatedPlates = {}
NP.VisiblePlates = {}
NP.Healers = {}

NP.HealerSpecs = {
	[L["Restoration"]] = true,
	[L["Holy"]] = true,
	[L["Discipline"]] = true
}

function NP:CheckBGHealers()
	local name, _, talentSpec
	for i = 1, GetNumBattlefieldScores() do
		name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
		if name then
			name = match(name, "([^%-]+).*")
			if name and self.HealerSpecs[talentSpec] then
				self.Healers[name] = talentSpec
			elseif name and self.Healers[name] then
				self.Healers[name] = nil
			end
		end
	end
end

function NP:SetFrameScale(frame, scale)
	if frame.HealthBar.currentScale ~= scale then
		if frame.HealthBar.scale:IsPlaying() then
			frame.HealthBar.scale:Stop()
			frame.CastBar.Icon.scale:Stop()
		end

		frame.HealthBar.scale.width:SetChange(self.db.units[frame.UnitType].healthbar.width * scale)
		frame.HealthBar.scale.height:SetChange(self.db.units[frame.UnitType].healthbar.height * scale)
		frame.HealthBar.scale:Play()
		frame.HealthBar.currentScale = scale

		local endScale = self.db.units[frame.UnitType].healthbar.height * scale + self.db.units[frame.UnitType].castbar.height + self.db.units[frame.UnitType].castbar.offset
		frame.CastBar.Icon.scale.width:SetChange(endScale)
		frame.CastBar.Icon.scale:Play()
		frame.CastBar.Icon.currentScale = scale
	end
end

function NP:GetPlateFrameLevel(frame)
	local plateLevel
	if frame.plateID then
		plateLevel = frame.plateID*NP.levelStep
	end

	return plateLevel
end

function NP:SetPlateFrameLevel(frame, level, isTarget)
	if frame and level then
		if isTarget then
			level = 890 --10 higher than the max calculated level of 880
		elseif frame.FrameLevelChanged then
			--calculate Style Filter FrameLevelChanged leveling
			--level method: (10*(40*2)) max 800 + max 80 (40*2) = max 880
			--highest possible should be level 880 and we add 1 to all so 881
			local leveledCount = NP.CollectedFrameLevelCount or 1
			level = (frame.FrameLevelChanged * (40 * NP.levelStep)) + (leveledCount * NP.levelStep)
		end

		frame:SetFrameLevel(level + 1)
		frame.Glow:SetFrameLevel(frame:GetFrameLevel() - 1)
		frame.Buffs:SetFrameLevel(level + 1)
		frame.Debuffs:SetFrameLevel(level + 1)
	end
end

function NP:ResetNameplateFrameLevel(frame)
	local isTarget = frame.isTarget --frame.isTarget is not the same here so keep this.
	local plateLevel = NP:GetPlateFrameLevel(frame)
	if plateLevel then
		if frame.FrameLevelChanged then --keep how many plates we change, this is reset to 1 post-ResetNameplateFrameLevel
			NP.CollectedFrameLevelCount = (NP.CollectedFrameLevelCount and NP.CollectedFrameLevelCount + 1) or 1
		end
		NP:SetPlateFrameLevel(frame, plateLevel, isTarget)
	end
end

function NP:SetTargetFrame(frame)
	if frame.isTarget then
		if not frame.isTargetChanged then
			frame.isTargetChanged = true

			NP:SetPlateFrameLevel(frame, NP:GetPlateFrameLevel(frame), true)

			if NP.db.useTargetScale then
				NP:SetFrameScale(frame, (frame.ThreatScale or 1) * NP.db.targetScale)
			end

			frame.unit = "target"
			frame.guid = UnitGUID("target")

			NP:RegisterEvents(frame)
			NP:UpdateElement_AurasByUnitID("target")

			if NP.db.units[frame.UnitType].healthbar.enable ~= true and NP.db.alwaysShowTargetHealth then
				frame.Name:ClearAllPoints()
				frame.Level:ClearAllPoints()
				frame.HealthBar.r, frame.HealthBar.g, frame.HealthBar.b = nil, nil, nil

				NP:ConfigureElement_HealthBar(frame)
				NP:ConfigureElement_CastBar(frame)
				NP:ConfigureElement_Glow(frame)
				NP:ConfigureElement_Elite(frame)
				NP:ConfigureElement_Highlight(frame)
				NP:ConfigureElement_Level(frame)
				NP:ConfigureElement_Name(frame)
				NP:ConfigureElement_CPoints(frame)
				NP:RegisterEvents(frame)

				NP:UpdateElement_All(frame, true)
			end

			frame.CastBar.Icon:SetWidth((NP.db.units[frame.UnitType].castbar.height + NP.db.units[frame.UnitType].healthbar.height + NP.db.units[frame.UnitType].castbar.offset) * (frame.HealthBar.currentScale or 1))

			if hasTarget then
				frame:SetAlpha(1)
			end

			NP:UpdateElement_Highlight(frame)
			NP:UpdateElement_CPoints(frame)
			NP:UpdateElement_Filters(frame, "PLAYER_TARGET_CHANGED")

			NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `UpdateElement_Filters`
		end
	elseif frame.isTargetChanged then
		frame.isTargetChanged = false

		NP:SetPlateFrameLevel(frame, NP:GetPlateFrameLevel(frame))

		if NP.db.useTargetScale then
			NP:SetFrameScale(frame, (frame.ThreatScale or 1))
		end

		frame.unit = nil
		frame.guid = nil

		frame:UnregisterAllEvents()

		if NP.db.units[frame.UnitType].healthbar.enable ~= true then
			NP:UpdateAllFrame(frame)
		end

		if not frame.AlphaChanged then
			if hasTarget then
				frame:SetAlpha(NP.db.nonTargetTransparency)
			else
				frame:SetAlpha(1)
			end
		end

		NP:UpdateElement_Cast(frame)
		NP:UpdateElement_CPoints(frame)
		NP:UpdateElement_Filters(frame, "PLAYER_TARGET_CHANGED")

		NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `UpdateElement_Filters`
	elseif frame.oldHighlight:IsShown() then
		if not frame.isMouseover then
			frame.isMouseover = true

			frame.unit = "mouseover"
			frame.guid = UnitGUID("mouseover")

			NP:UpdateElement_AurasByUnitID("mouseover")
			NP:UpdateElement_Cast(frame, nil, frame.unit)
		end

		NP:UpdateElement_Highlight(frame)
	elseif frame.isMouseover then
		frame.isMouseover = nil

		frame.unit = nil
		frame.guid = nil

		NP:UpdateElement_Cast(frame)
		NP:UpdateElement_Highlight(frame)
	else
		if not frame.AlphaChanged then
			if hasTarget then
				frame:SetAlpha(NP.db.nonTargetTransparency)
			else
				frame:SetAlpha(1)
			end
		end

		NP:UpdateElement_Filters(frame, "UNIT_AURA")
	end

	NP:UpdateElement_Glow(frame)
	NP:UpdateElement_HealthColor(frame)
end

function NP:StyleFrame(parent, noBackdrop, point)
	point = point or parent
	local noscalemult = E.mult * UIParent:GetScale()

	if point.bordertop then return end

	if not noBackdrop then
		point.backdrop = parent:CreateTexture(nil, "BACKGROUND")
		point.backdrop:SetAllPoints(point)
		point.backdrop:SetTexture(unpack(E.media.backdropfadecolor))
	end

	if E.PixelMode then
		point.bordertop = parent:CreateTexture()
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom = parent:CreateTexture()
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderleft = parent:CreateTexture()
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderright = parent:CreateTexture()
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))
	else
		point.bordertop = parent:CreateTexture(nil, "OVERLAY")
		point.bordertop:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult, noscalemult*2)
		point.bordertop:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult, noscalemult*2)
		point.bordertop:SetHeight(noscalemult)
		point.bordertop:SetTexture(unpack(E.media.bordercolor))

		point.bordertop.backdrop = parent:CreateTexture()
		point.bordertop.backdrop:SetPoint("TOPLEFT", point.bordertop, "TOPLEFT", noscalemult, noscalemult)
		point.bordertop.backdrop:SetPoint("TOPRIGHT", point.bordertop, "TOPRIGHT", -noscalemult, noscalemult)
		point.bordertop.backdrop:SetHeight(noscalemult * 3)
		point.bordertop.backdrop:SetTexture(0, 0, 0)

		point.borderbottom = parent:CreateTexture(nil, "OVERLAY")
		point.borderbottom:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", -noscalemult, -noscalemult*2)
		point.borderbottom:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", noscalemult, -noscalemult*2)
		point.borderbottom:SetHeight(noscalemult)
		point.borderbottom:SetTexture(unpack(E.media.bordercolor))

		point.borderbottom.backdrop = parent:CreateTexture()
		point.borderbottom.backdrop:SetPoint("BOTTOMLEFT", point.borderbottom, "BOTTOMLEFT", noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetPoint("BOTTOMRIGHT", point.borderbottom, "BOTTOMRIGHT", -noscalemult, -noscalemult)
		point.borderbottom.backdrop:SetHeight(noscalemult * 3)
		point.borderbottom.backdrop:SetTexture(0, 0, 0)

		point.borderleft = parent:CreateTexture(nil, "OVERLAY")
		point.borderleft:SetPoint("TOPLEFT", point, "TOPLEFT", -noscalemult*2, noscalemult*2)
		point.borderleft:SetPoint("BOTTOMLEFT", point, "BOTTOMLEFT", noscalemult*2, -noscalemult*2)
		point.borderleft:SetWidth(noscalemult)
		point.borderleft:SetTexture(unpack(E.media.bordercolor))

		point.borderleft.backdrop = parent:CreateTexture()
		point.borderleft.backdrop:SetPoint("TOPLEFT", point.borderleft, "TOPLEFT", -noscalemult, noscalemult)
		point.borderleft.backdrop:SetPoint("BOTTOMLEFT", point.borderleft, "BOTTOMLEFT", -noscalemult, -noscalemult)
		point.borderleft.backdrop:SetWidth(noscalemult * 3)
		point.borderleft.backdrop:SetTexture(0, 0, 0)

		point.borderright = parent:CreateTexture(nil, "OVERLAY")
		point.borderright:SetPoint("TOPRIGHT", point, "TOPRIGHT", noscalemult*2, noscalemult*2)
		point.borderright:SetPoint("BOTTOMRIGHT", point, "BOTTOMRIGHT", -noscalemult*2, -noscalemult*2)
		point.borderright:SetWidth(noscalemult)
		point.borderright:SetTexture(unpack(E.media.bordercolor))

		point.borderright.backdrop = parent:CreateTexture()
		point.borderright.backdrop:SetPoint("TOPRIGHT", point.borderright, "TOPRIGHT", noscalemult, noscalemult)
		point.borderright.backdrop:SetPoint("BOTTOMRIGHT", point.borderright, "BOTTOMRIGHT", noscalemult, -noscalemult)
		point.borderright.backdrop:SetWidth(noscalemult * 3)
		point.borderright.backdrop:SetTexture(0, 0, 0)
	end
end

function NP:RoundColors(r, g, b)
	return floor(r * 100 + 0.5) / 100, floor(g * 100 + 0.5) / 100, floor(b * 100 + 0.5) / 100
end

function NP:UnitClass(frame, unitType)
	if unitType == "FRIENDLY_PLAYER" then
		if UnitInParty("player") or UnitInRaid("player") then -- FRIENDLY_PLAYER
			local _, class = UnitClass(frame.UnitName)
			if class then return class end
		end
	elseif unitType == "ENEMY_PLAYER" then
		local r, g, b = NP:RoundColors(frame.oldHealthBar:GetStatusBarColor())
		for class in pairs(RAID_CLASS_COLORS) do -- ENEMY_PLAYER
			if RAID_CLASS_COLORS[class].r == r and RAID_CLASS_COLORS[class].g == g and RAID_CLASS_COLORS[class].b == b then
				return class
			end
		end
	end
end

function NP:UnitDetailedThreatSituation(frame)
	if not frame.Threat:IsShown() then
		if frame.UnitType == "ENEMY_NPC" then
			local r, g = frame.oldName:GetTextColor()
			return (r > 0.5 and g < 0.5) and 0 or nil
		end
	else
		local r, g, b = frame.Threat:GetVertexColor()
		if r > 0 then
			if g > 0 then
				if b > 0 then return 1 end
				return 2
			end
			return 3
		end
	end

	return nil
end

function NP:UnitLevel(frame)
	local level, boss = frame.oldLevel:GetObjectType() == "FontString" and tonumber(frame.oldLevel:GetText()) or false, frame.BossIcon:IsShown()
	if boss or not level then
		return "??", 0.9, 0, 0
	else
		return level, frame.oldLevel:GetTextColor()
	end
end

function NP:GetUnitInfo(frame)
	local r, g, b = frame.oldHealthBar:GetStatusBarColor()

	if r < 0.01 then
		if b < 0.01 and g > 0.99 then
			return 5, "FRIENDLY_NPC"
		elseif b > 0.99 and g < 0.01 then
			return 5, "FRIENDLY_PLAYER"
		end
	elseif r > 0.99 then
		if b < 0.01 and g > 0.99 then
			return 4, "ENEMY_NPC"
		elseif b < 0.01 and g < 0.01 then
			return 2, "ENEMY_NPC"
		end
	elseif r > 0.5 and r < 0.6 then
		if g > 0.5 and g < 0.6 and b > 0.5 and b < 0.6 then
			return 1, "ENEMY_NPC"
		end
	end

	return 3, "ENEMY_PLAYER"
end

function NP:OnShow()
	NP.VisiblePlates[self.UnitFrame] = true

	self.UnitFrame.UnitName = gsub(self.UnitFrame.oldName:GetText(), FSPAT, "")
	local unitReaction, unitType = NP:GetUnitInfo(self.UnitFrame)
	self.UnitFrame.UnitType = unitType
	self.UnitFrame.UnitClass = NP:UnitClass(self.UnitFrame, unitType)
	self.UnitFrame.UnitReaction = unitReaction

	if unitType == "ENEMY_PLAYER" then
		NP:UpdateElement_HealerIcon(self.UnitFrame)
	end

	self.UnitFrame.Level:ClearAllPoints()
	self.UnitFrame.Name:ClearAllPoints()

	self.UnitFrame.CutawayHealth:Hide()

	if NP.db.units[unitType].healthbar.enable or NP.db.alwaysShowTargetHealth then
		NP:ConfigureElement_HealthBar(self.UnitFrame)
		NP:ConfigureElement_CastBar(self.UnitFrame)
		NP:ConfigureElement_Glow(self.UnitFrame)

		if NP.db.units[unitType].buffs.enable then
			self.UnitFrame.Buffs.db = NP.db.units[unitType].buffs
			NP:UpdateAuraIcons(self.UnitFrame.Buffs)
		end

		if NP.db.units[unitType].debuffs.enable then
			self.UnitFrame.Debuffs.db = NP.db.units[unitType].debuffs
			NP:UpdateAuraIcons(self.UnitFrame.Debuffs)
		end
	end

	NP:ConfigureElement_CPoints(self.UnitFrame)
	NP:ConfigureElement_Level(self.UnitFrame)
	NP:ConfigureElement_Name(self.UnitFrame)
	NP:ConfigureElement_Elite(self.UnitFrame)
	NP:ConfigureElement_Highlight(self.UnitFrame)

	NP:RegisterEvents(self.UnitFrame)
	NP:UpdateElement_All(self.UnitFrame, nil, true)

	self.UnitFrame:Show()

	NP:UpdateElement_Filters(self.UnitFrame, "NAME_PLATE_UNIT_ADDED")
	NP:ForEachVisiblePlate("ResetNameplateFrameLevel") --keep this after `UpdateElement_Filters`
end

function NP:OnHide()
	NP.VisiblePlates[self.UnitFrame] = nil

	self.UnitFrame.unit = nil

	NP:HideAuraIcons(self.UnitFrame.Buffs)
	NP:HideAuraIcons(self.UnitFrame.Debuffs)
	NP:StyleFilterClear(self.UnitFrame)

	if self.UnitFrame:IsEventRegistered("UNIT_SPELLCAST_INTERRUPTED") then
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_START")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
		self.UnitFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	end

	self.UnitFrame.Glow.r, self.UnitFrame.Glow.g, self.UnitFrame.Glow.b = nil, nil, nil
	self.UnitFrame.Glow:Hide()
	self.UnitFrame.Glow2:Hide()
	self.UnitFrame.TopArrow:Hide()
	self.UnitFrame.LeftArrow:Hide()
	self.UnitFrame.RightArrow:Hide()
	self.UnitFrame.HealthBar.r, self.UnitFrame.HealthBar.g, self.UnitFrame.HealthBar.b = nil, nil, nil
	self.UnitFrame.HealthBar:Hide()
	self.UnitFrame.HealthBar.currentScale = nil
	self.UnitFrame.oldCastBar:Hide()
	self.UnitFrame.CastBar:Hide()
	self.UnitFrame.CastBar.spellName = nil
	self.UnitFrame.Level:ClearAllPoints()
	self.UnitFrame.Level:SetText("")
	self.UnitFrame.Name.r, self.UnitFrame.Name.g, self.UnitFrame.Name.b = nil, nil, nil
	self.UnitFrame.Name:ClearAllPoints()
	self.UnitFrame.Name:SetText("")
	self.UnitFrame.Name.NameOnlyGlow:Hide()
	self.UnitFrame.Highlight:Hide()
	self.UnitFrame.Elite:Hide()
	self.UnitFrame.CPoints:Hide()
	self.UnitFrame:Hide()
	self.UnitFrame.isTarget = nil
	self.UnitFrame.isTargetChanged = false
	self.UnitFrame.isMouseover = nil
	self.UnitFrame.UnitName = nil
	self.UnitFrame.UnitType = nil
	self.UnitFrame.UnitClass = nil
	self.UnitFrame.UnitReaction = nil
	self.UnitFrame.TopLevelFrame = nil
	self.UnitFrame.TopOffset = nil
	self.UnitFrame.ThreatReaction = nil
	self.UnitFrame.guid = nil
	self.UnitFrame.RaidIconType = nil

	NP:StyleFilterClearVariables(self)
end

function NP:UpdateAllFrame(frame)
	NP.OnHide(frame:GetParent())
	NP.OnShow(frame:GetParent())
end

function NP:ConfigureAll()
	if E.private.nameplates.enable ~= true then return end

	NP:StyleFilterConfigure()
	NP:ForEachPlate("UpdateAllFrame")
	NP:UpdateCVars()
end

function NP:ForEachPlate(functionToRun, ...)
	for frame in pairs(self.CreatedPlates) do
		if frame and frame.UnitFrame then
			self[functionToRun](self, frame.UnitFrame, ...)
		end
	end

	if functionToRun == "ResetNameplateFrameLevel" then
		NP.CollectedFrameLevelCount = 1
	end
end

function NP:ForEachVisiblePlate(functionToRun, ...)
	for frame in pairs(self.VisiblePlates) do
		self[functionToRun](self, frame, ...)
	end
end

function NP:UpdateElement_All(frame, noTargetFrame, filterIgnore)
	local healthShown = (frame.UnitType and self.db.units[frame.UnitType].healthbar.enable) or (frame.isTarget and self.db.alwaysShowTargetHealth)

	if healthShown then
		NP:UpdateElement_Health(frame)
		NP:UpdateElement_HealthColor(frame)
		NP:UpdateElement_Cast(frame, nil, frame.unit)
		NP:UpdateElement_Auras(frame)
	end
	NP:UpdateElement_RaidIcon(frame)
	NP:UpdateElement_HealerIcon(frame)
	NP:UpdateElement_Name(frame)
	NP:UpdateElement_Level(frame)
	NP:UpdateElement_Elite(frame)
	NP:UpdateElement_Highlight(frame)

	if healthShown then
		NP:UpdateElement_Glow(frame)
	else
		-- make sure we hide the arrows and/or glow after disabling the healthbar
		if frame.TopArrow and frame.TopArrow:IsShown() then frame.TopArrow:Hide() end
		if frame.LeftArrow and frame.LeftArrow:IsShown() then frame.LeftArrow:Hide() end
		if frame.RightArrow and frame.RightArrow:IsShown() then frame.RightArrow:Hide() end
		if frame.Glow2 and frame.Glow2:IsShown() then frame.Glow2:Hide() end
		if frame.Glow and frame.Glow:IsShown() then frame.Glow:Hide() end
	end

	if not noTargetFrame then
		NP:SetTargetFrame(frame)
	end

	if not filterIgnore then
		NP:UpdateElement_Filters(frame, "UpdateElement_All")
	end
end

local plateID = 0
function NP:OnCreated(frame)
	plateID = plateID + 1
	local HealthBar, CastBar = frame:GetChildren()
	local Threat, Border, Highlight, Name, Level, BossIcon, RaidIcon, EliteIcon = frame:GetRegions()
	local _, CastBarBorder, CastBarShield, CastBarIcon = CastBar:GetRegions()

	frame.UnitFrame = CreateFrame("Frame", format("ElvUI_NamePlate%d", plateID), frame)
	frame.UnitFrame:Hide()
	frame.UnitFrame:SetAllPoints(frame)
	frame.UnitFrame:SetScript("OnEvent", self.OnEvent)
	frame.UnitFrame.plateID = plateID

	frame.UnitFrame.HealthBar = self:ConstructElement_HealthBar(frame.UnitFrame)
	frame.UnitFrame.CutawayHealth = self:ConstructElement_CutawayHealth(frame.UnitFrame)
	frame.UnitFrame.Level = self:ConstructElement_Level(frame.UnitFrame)
	frame.UnitFrame.Name = self:ConstructElement_Name(frame.UnitFrame)
	frame.UnitFrame.CastBar = self:ConstructElement_CastBar(frame.UnitFrame)
	frame.UnitFrame.Glow = self:ConstructElement_Glow(frame.UnitFrame)
	frame.UnitFrame.Elite = self:ConstructElement_Elite(frame.UnitFrame)
	frame.UnitFrame.Buffs = self:ConstructElement_Auras(frame.UnitFrame, "LEFT")
	frame.UnitFrame.Debuffs = self:ConstructElement_Auras(frame.UnitFrame, "RIGHT")
	frame.UnitFrame.HealerIcon = self:ConstructElement_HealerIcon(frame.UnitFrame)
	frame.UnitFrame.CPoints = self:ConstructElement_CPoints(frame.UnitFrame)
	frame.UnitFrame.Highlight = self:ConstructElement_Highlight(frame.UnitFrame)

	self:QueueObject(HealthBar)
	self:QueueObject(CastBar)
	self:QueueObject(Level)
	self:QueueObject(Name)
	self:QueueObject(Threat)
	self:QueueObject(Border)
	self:QueueObject(CastBarBorder)
	self:QueueObject(CastBarShield)
	self:QueueObject(Highlight)
	CastBarIcon:SetParent(E.HiddenFrame)
	BossIcon:SetAlpha(0)
	EliteIcon:SetAlpha(0)

	frame.UnitFrame.oldHealthBar = HealthBar
	frame.UnitFrame.oldCastBar = CastBar
	frame.UnitFrame.oldCastBar.Shield = CastBarShield
	frame.UnitFrame.oldCastBar.Icon = CastBarIcon
	frame.UnitFrame.oldName = Name
	frame.UnitFrame.oldHighlight = Highlight
	frame.UnitFrame.oldLevel = Level

	frame.UnitFrame.Threat = Threat
	RaidIcon:SetParent(frame.UnitFrame)
	frame.UnitFrame.RaidIcon = RaidIcon

	frame.UnitFrame.BossIcon = BossIcon
	frame.UnitFrame.EliteIcon = EliteIcon

	self.OnShow(frame)

	frame:HookScript("OnShow", self.OnShow)
	frame:HookScript("OnHide", self.OnHide)
	HealthBar:HookScript("OnValueChanged", self.UpdateElement_HealthOnValueChanged)

	self.CreatedPlates[frame] = true
	self.VisiblePlates[frame.UnitFrame] = true
end

function NP:OnEvent(event, unit, ...)
	if not unit and not self.unit then return end
	if self.unit ~= unit then return end

	NP:UpdateElement_Cast(self, event, unit, ...)
end

function NP:RegisterEvents(frame)
	if not frame.unit then return end

	if self.db.units[frame.UnitType].healthbar.enable or (frame.isTarget and self.db.alwaysShowTargetHealth) then
		if self.db.units[frame.UnitType].castbar.enable then
			frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
			frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
			frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
			frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
			frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
			frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
			frame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
			frame:RegisterEvent("UNIT_SPELLCAST_START")
			frame:RegisterEvent("UNIT_SPELLCAST_STOP")
			frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
		end

		NP.OnEvent(frame, nil, frame.unit)
	end
end

function NP:QueueObject(object)
	local objectType = object:GetObjectType()
	if objectType == "Texture" then
		object:SetTexture("")
		object:SetTexCoord(0, 0, 0, 0)
	elseif objectType == "FontString" then
		object:SetWidth(0.001)
	elseif objectType == "StatusBar" then
		object:SetStatusBarTexture("")
	end
	object:Hide()
end

local function findNewPlate(...)
	local argc = select("#", ...)
	if argc == numChildren then return end

	local frame, region
	for i = numChildren + 1, argc do
		frame = select(i, ...)
		if not NP.CreatedPlates[frame] then
			region = frame:GetRegions()
			if (frame:GetName() and frame:GetName():find("NamePlate%d")) and (region and region:GetObjectType() == "Texture" and region:GetTexture() == OVERLAY) then
				NP:OnCreated(frame)
			end
		end
	end

	numChildren = argc
end

function NP:OnUpdate()
	findNewPlate(WorldGetChildren(WorldFrame))

	for frame in pairs(NP.VisiblePlates) do
		if hasTarget then
			frame.alpha = frame:GetParent():GetAlpha()
			frame:GetParent():SetAlpha(1)
		else
			frame.alpha = 1
		end

		frame.isTarget = hasTarget and frame.alpha == 1
	end
end

function NP:CheckRaidIcon(frame)
	if frame.RaidIcon:IsShown() then
		local ux, uy = frame.RaidIcon:GetTexCoord()
		frame.RaidIconType = RaidIconCoordinate[ux][uy]
	else
		frame.RaidIconType = nil
	end
end

function NP:SearchNameplateByGUID(guid)
	for frame in pairs(self.VisiblePlates) do
		if frame and frame:IsShown() and frame.guid == guid then
			return frame
		end
	end
end

function NP:SearchNameplateByName(sourceName)
	if not sourceName then return end
	local SearchFor = strsplit("-", sourceName)
	for frame in pairs(self.VisiblePlates) do
		if frame and frame:IsShown() and frame.UnitName == SearchFor and RAID_CLASS_COLORS[frame.UnitClass] then
			return frame
		end
	end
end

function NP:SearchNameplateByIconName(raidIcon)
	for frame in pairs(self.VisiblePlates) do
		self:CheckRaidIcon(frame)
		if frame and frame:IsShown() and frame.RaidIcon:IsShown() and (frame.RaidIconType == raidIcon) then
			return frame
		end
	end
end

function NP:SearchForFrame(guid, raidIcon, name)
	local frame
	if guid then frame = self:SearchNameplateByGUID(guid) end
	if (not frame) and name then frame = self:SearchNameplateByName(name) end
	if (not frame) and raidIcon then frame = self:SearchNameplateByIconName(raidIcon) end

	return frame
end

function NP:UpdateCVars()
	SetCVar("ShowClassColorInNameplate", "1")
	SetCVar("showVKeyCastbar", "1")

	if self.db.motionType == "OVERLAP" then
		SetCVar("nameplateMotion", "0")
	elseif self.db.motionType == "STACKED" then
		SetCVar("nameplateMotion", "1")
	elseif self.db.motionType == "SPREADING" then
		SetCVar("nameplateMotion", "2")
	end
end

local function CopySettings(from, to)
	for setting, value in pairs(from) do
		if type(value) == "table" and to[setting] ~= nil then
			CopySettings(from[setting], to[setting])
		else
			if to[setting] ~= nil then
				to[setting] = from[setting]
			end
		end
	end
end

function NP:ResetSettings(unit)
	CopySettings(P.nameplates.units[unit], self.db.units[unit])
end

function NP:CopySettings(from, to)
	if from == to then return end

	CopySettings(self.db.units[from], self.db.units[to])
end

function NP:PLAYER_ENTERING_WORLD()
	self:CleanAuraLists()
	twipe(self.Healers)

	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "pvp") and self.db.units.ENEMY_PLAYER.markHealers then
		self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "CheckBGHealers")
	else
		self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
	end
end

function NP:PLAYER_TARGET_CHANGED()
	hasTarget = UnitExists("target") == 1
end

function NP:UNIT_AURA(_, unit)
	if unit == "target" then
		self:UpdateElement_AurasByUnitID("target")
	elseif unit == "focus" then
		self:UpdateElement_AurasByUnitID("focus")
	end
end

function NP:UNIT_COMBO_POINTS(_, unit)
	if unit == "player" or unit == "vehicle" then
		self:ForEachVisiblePlate("UpdateElement_CPoints")
	end
end

function NP:PLAYER_REGEN_DISABLED()
	if self.db.showFriendlyCombat == "TOGGLE_ON" then
		SetCVar("nameplateShowFriends", 1)
	elseif self.db.showFriendlyCombat == "TOGGLE_OFF" then
		SetCVar("nameplateShowFriends", 0)
	end

	if self.db.showEnemyCombat == "TOGGLE_ON" then
		SetCVar("nameplateShowEnemies", 1)
	elseif self.db.showEnemyCombat == "TOGGLE_OFF" then
		SetCVar("nameplateShowEnemies", 0)
	end

	NP:ForEachVisiblePlate("UpdateElement_Filters", "PLAYER_REGEN_DISABLED")
end

function NP:PLAYER_REGEN_ENABLED()
	self:CleanAuraLists()
	if self.db.showFriendlyCombat == "TOGGLE_ON" then
		SetCVar("nameplateShowFriends", 0)
	elseif self.db.showFriendlyCombat == "TOGGLE_OFF" then
		SetCVar("nameplateShowFriends", 1)
	end

	if self.db.showEnemyCombat == "TOGGLE_ON" then
		SetCVar("nameplateShowEnemies", 0)
	elseif self.db.showEnemyCombat == "TOGGLE_OFF" then
		SetCVar("nameplateShowEnemies", 1)
	end

	NP:ForEachVisiblePlate("UpdateElement_Filters", "PLAYER_REGEN_ENABLED")
end

function NP:UNIT_HEALTH()
	NP:ForEachVisiblePlate("UpdateElement_Filters", "UNIT_HEALTH")
end

function NP:UNIT_POWER()
	NP:ForEachVisiblePlate("UpdateElement_Filters", "UNIT_POWER")
end

function NP:SPELL_UPDATE_COOLDOWN(...)
	NP:ForEachVisiblePlate("UpdateElement_Filters", "SPELL_UPDATE_COOLDOWN")
end

function NP:UNIT_FACTION()
	self:ForEachVisiblePlate("UpdateAllFrame")
end

function NP:UpdateFonts(plate)
	if not plate then return end

	if plate.Buffs and plate.Buffs.db and plate.Buffs.db.numAuras then
		for i = 1, plate.Buffs.db.numAuras do
			if plate.Buffs.icons[i] and plate.Buffs.icons[i].timeLeft then
				plate.Buffs.icons[i].timeLeft:SetFont(LSM:Fetch("font", self.db.durationFont), self.db.durationFontSize, self.db.durationFontOutline)
			end
			if plate.Buffs.icons[i] and plate.Buffs.icons[i].count then
				plate.Buffs.icons[i].count:SetFont(LSM:Fetch("font", self.db.stackFont), self.db.stackFontSize, self.db.stackFontOutline)
			end
		end
	end

	if plate.Debuffs and plate.Debuffs.db and plate.Debuffs.db.numAuras then
		for i = 1, plate.Debuffs.db.numAuras do
			if plate.Debuffs.icons[i] and plate.Debuffs.icons[i].timeLeft then
				plate.Debuffs.icons[i].timeLeft:SetFont(LSM:Fetch("font", self.db.durationFont), self.db.durationFontSize, self.db.durationFontOutline)
			end
			if plate.Debuffs.icons[i] and plate.Debuffs.icons[i].count then
				plate.Debuffs.icons[i].count:SetFont(LSM:Fetch("font", self.db.stackFont), self.db.stackFontSize, self.db.stackFontOutline)
			end
		end
	end

	--update glow incase name font changes
	local healthShown = (plate.UnitType and self.db.units[plate.UnitType].healthbar.enable) or (plate.isTarget and self.db.alwaysShowTargetHealth)
	if healthShown then
		self:UpdateElement_Glow(plate)
	end
end

function NP:UpdatePlateFonts()
	self:ForEachPlate("UpdateFonts")
end

function NP:Initialize()
	self.db = E.db.nameplates

	if E.private.nameplates.enable ~= true then return end
	NP.Initialized = true

	--Add metatable to all our StyleFilters so they can grab default values if missing
	self:StyleFilterInitialize()

	--Populate `NP.StyleFilterEvents` with events Style Filters will be using and sort the filters based on priority.
	self:StyleFilterConfigure()

	self.levelStep = 2

	self:UpdateCVars()

	self.Frame = CreateFrame("Frame"):SetScript("OnUpdate", self.OnUpdate)

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_LOGOUT", NP.StyleFilterClearDefaults)
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UNIT_COMBO_POINTS")
	self:RegisterEvent("UNIT_FACTION")

	self:ScheduleRepeatingTimer("ForEachVisiblePlate", 0.1, "SetTargetFrame")
end

local function InitializeCallback()
	NP:Initialize()
end

E:RegisterModule(NP:GetName(), InitializeCallback)