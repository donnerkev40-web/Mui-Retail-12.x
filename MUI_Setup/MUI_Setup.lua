-- luacheck: ignore MayronUI self 143 631
local _, namespace = ...;
namespace.import = {};

local _G = _G;
local MayronUI, table, pairs = _G.MayronUI, _G.table, _G.pairs;
local tk, db, _, gui, obj, L = MayronUI:GetCoreComponents();
local Private = {};
local mediaFolder = "Interface\\AddOns\\MUI_Setup\\media\\";

local tabText = {
  -- This should use the locales!
  L["INSTALL"]; L["INFORMATION"]; L["CREDITS"];
};

local RELOAD_MESSAGE = tk.Strings:SetTextColorByTheme(L["Warning:"]).." "..L["This will reload the UI!"];

local tabNames = {
  [L["INSTALL"]] = "Install";
  [L["INFORMATION"]] = "Info";
  [L["CREDITS"]] = "Credits";
};

local PlaySoundFile, SetCVar, SetChatWindowSize, UIFrameFadeIn, C_Timer,
      UIFrameFadeOut, PlaySound, IsAddOnLoaded, unpack, math, GetAddOnMetadata, string =
  _G.PlaySoundFile, _G.SetCVar, _G.SetChatWindowSize, _G.UIFrameFadeIn, _G.C_Timer, _G.UIFrameFadeOut,
  _G.PlaySound, _G.IsAddOnLoaded, _G.unpack, _G.math, _G.GetAddOnMetadata, _G.string;

local ipairs, strsplit, strjoin, strtrim, ReloadUI, DisableAddOn = _G.ipairs,
  _G.strsplit, _G.strjoin, _G.strtrim, _G.ReloadUI, _G.DisableAddOn;

local function SuppressFreshInstallTutorials()
  local version = GetAddOnMetadata("MUI_Core", "Version");

  if (obj:IsTable(db.profile)) then
    db.profile.installMessage = version;

    if (obj:IsTable(db.profile.actionbars)
        and obj:IsTable(db.profile.actionbars.bottom)) then
      db.profile.actionbars.bottom.tutorial = version;
    end
  end
end

-- Setup Objects -------------------------

local Panel = obj:Import("MayronUI.Panel");
local WindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");
local LayoutDefaults = obj:Import("MayronUI.Setup.LayoutDefaults");
local ProfileTemplates = obj:Import("MayronUI.Setup.ProfileTemplates");
local LayoutManager = obj:Import("MayronUI.LayoutManager");
local FeatureRegistry = obj:Import("MayronUI.FeatureRegistry");
local ChatMigrations = obj:Import("MayronUI.ChatModule.Migrations");

-- Register and Import Modules -----------

local SetUpModule = MayronUI:RegisterModule("SetUpModule", L["Setup"]);
local module = MayronUI:ImportModule("SetUpModule");

-- Local Functions -----------------------

local function ChangeTheme(_, classFileName)
  if (classFileName) then
    tk:UpdateThemeColor(classFileName);
  elseif (db.profile.theme) then
    local value = db.profile.theme.color:GetUntrackedTable();
    tk:UpdateThemeColor(value);
  else
    return
  end

  local window = module:GetWindow();
  local r, g, b = tk:GetThemeColor();
  local frame = window:GetFrame()--[[@as MayronUI.GridTextureMixin|table]];
  tk:ApplyThemeColor(frame.titleBar.bg, frame.closeBtn);
  tk:ApplyThemeColor(0.5, unpack(window.tabs));

  local instalDialogBox = window.tabDialogBox["Install"];

  if (instalDialogBox) then
    if (instalDialogBox.themeDropdown and instalDialogBox.themeDropdown.ApplyThemeColor) then
      instalDialogBox.themeDropdown:ApplyThemeColor();
    end

    if (instalDialogBox.layoutDropdown and instalDialogBox.layoutDropdown.ApplyThemeColor) then
      instalDialogBox.layoutDropdown:ApplyThemeColor();
    end

    if (instalDialogBox.profilePerCharacter and instalDialogBox.profilePerCharacter.ApplyThemeColor) then
      instalDialogBox.profilePerCharacter:ApplyThemeColor();
    end

    if (instalDialogBox.installButton and instalDialogBox.installButton.ApplyThemeColor) then
      instalDialogBox.installButton:ApplyThemeColor();
    end

    RELOAD_MESSAGE = tk.Strings:SetTextColorByTheme(L["Warning:"]).." "..L["This will reload the UI!"];
    instalDialogBox.message:SetText(RELOAD_MESSAGE);
  end

  for _, tabName in pairs(tabNames) do
    local menu = window.tabDialogBox[tabName];
    if (menu and menu.scrollBar) then
      menu.scrollBar.thumb:SetColorTexture(r, g, b);
    end
  end
end

-- first argument is the dropdown menu self reference
local function ApplyRetailChatButtonDefaults()
  LayoutDefaults:ApplyRetailChatButtonDefaults();
end

local function GetUniversalWindowType(windowSettings)
  if (not obj:IsTable(windowSettings)) then
    return "empty";
  end

  if (windowSettings.enabled == false) then
    return "empty";
  end

  return WindowTypes.NormalizeWindowType(windowSettings, "chat");
end

local function ApplyUniversalWindowDefaults()
  LayoutDefaults:ApplyUniversalWindowDefaults();

  if (obj:IsTable(db.profile.chat)) then
    local chatSettings = db.profile.chat:GetUntrackedTable();

    if (obj:IsTable(chatSettings)) then
      chatSettings.iconsAnchor = "BOTTOMLEFT";
    end
  end
