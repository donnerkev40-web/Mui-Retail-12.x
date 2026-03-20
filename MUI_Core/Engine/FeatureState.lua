local _G = _G;
local MayronUI = _G.MayronUI;
local _, db, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.FeatureState", true)) then
  return;
end

local FeatureRegistry = obj:Import("MayronUI.FeatureRegistry");
local string_gmatch = _G.string.gmatch;

local FeatureState = obj:CreateInterface("FeatureState", {});

local function GetFeaturesRoot()
  if (not obj:IsTable(db.profile)) then
    return FeatureRegistry:GetDefaults();
  end

  if (not obj:IsTable(db.profile.features)) then
    db.profile.features = {};
  end

  return db.profile.features;
end

local function TraverseFeaturePath(featurePath)
  if (not obj:IsString(featurePath) or featurePath == "") then
    return nil;
  end

  local node = GetFeaturesRoot();

  for segment in string_gmatch(featurePath, "[^%.]+") do
    if (not obj:IsTable(node)) then
      return nil;
    end

    node = node[segment];
  end

  return node;
end

function FeatureState:GetValue(featurePath)
  return TraverseFeaturePath(featurePath);
end

function FeatureState:IsEnabled(featurePath)
  local value = TraverseFeaturePath(featurePath);

  if (value == nil) then
    return true;
  end

  return value == true;
end

function FeatureState:IsModuleEnabled(moduleKey)
  local featurePath = FeatureRegistry:GetModuleFeaturePath(moduleKey);

  if (not obj:IsString(featurePath)) then
    return true;
  end

  return self:IsEnabled(featurePath);
end

obj:Export(FeatureState, "MayronUI.FeatureState");
