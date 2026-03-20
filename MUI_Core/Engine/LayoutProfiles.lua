local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.LayoutProfiles", true)) then
  return;
end

-- Layouts are now represented by full MUI profiles instead of internal
-- state snapshots. The legacy path list remains only for one-time migration
-- from old profile.layoutStates data.
local legacyManagedProfilePaths = {
  "actionbars";
  "bottomui";
  "castBars";
  "chat";
  "datatext";
  "minimap";
  "resourceBars";
  "tooltips";
  "unitPanels";
};

local DEFAULT_LAYOUTS = {
  "DPS";
  "Healer";
};

local DEFAULT_LAYOUT_PROFILES = {
  DPS = "MayronUI-Damage";
  Healer = "MayronUI-Healer";
};

local CURRENT_MIGRATION_VERSION = 1;

db:AddToDefaults("global.layoutProfiles", DEFAULT_LAYOUT_PROFILES);
db:AddToDefaults("global.layoutsByChar", {});
db:AddToDefaults("global.core", {
  migratedLegacyLayoutProfiles = {};
  layoutProfileMigrationVersion = CURRENT_MIGRATION_VERSION;
});

local LayoutProfiles = obj:CreateInterface("LayoutProfiles", {});

local function NormalizeLayoutName(layoutName)
  if (obj:IsString(layoutName) and layoutName ~= tk.Strings.Empty) then
    return layoutName;
  end

  if (obj:IsString(db.profile.layout) and db.profile.layout ~= tk.Strings.Empty) then
    return db.profile.layout;
  end

  return "DPS";
end

local function GetPlayerKey(playerKey)
  if (obj:IsString(playerKey) and playerKey ~= tk.Strings.Empty) then
    return playerKey;
  end

  return tk:GetPlayerKey();
end

local function IsProfilePerCharacterEnabled()
  return not (
    obj:IsTable(db.global.core)
    and obj:IsTable(db.global.core.setup)
    and db.global.core.setup.profilePerCharacter == false
  );
end

local function GetDefaultProfileName(layoutName, playerKey)
  layoutName = NormalizeLayoutName(layoutName);
  local profileSuffix = (layoutName == "DPS") and "Damage" or layoutName;

  if (IsProfilePerCharacterEnabled()) then
    return string.format("%s-%s", GetPlayerKey(playerKey), profileSuffix);
  end

  return DEFAULT_LAYOUT_PROFILES[layoutName] or ("MayronUI-" .. profileSuffix);
end

local function GetLegacyProfileAliases(layoutName, playerKey)
  layoutName = NormalizeLayoutName(layoutName);
  local aliases = obj:PopTable();

  if (layoutName == "DPS") then
    if (IsProfilePerCharacterEnabled()) then
      aliases[1] = string.format("%s-DPS", GetPlayerKey(playerKey));
    else
      aliases[1] = "MayronUI-DPS";
    end
  end

  return aliases;
end

local function EnsureMigrationState()
  if (not obj:IsTable(db.global.core)) then
    db.global.core = {};
  end

  if (not obj:IsTable(db.global.core.migratedLegacyLayoutProfiles)) then
    db.global.core.migratedLegacyLayoutProfiles = {};
  end

  return db.global.core.migratedLegacyLayoutProfiles;
end

local function EnsureLayoutProfileMappings()
  if (not obj:IsTable(db.global.layoutProfiles)) then
    db.global.layoutProfiles = {};
  end

  if (not IsProfilePerCharacterEnabled()) then
    for layoutName, profileName in pairs(DEFAULT_LAYOUT_PROFILES) do
      if (not obj:IsString(db.global.layoutProfiles[layoutName])
          or db.global.layoutProfiles[layoutName] == tk.Strings.Empty) then
        db.global.layoutProfiles[layoutName] = profileName;
      end
    end
  end

  return db.global.layoutProfiles;
end

local function AddKnownLayoutNames(layoutNames, source)
  if (not obj:IsTable(source)) then
    return;
  end

  if (obj:IsFunction(source.GetUntrackedTable)) then
    source = source:GetUntrackedTable();
  end

  for layoutName, value in pairs(source) do
    if (value ~= nil and value ~= false) then
      layoutNames[NormalizeLayoutName(layoutName)] = true;
    end
  end
