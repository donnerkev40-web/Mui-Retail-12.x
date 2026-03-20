--luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local ipairs, strformat = _G.ipairs, _G.string.format;
local lower, sort = _G.string.lower, _G.table.sort;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

---@class MayronUI.ConfigMenu
local C_ConfigMenuModule = MayronUI:GetModuleClass("ConfigMenu");
local components = {};

local function CanDeleteProfile(profileName)
  return MayronUI:CanDeleteProfile(profileName);
end

local function GetDeletableProfileOptions()
  local profiles = db:GetProfiles();
  local options = obj:PopTable();

  for _, profileName in ipairs(profiles) do
    if (CanDeleteProfile(profileName)) then
      options[profileName] = profileName;
    end
  end

  return options;
end

local function GetSelectedDeleteProfile()
  local profileName = components.selectedDeleteProfileName;

  if (CanDeleteProfile(profileName)) then
    return profileName;
  end

  local currentProfile = db:GetCurrentProfile();
  if (CanDeleteProfile(currentProfile)) then
    return currentProfile;
  end

  local deletableProfiles = GetDeletableProfileOptions();
  local fallbackProfileName;

  for optionProfileName in pairs(deletableProfiles) do
    fallbackProfileName = optionProfileName;
    break;
  end

  obj:PushTable(deletableProfiles);
  return fallbackProfileName;
end

local function RefreshDeleteButton()
  if (components.deleteProfileButton) then
    components.deleteProfileButton:SetEnabled(CanDeleteProfile(GetSelectedDeleteProfile()));
  end
end

local function RefreshDeleteProfileSelector(profileName)
  profileName = profileName or GetSelectedDeleteProfile();
  components.selectedDeleteProfileName = profileName;

  if (components.deleteProfileDropDown) then
    components.deleteProfileDropDown:SetLabel(profileName or L["Select profile"]);
  end
end

local function UpdateCurrentProfileText(currentProfile)
  if (not components.currentProfileFontString) then
    return;
  end

  currentProfile = tk.Strings:SetTextColorByKey(currentProfile, "GOLD");
  local text = tk.Strings:Join("", L["Current profile"], ": ", currentProfile);
  components.currentProfileFontString:SetText(text);
end

local function ResetProfile()
  db:ResetProfile();
end

local function CopyProfile(_, profileName)
  local currentProfile = db:GetCurrentProfile();
  db:CopyProfile(currentProfile, profileName);

  local copyProfileMessage = L["Profile %s has been copied into current profile %s."];

  copyProfileMessage = copyProfileMessage:format(
  tk.Strings:SetTextColorByKey(profileName, "gold"),
  tk.Strings:SetTextColorByKey(currentProfile, "gold"));

  tk:Print(copyProfileMessage);
end

-- Get all profiles and convert them to a list of options for use with dropdown menus
local function GetProfileOptions()
  local profiles = db:GetProfiles();
  local options = obj:PopTable();
  local seen = obj:PopTable();
  local currentProfile = db:GetCurrentProfile();

  local function AddProfileOption(profileName)
    if (obj:IsString(profileName) and profileName ~= tk.Strings.Empty and not seen[profileName]) then
      seen[profileName] = true;
      options[profileName] = profileName;
    end
  end

  AddProfileOption(currentProfile);

  for _, layoutName in ipairs({ "DPS", "Healer" }) do
    AddProfileOption(MayronUI:GetLayoutProfileName(layoutName));
  end

  for _, profileName in ipairs(profiles) do
    AddProfileOption(profileName);
  end

  obj:PushTable(seen);

  return options;
end

local function GetCurrentProfileText()
  return tk.Strings:Join("",
    L["Current profile"], ": ",
    tk.Strings:SetTextColorByKey(db:GetCurrentProfile(), "GOLD"));
end

local function SelectProfileDropDownValue(_, profileName)
  if (db:GetCurrentProfile() == profileName) then
    return;
  end

  db:SetProfile(profileName);
  UpdateCurrentProfileText(profileName);
  RefreshDeleteProfileSelector();
  RefreshDeleteButton();
end

local function SelectDeleteProfileDropDownValue(_, profileName)
  components.selectedDeleteProfileName = profileName;
  RefreshDeleteProfileSelector(profileName);
  RefreshDeleteButton();
end

