--luacheck: ignore self 143 631
local addOnName = ...;
local _G = _G;
local MayronUI = _G.MayronUI;
local LibStub = _G.LibStub;
local issecretvalue = _G.issecretvalue;
local issecrettable = _G.issecrettable;

local tk, _, _, _, obj, L = MayronUI:GetCoreComponents();

---@type MayronDB
local MayronDB = obj:Import("MayronDB");

---@type MayronDB
local db = MayronDB.Static:CreateDatabase(addOnName, "MUI_TimerBarsDb", nil, "MUI TimerBars");

_G.MUI_TimerBars = {}; -- Create new global

local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo;
local unpack, UnitIsDeadOrGhost = _G.unpack, _G.UnitIsDeadOrGhost;
local string, pairs, ipairs, max = _G.string, _G.pairs, _G.ipairs, _G.math.max;
local UnitExists, UnitGUID, UIParent = _G.UnitExists, _G.UnitGUID, _G.UIParent;
local table, GetTime, UnitAura = _G.table, _G.GetTime, _G.UnitAura;
local C_UnitAuras = _G.C_UnitAuras;
local UnitAffectingCombat = _G.UnitAffectingCombat;
local GetSpellInfo = _G.GetSpellInfo;
local CreateFrame = _G.CreateFrame;

local RepositionBars;

local UNKNOWN_EXPIRATION = 100000;
local HELPFUL, HARMFUL, DEBUFF, BUFF, UP = "HELPFUL", "HARMFUL", "DEBUFF", "BUFF", "UP";
local TIMER_FIELD_UPDATE_FREQUENCY = 0.05;
local TIMER_FIELD_AURA_REFRESH_FREQUENCY = 0.20;
local UNKNOWN_AURA_TYPE = "Unknown aura type '%s'.";
local DEBUFF_MAX_DISPLAY = _G.DEBUFF_MAX_DISPLAY;
local BUFF_MAX_DISPLAY = _G.BUFF_MAX_DISPLAY;
local ICON_GAP = -1;
local OnCombatLogEvent, CheckUnitAuras;
local GetAuraInfoByIndex, GetAuraInfoByAuraID, GetAuraInfoByAuraName;

local UnitIDFieldPairs = {}; -- contains FieldName to unitID
local auraEventFrame;

if (tk:IsClassic()) then
  local LibClassicDurations = LibStub("LibClassicDurations");
  LibClassicDurations:Register("MayronUI");
  UnitAura = LibClassicDurations.UnitAuraWrapper;
end

-- Objects -----------------------------
---@class TimerBarsModule : BaseModule
local C_TimerBars = MayronUI:RegisterModule("TimerBars", L["Timer Bars"]);
MayronUI:AddComponent("TimerBarsDatabase", db);

---@type TimerBars
local TimerBars = MayronUI:ImportModule("TimerBars");

---@class TimerField
local C_TimerField = obj:CreateClass("TimerField");
C_TimerField.Static:AddFriendClass("TimerBars");

---@class TimerBar
local C_TimerBar = obj:CreateClass("TimerBar");
C_TimerBar.Static:AddFriendClass("TimerBars");

---@type Stack
local Stack = obj:Import("Pkg-Collections.Stack<T>");

-- Database: ---------------------------
db:AddToDefaults("profile", {
  enabled               = true;
  sortByExpirationTime  = true;
  showTooltips          = true;
  statusBarTexture      = "MayronUI";
  showUnknownExpiration = tk:IsClassic();

  border = {
    type = "Solid";
    size = 1;
    show = true;
  };

  colors = {
    background        = { 0, 0, 0, 0.6 };
    basicBuff         = { 0.15, 0.15, 0.15, 1 };
    basicDebuff       = { 0.76, 0.2, 0.2, 1 };
    border            = { 0, 0, 0, 1 };
    canStealOrPurge   = { 1, 0.5, 0.25, 1 };
    magic             = { 0.2, 0.6, 1, 1 };
    disease           = { 0.6, 0.4, 0, 1 };
    poison            = { 0.0, 0.6, 0, 1 };
    curse             = { 0.6, 0.0, 1, 1 };
  };

  fields = {};

  __templateField = {
    enabled   = true;
    direction = "UP"; -- or "DOWN"
    unitID    = "player";
    position = { "CENTER", "UIParent", "CENTER", 0, 0 },

    bar = {
      width   = 210;
      height  = 22;
      spacing = 1;
      maxBars = 10;
    };

    showIcons             = true;
    showSpark             = true;
    colorDebuffsByType    = true;
    colorStealOrPurge     = true;
    nonPlayerAlpha        = 0.7;

    auraName = {
      show        = true;
      fontSize    = 11;
      font        = "MUI_Font";
    };

    spellCount = {
      show     = true;
      fontSize = 16;
      font     = "MUI_Font";
      position = "LEFT";
      xOffset = -28;
    };

    timeRemaining = {
      show        = true;
      fontSize    = 11;
      font        = "MUI_Font";
    };

    filters = {
      showBuffs = true;
      showDebuffs = true;
      onlyPlayerBuffs   = true;
      onlyPlayerDebuffs = true;
      enableWhiteList   = false;
      enableBlackList   = false;
      whiteList         = {};
      blackList         = {};
    };
  };
});

db:OnStartUp(function(self)
  _G.MUI_TimerBars.db = self;

  MayronUI:Hook("CoreModule", "OnInitialized", function()
    TimerBars:Initialize();
  end);
end);

db:OnProfileChange(function()
  if (TimerBars:IsInitialized() and MayronUI:IsInstalled()) then
    TimerBars:ApplyProfileSettings();
    TimerBars:RefreshSettings();
    TimerBars:ExecuteAllUpdateFunctions();
  end
end);

-- C_TimerBars --------------------

