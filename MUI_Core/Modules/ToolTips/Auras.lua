local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Tooltips.Auras", true)) then
  return;
end

obj:Export(obj:CreateInterface("TooltipsAuras", {
  featurePath = "tooltips.auras";
}), "MayronUI.Tooltips.Auras");
