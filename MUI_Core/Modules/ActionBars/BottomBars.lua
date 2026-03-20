-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

local InCombatLockdown = _G.InCombatLockdown;
local UIFrameFadeIn, strformat = _G.UIFrameFadeIn, _G.string.format;
local IsAddOnLoaded, LoadAddOn, ipairs = _G.IsAddOnLoaded, _G.LoadAddOn, _G.ipairs;
local GetAddOnMetadata = _G.GetAddOnMetadata;
local hooksecurefunc = _G.hooksecurefunc;
local FeatureState = obj:Import("MayronUI.FeatureState");

local TOGGLE_BUTTON_WIDTH = 120;
local TOGGLE_BUTTON_HEIGHT = 28;
local EXPAND_BUTTON_ID = 1;
local RETRACT_BUTTON_ID = 2;

-- Register and Import Modules -----------
---@class BottomActionBarsModule
local C_BottomActionBars = MayronUI:RegisterModule("BottomActionBars", L["Action Bar Panels"], true);
local BlizzardSuppressor = obj:Import("MayronUI.ActionBars.BlizzardSuppressor");
local BartenderCompatibility = obj:Import("MayronUI.ActionBars.BartenderCompatibility");

-- Load Database Defaults ----------------
db:AddToDefaults("profile.actionbars.bottom", {
  enabled = true; -- show/hide action bar panel
  -- Appearance properties
  texture = tk:GetAssetFilePath("Textures\\BottomUI\\ActionBarPanel");
  alpha = 1;
  manualSizes = {80, 120, 160}; -- the manual heights for each of the 3 rows
  sizeMode = "dynamic";
  panelPadding = 6;

  animation = {
    speed = 6;
    activeSets = 1;
    modKey = "A"; -- modifier key to toggle expand and retract button
  };

  bartender = {
    spacing = tk:IsRetail() and 2 or 3;

    controlVisibility = true;
    controlPositioning = true;
    controlScale = true;
    controlPadding = true;

    scale = 0.85 * (tk:IsRetail() and 0.8 or 1);
    padding = tk:IsRetail() and 6.8 or 5.5;

    -- These are the bartender IDs, not the Bar Name!
    -- Use Bartender4:GetModule("ActionBars"):GetBarName(id) to find out its name.
    -- Set 1:
    [1] = tk:IsRetail() and { 1, 13 } or { 1, 7 };
    -- Set 2:
    [2] = tk:IsRetail() and { 6, 14 } or { 9, 10 };
    -- Set 3
    [3] = tk:IsRetail() and { 5, 15 } or { 5, 6 };
  };
});

-- local functions ------------------

local modKeyLabels = {
  ["C"] = "CTRL",
  ["S"] = "SHIFT",
  ["A"] = "ALT",
};

local function NormalizeModKeySetting(modKey)
  if (not obj:IsString(modKey)) then
    return "A";
  end

  modKey = modKey:upper();
  local sanitized = tk.Strings.Empty;

  for i = 1, #modKey do
    local c = modKey:sub(i, i);

    if (modKeyLabels[c] and not sanitized:find(c, nil, true)) then
      sanitized = sanitized .. c;
    end
  end

  if (sanitized == tk.Strings.Empty) then
    return "A";
  end

  return sanitized;
end

