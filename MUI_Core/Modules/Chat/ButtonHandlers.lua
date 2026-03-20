-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI, table = _G.MayronUI, _G.table;
local tk, _, em, _, _, L = MayronUI:GetCoreComponents();
local obj = _G.MayronObjects:GetFramework();
local SHOW_TALENT_LEVEL = _G.SHOW_TALENT_LEVEL or 10;

---@class ChatFrame
local _, C_ChatModule = MayronUI:ImportModule("ChatModule");
local C_ChatFrame = obj:Import("MayronUI.ChatModule.ChatFrame");

local LoadAddOn, IsTrialAccount, IsInGuild, UnitLevel, UnitInBattleground =
_G.LoadAddOn, _G.IsTrialAccount, _G.IsInGuild, _G.UnitLevel,
_G.UnitInBattleground;

local InCombatLockdown, ipairs = _G.InCombatLockdown, _G.ipairs;
local ToggleGuildFrame;

if (tk:IsRetail()) then
  ToggleGuildFrame = _G.ToggleGuildFrame;
else
  local ToggleFriendsFrame = _G.ToggleFriendsFrame;
  ToggleGuildFrame = function()
    ToggleFriendsFrame(2)
  end
end

-- GLOBALS:
--[[ luacheck: ignore
ToggleCharacter ContainerFrame1 ToggleBackpack OpenAllBags ToggleFrame SpellBookFrame PlayerTalentFrame MacroFrame
ToggleFriendsFrame ToggleHelpFrame TogglePVPUI ToggleAchievementFrame ToggleCalendar ToggleQuestLog
ToggleLFDParentFrame ToggleRaidFrame ToggleEncounterJournal ToggleCollectionsJournal ToggleWorldMap
ToggleWorldStateScoreFrame TalentFrame ToggleLFGParentFrame
]]

local buttonKeys = {
  Character = L["Character"];
  Bags = L["Bags"];
  Friends = L["Friends"];
  Guild = L["Guild"];
  HelpMenu = L["Help Menu"];
  MainMenu = L["Main Menu"];
  Store = L["Store"];
  PlayerSpells = L["Player Spells"];
  Professions = L["Professions"];
  DungeonFinder = L["Dungeon Finder"];
  AdventureGuide = L["Adventure Guide"];
  SpellBook = L["Spell Book"];
  Talents = L["Talents"];
  Macros = L["Macros"];
  WorldMap = L["World Map"];
  QuestLog = L["Quest Log"];
  Reputation = L["Reputation"];
  PVPScore = L["PVP Score"];
};

if (not tk:IsRetail()) then
  C_ChatModule.Static.ButtonNames = {
    L["Character"]; L["Bags"]; L["Friends"]; L["Guild"]; L["Help Menu"];
    L["Spell Book"]; L["Talents"]; L["Raid"]; L["Macros"]; L["World Map"];
    L["Quest Log"]; L["Reputation"]; L["PVP Score"]; L["Skills"];
  };

  buttonKeys.Skills = L["Skills"];

  if (tk:IsWrathClassic()) then
    table.insert(C_ChatModule.Static.ButtonNames, 8, L["Achievements"]);
    table.insert(C_ChatModule.Static.ButtonNames, 9, L["Glyphs"]);
    table.insert(C_ChatModule.Static.ButtonNames, 10, L["Calendar"]);
    table.insert(C_ChatModule.Static.ButtonNames, 11, L["Currency"]);
    table.insert(C_ChatModule.Static.ButtonNames, 12, L["LFG"]);

    buttonKeys.Currency = L["Currency"];
    buttonKeys.Achievements = L["Achievements"];
    buttonKeys.Glyphs = L["Glyphs"];
    buttonKeys.Calendar = L["Calendar"];
    buttonKeys.LFG = L["LFG"];
  end