function C_TimerBars:OnInitialize(data)
  data.loadedFields = obj:PopTable();

  -- create 2 default (removable from database) TimerFields
  data.options = {
    onExecuteAll = {
      first = {}; -- this is updated in ApplyProfileSettings
      ignore = {
        "filters";
      };
    };

    groups = {
      {
        patterns = { "fields%.[^.]+%.[^.]+" }; -- (i.e. "fields.Player.<setting>")

        onPre = function(value, keysList)
          keysList:PopFront();
          local fieldName = keysList:PopFront();
          local field = data.loadedFields[fieldName];
          local settingName = keysList:GetFront();

          -- this is where we create a TimerField if it is enabled
          if (obj:IsBoolean(field)) then
            if (not (field or (settingName == "enabled" and value))) then
              -- if not trying to enable a field because it is disabled, then do not continue
              return nil;
            end

            -- create field (it is enabled)
            field = C_TimerField(fieldName, data.settings);
            data.loadedFields[fieldName] = field; -- replace "true" with real object

            local unitID = field:GetUnitID();
            UnitIDFieldPairs[unitID] = field;
          end

          return field, fieldName;
        end;

        value = {
          ---@param field TimerField
          enabled = function(value, _, field)
            field:SetEnabled(value);
          end;

          ---@param field TimerField
          position = function(_, _, field)
            field:PositionField();
          end;

          ---@param field TimerField
          unitID = function(value, _, field)
            field:SetUnitID(value);
          end;

          ---@param field TimerField
          bar = function(_, _, field, fieldName)
            local fieldSettings = data.settings.fields[fieldName];
            local maxBars = fieldSettings.bar.maxBars;
            local barHeight = fieldSettings.bar.height;
            local barWidth = fieldSettings.bar.width;
            local spacing = fieldSettings.bar.spacing;

            local fieldHeight = (maxBars * (barHeight + spacing)) - spacing;
            field:SetSize(barWidth, fieldHeight);

            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetHeight(barHeight);
              bar:SetAuraNameShown(fieldSettings.auraName.show);
              bar:SetIconShown(fieldSettings.showIcons);
            end

            local fieldData = data:GetFriendData(field);
            RepositionBars(fieldData);
          end;

          ---@param field TimerField
          showIcons = function(value, _, field)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetIconShown(value);
            end
          end;

          ---@param field TimerField
          nonPlayerAlpha = function(value, _, field)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              if (bar.Source == UnitGUID("player")) then
                bar:SetAlpha(1);
              else
                bar:SetAlpha(value);
              end
            end
          end;

          ---@param field TimerField
          showSpark = function(value, _, field)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetSparkShown(value);
            end
          end;

          ---@param field TimerField
          colorDebuffsByType = function(_, _, field)
            field:RecheckAuras();
          end;

          ---@param field TimerField
          auraName = function(_, _, field, fieldName)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetAuraNameShown(data.settings.fields[fieldName].auraName.show);
            end
          end;

          ---@param field TimerField
          timeRemaining = function(_, _, field, fieldName)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetTimeRemainingShown(data.settings.fields[fieldName].timeRemaining.show);
            end
          end;

          ---@param field TimerField
          spellCount = function(_, _, field, fieldName)
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              bar:SetSpellCountShown(data.settings.fields[fieldName].spellCount.show);
            end
          end;

          ---@param field TimerField
          filters = function(_, _, field)
            if (field) then
              field:RecheckAuras();
            end
          end;
        };
      };
    };
  };

  self:ApplyProfileSettings();

  local function UpdateBorders()
    for _, field in pairs(UnitIDFieldPairs) do
      if (not obj:IsBoolean(field)) then
        for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
          bar:SetBorderShown(data.settings.border.show);
        end
      end
    end
  end

  self:RegisterUpdateFunctions(db.profile, {
    showTooltips = function(value)
      for _, field in pairs(UnitIDFieldPairs) do
        if (not obj:IsBoolean(field)) then
          for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
            bar:SetTooltipsEnabled(value);
          end
        end
      end
    end;

    statusBarTexture = function(value)
      for _, field in pairs(UnitIDFieldPairs) do
        if (not obj:IsBoolean(field)) then
          for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
            local barData = data:GetFriendData(bar);
            barData.slider:SetStatusBarTexture(tk.Constants.LSM:Fetch("statusbar", value));
          end
        end
      end
    end;

    colors = function(_, keysList)
      local colorName = keysList:PopBack();

      if (colorName == "border") then
        UpdateBorders();

      elseif (colorName == "background") then
        for _, field in pairs(UnitIDFieldPairs) do
          if (not obj:IsBoolean(field)) then
            for _, bar in obj:IterateArgs(field:GetAllTimerBars()) do
              local barData = data:GetFriendData(bar);
              barData.slider.bg:SetColorTexture(unpack(data.settings.colors.background));
            end
          end
        end
      else
        for _, field in pairs(UnitIDFieldPairs) do
          if (not obj:IsBoolean(field)) then
            field:RecheckAuras();
          end
        end
      end
    end;

    border = UpdateBorders;
  });
end

function C_TimerBars:OnInitialized(data)
  EnsureAuraEventFrame();

  if (data.settings.enabled) then
    self:SetEnabled(true); -- this executes all update functions
  end
end

function C_TimerBars:OnEnable()
  EnsureAuraEventFrame();
  CheckUnitAuras();
end

function C_TimerBars:OnDisable()
end

local function SafePushTable(tbl)
  if (obj:IsTable(tbl)) then
    obj:PushTable(tbl);
  end
end

local function NotSecretValue(value)
  return (not issecretvalue) or not issecretvalue(value);
end

local function NotSecretTable(value)
  return (not issecrettable) or not issecrettable(value);
end

local function GetSafeArithmeticResult(callback, fallback)
  local ok, result = pcall(callback);

  if (ok and obj:IsNumber(result)) then
    return result;
  end

  return fallback or 0;
end

local function GetSafeAuraTimeValue(value, fallback)
  if (not NotSecretValue(value) or not obj:IsNumber(value)) then
    return fallback or 0;
  end

  return GetSafeArithmeticResult(function()
    return value + 0;
  end, fallback or 0);
end

local function GetSafeAuraCountValue(value)
  if (not NotSecretValue(value) or not obj:IsNumber(value)) then
    return 0;
  end

  return GetSafeArithmeticResult(function()
    return value + 0;
  end, 0);
end

local function GetSafeAuraIdValue(value)
  if (not NotSecretValue(value) or not obj:IsNumber(value)) then
    return 0;
  end

  return GetSafeArithmeticResult(function()
    return value + 0;
  end, 0);
end

local function SafeToNumber(value)
  if (not NotSecretValue(value)) then
    return nil;
  end

  local result;
  local ok = pcall(function()
    local converted = tonumber(value);

    if (converted ~= nil) then
      local _ = converted + 0;
      result = converted;
    end
  end);

  if (ok and obj:IsNumber(result)) then
    return result;
  end

  return nil;
end

local function SafeToString(value)
  if (not NotSecretValue(value)) then
    return nil;
  end

  local result;
  local ok = pcall(function()
    if (obj:IsString(value)) then
      local _ = value:sub(1, 1);
      result = value;
    else
      local converted = tostring(value);
      local _ = converted:sub(1, 1);
      result = converted;
    end
  end);

  if (ok and obj:IsString(result)) then
    if (result == "nil" or result == "<no value>") then
      return nil;
    end

    return result;
  end

  return nil;
end

local function GetSafeTableValue(tbl, key)
  if (not obj:IsTable(tbl)) then
    return nil;
  end

  local result;
  local ok = pcall(function()
    result = tbl[key];
  end);

  if (ok and NotSecretValue(result)) then
    return result;
  end

  return nil;
end

local function NormalizeAuraInfo(auraInfo)
  if (not obj:IsTable(auraInfo)) then
    return nil;
  end

  local normalized = obj:PopTable(
    SafeToString(GetSafeTableValue(auraInfo, 1)),
    SafeToNumber(GetSafeTableValue(auraInfo, 2)) or SafeToString(GetSafeTableValue(auraInfo, 2)),
    SafeToNumber(GetSafeTableValue(auraInfo, 3)) or 0,
    SafeToString(GetSafeTableValue(auraInfo, 4)),
    SafeToNumber(GetSafeTableValue(auraInfo, 5)) or 0,
    SafeToNumber(GetSafeTableValue(auraInfo, 6)) or 0,
    SafeToString(GetSafeTableValue(auraInfo, 7)),
    false,
    nil,
    SafeToNumber(GetSafeTableValue(auraInfo, 10)) or 0
  );

  SafePushTable(auraInfo);
  return normalized;
end

