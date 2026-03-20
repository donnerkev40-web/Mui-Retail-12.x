local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Config.ChatPage", true)) then
  return;
end

local Page = obj:CreateInterface("ChatConfigPage", {
  moduleKey = "ChatModule";
  featurePath = "chat.enabled";
});

obj:Export(Page, "MayronUI.Config.ChatPage");
