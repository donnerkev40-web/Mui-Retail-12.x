local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Universal.Config", true)) then
  return;
end

local Config = obj:CreateInterface("UniversalConfigMetadata", {
  moduleKey = "chat.universal";
  featurePath = "chat.universal.enabled";
});

obj:Export(Config, "MayronUI.Chat.Universal.Config");
