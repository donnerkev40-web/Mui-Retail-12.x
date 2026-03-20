local _G = _G;
local MayronUI = _G.MayronUI;
local _, db, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore
local IsAddOnLoaded = _G.IsAddOnLoaded;
local FeatureState = obj:Import("MayronUI.FeatureState");

if (obj:Import("MayronUI.UniversalWindow.Providers", true)) then
  return;
end

local KalielsTrackerAdapter = obj:Import("MayronUI.UniversalWindow.KalielsTrackerAdapter");
local MoneyLooterAdapter = obj:Import("MayronUI.UniversalWindow.MoneyLooterAdapter");
local BlizzardDamageMeterAdapter = obj:Import("MayronUI.UniversalWindow.BlizzardDamageMeterAdapter");
local ZygorGuidesAdapter = obj:Import("MayronUI.UniversalWindow.ZygorGuidesAdapter");

local adapters = {
  none = {
    key = "none";
    title = L["Universal Window"];
    configTitle = L["None"];
  };
  kalielsTracker = KalielsTrackerAdapter;
  moneyLooter = MoneyLooterAdapter;
  damageMeter = BlizzardDamageMeterAdapter;
  zygorGuides = ZygorGuidesAdapter;
};

local selectableContentTypes = {
  "kalielsTracker";
  "moneyLooter";
  "damageMeter";
  "zygorGuides";
  "none";
};

local defaultSidebarTypes = {
  "kalielsTracker";
  "moneyLooter";
  "damageMeter";
  "zygorGuides";
  "none";
  "none";
};

local providerFeaturePaths = {
  kalielsTracker = "chat.universal.providers.kalielsTracker";
  moneyLooter = "chat.universal.providers.moneyLooter";
  damageMeter = "chat.universal.providers.damageMeter";
  zygorGuides = "chat.universal.providers.zygorGuides";
};

local Providers = obj:CreateInterface("UniversalWindowProviders", {});

function Providers:GetPreferredDefaultContent()
  if (not FeatureState:IsEnabled("chat.universal.enabled")) then
    return "none";
  end

  if (self:IsContentAvailable("kalielsTracker")) then
    return "kalielsTracker";
  end

  for _, contentType in ipairs(selectableContentTypes) do
    if (contentType ~= "none" and self:IsContentAvailable(contentType)) then
      return contentType;
    end
  end

  return "none";
end

function Providers.NormalizeContentType(value)
  for _, contentType in ipairs(selectableContentTypes) do
    if (value == contentType) then
      return value;
    end
  end

  return Providers:GetPreferredDefaultContent();
end

function Providers:GetSelectableContentTypes()
  local contentTypes = {};

  for _, contentType in ipairs(selectableContentTypes) do
    if (self:IsContentAvailable(contentType)) then
      contentTypes[#contentTypes + 1] = contentType;
    end
  end

  return contentTypes;
end

function Providers:GetSidebarIconTypes()
  local iconTypes = {};

  for _, contentType in ipairs(self:GetSelectableContentTypes()) do
    if (contentType ~= "none") then
      iconTypes[#iconTypes + 1] = contentType;
    end
  end

  return iconTypes;
end

function Providers:GetCurrentContent(value)
  if (value == nil and obj:IsTable(db.profile.chat)) then
    value = db.profile.chat.universalContent;
  end

  value = self.NormalizeContentType(value);

  if (not self:IsContentAvailable(value)) then
    return self:GetPreferredDefaultContent();
  end

  return value;
end

function Providers:IsActiveContent(contentType, currentValue)
  return self:GetCurrentContent(currentValue) == self.NormalizeContentType(contentType);
end

function Providers:IsContentAvailable(contentType)
  local normalizedContent = self.NormalizeContentType(contentType);
  local adapter = adapters[normalizedContent];

  if (not FeatureState:IsEnabled("chat.universal.enabled")) then
    return normalizedContent == "none";
  end

  if (normalizedContent == "none") then
    return true;
  end

  local featurePath = providerFeaturePaths[normalizedContent];
  if (featurePath and not FeatureState:IsEnabled(featurePath)) then
    return false;
  end

  if (not obj:IsTable(adapter)) then
    return false;
  end

  if (obj:IsTable(adapter.watchedAddOns)) then
    local hasLoadedAddOn = false;

    for addOnName in pairs(adapter.watchedAddOns) do
      if (IsAddOnLoaded(addOnName)) then
        hasLoadedAddOn = true;
        break;
      end
    end

    if (not hasLoadedAddOn) then
      return false;
    end
  end

  return true;
end

function Providers:GetAdapter(contentType)
  local normalizedContent = self.NormalizeContentType(contentType);
  return adapters[normalizedContent] or adapters.none;
end

function Providers:GetMetadata(contentType)
  local normalizedContent = self.NormalizeContentType(contentType);
  return adapters[normalizedContent] or adapters.none;
end

function Providers:GetSupportedIconTypes()
  return selectableContentTypes;
end

function Providers:GetDefaultSidebarTypes()
  return defaultSidebarTypes;
end

function Providers:GetConfigOptions()
  local options = {};

  for _, contentType in ipairs(selectableContentTypes) do
    if (self:IsContentAvailable(contentType)) then
      local metadata = adapters[contentType];
      local label = metadata and (metadata.configTitle or metadata.title) or contentType;
      options[label] = contentType;
    end
  end

  return options;
end

function Providers:GetWatchedAddOnNames()
  local names = {};

  for _, metadata in pairs(adapters) do
    if (obj:IsTable(metadata) and obj:IsTable(metadata.watchedAddOns)) then
      for addOnName in pairs(metadata.watchedAddOns) do
        names[addOnName] = true;
      end
    end
  end

  return names;
end

obj:Export(Providers, "MayronUI.UniversalWindow.Providers");