else
  C_ChatModule.Static.ButtonNames = {
    L["Character"]; L["Friends"]; L["Guild"]; L["Help Menu"];
    L["Main Menu"]; L["Store"]; L["PVP"]; L["Player Spells"];
    L["Professions"]; L["Achievements"]; L["Quest Log"]; L["Calendar"];
    L["Dungeon Finder"]; L["Adventure Guide"]; L["Collections Journal"];
    L["Macros"]; L["World Map"]; L["Reputation"]; L["PVP Score"]; L["Currency"];
  };

  buttonKeys.PVP = L["PVP"];
  buttonKeys.Achievements = L["Achievements"];
  buttonKeys.Calendar = L["Calendar"];
  buttonKeys.PlayerSpells = L["Player Spells"];
  buttonKeys.Professions = L["Professions"];
  buttonKeys.DungeonFinder = L["Dungeon Finder"];
  buttonKeys.AdventureGuide = L["Adventure Guide"];
  buttonKeys.LFD = L["LFD"];
  buttonKeys.Currency = L["Currency"];
  buttonKeys.EncounterJournal = L["Encounter Journal"];
  buttonKeys.CollectionsJournal = L["Collections Journal"];
end

local clickHandlers = {};

local function ClickButton(button)
  if (obj:IsString(button)) then
    button = _G[button];
  end

  if (obj:IsWidget(button) and obj:IsFunction(button.Click)) then
    button:Click();
    return true;
  end

  return false;
end

local function ClickAnyButton(...)
  for _, button in obj:IterateArgs(...) do
    if (ClickButton(button)) then
      return true;
    end
  end

  return false;
end

local function SafeToggleFrame(frame)
  if (obj:IsWidget(frame) and obj:IsFunction(_G.ToggleFrame)) then
    pcall(_G.ToggleFrame, frame);
    return true;
  end

  return false;
end

local function CallGlobal(funcName, ...)
  local func = _G[funcName];

  if (obj:IsFunction(func)) then
    local ok = pcall(func, ...);
    return ok;
  end

  return false;
end

local function SafeLoadAddOn(addOnName)
  if (obj:IsFunction(LoadAddOn) and obj:IsString(addOnName)) then
    local ok = pcall(LoadAddOn, addOnName);
    return ok;
  end

  return false;
end

local function OpenMountJournal()
  if (not _G.CollectionsJournal and obj:IsFunction(LoadAddOn)) then
    SafeLoadAddOn("Blizzard_Collections");
  end

  if (obj:IsFunction(_G.ToggleCollectionsJournal)) then
    local ok = pcall(_G.ToggleCollectionsJournal, 1);
    if (ok and obj:IsWidget(_G.MountJournal)) then
      return true;
    end
  end

  if (obj:IsWidget(_G.CollectionsJournal)) then
    if (obj:IsFunction(_G.ShowUIPanel)) then
      pcall(_G.ShowUIPanel, _G.CollectionsJournal);
    end

    if (obj:IsFunction(_G.CollectionsJournal_SetTab)) then
      local ok = pcall(_G.CollectionsJournal_SetTab, _G.CollectionsJournal, 1);
      if (ok) then
        return true;
      end
    end
  end

  if (ClickAnyButton("MountJournalTab")) then
    return true;
  end

  if (obj:IsWidget(_G.MountJournal) and obj:IsFunction(_G.ShowUIPanel)) then
    local ok = pcall(_G.ShowUIPanel, _G.MountJournal);
    if (ok) then
      return true;
    end
  end

  return false;
end

-- Character
clickHandlers[buttonKeys.Character] = function()
  if (not CallGlobal("ToggleCharacter", "PaperDollFrame")) then
    tk:Print("This feature is currently unavailable.");
  end
end

-- Bags
clickHandlers[buttonKeys.Bags] = function()
  local frame = _G.ContainerFrame1;

  if (obj:IsFunction(_G.ToggleAllBags)) then
    _G.ToggleAllBags();
  else
    if (obj:IsWidget(frame) and frame:IsVisible()) then
      (_G.CloseAllBags or _G.ToggleBackpack)();
    else
      _G.OpenAllBags();
    end
  end
end

