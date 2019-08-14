local E, _, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G
local select = select
local hooksecurefunc = hooksecurefunc

-- functions that were overwritten, we need these to
-- finish the function call when our code executes!
local oldRegisterAsWidget, oldRegisterAsContainer

-- these do *not* need to match the current lib minor version
-- these numbers are used to not attempt skinning way older
-- versions of AceGUI and AceConfigDialog.
local minorGUI, minorConfigDialog = 36, 76

function S:Ace3_SkinDropdownPullout()
	if self and self.obj then
		local pullout = self.obj.pullout
		local dropdown = self.obj.dropdown

		if pullout and pullout.frame then
			if pullout.frame.template and pullout.slider.template then return end

			if not pullout.frame.template then
				pullout.frame:SetTemplate("Default", true)
			end

			if not pullout.slider.template then
				pullout.slider:SetTemplate("Default")
				pullout.slider:Point("TOPRIGHT", pullout.frame, "TOPRIGHT", -10, -10)
				pullout.slider:Point("BOTTOMRIGHT", pullout.frame, "BOTTOMRIGHT", -10, 10)
				if pullout.slider:GetThumbTexture() then
					pullout.slider:SetThumbTexture(E.Media.Textures.Melli)
					pullout.slider:GetThumbTexture():SetVertexColor(1, 0.82, 0, 0.8)
					pullout.slider:GetThumbTexture():Size(10, 14)
				end
			end
		elseif dropdown then
			dropdown:SetTemplate("Default", true)

			if dropdown.slider then
				dropdown.slider:SetTemplate("Default")
				dropdown.slider:Point("TOPRIGHT", dropdown, "TOPRIGHT", -10, -10)
				dropdown.slider:Point("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -10, 10)

				if dropdown.slider:GetThumbTexture() then
					dropdown.slider:SetThumbTexture(E.Media.Textures.Melli)
					dropdown.slider:GetThumbTexture():SetVertexColor(1, 0.82, 0, 0.8)
					dropdown.slider:GetThumbTexture():Size(10, 14)
				end
			end

			if TYPE == "LSM30_Sound" then
				local frame = self.obj.frame
				local width = frame:GetWidth()
				dropdown:Point("TOPLEFT", frame, "BOTTOMLEFT")
				dropdown:Point("TOPRIGHT", frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 30, 0)
			end
		end
	end
end

function S:Ace3_CheckBoxIsEnableSwitch(widget)
	local text = widget.text and widget.text:GetText()
	if text then
		local enabled, disabled = text == S.Ace3_L.GREEN_ENABLE, text == S.Ace3_L.RED_ENABLE
		local isSwitch = (text == S.Ace3_L.Enable) or enabled or disabled

		return isSwitch
	end
end

function S:Ace3_RegisterAsWidget(widget)
	if not E.private.skins.ace3.enable then
		return oldRegisterAsWidget(self, widget)
	end

	local TYPE = widget.type
	if TYPE == "MultiLineEditBox" then
		local frame = widget.frame
		local scrollBG = widget.scrollBG or select(2, frame:GetChildren())

		if not scrollBG.template then
			scrollBG:SetTemplate("Default")
		end

		S:HandleButton(widget.button)
		S:HandleScrollBar(widget.scrollBar)
		widget.scrollBar:Point("RIGHT", frame, "RIGHT", 0 -4)

		scrollBG:Point("TOPRIGHT", widget.scrollBar, "TOPLEFT", -2, 19)
		scrollBG:Point("BOTTOMLEFT", widget.button, "TOPLEFT")
		widget.scrollFrame:Point("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 8)
	elseif TYPE == "CheckBox" then
		local check = widget.check
		local checkbg = widget.checkbg
		local highlight = widget.highlight

		checkbg:CreateBackdrop("Default")
		checkbg.backdrop:SetFrameLevel(checkbg.backdrop:GetFrameLevel() + 1)
		checkbg:SetTexture("")
		checkbg.SetTexture = E.noop

		check:SetParent(checkbg.backdrop)

		hooksecurefunc(widget, "SetDisabled", function(w, value)
			local isSwitch = S:Ace3_CheckBoxIsEnableSwitch(w)

			if value then
				if isSwitch then
					w:SetLabel(S.Ace3_L.RED_ENABLE)
				end
			end
		end)

		hooksecurefunc(widget, "SetValue", function(w, value)
			local isSwitch = S:Ace3_CheckBoxIsEnableSwitch(w)

			if isSwitch then
				w:SetLabel(value and S.Ace3_L.GREEN_ENABLE or S.Ace3_L.RED_ENABLE)
			end
		end)

		if E.private.skins.checkBoxSkin then
			checkbg.backdrop:SetInside(checkbg, 5, 5)
			check:SetTexture(E.Media.Textures.Melli)
			check.SetTexture = E.noop
			check:SetInside(checkbg.backdrop)

			hooksecurefunc(check, "SetDesaturated", function(chk, value)
				local isSwitch = S:Ace3_CheckBoxIsEnableSwitch(widget)
				if value == true then
					if isSwitch then
						chk:SetVertexColor(1.0, 0.2, 0.2, 1.0)
					else
						chk:SetVertexColor(0.6, 0.6, 0.6, 0.8)
					end
				else
					if isSwitch then
						chk:SetVertexColor(0.2, 1.0, 0.2, 1.0)
					else
						chk:SetVertexColor(1, 0.82, 0, 0.8)
					end
				end
			end)
		else
			checkbg.backdrop:SetInside(checkbg, 4, 4)
			check:SetOutside(checkbg.backdrop, 3, 3)
		end

		highlight:SetTexture("")
		highlight.SetTexture = E.noop
	elseif TYPE == "Dropdown" then
		local frame = widget.dropdown
		local button = widget.button
		local button_cover = widget.button_cover
		local text = widget.text

		frame:StripTextures()

		S:HandleNextPrevButton(button, nil, {1, 0.8, 0})

		if not frame.backdrop then
			frame:CreateBackdrop("Default")
		end

		frame.backdrop:Point("TOPLEFT", 17, -2)
		frame.backdrop:Point("BOTTOMRIGHT", -21, 0)

		widget.label:ClearAllPoints()
		widget.label:Point("BOTTOMLEFT", frame.backdrop, "TOPLEFT", 2, 0)

		button:ClearAllPoints()
		button:Point("TOPLEFT", frame.backdrop, "TOPRIGHT", -22, -2)
		button:Point("BOTTOMRIGHT", frame.backdrop, "BOTTOMRIGHT", -2, 2)
		button:SetParent(frame.backdrop)

		text:ClearAllPoints()
		text:SetJustifyH("RIGHT")
		text:Point("RIGHT", button, "LEFT", -3, 0)
		text:Point("LEFT", frame.backdrop, "LEFT", 5, 0)
		text:SetParent(frame.backdrop)

		button:HookScript("OnClick", S.Ace3_SkinDropdownPullout)
		if button_cover then
			button_cover:HookScript("OnClick", S.Ace3_SkinDropdownPullout)
		end
	elseif TYPE == "LSM30_Font" or TYPE == "LSM30_Sound" or TYPE == "LSM30_Border" or TYPE == "LSM30_Background" or TYPE == "LSM30_Statusbar" then
		local frame = widget.frame
		local button = frame.dropButton
		local text = frame.text

		frame:StripTextures()

		S:HandleNextPrevButton(button, nil, {1, 0.8, 0})

		if not frame.backdrop then
			frame:CreateBackdrop("Default")
		end

		frame.label:ClearAllPoints()
		frame.label:Point("BOTTOMLEFT", frame.backdrop, "TOPLEFT", 2, 0)

		text:ClearAllPoints()
		text:Point("RIGHT", button, "LEFT", -2, 0)

		button:ClearAllPoints()
		button:Point("TOPLEFT", frame.backdrop, "TOPRIGHT", -22, -2)
		button:Point("BOTTOMRIGHT", frame.backdrop, "BOTTOMRIGHT", -2, 2)

		frame.backdrop:Point("TOPLEFT", 0, -21)
		frame.backdrop:Point("BOTTOMRIGHT", -4, -1)

		if TYPE == "LSM30_Sound" then
			widget.soundbutton:SetParent(frame.backdrop)
			widget.soundbutton:ClearAllPoints()
			widget.soundbutton:Point("LEFT", frame.backdrop, "LEFT", 2, 0)
		elseif TYPE == "LSM30_Statusbar" then
			widget.bar:SetParent(frame.backdrop)
			widget.bar:ClearAllPoints()
			widget.bar:Point("TOPLEFT", frame.backdrop, "TOPLEFT", 2, -2)
			widget.bar:Point("BOTTOMRIGHT", button, "BOTTOMLEFT", -1, 0)
		end

		button:SetParent(frame.backdrop)
		text:SetParent(frame.backdrop)

		button:HookScript("OnClick", S.Ace3_SkinDropdownPullout)
	elseif TYPE == "EditBox" then
		local frame = widget.editbox
		local button = widget.button

		_G[frame:GetName().."Left"]:Kill()
		_G[frame:GetName().."Middle"]:Kill()
		_G[frame:GetName().."Right"]:Kill()

		frame:Height(17)
		frame:CreateBackdrop("Default")
		frame.backdrop:Point("TOPLEFT", 2, -2)
		frame.backdrop:Point("BOTTOMRIGHT", -2, 0)
		frame.backdrop:SetParent(widget.frame)
		frame:SetParent(frame.backdrop)
		frame:SetTextInsets(4, 43, 3, 3)
		frame.SetTextInsets = E.noop

		S:HandleButton(button)
		button:Point("RIGHT", frame.backdrop, "RIGHT", -2, 0)

		hooksecurefunc(frame, "SetPoint", function(self, a, b, c, d, e)
			if d == 7 then
				self:SetPoint(a, b, c, 0, e)
			end
		end)
	elseif TYPE == "Button" or TYPE == "Button-ElvUI" then
		local frame = widget.frame

		S:HandleButton(frame, true, nil, true)
		frame.backdrop:SetInside()

		widget.text:SetParent(frame.backdrop)
	elseif TYPE == "Slider" then
		local frame = widget.slider
		local editbox = widget.editbox
		local lowtext = widget.lowtext
		local hightext = widget.hightext
		local HEIGHT = 12

		frame:StripTextures()
		frame:SetTemplate("Default")
		frame:Height(HEIGHT)

		local thumbTex = frame:GetThumbTexture()
		frame:SetThumbTexture(E.Media.Textures.Melli)
		thumbTex:SetVertexColor(1, 0.82, 0, 0.8)
		thumbTex:Size(HEIGHT - 2, HEIGHT - 2)

		editbox:SetTemplate("Default")
		editbox:Height(15)
		editbox:Point("TOP", frame, "BOTTOM", 0, -1)

		lowtext:Point("TOPLEFT", frame, "BOTTOMLEFT", 2, -2)
		hightext:Point("TOPRIGHT", frame, "BOTTOMRIGHT", -2, -2)

		hooksecurefunc(widget, "SetDisabled", function(_, disabled)
			if disabled then
				thumbTex:SetVertexColor(0.6, 0.6, 0.6, 0.8)
			else
				thumbTex:SetVertexColor(1, 0.82, 0, 0.8)
			end
		end)
	elseif TYPE == "Keybinding" then
		local button = widget.button
		local msgframe = widget.msgframe
		local msg = widget.msgframe.msg

		S:HandleButton(button)

		msgframe:StripTextures()
		msgframe:CreateBackdrop("Default", true)
		msgframe.backdrop:SetInside()
		msgframe:SetToplevel(true)

		msg:ClearAllPoints()
		msg:Point("LEFT", 10, 0)
		msg:Point("RIGHT", -10, 0)
		msg:SetJustifyV("MIDDLE")
		msg:Width(msg:GetWidth() + 10)
	elseif (TYPE == "ColorPicker" or TYPE == "ColorPicker-ElvUI") then
		local frame = widget.frame
		local colorSwatch = widget.colorSwatch

		if not frame.backdrop then
			frame:CreateBackdrop("Default")
		end

		frame.backdrop:Size(24, 16)
		frame.backdrop:ClearAllPoints()
		frame.backdrop:Point("LEFT", frame, "LEFT", 4, 0)
		frame.backdrop:SetBackdropColor(0, 0, 0, 0)
		frame.backdrop.SetBackdropColor = E.noop

		colorSwatch:SetTexture(E.media.blankTex)
		colorSwatch:ClearAllPoints()
		colorSwatch:SetParent(frame.backdrop)
		colorSwatch:SetInside(frame.backdrop)

		if frame.texture then
			frame.texture:SetTexture(0, 0, 0, 0)
		end

		if frame.checkers then
			frame.checkers:ClearAllPoints()
			frame.checkers:SetDrawLayer("ARTWORK")
			frame.checkers:SetParent(frame.backdrop)
			frame.checkers:SetInside(frame.backdrop)
		end
	elseif TYPE == "Icon" then
		widget.frame:StripTextures()
	end

	return oldRegisterAsWidget(self, widget)
end

function S:Ace3_RegisterAsContainer(widget)
	if not E.private.skins.ace3.enable then
		return oldRegisterAsContainer(self, widget)
	end
	local TYPE = widget.type
	if TYPE == "ScrollFrame" then
		S:HandleScrollBar(widget.scrollbar)
	elseif TYPE == "InlineGroup" or TYPE == "TreeGroup" or TYPE == "TabGroup" or TYPE == "Frame" or TYPE == "DropdownGroup" or TYPE == "Window" then
		local frame = widget.content:GetParent()
		if TYPE == "Frame" then
			frame:StripTextures()
			if not E.GUIFrame then
				E.GUIFrame = frame
			end
			for i = 1, frame:GetNumChildren() do
				local child = select(i, frame:GetChildren())
				if child:IsObjectType("Button") and child:GetText() then
					S:HandleButton(child)
				else
					child:StripTextures()
				end
			end
		elseif TYPE == "Window" then
			frame:StripTextures()
			S:HandleCloseButton(frame.obj.closebutton)
		end
		frame:SetTemplate("Transparent")

		if widget.treeframe then
			widget.treeframe:SetTemplate("Transparent")
			frame:Point("TOPLEFT", widget.treeframe, "TOPRIGHT", 1, 0)

			local oldRefreshTree = widget.RefreshTree
			widget.RefreshTree = function(self, scrollToSelection)
				oldRefreshTree(self, scrollToSelection)
				if not self.tree then return end
				local status = self.status or self.localstatus
				local groupstatus = status.groups
				local lines = self.lines
				local buttons = self.buttons
				local offset = status.scrollvalue

				for i = offset + 1, #lines do
					local button = buttons[i - offset]
					if button then
						button.highlight:SetTexture(E.Media.Textures.Highlight)
						button.highlight:SetVertexColor(1, 0.82, 0, 0.35)
						button.highlight:Point("TOPLEFT", 0, 0)
						button.highlight:Point("BOTTOMRIGHT", 0, 1)

						button.toggle:SetNormalTexture(E.Media.Textures.PlusMinusButton)
						button.toggle:SetPushedTexture(E.Media.Textures.PlusMinusButton)
						button.toggle:SetHighlightTexture("")

						if groupstatus[lines[i].uniquevalue] then
							button.toggle:GetNormalTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
							button.toggle:GetPushedTexture():SetTexCoord(0.540, 0.965, 0.085, 0.920)
						else
							button.toggle:GetNormalTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
							button.toggle:GetPushedTexture():SetTexCoord(0.040, 0.465, 0.085, 0.920)
						end
					end
				end
			end
		end

		if TYPE == "TabGroup" then
			local oldCreateTab = widget.CreateTab
			widget.CreateTab = function(self, id)
				local tab = oldCreateTab(self, id)
				tab:StripTextures()
				tab.backdrop = CreateFrame("Frame", nil, tab)
				tab.backdrop:SetTemplate("Transparent")
				tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
				tab.backdrop:Point("TOPLEFT", 10, -3)
				tab.backdrop:Point("BOTTOMRIGHT", -10, 0)

				return tab
			end
		end

		if widget.scrollbar then
			S:HandleScrollBar(widget.scrollbar)
		end
	elseif TYPE == "SimpleGroup" then
		local frame = widget.content:GetParent()
		frame:SetTemplate("Transparent", nil, true)
		frame.ignoreBackdropColors = true
		frame:SetBackdropColor(0, 0, 0, 0.25)
	end

	return oldRegisterAsContainer(self, widget)
end

function S:Ace3_StyleTooltip()
	if not self then return end
	self:SetTemplate("Transparent", nil, true)
end

function S:Ace3_SkinTooltip(lib, minor) -- lib: AceConfigDialog or AceGUI
	-- we only check `minor` here when checking an instance of AceConfigDialog
	-- we can safely ignore it when checking AceGUI because we minor check that
	-- inside of its own function.
	if not lib or (minor and minor < minorConfigDialog) then return end

	if lib.tooltip and not S:IsHooked(lib.tooltip, "OnShow") then
		S:SecureHookScript(lib.tooltip, "OnShow", S.Ace3_StyleTooltip)
	end

	if lib.popup and not lib.popup.template then -- StaticPopup
		lib.popup:SetTemplate("Transparent")
		lib.popup:GetChildren():StripTextures()
		S:HandleButton(lib.popup.accept, true)
		S:HandleButton(lib.popup.cancel, true)
	end
end

function S:HookAce3(lib, minor) -- lib: AceGUI
	if not lib or (not minor or minor < minorGUI) then return end

	if not S.Ace3_L then
		S.Ace3_L = E.Libs.ACL:GetLocale("ElvUI", E.global.general.locale or "enUS")
	end

	if lib.RegisterAsWidget ~= S.Ace3_RegisterAsWidget then
		oldRegisterAsWidget = lib.RegisterAsWidget
		lib.RegisterAsWidget = S.Ace3_RegisterAsWidget
	end

	if lib.RegisterAsContainer ~= S.Ace3_RegisterAsContainer then
		oldRegisterAsContainer = lib.RegisterAsContainer
		lib.RegisterAsContainer = S.Ace3_RegisterAsContainer
	end

	S:Ace3_SkinTooltip(lib)
end