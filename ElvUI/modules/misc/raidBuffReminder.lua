﻿local E, L, V, P, G = unpack(select(2, ...));
local RB = E:NewModule('ReminderBuffs', 'AceEvent-3.0');
local LSM = LibStub('LibSharedMedia-3.0');

E.ReminderBuffs = RB;

RB.Spell1Buffs = {
	94160, -- 'Flask of Flowing Water',
	79470, -- 'Flask of the Draconic Mind',
	79471, -- 'Flask of the Winds',
	79472, -- 'Flask of Titanic Strength',
	79638, -- 'Flask of Enhancement-STR',
	79639, -- 'Flask of Enhancement-AGI',
	79640, -- 'Flask of Enhancement-INT',
	92679, -- 'Flask of Battle',
	79469, -- 'Flask of Steelskin',
	79481, -- 'Hit',
	79632, -- 'Haste',
	79477, -- 'Critical',
	79635, -- 'Mastery',
	79474, -- 'Expertise',
	79468, -- 'Spirit',
	79480, -- 'Armor',
	79631, -- 'Resistance+90',
};

RB.Spell2Buffs = {
	87545, -- 90 STR
	87546, -- 90 AGI
	87547, -- 90 INT
	87548, -- 90 SPI
	87549, -- 90 MAST
	87550, -- 90 HIT
	87551, -- 90 CRIT
	87552, -- 90 HASTE
	87554, -- 90 DODGE
	87555, -- 90 PARRY
	87635, -- 90 EXP
	87556, -- 60 STR
	87557, -- 60 AGI
	87558, -- 60 INT
	87559, -- 60 SPI
	87560, -- 60 MAST
	87561, -- 60 HIT
	87562, -- 60 CRIT
	87563, -- 60 HASTE
	87564, -- 60 DODGE
	87634, -- 60 EXP
	87554, -- Seafood Feast
};

RB.Spell3Buffs = {
	1126, -- Mark of the wild
	90363, -- Embrace of the Shale Spider
	20217, -- Greater Blessing of Kings
};

RB.Spell4Buffs = {
	469, -- Commanding
	6307, -- Blood Pact
	90364, -- Qiraji Fortitude
	72590, -- Drums of fortitude
	21562, -- Fortitude
};

RB.CasterSpell5Buffs = {
	61316, -- Dalaran Brilliance (6% SP)
	1459, -- Arcane Brilliance (6% SP)
};

RB.MeleeSpell5Buffs = {
	6673, -- Battle Shout
	57330, -- Horn of Winter
	93435, -- Roar of Courage
	8076, -- Strength of Earth
};

RB.CasterSpell6Buffs = {
	5675, -- Mana Spring Totem
	54424, -- Fel Intelligence
	19740, -- Blessing of Might
};

RB.MeleeSpell6Buffs = {
	19740, -- Blessing of Might
	30808, -- Unleashed Rage
	53138, -- Abom Might
	19506, -- Trushot
};

function RB:CheckFilterForActiveBuff(filter)
	local spellName, texture, name, duration, expirationTime;

	for _, spell in pairs(filter) do
		spellName = GetSpellInfo(spell);
		name, _, texture, _, _, duration, expirationTime = UnitAura('player', spellName);

		if(name) then
			return true, texture, duration, expirationTime;
		end
	end

	return false, texture, duration, expirationTime;
end

function RB:UpdateReminderTime(elapsed)
	self.expiration = self.expiration - elapsed;

	if(self.nextupdate > 0) then
		self.nextupdate = self.nextupdate - elapsed;

		return;
	end

	if(self.expiration <= 0) then
		self.timer:SetText('');
		self:SetScript('OnUpdate', nil);

		return;
	end

	local timervalue, formatid;
	timervalue, formatid, self.nextupdate = E:GetTimeInfo(self.expiration, 4);
	self.timer:SetFormattedText(('%s%s|r'):format(E.TimeColors[formatid], E.TimeFormats[formatid][1]), timervalue);
end

