local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ModuleRegistry", true)) then
  return;
end

local ModuleRegistry = obj:CreateInterface("ModuleRegistry", {});
local definitions = {};
local runtime = {};

function ModuleRegistry:RegisterDefinition(moduleKey, metadata)
  if (obj:IsString(moduleKey) and obj:IsTable(metadata)) then
    definitions[moduleKey] = metadata;
  end
end

function ModuleRegistry:GetDefinition(moduleKey)
  return definitions[moduleKey];
end

function ModuleRegistry:RegisterRuntimeModule(moduleKey, moduleName, initializeOnDemand, classRef)
  if (not obj:IsString(moduleKey)) then
    return;
  end

  runtime[moduleKey] = runtime[moduleKey] or {};
  runtime[moduleKey].moduleKey = moduleKey;
  runtime[moduleKey].moduleName = moduleName or moduleKey;
  runtime[moduleKey].initializeOnDemand = initializeOnDemand == true;
  runtime[moduleKey].class = classRef;
end

function ModuleRegistry:AttachInstance(moduleKey, instance)
  if (obj:IsString(moduleKey)) then
    runtime[moduleKey] = runtime[moduleKey] or {};
    runtime[moduleKey].instance = instance;
  end
end

function ModuleRegistry:GetRuntimeModule(moduleKey)
  return runtime[moduleKey];
end

obj:Export(ModuleRegistry, "MayronUI.ModuleRegistry");
