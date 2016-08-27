local E, L, V, P, G = unpack(select(2, ...));
local A = E:NewModule('Auras', 'AceHook-3.0', 'AceEvent-3.0');
local LSM = LibStub('LibSharedMedia-3.0');

local GetTime = GetTime;
local select, unpack, tonumber, pairs, ipairs = select, unpack, tonumber, pairs, ipairs;
local floor, min, max = math.floor, math.min, math.max;
local format, join, wipe, tinsert = string.format, string.join, table.wipe, table.insert;

local CreateFrame = CreateFrame;
local UnitAura = UnitAura;

local DIRECTION_TO_POINT = {
	DOWN_RIGHT = 'TOPLEFT',
	DOWN_LEFT = 'TOPRIGHT',
	UP_RIGHT = 'BOTTOMLEFT',
	UP_LEFT = 'BOTTOMRIGHT',
	RIGHT_DOWN = 'TOPLEFT',
	RIGHT_UP = 'BOTTOMLEFT',
	LEFT_DOWN = 'TOPRIGHT',
	LEFT_UP = 'BOTTOMRIGHT'
};

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = 1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = -1,
	RIGHT_DOWN = 1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = -1
};

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = -1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = 1,
	RIGHT_DOWN = -1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = 1
};

local IS_HORIZONTAL_GROWTH = {
	RIGHT_DOWN = true,
	RIGHT_UP = true,
	LEFT_DOWN = true,
	LEFT_UP = true
};

local sortingTable = {};
local groupingTable = {};

function A:UpdateTime(elapsed)
	self.timeLeft = self.timeLeft - elapsed;
	
	if(self.nextUpdate > 0) then
		self.nextUpdate = self.nextUpdate - elapsed;
		return;
	end
	
	local timerValue, formatID;
	timerValue, formatID, self.nextUpdate = E:GetTimeInfo(self.timeLeft, A.db.fadeThreshold);
	self.time:SetFormattedText(('%s%s|r'):format(E.TimeColors[formatID], E.TimeFormats[formatID][1]), timerValue);
	
	if(self.timeLeft > E.db.auras.fadeThreshold) then
		E:StopFlash(self);
	else
		E:Flash(self, 1);
	end
end

local UpdateTooltip = function(self)
	GameTooltip:SetUnitAura(self:GetParent().unit, self:GetID(), self:GetParent().filter);
end

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT', -5, -5);
	self:UpdateTooltip();
end

local OnLeave = function()
	GameTooltip:Hide();
end

local OnClick = function(self)
	CancelUnitBuff(self:GetParent().unit, self:GetID(), self:GetParent().filter);
end

function A:CreateIcon(button)
	local font = LSM:Fetch('font', self.db.font);
	button:RegisterForClicks('RightButtonUp');
	button:SetTemplate('Default');
	
	button.texture = button:CreateTexture(nil, 'BORDER');
	button.texture:SetInside();
	button.texture:SetTexCoord(unpack(E.TexCoords));
	
	button.count = button:CreateFontString(nil, 'ARTWORK');
	button.count:SetPoint('BOTTOMRIGHT', -1 + self.db.countXOffset, 1 + self.db.countYOffset);
	button.count:FontTemplate(font, self.db.fontSize, self.db.fontOutline);
	
	button.time = button:CreateFontString(nil, 'ARTWORK');
	button.time:SetPoint('TOP', button, 'BOTTOM', 1 + self.db.timeXOffset, 0 + self.db.timeYOffset);
	button.time:FontTemplate(font, self.db.fontSize, self.db.fontOutline);
	
	button.highlight = button:CreateTexture(nil, 'HIGHLIGHT');
	button.highlight:SetTexture(1, 1, 1, 0.45);
	button.highlight:SetInside();
	
	E:SetUpAnimGroup(button);
	
	button.UpdateTooltip = UpdateTooltip;
	button:SetScript('OnEnter', OnEnter);
	button:SetScript('OnLeave', OnLeave);
	button:SetScript('OnClick', OnClick);
end

