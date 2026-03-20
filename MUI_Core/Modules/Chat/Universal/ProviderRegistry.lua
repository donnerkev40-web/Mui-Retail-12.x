local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Universal.ProviderRegistry", true)) then
  return;
end

local ProviderRegistry = obj:CreateInterface("UniversalProviderRegistry", {
  OrderedProviders = {
    "kalielsTracker";
    "moneyLooter";
    "damageMeter";
    "zygorGuides";
  };
  FeaturePaths = {
    kalielsTracker = "chat.universal.providers.kalielsTracker";
    moneyLooter = "chat.universal.providers.moneyLooter";
    damageMeter = "chat.universal.providers.damageMeter";
    zygorGuides = "chat.universal.providers.zygorGuides";
  };
});

obj:Export(ProviderRegistry, "MayronUI.Chat.Universal.ProviderRegistry");