local function RebuildProfileDropdown(dropdown, options, onSelect, selectedLabel, removedLabel)
  if (not (dropdown and obj:IsFunction(dropdown.GetNumOptions)
      and obj:IsFunction(dropdown.GetOptionByID)
      and obj:IsFunction(dropdown.RemoveOptionByLabel)
      and obj:IsFunction(dropdown.AddOption)
      and obj:IsFunction(dropdown.SetLabel)
      and obj:IsFunction(dropdown.SetEnabled))) then
    return;
  end

  local optionLabels = obj:PopTable();

  for optionID = dropdown:GetNumOptions(), 1, -1 do
    local option = dropdown:GetOptionByID(optionID);

    if (option) then
      dropdown:RemoveOptionByLabel(option:GetText());
    end
  end

  if (obj:IsString(removedLabel) and removedLabel ~= tk.Strings.Empty) then
    dropdown:RemoveOptionByLabel(removedLabel);
  end

  for optionLabel in pairs(options) do
    optionLabels[#optionLabels + 1] = optionLabel;
  end

  sort(optionLabels, function(a, b)
    return lower(a) < lower(b);
  end);

  for _, optionLabel in ipairs(optionLabels) do
    dropdown:AddOption(optionLabel, onSelect, optionLabel);
  end

  obj:PushTable(optionLabels);

  if (not (obj:IsString(selectedLabel) and options[selectedLabel])) then
    selectedLabel = L["Select profile"];
  end

  dropdown:SetLabel(selectedLabel or L["Select profile"]);
  dropdown:SetEnabled(next(options) ~= nil);
end

local function RefreshProfileManagerUI(removedProfileName)
  local currentProfile = db:GetCurrentProfile();
  local profileOptions = GetProfileOptions();
  local deletableOptions = GetDeletableProfileOptions();

  RebuildProfileDropdown(
    components.chooseProfileDropDown,
    profileOptions,
    SelectProfileDropDownValue,
    currentProfile,
    removedProfileName
  );

  RebuildProfileDropdown(
    components.deleteProfileDropDown,
    deletableOptions,
    SelectDeleteProfileDropDownValue,
    GetSelectedDeleteProfile(),
    removedProfileName
  );

  obj:PushTable(profileOptions);
  obj:PushTable(deletableOptions);

  RefreshDeleteProfileSelector();
  UpdateCurrentProfileText(currentProfile);
  RefreshDeleteButton();
end

local configTable = {
  id = 1;
  name = L["MUI Profile Manager"];
  tabs = {
    L["Profiles"];
    L["Import Profile"] .. " / " .. L["Export Profile"];
  };
  children = {
    {
      { type = "title"; name = L["Profiles"]; marginTop = 0; };
      { content = L["MANAGE_PROFILES_HERE"]; type = "fontstring"; };
      {
        type = "fontstring";
        GetContent = GetCurrentProfileText;
        OnLoad = function(_, container)
          components.currentProfileFontString = container.content;
          UpdateCurrentProfileText(db:GetCurrentProfile());
        end
      };
      { type = "divider"; };
      { type = "fontstring"; subtype = "header"; content = L["Choose Profile"]; };
      {
        GetOptions = GetProfileOptions;
        name       = L["Choose Profile"]..": ";
        tooltip    = L["Choose the currently active profile."];
        type       = "dropdown";
        width      = 320;
        inline     = true;

        OnLoad = function(_, container)
          components.chooseProfileDropDown = container.component.dropdown;
          RefreshProfileManagerUI();
        end;

        SetValue = function(_, newValue)
          if (db:GetCurrentProfile() == newValue) then
            return;
          end

          db:SetProfile(newValue);
          RefreshProfileManagerUI();
        end;

        GetValue = function()
          return db:GetCurrentProfile();
        end;
      };
      { type = "divider"; };
      { type = "fontstring"; subtype = "header"; content = L["Profiles"]; };
      {
        name    = L["New Profile"];
        tooltip = L["Create a new profile"] .. ".";
        type    = "button";

        OnClick = function()
          _G.MayronUI:TriggerCommand("profile", "new", nil, function()
            local currentProfile = db:GetCurrentProfile();

            RefreshProfileManagerUI();
            UpdateCurrentProfileText(currentProfile);
            RefreshDeleteProfileSelector(currentProfile);
            RefreshDeleteButton();
          end);
        end;
      };
      {
        name    = L["Copy From"]..": ";
        tooltip = L["Copy all settings from one profile to the active profile."];
        type    = "dropdown";
        width   = 320;
        inline  = true;
        GetOptions = GetProfileOptions;

        SetValue = function(self, profileName)
          local dropdown = self.component.dropdown;
          local currentProfile = db:GetCurrentProfile();

          if (currentProfile == profileName) then
            dropdown:SetLabel(L["Select profile"]);
            return;
          end

          local popupMessage = strformat(
            L["Are you sure you want to override all profile settings in '%s' for those in profile '%s'?"],
            currentProfile, profileName);

          tk:ShowConfirmPopup(popupMessage, nil, nil, CopyProfile, nil, nil, true, profileName);
          dropdown:SetLabel(L["Select profile"]);
        end;

        GetValue = function()
          return L["Select profile"];
        end;
      };
      { type = "divider"; };
      { type = "title"; name = L["Dangerous Actions!"]; };
      {
        GetOptions = GetDeletableProfileOptions;
        name = L["Delete Profile"] .. ": ";
        tooltip = L["Delete selected profile (cannot delete the 'Default' or layout-managed profiles)."];
        type = "dropdown";
        width = 320;
        inline = true;

        OnLoad = function(_, container)
          components.deleteProfileDropDown = container.component.dropdown;
          RefreshProfileManagerUI();
        end;

        SetValue = function(_, profileName)
          components.selectedDeleteProfileName = profileName;
          RefreshDeleteProfileSelector(profileName);
          RefreshDeleteButton();
        end;

        GetValue = function()
          return GetSelectedDeleteProfile() or L["Select profile"];
        end;
      };
      { type = "divider"; };
      {
        name    = L["Reset Profile"];
        tooltip = L["Reset currently active profile back to default settings."];
        type    = "button";

        OnClick = function()
          local profileName = db:GetCurrentProfile();
          local popupMessage = strformat(
          L["Are you sure you want to reset profile '%s' back to default settings?"], profileName);
          tk:ShowConfirmPopup(popupMessage, nil, nil, ResetProfile, nil, nil, true);
        end
      };
      {
        name    = L["Delete Profile"];
        tooltip = L["Delete selected profile (cannot delete the 'Default' or layout-managed profiles)."];
        type    = "button";

        OnLoad = function(_, widget)
          components.deleteProfileButton = widget;
          RefreshProfileManagerUI();
        end;

        OnClick = function()
          local profileName = GetSelectedDeleteProfile();
          local shown = MayronUI:RequestDeleteProfile(profileName, function(deletedProfileName, switchedProfile)
            RefreshProfileManagerUI(deletedProfileName or profileName);
            MayronUI:ShowReloadUIPopUp();
          end);

          if (not shown) then
            RefreshDeleteProfileSelector();
            RefreshDeleteButton();
          end
        end
      };
      { type = "divider"; };
      { name = L["Default Profile Behaviour"]; type = "title"; marginBottom = 0; };
      { content = L["UNIQUE_CHARACTER_PROFILE"]; type = "fontstring"; };
      { type = "divider" };
      {
        dbPath      = "global.core.setup.profilePerCharacter";
        name        = L["Profile Per Character"];
        tooltip     = L["If enabled, new characters will be assigned a unique character profile instead of the Default profile."];
        type        = "check";
      };
    };
    {
      { type = "title"; name = L["Import Profile"] .. " / " .. L["Export Profile"]; marginTop = 0; };
      { type = "fontstring"; subtype = "header"; content = L["Export Profile"]; };
      {
        name    = L["Export Profile"];
        tooltip = L["Export the current profile into a string that can be imported by other players."];
        type    = "button";
        OnClick = function()
          _G.StaticPopupDialogs["MUI_ExportProfile"] = _G.StaticPopupDialogs["MUI_ExportProfile"] or {
            text = tk.Strings:Join(
              "\n", tk.Strings:SetTextColorByTheme("MayronUI"), L["(CTRL+C to Copy, CTRL+V to Paste)"]
            );
            subText = L["Copy the import string below and give it to other players so they can import your current profile."],
            button1 = L["Close"];
            hasEditBox = true;
            maxLetters = 1024;
            editBoxWidth = 350;
            hideOnEscape = 1;
            timeout = 0;
            whileDead = 1;
            preferredIndex = 3;
          };

          local popup = _G.StaticPopup_Show("MUI_ExportProfile");
          local editbox = _G[ string.format("%sEditBox", popup:GetName()) ];

          local text = db:ExportProfile();
          editbox:SetText(text);
          editbox:SetFocus();
          editbox:HighlightText();
        end;
      };
      { type = "divider"; };
      { type = "fontstring"; subtype = "header"; content = L["Import Profile"]; };
      {
        name    = L["Import Profile"];
        tooltip = L["Import a profile from another player from an import string."];
        type    = "button";

        OnClick = function()
          tk:ShowInputPopup(L["Paste an import string into the box below to import a profile."],
          L["Warning: This will completely replace your current profile with the imported profile settings!"],
          "", nil, "Import", function(_, importStr)
            db:ImportProfile(importStr);
            MayronUI:Print(L["Successfully imported profile settings into your current profile!"]);
            MayronUI:ShowReloadUIPopUp();
          end, nil, nil, true);
        end;
      };
    };
  }
};

function C_ConfigMenuModule:ShowProfileManager(data)
  if (not data.configPanel or not data.configPanel:IsShown()) then
    self:Show();
  end

  local menuButton = data.configPanel.profilesBtn;

  if (not menuButton.name) then
    menuButton.configTable = configTable;
    menuButton.type = "menu";
    menuButton.name = configTable.name;
  end

  self:OpenMenu(menuButton);
  RefreshProfileManagerUI();
end
