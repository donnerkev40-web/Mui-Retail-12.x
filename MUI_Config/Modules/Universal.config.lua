local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.UniversalPage", true)) then
  return;
end

local Page = obj:CreateInterface("UniversalConfigPage", {
  moduleKey = "UniversalWindowModule";
  featurePath = "chat.universal.enabled";
});

obj:Export(Page, "MayronUI.Config.UniversalPage");