local buttons = {};
local function configureAuras(header, auraTable)
	local db = A.db.debuffs;
	if(header.filter == 'HELPFUL') then
		db = A.db.buffs;
	end
	
	local size = db.size;
	local point = DIRECTION_TO_POINT[db.growthDirection];
	local xOffset = 0;
	local yOffset = 0;
	local wrapXOffset = 0;
	local wrapYOffset = 0;
	local wrapAfter = db.wrapAfter;
	local maxWraps = db.maxWraps;
	local minWidth = 0;
	local minHeight = 0;
	
	if(IS_HORIZONTAL_GROWTH[db.growthDirection]) then
		minWidth = ((wrapAfter == 1 and 0 or db.horizontalSpacing) + size) * wrapAfter;
		minHeight = (db.verticalSpacing + size) * maxWraps;
		xOffset = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[db.growthDirection] * (db.horizontalSpacing + size);
		yOffset = 0;
		wrapXOffset = 0;
		wrapYOffset = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[db.growthDirection] * (db.verticalSpacing + size);
	else
		minWidth = (db.horizontalSpacing + size) * maxWraps;
		minHeight = ((wrapAfter == 1 and 0 or db.verticalSpacing) + size) * wrapAfter;
		xOffset = 0;
		yOffset = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[db.growthDirection] * (db.verticalSpacing + size);
		wrapXOffset = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[db.growthDirection] * (db.horizontalSpacing + size);
		wrapYOffset = 0;
	end
	
	local name = header:GetName();
	
	wipe(buttons);
	for i=1, #auraTable do
		local button = select(i, header:GetChildren());
		if(button) then
			button:ClearAllPoints();
		else
			button = CreateFrame('Button', name and name..'AuraButton'..i, header);
			A:CreateIcon(button);
		end
		local buffInfo = auraTable[i];
		button:SetID(buffInfo.index);
		button.index = buffInfo.index;
		button.filter = buffInfo.filter;
		
		if(buffInfo.duration > 0 and buffInfo.expires) then
			local timeLeft = buffInfo.expires - GetTime();
			if(not button.timeLeft) then
				button.timeLeft = timeLeft;
				button:SetScript('OnUpdate', A.UpdateTime);
			else
				button.timeLeft = timeLeft;
			end

			button.nextUpdate = -1;
			A.UpdateTime(button, 0);
		else
			button.timeLeft = nil;
			button.time:SetText('');
			button:SetScript('OnUpdate', nil);
		end
		
		if(buffInfo.count > 1) then
			button.count:SetText(buffInfo.count);
		else
			button.count:SetText('');
		end
		
		if(buffInfo.filter == 'HARMFUL') then
			local color = DebuffTypeColor[buffInfo.dtype or ''];
			button:SetBackdropBorderColor(color.r, color.g, color.b);
		else
			button:SetBackdropBorderColor(unpack(E.media.bordercolor));
		end
		
		button.texture:SetTexture(buffInfo.icon);
		
		buttons[i] = button;
	end
	
	local display = #buttons;
	if(wrapAfter and maxWraps) then
		display = min(display, wrapAfter * maxWraps);
	end
	
	local left, right, top, bottom = math.huge, -math.huge, -math.huge, math.huge;
	for index=1,display do
		local button = buttons[index];
		local wrapAfter = wrapAfter or index
		local tick, cycle = floor((index - 1) % wrapAfter), floor((index - 1) / wrapAfter);
		button:SetPoint(point, header, cycle * wrapXOffset + tick * xOffset, cycle * wrapYOffset + tick * yOffset);
		
		button:SetSize(size, size);
		
		if(button.time) then
			local font = LSM:Fetch('font', A.db.font);
			button.time:ClearAllPoints();
			button.time:SetPoint('TOP', button, 'BOTTOM', 1 + A.db.timeXOffset, 0 + A.db.timeYOffset);
			button.time:FontTemplate(font, A.db.fontSize, A.db.fontOutline);
			
			button.count:ClearAllPoints();
			button.count:SetPoint('BOTTOMRIGHT', -1 + A.db.countXOffset, 0 + A.db.countYOffset);
			button.count:FontTemplate(font, A.db.fontSize, A.db.fontOutline);
		end
		
		button:Show();
		left = min(left, button:GetLeft() or math.huge);
		right = max(right, button:GetRight() or -math.huge);
		top = max(top, button:GetTop() or -math.huge);
		bottom = min(bottom, button:GetBottom() or math.huge);
	end
	local deadIndex = #(auraTable) + 1;
	local button = select(deadIndex, header:GetChildren());
	while(button) do
		button:Hide();
		deadIndex = deadIndex + 1;
		button = select(deadIndex, header:GetChildren());
	end
	
	if(display >= 1) then
		header:SetWidth(max(right - left, minWidth));
		header:SetHeight(max(top - bottom, minHeight));
	else
		header:SetWidth(minWidth);
		header:SetHeight(minHeight);
	end
end

local tremove = table.remove;
local function stripRAID(filter)
	return filter and tostring(filter):upper():gsub('RAID', ''):gsub('|+', '|'):match('^|?(.+[^|])|?$');
