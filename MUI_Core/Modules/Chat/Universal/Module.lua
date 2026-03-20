local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Universal.Module", true)) then
  return;
end

local Module = obj:CreateInterface("UniversalWindowModuleFacade", {
  featurePath = "chat.universal.enabled";
});

obj:Export(Module, "MayronUI.Chat.Universal.Module");
