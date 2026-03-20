local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Universal.HostController", true)) then
  return;
end

local HostController = obj:CreateInterface("UniversalHostController", {
  featurePath = "chat.universal.host";
});

obj:Export(HostController, "MayronUI.Chat.Universal.HostController");