end

local freshTable;
local releaseTable;
do
	local tableReserve = {};
	freshTable = function ()
		local t = next(tableReserve) or {};
		tableReserve[t] = nil;
		return t;
	end
	releaseTable = function (t)
		tableReserve[t] = wipe(t);
	end
end

local sorters = {};
local function sortFactory(key, separateOwn, reverse)
	if(separateOwn ~= 0) then
		if(reverse) then
			return function (a, b)
				if(groupingTable[a.filter] == groupingTable[b.filter]) then
					local ownA, ownB = a.caster == 'player', b.caster == 'player';
					if(ownA ~= ownB) then
						return ownA == (separateOwn > 0)
					end
					return a[key] > b[key];
				else
					return groupingTable[a.filter] < groupingTable[b.filter];
				end
			end;
		else
			return function (a, b)
				if(groupingTable[a.filter] == groupingTable[b.filter]) then
					local ownA, ownB = a.caster == 'player', b.caster == 'player';
					if(ownA ~= ownB) then
						return ownA == (separateOwn > 0);
					end
					return a[key] < b[key];
				else
					return groupingTable[a.filter] < groupingTable[b.filter];
				end
			end;
		end
	else
		if(reverse) then
			return function (a, b)
				if(groupingTable[a.filter] == groupingTable[b.filter]) then
					return a[key] > b[key];
				else
					return groupingTable[a.filter] < groupingTable[b.filter];
				end
			end;
		else
			return function (a, b)
				if(groupingTable[a.filter] == groupingTable[b.filter]) then
					return a[key] < b[key];
				else
					return groupingTable[a.filter] < groupingTable[b.filter];
				end
			end;
		end
	end
end

for i, key in ipairs{'index', 'name', 'expires'} do
	local label = key:upper();
	sorters[label] = {};
	for bool in pairs{[true] = true, [false] = false} do
		sorters[label][bool] = {}
		for sep=-1,1 do
			sorters[label][bool][sep] = sortFactory(key, sep, bool);
		end
	end
end
sorters.TIME = sorters.EXPIRES;

function A:UpdateHeader(self)
	local db = A.db.debuffs;
	if(self.filter == 'HELPFUL') then
		db = A.db.buffs;
	end
	local filter = self.filter;
	local groupBy = self.groupBy;
	local unit = self.unit;
	local sortDirection = db.sortDir;
	local separateOwn = db.seperateOwn or 0;
	if(separateOwn > 0) then
		separateOwn = 1;
	elseif(separateOwn < 0) then
		separateOwn = -1;
	end
	local sortMethod = (sorters[tostring(db.sortMethod):upper()] or sorters['INDEX'])[sortDirection == '-'][separateOwn];

	local time = GetTime();

	wipe(sortingTable);
	wipe(groupingTable);

	if(groupBy) then
		local i = 1;
		for subFilter in groupBy:gmatch('[^,]+') do
			if(filter) then
				subFilter = stripRAID(filter..'|'..subFilter);
			else
				subFilter = stripRAID(subFilter);
			end
			groupingTable[subFilter], groupingTable[i] = i, subFilter;
			i = i + 1;
		end
	else
		filter = stripRAID(filter);
		groupingTable[filter], groupingTable[1] = 1, filter;
	end
	for filterIndex, fullFilter in ipairs(groupingTable) do
		local i = 1;
		repeat
			local aura, _, duration = freshTable();
			aura.name, _, aura.icon, aura.count, aura.dtype, duration, aura.expires, aura.caster, _, aura.shouldConsolidate, _ = UnitAura(unit, i, fullFilter);
			if(aura.name) then
				aura.filter = fullFilter;
				aura.index = i;
				aura.duration = duration;
				
				local targetList = sortingTable;
				tinsert(targetList, aura);
			else
				releaseTable(aura);
			end
			i = i + 1;
		until(not aura.name);
	end
	table.sort(sortingTable, sortMethod);

	configureAuras(self, sortingTable);
	while(sortingTable[1]) do
		releaseTable(tremove(sortingTable));
	end
end

function A:CreateAuraHeader(filter)
	local name = 'ElvUIPlayerDebuffs';
	if(filter == 'HELPFUL') then 
		name = 'ElvUIPlayerBuffs';
	end
	
	local header = CreateFrame('Frame', name, UIParent);
	header:SetClampedToScreen(true);
	header.unit = 'player';
	header.filter = filter;
	
	header:RegisterEvent('UNIT_AURA');
	header:SetScript('OnEvent', function(self, event, ...)
		if(self:IsVisible()) then
			local unit = self.unit;
			if(event == 'UNIT_AURA' and ... == unit) then
				A:UpdateHeader(self);
			end
		end
	end);
	
	A:UpdateHeader(header);
	
	return header;
