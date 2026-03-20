local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ChatModule.Migrations", true)) then
  return;
end

local UniversalWindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");
local NormalizeWindowType = UniversalWindowTypes.NormalizeWindowType;

local Migrations = obj:CreateInterface("ChatModuleMigrations", {});

local function IsPlayerSpellsButton(value)
  return tk:ValueIsEither(value,
    L["Player Spells"], "Player Spells", "Spells & Talents", "Zauber & Talente",
    L["Spell Book"], "Spell Book", "Zauber Buch", "Zauberbuch",
    L["Talents"], "Talents", "Zauber");
end

local function UsesPrimaryChat(windowSettings)
  return windowSettings.enabled and NormalizeWindowType(windowSettings) == "chat";
end

local function UsesChatShell(windowSettings)
  return obj:IsTable(windowSettings)
    and windowSettings.enabled
    and NormalizeWindowType(windowSettings) ~= "empty";
end

function Migrations:UsesPrimaryChat(windowSettings)
  return UsesPrimaryChat(windowSettings);
end

function Migrations:UsesChatShell(windowSettings)
  return UsesChatShell(windowSettings);
end

function Migrations:ModernizeRetailChatButtons(buttons)
  if (not (tk:IsRetail() and obj:IsTable(buttons))) then
    return;
  end

  for _, buttonState in ipairs(buttons) do
    if (obj:IsTable(buttonState)) then
      for index = 1, 3 do
        if (buttonState[index] == L["Bags"]) then
          buttonState[index] = L["World Map"];
        elseif (IsPlayerSpellsButton(buttonState[index])) then
          buttonState[index] = L["Player Spells"];
        end
      end
    end
  end

  local primaryButtons = buttons[1];
  if (obj:IsTable(primaryButtons)
      and primaryButtons[1] == L["Character"]
      and primaryButtons[2] == L["Player Spells"]
      and primaryButtons[3] == L["Player Spells"]) then
    primaryButtons[2] = L["Player Spells"];
    primaryButtons[3] = L["Professions"];
  end

  local controlButtons = buttons[2];
  if (obj:IsTable(controlButtons)
      and controlButtons.key == "C"
      and controlButtons[1] == L["Reputation"]
      and controlButtons[2] == L["LFD"]
      and controlButtons[3] == L["Quest Log"]) then
    controlButtons[2] = L["Dungeon Finder"];
    controlButtons[3] = L["World Map"];
  end

  if (obj:IsTable(controlButtons)
      and controlButtons.key == "C"
      and controlButtons[1] == L["Reputation"]
      and controlButtons[2] == L["Dungeon Finder"]
      and controlButtons[3] == L["Quests"]) then
    controlButtons[3] = L["World Map"];
  end

  local shiftButtons = buttons[3];
  if (obj:IsTable(shiftButtons)
      and shiftButtons.key == "S"
      and shiftButtons[1] == L["Achievements"]
      and shiftButtons[2] == L["Raid"]
      and shiftButtons[3] == L["Encounter Journal"]) then
    shiftButtons[2] = L["Collections Journal"];
    shiftButtons[3] = L["Adventure Guide"];
  end

  if (obj:IsTable(shiftButtons)
      and shiftButtons.key == "S"
      and shiftButtons[1] == L["Achievements"]
      and shiftButtons[2] == L["Collections Journal"]
      and shiftButtons[3] == L["Encounter Journal"]) then
    shiftButtons[3] = L["Adventure Guide"];
  end
end

