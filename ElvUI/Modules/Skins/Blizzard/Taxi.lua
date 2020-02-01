local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.taxi ~= true then return end

	TaxiFrame:StripTextures()
	TaxiFrame:CreateBackdrop("Transparent")

	S:HandleCloseButton(TaxiFrameCloseButton)

	TaxiRouteMap:CreateBackdrop("Default")
	TaxiRouteMap.backdrop.backdropTexture:Hide()
end

S:AddCallback("Taxi", LoadSkin)