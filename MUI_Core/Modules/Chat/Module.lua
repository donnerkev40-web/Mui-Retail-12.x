local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.Module", true)) then
  return;
end

local Module = obj:CreateInterface("ChatModuleFacade", {});

function Module:GetFeaturePath()
  return "chat.enabled";
end

obj:Export(Module, "MayronUI.Chat.Module");
