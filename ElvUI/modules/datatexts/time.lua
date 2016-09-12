local E, L, V, P, G = unpack(select(2, ...));
local DT = E:GetModule("DataTexts");

local date = date;
local format, join = string.format, string.join;

local GetGameTime = GetGameTime;
local GetNumSavedInstances = GetNumSavedInstances;
local GetSavedInstanceInfo = GetSavedInstanceInfo;
local GetWintergraspWaitTime = GetWintergraspWaitTime;
local RequestRaidInfo = RequestRaidInfo;
local SecondsToTime = SecondsToTime;
local QUEUE_TIME_UNAVAILABLE = QUEUE_TIME_UNAVAILABLE;
local TIMEMANAGER_TOOLTIP_LOCALTIME = TIMEMANAGER_TOOLTIP_LOCALTIME;
local TIMEMANAGER_TOOLTIP_REALMTIME = TIMEMANAGER_TOOLTIP_REALMTIME;
local WINTERGRASP_IN_PROGRESS = WINTERGRASP_IN_PROGRESS;

local APM = {TIMEMANAGER_PM, TIMEMANAGER_AM};
local europeDisplayFormat = "";
local ukDisplayFormat = "";
local europeDisplayFormat_nocolor = string.join("", "%02d", ":|r%02d")
local ukDisplayFormat_nocolor = string.join("", "", "%d", ":|r%02d", " %s|r")
local timerLongFormat = "%d:%02d:%02d"
local timerShortFormat = "%d:%02d"
local lockoutInfoFormat = "|cffcccccc[%d%s]|r %s |cfff04000(%s/%s)|r"
local formatBattleGroundInfo = "%s: "
local difficultyInfo = {"N", "N", "H", "H"};
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8};
local lockoutFormatString = { "%dd %02dh %02dm", "%dd %dh %02dm", "%02dh %02dm", "%dh %02dm", "%dh %02dm", "%dm" }
local curHr, curMin, curAmPm
local enteredFrame = false;

local Update, lastPanel; -- UpValue
local name, instanceID, reset, difficultyId, locked, extended, isRaid, maxPlayers, difficulty;

local function ValueColorUpdate(hex)
	europeDisplayFormat = string.join("", "%02d", hex, ":|r%02d ", format("%s", date(hex .. "%d.%m.%y|r")));
	ukDisplayFormat = string.join("", "", "%d", hex, ":|r%02d", hex, " %s|r ", format("%s", date(hex .. "%d.%m.%y|r")));

	if lastPanel ~= nil then
		Update(lastPanel, 20000)
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true;

local function CalculateTimeValues(tt)
	local Hr, Min, AmPm
	if tt and tt == true then
		if E.db.datatexts.localtime == true then
			Hr, Min = GetGameTime()
			if E.db.datatexts.time24 == true then
				return Hr, Min, -1
			else
				if Hr>=12 then
					if Hr>12 then Hr = Hr - 12 end
					AmPm = 1
				else
					if Hr == 0 then Hr = 12 end
					AmPm = 2
				end
				return Hr, Min, AmPm
			end
		else
			local Hr24 = tonumber(date("%H"))
			Hr = tonumber(date("%I"))
			Min = tonumber(date("%M"))
			if E.db.datatexts.time24 == true then
				return Hr24, Min, -1
			else
				if Hr24>=12 then AmPm = 1 else AmPm = 2 end
				return Hr, Min, AmPm
			end
		end
	else
		if E.db.datatexts.localtime == true then
			local Hr24 = tonumber(date("%H"))
			Hr = tonumber(date("%I"))
			Min = tonumber(date("%M"))
			if E.db.datatexts.time24 == true then
				return Hr24, Min, -1
			else
				if Hr24>=12 then AmPm = 1 else AmPm = 2 end
				return Hr, Min, AmPm
			end
		else
			Hr, Min = GetGameTime()
			if E.db.datatexts.time24 == true then
				return Hr, Min, -1
			else
				if Hr>=12 then
					if Hr>12 then Hr = Hr - 12 end
					AmPm = 1
				else
					if Hr == 0 then Hr = 12 end
					AmPm = 2
				end
				return Hr, Min, AmPm
			end
		end
	end
end

local function CalculateTimeLeft(time)
	local hour = floor(time / 3600)
	local min = floor(time / 60 - (hour*60))
	local sec = time - (hour * 3600) - (min * 60)

	return hour, min, sec
end