end

local function EnsureDefaultExternalAddOnProfiles()
  -- Fresh installs must not rely on an existing WTF folder. The setup owns
  -- the canonical external profile bindings per layout and writes them here.
  for _, layoutName in ipairs(ProfileTemplates:GetSupportedLayouts()) do
    local externalProfiles = ProfileTemplates:GetExternalProfiles(layoutName);
    local layoutData = LayoutManager:GetLayoutData(layoutName);

    for addOnName, profileName in pairs(externalProfiles) do
      layoutData[addOnName] = profileName;
    end
  end
end

local function ApplyMinimalFeaturePreset()
  if (not obj:IsTable(db.profile)) then
    return;
  end

  db.profile.features = tk.Tables:Copy(FeatureRegistry:GetDefaults(), true);
  db.profile.features.coreui.mainContainer = true;
  db.profile.features.actionbars.enabled = true;
  db.profile.features.actionbars.bottomBars = true;
  db.profile.features.actionbars.sideBars = true;
  db.profile.features.castBars.enabled = true;
  db.profile.features.castBars.frames = true;
  db.profile.features.castBars.anchors = true;
  db.profile.features.castBars.style = true;
  db.profile.features.chat.enabled = true;
  db.profile.features.chat.windowShell = true;
  db.profile.features.chat.windowLayout = true;
  db.profile.features.chat.sideIcons = true;
  db.profile.features.chat.buttons = true;
  db.profile.features.chat.blizzardFrames = true;
  db.profile.features.chat.universal.enabled = false;
  db.profile.features.chat.universal.host = false;
  db.profile.features.chat.universal.visibility = false;
  db.profile.features.chat.universal.providers.kalielsTracker = false;
  db.profile.features.chat.universal.providers.moneyLooter = false;
  db.profile.features.chat.universal.providers.damageMeter = false;
  db.profile.features.chat.universal.providers.zygorGuides = false;
  db.profile.features.minimap.enabled = true;
  db.profile.features.minimap.buttons = true;
  db.profile.features.minimap.widgets = true;
  db.profile.features.minimap.layout = true;
  db.profile.features.resourceBars.enabled = true;
  db.profile.features.timerBars.enabled = true;
  db.profile.features.timerBars.frames = true;
  db.profile.features.timerBars.anchors = true;
  db.profile.features.unitPanels.enabled = true;
  db.profile.features.datatext.enabled = true;

  -- Keep the active core modules enabled on fresh installs as well.
  db.profile.actionbars.bottom.enabled = true;
  db.profile.actionbars.side.enabled = true;
  db.profile.resourceBars.enabled = true;
  db.profile.resourceBars.experienceBar.enabled = true;
  db.profile.resourceBars.reputationBar.enabled = true;
  db.profile.unitPanels.enabled = true;
  db.profile.unitPanels.unitNames.enabled = true;
  db.profile.unitPanels.sufGradients.enabled = true;
  db.profile.castBars.enabled = true;
  db.profile.chat.enabled = true;
  db.profile.chat.chatFrames.BOTTOMLEFT.enabled = true;
  db.profile.minimap.enabled = true;
end

local function ForceExternalProfilesForLayout(layoutName)
  local layoutData = LayoutManager:GetLayoutData(layoutName);
  local timerBarsProfile = obj:IsTable(layoutData) and layoutData["MUI TimerBars"];

  if (obj:IsString(timerBarsProfile)) then
    local timerBarsDb = tk.Tables:GetDBObject("MUI TimerBars");

    if (timerBarsDb and obj:IsFunction(timerBarsDb.SetProfile)) then
      pcall(function()
        timerBarsDb:SetProfile(timerBarsProfile);
      end);
    end
  end

  local bartenderProfile = obj:IsTable(layoutData) and layoutData["Bartender4"];
  if (obj:IsString(bartenderProfile)
      and _G.Bartender4
      and obj:IsTable(_G.Bartender4.db)
      and obj:IsFunction(_G.Bartender4.db.SetProfile)) then
    pcall(function()
      _G.Bartender4.db:SetProfile(bartenderProfile);
    end);
  end

  local shadowUfProfile = obj:IsTable(layoutData) and layoutData["ShadowUF"];
  if (obj:IsString(shadowUfProfile)
      and _G.ShadowUF
      and obj:IsTable(_G.ShadowUF.db)
      and obj:IsFunction(_G.ShadowUF.db.SetProfile)) then
    pcall(function()
      _G.ShadowUF.db:SetProfile(shadowUfProfile);
    end);

    if (_G.ShadowUF.modules and _G.ShadowUF.modules.movers) then
      pcall(function()
        _G.ShadowUF.db.profile.locked = true;
        _G.ShadowUF.modules.movers.isConfigModeSpec = nil;
        _G.ShadowUF.modules.movers:Disable();
        _G.ShadowUF.modules.movers:Update();
      end);
    end
  end

  local grid2Profile = obj:IsTable(layoutData) and layoutData["Grid2"];
  if (obj:IsString(grid2Profile)
      and _G.Grid2
      and obj:IsTable(_G.Grid2.db)
      and obj:IsFunction(_G.Grid2.db.SetProfile)) then
    pcall(function()
      _G.Grid2.db:SetProfile(grid2Profile);
    end);
  end
end

local function GetImportFunctionForAddOn(addonName)
  local importFunc = namespace.import[addonName];

  if (tk:IsRetail() and addonName == "Bartender4") then
    importFunc = namespace.import[addonName.."-Dragonflight"];
  end

  return importFunc;
end