-- Local Functions -------------------
do
  local SUB_EVENT_NAMES = {
    SPELL_AURA_REFRESH        = "SPELL_AURA_REFRESH";
    SPELL_AURA_APPLIED        = "SPELL_AURA_APPLIED";
    SPELL_AURA_APPLIED_DOSE   = "SPELL_AURA_APPLIED_DOSE";
    SPELL_AURA_REMOVED_DOSE   = "SPELL_AURA_REMOVED_DOSE";
    UNIT_DESTROYED            = "UNIT_DESTROYED";
    UNIT_DIED                 = "UNIT_DIED";
    UNIT_DISSIPATES           = "UNIT_DISSIPATES";
  };

  function OnCombatLogEvent()
    local payload = obj:PopTable(CombatLogGetCurrentEventInfo());
    local subEvent = payload[2];

    if (not SUB_EVENT_NAMES[subEvent]) then
      SafePushTable(payload);
      return
    end

    local sourceGuid = payload[4];
    local destGuid = payload[8];

    if (subEvent:find("UNIT")) then
      for unitID, field in pairs(UnitIDFieldPairs) do
        if (not obj:IsBoolean(field) and destGuid == UnitGUID(unitID)) then
          field:Hide();
        end
      end
    else
      -- guaranteed to always be the same for all registered events:
      local auraId = payload[12];
      local auraName = payload[13];
      local auraType = payload[15];

      if (auraType ~= BUFF and auraType ~= DEBUFF) then
        SafePushTable(payload);
        return;
      end

      ---@param field TimerField
      for _, field in pairs(UnitIDFieldPairs) do
        if (not obj:IsBoolean(field)) then
          local unitID = field:GetUnitID();

          if (UnitGUID(unitID) == destGuid) then
            field:UpdateBarsByAura(sourceGuid, auraId, auraName, auraType);
          end
        end
      end
    end

    SafePushTable(payload);
  end
end

function CheckUnitAuras()
  for _, field in pairs(UnitIDFieldPairs) do
    if (not obj:IsBoolean(field)) then
      field:RecheckAuras();
    end
  end
end

local function RefreshFieldForUnit(unitID)
  local field = UnitIDFieldPairs[unitID];

  if (obj:IsBoolean(field) or not obj:IsObject(field)) then
    return;
  end

  if (UnitExists(unitID) and not UnitIsDeadOrGhost(unitID)) then
    field:RecheckAuras();
  else
    field:RemoveAllAuras();
  end
end

local function EnsureAuraEventFrame()
  if (obj:IsWidget(auraEventFrame)) then
    return auraEventFrame;
  end

  auraEventFrame = CreateFrame("Frame", "MUI_TimerBarsAuraEventFrame");
  auraEventFrame:RegisterUnitEvent("UNIT_AURA", "player", "target", "focus", "pet", "vehicle");
  auraEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
  auraEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
  auraEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
  auraEventFrame:RegisterUnitEvent("UNIT_TARGET", "player", "pet", "focus");
  auraEventFrame:SetScript("OnEvent", function(_, event, unit)
    if (event == "UNIT_AURA") then
      RefreshFieldForUnit(unit);

    elseif (event == "PLAYER_TARGET_CHANGED") then
      RefreshFieldForUnit("target");

    elseif (event == "PLAYER_FOCUS_CHANGED") then
      RefreshFieldForUnit("focus");

    elseif (event == "UNIT_TARGET") then
      if (unit == "player") then
        RefreshFieldForUnit("target");
      elseif (unit == "focus") then
        RefreshFieldForUnit("focus");
      end

    elseif (event == "PLAYER_ENTERING_WORLD") then
      CheckUnitAuras();
    end
  end);

  return auraEventFrame;
end

do
  function GetAuraInfoByIndex(unitID, auraType, auraIndex)
    local filterName;

    if (auraType == DEBUFF) then
      filterName = HARMFUL;
    elseif (auraType == BUFF) then
      filterName = HELPFUL;
    end

    if (tk:IsRetail() and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
      local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unitID, auraIndex, filterName);

      if (ok and obj:IsTable(auraData)) then
        local auraSubType = GetSafeTableValue(auraData, "dispelName")
          or GetSafeTableValue(auraData, "debuffType");
        local applications = GetSafeTableValue(auraData, "applications")
          or GetSafeTableValue(auraData, "charges")
          or GetSafeTableValue(auraData, "stackCount");
        local icon = GetSafeTableValue(auraData, "icon")
          or GetSafeTableValue(auraData, "iconFileID");
        local spellId = GetSafeAuraIdValue(GetSafeTableValue(auraData, "spellId"));
        local auraName = SafeToString(GetSafeTableValue(auraData, "name"));
        local duration = GetSafeAuraTimeValue(GetSafeTableValue(auraData, "duration"), 0);
        local expirationTime = GetSafeAuraTimeValue(GetSafeTableValue(auraData, "expirationTime"), 0);

        if ((not auraName or auraName == "") and spellId > 0 and obj:IsFunction(GetSpellInfo)) then
          local spellName, _, spellIcon = GetSpellInfo(spellId);
          auraName = SafeToString(spellName) or auraName;
          icon = icon or spellIcon;
        end

        local normalizedAura = obj:PopTable(
          auraName,
          SafeToNumber(icon) or SafeToString(icon),
          GetSafeAuraCountValue(applications),
          SafeToString(auraSubType),
          duration,
          expirationTime,
          SafeToString(GetSafeTableValue(auraData, "sourceUnit")),
          false,
          nil,
          spellId
        );

        if (normalizedAura[1]
            and (normalizedAura[6] > 0
              or normalizedAura[5] > 0
              or db.profile.showUnknownExpiration)) then
          return normalizedAura;
        end

        obj:PushTable(normalizedAura);
      end
    end

    return NormalizeAuraInfo(obj:PopTable(UnitAura(unitID, auraIndex, filterName)));
  end

  local function GetAuraInfo(unitID, auraType, index, key)
    local auraInfo, maxAuras;

    if (auraType == DEBUFF) then
      maxAuras = DEBUFF_MAX_DISPLAY;
    elseif (auraType == BUFF) then
      maxAuras = BUFF_MAX_DISPLAY;
    end

    for i = 1, maxAuras do
      auraInfo = GetAuraInfoByIndex(unitID, auraType, i);

      if (obj:IsTable(auraInfo) and auraInfo[index] ~= nil and auraInfo[index] == key) then
        break;
      end

      SafePushTable(auraInfo);
      auraInfo = nil;
    end

    return auraInfo;
  end

  function GetAuraInfoByAuraID(unitID, auraId, auraType)
    return GetAuraInfo(unitID, auraType, 10, auraId);
  end

  function GetAuraInfoByAuraName(unitID, auraName, auraType)
    return GetAuraInfo(unitID, auraType, 1, auraName);
  end
end

local function CanTrackAura(auraInfo, sharedSettings)
  if (not obj:IsTable(auraInfo)) then
    -- some aura's do not return aura info from UnitAura (such as Windfury)
    return false;
  end

  local auraName = auraInfo[1];
  if (not auraName) then
    -- `nil` usually means the aura no longer exists (also, we don't want a timer bar with no name).
    obj:PushTable(auraInfo);
    return false;
  end

  local expirationTime = auraInfo[6];
  if (not (expirationTime and expirationTime > 0)) then
    -- some aura's do not have an expiration time so cannot be added to a timer bar (aura's that are fixed).
    if (not sharedSettings.showUnknownExpiration) then
      obj:PushTable(auraInfo);
      return false;
    end
  end

  return true;
