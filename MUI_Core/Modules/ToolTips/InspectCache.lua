local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Tooltips.InspectCache", true)) then
  return;
end

obj:Export(obj:CreateInterface("TooltipsInspectCache", {
  featurePath = "tooltips.inspectCache";
}), "MayronUI.Tooltips.InspectCache");
