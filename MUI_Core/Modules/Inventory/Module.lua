local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.Module", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventoryModuleFacade", {
  featurePath = "inventory.enabled";
}), "MayronUI.Inventory.Module");
