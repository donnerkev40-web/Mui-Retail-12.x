-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, gui, obj, L = MayronUI:GetCoreComponents();
local C_ConfigMenu = MayronUI:GetModuleClass("ConfigMenu"); ---@type ConfigMenuModule
local LayoutManager = obj:Import("MayronUI.LayoutManager");

local ipairs, pairs, sort, strformat, tonumber = _G.ipairs, _G.pairs, _G.table.sort, _G.string.format, _G.tonumber;
local GetCVar, SetCVar = _G.GetCVar, _G.SetCVar;
local CUSTOM_THEME_PRESET = "CUSTOM";
local DEFAULT_THEME_FRAME_COLOR = {
  r = 0.5;
  g = 0.5;
  b = 0.5;
};

local function ApplyGameFonts()
  if (obj:IsTable(db.global) and obj:IsTable(db.global.core) and obj:IsTable(db.global.core.fonts)) then
    tk:SetGameFont(db.global.core.fonts);
  end
end

local function RefreshConfigTheme(skipMenuRefresh)
  local configMenu = MayronUI:ImportModule("ConfigMenu", true);

  if (configMenu and obj:IsFunction(configMenu.RefreshThemeVisuals)) then
    configMenu:RefreshThemeVisuals(skipMenuRefresh);
  end
end

local function GetThemePresetOptions()
  local options = obj:PopTable();
  local classFileNames = tk.Tables:GetKeys(tk.Constants.CLASS_FILE_NAMES);

  if (not obj:IsTable(classFileNames)) then
    options[L["Custom"]] = CUSTOM_THEME_PRESET;
    return options;
  end

  sort(classFileNames);

  options[L["Custom"]] = CUSTOM_THEME_PRESET;

  for _, classFileName in ipairs(classFileNames) do
    local localizedName = tk:GetLocalizedClassNameByFileName(classFileName, true);

    if (obj:IsString(localizedName) and localizedName ~= tk.Strings.Empty) then
      options[localizedName] = classFileName;
    end
  end

  obj:PushTable(classFileNames);
  return options;
end

local function GetVisibleThemePreset(value)
  if (obj:IsString(value) and value ~= tk.Strings.Empty) then
    return value;
  end

  return tk:GetClassFileNameByUnitID("player");
end

local function GetMasqueAPI()
  if (not _G.LibStub) then
    return;
  end

  return _G.LibStub("Masque", true);
end

local function GetBartenderMasqueGroup()
  local masque = GetMasqueAPI();

  if (not (masque and _G.Bartender4 and obj:IsFunction(masque.Group))) then
    return;
  end

  local ok, group = pcall(masque.Group, masque, "Bartender4");

  if (ok and obj:IsTable(group)) then
    return group, masque;
  end
end