local function GetSelectedInstallLayout()
  local layoutName = db.global.core.setup.defaultLayout;

  if (layoutName ~= "Healer") then
    layoutName = "DPS";
  end

  return layoutName;
end

local function SetSelectedInstallLayout(_, layoutName)
  if (layoutName ~= "Healer") then
    layoutName = "DPS";
  end

  db.global.core.setup.defaultLayout = layoutName;
end

local function AddLayoutSelection(tabFrame, anchor, relativePoint, x, y)
  tabFrame.layoutTitle = tabFrame.layoutTitle or tabFrame:CreateFontString(
    nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.layoutTitle:SetPoint("TOPLEFT", anchor, relativePoint, x or 0, y or 0);
  tabFrame.layoutTitle:SetText(L["Layout"] .. ":");

  tabFrame.layoutDropdown = tabFrame.layoutDropdown or gui:CreateDropDown(tabFrame);
  tabFrame.layoutDropdown:SetPoint("TOPLEFT", tabFrame.layoutTitle, "BOTTOMLEFT", 0, -10);
  tabFrame.layoutDropdown:SetWidth(200);
  tabFrame.layoutDropdown:SetLabel(GetSelectedInstallLayout());

  if (tabFrame.layoutDropdown:GetNumOptions() == 0) then
    tabFrame.layoutDropdown:AddOption("DPS", SetSelectedInstallLayout, "DPS");
    tabFrame.layoutDropdown:AddOption("Healer", SetSelectedInstallLayout, "Healer");
  end
end

local function ExpandSetupWindow()
  local window = module:GetWindow();
  local width, height = window:GetSize();

  if (width >= 900 and height >= 540) then
    return
  end

  window:SetSize(width + 20, height + 12);
  C_Timer.After(0.02, ExpandSetupWindow);
end

local function OnMenuTabButtonClick(self)
  local window = module:GetWindow();
  local dialogFrame = window.tabDialogBox --[[@as MayronUI.GridTextureMixin]]; -- the tab wrapper frame with the dialog box texture

  if (self:GetChecked()) then
    if (dialogFrame.activeTabChildFrame) then
      dialogFrame.activeTabChildFrame:Hide();
    end

    local tabName = tabNames[self:GetText()];
    if (not dialogFrame[tabName]) then
      local tabContentFrame = tk:CreateFrame("Frame", dialogFrame);
      tabContentFrame:SetAllPoints(true);
      dialogFrame[tabName] = Private["Load" .. tabName .. "Menu"](Private, tabContentFrame);
    end

    dialogFrame[tabName]:Show();
    dialogFrame.activeTabChildFrame = dialogFrame[tabName];

    if (not window.expanded) then
      C_Timer.After(0.02, ExpandSetupWindow);
      dialogFrame:SetGridBlendMode("BLEND");
      UIFrameFadeIn(dialogFrame, 0.4, dialogFrame:GetAlpha(), 1);
      UIFrameFadeOut(window.banner.left, 0.4, window.banner.left:GetAlpha(), 0.3);
      UIFrameFadeOut(window.banner.right, 0.4, window.banner.right:GetAlpha(), 0.3);
      window.expanded = true;
    end
  end

  PlaySound(tk.Constants.CLICK);
end

-- Private Functions ---------------------------

function Private:LoadInstallMenu(tabFrame)
  local leftX = 30;
  local rightX = 320;

  self:LoadThemeMenu(tabFrame);
  tabFrame.themeTitle:ClearAllPoints();
  tabFrame.themeTitle:SetPoint("TOPLEFT", leftX, -28);
  tabFrame.themeTitle:SetText(L["Installer Theme Header"]);

  tabFrame.themeDropdown:ClearAllPoints();
  tabFrame.themeDropdown:SetPoint("TOPLEFT", tabFrame.themeTitle, "BOTTOMLEFT", 0, -10);
  tabFrame.themeDropdown:SetWidth(220);
  tabFrame.themeDropdown:SetLabel(L["Theme"]);

  tabFrame.layoutHeader = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.layoutHeader:SetPoint("TOPLEFT", tabFrame.themeDropdown:GetFrame(), "BOTTOMLEFT", 0, -28);
  tabFrame.layoutHeader:SetText(L["Installer Layout Header"]);

  AddLayoutSelection(tabFrame, tabFrame.layoutHeader, "BOTTOMLEFT", 0, -10);
  tabFrame.layoutTitle:ClearAllPoints();
  tabFrame.layoutTitle:SetPoint("TOPLEFT", tabFrame.layoutHeader, "BOTTOMLEFT", 0, -10);
  tabFrame.layoutTitle:SetText(L["Layout"]);
  tabFrame.layoutDropdown:SetWidth(220);

  tabFrame.optionsHeader = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.optionsHeader:SetPoint("TOPLEFT", tabFrame.layoutDropdown:GetFrame(), "BOTTOMLEFT", 0, -28);
  tabFrame.optionsHeader:SetText(L["Installer Options Header"]);

  tabFrame.profilePerCharacter = gui:CreateCheckButton(
    tabFrame, L["Profile Per Character"],
    L["If enabled, new characters will be assigned a unique character profile instead of the Default profile."]);
  tabFrame.profilePerCharacter:SetPoint(
    "TOPLEFT", tabFrame.optionsHeader, "BOTTOMLEFT", 0, -10);
  tabFrame.profilePerCharacter.btn:SetChecked(db.global.core.setup.profilePerCharacter);
  tabFrame.profilePerCharacter.btn:SetScript("OnClick", function(self)
    db:SetPathValue("global.core.setup.profilePerCharacter", self:GetChecked());
  end);

  tabFrame.installSummary = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
  tabFrame.installSummary:SetPoint("TOPLEFT", tabFrame.profilePerCharacter, "BOTTOMLEFT", 0, -18);
  tabFrame.installSummary:SetWidth(230);
  tabFrame.installSummary:SetJustifyH("LEFT");
  tabFrame.installSummary:SetText(L["Installer Minimal Summary"]);

  tabFrame.installButton = gui:CreateButton(tabFrame, L["INSTALL"], nil, nil, nil, 200);
  tabFrame.installButton:SetPoint("TOPLEFT", tabFrame.installSummary, "BOTTOMLEFT", 0, -28);
  tabFrame.installButton:SetScript("OnClick", function() module:Install(); end);

  tabFrame.installTitle = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.installTitle:SetPoint("TOPLEFT", rightX, -28);
  tabFrame.installTitle:SetWidth(250);
  tabFrame.installTitle:SetJustifyH("LEFT");
  tabFrame.installTitle:SetText(L["Installer Quick Start"]);

  tabFrame.description = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
  tabFrame.description:SetPoint("TOPLEFT", tabFrame.installTitle, "BOTTOMLEFT", 0, -10);
  tabFrame.description:SetWidth(250);
  tabFrame.description:SetJustifyH("LEFT");
  tabFrame.description:SetText(L["Installer Quick Start Description"]);

  tabFrame.hintTitle = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.hintTitle:SetPoint("TOPLEFT", tabFrame.description, "BOTTOMLEFT", 0, -28);
  tabFrame.hintTitle:SetText(L["Hint"]);

  tabFrame.message = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
  tabFrame.message:SetPoint("TOPLEFT", tabFrame.hintTitle, "BOTTOMLEFT", 0, -10);
  tabFrame.message:SetWidth(250);
  tabFrame.message:SetJustifyH("LEFT");
  tabFrame.message:SetText(RELOAD_MESSAGE .. "\n\n" .. L["Installer Secondary Layout Hint"]);
  return tabFrame;
end

function Private:LoadThemeMenu(tabFrame)
  tabFrame.themeTitle = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  tabFrame.themeTitle:SetPoint("TOPLEFT", 20, -20);
  tabFrame.themeTitle:SetText(L["Choose Theme:"]);

  tabFrame.themeDropdown = gui:CreateDropDown(tabFrame);
  local classFileNames = tk.Tables:GetKeys(tk.Constants.CLASS_FILE_NAMES);
  table.sort(classFileNames);

  local optionsTable = obj:PopTable();
  for _, classFileName in ipairs(classFileNames) do
    local text = tk:GetLocalizedClassNameByFileName(classFileName, true);
    local option = obj:PopTable(text, classFileName);
    table.insert(optionsTable, option);
  end

  obj:PushTable(classFileNames);

  tabFrame.themeDropdown:AddOptions(ChangeTheme, optionsTable);

  tabFrame.themeDropdown:SetLabel(L["Theme"]);
  tabFrame.themeDropdown:SetPoint("TOPLEFT", tabFrame.themeTitle, "BOTTOMLEFT", 0, -10);
end

function Private:LoadInfoMenu(scrollChild)
  local font = tk:GetMasterFont();

  local scrollFrame, scrollBar = gui:WrapInScrollFrame(scrollChild);
  scrollChild.scrollBar = scrollBar;

  scrollChild:SetHeight(300);
  scrollFrame:SetPoint("TOPLEFT", 20, -20);
  scrollFrame:SetPoint("BOTTOMRIGHT", -20, 20);

  scrollFrame.bg = tk:SetBackground(scrollFrame, 0, 0, 0, 0.5);
  scrollFrame.bg:ClearAllPoints();
  scrollFrame.bg:SetPoint("TOPLEFT", -10, 10);
  scrollFrame.bg:SetPoint("BOTTOMRIGHT", 10, -10);

  local content = tk:CreateFrame("EditBox", scrollChild);
  content:SetMultiLine(true);
  content:SetMaxLetters(99999);
  content:EnableMouse(true);
  content:SetAutoFocus(false);
  content:SetFontObject("GameFontHighlight");
  content:SetFont(font, 13, "");
  content:SetAllPoints(true);
  content:SetText(Private.info);

  content:SetScript("OnEscapePressed", function(self)
    self:ClearFocus();
  end);

  content:SetScript("OnTextChanged", function(self)
    self:SetText(Private.info);
  end);

  return scrollFrame;
end

function Private:LoadCreditsMenu(scrollChild)
  local font = tk:GetMasterFont();

  local scrollFrame, scrollBar = gui:WrapInScrollFrame(scrollChild);
  scrollChild.scrollBar = scrollBar;

  scrollChild:SetHeight(700); -- can't use GetStringHeight
  scrollFrame:SetPoint("TOPLEFT", 20, -20);
  scrollFrame:SetPoint("BOTTOMRIGHT", -20, 20);

  scrollFrame.bg = tk:SetBackground(scrollFrame, 0, 0, 0, 0.5);
  scrollFrame.bg:ClearAllPoints();
  scrollFrame.bg:SetPoint("TOPLEFT", -10, 10);
  scrollFrame.bg:SetPoint("BOTTOMRIGHT", 10, -10);

  local content = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  content:SetWordWrap(true);
  content:SetAllPoints(true);
  content:SetJustifyH("LEFT");
  content:SetJustifyV("TOP");
  content:SetText(Private.credits);
  content:SetFont(font, 13); -- font size should be added to config and profile
  content:SetSpacing(6);

  return scrollFrame;
end

-- C_SetUpModule -----------------------
local function GetInfoLinks(...)
  local links = obj:PopTable(...);

  for i, name in ipairs(links) do
    links[i] = ("|cffffff9a%s|r"):format(GetAddOnMetadata("MUI_Core", name));
  end

  return obj:UnpackTable(links);
end

local function GetCreditsSections(...)
  local sections = obj:PopTable(...);

  for s, sectionName in ipairs(sections) do
    local names = (GetAddOnMetadata("MUI_Core", sectionName));
    names = obj:PopTable(strsplit(",", names))

    for i, name in ipairs(names) do
      names[i] = string.format(
        "|TInterface\\Challenges\\ChallengeMode_Medal_Gold:18:18:0:-4|t %s",
          strtrim(name));
    end

    sections[s] = strjoin("\n", unpack(names));
    obj:PushTable(names);
  end

  return obj:UnpackTable(sections);
end

function SetUpModule:OnInitialize()
  self:Show();
end

function SetUpModule:Show(data)
  if (_G.InCombatLockdown()) then
    tk:Print(L["Cannot install while in combat."]);

    if (data.window) then
      data.window:Hide();
    end

    return
  end

  if (data.window) then
    data.window:Show();
    UIFrameFadeIn(data.window, 0.3, 0, 1);
    return
  end

  Private.info = L["MUI_Setup_InfoTab"]:format(
    GetInfoLinks("X-Discord", "X-Home-Page", "X-GitHub-Repo", "X-Patreon", "X-YouTube"));

  Private.credits = L["MUI_Setup_CreditsTab"]:format(
    GetCreditsSections(
      "X-Patrons", "X-Development-and-Bug-Fixes",
      "X-Translation-Support", "X-Community-Support-Team"));

  local windowFrame = tk:CreateFrame("Frame", nil, "MUI_Setup");
  local window = gui:AddDialogTexture(windowFrame, "High");
  window:SetSize(750, 485);
  window:SetPoint("CENTER");
  window:SetFrameStrata("DIALOG");
  window:RegisterEvent("PLAYER_REGEN_DISABLED");
  window:SetScript("OnEvent", function(self)
    self:Hide();
    tk:Print(L["Cannot install while in combat."]);
  end);

  if (tk:IsLocale("itIT")) then
    window:SetSize(900, 582);
  end

  gui:AddTitleBar(window, L["Setup Menu"]);
  gui:AddCloseButton(window);

  window.bg = tk:SetBackground(window, 0, 0, 0, 0.8); -- was 0.8 but set to 0.2 for testing
  window.bg:SetDrawLayer("BACKGROUND", -5);
  window.bg:SetAllPoints(_G.UIParent);

  -- turn window frame into a Panel
  window = Panel(window);
  window:SetDevMode(false); -- shows or hides panel cell backgrounds used for arranging content
  window:SetDimensions(1, 3);
  window:GetRow(1):SetFixed(60);
  window:GetRow(3):SetFixed(70);
  window.menu = window:CreateCell();
  window.menu:SetInsets(25, 8, 8, 8);

  window.banner = window:CreateCell();
  window.banner:SetInsets(4, 4);

  local bannerFrame = window.banner:GetFrame();

  window.banner.left = window.banner:CreateTexture(nil, "OVERLAY");
  window.banner.left:SetTexture(mediaFolder.."banner-left");
  window.banner.left:SetPoint("TOPLEFT", -4, 0);
  window.banner.left:SetPoint("BOTTOMLEFT", -4, 0);
  window.banner.left:SetPoint("RIGHT", bannerFrame, "CENTER");

  window.banner.right = window.banner:CreateTexture(nil, "OVERLAY");
  window.banner.right:SetTexture(mediaFolder.."banner-right");
  window.banner.right:SetPoint("TOPRIGHT", 4, 0);
  window.banner.right:SetPoint("BOTTOMRIGHT", 4, 0);
  window.banner.right:SetPoint("LEFT", bannerFrame, "CENTER");

  window.info = window:CreateCell();
  window.info:SetInsets(15, 20);

  local title = window.info:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge");
  title:SetText("MAYRONUI");
  title:SetPoint("TOPLEFT");
  tk:SetFontSize(title, 22);

  local version = window.info:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
  local currentVersion = GetAddOnMetadata("MUI_Core", "Version") or GetAddOnMetadata("MUI_Setup", "Version") or "UNKNOWN";
  version:SetText(L["VERSION"].." "..currentVersion);
  version:SetPoint("TOPLEFT");
  version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 2, 0);
  tk:SetFontSize(version, 12);

  local frame = tk:CreateFrame("Frame", bannerFrame);
  window.tabDialogBox = gui:AddDialogTexture(frame, nil, 15);
  window.tabDialogBox:SetGridAlphaType("None");
  window.tabDialogBox:SetPoint("TOPLEFT", 0, -5);
  window.tabDialogBox:SetPoint("BOTTOMRIGHT", 0, 5);

  -- menu buttons:
  local tabs = {};

  for i, text in ipairs(tabText) do
    local tab = tk:CreateFrame("CheckButton", window.menu:GetFrame(), ("MUI_SetupTab%d"):format(i));
    tab:SetNormalFontObject("GameFontHighlight");
    tab:SetText(text);
    tab:SetCheckedTexture(1);
    tab:SetHighlightTexture(1);
    tab:GetFontString():SetDrawLayer("OVERLAY")
    tab:SetSize(tab:GetFontString():GetWidth() + 50, 30);
    tab:SetScript("OnClick", OnMenuTabButtonClick);

    if (i == 1) then
      tab:SetPoint("LEFT");
    else
      tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", 30, 0);
    end

    tabs[i] = tab;
  end

  tk:ApplyThemeColor(0.5, unpack(tabs));
  tk:GroupCheckButtons(tabs, false);

  window:AddCells(window.menu, window.banner, window.info);
  data.window = window;
  data.window.tabs = tabs;
  UIFrameFadeIn(data.window, 0.3, 0, 1);
