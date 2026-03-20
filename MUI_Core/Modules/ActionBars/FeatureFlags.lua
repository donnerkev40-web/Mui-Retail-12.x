local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ActionBars.FeatureFlags", true)) then
  return;
end

local FeatureFlags = obj:CreateInterface("ActionBarsFeatureFlags", {
  module = "actionbars.enabled";
  bottomBars = "actionbars.bottomBars";
  sideBars = "actionbars.sideBars";
  bartenderCompatibility = "actionbars.bartenderCompatibility";
  blizzardSuppressor = "actionbars.blizzardSuppressor";
  microMenuReplacement = "actionbars.microMenuReplacement";
});

obj:Export(FeatureFlags, "MayronUI.ActionBars.FeatureFlags");
