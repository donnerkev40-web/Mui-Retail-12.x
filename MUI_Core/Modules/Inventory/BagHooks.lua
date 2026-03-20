local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.BagHooks", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventoryBagHooks", {
  featurePath = "inventory.bagHooks";
}), "MayronUI.Inventory.BagHooks");
