﻿local E, L, V, P, G = unpack(select(2, ...));
local AB = E:GetModule('ActionBars');

local _G = _G;
local select = select;
local ceil = math.ceil;

local hooksecurefunc = hooksecurefunc
local RegisterStateDriver = RegisterStateDriver
local GetBindingKey = GetBindingKey
local PetHasActionBar = PetHasActionBar
local GetPetActionInfo = GetPetActionInfo
local IsPetAttackAction = IsPetAttackAction
local PetActionButton_StartFlash = PetActionButton_StartFlash
local PetActionButton_StopFlash = PetActionButton_StopFlash
local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop
local GetPetActionSlotUsable = GetPetActionSlotUsable
local SetDesaturation = SetDesaturation
local PetActionBar_ShowGrid = PetActionBar_ShowGrid
local PetActionBar_UpdateCooldowns = PetActionBar_UpdateCooldowns
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

local bar = CreateFrame('Frame', 'ElvUI_BarPet', E.UIParent, 'SecureHandlerStateTemplate');
bar:SetFrameStrata("LOW");

function AB:UpdatePet()
	if(event == "UNIT_AURA" and unit ~= "pet") then return end

	for i=1, NUM_PET_ACTION_SLOTS, 1 do
		local buttonName = "PetActionButton"..i;
		local button = _G[buttonName];
		local icon = _G[buttonName.."Icon"];
		local autoCast = _G[buttonName.."AutoCastable"];
		local shine = _G[buttonName.."Shine"];	
		local checked = button:GetCheckedTexture();
		local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i);

		if not isToken then
			icon:SetTexture(texture);
			button.tooltipName = name;
		else
			icon:SetTexture(_G[texture]);
			button.tooltipName = _G[name];
		end

		button.isToken = isToken;
		button.tooltipSubtext = subtext;

		if isActive and name ~= "PET_ACTION_FOLLOW" then
			button:GetCheckedTexture():SetTexture(1, 1, 1)
			button:SetChecked(true);

			if IsPetAttackAction(i) then
				PetActionButton_StartFlash(button);
			end
		else
			button:SetCheckedTexture("")
			button:SetChecked(false);
			if IsPetAttackAction(i) then
				PetActionButton_StopFlash(button);
			end
		end	

		if autoCastAllowed then
			autoCast:Show();
		else
			autoCast:Hide();
		end	

		if autoCastEnabled then
			AutoCastShine_AutoCastStart(shine);
		else
			AutoCastShine_AutoCastStop(shine);
		end

		button:SetAlpha(1);

		if texture then
			if GetPetActionSlotUsable(i) then
				SetDesaturation(icon, nil);
			else
				SetDesaturation(icon, 1);
			end
			icon:Show();
		else
			icon:Hide();
		end

		if not PetHasActionBar() and texture and name ~= "PET_ACTION_FOLLOW" then
			PetActionButton_StopFlash(button);
			SetDesaturation(icon, 1);
			button:SetChecked(0);
		end

		checked:SetAlpha(0.3);
	end
end

function AB:PetOnEnter()
	E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), self.db["barPet"].alpha)
end

function AB:PetOnLeave()
	E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
end

