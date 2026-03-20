local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.Filters", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventoryFilters", {
  featurePath = "inventory.filters";
}), "MayronUI.Inventory.Filters");
