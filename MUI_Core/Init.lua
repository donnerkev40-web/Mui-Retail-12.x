-- luacheck: ignore MayronUI LibStub self 143 631
local addOnName = ...;

local _G = _G;
local pairs, CreateFont = _G.pairs, _G.CreateFont;
local hooksecurefunc = _G.hooksecurefunc;
local C_AddOns = _G.C_AddOns;
local C_UnitAuras = _G.C_UnitAuras;
local C_Spell = _G.C_Spell;
local obj = _G.MayronObjects:GetFramework(); ---@type MayronObjects

if (not _G.IsAddOnLoaded and C_AddOns and C_AddOns.IsAddOnLoaded) then
  _G.IsAddOnLoaded = C_AddOns.IsAddOnLoaded;
end

if (not _G.LoadAddOn and C_AddOns and C_AddOns.LoadAddOn) then
  _G.LoadAddOn = C_AddOns.LoadAddOn;
end

if (not _G.EnableAddOn and C_AddOns and C_AddOns.EnableAddOn) then
  _G.EnableAddOn = C_AddOns.EnableAddOn;
end

if (not _G.DisableAddOn and C_AddOns and C_AddOns.DisableAddOn) then
  _G.DisableAddOn = C_AddOns.DisableAddOn;
end

if (not _G.GetNumAddOns and C_AddOns and C_AddOns.GetNumAddOns) then
  _G.GetNumAddOns = C_AddOns.GetNumAddOns;
end

if (not _G.GetAddOnInfo and C_AddOns and C_AddOns.GetAddOnInfo) then
  _G.GetAddOnInfo = function(indexOrName)
    local info = C_AddOns.GetAddOnInfo(indexOrName);

    if (type(info) == "table") then
      return info.name, info.title, info.notes, info.loadable, info.reason, info.security, info.newVersion;
    end

    return info;
  end
end

if (not _G.GetAddOnMetadata and C_AddOns and C_AddOns.GetAddOnMetadata) then
  _G.GetAddOnMetadata = C_AddOns.GetAddOnMetadata;
end

if (not _G.UnitAura and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
  local AuraUtil = _G.AuraUtil;
  local pcall = _G.pcall;
  local type = _G.type;

  local function SafeGetAuraDataByIndex(unitID, auraIndex, filter)
    if (type(unitID) ~= "string" or unitID == "") then
      return;
    end

    local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unitID, auraIndex, filter);
    if (ok and type(auraData) == "table") then
      return auraData;
    end
  end

  local function SafeFindAuraByName(auraName, unitID, filter)
    if (not (AuraUtil and AuraUtil.FindAuraByName)) then
      return;
    end

    if (type(unitID) ~= "string" or unitID == "") then
      return;
    end

    local ok, auraData = pcall(AuraUtil.FindAuraByName, auraName, unitID, filter);
    if (ok and type(auraData) == "table") then
      return auraData;
    end
  end

  local function GetAuraData(unitID, indexOrName, filter)
    if (type(indexOrName) == "number") then
      return SafeGetAuraDataByIndex(unitID, indexOrName, filter);
    end

    if (type(indexOrName) ~= "string") then
      return;
    end

    local auraData = SafeFindAuraByName(indexOrName, unitID, filter);
    if (auraData) then
      return auraData;
    end

    local auraIndex = 1;
    while (true) do
      auraData = SafeGetAuraDataByIndex(unitID, auraIndex, filter);
      if (type(auraData) ~= "table") then
        break;
      end

      if (auraData.name == indexOrName) then
        return auraData;
      end

      auraIndex = auraIndex + 1;
    end
  end

  local function UnpackAuraData(auraData)
    if (type(auraData) ~= "table") then
      return;
    end

    local applications = auraData.applications or auraData.charges or auraData.stackCount;
    local debuffType = auraData.dispelName or auraData.debuffType;

    return auraData.name, auraData.icon, applications, debuffType,
      auraData.duration, auraData.expirationTime, auraData.sourceUnit,
      auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId,
      auraData.canApplyAura, auraData.isBossAura, auraData.isFromPlayerOrPlayerPet,
      auraData.nameplateShowAll, auraData.timeMod, nil, nil, nil;
  end

  _G.UnitAura = function(unitID, indexOrName, filter)
    local auraData = GetAuraData(unitID, indexOrName, filter);
    return UnpackAuraData(auraData);
  end