function RB:UpdateReminder(event, unit)
	if(event == 'UNIT_AURA' and unit ~= 'player') then
		return;
	end

	local frame = self.frame;

	if(E.Role == 'Caster') then
		self.Spell5Buffs = self.CasterSpell5Buffs;
		self.Spell6Buffs = self.CasterSpell6Buffs;
	else
		self.Spell5Buffs = self.MeleeSpell5Buffs;
		self.Spell6Buffs = self.MeleeSpell6Buffs;
	end

	for i = 1, 6 do
		local hasBuff, texture, duration, expirationTime = self:CheckFilterForActiveBuff(self['Spell'..i..'Buffs']);
		local button = frame[i];

		if(hasBuff) then
			button.expiration = expirationTime - GetTime();
			button.nextupdate = 0;
			button.t:SetTexture(texture);

			if(duration == 0.1 and expirationTime == 0.1) then
			--	button.t:SetAlpha(0.3);
				button:SetScript('OnUpdate', nil);
				button.timer:SetText(nil);
				CooldownFrame_SetTimer(button.cd, 0, 0, 0);
			else
				button.t:SetAlpha(1)
				CooldownFrame_SetTimer(button.cd, expirationTime - duration, duration, 1);
				button:SetScript('OnUpdate', self.UpdateReminderTime);
			end
		else
			CooldownFrame_SetTimer(button.cd, 0, 0, 0);
			button.t:SetAlpha(0.3);
			button:SetScript('OnUpdate', nil);
			button.timer:SetText(nil);
			button.t:SetTexture(self.DefaultIcons[i]);
		end
	end
end

function RB:CreateButton()
	local button = CreateFrame('Button', nil, ElvUI_ReminderBuffs);
	button:SetTemplate('Default');

	button.t = button:CreateTexture(nil, 'OVERLAY');
	button.t:SetTexCoord(unpack(E.TexCoords));
	button.t:SetInside();
	button.t:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark');

	button.cd = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate');
	button.cd:SetInside();
	button.cd.noOCC = true;
	button.cd.noCooldownCount = true;
	button.cd:SetReverse(true);

	button.timer = button.cd:CreateFontString(nil, 'OVERLAY');
	button.timer:SetPoint('CENTER');

	return button;
end

function RB:EnableRB()
	ElvUI_ReminderBuffs:Show()
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', 'UpdateReminder');
	self:RegisterEvent('UNIT_INVENTORY_CHANGED', 'UpdateReminder');
	self:RegisterEvent('UNIT_AURA', 'UpdateReminder');
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateReminder');
	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'UpdateReminder');
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateReminder');
	self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'UpdateReminder');
	self:RegisterEvent('CHARACTER_POINTS_CHANGED', 'UpdateReminder');
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateReminder');
	self:UpdateReminder();
end

function RB:DisableRB()
	ElvUI_ReminderBuffs:Hide()
	self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
	self:UnregisterEvent('UNIT_INVENTORY_CHANGED');
	self:UnregisterEvent('UNIT_AURA');
	self:UnregisterEvent('PLAYER_REGEN_ENABLED');
	self:UnregisterEvent('PLAYER_REGEN_DISABLED');
	self:UnregisterEvent('PLAYER_ENTERING_WORLD');
	self:UnregisterEvent('UPDATE_BONUS_ACTIONBAR');
	self:UnregisterEvent('CHARACTER_POINTS_CHANGED');
	self:UnregisterEvent('ZONE_CHANGED_NEW_AREA');
end

function RB:UpdateSettings(isCallback)
	local frame = self.frame;
	frame:Width(E.RBRWidth);

	for i = 1, 6 do
		local button = frame[i];
		button:ClearAllPoints();
		button:SetWidth(E.RBRWidth);
		button:SetHeight(E.RBRWidth);

		if(i == 1) then
			button:Point("TOP", ElvUI_ReminderBuffs, "TOP", 0, 0);
		else
			button:Point("TOP", frame[i - 1], "BOTTOM", 0, E.Border - E.Spacing);
		end

		if(i == 6) then
			button:Point('BOTTOM', ElvUI_ReminderBuffs, 'BOTTOM', 0, (E.PixelMode and 0 or 2));
		end

		if(E.db.general.reminder.durations) then
			button.cd:SetAlpha(1);
		else
			button.cd:SetAlpha(0);
		end

		button.cd:SetReverse(E.db.general.reminder.reverse);

		local font = LSM:Fetch("font", E.db.general.reminder.font);
		button.timer:FontTemplate(font, E.db.general.reminder.fontSize, E.db.general.reminder.fontOutline);
	end

	if(not isCallback) then
		if(E.db.general.reminder.enable) then
			RB:EnableRB();
		else
			RB:DisableRB();
		end
	end
