local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Universal.VisibilityController", true)) then
  return;
end

local VisibilityController = obj:CreateInterface("UniversalVisibilityController", {
  featurePath = "chat.universal.visibility";
});

obj:Export(VisibilityController, "MayronUI.Chat.Universal.VisibilityController");
