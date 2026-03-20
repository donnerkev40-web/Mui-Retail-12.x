local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.CombatAlerts", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUICombatAlerts", {
  featurePath = "coreui.combatAlerts";
}), "MayronUI.CoreUI.CombatAlerts");
