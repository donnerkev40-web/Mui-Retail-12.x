local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (obj:Import("MayronUI.UniversalWindow.WindowTypes", true)) then
  return;
end

local WindowTypes = obj:CreateInterface("UniversalWindowWindowTypes", {});

WindowTypes.OrderedChatAnchors = {
  "TOPLEFT";
  "TOPRIGHT";
  "BOTTOMLEFT";
  "BOTTOMRIGHT";
};

function WindowTypes.NormalizeWindowType(windowSettings, fallback)
  fallback = fallback or "chat";

  if (not obj:IsTable(windowSettings)) then
    return fallback;
  end

  local windowType = windowSettings.windowType;

  if (windowType == "chat" or windowType == "action"
      or windowType == "grid2"
      or windowType == "empty") then
    return windowType;
  end

  return fallback;
end

obj:Export(WindowTypes, "MayronUI.UniversalWindow.WindowTypes");