end

--Blizzard Temp Enchant Duration Text
local function updateTime(button, timeLeft)
	local duration = _G[button:GetName().."Duration"]
	if SHOW_BUFF_DURATIONS == "1" and timeLeft then
		duration:SetTextColor(1, 1, 1)
		local d, h, m, s = ChatFrame_TimeBreakDown(timeLeft);
		if d > 0 then
			duration:SetFormattedText("%1dd", d)
		elseif h > 0 then
			duration:SetFormattedText("%1dh", h)
		elseif m > 0 then
			duration:SetFormattedText("%1dm", m)
		else
			duration:SetTextColor(1, 0, 0)
			duration:SetFormattedText("%1d", s)
		end
	end
end
hooksecurefunc("AuraButton_UpdateDuration", updateTime)

function A:Initialize()
	if(self.db) then
		return;
	end

	if(E.private.auras.disableBlizzard) then
		BuffFrame:Kill()
		ConsolidatedBuffs:Kill()
	end

	if(not E.private.auras.enable) then
		return;
	end

	self.db = E.db.auras;
	
	self.BuffFrame = self:CreateAuraHeader('HELPFUL')
	self.BuffFrame:Point("TOPRIGHT", MMHolder, "TOPLEFT", -(6 + E.Border), -E.Border - E.Spacing);
	E:CreateMover(self.BuffFrame, 'BuffsMover', L['Player Buffs']);
	
	self.DebuffFrame = self:CreateAuraHeader('HARMFUL');
	self.DebuffFrame:Point("BOTTOMRIGHT", MMHolder, "BOTTOMLEFT", -(6 + E.Border), E.Border + E.Spacing);
	E:CreateMover(self.DebuffFrame, 'DebuffsMover', L['Player Debuffs']);
	
	--Temp Enchant
	self.WeaponFrame = CreateFrame("Frame", "ElvUIPlayerWeapons", UIParent);
	self.WeaponFrame:Point("TOPRIGHT", MMHolder, "BOTTOMRIGHT", 0, -E.Border - E.Spacing);

	if(E.myclass == "ROGUE") then
		self.WeaponFrame:Size(110, 32);
	else
		self.WeaponFrame:Size(71, 32);
	end

	TemporaryEnchantFrame:ClearAllPoints()
	TemporaryEnchantFrame:SetPoint("TOPRIGHT", ElvUIPlayerWeapons, "TOPRIGHT", 0, 0)
	E:CreateMover(self.WeaponFrame, "WeaponsMover", L["Player Weapons"]);

	for i = 1, 3 do
		_G["TempEnchant"..i]:ClearAllPoints()
	end

	TempEnchant1:Point("TOPRIGHT", ElvUIPlayerWeapons, "TOPRIGHT")
	TempEnchant2:Point("RIGHT", TempEnchant1, "LEFT", -7, 0)
	TempEnchant3:Point("RIGHT", TempEnchant2, "LEFT", -7, 0)

	for i = 1, 3 do
		local font = LSM:Fetch('font', self.db.font);
		_G["TempEnchant"..i]:Size(32);
		_G["TempEnchant"..i]:CreateBackdrop("Default", true, true);
		_G["TempEnchant"..i].backdrop:SetTemplate("Default", true, true);
		_G["TempEnchant"..i].backdrop:SetBackdropBorderColor(0.5, 0, 0.8, 1);
		_G["TempEnchant"..i].highlight = _G["TempEnchant"..i]:CreateTexture(nil, 'HIGHLIGHT');
		_G["TempEnchant"..i].highlight:SetTexture(1, 1, 1, 0.45);
		_G["TempEnchant"..i].highlight:SetInside();
		_G["TempEnchant"..i.."Border"]:Hide()
		_G["TempEnchant"..i.."Icon"]:SetTexCoord(unpack(E.TexCoords))
		_G["TempEnchant"..i.."Icon"]:SetInside()
		_G["TempEnchant"..i.."Duration"]:ClearAllPoints()
		_G["TempEnchant"..i.."Duration"]:Point("BOTTOM", 1, -12)
		_G["TempEnchant"..i.."Duration"]:FontTemplate(font, self.db.fontSize, self.db.fontOutline);
	end
end

E:RegisterModule(A:GetName());