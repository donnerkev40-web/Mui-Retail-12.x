local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ModuleLifecycle", true)) then
  return;
end

local FeatureState = obj:Import("MayronUI.FeatureState");
local ModuleLifecycle = obj:CreateInterface("ModuleLifecycle", {});

local function GetModuleKey(moduleOrKey)
  if (obj:IsString(moduleOrKey)) then
    return moduleOrKey;
  end

  if (obj:IsTable(moduleOrKey) and obj:IsFunction(moduleOrKey.GetModuleKey)) then
    return moduleOrKey:GetModuleKey();
  end
end

function ModuleLifecycle:ShouldInitializeModule(moduleOrKey)
  return FeatureState:IsModuleEnabled(GetModuleKey(moduleOrKey));
end

function ModuleLifecycle:ShouldEnableModule(moduleOrKey)
  return FeatureState:IsModuleEnabled(GetModuleKey(moduleOrKey));
end

function ModuleLifecycle:InitializeModule(module, ...)
  if (not (obj:IsTable(module) and obj:IsFunction(module.Initialize))) then
    return false;
  end

  if (not self:ShouldInitializeModule(module)) then
    return false;
  end

  module:Initialize(...);
  return true;
end

function ModuleLifecycle:SetModuleEnabled(module, enabled, ...)
  if (not (obj:IsTable(module) and obj:IsFunction(module.SetEnabled))) then
    return false;
  end

  module:SetEnabled(enabled and self:ShouldEnableModule(module), ...);
  return true;
end

obj:Export(ModuleLifecycle, "MayronUI.ModuleLifecycle");