end

local TimerBar_OnClick;

do
  local optionsMenu, insertedFrame;
  local params = obj:PopTable();

  local function OptionSelected_Inner(enableListFieldName, message, listName, printMessage, value)
    local enablePath = ("profile.fields.%s.filters.%s"):format(params.fieldName, enableListFieldName);
    local enabled = db:ParsePathValue(enablePath);
    local subMessage = L["Are you sure you want to do this?"];

    local function onConfirm(self)
      if (self.insertedFrame and self.insertedFrame.btn:GetChecked()) then
        db:SetPathValue(enablePath, true);
      end

      db:SetPathValue(("profile.fields.%s.filters.%s.%s"):format(params.fieldName, listName, params.auraName), value);
      tk:Print(printMessage:format(params.auraName));
      params.timerBar.Remove = true;
      TimerBars:RefreshSettings();
    end

    if (not enabled) then
      if (not insertedFrame) then
        insertedFrame = tk:CreateFrame("Frame", self);
        insertedFrame:SetSize(200, 30);

        insertedFrame.btn = tk:CreateFrame("CheckButton", insertedFrame, nil, "UICheckButtonTemplate");
        insertedFrame.btn:SetSize(30, 30);
        insertedFrame.btn:SetPoint("LEFT");

        local text = insertedFrame.btn.Text or insertedFrame.btn.text;
        text:SetFontObject("GameFontHighlight");
        text:ClearAllPoints();
        text:SetPoint("LEFT", insertedFrame.btn, "RIGHT", 5, 0);
      end

      local text = insertedFrame.btn.Text or insertedFrame.btn.text;
      text:SetText(L["Also enable the %s"]:format(listName:lower()));
      insertedFrame.btn:SetChecked(true);
    end

    tk:ShowConfirmPopupWithInsertedFrame(insertedFrame, message, subMessage, nil, onConfirm);
  end

  local function CreateOptionsMenu()
    local options = tk:CreateFrame("Frame", nil, "MUI_TimerBarOptionsMenu", "UIMenuTemplate");
    _G.UIMenu_Initialize(options);

    local function OptionSelected(whitelist)
      local auraNameWithHexColor = tk.Strings:SetTextColorByKey(params.auraName, "GOLD");
      options:Hide();

      if (whitelist) then
        local message = L["Removing %s from the whitelist will hide this timer bar if the whitelist is enabled."]:format(auraNameWithHexColor);
        local printMessage = L["%s has been removed from the whitelist."]:format(auraNameWithHexColor);
        OptionSelected_Inner("enableWhiteList", message, "whiteList", printMessage, nil);
      else
        local message = L["Adding %s to the blacklist will hide this timer bar if the blacklist is enabled."]:format(auraNameWithHexColor);
        local printMessage = L["%s has been added to the blacklist."]:format(auraNameWithHexColor);
        OptionSelected_Inner("enableBlackList", message, "blackList", printMessage, true);
      end
    end

    local optionText = "\124T%s.tga:16:16:0:0\124t %s";
    local blacklistText = string.format(optionText, "Interface\\COMMON\\Indicator-Green", L["Add to Blacklist"]);
    local whitelistText = string.format(optionText, "Interface\\COMMON\\Indicator-Red", L["Remove from Whitelist"]);

        --self, text, shortcut, func, nested, value
    _G.UIMenu_AddButton(options, blacklistText, nil, function() OptionSelected(false) end);
    _G.UIMenu_AddButton(options, whitelistText, nil, function() OptionSelected(true) end);
    _G.UIMenu_AddButton(options, "Cancel", nil, function() options:Hide() end);
    _G.UIMenu_AutoSize(options);
    options:Hide();

    return options;
  end

  function TimerBar_OnClick(self, button, timerBar)
    if (button ~= "RightButton") then return; end
    self:GetScript("OnLeave")(self);
    optionsMenu = optionsMenu or CreateOptionsMenu();
    optionsMenu:SetParent(self);
    optionsMenu:SetShown(not optionsMenu:IsShown());

    obj:EmptyTable(params);

    if (optionsMenu:IsShown()) then
      params.itemID = self.itemID;
      params.auraName = self.auraName
      params.fieldName = timerBar.FieldName;
      params.timerBar = timerBar;

      optionsMenu:ClearAllPoints();
      optionsMenu:SetPoint("BOTTOM", self, "TOP");
    end
  end
end

-- C_TimerField ------------------------------

obj:DefineParams("string", "table");
---@param name string @The unit of the field (to be used in the global variable name).
function C_TimerField:__Construct(data, name, sharedSettings)
  data.name = name;
  data.sharedSettings = sharedSettings;
  data.settings = sharedSettings.fields[name];
  data.timeSinceLastUpdate = 0;
  data.timeSinceLastAuraRefresh = 0;
  data.refreshToken = 0;
  data.activeBars = obj:PopTable();

  ---@type Stack
  data.expiredBarsStack = Stack:UsingTypes("TimerBar")(); -- this returns a class...

  data.expiredBarsStack:OnNewItem(function()
    return C_TimerBar(sharedSettings, data.settings);
  end);

  data.expiredBarsStack:OnPushItem(function(bar)
    bar.ExpirationTime = -1;
    bar.AuraName = nil;
    bar.FieldName = nil;
    bar:Hide();
    bar:SetParent(tk.Constants.DUMMY_FRAME);
  end);

  data.expiredBarsStack:OnPopItem(function(bar, auraId, source)
    data.barAdded = true; -- needed for controlling OnUpdate
    bar.AuraId = auraId;
    bar.Source = source;
    bar.FieldName = name; -- Needed for right click options menu (used in dbPath)
    table.insert(data.activeBars, bar);
  end);
end

obj:DefineReturns("string");
---@return string @The unit name to track that is registered with the TimerField.
function C_TimerField:GetUnitID(data)
  local unitID = data.settings.unitID;

  if (obj:IsString(unitID)) then
    unitID = unitID:lower();
  end

  return unitID;
end

obj:DefineParams("string");
---@param unitID string @Set which unit ID to track.
function C_TimerField:SetUnitID(data, unitID)
  if (not obj:IsString(unitID)) then
    return data.settings.unitID;
  end

  local oldUnitID = data.settings.unitID;
  unitID = unitID:lower();
  data.settings.unitID = unitID;

  if (obj:IsString(oldUnitID) and UnitIDFieldPairs[oldUnitID] == self) then
    UnitIDFieldPairs[oldUnitID] = nil;
  end

  UnitIDFieldPairs[unitID] = self;

  self:RecheckAuras();

  return unitID;
end

obj:DefineParams("boolean");
---@param enabled boolean @Set to true to enable TimerField tracking.
function C_TimerField:SetEnabled(data, enabled)
  if (data.enabled == enabled) then
    return;
  end

  data.enabled = enabled;

  if (not enabled and not data.frame) then
    return;
  end

  if (enabled and not data.frame) then
    data.frame = self:CreateField(data.name);
  end

  data.frame.disabled = not enabled;
  data.frame:Hide();

  if (not enabled) then
    -- disable:
    data.frame:SetAllPoints(tk.Constants.DUMMY_FRAME);
    data.frame:SetParent(tk.Constants.DUMMY_FRAME);
    data.frame:UnregisterAllEvents(); -- doesn't seem to work, so use disabled=true
  else
    -- enable:
    data.frame:SetParent(UIParent);
    self:PositionField();
    self:RecheckAuras();
    data.frame:Show();
  end