end

local function ApplyMayronUIConsoleVariableDefaults()
  SetCVar("ScriptErrors", "1");
  SetCVar("chatStyle", "classic");
  SetCVar("chatClassColorOverride", "0"); -- chat class colors
  SetCVar("floatingCombatTextCombatDamage", "1");
  SetCVar("floatingCombatTextCombatHealing", "1");
  SetCVar("nameplateMaxDistance", 41);
  SetCVar("useUiScale", "1");
  SetCVar("uiscale", db.global.core.uiScale);
end

local ApplyMayronUIChatFrameDefaults;
do
  local FCF_ResetChatWindows = _G.FCF_ResetChatWindows;
  local VoiceTranscriptionFrame_UpdateVisibility = _G.VoiceTranscriptionFrame_UpdateVisibility;
  local VoiceTranscriptionFrame_UpdateVoiceTab = _G.VoiceTranscriptionFrame_UpdateVoiceTab;
  local VoiceTranscriptionFrame_UpdateEditBox = _G.VoiceTranscriptionFrame_UpdateEditBox;
  local FCF_StopDragging = _G.FCF_StopDragging;
  local ToggleChatColorNamesByClassGroup = _G.ToggleChatColorNamesByClassGroup;
  local CHAT_CONFIG_CHAT_LEFT = _G.CHAT_CONFIG_CHAT_LEFT;
  local FCF_SetLocked = _G.FCF_SetLocked;
  local EditModeManagerFrame = _G.EditModeManagerFrame;
  local FCF_SetWindowName = _G.FCF_SetWindowName;
  local FCF_SetWindowColor = _G.FCF_SetWindowColor;
  local FCF_SetWindowAlpha = _G.FCF_SetWindowAlpha;
  local C_EditMode = _G.C_EditMode;

  local function GetPresetLayoutInfo()
    local layouts = EditModeManagerFrame:GetLayouts();

    for _, layoutInfo in ipairs(layouts) do
      if (layoutInfo.layoutType == 0) then
        return layoutInfo;
      end
    end

    return layouts[1];
  end

  local function GetMayronUILayoutIndex()
    local layoutsInfo = EditModeManagerFrame:GetLayouts();

    for index, layoutInfo in ipairs(layoutsInfo) do
      if (layoutInfo.layoutName == "MayronUI") then
        return index;
      end
    end

    return 0;
  end

  local function SetHighestLayoutIndexByType(layoutType)
    local layouts = EditModeManagerFrame:GetLayouts();
    local highest = 0;

    for index, layoutInfo in ipairs(layouts) do
      if (layoutInfo.layoutType == layoutType and highest < index) then
        highest = index;
      end
    end

    EditModeManagerFrame.highestLayoutIndexByType = {};

    if (highest > 0) then
      EditModeManagerFrame.highestLayoutIndexByType[layoutType] = highest;
    end
  end

  local function SetMayronUILayout()
    if (not obj:IsTable(EditModeManagerFrame)
        or not obj:IsFunction(EditModeManagerFrame.GetActiveLayoutInfo)) then
      return;
    end

    local ok, activeLayoutInfo = pcall(EditModeManagerFrame.GetActiveLayoutInfo, EditModeManagerFrame);
    if (not ok or not obj:IsTable(activeLayoutInfo)) then
      return;
    end

    local activeLayoutName = activeLayoutInfo.layoutName;

    if (activeLayoutName ~= "MayronUI") then
      -- check if there is one:
      if (GetMayronUILayoutIndex() == 0) then
        -- create it
        local preset = GetPresetLayoutInfo();
        local newLayoutInfo = tk.Tables:Copy(preset);
        local layoutType = _G.Enum.EditModeLayoutType.Account;
        SetHighestLayoutIndexByType(layoutType);
        local created = pcall(
          EditModeManagerFrame.MakeNewLayout,
          EditModeManagerFrame,
          newLayoutInfo,
          layoutType,
          "MayronUI",
          false
        );

        if (not created) then
          return;
        end
      end

      local muiLayoutIndex = GetMayronUILayoutIndex();
      if (muiLayoutIndex > 0 and obj:IsTable(C_EditMode)
          and obj:IsFunction(C_EditMode.SetActiveLayout)) then
        C_EditMode.SetActiveLayout(muiLayoutIndex);
      end
    end
  end

  function ApplyMayronUIChatFrameDefaults()
    FCF_ResetChatWindows();

    -- Create social
    local socialTab = _G.FCF_OpenNewWindow(_G.SOCIAL_LABEL or "Social");
    _G.ChatFrame_RemoveAllMessageGroups(socialTab);

    for _, group in ipairs({
      "SAY", "WHISPER", "BN_WHISPER", "PARTY", "PARTY_LEADER", "RAID",
      "RAID_LEADER", "RAID_WARNING", "INSTANCE_CHAT",
      "INSTANCE_CHAT_LEADER", "GUILD", "OFFICER", "ACHIEVEMENT",
      "GUILD_ACHIEVEMENT", "COMMUNITIES_CHANNEL", "SYSTEM", "TARGETICONS"
    }) do
      _G.ChatFrame_AddMessageGroup(socialTab, group);
    end

    -- Create Loot
    local lootTab = _G.FCF_OpenNewWindow(_G.LOOT or "Loot");
    _G.ChatFrame_RemoveAllMessageGroups(lootTab);

    for _, group in ipairs({"LOOT", "CURRENCY", "MONEY", "SYSTEM", "COMBAT_FACTION_CHANGE"}) do
      _G.ChatFrame_AddMessageGroup(lootTab, group);
    end

    local editModeIsAvailable = tk:IsRetail() and
      obj:IsTable(EditModeManagerFrame) and
      obj:IsFunction(EditModeManagerFrame.GetActiveLayoutInfo);

    if (editModeIsAvailable) then
      SetMayronUILayout();
    end

    for _, name in ipairs(_G.CHAT_FRAMES) do
      local chatFrame = _G[name];
      local id = chatFrame:GetID();

      SetChatWindowSize(id, 13);
      FCF_SetWindowAlpha(chatFrame, 0);
      FCF_SetWindowColor(chatFrame, 0, 0, 0);

      if (id == 1) then
        FCF_SetLocked(chatFrame, 1); -- required for the older system

        if (not editModeIsAvailable) then
          chatFrame:SetMovable(true);
          chatFrame:SetUserPlaced(true);
          chatFrame:SetClampedToScreen(false);
          chatFrame:ClearAllPoints();

          if (db.profile.chat) then
            if (db.profile.chat.chatFrames["TOPLEFT"].enabled
                and GetUniversalWindowType(db.profile.chat.chatFrames["TOPLEFT"]) == "chat") then
              chatFrame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 34, -55);

            elseif (db.profile.chat.chatFrames["BOTTOMLEFT"].enabled
                and GetUniversalWindowType(db.profile.chat.chatFrames["BOTTOMLEFT"]) == "chat") then
              chatFrame:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", 34, 30);

            elseif (db.profile.chat.chatFrames["TOPRIGHT"].enabled
                and GetUniversalWindowType(db.profile.chat.chatFrames["TOPRIGHT"]) == "chat") then
              chatFrame:SetPoint("TOPRIGHT", _G.UIParent, "TOPRIGHT", -34, -55);

            elseif (db.profile.chat.chatFrames["BOTTOMRIGHT"].enabled
                and GetUniversalWindowType(db.profile.chat.chatFrames["BOTTOMRIGHT"]) == "chat") then
              chatFrame:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", 34, -30);
            end
          end
        end

        chatFrame:SetWidth(375);
        chatFrame:SetHeight(240);

        if (not editModeIsAvailable) then
          FCF_StopDragging(chatFrame); -- for the older system
        end

      elseif (id == 2 and resetChat) then
        FCF_SetWindowName(chatFrame, _G.GUILD_EVENT_LOG or "Log");

      elseif (id == 3) then
        VoiceTranscriptionFrame_UpdateVisibility(chatFrame);
        VoiceTranscriptionFrame_UpdateVoiceTab(chatFrame);
        VoiceTranscriptionFrame_UpdateEditBox(chatFrame);
      end
    end

    if (obj:IsFunction(ToggleChatColorNamesByClassGroup)) then
      for i = 1, _G.MAX_WOW_CHAT_CHANNELS do
        ToggleChatColorNamesByClassGroup(true, "CHANNEL" .. i);
      end

      for _, value in ipairs(CHAT_CONFIG_CHAT_LEFT) do
        if (obj:IsTable(value) and obj:IsString(value.type)) then
          ToggleChatColorNamesByClassGroup(true, value.type);
        end
      end
    end
  end
