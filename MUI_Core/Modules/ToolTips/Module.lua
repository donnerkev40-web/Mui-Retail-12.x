local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Tooltips.Module", true)) then
  return;
end

obj:Export(obj:CreateInterface("TooltipsModuleFacade", {
  featurePath = "tooltips.enabled";
}), "MayronUI.Tooltips.Module");