local function LoadTutorial(panel)
  local frame = tk:CreateFrame("Frame", panel);

  frame:SetFrameStrata("TOOLTIP");
  frame:SetSize(300, 130);
  frame:SetPoint("BOTTOM", panel, "TOP", 0, 120);

  gui:AddDialogTexture(frame, "High");
  gui:AddCloseButton(frame);
  gui:AddTitleBar(frame, L["Tutorial: Step 1"]);
  gui:AddArrow(frame, "DOWN");

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  frame.text:SetWordWrap(true);
  frame.text:SetPoint("TOPLEFT", 10, -30);
  frame.text:SetPoint("BOTTOMRIGHT", -10, 10);
  tk:SetFontSize(frame.text, 13);

  local modKey = NormalizeModKeySetting(db.profile.actionbars.bottom.animation.modKey);
  db.profile.actionbars.bottom.animation.modKey = modKey;

  local modKeyLabel;
  for i = 1, #modKey do
    local c = modKey:sub(i,i);

    if (i == 1) then
      modKeyLabel = modKeyLabels[c];
    else
      modKeyLabel = strformat("%s+%s", modKeyLabel, modKeyLabels[c]);
    end
  end

  local tutorialMessage = L["PRESS_HOLD_TOGGLE_BUTTONS"];
  tutorialMessage = tutorialMessage:format(tk.Strings:SetTextColorByKey(modKeyLabel, "GOLD"));
  frame.text:SetText(tutorialMessage);

  local listener = em:CreateEventListener(function(self)
    if (not tk:IsModComboActive(modKey)) then return end
    frame.titleBar.text:SetText(L["Tutorial: Step 2"]);

    local step2Text = L["CHANGE_KEYBINDINGS"];
    step2Text = strformat(step2Text, tk.Strings:SetTextColorByKey("/mui config", "GOLD"));
    frame.text:SetText(step2Text);
    frame:SetHeight(200);
    frame.text:SetPoint("BOTTOMRIGHT", -10, 50);

    local btn = gui:CreateButton(frame, L["Show MUI Key Bindings"]);
    btn:SetPoint("BOTTOM", 0, 20);
    btn:SetScript("OnClick", function()
      MayronUI:ShowKeyBindings();
      frame.closeBtn:Click();
    end);

    btn:SetWidth(200);

    if (not frame:IsShown()) then
      UIFrameFadeIn(frame, 0.5, 0, 1);
      frame:Show();
    end

    db.profile.actionbars.bottom.tutorial = GetAddOnMetadata("MUI_Core", "Version");
    self:Destroy();
  end);

  listener:RegisterEvent("MODIFIER_STATE_CHANGED");
end

local function OnArrowButtonClick(btnId, currentActiveSets)
  if (btnId == EXPAND_BUTTON_ID) then
    if (currentActiveSets == 1) then
      MayronUI:TriggerCommand("Show2BottomActionBars");
    elseif (currentActiveSets == 2) then
      MayronUI:TriggerCommand("Show3BottomActionBars");
    end

  elseif (btnId == RETRACT_BUTTON_ID) then
    if (currentActiveSets == 2) then
      MayronUI:TriggerCommand("Show1BottomActionBar");
    elseif (currentActiveSets == 3) then
      MayronUI:TriggerCommand("Show2BottomActionBars");
    end
  end
end

local function OnArrowButtonEnter(self)
  local r, g, b = self.icon:GetVertexColor();
  self.icon:SetVertexColor(r * 1.2, g * 1.2, b * 1.2);
end

local function OnArrowButtonLeave(self)
  tk:ApplyThemeColor(self.icon);
end

local function PositionToggleButtons(data)
  data.expand:Hide();
  data.retract:Hide();
  data.expand:ClearAllPoints();
  data.retract:ClearAllPoints();

  if (data.settings.animation.activeSets == 1) then
    data.expand:SetPoint("BOTTOM", data.buttons, "TOP");
    data.expand:SetSize(TOGGLE_BUTTON_WIDTH, TOGGLE_BUTTON_HEIGHT);
    data.expand:Show();

  elseif (data.settings.animation.activeSets == 2) then
    local smallWidth = TOGGLE_BUTTON_WIDTH / 2;
    local gap = 1;
    local offset = (smallWidth / 2) + gap;

    data.retract:SetPoint("BOTTOM", data.buttons, "TOP", -offset, 0);
    data.retract:SetSize(smallWidth, TOGGLE_BUTTON_HEIGHT);
    data.retract:Show();
    data.expand:SetPoint("BOTTOM", data.buttons, "TOP", offset, 0);
    data.expand:SetSize(smallWidth, TOGGLE_BUTTON_HEIGHT);
    data.expand:Show();

  elseif (data.settings.animation.activeSets == 3) then
    data.retract:SetPoint("BOTTOM", data.buttons, "TOP");
    data.retract:SetSize(TOGGLE_BUTTON_WIDTH, TOGGLE_BUTTON_HEIGHT);
    data.retract:Show();
  end
end

local function SuppressBlizzardActionBarRemainder()
  if (not FeatureState:IsEnabled("actionbars.blizzardSuppressor")) then
    return;
  end

  BlizzardSuppressor:SuppressActionBarRemainder();
