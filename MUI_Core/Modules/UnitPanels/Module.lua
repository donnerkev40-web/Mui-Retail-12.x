local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.UnitPanels.Module", true)) then
  return;
end

obj:Export(obj:CreateInterface("UnitPanelsModuleFacade", {
  featurePath = "unitPanels.enabled";
}), "MayronUI.UnitPanels.Module");
