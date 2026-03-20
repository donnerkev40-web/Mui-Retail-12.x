local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.LayoutManager", true)) then
  return;
end

local LayoutProfiles = obj:Import("MayronUI.LayoutProfiles");
local LayoutManager = obj:CreateInterface("LayoutManager", {});

local function GetPlayerKey(playerKey)
  if (obj:IsString(playerKey) and playerKey ~= tk.Strings.Empty) then
    return playerKey;
  end

  return tk:GetPlayerKey();
end

local function EnsureLegacyLayouts()
  if (not obj:IsTable(db.global.layouts)) then
    db.global.layouts = {};
  end

  return db.global.layouts;
end

local function EnsureCharacterLayouts(playerKey)
  playerKey = GetPlayerKey(playerKey);

  if (not obj:IsTable(db.global.layoutsByChar)) then
    db.global.layoutsByChar = {};
  end

  if (not obj:IsTable(db.global.layoutsByChar[playerKey])) then
    local clonedLayouts = {};
    local legacyLayouts = EnsureLegacyLayouts();

    if (obj:IsFunction(legacyLayouts.GetUntrackedTable)) then
      legacyLayouts = legacyLayouts:GetUntrackedTable();
    end

    if (obj:IsTable(legacyLayouts)) then
      for layoutName, layoutData in pairs(legacyLayouts) do
        if (obj:IsTable(layoutData)) then
          clonedLayouts[layoutName] = tk.Tables:Copy(layoutData, true);
        end
      end
    end

    db.global.layoutsByChar[playerKey] = clonedLayouts;
  end

  return db.global.layoutsByChar[playerKey];
end

local function GetLayoutContainer(playerKey)
  if (LayoutProfiles:IsProfilePerCharacterEnabled()) then
    return EnsureCharacterLayouts(playerKey);
  end

  return EnsureLegacyLayouts();
end

function LayoutManager:NormalizeLayoutName(layoutName)
  return LayoutProfiles:NormalizeLayoutName(layoutName);
end

function LayoutManager:GetPlayerKey(playerKey)
  return GetPlayerKey(playerKey);
end

function LayoutManager:IsProfilePerCharacterEnabled()
  return LayoutProfiles:IsProfilePerCharacterEnabled();
end

function LayoutManager:GetCanonicalProfileName(layoutName, playerKey)
  return LayoutProfiles:GetCanonicalProfileName(layoutName, playerKey);
end

function LayoutManager:GetProfileName(layoutName, playerKey)
  return LayoutProfiles:GetProfileName(layoutName, playerKey);
end

function LayoutManager:SetProfileName(layoutName, profileName)
  return LayoutProfiles:SetProfileName(layoutName, profileName);
end

function LayoutManager:GetLayoutNameForProfile(profileName, playerKey)
  return LayoutProfiles:GetLayoutNameForProfile(profileName, playerKey);
end

function LayoutManager:GetLayouts(playerKey)
  return GetLayoutContainer(playerKey);
end

function LayoutManager:IterateLayouts(playerKey)
  local layouts = GetLayoutContainer(playerKey);

  if (obj:IsFunction(layouts.Iterate)) then
    return layouts:Iterate();
  end

  return pairs(layouts);
end

function LayoutManager:LayoutExists(layoutName, playerKey)
  layoutName = self:NormalizeLayoutName(layoutName);
  local layouts = GetLayoutContainer(playerKey);
  return obj:IsTable(layouts[layoutName]);
end

function LayoutManager:GetLayoutData(layoutName, playerKey)
  layoutName = self:NormalizeLayoutName(layoutName);

  local layouts = GetLayoutContainer(playerKey);
  local layoutData = layouts[layoutName];

  if (not obj:IsTable(layoutData)) then
    layouts[layoutName] = obj:PopTable();
    layoutData = layouts[layoutName];
  end

  return layoutData;
end

function LayoutManager:SetLayoutData(layoutName, layoutData, playerKey)
  layoutName = self:NormalizeLayoutName(layoutName);
  local layouts = GetLayoutContainer(playerKey);
  layouts[layoutName] = layoutData;
  return layouts[layoutName];
end

function LayoutManager:DeleteLayout(layoutName, playerKey)
  layoutName = self:NormalizeLayoutName(layoutName);
  local layouts = GetLayoutContainer(playerKey);
  layouts[layoutName] = false;
end

function LayoutManager:RenameLayout(oldLayoutName, newLayoutName, playerKey)
  oldLayoutName = self:NormalizeLayoutName(oldLayoutName);
  newLayoutName = self:NormalizeLayoutName(newLayoutName);

  local layouts = GetLayoutContainer(playerKey);
  local oldLayoutData = layouts[oldLayoutName];

  if (not obj:IsTable(oldLayoutData) or layouts[newLayoutName]) then
    return false;
  end

  if (obj:IsFunction(oldLayoutData.GetSavedVariable)) then
    layouts[newLayoutName] = oldLayoutData:GetSavedVariable();
  else
    layouts[newLayoutName] = tk.Tables:Copy(oldLayoutData, true);
  end

  layouts[oldLayoutName] = false;
  return true;
end

function LayoutManager:ApplyToProfile(profileName, callback)
  return LayoutProfiles:ApplyToProfile(profileName, callback);
end

function LayoutManager:CreateOrReplaceProfile(profileName, sourceProfileName)
  return LayoutProfiles:CreateOrReplaceProfile(profileName, sourceProfileName);
end

function LayoutManager:EnsureLayoutProfile(layoutName, sourceProfileName)
  return LayoutProfiles:EnsureLayoutProfile(layoutName, sourceProfileName);
end

function LayoutManager:EnsureDefaultLayoutProfiles(sourceProfileName)
  return LayoutProfiles:EnsureDefaultLayoutProfiles(sourceProfileName);
end

function LayoutManager:ActivateLayoutProfile(layoutName, sourceProfileName)
  return LayoutProfiles:ActivateLayoutProfile(layoutName, sourceProfileName);
end

function LayoutManager:SyncCurrentProfileLayoutName()
  return LayoutProfiles:SyncCurrentProfileLayoutName();
end

function LayoutManager:MigrateLegacyLayoutStates(sourceProfileName)
  return LayoutProfiles:MigrateLegacyLayoutStates(sourceProfileName);
end

obj:Export(LayoutManager, "MayronUI.LayoutManager");