end

local function GetRelevantBartenderProfiles()
  if (not FeatureState:IsEnabled("actionbars.bartenderCompatibility")) then
    return {};
  end

  return BartenderCompatibility:GetRelevantProfiles();
end

local function ApplyBartenderProfileCompliance(profileName)
  if (not FeatureState:IsEnabled("actionbars.bartenderCompatibility")) then
    return;
  end

  BartenderCompatibility:ApplyProfileCompliance(profileName);
end

local function ApplyBartenderRuntimeCompliance()
  if (not FeatureState:IsEnabled("actionbars.bartenderCompatibility")) then
    return;
  end

  BartenderCompatibility:ApplyRuntimeCompliance();
end

-- MayronUI functions ------------------

function MayronUI:ShowKeyBindings()
  pcall(LoadAddOn, "Blizzard_BindingUI");
  local keybindingsFrame = _G.KeyBindingFrame;

  if (IsAddOnLoaded("Blizzard_BindingUI") and obj:IsWidget(keybindingsFrame)) then
    keybindingsFrame:Show();

    local categoryList = keybindingsFrame.categoryList;

    if (obj:IsTable(categoryList) and obj:IsTable(categoryList.buttons)) then
      for _, btn in ipairs(categoryList.buttons) do
        if (obj:IsTable(btn) and obj:IsTable(btn.element)
            and btn.element.name == "MayronUI" and obj:IsFunction(btn.Click)) then
          btn:Click();
        end
      end
    end
  elseif (IsAddOnLoaded("Blizzard_Settings") and obj:IsTable(_G.Settings)
      and obj:IsFunction(_G.Settings.OpenToCategory)) then
    _G.Settings.OpenToCategory(); -- can't use 12 (the Keybindings category) due to taint
  end
end

-- C_BottomActionBars -----------------
function C_BottomActionBars:OnInitialize(data, containerModule)
  data.containerModule = containerModule;
  data.rows = obj:PopTable();

  local options = {
    onExecuteAll = {
      ignore = {
        ".*";
      };
    };
  };

  self:RegisterUpdateFunctions(db.profile.actionbars.bottom, {
    texture = function(value)
      if (data.panel and obj:IsFunction(data.panel.SetGridTexture)) then
        data.panel:SetGridTexture(value);
      end
    end;

    alpha = function(value)
      if (data.panel) then
        data.panel:SetAlpha(value);
      end
    end;

    manualSizes = function()
      if (data.controller and data.settings.sizeMode == "manual") then
        data.controller.panelSizes = tk.Tables:Copy(data.settings.manualSizes);
        local activeSets = data.settings.animation.activeSets;
        data.controller.slider:SetValue(data.settings.manualSizes[activeSets]);
      end
    end;

    sizeMode = function(value)
      if (not data.controller) then
        return;
      end

      data.controller.sizeMode = value;

      if (value == "dynamic") then
        local bottom = data.panel:GetBottom();
        data.controller:LoadPositions(bottom);
        local activeSets = data.settings.animation.activeSets;
        data.controller.slider:SetValue(data.controller.panelSizes[activeSets]);
      else
        data.controller.panelSizes = tk.Tables:Copy(data.settings.manualSizes);
        local activeSets = data.settings.animation.activeSets;
        data.controller.slider:SetValue(data.settings.manualSizes[activeSets]);
      end
    end;

    panelPadding = function(value)
      if (data.controller and data.settings.sizeMode == "dynamic") then
        data.controller.panelPadding = value;
        local bottom = data.panel:GetBottom();
        data.controller:LoadPositions(bottom);
        local activeSets = data.settings.animation.activeSets;
        data.controller.slider:SetValue(data.controller.panelSizes[activeSets]);
      end
    end;

    ---@param keys LinkedList
    bartender = function(_, path)
      local key = path:GetBack();
      if (key ~= "activeSets") then
        self:SetUpExpandRetract();
      end
    end;

    animation = {
      speed = function(value)
        if (data.controller) then
          data.controller:SetAnimationSpeed(value);
        end
      end
    };
  }, options);

  if (data.settings.enabled) then
    self:SetEnabled(true);
  end
end

