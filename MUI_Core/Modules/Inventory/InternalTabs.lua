local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.InternalTabs", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventoryInternalTabs", {
  featurePath = "inventory.tabs";
}), "MayronUI.Inventory.InternalTabs");
