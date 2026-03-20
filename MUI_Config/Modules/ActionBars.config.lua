local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.ActionBarsPage", true)) then
  return;
end

local Page = obj:CreateInterface("ActionBarsConfigPage", {
  moduleKey = "BottomActionBars";
  featurePath = "actionbars.enabled";
});

obj:Export(Page, "MayronUI.Config.ActionBarsPage");