function AB:PositionAndSizeBarPet()
	local buttonSpacing = E:Scale(self.db['barPet'].buttonspacing);
	local backdropSpacing = E:Scale((self.db['barPet'].backdropSpacing or self.db['barPet'].buttonspacing));
	local buttonsPerRow = self.db['barPet'].buttonsPerRow;
	local numButtons = self.db['barPet'].buttons;
	local size = E:Scale(self.db['barPet'].buttonsize);
	local autoCastSize = (size / 2) - (size / 7.5)
	local point = self.db['barPet'].point;
	local numColumns = ceil(numButtons / buttonsPerRow);
	local widthMult = self.db['barPet'].widthMult;
	local heightMult = self.db['barPet'].heightMult;
	bar.db = self.db['barPet']
	bar.db.position = nil;
	if numButtons < buttonsPerRow then
		buttonsPerRow = numButtons;
	end

	if numColumns < 1 then
		numColumns = 1;
	end

 	if self.db['barPet'].backdrop == true then
 		bar.backdrop:Show();
 	else
 		bar.backdrop:Hide();
 		--Set size multipliers to 1 when backdrop is disabled
 		widthMult = 1
 		heightMult = 1
	end

 	local barWidth = (size * (buttonsPerRow * widthMult)) + ((buttonSpacing * (buttonsPerRow - 1)) * widthMult) + (buttonSpacing * (widthMult-1)) + ((self.db["barPet"].backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
 	local barHeight = (size * (numColumns * heightMult)) + ((buttonSpacing * (numColumns - 1)) * heightMult) + (buttonSpacing * (heightMult-1)) + ((self.db["barPet"].backdrop == true and (E.Border + backdropSpacing) or E.Spacing)*2)
 	bar:Width(barWidth);
	bar:Height(barHeight);

	bar.mouseover = self.db['barPet'].mouseover

	if self.db['barPet'].enabled then
		bar:SetScale(1);
		bar:SetAlpha(self.db['barPet'].alpha);
	else
		bar:SetScale(0.0001);
		bar:SetAlpha(0);
	end

	local horizontalGrowth, verticalGrowth;
	if point == "TOPLEFT" or point == "TOPRIGHT" then
		verticalGrowth = "DOWN";
	else
		verticalGrowth = "UP";
	end

	if point == "BOTTOMLEFT" or point == "TOPLEFT" then
		horizontalGrowth = "RIGHT";
	else
		horizontalGrowth = "LEFT";
	end

	local button, lastButton, lastColumnButton, autoCast;
	local firstButtonSpacing = (self.db["barPet"].backdrop == true and (E.Border + backdropSpacing) or E.Spacing)
	for i=1, NUM_PET_ACTION_SLOTS do
		button = _G["PetActionButton"..i];
		lastButton = _G["PetActionButton"..i-1];
		autoCast = _G["PetActionButton"..i..'AutoCastable'];
		lastColumnButton = _G["PetActionButton"..i-buttonsPerRow];
		button:SetParent(bar);
		button:ClearAllPoints();
		button:Size(size);
		autoCast:SetOutside(button, autoCastSize, autoCastSize)
		button:SetAttribute("showgrid", 1);

		if(self.db["barPet"].inheritGlobalFade) then
			bar:SetParent(self.fadeParent);
		else
			bar:SetParent(E.UIParent);
		end

		if(self.db['barPet'].mouseover == true) then
			bar:SetAlpha(0);
			if(not self.hooks[bar]) then
				self:HookScript(bar, 'OnEnter', 'PetOnEnter');
				self:HookScript(bar, 'OnLeave', 'PetOnLeave');	
			end
			
			if(not self.hooks[button]) then
				self:HookScript(button, 'OnEnter', 'PetOnEnter');
				self:HookScript(button, 'OnLeave', 'PetOnLeave');
			end
		else
			bar:SetAlpha(1);
			if(self.hooks[bar]) then
				self:Unhook(bar, 'OnEnter');
				self:Unhook(bar, 'OnLeave');
			end

			if(self.hooks[button]) then
				self:Unhook(button, 'OnEnter');
				self:Unhook(button, 'OnLeave');
			end
		end

		if(i == 1) then
			local x, y;
			if(point == "BOTTOMLEFT") then
				x, y = firstButtonSpacing, firstButtonSpacing;
			elseif(point == "TOPRIGHT") then
				x, y = -firstButtonSpacing, -firstButtonSpacing;
			elseif(point == "TOPLEFT") then
				x, y = firstButtonSpacing, -firstButtonSpacing;
			else
				x, y = -firstButtonSpacing, firstButtonSpacing;
			end

			button:Point(point, bar, point, x, y);
		elseif((i - 1) % buttonsPerRow == 0) then
			local x = 0;
			local y = -buttonSpacing;
			local buttonPoint, anchorPoint = "TOP", "BOTTOM";
			if(verticalGrowth == "UP") then
				y = buttonSpacing;
				buttonPoint = "BOTTOM";
				anchorPoint = "TOP";
			end
			button:Point(buttonPoint, lastColumnButton, anchorPoint, x, y);
		else
			local x = buttonSpacing;
			local y = 0;
			local buttonPoint, anchorPoint = "LEFT", "RIGHT";
			if(horizontalGrowth == "LEFT") then
				x = -buttonSpacing;
				buttonPoint = "RIGHT";
				anchorPoint = "LEFT";
			end

			button:Point(buttonPoint, lastButton, anchorPoint, x, y);
		end

		if i > numButtons then
			button:SetScale(0.0001);
			button:SetAlpha(0);
		else
			button:SetScale(1);
			button:SetAlpha(bar.db.alpha);
		end

		self:StyleButton(button);
		
		if not button.CheckFixed then
			hooksecurefunc(button:GetCheckedTexture(), 'SetAlpha', function(self, value)
				if value == 1 then
					self:SetAlpha(0.3)
				end
			end)
			button.CheckFixed = true;
		end
	end
	RegisterStateDriver(bar, "show", self.db['barPet'].visibility);

	bar:GetScript("OnSizeChanged")(bar)
end

function AB:UpdatePetBindings()
	for i=1, NUM_PET_ACTION_SLOTS do
		if self.db.hotkeytext then
			local key = GetBindingKey("BONUSACTIONBUTTON"..i)
			_G["PetActionButton"..i.."HotKey"]:Show()
			_G["PetActionButton"..i.."HotKey"]:SetText(key)
			self:FixKeybindText(_G["PetActionButton"..i])
		else
			_G["PetActionButton"..i.."HotKey"]:Hide()
		end
	end
end

function AB:CreateBarPet()
	bar:CreateBackdrop('Default');
	bar.backdrop:SetAllPoints();
	if self.db['bar4'].enabled then
		bar:Point('RIGHT', ElvUI_Bar4, 'LEFT', -4, 0);
	else
		bar:Point('RIGHT', E.UIParent, 'RIGHT', -4, 0);
	end

	bar:SetAttribute("_onstate-show", [[
		if newstate == "hide" then
			self:Hide();
		else
			self:Show();
		end	
	]]);

	PetActionBarFrame.showgrid = 1;
	PetActionBar_ShowGrid();

	self:RegisterEvent('SPELLS_CHANGED', 'UpdatePet');
	self:RegisterEvent('PLAYER_CONTROL_GAINED', 'UpdatePet');
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdatePet');
	self:RegisterEvent('PLAYER_CONTROL_LOST', 'UpdatePet');
	self:RegisterEvent('PET_BAR_UPDATE', 'UpdatePet');
	self:RegisterEvent('UNIT_PET', 'UpdatePet');
	self:RegisterEvent('UNIT_FLAGS', 'UpdatePet');
	self:RegisterEvent('UNIT_AURA', 'UpdatePet');
	self:RegisterEvent('PLAYER_FARSIGHT_FOCUS_CHANGED', 'UpdatePet');
	self:RegisterEvent('PET_BAR_UPDATE_COOLDOWN', PetActionBar_UpdateCooldowns);

	E:CreateMover(bar, 'ElvBar_Pet', L['Pet Bar'], nil, nil, nil,'ALL,ACTIONBARS');
	self:PositionAndSizeBarPet();
	self:UpdatePetBindings();
end