end

local function GetKnownLayoutNames(playerKey)
  local layoutNames = obj:PopTable();

  for _, layoutName in ipairs(DEFAULT_LAYOUTS) do
    layoutNames[layoutName] = true;
  end

  AddKnownLayoutNames(layoutNames, db.global.layoutProfiles);
  AddKnownLayoutNames(layoutNames, db.global.layouts);

  if (obj:IsTable(db.global.layoutsByChar)) then
    AddKnownLayoutNames(layoutNames, db.global.layoutsByChar[GetPlayerKey(playerKey)]);
  end

  return layoutNames;
end

local function CopyValue(value)
  if (obj:IsTable(value)) then
    return tk.Tables:Copy(value, true);
  end

  return value;
end

local function GetRawDatabase()
  return _G.MayronUIdb;
end

local function GetRawProfileTable(profileName)
  local rawDatabase = GetRawDatabase();

  if (obj:IsTable(rawDatabase) and obj:IsTable(rawDatabase.profiles)) then
    return rawDatabase.profiles[profileName];
  end

  return nil;
end

local function IsSparseLayoutProfile(profileName)
  local rawProfile = GetRawProfileTable(profileName);

  if (not obj:IsTable(rawProfile)) then
    return false;
  end

  -- Older broken layout-profile builds only carried a handful of raw keys,
  -- which caused whole modules like Minimap to disappear in healer/dps.
  return rawProfile.minimap == nil
    or rawProfile.actionbars == nil
    or rawProfile.inventory == nil
    or rawProfile.tooltips == nil;
end

local function SanitizeClonedProfileData(profileData)
  if (not obj:IsTable(profileData)) then
    return profileData;
  end

  -- Layouts are full profiles now. Legacy snapshot state should never be
  -- carried forward into the cloned layout profiles.
  profileData.layoutStates = nil;
  profileData.freshInstall = nil;

  return profileData;
end

local function WithSuppressedProfileChange(callback)
  local previousState = MayronUI.__suppressProfileChangeCallback;
  MayronUI.__suppressProfileChangeCallback = true;

  local ok, resultA, resultB, resultC = pcall(callback);
  MayronUI.__suppressProfileChangeCallback = previousState;

  if (not ok) then
    error(resultA);
  end

  return resultA, resultB, resultC;
end

local function WithTemporaryProfile(profileName, callback)
  local currentProfile = db:GetCurrentProfile();

  return WithSuppressedProfileChange(function()
    if (currentProfile ~= profileName) then
      db:SetProfile(profileName);
    end

    local ok, resultA, resultB, resultC = pcall(callback);

    if (currentProfile ~= profileName) then
      db:SetProfile(currentProfile);
    end

    if (not ok) then
      error(resultA);
    end

    return resultA, resultB, resultC;
  end);
end

function LayoutProfiles:NormalizeLayoutName(layoutName)
  return NormalizeLayoutName(layoutName);
end

function LayoutProfiles:IsProfilePerCharacterEnabled()
  return IsProfilePerCharacterEnabled();
end

function LayoutProfiles:GetCanonicalProfileName(layoutName, playerKey)
  return GetDefaultProfileName(layoutName, playerKey);
end

function LayoutProfiles:GetManagedProfilePaths()
  return legacyManagedProfilePaths;
end

function LayoutProfiles:GetProfileName(layoutName, playerKey)
  layoutName = NormalizeLayoutName(layoutName);

  if (IsProfilePerCharacterEnabled()) then
    return GetDefaultProfileName(layoutName, playerKey);
  end

  local layoutProfiles = EnsureLayoutProfileMappings();
  local profileName = layoutProfiles[layoutName];
  if (not obj:IsString(profileName) or profileName == tk.Strings.Empty) then
    profileName = GetDefaultProfileName(layoutName);
    layoutProfiles[layoutName] = profileName;
  end

  return profileName;
end

