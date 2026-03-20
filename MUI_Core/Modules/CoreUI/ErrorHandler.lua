local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.ErrorHandler", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUIErrorHandler", {
  featurePath = "coreui.errorHandler";
}), "MayronUI.CoreUI.ErrorHandler");
