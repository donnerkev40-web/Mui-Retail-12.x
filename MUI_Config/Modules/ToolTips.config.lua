local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.ToolTipsPage", true)) then
  return;
end

local Page = obj:CreateInterface("ToolTipsConfigPage", {
  moduleKey = "Tooltips";
  featurePath = "tooltips.enabled";
});

obj:Export(Page, "MayronUI.Config.ToolTipsPage");
