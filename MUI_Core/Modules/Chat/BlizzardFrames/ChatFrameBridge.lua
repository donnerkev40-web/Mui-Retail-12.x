local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.BlizzardFrames.ChatFrameBridge", true)) then
  return;
end

local ChatFrameBridge = obj:CreateInterface("ChatFrameBridgeFacade", {
  featurePath = "chat.blizzardFrames";
});

obj:Export(ChatFrameBridge, "MayronUI.Chat.BlizzardFrames.ChatFrameBridge");
