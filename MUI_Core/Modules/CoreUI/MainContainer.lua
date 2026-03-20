local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.MainContainer", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUIMainContainer", {
  featurePath = "coreui.mainContainer";
}), "MayronUI.CoreUI.MainContainer");
