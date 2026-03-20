-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

local pairs, ipairs = _G.pairs, _G.ipairs;
local IsAddOnLoaded, UnitExists, UnitIsPlayer = _G.IsAddOnLoaded, _G.UnitExists, _G.UnitIsPlayer;
local C_UnitPanels = MayronUI:RegisterModule("UnitPanels", L["Unit Panels"], true);

local function DetachShadowedUnitFrame()
  if (not (_G.ShadowedUFDB and obj:IsTable(_G.ShadowedUFDB.profiles))) then
    return;
  end

  for _, profileTable in pairs(_G.ShadowedUFDB.profiles) do
    if (obj:IsTable(profileTable) and obj:IsTable(profileTable.positions)) then
      local config = profileTable.positions.targettarget;

      if (obj:IsTable(config) and config.anchorTo == "MUI_UnitPanelCenter") then
        config.point = "TOP";
        config.anchorTo = "UIParent";
        config.relativePoint = "TOP";
        config.x = 100;
        config.y = -100;
      end
    end
  end
end

if (_G.ShadowUF and obj:IsTable(_G.ShadowUF.Units)) then
  _G.ShadowUF.Units.OnInitialize = DetachShadowedUnitFrame;
end

-- Load Database Defaults ----------------

db:AddToDefaults("profile.unitPanels", {
  enabled = true;
  controlSUF = true;
  unitWidth = 325;
  unitHeight = 75;
  isSymmetric = false;
  targetClassColored = true;
  restingPulse = true;
  pulseStrength = 0.3;
  alpha = 0.8;
  unitNames = {
    enabled = true;
    width = 235;
    height = 20;
    fontSize = 11;
    targetClassColored = true;
    xOffset = 24;
  };
  sufGradients = {
    enabled = true;
    height = 24;
    targetClassColored = true;
    opacity = 0.5;
  };
});

-- UnitPanels Module -----------------