end

local function ResetMayronUIChatProfileDefaults()
  local defaultChatObserver = db:GetDefault("profile.chat");
  local defaultChat = obj:IsTable(defaultChatObserver)
    and obj:IsFunction(defaultChatObserver.GetUntrackedTable)
    and defaultChatObserver:GetUntrackedTable();

  if (not obj:IsTable(defaultChat)) then
    return;
  end

  db:SetPathValue("profile.chat", tk.Tables:Copy(defaultChat, true));
end

local function ApplyInstalledChatLayoutDefaults(selectedLayout)
  local universalEnabled = obj:IsTable(db.profile.features)
    and obj:IsTable(db.profile.features.chat)
    and obj:IsTable(db.profile.features.chat.universal)
    and db.profile.features.chat.universal.enabled == true;

  if (obj:IsTable(db.profile.chat) and obj:IsTable(db.profile.chat.editBox)) then
    if (selectedLayout == "DPS") then
      db.profile.chat.editBox.position = "TOP";
      db.profile.chat.editBox.yOffset = 8;
    else
      db.profile.chat.editBox.position = "BOTTOM";
      db.profile.chat.editBox.yOffset = -8;
    end
  end

  if (not universalEnabled and obj:IsTable(db.profile.chat)
      and obj:IsTable(db.profile.chat.chatFrames)) then
    for _, anchorName in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMRIGHT" }) do
      local windowSettings = db.profile.chat.chatFrames[anchorName];

      if (obj:IsTable(windowSettings)) then
        windowSettings.enabled = false;
        windowSettings.windowType = "empty";
      end
    end

    if (obj:IsTable(db.profile.chat.chatFrames.BOTTOMLEFT)) then
      db.profile.chat.chatFrames.BOTTOMLEFT.enabled = true;
      db.profile.chat.chatFrames.BOTTOMLEFT.windowType = "chat";
      db.profile.chat.chatFrames.BOTTOMLEFT.xOffset = 2;
      db.profile.chat.chatFrames.BOTTOMLEFT.yOffset = 2;
    end

    db.profile.chat.iconsAnchor = "BOTTOMLEFT";
    db.profile.chat.iconsWindowType = "chat";
    db.profile.chat.universalContent = "none";
    return;
  end

  if (selectedLayout == "DPS") then
    ApplyUniversalWindowDefaults();
    ApplyRetailChatButtonDefaults();

    if (obj:IsTable(db.profile.chat)
        and obj:IsTable(db.profile.chat.chatFrames)) then
      ChatMigrations:ApplyDefaultDPSWindowLayout(
        db.profile.chat.chatFrames,
        db.profile.chat
      );
    end
  else
    if (obj:IsTable(db.profile.chat)
        and obj:IsTable(db.profile.chat.chatFrames)) then
      ChatMigrations:ApplyDefaultHealerWindowLayout(
        db.profile.chat.chatFrames,
        db.profile.chat
      );
    end
  end