end

function RB:UpdatePosition()
	Minimap:ClearAllPoints();
	ElvConfigToggle:ClearAllPoints();
	ElvUI_ReminderBuffs:ClearAllPoints();
	if(E.db.general.reminder.position == "LEFT") then
		Minimap:Point("TOPRIGHT", MMHolder, "TOPRIGHT", -2, -2);
		ElvConfigToggle:SetPoint("TOPRIGHT", LeftMiniPanel, "TOPLEFT", (E.PixelMode and 1 or -1), 0);
		ElvConfigToggle:SetPoint("BOTTOMRIGHT", LeftMiniPanel, "BOTTOMLEFT", (E.PixelMode and 1 or -1), 0);
		ElvUI_ReminderBuffs:SetPoint("TOPRIGHT", Minimap.backdrop, "TOPLEFT", (E.PixelMode and 1 or -1), 0);
		ElvUI_ReminderBuffs:SetPoint("BOTTOMRIGHT", Minimap.backdrop, "BOTTOMLEFT", (E.PixelMode and 1 or -1), 0);
	else
		Minimap:Point("TOPLEFT", MMHolder, "TOPLEFT", 2, -2);
		ElvConfigToggle:SetPoint("TOPLEFT", RightMiniPanel, "TOPRIGHT", (E.PixelMode and -1 or 1), 0);
		ElvConfigToggle:SetPoint("BOTTOMLEFT", RightMiniPanel, "BOTTOMRIGHT", (E.PixelMode and -1 or 1), 0);
		ElvUI_ReminderBuffs:SetPoint("TOPLEFT", Minimap.backdrop, "TOPRIGHT", (E.PixelMode and -1 or 1), 0);
		ElvUI_ReminderBuffs:SetPoint("BOTTOMLEFT", Minimap.backdrop, "BOTTOMRIGHT", (E.PixelMode and -1 or 1), 0);
	end
end

function RB:Initialize()
	self.db = E.db.general.reminder;

	self.DefaultIcons = {
		[1] = 'Interface\\Icons\\INV_PotionE_4',
		[2] = 'Interface\\Icons\\INV_Misc_Food_68',
		[3] = 'Interface\\Icons\\Spell_Nature_Regeneration',
		[4] = 'Interface\\Icons\\Spell_Holy_WordFortitude',
		[5] = 'Interface\\Icons\\Ability_Warrior_BattleShout',
		[6] = 'Interface\\Icons\\Spell_Holy_GreaterBlessingofKings'
	};

	local frame = CreateFrame('Frame', 'ElvUI_ReminderBuffs', Minimap);
	frame:SetTemplate('Default');
	frame:Width(E.RBRWidth);
	if(E.db.general.reminder.position == "LEFT") then
		frame:Point('TOPRIGHT', Minimap.backdrop, 'TOPLEFT', E.Border - E.Spacing*3, 0);
		frame:Point('BOTTOMRIGHT', Minimap.backdrop, 'BOTTOMLEFT', E.Border - E.Spacing*3, 0);
	else
		frame:Point('TOPLEFT', Minimap.backdrop, 'TOPRIGHT', -E.Border + E.Spacing*3, 0);
		frame:Point('BOTTOMLEFT', Minimap.backdrop, 'BOTTOMRIGHT', -E.Border + E.Spacing*3, 0);
	end
	self.frame = frame;

	for i = 1, 6 do
		frame[i] = self:CreateButton();
		frame[i]:SetID(i);
	end

	self:UpdateSettings();
end

E:RegisterInitialModule(RB:GetName());