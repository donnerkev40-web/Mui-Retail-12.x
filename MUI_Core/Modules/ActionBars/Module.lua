local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ActionBars.Module", true)) then
  return;
end

local Module = obj:CreateInterface("ActionBarsModuleFacade", {});

function Module:GetFeaturePath()
  return "actionbars.enabled";
end

obj:Export(Module, "MayronUI.ActionBars.Module");
