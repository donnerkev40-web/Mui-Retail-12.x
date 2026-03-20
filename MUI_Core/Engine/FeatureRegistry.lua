local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.FeatureRegistry", true)) then
  return;
end

local builtinFeatureDefaults = {
  coreui = {
    mainContainer = true;
    movableFrames = false;
    tutorial = false;
    afkDisplay = false;
    combatAlerts = false;
    errorHandler = true;
  };
  actionbars = {
    enabled = true;
    bottomBars = true;
    sideBars = true;
    bartenderCompatibility = false;
    blizzardSuppressor = false;
    microMenuReplacement = false;
  };
  auras = {
    enabled = false;
    frames = false;
    anchors = false;
    filters = false;
  };
  castBars = {
    enabled = true;
    frames = true;
    anchors = true;
    style = true;
  };
  chat = {
    enabled = true;
    windowShell = true;
    windowLayout = true;
    sideIcons = true;
    buttons = true;
    blizzardFrames = true;
    universal = {
      enabled = false;
      host = false;
      visibility = false;
      providers = {
        kalielsTracker = false;
        moneyLooter = false;
        damageMeter = false;
        zygorGuides = false;
      };
    };
  };
  datatext = {
    enabled = true;
  };
  inventory = {
    enabled = false;
    anchors = false;
    layout = false;
    filters = false;
    tabs = false;
    bagHooks = false;
    slotRenderer = false;
  };
  minimap = {
    enabled = true;
    buttons = true;
    widgets = true;
    layout = true;
  };
  resourceBars = {
    enabled = true;
    experience = false;
    reputation = false;
    artifact = false;
    azerite = false;
  };
  timerBars = {
    enabled = true;
    frames = true;
    anchors = true;
  };
  tooltips = {
    enabled = false;
    style = false;
    anchors = false;
    statusBars = false;
    auras = false;
    inspectCache = false;
  };
  unitPanels = {
    enabled = true;
    layout = false;
    shadowedUFBridge = false;
  };
};

local builtinModuleFeatureMap = {
  MainContainer = "coreui.mainContainer";
  MovableFramesModule = "coreui.movableFrames";
  TutorialModule = "coreui.tutorial";
  AFKDisplay = "coreui.afkDisplay";
  CombatAlerts = "coreui.combatAlerts";
  ErrorHandlerModule = "coreui.errorHandler";
  BottomActionBars = "actionbars.bottomBars";
  SideActionBars = "actionbars.sideBars";
  AurasModule = "auras.enabled";
  CastBarsModule = "castBars.enabled";
  ChatModule = "chat.enabled";
  UniversalWindowModule = "chat.universal.enabled";
  DataTextModule = "datatext.enabled";
  InventoryModule = "inventory.enabled";
  MiniMap = "minimap.enabled";
  ResourceBars = "resourceBars.enabled";
  TimerBars = "timerBars.enabled";
  Tooltips = "tooltips.enabled";
  UnitPanels = "unitPanels.enabled";
};

db:AddToDefaults("profile.features", builtinFeatureDefaults);

local FeatureRegistry = obj:CreateInterface("FeatureRegistry", {});
local moduleFeatureMap = tk.Tables:Copy(builtinModuleFeatureMap, true);

function FeatureRegistry:GetDefaults()
  return builtinFeatureDefaults;
end

function FeatureRegistry:GetModuleFeatureMap()
  return moduleFeatureMap;
end

function FeatureRegistry:RegisterModuleFeature(moduleKey, featurePath)
  if (obj:IsString(moduleKey) and obj:IsString(featurePath)
      and featurePath ~= tk.Strings.Empty) then
    moduleFeatureMap[moduleKey] = featurePath;
  end
end

function FeatureRegistry:GetModuleFeaturePath(moduleKey)
  if (not obj:IsString(moduleKey)) then
    return nil;
  end

  return moduleFeatureMap[moduleKey];
end

obj:Export(FeatureRegistry, "MayronUI.FeatureRegistry");
