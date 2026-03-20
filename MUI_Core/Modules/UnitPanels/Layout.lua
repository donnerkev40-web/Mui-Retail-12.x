local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.UnitPanels.Layout", true)) then
  return;
end

obj:Export(obj:CreateInterface("UnitPanelsLayout", {
  featurePath = "unitPanels.layout";
}), "MayronUI.UnitPanels.Layout");