local function GetMasqueSkinOptions()
  local options = obj:PopTable();
  local masque = GetMasqueAPI();

  if (not (masque and obj:IsFunction(masque.GetSkins))) then
    return options;
  end

  local skins = masque:GetSkins();
  local skinIDs = {};

  for skinID in pairs(skins) do
    skinIDs[#skinIDs + 1] = skinID;
  end

  sort(skinIDs);

  for _, skinID in ipairs(skinIDs) do
    options[skinID] = skinID;
  end

  return options;
end

local function GetCurrentMasqueSkin()
  local group, masque = GetBartenderMasqueGroup();

  if (group and obj:IsTable(group.db) and obj:IsString(group.db.SkinID)) then
    return group.db.SkinID;
  end

  if (masque and obj:IsFunction(masque.GetDefaultSkin)) then
    local defaultSkin = masque:GetDefaultSkin();

    if (obj:IsString(defaultSkin)) then
      return defaultSkin;
    end
  end
end

local function SetMasqueSkin(skinID)
  local group = GetBartenderMasqueGroup();

  if (group and obj:IsFunction(group.__Set)) then
    pcall(group.__Set, group, "SkinID", skinID);
  end
end

local function GetManagedModule(moduleName)
  local module = MayronUI:ImportModule(moduleName, true);

  if (module and obj:IsFunction(module.IsInitialized) and not module:IsInitialized()) then
    module:Initialize();
  end

  return module;
end

local function SetManagedModuleEnabled(moduleName, dbPath, enabled)
  db:SetPathValue(dbPath, enabled);

  local module = GetManagedModule(moduleName);
  if (module and obj:IsFunction(module.SetEnabled)) then
    module:SetEnabled(enabled);
  end
end

local function GetCurrentLayoutName()
  local currentLayout = obj:IsTable(db.profile) and db.profile.layout or "DPS";
  return LayoutManager:NormalizeLayoutName(currentLayout);
end

local function GetActiveExternalProfileName(addOnName)
  local layoutData = LayoutManager:GetLayoutData(GetCurrentLayoutName());

  if (obj:IsTable(layoutData) and obj:IsString(layoutData[addOnName])) then
    return layoutData[addOnName];
  end
end

local function GetShadowUFProfileTable()
  local profileName = GetActiveExternalProfileName("ShadowUF");
  local database = _G.ShadowedUFDB;

  if (not (obj:IsString(profileName) and obj:IsTable(database) and obj:IsTable(database.profiles))) then
    return;
  end

  if (not obj:IsTable(database.profiles[profileName])) then
    database.profiles[profileName] = {};
  end

  return database.profiles[profileName], profileName;
end

local function ReloadShadowUFProfile(profileName)
  if (not (_G.ShadowUF and _G.ShadowUF.db and obj:IsFunction(_G.ShadowUF.db.GetCurrentProfile))) then
    return;
  end

  if (_G.ShadowUF.db:GetCurrentProfile() ~= profileName) then
    return;
  end

  if (obj:IsTable(_G.ShadowUF.Layout) and obj:IsFunction(_G.ShadowUF.Layout.Reload)) then
    pcall(function()
      _G.ShadowUF.Layout:Reload();
    end);
  end
end

local function GetShadowUFPortraitEnabled()
  local profileTable = GetShadowUFProfileTable();

  if (not (obj:IsTable(profileTable)
      and obj:IsTable(profileTable.units)
      and obj:IsTable(profileTable.units.player)
      and obj:IsTable(profileTable.units.player.portrait)
      and obj:IsTable(profileTable.units.target)
      and obj:IsTable(profileTable.units.target.portrait))) then
    return false;
  end

  return profileTable.units.player.portrait.enabled == true
    and profileTable.units.target.portrait.enabled == true;
end

local function SetShadowUFPortraitEnabled(value)
  local profileTable, profileName = GetShadowUFProfileTable();

  if (not obj:IsTable(profileTable)) then
    return;
  end

  profileTable.units = profileTable.units or {};
  profileTable.units.player = profileTable.units.player or {};
  profileTable.units.player.portrait = profileTable.units.player.portrait or {};
  profileTable.units.target = profileTable.units.target or {};
  profileTable.units.target.portrait = profileTable.units.target.portrait or {};

  profileTable.units.player.portrait.enabled = value == true;
  profileTable.units.target.portrait.enabled = value == true;

  ReloadShadowUFProfile(profileName);
end

local function GetBartenderActionBarProfileTable()
  local profileName = GetActiveExternalProfileName("Bartender4");
  local database = _G.Bartender4DB;

  if (not (obj:IsString(profileName)
      and obj:IsTable(database)
      and obj:IsTable(database.namespaces)
      and obj:IsTable(database.namespaces.ActionBars)
      and obj:IsTable(database.namespaces.ActionBars.profiles))) then
    return;
  end

  if (not obj:IsTable(database.namespaces.ActionBars.profiles[profileName])) then
    database.namespaces.ActionBars.profiles[profileName] = {};
  end

  return database.namespaces.ActionBars.profiles[profileName], profileName;
end

local function GetBartenderFontValue()
  local profileTable = GetBartenderActionBarProfileTable();

  if (not (obj:IsTable(profileTable) and obj:IsTable(profileTable.actionbars))) then
    return;
  end

  for _, barSettings in ipairs(profileTable.actionbars) do
    if (obj:IsTable(barSettings)
        and obj:IsTable(barSettings.elements)
        and obj:IsTable(barSettings.elements.hotkey)
        and obj:IsString(barSettings.elements.hotkey.font)) then
      return barSettings.elements.hotkey.font;
    end
  end
end

local function SetBartenderFontValue(newFont)
  local profileTable = GetBartenderActionBarProfileTable();

  if (not (obj:IsTable(profileTable) and obj:IsTable(profileTable.actionbars))) then
    return;
  end

  for _, barSettings in ipairs(profileTable.actionbars) do
    if (obj:IsTable(barSettings)) then
      barSettings.elements = barSettings.elements or {};
      barSettings.elements.macro = barSettings.elements.macro or {};
      barSettings.elements.hotkey = barSettings.elements.hotkey or {};
      barSettings.elements.count = barSettings.elements.count or {};

      barSettings.elements.macro.font = newFont;
      barSettings.elements.hotkey.font = newFont;
      barSettings.elements.count.font = newFont;
    end
  end
end

local bottomPanelManualHeightOptions;
local bottomPanelPaddingOption;
local sidePanelManualWidthOptions;
local sidePanelPaddingOption;

local function GetInfoPanelLabels()
  return MayronUI:GetComponent("DataTextLabels");
end

local function GetModKeyValue(modKey, currentValue)
  if (obj:IsString(currentValue) and currentValue:find(modKey)) then
    return true;
  end

  return false;
end

local function SetModKeyValue(modKey, dbPath, newValue, oldValue)
  if (obj:IsString(oldValue) and oldValue:find(modKey)) then
    -- remove modKey from current value before trying to append new value
    oldValue = oldValue:gsub(modKey, tk.Strings.Empty);
  end

  if (newValue) then
    newValue = modKey;

    if (obj:IsString(oldValue)) then
      newValue = oldValue .. newValue;
    end
  else
    -- if check button is not checked (false) set back to oldValue that does not include modKey
    newValue = oldValue;
  end

  db:SetPathValue(dbPath, newValue);
end

local function GetBartender4ActionBarOptions()
  local options = { [L["None"]] = 0 };
  local bt4 = _G.Bartender4;

  if (not (obj:IsTable(bt4) and obj:IsFunction(bt4.GetModule))) then
    return options
  end

  local ok, BT4ActionBars = pcall(bt4.GetModule, bt4, "ActionBars");

  if (not ok or not obj:IsTable(BT4ActionBars) or not obj:IsTable(BT4ActionBars.LIST_ACTIONBARS)) then
    return options
  end

  for _, barId in ipairs(BT4ActionBars.LIST_ACTIONBARS) do
    local barName = BT4ActionBars:GetBarName(barId);
    options[barName] = barId;
  end

  return options;
end

local function AddRepStandingIDColorOptions(repSettings, child)
  if (not obj:IsTable(repSettings)) then
    return;
  end

  repSettings.standingColors = repSettings.standingColors or {};
  repSettings.defaultColor = repSettings.defaultColor or { r = 0.16; g = 0.6; b = 0.16; };

  local repColors = {};
  local fixedBtn;

  local options = {
    { type = "fontstring"; content = L["Reputation Colors"]; subtype = "header" };
    {
      name = L["Use Fixed Color"];
      tooltip = L["If checked, the reputation bar will use a fixed color instead of dynamically changing based on your reputation with the selected faction."];
      type = "check";
      dbPath = "profile.resourceBars.reputationBar.useDefaultColor";
      SetValue = function(self, newValue)
        db:SetPathValue(self.dbPath, newValue);
        fixedBtn:SetEnabled(newValue);

        for _, btn in ipairs(repColors) do
          btn:SetEnabled(not newValue);
        end
      end;
    }; {
      name = L["Fixed Color"];
      type = "color";
      width = 120;
      dbPath = "profile.resourceBars.reputationBar.defaultColor";
      enabled = repSettings.useDefaultColor;
      OnLoad = function(_, btn)
        fixedBtn = btn;
      end;
    }; { type = "divider" };
  };

  for i = 1, 8 do
    local name = _G.GetText("FACTION_STANDING_LABEL" .. i, _G.UnitSex("PLAYER"));

    options[#options + 1] = {
      name = name;
      type = "color";
      width = 120;
      enabled = not repSettings.useDefaultColor;
      dbPath = strformat(
        "profile.resourceBars.reputationBar.standingColors[%d]", i);
      OnLoad = function(_, btn)
        repColors[#repColors + 1] = btn;
      end;
    };
  end

  for id, value in ipairs(options) do
    options[id] = nil;
    child[#child + 1] = value;
  end

  obj:PushTable(options);
end

local function BuildReputationBarChildren()
  local reputationSettings = db.profile and db.profile.resourceBars and db.profile.resourceBars.reputationBar;
  local child = {
    {
      name = tk.Strings:JoinWithSpace(L["Reputation"], L["Bar"]);
      type = "title";
      marginTop = 0;
    };
    {
      name = L["Enabled"];
      type = "check";
      dbPath = "profile.resourceBars.reputationBar.enabled";
    };
    {
      name = L["Show Text"];
      type = "check";
      dbPath = "profile.resourceBars.reputationBar.alwaysShowText";
    };
    {
      name = L["Height"];
      type = "slider";
      step = 1;
      min = 4;
      max = 30;
      dbPath = "profile.resourceBars.reputationBar.height";
    };
    {
      name = L["Font Size"];
      type = "slider";
      step = 1;
      min = 8;
      max = 18;
      dbPath = "profile.resourceBars.reputationBar.fontSize";
    };
    {
      type = "dropdown";
      name = L["Bar Texture"];
      media = "statusbar";
      width = 320;
      inline = true;
      dbPath = "profile.resourceBars.reputationBar.texture";
    };
  };

  if (obj:IsTable(reputationSettings)) then
    AddRepStandingIDColorOptions(reputationSettings, child);
  end

  return child;
end

local function BuildExperienceBarChildren()
  return {
    {
      name = tk.Strings:JoinWithSpace(L["Experience"], L["Bar"]);
      type = "title";
      marginTop = 0;
    };
    {
      name = L["Enabled"];
      type = "check";
      dbPath = "profile.resourceBars.experienceBar.enabled";
    };
    {
      name = L["Show Text"];
      type = "check";
      dbPath = "profile.resourceBars.experienceBar.alwaysShowText";
    };
    {
      name = L["Height"];
      type = "slider";
      step = 1;
      min = 4;
      max = 30;
      dbPath = "profile.resourceBars.experienceBar.height";
    };
    {
      name = L["Font Size"];
      type = "slider";
      step = 1;
      min = 8;
      max = 18;
      dbPath = "profile.resourceBars.experienceBar.fontSize";
    };
    {
      type = "dropdown";
      name = L["Bar Texture"];
      media = "statusbar";
      width = 320;
      inline = true;
      dbPath = "profile.resourceBars.experienceBar.texture";
    };
  };
end

local function BuildResourceBarsTabChildren()
  local children = {
    {
      type = "title";
      name = L["Resource Bars"];
      marginTop = 0;
    };
    {
      type = "fontstring";
      content = L["These settings control the experience and reputation bars shown around the main action bar area."];
    };
  };

  tk.Tables:AddAll(children, BuildExperienceBarChildren());
  children[#children + 1] = { type = "divider"; };
  tk.Tables:AddAll(children, BuildReputationBarChildren());

  return children;
end

local function BuildBottomPanelManualHeightFrame()
  return {
    type = "frame";
    OnLoad = function(_, frame)
      bottomPanelManualHeightOptions = frame;
    end;
    shown = function()
      return db.profile.actionbars.bottom.sizeMode == "manual";
    end;
    children = {
      {
        type = "fontstring";
        subtype = "header";
        content = L["Manual Height Mode Settings"],
      },
      {
        type = "slider";
        name = L["Set Row 1 Height"];
        dbPath = "profile.actionbars.bottom.manualSizes[1]";
        min = 40; max = 300; step = 5;
      },
      {
        type = "slider";
        name = L["Set Row 2 Height"];
        dbPath = "profile.actionbars.bottom.manualSizes[2]";
        min = 40; max = 300; step = 5;
      },
      {
        type = "slider";
        name = L["Set Row 3 Height"];
        min = 40; max = 300; step = 5;
        dbPath = "profile.actionbars.bottom.manualSizes[3]";
      },
    },
  };
end

local function BuildSidePanelManualWidthFrame()
  return {
    type = "frame";
    OnLoad = function(_, frame)
      sidePanelManualWidthOptions = frame;
    end;
    shown = function()
      return db.profile.actionbars.side.sizeMode == "manual";
    end;
    children = {
      {
        type = "fontstring";
        subtype = "header";
        content = L["Manual Side Panel Widths"],
      },
      {
        type = "slider";
        name = L["Set Column 1 Width"];
        dbPath = "profile.actionbars.side.manualSizes[1]";
        min = 40; max = 300; step = 5;
      },
      {
        type = "slider";
        name = L["Set Column 2 Width"];
        dbPath = "profile.actionbars.side.manualSizes[2]";
        min = 40; max = 300; step = 5;
      },
    },
  };
end

local function BuildBottomBartenderBarSelectors()
  return {
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "1", L["Bar"], "1");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[1][1]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "1", L["Bar"], "2");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[1][2]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "2", L["Bar"], "1");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[2][1]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "2", L["Bar"], "2");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[2][2]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "3", L["Bar"], "1");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[3][1]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = tk.Strings:JoinWithSpace(L["Row"], "3", L["Bar"], "2");
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.bottom.bartender[3][2]";
      GetOptions = GetBartender4ActionBarOptions;
    };
  };
