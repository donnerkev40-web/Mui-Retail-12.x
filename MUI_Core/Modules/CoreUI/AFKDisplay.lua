local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.AFKDisplay", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUIAFKDisplay", {
  featurePath = "coreui.afkDisplay";
}), "MayronUI.CoreUI.AFKDisplay");
