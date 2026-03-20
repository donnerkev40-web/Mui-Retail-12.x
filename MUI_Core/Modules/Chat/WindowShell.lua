local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.WindowShell", true)) then
  return;
end

local WindowShell = obj:CreateInterface("ChatWindowShell", {
  featurePath = "chat.windowShell";
});

obj:Export(WindowShell, "MayronUI.Chat.WindowShell");