end

if (not _G.UnitBuff and _G.UnitAura) then
  _G.UnitBuff = function(unitID, indexOrName, filter)
    local auraFilter = "HELPFUL";

    if (type(filter) == "string" and filter ~= "") then
      auraFilter = auraFilter .. "|" .. filter;
    end

    return _G.UnitAura(unitID, indexOrName, auraFilter);
  end
end

if (not _G.UnitDebuff and _G.UnitAura) then
  _G.UnitDebuff = function(unitID, indexOrName, filter)
    local auraFilter = "HARMFUL";

    if (type(filter) == "string" and filter ~= "") then
      auraFilter = auraFilter .. "|" .. filter;
    end

    return _G.UnitAura(unitID, indexOrName, auraFilter);
  end
end

if (C_Spell) then
  local function GetRetailSpellInfo(spellIdentifier)
    if (not C_Spell.GetSpellInfo) then
      return;
    end

    local spellInfo = C_Spell.GetSpellInfo(spellIdentifier);
    if (type(spellInfo) ~= "table") then
      return;
    end

    local icon = spellInfo.iconID or spellInfo.originalIconID;
    return spellInfo.name, nil, icon, spellInfo.castTime, spellInfo.minRange,
      spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID;
  end

  if (not _G.GetSpellInfo) then
    _G.GetSpellInfo = GetRetailSpellInfo;
  end

  if (not _G.GetSpellTexture) then
    _G.GetSpellTexture = function(spellIdentifier)
      if (C_Spell.GetSpellTexture) then
        return C_Spell.GetSpellTexture(spellIdentifier);
      end

      local _, _, icon = GetRetailSpellInfo(spellIdentifier);
      return icon;
    end
  end

  if (not _G.GetSpellCooldown and C_Spell.GetSpellCooldown) then
    _G.GetSpellCooldown = function(spellIdentifier)
      local cooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier);
      if (type(cooldownInfo) ~= "table") then
        return 0, 0, 0, 1;
      end

      local enabled = cooldownInfo.isEnabled;
      if (enabled == nil) then
        enabled = cooldownInfo.enabled;
      end

      return cooldownInfo.startTime or 0, cooldownInfo.duration or 0,
        enabled and 1 or 0, cooldownInfo.modRate or 1;
    end
  end
end

if (not _G.FillLocalizedClassList) then
  _G.FillLocalizedClassList = function(targetTable, isFemale)
    if (type(targetTable) ~= "table") then
      return;
    end

    local sourceTable = isFemale and _G.LOCALIZED_CLASS_NAMES_FEMALE or _G.LOCALIZED_CLASS_NAMES_MALE;
    if (type(sourceTable) ~= "table") then
      return;
    end

    for classToken, localizedName in pairs(sourceTable) do
      targetTable[classToken] = localizedName;
    end
  end
end

---@class MayronUI
local MayronUI = {};
_G.MayronUI = MayronUI;

---@class MayronUI.Toolkit
local tk = {};

---@class MayronUI.GUIBuilder
local gui = {};

local db = obj:Import("MayronDB").Static:CreateDatabase(addOnName, "MayronUIdb", nil, "MayronUI"); ---@type MayronDB
local L = _G.LibStub("AceLocale-3.0"):GetLocale("MayronUI"); ---@type AceLocale.Localizations

---@class MayronUI.CoreComponents
---@field EventManager MayronUI.EventManager
local components = {
  Toolkit = tk;
  Database = db;
  GUIBuilder = gui;
  Objects = obj;
  Locale = L;
};

---Gets the core components of MayronUI
---@return MayronUI.Toolkit, MayronDB, MayronUI.EventManager, MayronUI.GUIBuilder, MayronObjects, AceLocale.Localizations
function MayronUI:GetCoreComponents()
  return tk, db, components.EventManager, gui, obj, L;
end

---@param componentName string
---@param silent boolean?
---@return table
function MayronUI:GetComponent(componentName, silent)
  tk:Assert(silent or obj:IsString(componentName), "Invalid component '%s'", componentName);

  local component = components[componentName];
  tk:Assert(silent or obj:IsTable(component), "Invalid component '%s'", componentName);

  return component;
