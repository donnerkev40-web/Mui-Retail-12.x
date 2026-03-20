local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local WindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");

if (obj:Import("MayronUI.Setup.LayoutDefaults", true)) then
  return;
end

local LayoutDefaults = obj:CreateInterface("SetupLayoutDefaults", {});

function LayoutDefaults:CreateRetailChatButtonDefaults()
  return {
    {
      L["Character"];
      L["Player Spells"];
      L["Professions"];
    };
    {
      key = "C";
      L["Reputation"];
      L["Dungeon Finder"];
      L["World Map"];
    };
    {
      key = "S";
      L["Achievements"];
      L["Collections Journal"];
      L["Adventure Guide"];
    };
  };
end

function LayoutDefaults:ApplyRetailChatButtonDefaults()
  if (not (tk:IsRetail() and obj:IsTable(db.profile.chat))) then
    return;
  end

  local chatSettings = db.profile.chat:GetUntrackedTable();
  local chatFrames = chatSettings and chatSettings.chatFrames;
  local template = chatSettings and chatSettings.__templateChatFrame;

  if (obj:IsTable(template)) then
    template.buttons = self:CreateRetailChatButtonDefaults();
  end

  if (not obj:IsTable(chatFrames)) then
    return;
  end

  for _, anchorName in ipairs(WindowTypes.OrderedChatAnchors) do
    if (obj:IsTable(chatFrames[anchorName])) then
      chatFrames[anchorName].buttons = self:CreateRetailChatButtonDefaults();
    end
  end
end

function LayoutDefaults:GetWindowType(windowSettings)
  if (not obj:IsTable(windowSettings)) then
    return "empty";
  end

  if (windowSettings.enabled == false) then
    return "empty";
  end

  return WindowTypes.NormalizeWindowType(windowSettings, "chat");
end

function LayoutDefaults:ApplyUniversalWindowDefaults()
  if (not obj:IsTable(db.profile.chat)) then
    return;
  end

  local chatSettings = db.profile.chat:GetUntrackedTable();
  local chatFrames = chatSettings and chatSettings.chatFrames;

  if (not obj:IsTable(chatFrames)) then
    return;
  end

  local defaults = {
    TOPLEFT = { enabled = false; windowType = "empty"; xOffset = 2; yOffset = -2; };
    TOPRIGHT = { enabled = false; windowType = "empty"; xOffset = -2; yOffset = -2; };
    BOTTOMLEFT = {
      enabled = true; windowType = "chat"; xOffset = 2; yOffset = 2;
      buttons = {
        {
          L["Character"];
          L["Player Spells"];
          L["Dungeon Finder"];
        };
        {
          key = "C";
          L["Friends"];
          L["Guild"];
          L["Help Menu"];
        };
        {
          key = "S";
          L["PVP"];
          L["Quest Log"];
          L["Calendar"];
        };
        {
          key = "A";
          L["Macros"];
          L["World Map"];
          L["Main Menu"];
        };
        {
          key = "CS";
          L["Reputation"];
          L["PVP Score"];
          L["Currency"];
        };
      };
    };
    BOTTOMRIGHT = {
      enabled = true; windowType = "action"; xOffset = -2; yOffset = 2;
      buttons = {
        {
          L["Achievements"];
          L["Collections Journal"];
          L["Adventure Guide"];
        };
        {
          key = "C";
          L["Professions"];
          L["Store"];
          L["Character"];
        };
        {
          key = "S";
          L["Player Spells"];
          L["Dungeon Finder"];
          L["Quest Log"];
        };
        {
          key = "A";
          L["Friends"];
          L["Guild"];
          L["Help Menu"];
        };
      };
    };
  };

  for anchorName, defaultSettings in pairs(defaults) do
    if (obj:IsTable(chatFrames[anchorName])) then
      local windowSettings = chatFrames[anchorName];
      windowSettings.enabled = defaultSettings.enabled;
      windowSettings.windowType = defaultSettings.windowType;
      windowSettings.xOffset = defaultSettings.xOffset;
      windowSettings.yOffset = defaultSettings.yOffset;

      if (obj:IsTable(defaultSettings.buttons)) then
        windowSettings.buttons = tk.Tables:Copy(defaultSettings.buttons, true);
      end
    end
  end

  if (obj:IsTable(chatSettings.editBox)) then
    chatSettings.editBox.position = "BOTTOM";
    chatSettings.editBox.yOffset = -8;
  end
end

obj:Export(LayoutDefaults, "MayronUI.Setup.LayoutDefaults");
