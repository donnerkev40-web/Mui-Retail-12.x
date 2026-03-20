local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.UnitPanelsPage", true)) then
  return;
end

local Page = obj:CreateInterface("UnitPanelsConfigPage", {
  moduleKey = "UnitPanels";
  featurePath = "unitPanels.enabled";
});

obj:Export(Page, "MayronUI.Config.UnitPanelsPage");