function LayoutProfiles:SetProfileName(layoutName, profileName)
  layoutName = NormalizeLayoutName(layoutName);
  local layoutProfiles = EnsureLayoutProfileMappings();

  if (IsProfilePerCharacterEnabled()) then
    if (profileName == false or profileName == nil) then
      layoutProfiles[layoutName] = nil;
    end

    return;
  end

  layoutProfiles[layoutName] = profileName;
end

function LayoutProfiles:GetLayoutNameForProfile(profileName, playerKey)
  if (not obj:IsString(profileName) or profileName == tk.Strings.Empty) then
    return nil;
  end

  local layoutNames = GetKnownLayoutNames(playerKey);

  for layoutName in pairs(layoutNames) do
    if (self:GetProfileName(layoutName, playerKey) == profileName) then
      obj:PushTable(layoutNames);
      return layoutName;
    end

    local legacyAliases = GetLegacyProfileAliases(layoutName, playerKey);
    for _, legacyProfileName in ipairs(legacyAliases) do
      if (legacyProfileName == profileName) then
        obj:PushTable(legacyAliases);
        obj:PushTable(layoutNames);
        return layoutName;
      end
    end
    obj:PushTable(legacyAliases);
  end

  obj:PushTable(layoutNames);
  return nil;
end

function LayoutProfiles:ProfileExists(profileName)
  return db:ProfileExists(profileName);
end

function LayoutProfiles:ApplyToProfile(profileName, callback)
  obj:Assert(obj:IsString(profileName), "profileName expected");
  obj:Assert(obj:IsFunction(callback), "callback expected");

  if (not db:ProfileExists(profileName)) then
    local currentProfile = db:GetCurrentProfile();

    WithSuppressedProfileChange(function()
      db:SetProfile(profileName);

      if (currentProfile ~= profileName) then
        db:SetProfile(currentProfile);
      end
    end);
  end

  return WithTemporaryProfile(profileName, callback);
end

function LayoutProfiles:CreateOrReplaceProfile(profileName, sourceProfileName)
  obj:Assert(obj:IsString(profileName), "profileName expected");

  local sourceProfileExport;

  if (obj:IsString(sourceProfileName) and db:ProfileExists(sourceProfileName)) then
    sourceProfileExport = db:ExportProfile(sourceProfileName);
  end

  WithSuppressedProfileChange(function()
    db:ResetProfile(profileName);

    if (obj:IsString(sourceProfileExport) and sourceProfileExport ~= tk.Strings.Empty) then
      db:ImportProfile(sourceProfileExport, profileName);

      local rawProfile = GetRawProfileTable(profileName);
      SanitizeClonedProfileData(rawProfile);
    end
  end);
end

function LayoutProfiles:EnsureLayoutProfile(layoutName, sourceProfileName)
  layoutName = NormalizeLayoutName(layoutName);

  local profileName = self:GetProfileName(layoutName);
  if (not db:ProfileExists(profileName)) then
    local legacyAliases = GetLegacyProfileAliases(layoutName);
    local migrationSourceProfile = sourceProfileName or db:GetCurrentProfile();

    for _, legacyProfileName in ipairs(legacyAliases) do
      if (db:ProfileExists(legacyProfileName)) then
        migrationSourceProfile = legacyProfileName;
        break;
      end
    end

    self:CreateOrReplaceProfile(profileName, migrationSourceProfile);
    obj:PushTable(legacyAliases);
  else
    local legacyAliases = GetLegacyProfileAliases(layoutName);
    obj:PushTable(legacyAliases);
  end

  return profileName;
end

function LayoutProfiles:CleanupObsoleteCharacterProfiles(playerKey, preserveProfileName)
  playerKey = GetPlayerKey(playerKey);

  local obsoleteProfiles = obj:PopTable();
  obsoleteProfiles[playerKey] = true;

  for _, layoutName in ipairs(DEFAULT_LAYOUTS) do
    local legacyAliases = GetLegacyProfileAliases(layoutName, playerKey);

    for _, legacyProfileName in ipairs(legacyAliases) do
      if (obj:IsString(legacyProfileName) and legacyProfileName ~= preserveProfileName) then
        obsoleteProfiles[legacyProfileName] = true;
      end
    end

    obj:PushTable(legacyAliases);
  end

  WithSuppressedProfileChange(function()
    for obsoleteProfileName in pairs(obsoleteProfiles) do
      if (obsoleteProfileName ~= preserveProfileName and db:ProfileExists(obsoleteProfileName)) then
        db:RemoveProfile(obsoleteProfileName);
      end
    end
  end);

  obj:PushTable(obsoleteProfiles);