function C_BottomActionBars:OnDisable(data)
  if (data.panel) then
    data.panel:Hide();
    if (data.containerModule and obj:IsFunction(data.containerModule.RepositionContent)) then
      data.containerModule:RepositionContent();
    end
    return;
  end
end

function C_BottomActionBars:OnEnable(data)
  if (_G.Bartender4DB and tk:IsRetail()) then
    for profileName in _G.pairs(GetRelevantBartenderProfiles()) do
      ApplyBartenderProfileCompliance(profileName);
    end

    db.global.bartender4Update = 6;
  end

  if (tk:IsRetail()) then
    ApplyBartenderRuntimeCompliance();
  end

  if (tk:IsRetail() and _G.Bartender4 and obj:IsFunction(_G.Bartender4.UpdateModuleConfigs)
      and obj:IsFunction(hooksecurefunc) and not data.bartenderComplianceHooked) then
    hooksecurefunc(_G.Bartender4, "UpdateModuleConfigs", function()
      if (_G.Bartender4DB) then
        for profileName in _G.pairs(GetRelevantBartenderProfiles()) do
          ApplyBartenderProfileCompliance(profileName);
        end

        db.global.bartender4Update = 6;
      end

      ApplyBartenderRuntimeCompliance();
      SuppressBlizzardActionBarRemainder();
    end);

    data.bartenderComplianceHooked = true;
  end

  if (data.panel) then
    SuppressBlizzardActionBarRemainder();
    data.panel:Show();
    if (data.containerModule and obj:IsFunction(data.containerModule.RepositionContent)) then
      data.containerModule:RepositionContent();
    end
    return;
  end

  data.panel = tk:CreateFrame("Frame", _G.MUI_BottomContainer, "MUI_BottomActionBarsPanel");
  data.panel:SetFrameLevel(10);
  data.panel:SetHeight(1);
  data.panel:SetAlpha(data.settings.alpha);
  gui:CreateGridTexture(data.panel, data.settings.texture, 20, nil, 749, 45);
  SuppressBlizzardActionBarRemainder();

  if (not data.settings.tutorial) then
    local show = tk:GetTutorialShowState(data.settings.tutorial);

    if (show) then
      LoadTutorial(data.panel);
    end
  end
end