-- Friends
clickHandlers[buttonKeys.Friends] = function()
  if (not CallGlobal("ToggleFriendsFrame", _G.FRIEND_TAB_FRIENDS)) then
    tk:Print("This feature is currently unavailable.");
  end
end

-- Guild
clickHandlers[buttonKeys.Guild] = function()
  if (tk:IsRetail()) then
    if (ClickAnyButton("GuildMicroButton")) then
      return;
    end

    if (not obj:IsWidget(_G.CommunitiesFrame)) then
      SafeLoadAddOn("Blizzard_Communities");
    end

    if (SafeToggleFrame(_G.CommunitiesFrame)) then
      return;
    end

    if (obj:IsFunction(ToggleGuildFrame)) then
      ToggleGuildFrame();
      return;
    end

    tk:Print("This feature is currently unavailable.");
    return;
  end

  if (IsTrialAccount()) then
    tk:Print(L["Starter Edition accounts cannot perform this action."]);
  elseif (IsInGuild()) then
    ToggleGuildFrame();
  else
    tk:Print("You need to be in a guild to perform this action.");
  end
end

-- Help Menu
clickHandlers[buttonKeys.HelpMenu] = function()
  if (not CallGlobal("ToggleHelpFrame")) then
    tk:Print("This feature is currently unavailable.");
  end
end;

-- Main Menu
clickHandlers[buttonKeys.MainMenu] = function()
  if (ClickAnyButton("MainMenuMicroButton")) then
    return;
  end

  if (obj:IsFunction(_G.ToggleGameMenu)) then
    _G.ToggleGameMenu();
    return;
  end

  tk:Print("This feature is currently unavailable.");
end

-- Store
clickHandlers[buttonKeys.Store] = function()
  if (ClickAnyButton("StoreMicroButton")) then
    return;
  end

  tk:Print("This feature is currently unavailable.");
end

if (tk:IsRetail()) then
  -- PVP
  clickHandlers[buttonKeys.PVP] = function()
    local playerLevel = UnitLevel("player") or 0;
    if (playerLevel < 10) then
      tk:Print(L["Requires level 10+ to view the PVP window."]);
    else
      if (not CallGlobal("TogglePVPUI")) then
        tk:Print("This feature is currently unavailable.");
      end
    end
  end
end

local OpenSpellBook;

local function OpenPlayerSpells()
  if (tk:IsRetail()) then
    OpenSpellBook();
    return;
  elseif (obj:IsFunction(_G.ToggleTalentFrame)) then
    local playerLevel = UnitLevel("player") or 0;
    if (playerLevel < SHOW_TALENT_LEVEL) then
      tk:Print(L["Must be level 10 or higher to use Talents."]);
      return;
    end

    _G.ToggleTalentFrame();
    return;
  end

  if (not SafeToggleFrame(_G.SpellBookFrame)) then
    tk:Print("This feature is currently unavailable.");
  end
end

OpenSpellBook = function()
  if (tk:IsRetail()) then
    if (ClickAnyButton("SpellbookMicroButton", "PlayerSpellsMicroButton")) then
      return;
    end

    if (obj:IsFunction(_G.ToggleSpellBook)) then
      _G.ToggleSpellBook(_G.BOOKTYPE_SPELL);
      return;
    end
  end

  if (not SafeToggleFrame(_G.SpellBookFrame)) then
    tk:Print("This feature is currently unavailable.");
  end
end

local function OpenProfessions()
  if (obj:IsFunction(_G.ToggleProfessionsBook)) then
    _G.ToggleProfessionsBook();
    return;
  end

  if (obj:IsFunction(_G.ProfessionsFrame_LoadUI)) then
    _G.ProfessionsFrame_LoadUI();
  end

  if (SafeToggleFrame(_G.ProfessionsFrame) or SafeToggleFrame(_G.TradeSkillFrame)) then
    return;
  end

  tk:Print("This feature is currently unavailable.");
end

-- Player Spells
clickHandlers[buttonKeys.PlayerSpells] = OpenPlayerSpells;

