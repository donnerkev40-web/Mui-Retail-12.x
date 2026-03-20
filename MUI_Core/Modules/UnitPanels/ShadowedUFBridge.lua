local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.UnitPanels.ShadowedUFBridge", true)) then
  return;
end

obj:Export(obj:CreateInterface("UnitPanelsShadowedUFBridge", {
  featurePath = "unitPanels.shadowedUFBridge";
}), "MayronUI.UnitPanels.ShadowedUFBridge");