end

function LayoutProfiles:EnsureDefaultLayoutProfiles(sourceProfileName)
  sourceProfileName = sourceProfileName or db:GetCurrentProfile();

  for _, layoutName in ipairs(DEFAULT_LAYOUTS) do
    local profileName = self:GetProfileName(layoutName);

    if (not db:ProfileExists(profileName)) then
      self:CreateOrReplaceProfile(profileName, sourceProfileName);
    end
  end
end

function LayoutProfiles:ActivateLayoutProfile(layoutName, sourceProfileName)
  local profileName = self:EnsureLayoutProfile(layoutName, sourceProfileName);

  WithSuppressedProfileChange(function()
    db:SetProfile(profileName);
  end);

  db.profile.layout = NormalizeLayoutName(layoutName);
  self:CleanupObsoleteCharacterProfiles(nil, profileName);
  return profileName;
end

function LayoutProfiles:SyncCurrentProfileLayoutName()
  local currentProfile = db:GetCurrentProfile();
  local mappedLayout = self:GetLayoutNameForProfile(currentProfile);

  if (mappedLayout) then
    db.profile.layout = mappedLayout;
    return mappedLayout;
  end

  local currentLayout = NormalizeLayoutName(db.profile.layout);
  db.profile.layout = currentLayout;
  return currentLayout;
end

function LayoutProfiles:MigrateLegacyLayoutStates(sourceProfileName)
  sourceProfileName = sourceProfileName or db:GetCurrentProfile();

  local migratedProfiles = EnsureMigrationState();
  local migrationState = migratedProfiles[sourceProfileName];
  if (migrationState == CURRENT_MIGRATION_VERSION) then
    return false;
  end

  local legacyLayoutStates;

  self:ApplyToProfile(sourceProfileName, function()
    local savedProfile = obj:IsTable(db.profile) and obj:IsFunction(db.profile.GetSavedVariable)
      and db.profile:GetSavedVariable();

    if (obj:IsTable(savedProfile) and obj:IsTable(savedProfile.layoutStates)) then
      legacyLayoutStates = tk.Tables:Copy(savedProfile.layoutStates, true);
    end
  end);

  if (not (obj:IsTable(legacyLayoutStates) and next(legacyLayoutStates))) then
    migratedProfiles[sourceProfileName] = CURRENT_MIGRATION_VERSION;
    return false;
  end

  for layoutName, layoutState in pairs(legacyLayoutStates) do
    if (obj:IsTable(layoutState)) then
      local normalizedLayout = NormalizeLayoutName(layoutName);
      local targetProfileName = self:EnsureLayoutProfile(normalizedLayout, sourceProfileName);

      self:ApplyToProfile(targetProfileName, function()
        local savedProfile = obj:IsTable(db.profile) and obj:IsFunction(db.profile.GetSavedVariable)
          and db.profile:GetSavedVariable();

        if (not obj:IsTable(savedProfile)) then
          return;
        end

        for _, profilePath in ipairs(legacyManagedProfilePaths) do
          if (layoutState[profilePath] ~= nil) then
            -- Migrate legacy layout state directly into the raw saved profile.
            -- Using db:SetPathValue here forces MayronDB to stringify/refresh
            -- very large legacy tables, which can exceed script time.
            savedProfile[profilePath] = CopyValue(layoutState[profilePath]);
          end
        end

        savedProfile.layout = normalizedLayout;
      end);
    end
  end

  -- Keep the legacy data untouched for safety, but stop reading it after a
  -- successful migration. Any remaining legacy profiles migrate when activated.
  migratedProfiles[sourceProfileName] = CURRENT_MIGRATION_VERSION;
  return true;
end

obj:Export(LayoutProfiles, "MayronUI.LayoutProfiles");