-- Spell Book
clickHandlers[buttonKeys.SpellBook] = tk:IsRetail() and OpenPlayerSpells or OpenSpellBook;

-- Talents
clickHandlers[buttonKeys.Talents] = tk:IsRetail() and OpenPlayerSpells or OpenSpellBook;

-- Professions
clickHandlers[buttonKeys.Professions] = OpenProfessions;

-- Raid
clickHandlers[L["Raid"]] = function()
  if (not CallGlobal("ToggleRaidFrame")) then
    tk:Print("This feature is currently unavailable.");
  end
end;

if (tk:IsRetail() or tk:IsWrathClassic()) then
  -- Achievements
  clickHandlers[buttonKeys.Achievements] = function()
    if (tk:IsRetail() and ClickAnyButton("AchievementMicroButton")) then
      return;
    end

    if (not CallGlobal("ToggleAchievementFrame")) then
      tk:Print("This feature is currently unavailable.");
    end
  end

  -- Calendar
  clickHandlers[buttonKeys.Calendar] = function()
    if (tk:IsRetail() and ClickAnyButton("CalendarMicroButton")) then
      return;
    end

    if (not CallGlobal("ToggleCalendar")) then
      tk:Print("This feature is currently unavailable.");
    end
  end
end

if (tk:IsWrathClassic() and obj:IsNumber(SHOW_INSCRIPTION_LEVEL) and obj:IsFunction(ToggleGlyphFrame)) then
  -- Glyphs
  clickHandlers[buttonKeys.Glyphs] = function()
    if (UnitLevel("player") < SHOW_INSCRIPTION_LEVEL) then
      tk:Print(L["Must be level 10 or higher to use Talents."]);
    else
      if (not CallGlobal("ToggleGlyphFrame")) then
        tk:Print("This feature is currently unavailable.");
      end
    end
  end
end

if (tk:IsWrathClassic()) then
  clickHandlers[buttonKeys.LFG] = function()
    if (not CallGlobal("ToggleLFGParentFrame")) then
      tk:Print("This feature is currently unavailable.");
    end
  end;
end

if (tk:IsRetail()) then
  -- Dungeon Finder
  clickHandlers[buttonKeys.DungeonFinder] = function()
    if (ClickAnyButton("LFDMicroButton")) then
      return;
    end

    if (not CallGlobal("ToggleLFDParentFrame")) then
      tk:Print("This feature is currently unavailable.");
    end
  end

  -- LFD
  clickHandlers[buttonKeys.LFD] = clickHandlers[buttonKeys.DungeonFinder];

  -- Adventure Guide
  clickHandlers[buttonKeys.AdventureGuide] = function()
    if (ClickAnyButton("EJMicroButton")) then
      return;
    end

    if (not CallGlobal("ToggleEncounterJournal")) then
      tk:Print("This feature is currently unavailable.");
    end
  end

  -- Encounter Journal
  clickHandlers[buttonKeys.EncounterJournal] = clickHandlers[buttonKeys.AdventureGuide];

  -- Collections Journal
  clickHandlers[buttonKeys.CollectionsJournal] = function()
    if (OpenMountJournal()) then
      return;
    end

    if (ClickAnyButton("CollectionsMicroButton")) then
      return;
    end

    if (not CallGlobal("ToggleCollectionsJournal")) then
      tk:Print("This feature is currently unavailable.");
    end
  end
end

if (tk:IsWrathClassic() or tk:IsRetail()) then
  -- Currency
    if (buttonKeys.Currency) then
      clickHandlers[buttonKeys.Currency] = function()
      if (not CallGlobal("ToggleCharacter", "TokenFrame")) then
        tk:Print("This feature is currently unavailable.");
      end
    end
  end
end

-- -- Macros
clickHandlers[buttonKeys.Macros] = function()
  if (not obj:IsWidget(MacroFrame)) then
    SafeLoadAddOn("Blizzard_MacroUI");
  end

  if (not SafeToggleFrame(MacroFrame)) then
    tk:Print("This feature is currently unavailable.");
  end