function C_UnitPanels:OnInitialize(data, containerModule)
  data.containerModule = containerModule;
  data.currentPulseAlpha = 0;

  if (not (db.profile.unitPanels.sufGradients.from
    and db.profile.unitPanels.sufGradients.to)) then
    db:RemoveAppended(db.profile, "unitPanels.sufGradients");
  end

  local r, g, b = tk:GetThemeColor();
  db:AppendOnce("profile.unitPanels.sufGradients", nil, {
    opacity = 0.5;
    from = { r = r; g = g; b = b; a = 0.5 };
    to = { r = 0; g = 0; b = 0; a = 0 };
  });

  if (not obj:IsNumber(db.profile.unitPanels.sufGradients.opacity)) then
    db.profile.unitPanels.sufGradients.opacity = db.profile.unitPanels.sufGradients.from.a or 0.5;
  end

  db.profile.unitPanels.sufGradients.from.a = db.profile.unitPanels.sufGradients.opacity;
  db.profile.unitPanels.sufGradients.to.a = 0;

  local options = {
    onExecuteAll = {
      dependencies = {
        ["unitNames[.].*"] = "unitNames.enabled";
        ["restingPulse"] = "unitNames.enabled";
      };
      ignore = { "unitHeight"; "alpha" };
    };
  };

  local attachWrapper = function()
    data:Call("AttachShadowedUnitFrames");
  end
  data.attachShadowUFWrapper = attachWrapper;

  self:RegisterUpdateFunctions(
    db.profile.unitPanels, {
      controlSUF = function(value)
        if (not IsAddOnLoaded("ShadowedUnitFrames")) then
          return
        end

        local listener = em:GetEventListenerByID("MuiDetachSuf_Logout");

        if (not value) then
          if (listener) then
            DetachShadowedUnitFrame();
            listener:UnregisterEvent("PLAYER_LOGOUT");
            if (_G.ShadowUF and data.sufProfilesChangedHooked) then
              tk:UnhookFunc(_G.ShadowUF, "ProfilesChanged", data.attachShadowUFWrapper or attachWrapper);
              data.sufProfilesChangedHooked = nil;
            end
            if (data.sufReloadHooked) then
              tk:UnhookFunc("ReloadUI", DetachShadowedUnitFrame);
              data.sufReloadHooked = nil;
            end
          end
        else
          data:Call("AttachShadowedUnitFrames");
          if (_G.ShadowUF and not data.sufProfilesChangedHooked) then
            tk:HookFunc(_G.ShadowUF, "ProfilesChanged", data.attachShadowUFWrapper or attachWrapper);
            data.sufProfilesChangedHooked = true;
          end
          if (not data.sufReloadHooked) then
            tk:HookFunc("ReloadUI", DetachShadowedUnitFrame);
            data.sufReloadHooked = true;
          end

          if (not listener) then
            listener = em:CreateEventListenerWithID(
              "MuiDetachSuf_Logout", DetachShadowedUnitFrame);
          end

          listener:RegisterEvent("PLAYER_LOGOUT");
        end
      end;

      unitWidth = function(value)
        if (obj:IsWidget(data.left) and obj:IsWidget(data.right)) then
          data.left:SetSize(value, 180);
          data.right:SetSize(value, 180);
        end
      end;

      unitHeight = function()
        if (data.containerModule and obj:IsFunction(data.containerModule.RepositionContent)) then
          data.containerModule:RepositionContent();
        end
      end;

      isSymmetric = function(value)
        self:SetSymmetricalEnabled(value);
      end;

      targetClassColored = function(value)
        local listener = em:GetEventListenerByID("targetClassColored");

        if (listener) then
          listener:SetEnabled(value);
          em:TriggerEventListener(listener);
        end
      end;

      restingPulse = function(value)
        self:SetRestingPulseEnabled(value);
      end;

      alpha = function()
        data:Call("UpdateAllVisuals");
      end;

      unitNames = {
        enabled = function(value)
          self:SetUnitNamesEnabled(value);
        end;

        width = function(value)
          if (obj:IsWidget(data.player) and obj:IsWidget(data.target)
              and obj:IsWidget(data.player.text) and obj:IsWidget(data.target.text)) then
            data.player:SetSize(value, data.settings.unitNames.height);
            data.target:SetSize(value, data.settings.unitNames.height);
            data.player.text:SetWidth(value - 25);
            data.target.text:SetWidth(value - 25);
          end
        end;

        height = function(value)
          if (obj:IsWidget(data.player) and obj:IsWidget(data.target)) then
            data.player:SetSize(data.settings.unitNames.width, value);
            data.target:SetSize(data.settings.unitNames.width, value);
          end
        end;

        fontSize = function(value)
          if (obj:IsWidget(data.player) and obj:IsWidget(data.target)
              and obj:IsWidget(data.player.text) and obj:IsWidget(data.target.text)) then
            tk:SetMasterFont(data.player.text, value);
            tk:SetMasterFont(data.target.text, value);
          end
        end;

        targetClassColored = function()
          if (data.player and data.target) then
            em:TriggerEventListenerByID("MuiUnitNames_TargetChanged");
          end
        end;

        xOffset = function(value)
          if (obj:IsWidget(data.player) and obj:IsWidget(data.target)
              and obj:IsWidget(data.left) and obj:IsWidget(data.right)) then
            data.player:ClearAllPoints();
            data.target:ClearAllPoints();
            data.player:SetPoint("BOTTOMLEFT", data.left, "TOPLEFT", value, 0);
            data.target:SetPoint(
              "BOTTOMRIGHT", data.right, "TOPRIGHT", -(value), 0);
          end
        end;
      };

      sufGradients = {
        enabled = function(value)
          self:SetPortraitGradientsEnabled(value);
        end;

        height = function(value)
          if (data.settings.sufGradients.enabled and data.gradients) then
            for _, frame in pairs(data.gradients) do
              frame:SetSize(100, value);
            end
          end
        end;

        targetClassColored = function()
          if (data.settings.sufGradients.enabled) then
            self:RefreshPortraitGradients();
          end
        end;

        opacity = function(value)
          if (data.settings.sufGradients.from) then
            data.settings.sufGradients.from.a = value;
          end

          if (data.settings.sufGradients.to) then
            data.settings.sufGradients.to.a = 0;
          end

          if (data.settings.sufGradients.enabled) then
            self:RefreshPortraitGradients();
          end
        end;

        from = function()
          if (data.settings.sufGradients.enabled) then
            self:RefreshPortraitGradients();
          end
        end;

        to = function()
          if (data.settings.sufGradients.enabled) then
            self:RefreshPortraitGradients();
          end
        end;
      };
    }, options);

  if (data.settings.enabled) then
    self:SetEnabled(true);
  end
end

function C_UnitPanels:OnDisable(data)
  if (obj:IsWidget(data.left)) then
    data.left:Hide();
  end

  if (obj:IsWidget(data.right)) then
    data.right:Hide();
  end

  if (obj:IsWidget(data.center)) then
    data.center:Hide();
  end

  if (obj:IsWidget(data.player)) then
    data.player:Hide();
  end

  if (obj:IsWidget(data.target)) then
    data.target:Hide();
  end

  -- disable all events:
  em:DisableEventListeners(
    "MuiRestingPulse", "MuiUnitFramePanels_TargetChanged",
      "MuiDetachSuf_Logout", "MuiUnitNames_TargetChanged",
      "MuiUnitNames_LevelUp", "MuiUnitNames_UpdatePlayerName",
      "MuiUnitPanels_TargetGradient");

  if (_G.ShadowUF and data.sufProfilesChangedHooked and data.attachShadowUFWrapper) then
    tk:UnhookFunc(_G.ShadowUF, "ProfilesChanged", data.attachShadowUFWrapper);
    data.sufProfilesChangedHooked = nil;
  end

  if (data.sufReloadHooked) then
    tk:UnhookFunc("ReloadUI", DetachShadowedUnitFrame);
    data.sufReloadHooked = nil;
  end

  data.stopPulsing = true;
