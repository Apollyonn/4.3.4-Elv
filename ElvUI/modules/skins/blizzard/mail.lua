local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule('Skins')

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.mail ~= true then return end
	MailFrame:StripTextures(true)
	MailFrame:CreateBackdrop("Transparent")
	MailFrame.backdrop:Point("TOPLEFT", 4, 0)
	MailFrame.backdrop:Point("BOTTOMRIGHT", 2, 74)
	MailFrame:SetWidth(345)

	for i = 1, INBOXITEMS_TO_DISPLAY do
		local bg = _G["MailItem"..i]
		bg:StripTextures()
		bg:CreateBackdrop("Default")
		bg.backdrop:Point("TOPLEFT", 2, 1)
		bg.backdrop:Point("BOTTOMRIGHT", -2, 2)
		
		local b = _G["MailItem"..i.."Button"]
		b:StripTextures()
		b:SetTemplate("Default", true)
		b:StyleButton()

		local t = _G["MailItem"..i.."ButtonIcon"]
		t:SetTexCoord(unpack(E.TexCoords))
		t:SetInside()
	end
	
	S:HandleCloseButton(InboxCloseButton)
	InboxCloseButton:Point("TOPRIGHT", 2, 2)
	S:HandleNextPrevButton(InboxPrevPageButton)
	S:HandleNextPrevButton(InboxNextPageButton)

	MailFrameTab1:StripTextures()
	MailFrameTab2:StripTextures()
	S:HandleTab(MailFrameTab1)
	S:HandleTab(MailFrameTab2)

	-- send mail
	SendMailScrollFrame:StripTextures(true)
	SendMailScrollFrame:SetTemplate("Default")

	S:HandleScrollBar(SendMailScrollFrameScrollBar)
	
	S:HandleEditBox(SendMailNameEditBox)
	S:HandleEditBox(SendMailSubjectEditBox)
	S:HandleEditBox(SendMailMoneyGold)
	S:HandleEditBox(SendMailMoneySilver)
	S:HandleEditBox(SendMailMoneyCopper)
	
	SendMailNameEditBox.backdrop:Point("BOTTOMRIGHT", 2, 0)
	SendMailSubjectEditBox.backdrop:Point("BOTTOMRIGHT", 2, 0)
	SendMailFrame:StripTextures()
	
	local function MailFrameSkin()
		for i = 1, ATTACHMENTS_MAX_SEND do
			local b = _G["SendMailAttachment"..i];
			if(not b.skinned) then
				b:StripTextures();
				b:SetTemplate("Default", true);
				b:StyleButton(nil, true);
				b.skinned = true;
			end
			local t = b:GetNormalTexture();
			local itemName = GetSendMailItem(i);
			if(itemName) then
				local quality = select(3, GetItemInfo(itemName));
				if(quality and quality > 1) then
					b:SetBackdropBorderColor(GetItemQualityColor(quality));
				else
					b:SetBackdropBorderColor(unpack(E["media"].bordercolor));
				end
				t:SetTexCoord(unpack(E.TexCoords));
				t:SetInside();
			else
				b:SetBackdropBorderColor(unpack(E["media"].bordercolor));
			end
		end
	end
	hooksecurefunc("SendMailFrame_Update", MailFrameSkin)
	
	local function OpenMail_Update()
		if(not InboxFrame.openMailID) then return; end
		local bodyText, texture, isTakeable, isInvoice = GetInboxText(InboxFrame.openMailID);
		local itemButtonCount, itemRowCount = OpenMail_GetItemCounts(isTakeable, textCreated, money);
		if(itemRowCount > 0 and OpenMailFrame.activeAttachmentButtons) then
			for i, attachmentButton in pairs(OpenMailFrame.activeAttachmentButtons) do
				if(attachmentButton ~= OpenMailLetterButton and attachmentButton ~= OpenMailMoneyButton) then
					local name, itemTexture, count, quality = GetInboxItem(InboxFrame.openMailID, attachmentButton:GetID());
					if (name) then
						if (quality and quality > 1) then
							attachmentButton:SetBackdropBorderColor(GetItemQualityColor(quality));
						else
							attachmentButton:SetBackdropBorderColor(unpack(E["media"].bordercolor));
						end
					end
				end
			end
		end
	end
	hooksecurefunc("OpenMail_Update", OpenMail_Update);

	S:HandleButton(SendMailMailButton)
	S:HandleButton(SendMailCancelButton)
	
	SendMailCancelButton:Point("BOTTOMRIGHT", SendMailFrame, "BOTTOMRIGHT", -45, 80)
	SendMailMoneyFrame:Point("BOTTOMRIGHT", SendMailFrame, "BOTTOMLEFT", 170, 84)
	
	-- open mail (cod)
	OpenMailFrame:StripTextures(true)
	OpenMailFrame:CreateBackdrop("Transparent")
	OpenMailFrame.backdrop:Point("TOPLEFT", 4, 0)
	OpenMailFrame.backdrop:Point("BOTTOMRIGHT", 2, 74)
	OpenMailFrame:SetWidth(350)
	
	S:HandleCloseButton(OpenMailCloseButton)
	OpenMailCloseButton:Point("TOPRIGHT", 2, 2)
	S:HandleButton(OpenMailReportSpamButton)
	S:HandleButton(OpenMailReplyButton)
	S:HandleButton(OpenMailDeleteButton)
	S:HandleButton(OpenMailCancelButton)
	
	OpenMailScrollFrame:StripTextures(true)
	OpenMailScrollFrame:SetTemplate("Default")

	S:HandleScrollBar(OpenMailScrollFrameScrollBar)
	
	SendMailBodyEditBox:SetTextColor(1, 1, 1)
	OpenMailBodyText:SetTextColor(1, 1, 1)
	InvoiceTextFontNormal:SetTextColor(1, 1, 1)
	OpenMailArithmeticLine:Kill()
	
	OpenMailLetterButton:StripTextures()
	OpenMailLetterButton:SetTemplate("Default", true)
	OpenMailLetterButton:StyleButton()
	OpenMailLetterButtonIconTexture:SetTexCoord(unpack(E.TexCoords))						
	OpenMailLetterButtonIconTexture:SetDrawLayer("ARTWORK")
	OpenMailLetterButtonIconTexture:SetInside()
	OpenMailLetterButtonCount:SetDrawLayer("OVERLAY")
	
	OpenMailMoneyButton:StripTextures()
	OpenMailMoneyButton:SetTemplate("Default", true)
	OpenMailMoneyButton:StyleButton()
	OpenMailMoneyButtonIconTexture:SetTexCoord(unpack(E.TexCoords))						
	OpenMailMoneyButtonIconTexture:SetDrawLayer("ARTWORK")
	OpenMailMoneyButtonIconTexture:SetInside()
	OpenMailMoneyButtonCount:SetDrawLayer("OVERLAY")
	
	for i = 1, ATTACHMENTS_MAX_SEND do				
		local b = _G["OpenMailAttachmentButton"..i]
		b:StripTextures()
		b:SetTemplate("Default", true)
		b:StyleButton()
		
		local it = _G["OpenMailAttachmentButton"..i.."IconTexture"]
		local c = _G["OpenMailAttachmentButton"..i.."Count"]
		if it then
			it:SetTexCoord(unpack(E.TexCoords))
			it:SetDrawLayer("ARTWORK")
			it:SetInside()
			c:SetDrawLayer("OVERLAY")
		end
	end
	
	OpenMailReplyButton:Point("RIGHT", OpenMailDeleteButton, "LEFT", -2, 0)
	OpenMailDeleteButton:Point("RIGHT", OpenMailCancelButton, "LEFT", -2, 0)
	SendMailMailButton:Point("RIGHT", SendMailCancelButton, "LEFT", -2, 0)
end

S:RegisterSkin('ElvUI', LoadSkin)