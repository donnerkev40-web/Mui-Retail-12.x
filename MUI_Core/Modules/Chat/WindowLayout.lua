local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Chat.WindowLayout", true)) then
  return;
end

local WindowLayout = obj:CreateInterface("ChatWindowLayout", {
  featurePath = "chat.windowLayout";
  defaults = {
    DPS = {
      TOPLEFT = "grid2";
      TOPRIGHT = "empty";
      BOTTOMLEFT = "chat";
      BOTTOMRIGHT = "action";
    };
    Healer = {
      TOPLEFT = "chat";
      TOPRIGHT = "empty";
      BOTTOMLEFT = "grid2";
      BOTTOMRIGHT = "action";
    };
  };
});

obj:Export(WindowLayout, "MayronUI.Chat.WindowLayout");