end

---@param componentName string
---@param component table
function MayronUI:AddComponent(componentName, component)
  components[componentName] = component;
end

---@param componentName string
---@return table
function MayronUI:NewComponent(componentName)
  local component = {};
  components[componentName] = component;
  return component;
end

--------------------------------
--- On Database StartUp
--------------------------------
db:OnStartUp(function(self, sv)
  -- setup globals:
  MayronUI.db = self;

  -- Migration Code:
  for _, profile in pairs(sv.profiles) do
    profile.actionBarPanel = nil;
    profile.sidebar = nil;
  end

  local r, g, b = tk:GetThemeColor();

  local myFont = CreateFont("MUI_FontNormal");
  myFont:SetFontObject("GameFontNormal");
  myFont:SetTextColor(r, g, b);

  myFont = CreateFont("MUI_FontSmall");
  myFont:SetFontObject("GameFontNormalSmall");
  myFont:SetTextColor(r, g, b);

  myFont = CreateFont("MUI_FontLarge");
  myFont:SetFontObject("GameFontNormalLarge");
  myFont:SetTextColor(r, g, b);

  -- Load Media using LibSharedMedia --------------
  local media = tk.Constants.LSM;
  local types = media.MediaType;
  local mayronUIFont = tk:GetAssetFilePath("Fonts\\MayronUI.ttf");
  local prototypeFont = tk:GetAssetFilePath("Fonts\\Prototype.ttf");
  local indieFlowerFont = tk:GetAssetFilePath("Fonts\\IndieFlower-Regular.ttf");
  local orbitronFont = tk:GetAssetFilePath("Fonts\\Orbitron-Regular.ttf");
  local actionManFont = tk:GetAssetFilePath("Fonts\\ActionMan.ttf");
  local continuumMediumFont = tk:GetAssetFilePath("Fonts\\ContinuumMedium.ttf");
  local expresswayFont = tk:GetAssetFilePath("Fonts\\Expressway.ttf");
  local ptSansNarrowFont = tk:GetAssetFilePath("Fonts\\PTSansNarrow.ttf");
  local rotundaPommeraniaFont = tk:GetAssetFilePath("Fonts\\rotunda-pommerania.regular.ttf");

  media:Register(types.FONT, "MayronUI", mayronUIFont);
  media:Register(types.FONT, "Prototype", prototypeFont);
  media:Register(types.FONT, "Indie Flower", indieFlowerFont);
  media:Register(types.FONT, "Orbitron", orbitronFont);
  media:Register(types.FONT, "Action Man", actionManFont);
  media:Register(types.FONT, "Continuum Medium", continuumMediumFont);
  media:Register(types.FONT, "Expressway", expresswayFont);
  media:Register(types.FONT, "PT Sans Narrow", ptSansNarrowFont);
  media:Register(types.FONT, "Rotunda Pommerania", rotundaPommeraniaFont);
  media:Register(types.STATUSBAR, "MayronUI", tk:GetAssetFilePath("Textures\\Widgets\\Button.tga"));
  media:Register(types.BORDER, "Solid", tk.Constants.BACKDROP.edgeFile);
  media:Register(types.BORDER, "Glow", tk:GetAssetFilePath("Borders\\Glow.tga"));

  hooksecurefunc("MovieFrame_PlayMovie", function(s)
    s:SetFrameStrata("DIALOG");
  end);

  local totemUpdater = _G["TotemFrame_Update"];
  if (tk:IsClassic() and not obj:IsFunction(totemUpdater)) then
    _G["TotemFrame_Update"] = function() end;
  end

  tk:SetGameFont(self.global.core.fonts);
  tk:KillElement(_G.WorldMapFrame.BlackoutFrame);

  if (not tk:IsRetail()) then
    _G["DisplayInterfaceActionBlockedMessage"] = tk.Constants.DUMMY_FUNC;
  end

  if (tk.Constants.DEBUG_WHITELIST[tk:GetPlayerKey()])  then
    MayronUI.DEBUG_MODE = true;
    -- _G.SetCVar("ScriptErrors", "1");
    MayronUI:LogDebug("Debugging Enabled");
  end
end);