function C_BottomActionBars:SetUpExpandRetract(data)
  if (not (IsAddOnLoaded("Bartender4") and obj:IsWidget(data.panel))) then
    return
  end

  local bottom = data.panel:GetBottom();
  if (not obj:IsNumber(bottom)) then
    return
  end

  if (data.controller) then
    em:EnableEventListeners("BottomSets_ExpandRetract");
    data.controller:ApplyOverrides();
    data.controller:LoadPositions(bottom);
    return
  end

  -- Create up and down buttons used to expand/retract rows:
  data.buttons = tk:CreateFrame("Frame", data.panel);
  data.buttons:SetFrameStrata("HIGH");
  data.buttons:SetFrameLevel(20);
  data.buttons:SetPoint("BOTTOM", data.panel, "TOP", 0, -2);
  data.buttons:SetSize(1, 1);
  data.buttons:Hide();

  for btnId = 1, 2 do
    local btn = gui:CreateButton(data.buttons);
    btn:Hide();
    btn:SetID(btnId);
    btn:SetScript("OnEnter", OnArrowButtonEnter);
    btn:SetScript("OnLeave", OnArrowButtonLeave);
    btn:SetScript("OnClick", function()
      OnArrowButtonClick(btnId, data.settings.animation.activeSets);
      data.buttons:Hide();
    end);

    btn:SetFrameStrata("HIGH");
    btn:SetFrameLevel(30);
    btn:SetBackdrop(tk.Constants.BACKDROP);
    btn:SetBackdropBorderColor(0, 0, 0);

    local iconRotation;
    if (btnId == RETRACT_BUTTON_ID) then
      iconRotation = 180;
    end

    btn.icon = gui:CreateIconTexture("arrow", btn, true, iconRotation);
    btn.icon:ClearAllPoints();
    btn.icon:SetDrawLayer("OVERLAY");
    btn.icon:SetSize(16, 10);
    btn.icon:SetPoint("CENTER");
    btn.icon:SetAlpha(1);

    local normalTexture = btn:GetNormalTexture();
    normalTexture:SetVertexColor(0.15, 0.15, 0.15, 1);

    local btnKey = btnId == EXPAND_BUTTON_ID and "expand" or "retract";
    data[btnKey] = btn;
  end

  -- Create glow effect that fades in when holding the modifier key/s:
  local glow = data.buttons:CreateTexture("MUI_BottomActionBarsPanelGlow", "BACKGROUND");
  glow:SetTexture(tk:GetAssetFilePath("Textures\\BottomUI\\GlowEffect"));
  glow:SetSize(db.profile.bottomui.width, 80);
  glow:SetBlendMode("ADD");
  glow:SetPoint("BOTTOM", 0, 2);
  tk:ApplyThemeColor(glow);

  -- Create the glow effect's scaling effect:
  local glowScaler = glow:CreateAnimationGroup();
  glowScaler.anim = glowScaler:CreateAnimation("Scale");
  glowScaler.anim:SetOrigin("BOTTOM", 0, 0);
  glowScaler.anim:SetDuration(0.4);

  if (obj:IsFunction(glowScaler.anim.SetFromScale)) then
    glowScaler.anim:SetFromScale(0, 0);
    glowScaler.anim:SetToScale(1, 1);
  else
    -- changed function name in dragonflight
    glowScaler.anim:SetScaleFrom(0, 0);
    glowScaler.anim:SetScaleTo(1, 1);
  end

  -- Create the glow effect's fade in effect:
  local fader = data.buttons:CreateAnimationGroup();
  fader.anim = fader:CreateAnimation("Alpha");
  fader.anim:SetSmoothing("OUT");
  fader.anim:SetDuration(0.2);
  fader.anim:SetFromAlpha(0);
  fader.anim:SetToAlpha(1);

  fader:SetScript("OnFinished", function()
    data.buttons:SetAlpha(1);
  end);

  fader:SetScript("OnPlay", function()
    data.buttons:Show();
    PositionToggleButtons(data);
    data.buttons:SetAlpha(0);
  end);

  -- Needed for private script handler callbacks:
  data.glowScaler = glowScaler;
  data.glow = glow;
  data.fader = fader;

  local mixin = MayronUI:GetComponent("ActionBarController");

  ---@type ActionBarControllerMixin
  data.controller = _G.CreateAndInitFromMixin(mixin,
    data.panel, data.settings, bottom, "VERTICAL", nil, tk:IsRetail() and 0 or 2, 0);

  local function PlayTransition(nextActiveSetId)
    data.controller:PlayTransition(nextActiveSetId);
    db.profile.actionbars.bottom.animation.activeSets = nextActiveSetId;
  end

  -- Setup action bar toggling commands:
  _G.BINDING_NAME_MUI_SHOW_1_BOTTOM_ACTION_BAR = "Show 1 Bottom Action Bar";
  MayronUI:RegisterCommand("Show1BottomActionBar", PlayTransition, 1);

  _G.BINDING_NAME_MUI_SHOW_2_BOTTOM_ACTION_BARS = "Show 2 Bottom Action Bars";
  MayronUI:RegisterCommand("Show2BottomActionBars", PlayTransition, 2);

  _G.BINDING_NAME_MUI_SHOW_3_BOTTOM_ACTION_BARS = "Show 3 Bottom Action Bars";
  MayronUI:RegisterCommand("Show3BottomActionBars", PlayTransition, 3);

  em:CreateEventListenerWithID("BottomSets_ExpandRetract", function()
    local modKey = NormalizeModKeySetting(data.settings.animation.modKey);
    data.settings.animation.modKey = modKey;

    if (not tk:IsModComboActive(modKey) or InCombatLockdown()) then
      data.buttons:Hide();
      return
    end

    data.fader:Stop(); -- force execution of OnFinished callback
    data.glowScaler:Play();
    data.fader:Play();
  end):RegisterEvent("MODIFIER_STATE_CHANGED");

  em:CreateEventListener(function()
    data.expand:Hide();
    data.retract:Hide();
  end):RegisterEvent("PLAYER_REGEN_DISABLED");
end

function C_BottomActionBars:GetPanel(data)
  return data.panel;
end
