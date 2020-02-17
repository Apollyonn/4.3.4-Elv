local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G
local unpack = unpack
local strfind = strfind

local NUM_GLYPH_SLOTS = NUM_GLYPH_SLOTS

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	GlyphFrame:StripTextures()
	GlyphFrame:CreateBackdrop("Transparent")

	GlyphFrame.levelOverlayText1:SetTextColor(1, 1, 1)
	GlyphFrame.levelOverlayText2:SetTextColor(1, 1, 1)

	GlyphFrame.sideInset:StripTextures()

	GlyphFrame.clearInfo:CreateBackdrop("Default", true)
	GlyphFrame.clearInfo.backdrop:SetAllPoints()
	GlyphFrame.clearInfo:StyleButton()
	GlyphFrame.clearInfo:Size(25)
	GlyphFrame.clearInfo:Point("BOTTOMLEFT", GlyphFrame, "BOTTOMRIGHT", 10, -2)

	GlyphFrame.clearInfo.icon:SetTexCoord(unpack(E.TexCoords))
	GlyphFrame.clearInfo.icon:ClearAllPoints()
	GlyphFrame.clearInfo.icon:SetInside()

	GlyphFrameScrollFrame:StripTextures()
	GlyphFrameScrollFrameScrollChild:StripTextures()

	S:HandleEditBox(GlyphFrameSearchBox)

	S:HandleDropDownBox(GlyphFrameFilterDropDown, 206)
	GlyphFrameFilterDropDown:Point("TOPLEFT", GlyphFrameSearchBox, "BOTTOMLEFT", -13, -3)

	for i = 1, NUM_GLYPH_SLOTS do
		local frame = _G["GlyphFrameGlyph"..i]

		frame:SetTemplate("Default", true)
		frame:SetFrameLevel(frame:GetFrameLevel() + 5)
		frame:StyleButton(nil, true)

		if i == 1 or i == 4 or i == 6 then
			frame:Size(60)
		elseif i == 2 or i == 3 or i == 5 then
			frame:Size(40)
		else
			frame:Size(80)
		end

		frame.highlight:SetTexture(nil)
		frame.ring:Hide()
		hooksecurefunc(frame.glyph, "Show", function(self) self:Hide() end)

		frame.icon = frame:CreateTexture(nil, "OVERLAY")
		frame.icon:SetInside()
		frame.icon:SetTexCoord(unpack(E.TexCoords))

		frame.onUpdate = CreateFrame("Frame", nil, frame)
		frame.onUpdate:SetScript("OnUpdate", function()
			local alpha = frame.highlight:GetAlpha()
			local glyphIcon = strfind(frame.icon:GetTexture(), "Interface\\Spellbook\\UI%-Glyph%-Rune")

			if alpha == 0 then
				frame:SetBackdropBorderColor(unpack(E.media.bordercolor))
				frame:SetAlpha(1)

				if glyphIcon then
					frame.icon:SetVertexColor(1, 1, 1, 1)
				end
			else
				frame:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
				frame:SetAlpha(alpha)

				if glyphIcon then
					frame.icon:SetVertexColor(unpack(E.media.rgbvaluecolor))
					frame.icon:SetAlpha(alpha)
				end
			end
		end)
	end

	hooksecurefunc("GlyphFrame_Update", function(self)
		local isActiveTalentGroup = PlayerTalentFrame and not PlayerTalentFrame.pet and PlayerTalentFrame.talentGroup == GetActiveTalentGroup(PlayerTalentFrame.pet)

		for i = 1, NUM_GLYPH_SLOTS do
			local glyph = _G["GlyphFrameGlyph"..i]
			local _, _, _, _, iconFilename = GetGlyphSocketInfo(i, PlayerTalentFrame.talentGroup)

			if iconFilename then
				glyph.icon:SetTexture(iconFilename)
			else
				glyph.icon:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune-"..i)
			end

			GlyphFrameGlyph_UpdateSlot(glyph)
			SetDesaturation(glyph.icon, not isActiveTalentGroup)
		end
	end)

	for i = 1, 3 do
		local header = _G["GlyphFrameHeader"..i]

		header:StripTextures()
		header:StyleButton()
	end

	for i = 1, 10 do
		local button = _G["GlyphFrameScrollFrameButton"..i]
		local icon = _G["GlyphFrameScrollFrameButton"..i.."Icon"]

		button:StripTextures()
		S:HandleButton(button)

		icon:SetTexCoord(unpack(E.TexCoords))
	end

	S:HandleScrollBar(GlyphFrameScrollFrameScrollBar, 5)
end

S:AddCallbackForAddon("Blizzard_GlyphUI", "Glyph", LoadSkin)