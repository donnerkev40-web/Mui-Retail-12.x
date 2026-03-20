local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Inventory.SlotRenderer", true)) then
  return;
end

obj:Export(obj:CreateInterface("InventorySlotRenderer", {
  featurePath = "inventory.slotRenderer";
}), "MayronUI.Inventory.SlotRenderer");
