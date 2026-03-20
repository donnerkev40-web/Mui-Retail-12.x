local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.Tutorial", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUITutorial", {
  featurePath = "coreui.tutorial";
}), "MayronUI.CoreUI.Tutorial");
