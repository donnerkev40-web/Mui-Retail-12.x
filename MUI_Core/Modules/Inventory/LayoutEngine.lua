local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.LayoutEngine", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventoryLayoutEngine", {
  featurePath = "inventory.layout";
}), "MayronUI.Inventory.LayoutEngine");