end

-- World Map
clickHandlers[buttonKeys.WorldMap] = function()
  if (not CallGlobal("ToggleWorldMap")) then
    tk:Print("This feature is currently unavailable.");
  end
end;

local function OpenQuests()
  if (tk:IsRetail() and ClickAnyButton("QuestLogMicroButton")) then
    return;
  end

  if (obj:IsFunction(_G.ToggleQuestLog)) then
    _G.ToggleQuestLog();
    return;
  end

  if (not CallGlobal("ToggleWorldMap")) then
    tk:Print("This feature is currently unavailable.");
  end
end

-- Quest Log
clickHandlers[buttonKeys.QuestLog] = OpenQuests;

-- legacy retail label from earlier migration
clickHandlers["Zauber"] = OpenPlayerSpells;
clickHandlers["Player Spells"] = OpenPlayerSpells;
clickHandlers["Spells & Talents"] = OpenPlayerSpells;
clickHandlers["Zauber & Talente"] = OpenPlayerSpells;
clickHandlers["Spell Book"] = OpenPlayerSpells;
clickHandlers["Talents"] = OpenPlayerSpells;
clickHandlers["Zauber Buch"] = OpenPlayerSpells;
clickHandlers["Zauberbuch"] = OpenPlayerSpells;

-- Repuation
clickHandlers[buttonKeys.Reputation] = function()
  if (not CallGlobal("ToggleCharacter", "ReputationFrame")) then
    tk:Print("This feature is currently unavailable.");
  end
end

-- PVP Score
clickHandlers[buttonKeys.PVPScore] = function()
  if (not UnitInBattleground("player")) then
    tk:Print(L["Requires being inside a Battle Ground."]);
  else
    if (not CallGlobal("ToggleWorldStateScoreFrame")) then
      tk:Print("This feature is currently unavailable.");
    end
  end
end

-- Skill
if (buttonKeys.Skills) then
  clickHandlers[buttonKeys.Skills] = function()
    if (not CallGlobal("ToggleCharacter", "SkillFrame")) then
      tk:Print("This feature is currently unavailable.");
    end
  end
end

local function ChatButton_OnClick(self)
  if (InCombatLockdown()) then
    tk:Print(L["Cannot toggle menu while in combat."]);
    return;
  end

  local handler = clickHandlers[self:GetText()];

  if (obj:IsFunction(handler)) then
    handler();
  else
    tk:Print("This feature is currently unavailable.");
  end
end

local function ChatFrame_OnModifierStateChanged(_, _, data)
  if (data.chatModuleSettings.swapInCombat or not InCombatLockdown()) then
    for _, buttonStateData in ipairs(data.settings.buttons) do
      if (not buttonStateData.key or tk:IsModComboActive(buttonStateData.key)) then
        data.buttons[1]:SetText(buttonStateData[1]);
        data.buttons[2]:SetText(buttonStateData[2]);
        data.buttons[3]:SetText(buttonStateData[3]);
      end
    end
  end
end

obj:DefineParams("table")
function C_ChatFrame:SetUpButtonHandler(data, buttonSettings)
  data.settings.buttons = buttonSettings;

  local listenerID = data.anchorName .. "_OnModifierStateChanged";
  local listener = em:GetEventListenerByID(listenerID);

  if (not listener) then
    listener = em:CreateEventListenerWithID(listenerID,
               ChatFrame_OnModifierStateChanged)
  end

  listener:SetCallbackArgs(data);
  listener:RegisterEvent("MODIFIER_STATE_CHANGED");
  em:TriggerEventListenerByID(listenerID);

  data.buttons[1]:SetScript("OnClick", ChatButton_OnClick);
  data.buttons[2]:SetScript("OnClick", ChatButton_OnClick);
  data.buttons[3]:SetScript("OnClick", ChatButton_OnClick);

  for buttonID = 1, 3 do
    local button = data.buttons[buttonID];
    if (obj:IsWidget(button)) then
      button:Enable();
      button:Show();
    end
  end
end