end

local function BuildSideBartenderBarSelectors()
  return {
    {
      name = L["Column"] .. " 1";
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.side.bartender[1][1]";
      GetOptions = GetBartender4ActionBarOptions;
    };
    {
      name = L["Column"] .. " 2";
      type = "dropdown";
      width = 320;
      inline = true;
      dbPath = "profile.actionbars.side.bartender[2][1]";
      GetOptions = GetBartender4ActionBarOptions;
    };
  };
end

function C_ConfigMenu:GetConfigTable()
  return {
    {
      name = L["General"];
      id = 1;
      tabs = {
        L["Appearance Settings"];
        L["Fonts"];
        L["Blizzard Frames"];
        L["Global Settings"];
      };
      children = {
        {
          { type = "title"; name = L["Appearance Settings"]; marginTop = 0; };
          { type = "fontstring"; subtype = "header"; content = L["Theme"]; };
          {
            name = L["Theme"];
            type = "dropdown";
            options = GetThemePresetOptions;
            width = 320;
            inline = true;
            dbPath = "profile.theme.preset";
            disableSorting = true;

            GetValue = function(_, value)
              return GetVisibleThemePreset(value);
            end;

            SetValue = function(self, value)
              db:SetPathValue(self.dbPath, value);

              if (value == CUSTOM_THEME_PRESET) then
                tk:UpdateThemeColor(db.profile.theme.color);
              else
                tk:UpdateThemeColor(value);
                db.profile.theme.frameColor = {
                  r = DEFAULT_THEME_FRAME_COLOR.r;
                  g = DEFAULT_THEME_FRAME_COLOR.g;
                  b = DEFAULT_THEME_FRAME_COLOR.b;
                };
                gui:UpdateMuiFrameColor(
                  DEFAULT_THEME_FRAME_COLOR.r,
                  DEFAULT_THEME_FRAME_COLOR.g,
                  DEFAULT_THEME_FRAME_COLOR.b
                );
              end

              RefreshConfigTheme();
            end;
          };
          {
            name = L["Set Theme Color"];
            type = "color";
            dbPath = "profile.theme.color";

            SetValue = function(self, value)
              db.profile.theme.preset = CUSTOM_THEME_PRESET;
              db:SetPathValue(self.dbPath, value);
              tk:UpdateThemeColor(value);
              RefreshConfigTheme(true);
            end;
          };
          {
            name = L["Frame Color"];
            type = "color";
            tooltip = L["MUI_FRAMES_COLOR_TOOLTIP"];
            dbPath = "profile.theme.frameColor";
            SetValue = function(_, value)
              db.profile.theme.frameColor = value;
              gui:UpdateMuiFrameColor(value.r, value.g, value.b);
            end;
          };
          {
            name = L["Adjust the UI Scale:"];
            type = "slider";
            min = 0.6;
            max = 1.2;
            step = 0.05;
            dbPath = "global.core.uiScale";
            SetValue = function(self, value)
              db:SetPathValue(self.dbPath, value);
              SetCVar("useUiScale", "1");
              SetCVar("uiscale", value);
            end;
          };
          { type = "divider" };
          { type = "title";
            name = L["Main Container"];
            description = L["The main container holds the unit frame panels, action bar panels, data-text bar, and all resource bars at the bottom of the screen."]
          };
          {
            name = L["Width"];
            type = "slider";
            min = 500;
            max = 1500;
            step = 50;
            valueType = "number";
            tooltip = L["Adjust the width of the main container."];
            dbPath = "profile.bottomui.width";
          };
          {
            name = L["Frame Strata"];
            type = "dropdown";
            options = tk.Constants.ORDERED_FRAME_STRATAS;
            dbPath = "profile.bottomui.frameStrata";
          };
          {
            name = L["Frame Level"];
            type = "textfield";
            valueType = "number";
            dbPath = "profile.bottomui.frameLevel";
          };
          { type = "divider" };
          {
            name = L["X-Offset"];
            type = "textfield";
            valueType = "number";
            dbPath = "profile.bottomui.xOffset";
          };
          {
            name = L["Y-Offset"];
            type = "textfield";
            valueType = "number";
            dbPath = "profile.bottomui.yOffset";
          };
          { type = "title"; name = L["Info Panel"]; };
          {   name = L["Enabled"],
              tooltip = tk.Strings:Concat(
                L["If unchecked, the entire Info Panel will be disabled and all"], "\n",
                L["Info Panel buttons, as well as the background bar, will not be displayed."]),
              type = "check",
              requiresReload = true,
              dbPath = "profile.datatext.enabled",
          };
          {   name = L["Auto Hide Menu in Combat"],
              type = "check",
              dbPath = "profile.datatext.popup.hideInCombat",
          };
          {   type = "dropdown",
              name = L["Bar Strata"],
              tooltip = L["The frame strata of the entire Info Panel bar."],
              options = tk.Constants.ORDERED_FRAME_STRATAS,
              disableSorting = true;
              dbPath = "profile.datatext.frameStrata";
          };
          {   type = "slider",
              name = L["Bar Level"],
              tooltip = L["The frame level of the entire Info Panel bar based on its frame strata value."],
              min = 1,
              max = 50,
              default = 30,
              dbPath = "profile.datatext.frameLevel"
          };
          {   type = "fontstring"; subtype = "header"; content = L["Info Panel Modules"]; };
          {   type = "loop",
              loops = 8,
              func = function(id)
                local dataTextLabels = GetInfoPanelLabels();
                local child = {
                  name = tk.Strings:JoinWithSpace(L["Button"], id);
                  type = "dropdown";
                  dbPath = string.format("profile.datatext.displayOrders[%s]", id);
                  options = dataTextLabels;
                  labels = "values";

                  GetValue = function(_, value)
                    if (value == nil) then
                      value = "disabled";
                    end

                    return dataTextLabels[value];
                  end;

                  SetValue = function(self, newLabel)
                    local newValue;

                    for value, label in pairs(dataTextLabels) do
                      if (newLabel == label) then
                        newValue = value;
                        break;
                      end
                    end

                    db:SetPathValue(self.dbPath, newValue);
                  end;
                };

                return child;
              end
          };
        };
        {
          { type = "title"; name = L["Fonts"]; marginTop = 0; };
          { type = "fontstring"; subtype = "header"; content = L["Blizzard Font"]; };
          {
            name = L["Enabled"];
            height = 42;
            verticalAlignment = "BOTTOM";
            tooltip = L["Uncheck to prevent MUI from changing the game font."];
            width = 200;
            dbPath = "global.core.fonts.useMasterFont";
            type = "check";
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              ApplyGameFonts();
            end;
          };
          {
            name = L["Blizzard Font"];
            type = "dropdown";
            media = "font";
            width = 320;
            inline = true;
            dbPath = "global.core.fonts.master";
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              ApplyGameFonts();
            end;
          };
          { type = "divider"};
          { type = "fontstring"; subtype = "header"; content = L["MUI Font"]; };
          {
            name = L["MUI Font"];
            type = "dropdown";
            media = "font";
            width = 320;
            inline = true;
            dbPath = "global.core.fonts.mui";
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              ApplyGameFonts();
            end;
          };
          { type = "divider"};
          { type = "fontstring"; subtype = "header"; content = L["Combat Text Font"]; };
          {
            name = L["Enabled"];
            height = 42;
            width = 200;
            verticalAlignment = "BOTTOM";
            tooltip = L["Uncheck to prevent MUI from changing the game font."] .. " " ..
              L["Some changes require a client restart to take effect."];
            dbPath = "global.core.fonts.useCombatFont";
            type = "check";
            requiresRestart = true;
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              ApplyGameFonts();
            end;
          };
          {
            tooltip = L["This font is used to display the damage and healing combat numbers."] .. " " ..
              L["Some changes require a client restart to take effect."];
            name = L["Combat Text Font"];
            type = "dropdown";
            media = "font";
            width = 320;
            inline = true;
            dbPath = "global.core.fonts.combat";
            requiresRestart = true;
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              ApplyGameFonts();
            end;
          };
          {
            type = "fontstring";
            subtype = "sub-header";
            content = L["Changing combat text fonts requires a full client restart."];
          };
          { type = "divider" };
          { type = "fontstring"; subtype = "header"; content = L["Info Panel"]; };
          {
            name = tk.Strings:JoinWithSpace(L["Info Panel"], L["Font Size"]);
            type = "slider";
            min = 8;
            max = 18;
            step = 1;
            tooltip = L["The font size of text that appears on Info Panel buttons."];
            dbPath = "profile.datatext.fontSize";
          };
          { type = "divider" };
          { type = "fontstring"; subtype = "header"; content = L["External AddOns"]; };
          {
            type = "fontstring";
            subtype = "sub-header";
            content = L["External addon font changes are written to the currently active profile."];
          };
          { type = "divider" };
          { type = "fontstring"; subtype = "header"; content = "SUF"; };
          {
            name = L["SUF Font"];
            type = "dropdown";
            media = "font";
            inline = true;
            width = 320;
            requiresReload = true;
            shown = function()
              return GetShadowUFProfileTable() ~= nil;
            end;
            GetValue = function()
              local profileTable = GetShadowUFProfileTable();

              if (obj:IsTable(profileTable) and obj:IsTable(profileTable.font)) then
                return profileTable.font.name;
              end
            end;
            SetValue = function(_, newValue)
              local profileTable, profileName = GetShadowUFProfileTable();

              if (not obj:IsTable(profileTable)) then
                return;
              end

              profileTable.font = profileTable.font or {};
              profileTable.font.name = newValue;
              ReloadShadowUFProfile(profileName);
            end;
          };
          {
            name = tk.Strings:JoinWithSpace("SUF", L["Font Size"]);
            type = "slider";
            min = 8;
            max = 24;
            step = 1;
            requiresReload = true;
            shown = function()
              return GetShadowUFProfileTable() ~= nil;
            end;
            GetValue = function()
              local profileTable = GetShadowUFProfileTable();

              if (obj:IsTable(profileTable) and obj:IsTable(profileTable.font)) then
                return profileTable.font.size;
              end

              return 10;
            end;
            SetValue = function(_, newValue)
              local profileTable, profileName = GetShadowUFProfileTable();

              if (not obj:IsTable(profileTable)) then
                return;
              end

              profileTable.font = profileTable.font or {};
              profileTable.font.size = newValue;
              ReloadShadowUFProfile(profileName);
            end;
          };
          { type = "divider" };
          { type = "fontstring"; subtype = "header"; content = "Bartender4"; };
          {
            name = L["Bartender Font"];
            type = "dropdown";
            media = "font";
            inline = true;
            width = 320;
            requiresReload = true;
            shown = function()
              return GetBartenderActionBarProfileTable() ~= nil;
            end;
            GetValue = function()
              return GetBartenderFontValue();
            end;
            SetValue = function(_, newValue)
              SetBartenderFontValue(newValue);
            end;
          };
        };
        {
          { type = "title"; name = L["Blizzard Frames"]; marginTop = 0; };
          {
            name = L["Movable Frames"];
            type = "check";
            tooltip = L["Allows you to move Blizzard Frames outside of combat only."];
            dbPath = "global.movable.enabled";

            GetValue = function(_, value)
              return value and MayronUI:IsFeatureEnabled("coreui.movableFrames");
            end;

            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              db:SetPathValue("profile.features.coreui.movableFrames", newValue);

              local movableFramesModule = MayronUI:ImportModule("MovableFramesModule");
              if (movableFramesModule and not movableFramesModule:IsInitialized()) then
                movableFramesModule:Initialize();
              end

              if (movableFramesModule) then
                movableFramesModule:SetEnabled(newValue);
              end
            end;
          };
          {
            name = L["Clamped to Screen"];
            type = "check";
            tooltip = L["If checked, Blizzard frames cannot be dragged outside of the screen."];
            dbPath = "global.movable.clampToScreen";
            requiresReload = true;
          };
          {
            name = L["Reset Positions"];
            type = "button";
            tooltip = L["Reset Blizzard frames back to their original position."];
            OnClick = function()
              MayronUI:ImportModule("MovableFramesModule"):ResetPositions();
              MayronUI:Print(L["Blizzard frame positions have been reset."]);
            end;
          };
          {
            type = "fontstring";
            subtype="header";
            client = "retail";
            height = 20;
            content = L["Talking Head Frame"];
          };
          {
            type = "fontstring";
            client = "retail";
            padding = 4;
            content = L["This is the animated character portrait frame that shows when an NPC is talking to you."];
          }; {
            name = L["Top of Screen"];
            type = "radio";
            client = "retail";
            groupName = "talkingHead_position";
            dbPath = "global.movable.talkingHead.position";
            height = 50;
            GetValue = function(_, value)
              return value == "TOP";
            end;

            SetValue = function(self)
              db:SetPathValue(self.dbPath, "TOP");
            end;
          }; {
            name = L["Bottom of Screen"];
            type = "radio";
            client = "retail";
            groupName = "talkingHead_position";
            dbPath = "global.movable.talkingHead.position";
            height = 50;
            GetValue = function(_, value)
              return value == "BOTTOM";
            end;

            SetValue = function(self)
              db:SetPathValue(self.dbPath, "BOTTOM");
            end;
          }; {
            name = L["Y-Offset"];
            type = "textfield";
            client = "retail";
            valueType = "number";
            dbPath = "global.movable.talkingHead.yOffset";
          };
        };
        {
          { type = "title";
            name = L["Global Settings"];
            marginTop = 0;
            description = L["These settings are applied account-wide"];
          };
          {
            name = L["Display Lua Errors"];
            type = "check";

            GetValue = function()
              return tonumber(GetCVar("ScriptErrors")) == 1;
            end;

            SetValue = function(_, value)
              if (value) then
                SetCVar("ScriptErrors", "1");
              else
                SetCVar("ScriptErrors", "0");
              end
            end;
          }; {
            name = L["Show AFK Display"];
            type = "check";
            tooltip = L["Enable/disable the AFK Display"];
            dbPath = "global.AFKDisplay.enabled";

            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);
              MayronUI:ImportModule("AFKDisplay"):SetEnabled(newValue);
            end;
          }; {
            name = L["Enable Max Camera Zoom"];
            type = "check";
            tooltip = L["Enable Max Camera Zoom"];
            dbPath = "global.core.maxCameraZoom";
            SetValue = function(self, newValue)
              db:SetPathValue(self.dbPath, newValue);

              if (newValue) then
                SetCVar("cameraDistanceMaxZoomFactor", 4.0);
              else
                SetCVar("cameraDistanceMaxZoomFactor", 1.9);
              end
            end;
          };
        };
      };
    };
    {
      name = L["Action Bars"];
      id = 2;
      tabs = {
        L["Action Bars"];
        L["Side Bars"];
        L["Resource Bars"];
        "Bartender4";
      };
      children = {
        {
          {
            type = "title";
            name = L["Action Bars"];
            marginTop = 0;
          };
          {
            type = "fontstring";
            content = L["These settings control the MayronUI artwork behind the Bartender4 action bars."];
          };
          {
            type = "fontstring";
            content = L["These options style the MUI background panels. Use the Bartender4 tab for the external action bars themselves."];
          };
          {
            type = "fontstring";
            subtype = "header";
            content = L["Action Buttons"];
          },
        {
          name = L["Masque Style"];
          type = "dropdown";
          width = 320;
          inline = true;
          disableSorting = true;
          tooltip = L["Choose the Masque skin used for the Bartender4 action buttons."];
          shown = function()
            return GetBartenderMasqueGroup() ~= nil;
          end;
          enabled = function()
            return GetBartenderMasqueGroup() ~= nil;
          end;
          GetOptions = function()
            return GetMasqueSkinOptions();
          end;
          GetValue = function()
            return GetCurrentMasqueSkin();
          end;
          SetValue = function(_, value)
            SetMasqueSkin(value);
          end;
        },
          { type = "divider" };
        {
          type = "slider",
          name = L["Set Animation Speed"],
          min = 1; max = 10; step = 1;
          dbPath = "profile.actionbars.bottom.animation.speed";
          tooltip = L["The speed of the Expand and Retract transitions."]
            .. "\n" .. L["The higher the value, the quicker the speed."];
        },
        {
          type = "slider",
          name = L["Set Alpha"],
          dbPath = "profile.actionbars.bottom.alpha";
        },
        { type = "divider" };
        {
          type = "fontstring";
          content = L["Set the modifier key/s that should be pressed to show the arrow buttons."];
        };
        {
          type = "loop";
          args = { "C"; "S"; "A" };
          func = function(_, arg)
            local name = L["Alt"];

            if (arg == "C") then
              name = L["Control"];

            elseif (arg == "S") then
              name = L["Shift"];
            end

            return {
              name = name;
              height = 40;
              type = "check";
              dbPath = "profile.actionbars.bottom.animation.modKey";

              GetValue = function(_, currentValue)
                return GetModKeyValue(arg, currentValue);
              end;

              SetValue = function(self, newValue, oldValue)
                SetModKeyValue(arg, self.dbPath, newValue, oldValue);
              end;
            };
          end;
        };
        { type = "divider" };
        {
          name = L["Set Height Mode"];
          type = "dropdown";
          options = { [L["Dynamic"]] = "dynamic", [L["Manual"]] = "manual" };
          width = 320;
          inline = true;
          dbPath = "profile.actionbars.bottom.sizeMode";
          tooltip = L["If set to dynamic, MayronUI will calculate the optimal height for the selected Bartender4 action bars to fit inside the panel."];
          OnValueChanged = function(value)
            if (bottomPanelManualHeightOptions) then
              bottomPanelManualHeightOptions:SetShown(value == "manual");
            end

            if (bottomPanelPaddingOption) then
              bottomPanelPaddingOption:SetShown(value == "dynamic");
            end

            self:RefreshMenu();
          end
        };
        {
          type = "slider",
          name = L["Set Panel Padding"],
          dbPath = "profile.actionbars.bottom.panelPadding";
          min = 0; max = 20;
          OnLoad = function(_, slider)
            bottomPanelPaddingOption = slider;
          end;
          shown = function()
            return db.profile.actionbars.bottom.sizeMode == "dynamic";
          end;
        },
        BuildBottomPanelManualHeightFrame(),
        };
        {
          {
            type = "title";
            name = L["Side Bars"];
            marginTop = 0;
          };
          {
            type = "slider",
            name = "Set Animation Speed",
            min = 1; max = 10; step = 1;
            dbPath = "profile.actionbars.side.animation.speed";
            tooltip = L["The speed of the Expand and Retract transitions."]
              .. "\n" .. L["The higher the value, the quicker the speed."];
          };
          {
            type = "slider",
            name = L["Set Alpha"],
            dbPath = "profile.actionbars.side.alpha";
          };
          {
            type = "slider",
            name = L["Set Y-Offset"],
            valueType = "number";
            dbPath = "profile.actionbars.side.yOffset";
            min = -200; max = 200; step = 10;
          };
          {
            type = "slider",
            name = L["Height"],
            dbPath = "profile.actionbars.side.height";
            min = 200; max = 800; step = 10;
          };
          { type = "divider" };
          {
            name = L["Set Arrow Button Visibility"];
            type = "dropdown";
            width = 320;
            inline = true;
            options = {
              [L["Always"]] = "Always";
              [L["On Mouse-over"]] = "On Mouse-over";
              [L["Never"]] = "Never";
            };
            dbPath = "profile.actionbars.side.animation.showWhen";
          };
          {
            name = L["Hide Arrow Buttons In Combat"];
            type = "check";
            dbPath = "profile.actionbars.side.animation.hideInCombat";
            height = 42;
            verticalAlignment = "BOTTOM";
          };
          { type = "divider" };
          {
            name = L["Set Width Mode"];
            type = "dropdown";
            options = { [L["Dynamic"]] = "dynamic", [L["Manual"]] = "manual" };
            width = 320;
            inline = true;
            dbPath = "profile.actionbars.side.sizeMode";
            tooltip = L["If set to dynamic, MayronUI will calculate the optimal width for the selected Bartender4 action bars to fit inside the panel."];
            OnValueChanged = function(value)
              if (sidePanelManualWidthOptions) then
                sidePanelManualWidthOptions:SetShown(value == "manual");
              end

              if (sidePanelPaddingOption) then
                sidePanelPaddingOption:SetShown(value == "dynamic");
              end

              self:RefreshMenu();
            end
          };
          {
            type = "slider",
            name = L["Set Panel Padding"],
            dbPath = "profile.actionbars.side.panelPadding";
            min = 0; max = 20;
            OnLoad = function(_, slider)
              sidePanelPaddingOption = slider;
            end;
            shown = function()
              return db.profile.actionbars.side.sizeMode == "dynamic";
            end;
          };
          BuildSidePanelManualWidthFrame(),
        };
        BuildResourceBarsTabChildren;
        {
          {
            type = "title";
            name = "Bartender4";
            marginTop = 0;
          };
          {
            type = "fontstring";
            content = L["These settings control what MayronUI is allowed to do with the Bartender4 action bars. By default, MayronUI:"];
          },
          {
            type = "fontstring";
            content = L["These settings only affect the Bartender4 action bars, not the MUI panels themselves."];
          },
          {
            type = "fontstring",
            list = {
              L["Fades action bars in and out when you press the provided arrow buttons."];
              L["Maintains the visibility of action bars between sessions of gameplay."];
              L["Sets the scale and padding of action bar buttons to best fit inside the background panels."];
              L["Sets and updates the position the action bars so they remain in place ontop of the background panels."]
            }
          },
          {
            type = "fontstring",
            subtype = "header",
            content = L["Bottom Bartender4 Action Bars"],
          },
          { type = "check";
            name = L["Control Bartender Positioning"];
            dbPath = "profile.actionbars.bottom.bartender.controlPositioning";
            tooltip = L["If enabled, MayronUI will move the selected Bartender4 action bars into the correct position for you."]
          },
          { type = "check";
            name = L["Override Bartender Padding"];
            dbPath = "profile.actionbars.bottom.bartender.controlPadding";
            tooltip = L["If enabled, MayronUI will set the padding of the selected Bartender4 action bar to best fit the background panel."]
          },
          { type = "check";
            name = L["Override Bartender Scale"];
            dbPath = "profile.actionbars.bottom.bartender.controlScale";
            tooltip = L["If enabled, MayronUI will set the scale of the selected Bartender4 action bar to best fit the background panel."]
          },
          { type = "divider" };
          {
            type = "slider",
            name = L["Set Row Spacing"],
            dbPath = "profile.actionbars.bottom.bartender.spacing";
            min = 0; max = 20;
          },
          { type = "slider";
            name = L["Set Bar Padding"];
            dbPath = "profile.actionbars.bottom.bartender.padding";
            min = 0; max = 10; step = 0.1;
            enabled = "profile.actionbars.bottom.bartender.controlPadding";
          },
          { type = "slider";
            name = L["Set Bar Scale"];
            dbPath = "profile.actionbars.bottom.bartender.scale";
            min = 0.25; max = 2;
            enabled = "profile.actionbars.bottom.bartender.controlScale"
          },
          {
            type = "fontstring",
            content = L["The bottom panel can display and control up to two Bartender4 action bars per row."],
          },
          {
            type = "frame";
            children = BuildBottomBartenderBarSelectors();
          };
          {
            type = "fontstring",
            subtype = "header",
            content = L["Side Bartender4 Action Bars"],
          },
          { type = "check";
            name = L["Control Bartender Positioning"];
            dbPath = "profile.actionbars.side.bartender.controlPositioning";
            tooltip = L["If enabled, MayronUI will move the selected Bartender4 action bars into the correct position for you."]
          },
          { type = "check";
            name = L["Override Bartender Padding"];
            dbPath = "profile.actionbars.side.bartender.controlPadding";
            tooltip = L["If enabled, MayronUI will set the padding of the selected Bartender4 action bar to best fit the background panel."]
          },
          { type = "check";
            name = L["Override Bartender Scale"];
            dbPath = "profile.actionbars.side.bartender.controlScale";
            tooltip = L["If enabled, MayronUI will set the scale of the selected Bartender4 action bar to best fit the background panel."]
          },
          { type = "divider" };
          {
            type = "slider",
            name = L["Set Column Spacing"],
            dbPath = "profile.actionbars.side.bartender.spacing";
            min = 0; max = 20;
          },
          { type = "slider";
            name = L["Set Bar Padding"];
            dbPath = "profile.actionbars.side.bartender.padding";
            min = 0; max = 10;
            enabled = "profile.actionbars.side.bartender.controlPadding"
          },
          { type = "slider";
            name = L["Set Bar Scale"];
            dbPath = "profile.actionbars.side.bartender.scale";
            min = 0.25; max = 2;
            enabled = "profile.actionbars.side.bartender.controlScale"
          },
          {
            type = "frame";
            children = BuildSideBartenderBarSelectors();
          };
        };
      };
    };
    {
      name = L["Unit Panels"];
      id = 3;
      tabs = {
        L["Unit Panels"];
        L["Name Panels"];
        "SUF";
      };
      children = {
        {
          {
            type = "title";
            name = L["Unit Panels"];
            marginTop = 0;
          };
          {
            type = "fontstring";
            content = L["These options style the MUI unit background panels. Use the SUF tab for external Shadowed Unit Frames."];
          };
          {
            name = L["Enabled"];
            type = "check";
          dbPath = "profile.unitPanels.enabled";
          SetValue = function(self, value)
            SetManagedModuleEnabled("UnitPanels", self.dbPath, value);
          end;
        };
        {
          name = L["Width"];
          type = "slider";
          min = 220;
          max = 500;
          step = 5;
          dbPath = "profile.unitPanels.unitWidth";
          tooltip = L["Adjust the width of the unit frame background panels."];
        };
        {
          name = L["Height"];
          type = "slider";
          min = 40;
          max = 140;
          step = 5;
          dbPath = "profile.unitPanels.unitHeight";
        };
        {
          name = L["Set Alpha"];
          type = "slider";
          min = 0;
          max = 1;
          step = 0.05;
          dbPath = "profile.unitPanels.alpha";
        };
        {
          name = L["Symmetric Unit Panels"];
          type = "check";
          dbPath = "profile.unitPanels.isSymmetric";
        };
        {
          name = L["Target Class Colored"];
          type = "check";
          tooltip = L["TT_MUI_USE_TARGET_CLASS_COLOR"];
          dbPath = "profile.unitPanels.targetClassColored";
        };
        {
          name = L["Resting Pulse"];
          type = "check";
          tooltip = L["If enabled, the unit panels will fade in and out while resting."];
          dbPath = "profile.unitPanels.restingPulse";
        };
        {
          name = L["Set Pulse Strength"];
          type = "slider";
          min = 0.05;
          max = 0.7;
          step = 0.05;
          dbPath = "profile.unitPanels.pulseStrength";
          shown = function()
            return db.profile.unitPanels.restingPulse == true;
          end;
        };
        };
        {
          {
            type = "title";
            name = L["Name Panels"];
            marginTop = 0;
          };
          {
            name = L["Enabled"];
            type = "check";
            dbPath = "profile.unitPanels.unitNames.enabled";
          };
          {
            name = L["Width"];
            type = "slider";
            min = 120;
            max = 320;
            step = 5;
            dbPath = "profile.unitPanels.unitNames.width";
            tooltip = L["Adjust the width of the unit name background panels."];
          };
          {
            name = L["Height"];
            type = "slider";
            min = 14;
            max = 36;
            step = 1;
            dbPath = "profile.unitPanels.unitNames.height";
            tooltip = L["Adjust the height of the unit name background panels."];
          };
          {
            name = L["Font Size"];
            type = "slider";
            min = 8;
            max = 20;
            step = 1;
            dbPath = "profile.unitPanels.unitNames.fontSize";
            tooltip = L["Set the font size of unit names."];
          };
          {
            name = L["X-Offset"];
            type = "slider";
            min = 0;
            max = 80;
            step = 1;
            dbPath = "profile.unitPanels.unitNames.xOffset";
            tooltip = L["Move the unit name panels further in or out."];
          };
          {
            name = L["Target Class Colored"];
            type = "check";
            tooltip = L["TT_MUI_USE_TARGET_CLASS_COLOR"];
            dbPath = "profile.unitPanels.unitNames.targetClassColored";
          };
        };
        {
          {
            type = "title";
            name = "SUF";
            marginTop = 0;
          };
          {
            type = "fontstring";
            content = L["These settings only apply when MUI is allowed to manage Shadowed Unit Frames."];
          };
          {
            name = L["Allow MUI to Control Unit Frames"];
            type = "check";
            tooltip = L["TT_MUI_CONTROL_SUF"];
            dbPath = "profile.unitPanels.controlSUF";
          };
          {
            name = L["Enable Portraits"];
            type = "check";
            shown = function()
              return GetShadowUFProfileTable() ~= nil;
            end;
            tooltip = L["TT_MUI_ENABLE_SUF_PORTRAITS"];
            GetValue = function()
              return GetShadowUFPortraitEnabled();
            end;
            SetValue = function(_, newValue)
              SetShadowUFPortraitEnabled(newValue);
            end;
          };
          {
            type = "fontstring";
            subtype = "header";
            content = L["SUF Portrait Gradient"];
          };
          {
            name = L["Enable Portrait Gradient"];
            type = "check";
            dbPath = "profile.unitPanels.sufGradients.enabled";
          };
          {
            name = L["Opacity"];
            type = "slider";
            min = 0;
            max = 1;
            step = 0.05;
            dbPath = "profile.unitPanels.sufGradients.opacity";
          };
          {
            name = L["Target Class Colored"];
            type = "check";
            tooltip = L["TT_MUI_USE_TARGET_CLASS_COLOR"];
            dbPath = "profile.unitPanels.sufGradients.targetClassColored";
          };
          {
            name = L["Start Color"];
            type = "color";
            dbPath = "profile.unitPanels.sufGradients.from";
          };
          {
            name = L["End Color"];
            type = "color";
            dbPath = "profile.unitPanels.sufGradients.to";
          };
        };
      };
    };
  };
end