function Migrations:ApplyDefaultDPSWindowLayout(chatFrames, chatSettings)
  if (db.profile.layout ~= "DPS"
      or not obj:IsTable(chatFrames)
      or not obj:IsTable(chatSettings)) then
    return;
  end

  local topLeft = chatFrames.TOPLEFT;
  local topRight = chatFrames.TOPRIGHT;
  local bottomLeft = chatFrames.BOTTOMLEFT;
  local bottomRight = chatFrames.BOTTOMRIGHT;

  if (not (obj:IsTable(topLeft) and obj:IsTable(topRight)
      and obj:IsTable(bottomLeft) and obj:IsTable(bottomRight))) then
    return;
  end

  local legacyTopLeftChat = UsesPrimaryChat(topLeft) and not UsesPrimaryChat(bottomLeft);
  local missingActionWindow = NormalizeWindowType(bottomRight) ~= "action";
  local missingGrid2Window = NormalizeWindowType(topLeft) ~= "grid2";

  if (legacyTopLeftChat or missingActionWindow or missingGrid2Window) then
    topLeft.enabled = true;
    topLeft.windowType = "grid2";
    topLeft.xOffset = 2;
    topLeft.yOffset = -2;

    topRight.enabled = false;
    topRight.windowType = "empty";
    topRight.xOffset = -2;
    topRight.yOffset = -2;

    bottomLeft.enabled = true;
    bottomLeft.windowType = "chat";
    bottomLeft.xOffset = 2;
    bottomLeft.yOffset = 2;

    bottomRight.enabled = true;
    bottomRight.windowType = "action";
    bottomRight.xOffset = -2;
    bottomRight.yOffset = 2;

    chatSettings.iconsAnchor = "BOTTOMLEFT";
  end
end

function Migrations:ApplyDefaultHealerWindowLayout(chatFrames, chatSettings)
  if (db.profile.layout ~= "Healer"
      or not obj:IsTable(chatFrames)
      or not obj:IsTable(chatSettings)) then
    return;
  end

  local topLeft = chatFrames.TOPLEFT;
  local topRight = chatFrames.TOPRIGHT;
  local bottomLeft = chatFrames.BOTTOMLEFT;
  local bottomRight = chatFrames.BOTTOMRIGHT;

  if (not (obj:IsTable(topLeft) and obj:IsTable(topRight)
      and obj:IsTable(bottomLeft) and obj:IsTable(bottomRight))) then
    return;
  end

  local missingChatWindow = NormalizeWindowType(topLeft) ~= "chat";
  local missingGrid2Window = NormalizeWindowType(bottomLeft) ~= "grid2";
  local missingActionWindow = NormalizeWindowType(bottomRight) ~= "action";
  local legacyBottomLeftChat = UsesPrimaryChat(bottomLeft) and not UsesPrimaryChat(topLeft);

  if (legacyBottomLeftChat or missingChatWindow or missingGrid2Window or missingActionWindow) then
    topLeft.enabled = true;
    topLeft.windowType = "chat";
    topLeft.xOffset = 2;
    topLeft.yOffset = -2;

    topRight.enabled = false;
    topRight.windowType = "empty";
    topRight.xOffset = -2;
    topRight.yOffset = -2;

    bottomLeft.enabled = true;
    bottomLeft.windowType = "grid2";
    bottomLeft.xOffset = 2;
    bottomLeft.yOffset = 2;

    bottomRight.enabled = true;
    bottomRight.windowType = "action";
    bottomRight.xOffset = -2;
    bottomRight.yOffset = 2;

    chatSettings.iconsAnchor = "TOPLEFT";
    chatSettings.universalIconsAnchor = "BOTTOMRIGHT";
  end
end

function Migrations:ApplyDefaultDPSWindowButtons(chatFrames)
  if (db.profile.layout ~= "DPS" or not obj:IsTable(chatFrames)) then
    return;
  end

  local bottomLeft = chatFrames.BOTTOMLEFT;
  local bottomRight = chatFrames.BOTTOMRIGHT;

  if (obj:IsTable(bottomLeft)) then
    local bottomLeftButtons = bottomLeft.buttons;

    if (not obj:IsTable(bottomLeftButtons) or #bottomLeftButtons <= 1) then
      bottomLeft.buttons = {
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
    end
  end

  if (obj:IsTable(bottomRight)) then
    local bottomRightButtons = bottomRight.buttons;

    if (not obj:IsTable(bottomRightButtons) or #bottomRightButtons <= 1) then
      bottomRight.buttons = {
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
    end
  end
end

obj:Export(Migrations, "MayronUI.ChatModule.Migrations");
