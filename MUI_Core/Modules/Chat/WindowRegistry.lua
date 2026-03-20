local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.WindowRegistry", true)) then
  return;
end

local WindowRegistry = obj:CreateInterface("ChatWindowRegistry", {
  OrderedAnchors = {
    "TOPLEFT";
    "TOPRIGHT";
    "BOTTOMLEFT";
    "BOTTOMRIGHT";
  };
  SupportedWindowTypes = {
    chat = true;
    action = true;
    grid2 = true;
    empty = true;
  };
});

obj:Export(WindowRegistry, "MayronUI.Chat.WindowRegistry");