end

-- Occurs before update functions execute
-- Can be toggled on and off though without update functions executing
function C_UnitPanels:OnEnable(data)
  if (not obj:IsTable(data.settings)) then
    return;
  end

  if (not obj:IsWidget(_G.MUI_BottomContainer)) then
    return;
  end

  if (data.left) then
    data.left:Show();
    data.right:Show();
    data.center:Show();

    if (data.settings.unitNames.enabled and not (data.player and data.target)) then
      self:SetUpUnitNames(data);
    elseif (data.player and data.target) then
      data.player:Show();
      data.target:Show();
    end

    -- enable event handlers
    if (data.settings.restingPulse) then
      em:EnableEventListeners("MuiRestingPulse");
    end

    if (data.settings.controlSUF) then
      em:EnableEventListeners("MuiDetachSuf_Logout");
    end

    if (data.settings.unitNames.enabled) then
      em:EnableEventListeners(
        "MuiUnitNames_TargetChanged", "MuiUnitNames_LevelUp",
          "MuiUnitNames_UpdatePlayerName");
    end

    if (data.settings.sufGradients.enabled) then
      em:EnableEventListeners("MuiUnitPanels_TargetGradient");
    end

    em:EnableEventListeners("MuiUnitFramePanels_TargetChanged");
    data.stopPulsing = nil;
    if (data.settings.controlSUF) then
      data:Call("AttachShadowedUnitFrames");
    end
    return;
  end

  -- data.left.bg is created when loading Symmetrical.lua
  data.left = tk:CreateFrame("Frame", _G.MUI_BottomContainer, "MUI_UnitPanelLeft");
  data.right = tk:CreateFrame("Frame", _G.MUI_BottomContainer, "MUI_UnitPanelRight");
  data.center = tk:CreateFrame("Frame", data.right, "MUI_UnitPanelCenter");

  data.center:SetPoint("TOPLEFT", data.left, "TOPRIGHT");
  data.center:SetPoint("TOPRIGHT", data.right, "TOPLEFT");
  data.center:SetPoint("BOTTOMLEFT", data.left, "BOTTOMRIGHT");
  data.center:SetPoint("BOTTOMRIGHT", data.right, "BOTTOMLEFT");

  data.center.bg = tk:SetBackground(data.center, tk:GetAssetFilePath("Textures\\BottomUI\\Center"));
  data.center.hasGradient = true; -- should be colored using SetGradient when target changes.

  data.left:SetFrameStrata("BACKGROUND");
  data.center:SetFrameStrata("BACKGROUND");
  data.right:SetFrameStrata("BACKGROUND");

  -- Ensure panel textures are initialized even if the update pipeline does not
  -- execute the `isSymmetric` update immediately during startup.
  data.stopPulsing = nil;
  self:SetSymmetricalEnabled(data.settings.isSymmetric);
  data:Call("UpdateAllVisuals");
end

function C_UnitPanels:OnEnabled(data)
  if (em:GetEventListenerByID("MuiUnitFramePanels_TargetChanged")) then
    return
  end

  local listener = em:CreateEventListenerWithID("MuiUnitFramePanels_TargetChanged", function()
    data:Call("UpdateAllVisuals");
  end);

  listener:RegisterEvents(
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_TARGET_CHANGED",
      "PLAYER_ENTERING_WORLD");

  data:Call("UpdateAllVisuals");
end

do
  local doubleTextureFilePath = tk:GetAssetFilePath("Textures\\BottomUI\\Double");
  local singleTextureFilePath = tk:GetAssetFilePath("Textures\\BottomUI\\Single");

  function C_UnitPanels:SetSymmetricalEnabled(data, enabled)
    if (not (obj:IsWidget(data.left) and obj:IsWidget(data.right))) then
      return;
    end

    if (not data.left.bg) then
      -- Finish setting up the unit frames here
      data.left.bg = tk:SetBackground(data.left, doubleTextureFilePath);
      data.right.bg = tk:SetBackground(data.right, doubleTextureFilePath);
      data.right.bg:SetTexCoord(1, 0, 0, 1);
      tk:ApplyThemeColor(data.settings.alpha, data.left.bg, data.right.bg);
    end

    if (not enabled) then
      -- create single texture (shown when there is no target and not symmetrical)
      data.left.singleBg = data.left.singleBg
        or tk:SetBackground(data.left, singleTextureFilePath);
      tk:ApplyThemeColor(data.settings.alpha, data.left.singleBg);
    end

    data:Call("UpdateAllVisuals");
  end
