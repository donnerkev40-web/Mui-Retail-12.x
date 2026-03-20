local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.InventoryPage", true)) then
  return;
end

local Page = obj:CreateInterface("InventoryConfigPage", {
  moduleKey = "InventoryModule";
  featurePath = "inventory.enabled";
});

obj:Export(Page, "MayronUI.Config.InventoryPage");
