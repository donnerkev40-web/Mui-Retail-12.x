local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Tooltips.StatusBars", true)) then
  return;
end

obj:Export(obj:CreateInterface("TooltipsStatusBars", {
  featurePath = "tooltips.statusBars";
}), "MayronUI.Tooltips.StatusBars");