end

-- This is used by the Resting Pulse feature and by the "alpha" update function:
function C_UnitPanels.Private:UpdateVisuals(data, frame, restingPulseAlpha)
  if (not (obj:IsTable(data.settings) and obj:IsWidget(data.left) and obj:IsWidget(data.left.bg))) then
    return;
  end

  local targetR, targetG, targetB = tk:GetClassColor("target");
  local r, g, b = data.left.bg:GetVertexColor();
  local alpha = data.settings.alpha;

  if (data:Call("ShouldPulse")) then
    alpha = restingPulseAlpha or data.currentPulseAlpha;
  elseif (restingPulseAlpha) then
    return
  end

  if (frame ~= data.left and frame ~= data.player) then
    if (not (data.settings.isSymmetric or UnitExists("target"))) then
      alpha = 0;
    end
  end

  if (frame == data.center) then
    if (UnitIsPlayer("target") and data.settings.targetClassColored) then
      tk:SetGradient(frame.bg, "HORIZONTAL", r, g, b, alpha, targetR, targetG, targetB, alpha);
    else
      tk:SetGradient(frame.bg, "HORIZONTAL", r, g, b, alpha, r, g, b, alpha);
    end
  elseif (frame == data.right) then
    if (UnitIsPlayer("target") and data.settings.targetClassColored) then
      frame.bg:SetVertexColor(targetR, targetG, targetB, alpha);
    else
      frame.bg:SetVertexColor(r, g, b, alpha);
    end
  elseif (frame == data.target) then
    if (UnitIsPlayer("target") and data.settings.unitNames.targetClassColored) then
      frame.bg:SetVertexColor(targetR, targetG, targetB, alpha);
    else
      frame.bg:SetVertexColor(r, g, b, alpha);
    end
  elseif (frame == data.player) then
    frame.bg:SetVertexColor(r, g, b, alpha);
  else
    if (UnitExists("target") or data.settings.isSymmetric) then
      if (frame.singleBg) then
        frame.singleBg:SetVertexColor(r, g, b, 0);
      end
      frame.bg:SetVertexColor(r, g, b, alpha);
    else
      if (frame.singleBg) then
        frame.singleBg:SetVertexColor(r, g, b, alpha);
      end

      frame.bg:SetVertexColor(r, g, b, 0);
    end
  end
end

do
  local textures = { "left"; "center"; "right"; "player"; "target" };

function C_UnitPanels.Private:UpdateAllVisuals(data)
    if (not obj:IsTable(data.settings)) then
      return;
    end

    for _, key in ipairs(textures) do
      if (key == "player" and not data.settings.unitNames.enabled) then
        break
      end
      if (obj:IsWidget(data[key]) and obj:IsWidget(data[key].bg)) then
        data:Call("UpdateVisuals", data[key]);
      end
    end
  end
end

do
  local IsResting = _G.IsResting;
  local InCombatLockdown = _G.InCombatLockdown;

  function C_UnitPanels.Private:ShouldPulse(data)
    return not (data.stopPulsing or InCombatLockdown()) and IsResting()
             and data.settings.restingPulse;
  end
end

function C_UnitPanels.Private:AttachShadowedUnitFrames(data)
  if (not obj:IsWidget(data.center)) then
    return
  end

  if (not (_G.ShadowUF
      and _G.ShadowUF.db
      and obj:IsTable(_G.ShadowUF.db.profile)
      and obj:IsTable(_G.ShadowUF.db.profile.positions)
      and obj:IsTable(_G.ShadowUF.db.profile.positions.targettarget))) then
    return;
  end

  if (not obj:IsWidget(_G.MUI_UnitPanelCenter)) then
    return;
  end

  local SUFTargetTarget = _G.ShadowUF.db.profile.positions.targettarget;

  SUFTargetTarget.point = "TOP";
  SUFTargetTarget.anchorTo = "MUI_UnitPanelCenter";
  SUFTargetTarget.relativePoint = "TOP";
  SUFTargetTarget.x = 0;
  SUFTargetTarget.y = -40;

  if (_G.SUFUnitplayer) then
    _G.SUFUnitplayer:SetFrameStrata("MEDIUM");
  end

  if (_G.SUFUnittarget) then
    _G.SUFUnittarget:SetFrameStrata("MEDIUM");
    if (obj:IsWidget(data.right)) then
      data.right:SetFrameStrata("LOW");
    end
  end

  if (_G.SUFUnittargettarget) then
    _G.SUFUnittargettarget:SetFrameStrata("MEDIUM");
  end

  if (_G.ShadowUF.Layout and obj:IsFunction(_G.ShadowUF.Layout.Reload)) then
    pcall(_G.ShadowUF.Layout.Reload, _G.ShadowUF.Layout, "targettarget");
  end
end