end

local function BuildInstalledLayoutProfiles(selectedLayout)
  -- Install into full layout profiles instead of keeping hidden internal
  -- layout snapshots inside one MUI profile.
  selectedLayout = LayoutManager:NormalizeLayoutName(selectedLayout);
  local playerKey = tk:GetPlayerKey();
  local seedProfileName = string.format("__MUIInstallSeed-%s", playerKey);

  local previousSuppressState = MayronUI.__suppressProfileChangeCallback;
  MayronUI.__suppressProfileChangeCallback = true;
  db:ResetProfile(seedProfileName);
  MayronUI.__suppressProfileChangeCallback = previousSuppressState;

  db.profile.layout = "Healer";
  ApplyMinimalFeaturePreset();
  ResetMayronUIChatProfileDefaults();
  ApplyMayronUIConsoleVariableDefaults();
  -- A fresh install should always rebuild the Blizzard chat state so the
  -- active profile and the live chat windows start from the same baseline.
  ApplyMayronUIChatFrameDefaults();
  local targetProfileName = LayoutManager:GetProfileName(selectedLayout);

  if (obj:IsTable(db.profile.actionbars)
      and obj:IsTable(db.profile.actionbars.bottom)
      and obj:IsTable(db.profile.actionbars.bottom.animation)) then
    db.profile.actionbars.bottom.animation.activeSets = 1;
  end

  db.profile.layout = selectedLayout;
  ApplyInstalledChatLayoutDefaults(selectedLayout);

  LayoutManager:CreateOrReplaceProfile(targetProfileName, seedProfileName);
  local activeProfileName = LayoutManager:ActivateLayoutProfile(selectedLayout, seedProfileName);

  -- Re-apply the current MUI chat defaults to the active installed profile so
  -- no previous character/profile state survives the install.
  ResetMayronUIChatProfileDefaults();
  db.profile.layout = selectedLayout;
  ApplyInstalledChatLayoutDefaults(selectedLayout);

  MayronUI.__suppressProfileChangeCallback = true;
  if (db:ProfileExists(seedProfileName)) then
    db:RemoveProfile(seedProfileName);
  end
  MayronUI.__suppressProfileChangeCallback = previousSuppressState;

  return activeProfileName;
