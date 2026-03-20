local _G = _G;
local pairs = _G.pairs;
local next = _G.next;
local type = _G.type;

local _, setup = ...;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

local TARGET_PROFILE_NAME = "MayronUI";

local function DeepCopy(value)
  if (type(value) ~= "table") then
    return value;
  end

  return tk.Tables:Copy(value, true);
end

local function GetSourceProfileName()
  if (_G.Grid2 and obj:IsTable(_G.Grid2.db)
      and obj:IsFunction(_G.Grid2.db.GetCurrentProfile)) then
    local success, profileName = pcall(function()
      return _G.Grid2.db:GetCurrentProfile();
    end);

    if (success and obj:IsString(profileName) and profileName ~= tk.Strings.Empty) then
      return profileName;
    end
  end

  if (obj:IsTable(_G.Grid2DB)) then
    if (obj:IsTable(_G.Grid2DB.profileKeys)) then
      for _, profileName in pairs(_G.Grid2DB.profileKeys) do
        if (obj:IsString(profileName) and profileName ~= tk.Strings.Empty) then
          return profileName;
        end
      end
    end

    if (obj:IsTable(_G.Grid2DB.profiles)) then
      for profileName in pairs(_G.Grid2DB.profiles) do
        if (obj:IsString(profileName) and profileName ~= tk.Strings.Empty) then
          return profileName;
        end
      end
    end
  end
end

local function EnsureNamespaceProfile(namespaceName, sourceProfileName)
  local namespaces = _G.Grid2DB.namespaces;
  namespaces[namespaceName] = namespaces[namespaceName] or {};
  namespaces[namespaceName].profiles = namespaces[namespaceName].profiles or {};

  local sourceProfiles = namespaces[namespaceName].profiles;
  local sourceProfile = obj:IsString(sourceProfileName) and sourceProfiles[sourceProfileName];

  if (obj:IsTable(sourceProfile)) then
    sourceProfiles[TARGET_PROFILE_NAME] = DeepCopy(sourceProfile);
  elseif (not obj:IsTable(sourceProfiles[TARGET_PROFILE_NAME])) then
    sourceProfiles[TARGET_PROFILE_NAME] = {};
  end

  return sourceProfiles[TARGET_PROFILE_NAME];
end

local function NormalizeLayoutProfile(layoutProfile)
  if (not obj:IsTable(layoutProfile)) then
    return;
  end

  layoutProfile.FrameDisplay = "Always";
  layoutProfile.FrameLock = true;
  layoutProfile.layouts = layoutProfile.layouts or {};
  layoutProfile.layouts.solo = layoutProfile.layouts.solo or "By Group";
  layoutProfile.layouts.party = layoutProfile.layouts.party or "By Group";
  layoutProfile.layouts.raid = layoutProfile.layouts.raid or "By Group";
  layoutProfile.layouts.arena = layoutProfile.layouts.arena or "By Group";
end

local function NormalizeRootProfile(profile)
  if (not obj:IsTable(profile)) then
    return;
  end

  profile.__template = profile.__template or "Blizzard";
  profile.indicators = profile.indicators or {};
  profile.statuses = profile.statuses or {};
  profile.statusMap = profile.statusMap or {};
  profile.themes = profile.themes or { indicators = { [0] = {} } };
  profile.versions = profile.versions or {};
end

setup.import["Grid2"] = function()
  _G.Grid2DB = _G.Grid2DB or {};
  _G.Grid2DB.namespaces = _G.Grid2DB.namespaces or {};
  _G.Grid2DB.profiles = _G.Grid2DB.profiles or {};
  _G.Grid2DB.profileKeys = _G.Grid2DB.profileKeys or {};

  local sourceProfileName = GetSourceProfileName();
  local sourceProfile = obj:IsString(sourceProfileName) and _G.Grid2DB.profiles[sourceProfileName];

  if (obj:IsTable(sourceProfile)) then
    _G.Grid2DB.profiles[TARGET_PROFILE_NAME] = DeepCopy(sourceProfile);
  elseif (not obj:IsTable(_G.Grid2DB.profiles[TARGET_PROFILE_NAME])) then
    _G.Grid2DB.profiles[TARGET_PROFILE_NAME] = {};
  end

  NormalizeRootProfile(_G.Grid2DB.profiles[TARGET_PROFILE_NAME]);
  NormalizeLayoutProfile(EnsureNamespaceProfile("Grid2Layout", sourceProfileName));
  EnsureNamespaceProfile("Grid2Frame", sourceProfileName);

  for playerKey in pairs(_G.Grid2DB.profileKeys) do
    _G.Grid2DB.profileKeys[playerKey] = TARGET_PROFILE_NAME;
  end

  if (next(_G.Grid2DB.profileKeys) == nil) then
    _G.Grid2DB.profileKeys[tk:GetPlayerKey()] = TARGET_PROFILE_NAME;
  end

  return 1;
end