end

obj:DefineReturns("boolean");
---@return boolean @The enabled state of the TimerField.
function C_TimerField:IsEnabled(data)
  if (obj:IsNil(data.enabled)) then
    return false;
  end

  return data.enabled;
end

---Uses the position config settings to set the field's position on the UIParent.
function C_TimerField:PositionField(data)
  if (not obj:IsWidget(data.frame)) then
    return;
  end

  data.frame:ClearAllPoints();

  if (obj:IsTable(data.settings.position)) then
    local point, relativeFrame, relativePoint, xOffset, yOffset = unpack(data.settings.position);

    if (obj:IsString(relativeFrame) and _G[relativeFrame]) then
      data.frame:SetPoint(point, _G[relativeFrame], relativePoint, xOffset, yOffset);
    else
      data.frame:SetPoint("CENTER");
    end
  else
    data.frame:SetPoint("CENTER");
  end
end

do
  ---Rearranges the TimerField active TimerBars after first being sorted by time remaining + bars being removed or added.
  function RepositionBars(data)
    local p = tk.Constants.POINTS;
    local activeBar, previousBarFrame;

    for id = 1, data.settings.bar.maxBars do
      activeBar = data.activeBars[id];

      if (activeBar) then
        activeBar:ClearAllPoints();

        if (data.settings.direction == UP) then
          if (id > 1) then
            previousBarFrame = data.activeBars[id - 1]:GetFrame();
            activeBar:SetPoint(p["Bottom Left"], previousBarFrame, p["Top Left"], 0, data.settings.bar.spacing);
            activeBar:SetPoint(p["Bottom Right"], previousBarFrame, p["Top Right"], 0, data.settings.bar.spacing);
          else
            activeBar:SetPoint(p["Bottom Right"], data.frame, p["Bottom Right"], 0, 0);
          end
        elseif (id > 1) then
          previousBarFrame = data.activeBars[id - 1]:GetFrame();
          activeBar:SetPoint(p["Top Left"], previousBarFrame, p["Bottom Left"], 0, -data.settings.bar.spacing);
          activeBar:SetPoint(p["Top Right"], previousBarFrame, p["Bottom Right"], 0, -data.settings.bar.spacing);
        else
          activeBar:SetPoint(p["Top Left"], data.frame, p["Bottom Left"], 0, 0);
          activeBar:SetPoint(p["Top Right"], data.frame, p["Bottom Right"], 0, 0);
        end
      end
    end
  end

  local function SortByExpirationTime(a, b)
    return a.ExpirationTime > b.ExpirationTime;
  end

  obj:DefineParams("string");
  obj:DefineReturns("Frame");
  ---@param name string @The name of the field to create (used as a substring in global frame name)
  ---@return Frame @Returns the created field (a Frame widget)
  function C_TimerField:CreateField(data, name)
    local globalName = tk.Strings:Concat("MUI_", name, "TimerField");
    local frame = tk:CreateBackdropFrame("Frame", nil, globalName);
    tk:HideInPetBattles(frame);

    local fieldHeight = (data.settings.bar.maxBars * (data.settings.bar.height + data.settings.bar.spacing)) - data.settings.bar.spacing;
    frame:SetSize(data.settings.bar.width, fieldHeight);

    frame:SetScript("OnUpdate", function(_, elapsed)
      data.timeSinceLastUpdate = data.timeSinceLastUpdate + elapsed;
      data.timeSinceLastAuraRefresh = data.timeSinceLastAuraRefresh + elapsed;

      if (data.timeSinceLastAuraRefresh > TIMER_FIELD_AURA_REFRESH_FREQUENCY) then
        if (not frame.disabled) then
          if (UnitExists(data.settings.unitID)
              and not UnitIsDeadOrGhost(data.settings.unitID)) then
            self:RecheckAuras();
          else
            self:RemoveAllAuras();
          end
        end

        data.timeSinceLastAuraRefresh = 0;
      end

      if (data.timeSinceLastUpdate > TIMER_FIELD_UPDATE_FREQUENCY) then
        local currentTime = GetTime();
        local barRemoved;
        local changed = data.barAdded;

        repeat
          -- Remove expired bars:
          barRemoved = false;
          -- cannot use a new activeBars table (by inserting non-expired bars into it and replacing old table)
          -- because this would reverse the bar order which causes graphical issues if the time remaining of 2 bars is equal.
          for id, activeBar in ipairs(data.activeBars) do
            if (activeBar:UpdateExpirationTime()) then
              changed = true;
            end

            if (activeBar.Remove or (activeBar.ExpirationTime < currentTime)) then
              data.expiredBarsStack:Push(activeBar); -- remove bar here!
              table.remove(data.activeBars, id);
              barRemoved = true;
              changed = true;
              break
            end
          end

        until (not barRemoved);

        for _, bar in ipairs(data.activeBars) do
          bar:UpdateTimeRemaining(currentTime);
        end

        if (not changed) then
          return;
        end

        if (#data.activeBars > 0) then
          if (data.sharedSettings.sortByExpirationTime) then
            table.sort(data.activeBars, SortByExpirationTime);
          end

          RepositionBars(data);

          ---@param bar TimerBar
          for i, bar in ipairs(data.activeBars) do
            if (i <= data.settings.bar.maxBars) then
              -- make visible
              bar:SetParent(data.frame);
              bar:Show();
            else
              -- make invisible
              bar:Hide();
              bar:SetParent(tk.Constants.DUMMY_FRAME);
            end
          end
        end

        data.barAdded = nil;
        data.timeSinceLastUpdate = 0;
      end
    end);

    return frame;
  end
end

obj:DefineParams("number");
---@param auraId number @The aura's unique id used to find and remove the aura.
function C_TimerField:RemoveAuraByID(data, auraId)
  for _, activeBar in ipairs(data.activeBars) do
    if (auraId == activeBar.AuraId) then
      activeBar.Remove = true;
    end
  end
end
function C_TimerField:RemoveAllAuras(data)
  for _, activeBar in ipairs(data.activeBars) do
    activeBar.Remove = true;
  end
end

local function IsFilteredOut(filters, sourceGuid, auraName, auraType)
  local playerGuid = UnitGUID("player");
  local hasKnownSource = obj:IsString(sourceGuid) and sourceGuid ~= "" and sourceGuid ~= "Unknown";

  if (auraType == BUFF and not filters.showBuffs) then
    return true;
  end

  if (auraType == DEBUFF and not filters.showDebuffs) then
    return true;
  end

  if (auraType == BUFF and filters.onlyPlayerBuffs and hasKnownSource and playerGuid ~= sourceGuid) then
    return true;
  end

  if (auraType == DEBUFF and filters.onlyPlayerDebuffs and hasKnownSource and playerGuid ~= sourceGuid) then
    return true;
  end

  if (filters.enableWhiteList and not filters.whiteList[auraName]) then
    return true;
  end

  if (filters.enableBlackList and filters.blackList[auraName]) then
    return true;
  end

  return false;
end

obj:DefineParams("string", "number", "string", "string", "?table");
---@param sourceGuid string @The globally unique identify (GUID) representing the source of the aura (the creature or player who casted the aura).
---@param auraId number @The unique id of the aura used to find and update the aura.
---@param auraName number @The name of the aura used for filtering and updating the TimerBar name.
---@param auraType string @The type of aura (must be either "BUFF" or "DEBUFF").
function C_TimerField:UpdateBarsByAura(data, sourceGuid, auraId, auraName, auraType, auraInfo)
  if (IsFilteredOut(data.settings.filters, sourceGuid, auraName, auraType)) then
    SafePushTable(auraInfo);
    return;
  end

  ---@type TimerBar
  local foundBar;

  if (not obj:IsTable(auraInfo)) then
    if (auraId > 0) then
      auraInfo = GetAuraInfoByAuraID(data.settings.unitID, auraId, auraType);
    else
      auraInfo = GetAuraInfoByAuraName(data.settings.unitID, auraName, auraType);

      if (obj:IsTable(auraInfo)) then
        auraId = auraInfo[10];
      end
    end
  elseif (auraId <= 0) then
    auraId = auraInfo[10];
  end

  local canTrack = CanTrackAura(auraInfo, data.sharedSettings);

  if (not canTrack) then
    return;
  end

  -- first try to search for an existing one:
  for _, activeBar in ipairs(data.activeBars) do
    if (auraId > 0 and auraId == activeBar.AuraId and sourceGuid == activeBar.Source) then
      foundBar = activeBar;
      break
    end

    if (auraId > 0 and auraId == activeBar.AuraId and sourceGuid ~= activeBar.Source and activeBar.Source == "Unknown") then
      foundBar = activeBar;
      break
    end

    if (obj:IsString(auraName) and auraName ~= "" and auraName == activeBar.AuraName and auraType == activeBar.AuraType) then
      foundBar = activeBar;
      break
    end
  end

  if (not foundBar) then
    -- create a new timer bar
    foundBar = data.expiredBarsStack:Pop(auraId, sourceGuid);
  end

  -- update expiration time outside of UpdateAura!
  foundBar.AuraId = auraId;
  foundBar.AuraName = auraName;
  foundBar.AuraType = auraType;
  foundBar.Source = sourceGuid;
  foundBar.Remove = nil;
  foundBar:UpdateAura(auraInfo);
  return foundBar;
end

---Rechecks whether auras are still in use by the unit
function C_TimerField:RecheckAuras(data)
  local maxAuras, auraType;
  local refreshToken = (data.refreshToken or 0) + 1;
  local trackedCount = 0;

  data.refreshToken = refreshToken;

  for a = 1, 2 do
    if (a == 1) then
      maxAuras, auraType = BUFF_MAX_DISPLAY, BUFF;
    elseif (a == 2) then
      maxAuras, auraType = DEBUFF_MAX_DISPLAY, DEBUFF;
    end

    for i = 1, maxAuras do
      local auraInfo = GetAuraInfoByIndex(data.settings.unitID, auraType, i);

      if (CanTrackAura(auraInfo, data.sharedSettings)) then
        local auraName = auraInfo[1];
        local auraId = auraInfo[10];
        local sourceUnit = auraInfo[7]; -- classic returns nil
        local sourceGuid = sourceUnit and UnitGUID(sourceUnit) or "Unknown";
        local bar;

        if (auraName) then
          bar = self:UpdateBarsByAura(sourceGuid, auraId, auraName, auraType, auraInfo);

          if (bar) then
            bar.RefreshToken = refreshToken;
            trackedCount = trackedCount + 1;
          end
        end
      end
    end
  end

  if (trackedCount > 0 or not UnitAffectingCombat(data.settings.unitID)) then
    for _, activeBar in ipairs(data.activeBars) do
      if (activeBar.RefreshToken ~= refreshToken) then
        activeBar.Remove = true;
      end
    end
  end
end

obj:DefineReturns("?TimerBar");
---@return table @A table containing all active, and non-active, timer bars.
function C_TimerField:GetAllTimerBars(data)
  local allBars = obj:PopTable();

  if (not tk.Tables:IsEmpty(data.activeBars)) then
    tk.Tables:AddAll(allBars, unpack(data.activeBars));
  end

  local stack = data.expiredBarsStack; ---@type Stack

  if (not stack:IsEmpty()) then
    tk.Tables:AddAll(allBars, stack:Unpack());
  end

  if (tk.Tables:IsEmpty(allBars)) then
    obj:PushTable(allBars);
    return
  end

  return obj:UnpackTable(allBars);
end

-- C_TimerBar ---------------------------

obj:DefineParams("table", "table");
---@param settings table @The config settings table.
function C_TimerBar:__Construct(data, sharedSettings, settings)

  -- fields
  self.AuraId = -1;
  self.Source = "Unset";
  self.ExpirationTime = -1;

  data.settings = settings;
  data.sharedSettings = sharedSettings;

  data.frame = tk:CreateBackdropFrame("Button");
  data.frame:SetSize(settings.bar.width, settings.bar.height);
  data.frame:RegisterForClicks("RightButtonUp");
  data.frame:Hide();

  data.slider = tk:CreateFrame("StatusBar", data.frame);
  data.slider:SetStatusBarTexture(tk.Constants.LSM:Fetch("statusbar", sharedSettings.statusBarTexture));
  data.slider.bg = tk:SetBackground(data.slider, unpack(sharedSettings.colors.background));
  data.frame.slider = data.slider;

  self:SetIconShown(settings.showIcons);
  self:SetSparkShown(settings.showSpark);
  self:SetBorderShown(sharedSettings.border.show);
  self:SetAuraNameShown(settings.auraName.show);
  self:SetSpellCountShown(settings.spellCount.show);
  self:SetTimeRemainingShown(settings.timeRemaining.show);
  self:SetTooltipsEnabled(sharedSettings.showTooltips);

  data.frame:SetScript("OnClick", function(frame, button)
    TimerBar_OnClick(frame, button, self, data);
  end);
end

obj:DefineParams("boolean");
---@param shown boolean @Set to true to show the timer bar icon.
function C_TimerBar:SetIconShown(data, shown)
  if (not data.iconFrame and not shown) then
    return;
  end

  if (shown) then
    if (not data.iconFrame) then
      data.iconFrame = tk:CreateBackdropFrame("Frame", data.frame);
      data.icon = data.iconFrame:CreateTexture(nil, "ARTWORK");
      data.icon:SetTexCoord(0.1, 0.92, 0.08, 0.92);
    end

    local barWidthWithIcon = data.settings.bar.width - data.settings.bar.height - ICON_GAP;
    data.frame:SetWidth(barWidthWithIcon);
    data.iconFrame:SetWidth(data.settings.bar.height);
  else
    data.frame:SetWidth(data.settings.bar.width);
  end

  data.iconFrame:SetShown(shown);
end

do
  local function SetWidgetBorderSize(widget, borderSize)
    widget:ClearAllPoints();
    widget:SetPoint("TOPLEFT", borderSize, -borderSize);
    widget:SetPoint("TOPRIGHT", -borderSize, -borderSize);
    widget:SetPoint("BOTTOMLEFT", borderSize, borderSize);
    widget:SetPoint("BOTTOMRIGHT", -borderSize, borderSize);
  end

  obj:DefineParams("boolean");
  ---@param shown boolean @Set to true to show borders.
  function C_TimerBar:SetBorderShown(data, shown)
    if (not data.backdrop and not shown) then
      return;
    end

    local borderSize = 0; -- must be 0 in case it needs to be disabled

    if (shown) then
      if (not data.backdrop) then
        data.backdrop = obj:PopTable();
      end

      local borderType = data.sharedSettings.border.type;
      local borderColor = data.sharedSettings.colors.border;

      borderSize = data.sharedSettings.border.size;

      data.backdrop.edgeFile = tk.Constants.LSM:Fetch("border", borderType);
      data.backdrop.edgeSize = borderSize;

      data.frame:SetBackdrop(data.backdrop);
      data.frame:SetBackdropBorderColor(unpack(borderColor));

      if (obj:IsWidget(data.iconFrame)) then
        data.iconFrame:SetBackdrop(data.backdrop);
        data.iconFrame:SetBackdropBorderColor(unpack(borderColor));
      end
    else
      data.frame:SetBackdrop(nil);

      if (obj:IsWidget(data.iconFrame)) then
        data.iconFrame:SetBackdrop(nil);
      end
    end

    SetWidgetBorderSize(data.slider, borderSize);

    if (obj:IsWidget(data.iconFrame) and obj:IsWidget(data.icon) and data.settings.showIcons) then
      data.iconFrame:SetPoint("TOPRIGHT", data.frame, "TOPLEFT", -(borderSize * 2) - ICON_GAP, 0);
      data.iconFrame:SetPoint("BOTTOMRIGHT", data.frame, "BOTTOMLEFT", -(borderSize * 2) - ICON_GAP, 0);
      SetWidgetBorderSize(data.icon, borderSize);

      local barWidthWithIconAndBorder = data.frame:GetWidth() - (borderSize * 2);
      data.frame:SetWidth(barWidthWithIconAndBorder);
    end
  end
end

obj:DefineParams("boolean");
---@param shown boolean @Set to true to show the timer bar spark effect.
function C_TimerBar:SetSparkShown(data, shown)
  if (not data.spark and not shown) then
    return
  end

  if (not data.spark) then
    data.spark = data.slider:CreateTexture(nil, "OVERLAY");
    data.spark:SetSize(26, 50);
    data.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");

    local r, g, b = tk:GetThemeColor();
    data.spark:SetVertexColor(r, g, b);
    data.spark:SetBlendMode("ADD");
  end

  data.spark:SetShown(shown);
  data.showSpark = shown;
end

obj:DefineParams("boolean");
---@param shown boolean @Set to true to show the timer bar aura name.
function C_TimerBar:SetAuraNameShown(data, shown)
  if (not data.auraName and not shown) then
    return;
  end

  if (not data.auraName) then
    data.auraName = data.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    data.auraName:SetPoint("LEFT", 4, 0);
    data.auraName:SetPoint("RIGHT", -50, 0);
    data.auraName:SetJustifyH("LEFT");
    data.auraName:SetWordWrap(false);
  end

  local font = tk.Constants.LSM:Fetch("font", data.settings.auraName.font);
  data.auraName:SetFont(font, data.settings.auraName.fontSize);
  data.auraName:SetShown(shown);
end

obj:DefineParams("boolean");
---@param shown boolean @Set to true to show the timer bar's time remaining text.
function C_TimerBar:SetTimeRemainingShown(data, shown)
  if (not data.timeRemaining and not shown) then
    return;
  end

  if (not data.timeRemaining) then
    data.timeRemaining = data.slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
    data.timeRemaining:SetPoint("RIGHT", -4, 0);
  end

  local font = tk.Constants.LSM:Fetch("font", data.settings.timeRemaining.font);
  data.timeRemaining:SetFont(font, data.settings.timeRemaining.fontSize);
  data.timeRemaining:SetShown(shown);
end

obj:DefineParams("boolean");
---@param shown boolean @Set to true to show the timer bar's time remaining text.
function C_TimerBar:SetSpellCountShown(data, shown)
  if (not data.spellCount and not shown) then
    return;
  end

  if (not data.spellCount) then
    data.spellCount = data.slider:CreateFontString(nil, "ARTWORK", "GameFontNormal");
  end

  local font = tk.Constants.LSM:Fetch("font", data.settings.spellCount.font);
  data.spellCount:SetFont(font, data.settings.spellCount.fontSize);

  local relPoint = data.settings.spellCount.position;
  local xOffset = data.settings.spellCount.xOffset;
  data.spellCount:ClearAllPoints();

  if (relPoint == "CENTER") then
    data.spellCount:SetPoint("CENTER", data.slider, "CENTER", xOffset, 0);
    data.spellCount:SetJustifyH("CENTER");
  else
    local position;

    if (relPoint == "LEFT") then
      position = "RIGHT";
    elseif (relPoint == "RIGHT") then
      position = "LEFT";
    end

    data.spellCount:SetPoint("TOP"..position, data.slider, "TOP"..relPoint, xOffset, 0);
    data.spellCount:SetPoint("BOTTOM"..position, data.slider, "BOTTOM"..relPoint, xOffset, 0);
    data.spellCount:SetJustifyH(position);
  end

  data.spellCount:SetWidth(max(16, data.spellCount:GetStringWidth() + 6));
  data.spellCount:SetShown(shown);
end

obj:DefineParams("boolean");
---@param enabled boolean @Set to true to show the aura tooltip on mouse over.
function C_TimerBar:SetTooltipsEnabled(data, enabled)
  if (enabled) then
    data.frame:SetScript("OnEnter", tk.HandleTooltipOnEnter);
    data.frame:SetScript("OnLeave", tk.HandleTooltipOnLeave);
  else
    data.frame:SetScript("OnEnter", tk.Constants.DUMMY_FUNC);
    data.frame:SetScript("OnLeave", tk.Constants.DUMMY_FUNC);
  end
end

obj:DefineParams("number", "?number");
---@param currentTime number @The current time using GetTime.
function C_TimerBar:UpdateTimeRemaining(data, currentTime)
  if (self.ExpirationTime == UNKNOWN_EXPIRATION) then
    data.slider:SetMinMaxValues(0, 1);
    data.slider:SetValue(1);
    if (data.timeRemaining) then
      data.timeRemaining:SetText("");
    end

    if (data.auraName and data.sharedSettings.showUnknownExpiration) then
      data.auraName:SetPoint("RIGHT", -50, 0);
    elseif (data.auraName) then
      data.auraName:SetPoint("RIGHT", 0, 0);
    end

    self:SetSparkShown(false);
    return
  end

  if (data.auraName) then
    data.auraName:SetPoint("RIGHT", -50, 0);
  end

  local timeRemaining = self.ExpirationTime - currentTime;

  -- duration should have been checked in the frame OnUpdate script
  -- Update: During a big 40 vs 40 PVP battleground, this condition failed!
  -- obj:Assert(timeRemaining >= 0);

  if (timeRemaining < 0) then
    return -- Let OnUpdate Script remove it!
  end

  if (self.TotalDuration) then
    -- Called from UpdateAura
    data.slider:SetMinMaxValues(0, self.TotalDuration);
  end

  tk:AnimateSliderChange(data.slider, timeRemaining);

  if (not data.showSpark and data.settings.showSpark) then
    self:SetSparkShown(true);
  end

  if (data.showSpark) then
    local _, maxValue = data.slider:GetMinMaxValues();
    local offset = data.spark:GetWidth() / 2;
    local barWidth = data.slider:GetWidth();
    local value = (timeRemaining / maxValue) * barWidth - offset;

    if (value > barWidth - offset) then
      value = barWidth - offset;
    end

    data.spark:SetPoint("LEFT", value, 0);
  end

  if (data.timeRemaining) then
    tk:SetTimeRemaining(data.timeRemaining, timeRemaining, data.settings.timeRemaining.fontSize, 10, 14);
  end
end

obj:DefineParams("table");
---@param auraInfo table @A table containing a subset of the results from UnitAura.
function C_TimerBar:UpdateAura(data, auraInfo)
  local auraName        = auraInfo[1];
  local iconPath        = auraInfo[2];
  local count          = auraInfo[3];
  local debuffType      = auraInfo[4];
  local canStealOrPurge = auraInfo[8];
  local totalDuration   = auraInfo[5];
  local expirationTime  = auraInfo[6];

  obj:PushTable(auraInfo);

  self.TotalDuration = totalDuration;
  self.ExpirationTime = expirationTime;

  if (self.TotalDuration == 0 and self.ExpirationTime == 0) then
    self.ExpirationTime = UNKNOWN_EXPIRATION;
  end

  -- this is needed for the tooltip mouse over + right click menu
  data.frame.itemID = self.AuraId;
  data.frame.auraName = auraName;
  data.frame.iconType = "spell";
  data.frame.tooltipAnchor = "ANCHOR_TOP";

  if (data.icon) then
    data.icon:SetTexture(iconPath);
  end

  if (data.auraName) then
    data.auraName:SetText(auraName);
  end

  if (data.spellCount and count > 1) then
    data.spellCount:SetText(count);
    data.spellCount:SetWidth(max(16, data.spellCount:GetStringWidth() + 6));
    data.spellCount:Show();
  elseif (data.spellCount) then
    data.spellCount:Hide();
  end

  if (data.settings.colorStealOrPurge and canStealOrPurge) then
    data.slider:SetStatusBarColor(unpack(data.sharedSettings.colors.canStealOrPurge));
  else
    if (self.AuraType == BUFF) then
      data.slider:SetStatusBarColor(unpack(data.sharedSettings.colors.basicBuff));

    elseif (self.AuraType == DEBUFF) then
      if (data.settings.colorDebuffsByType and obj:IsString(debuffType)) then
        local debuffColor = data.sharedSettings.colors[string.lower(debuffType)];

        if (obj:IsTable(debuffColor)) then
          data.slider:SetStatusBarColor(unpack(debuffColor));
        else
          data.slider:SetStatusBarColor(unpack(data.sharedSettings.colors.basicDebuff));
        end
      else
        data.slider:SetStatusBarColor(unpack(data.sharedSettings.colors.basicDebuff));
      end
    end
  end

  if (self.Source == UnitGUID("player")) then
    data.frame:SetAlpha(1);
  else
    data.frame:SetAlpha(data.settings.nonPlayerAlpha);
  end
end

obj:DefineReturns("boolean");
function C_TimerBar:UpdateExpirationTime(data)
  local old = self.ExpirationTime;
  local auraInfo;
  local currentTime = GetTime();

  if (self.AuraId and self.AuraId > 0) then
    auraInfo = GetAuraInfoByAuraID(data.settings.unitID, self.AuraId, self.AuraType);
  end

  if (not obj:IsTable(auraInfo) and self.AuraName) then
    auraInfo = GetAuraInfoByAuraName(data.settings.unitID, self.AuraName, self.AuraType);
  end

  if (obj:IsTable(auraInfo)) then
    self.TotalDuration = auraInfo[5];
    self.ExpirationTime = auraInfo[6];

    if (self.TotalDuration == 0 and self.ExpirationTime == 0) then
      self.ExpirationTime = UNKNOWN_EXPIRATION;
    end
  else
    if (UnitAffectingCombat(data.settings.unitID)
        and old
        and (old == UNKNOWN_EXPIRATION or old > currentTime)) then
      return false;
    end

    self.ExpirationTime = -1;
  end

  obj:PushTable(auraInfo);

  return (old ~= self.ExpirationTime);
end

function C_TimerBars:ApplyProfileSettings(data)
  if (not (db.profile.fieldNames and db.profile.fields)) then
    db:RemoveAppended(db.profile, "defaultFields");
  end

  if (db:GetCurrentProfile() == "Healer") then
    if (not db:IsAppended("removedTargetInHealing")) then
      local sv = db.profile:GetSavedVariable();
      db:AppendOnce("profile", "removedTargetInHealing", { removed = true });

      if (obj:IsTable(sv.fieldNames)) then
        sv.fields.Target = nil;

        if (tk.Tables:Contains(sv.fieldNames, "Target")) then
          local index = tk.Tables:IndexOf(sv.fieldNames, "Target");
          table.remove(sv.fieldNames, index);
        end
      end
    end

    -- Healer Layout/Profile
    db:AppendOnce("profile", "defaultFields", {
      fieldNames = {
        "Player";
      };
      fields = {
        Player = {
          position = { "BOTTOMLEFT", "MUI_PlayerName", "TOPLEFT", 12, 2 },
          unitID = "player";
        };
      };
    }, true);
  else
    -- DPS Layout/Default Profile
    db:AppendOnce("profile", "defaultFields", {
      fieldNames = {
        "Player";
        "Target";
      };
      fields = {
        Player = {
          position = { "BOTTOMLEFT", "MUI_PlayerName", "TOPLEFT", 12, 2 },
          unitID = "player";
        };
        Target = {
          position = { "BOTTOMRIGHT", "MUI_TargetName", "TOPRIGHT", -10, 2 },
          unitID = "target";
        };
      };
    }, true);
  end

  if (obj:IsObject(db.profile.fieldNames)) then
    for _, fieldName in db.profile.fieldNames:Iterate() do
      local sv = db.profile.fields[fieldName];
      sv:SetParent(nil); -- remove before comparison
    end
  end

  tk.Tables:Empty(data.options.onExecuteAll.first);

  if (obj:IsObject(db.profile.fieldNames)) then
    for _, fieldName in db.profile.fieldNames:Iterate() do
      local sv = db.profile.fields[fieldName];
      sv:SetParent(db.profile.__templateField);

      if (not obj:IsObject(data.loadedFields[fieldName])) then
        data.loadedFields[fieldName] = sv.enabled;
      end

      if (sv.enabled) then
        table.insert(data.options.onExecuteAll.first, tk.Strings:Concat("fields.", fieldName, ".", "enabled"));
      end
    end

    -- disable fields that are removed in the current profile but are active (previous profile uses them):
    for fieldName, field in pairs(data.loadedFields) do
      if (not db.profile.fields[fieldName] and obj:IsObject(field)) then
        field:SetEnabled(false);
      end
    end
  end
end