end

function SetUpModule:Install(data)
  if (_G.InCombatLockdown()) then
    tk:Print(L["Cannot install while in combat."]);
    data.window:Hide();
    return;
  end

  local selectedLayout = GetSelectedInstallLayout();
  MayronUI.__suppressAutoInstallerOnProfileReset = true;
  BuildInstalledLayoutProfiles(selectedLayout);
  MayronUI.__suppressAutoInstallerOnProfileReset = nil;

  local usedDragonflightLayout = db.global[tk.Constants.DRAGONFLIGHT_BAR_LAYOUT_PATCH];

  -- Export AddOn values to db:
  for id, addonData in db.global.core.setup.addOns:Iterate() do
    local alias, _, addonName = unpack(addonData);

    if (IsAddOnLoaded(addonName)) then
      local importFunc = GetImportFunctionForAddOn(addonName);

      if (obj:IsFunction(importFunc)) then
        local presetVersion = importFunc(selectedLayout);
        db.global.core.setup.addOns[id] = { alias; false; addonName; presetVersion };

        if (tk:IsRetail() and not usedDragonflightLayout and addonName == "Bartender4") then
          db.global[tk.Constants.DRAGONFLIGHT_BAR_LAYOUT_PATCH] = true;
        end
      end
    end
  end

  if (not db.global.installed) then
    -- db.global.installed = db.global.installed or {}; -- won't work (Observer)
    db.global.installed = {};
  end

  db.global.installed[tk:GetPlayerKey()] = true;
  db.profile.freshInstall = true;

  EnsureDefaultExternalAddOnProfiles();
  SuppressFreshInstallTutorials();
  ForceExternalProfilesForLayout(selectedLayout);

  PlaySoundFile("Interface\\AddOns\\MUI_Setup\\install.ogg");
  DisableAddOn("MUI_Setup");
  ReloadUI();
end

function SetUpModule:ImportExternalPreset(addonName, layoutName)
  local importFunc = GetImportFunctionForAddOn(addonName);

  if (not obj:IsFunction(importFunc)) then
    return nil;
  end

  local presetVersion = importFunc(layoutName);

  for id, addonData in db.global.core.setup.addOns:Iterate() do
    if (addonData[3] == addonName) then
      db.global.core.setup.addOns[id] = { addonData[1]; false; addonName; presetVersion };
      break
    end
  end

  return presetVersion;
end

function SetUpModule:GetWindow(data)
  return data.window;
end
