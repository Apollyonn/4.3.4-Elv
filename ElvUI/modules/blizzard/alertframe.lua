local E, L, V, P, G = unpack(select(2, ...))
local B = E:GetModule("Blizzard")
local Misc = E:GetModule("Misc")

local _G = _G
local pairs = pairs

local AlertFrame_FixAnchors = AlertFrame_FixAnchors
local NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES

local POSITION, ANCHOR_POINT, YOFFSET = "TOP", "BOTTOM", -10

function E:PostAlertMove(screenQuadrant)
	local AlertFrameMover = _G.AlertFrameMover
	local AlertFrameHolder = _G.AlertFrameHolder

	local _, y = AlertFrameMover:GetCenter()
	local screenHeight = E.UIParent:GetTop()

	if y > (screenHeight / 2) then
		POSITION = "TOP"
		ANCHOR_POINT = "BOTTOM"
		YOFFSET = -10
		AlertFrameMover:SetText(AlertFrameMover.textString.." [Grow Down]")
	else
		POSITION = "BOTTOM"
		ANCHOR_POINT = "TOP"
		YOFFSET = 10
		AlertFrameMover:SetText(AlertFrameMover.textString.." [Grow Up]")
	end

	local rollBars = Misc.RollBars
	if E.private.general.lootRoll then
		local lastframe, lastShownFrame
		for i, frame in pairs(rollBars) do
			frame:ClearAllPoints()
			if i ~= 1 then
				if POSITION == "TOP" then
					frame:Point("TOP", lastframe, "BOTTOM", 0, -4)
				else
					frame:Point("BOTTOM", lastframe, "TOP", 0, 4)
				end
			else
				if POSITION == "TOP" then
					frame:Point("TOP", AlertFrameHolder, "BOTTOM", 0, -4)
				else
					frame:Point("BOTTOM", AlertFrameHolder, "TOP", 0, 4)
				end
			end
			lastframe = frame

			if frame:IsShown() then
				lastShownFrame = frame
			end
		end

		AlertFrame:ClearAllPoints()
		if lastShownFrame then
			AlertFrame:SetAllPoints(lastShownFrame)
		else
			AlertFrame:SetAllPoints(AlertFrameHolder)
		end
	elseif E.private.skins.blizzard.enable and E.private.skins.blizzard.lootRoll then
		local lastframe, lastShownFrame
		for i = 1, NUM_GROUP_LOOT_FRAMES do
			local frame = _G["GroupLootFrame"..i]
			if frame then
				frame:ClearAllPoints()
				if i ~= 1 then
					if POSITION == "TOP" then
						frame:Point("TOP", lastframe, "BOTTOM", 0, -4)
					else
						frame:Point("BOTTOM", lastframe, "TOP", 0, 4)
					end
				else
					if POSITION == "TOP" then
						frame:Point("TOP", AlertFrameHolder, "BOTTOM", 0, -4)
					else
						frame:Point("BOTTOM", AlertFrameHolder, "TOP", 0, 4)
					end
				end
				lastframe = frame

				if frame:IsShown() then
					lastShownFrame = frame
				end
			end
		end

		AlertFrame:ClearAllPoints()
		if lastShownFrame then
			AlertFrame:SetAllPoints(lastShownFrame)
		else
			AlertFrame:SetAllPoints(AlertFrameHolder)
		end
	else
		AlertFrame:ClearAllPoints()
		AlertFrame:SetAllPoints(AlertFrameHolder)
	end

	if screenQuadrant then
		AlertFrame_FixAnchors()
	end
end

function B:AchievementAlertFrame_FixAnchors()
	local alertAnchor
	for i = 1, MAX_ACHIEVEMENT_ALERTS do
		local frame = _G["AchievementAlertFrame"..i]
		if frame then
			frame:ClearAllPoints()
			if alertAnchor and alertAnchor:IsShown() then
				frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
			else
				frame:SetPoint(POSITION, AlertFrame, ANCHOR_POINT)
			end

			alertAnchor = frame
		end
	end
end

function B:DungeonCompletionAlertFrame_FixAnchors()
	for i = MAX_ACHIEVEMENT_ALERTS, 1, -1 do
		local frame = _G["AchievementAlertFrame"..i]
		if frame and frame:IsShown() then
			DungeonCompletionAlertFrame1:ClearAllPoints()
			DungeonCompletionAlertFrame1:Point(POSITION, frame, ANCHOR_POINT, 0, YOFFSET)
			return
		end

		DungeonCompletionAlertFrame1:ClearAllPoints()
		DungeonCompletionAlertFrame1:Point(POSITION, AlertFrame, ANCHOR_POINT)
	end
end

function B:GuildChallengeAlertFrame_FixAnchors()
	for i = MAX_ACHIEVEMENT_ALERTS, 1, -1 do
		if _G["AchievementAlertFrame"..i] and _G["AchievementAlertFrame"..i]:IsShown() then
			aFrame = _G["AchievementAlertFrame"..i]
		end
	end

	if DungeonCompletionAlertFrame1:IsShown() then
		aFrame = DungeonCompletionAlertFrame1
	end

	if aFrame == nil then
		aFrame = AlertFrame
	end

	GuildChallengeAlertFrame:ClearAllPoints()
	if POSITION == "TOP" then
		GuildChallengeAlertFrame:SetPoint("TOP", aFrame, "BOTTOM", 0, -10)
	else
		GuildChallengeAlertFrame:SetPoint("BOTTOM", aFrame, "TOP", 0, 10)
	end
end

function B:AlertMovers()
	local AlertFrameHolder = CreateFrame("Frame", "AlertFrameHolder", E.UIParent)
	AlertFrameHolder:Width(180)
	AlertFrameHolder:Height(20)
	AlertFrameHolder:Point("TOP", E.UIParent, "TOP", 0, -18)

	self:SecureHook("AlertFrame_FixAnchors", E.PostAlertMove)
	self:SecureHook("AchievementAlertFrame_FixAnchors")
	self:SecureHook("DungeonCompletionAlertFrame_FixAnchors")
	self:SecureHook("GuildChallengeAlertFrame_FixAnchors")

	E:CreateMover(AlertFrameHolder, "AlertFrameMover", L["Loot / Alert Frames"], nil, nil, E.PostAlertMove, nil, nil, "general,general")
end