local E, L, V, P, G = unpack(select(2, ...));
local DT = E:GetModule('DataTexts')

local format = string.format
local lastPanel
local displayString = '';

local function OnEvent(self, event, unit)
	if event == "UNIT_AURA" and unit ~= 'player' then return end
	lastPanel = self

	local expertise, offhandExpertise = GetExpertise();
	local speed, offhandSpeed = UnitAttackSpeed("player");
	local text;
	if( offhandSpeed ) then
		text = expertise.." / "..offhandExpertise;
	else
		text = expertise;
	end
	self.text:SetFormattedText(displayString, STAT_EXPERTISE..": ", text)
end

local function OnEnter(self)
	DT:SetupTooltip(self)

	local expertisePercent, offhandExpertisePercent = GetExpertisePercent();
	expertisePercent = format("%.2f", expertisePercent);
	offhandExpertisePercent = format("%.2f", offhandExpertisePercent);

	local expertisePercentDisplay;
	if (IsDualWielding()) then
		expertisePercentDisplay = expertisePercent.."% / "..offhandExpertisePercent.."%";
	else
		expertisePercentDisplay = expertisePercent.."%";
	end

	DT.tooltip:AddLine(format(CR_EXPERTISE_TOOLTIP, expertisePercentDisplay, GetCombatRating(CR_EXPERTISE), GetCombatRatingBonus(CR_EXPERTISE)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
	DT.tooltip:AddLine(" ");

	-- Dodge chance
	DT.tooltip:AddDoubleLine(STAT_TARGET_LEVEL, DODGE_CHANCE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	local playerLevel = UnitLevel("player");
	for i=0, 3 do
		local mainhandDodge, offhandDodge = GetEnemyDodgeChance(i);
		mainhandDodge = format("%.2f%%", mainhandDodge);
		offhandDodge = format("%.2f%%", offhandDodge);
		local level = playerLevel + i;
		if (i == 3) then
			level = level.." / |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t";
		end
		local dodgeDisplay;
		if (IsDualWielding() and mainhandDodge ~= offhandDodge) then
			dodgeDisplay = mainhandDodge.." / "..offhandDodge;
		else
			dodgeDisplay = mainhandDodge.."  ";
		end
		DT.tooltip:AddDoubleLine("      "..level, dodgeDisplay.."  ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end

	-- Parry chance
	DT.tooltip:AddLine(" ");
	DT.tooltip:AddDoubleLine(STAT_TARGET_LEVEL, PARRY_CHANCE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	local playerLevel = UnitLevel("player");
	for i=0, 3 do
		local mainhandParry, offhandParry = GetEnemyParryChance(i);
		mainhandParry = format("%.2f%%", mainhandParry);
		offhandParry = format("%.2f%%", offhandParry);
		local level = playerLevel + i;
		if (i == 3) then
			level = level.." / |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t";
		end
		local parryDisplay;
		if (IsDualWielding() and mainhandParry ~= offhandParry) then
			parryDisplay = mainhandParry.." / "..offhandParry;
		else
			parryDisplay = mainhandParry.."  ";
		end
		DT.tooltip:AddDoubleLine("      "..level, parryDisplay.."  ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end
	DT.tooltip:Show()
end

local function ValueColorUpdate(hex, r, g, b)
	displayString = string.join("", "%s", hex, "%s|r")

	if lastPanel ~= nil then
		OnEvent(lastPanel, 2000)
	end
end
E['valueColorUpdateFuncs'][ValueColorUpdate] = true

DT:RegisterDatatext('Expertise',{"UNIT_STATS", "UNIT_AURA", "FORGE_MASTER_ITEM_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE"}, OnEvent, nil, nil, OnEnter)