local function formatResetTime(sec)
	local d,h,m,s = ChatFrame_TimeBreakDown(floor(sec))
	if not type(d) == 'number' or not type(h)== 'number' or not type(m) == 'number' or not type(s) == 'number' then
		return 'N/A'
	end

	if d > 0 and lockoutFormatString[h>10 and 1 or 2] then 
		return format(lockoutFormatString[h>10 and 1 or 2], d, h, m)
	end
	if h > 0 and lockoutFormatString[h>10 and 3 or 4] then
		return format(lockoutFormatString[h>10 and 3 or 4], h, m)
	end
	if m > 0 and lockoutFormatString[m>10 and 5 or 6] then 
		return format(lockoutFormatString[m>10 and 5 or 6], m) 
	end
end

local function Click(_, btn)
	if(btn == "RightButton") then
 		TimeManagerClockButton_OnClick(TimeManagerClockButton);
 	else
 		GameTimeFrame:Click();
 	end
end

local function OnLeave()
	DT.tooltip:Hide();
	enteredFrame = false;
end

local function OnEvent(_, event)
	if(event == "UPDATE_INSTANCE_INFO" and enteredFrame) then
		RequestRaidInfo();
	end
end

local function OnEnter(self)
	DT:SetupTooltip(self)
	enteredFrame = true;
	DT.tooltip:AddLine(VOICE_CHAT_BATTLEGROUND);
	local localizedName, isActive, canQueue, startTime, canEnter
	for i = 1, GetNumWorldPVPAreas() do
		_, localizedName, isActive, canQueue, startTime, canEnter = GetWorldPVPAreaInfo(i)
		if canEnter then
			if isActive then
				startTime = WINTERGRASP_IN_PROGRESS
			elseif startTime == nil then
				startTime = QUEUE_TIME_UNAVAILABLE
			else
				local hour, min, sec = CalculateTimeLeft(startTime)
				if hour > 0 then 
					startTime = string.format(timerLongFormat, hour, min, sec) 
				else 
					startTime = string.format(timerShortFormat, min, sec)
				end
			end
			DT.tooltip:AddDoubleLine(format(formatBattleGroundInfo, localizedName), startTime, 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)	
		end
	end	

	local timeText
	local Hr, Min, AmPm = CalculateTimeValues(true)

	DT.tooltip:AddLine(" ")
	timeText = E.db.datatexts.localtime and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME
	if AmPm == -1 then
			DT.tooltip:AddDoubleLine(timeText, string.format(europeDisplayFormat_nocolor, Hr, Min), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)
	else
			DT.tooltip:AddDoubleLine(timeText, string.format(ukDisplayFormat_nocolor, Hr, Min, APM[AmPm]), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b)
	end

	local oneraid, lockoutColor
	for i = 1, GetNumSavedInstances() do
		local name, _, reset, difficulty, locked, extended, _, isRaid, maxPlayers, _, numEncounters, encounterProgress  = GetSavedInstanceInfo(i)
		if isRaid and (locked or extended) then
			local tr,tg,tb,diff
			if not oneraid then
				DT.tooltip:AddLine(" ")
				DT.tooltip:AddLine(L["Saved Raid(s)"])
				oneraid = true
			end
			if extended then lockoutColor = lockoutColorExtended else lockoutColor = lockoutColorNormal end
			DT.tooltip:AddDoubleLine(format(lockoutInfoFormat, maxPlayers, difficultyInfo[difficulty], name, encounterProgress, numEncounters), formatResetTime(reset), 1,1,1, lockoutColor.r,lockoutColor.g,lockoutColor.b)
		end
	end

	DT.tooltip:Show()
end

local int = 1
function Update(self, t)
	int = int - t

	if enteredFrame then
		OnEnter(self)
	end

	if int > 0 then return end

	local Hr, Min, AmPm = CalculateTimeValues(false)

	if (Hr == curHr and Min == curMin and AmPm == curAmPm) and not (int < -15000) then
		int = 2
		return
	end

	curHr = Hr
	curMin = Min
	curAmPm = AmPm

	if AmPm == -1 then
		self.text:SetFormattedText(europeDisplayFormat, Hr, Min)
	else
		self.text:SetFormattedText(ukDisplayFormat, Hr, Min, APM[AmPm])
	end
	lastPanel = self
	int = 2
end

DT:RegisterDatatext("Time", {"UPDATE_INSTANCE_INFO"}, OnEvent, Update, Click, OnEnter, OnLeave); 