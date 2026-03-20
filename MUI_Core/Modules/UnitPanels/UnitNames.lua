-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, em, _, obj = MayronUI:GetCoreComponents(); -- luacheck: ignore
local _, C_UnitPanels = _G.MayronUI:ImportModule("UnitPanels");

local UnitGUID, UnitAffectingCombat, UnitName = _G.UnitGUID, _G.UnitAffectingCombat, _G.UnitName;
local UnitExists, IsResting, GetRestState = _G.UnitExists, _G.IsResting, _G.GetRestState;

local function UpdateUnitNameText(data, unitID, unitLevel)
  if (not (obj:IsTable(data) and obj:IsWidget(data[unitID])
      and obj:IsTable(data[unitID].text) and obj:IsFunction(data[unitID].text.SetText))) then
    return;
  end

  local overflow = tk:IsLocale("enUS", "deDE", "esES", "esMX", "frFR", "itIT", "prBR") and 22;
  local unitNameText = tk.Strings:GetUnitFullNameText(unitID, unitLevel, overflow);

  if (not unitNameText or unitNameText == tk.Strings.Empty) then
    local fallbackName = UnitName(unitID);

    if (obj:IsString(fallbackName) and fallbackName ~= tk.Strings.Empty) then
      unitNameText = fallbackName;
    else
      unitNameText = tk.Strings.Empty;
    end
  end

  if (unitID:lower() == "player") then
    if (UnitAffectingCombat("player")) then
      tk:SetBasicTooltip(data[unitID], _G.COMBAT, "ANCHOR_CURSOR");

    elseif (IsResting()) then
      local _, exhaustionStateName = GetRestState();
      tk:SetBasicTooltip(data[unitID], exhaustionStateName, "ANCHOR_CURSOR");

    else
      tk:SetBasicTooltip(data[unitID], nil, "ANCHOR_CURSOR");
    end
  end

  data[unitID].text:SetText(unitNameText);
end

function C_UnitPanels:SetUnitNamesEnabled(data, enabled)
  if (enabled) then
    if (not (data.player and data.target)) then
      self:SetUpUnitNames(data);
    else
      em:EnableEventListeners(
        "MuiUnitNames_LevelUp",
        "MuiUnitNames_UpdatePlayerName",
        "MuiUnitNames_TargetChanged");
    end

    data.player:Show();
    data.target:Show();

  elseif (data.player and data.target) then
    data.player:Hide();
    data.target:Hide();

    em:DisableEventListeners(
      "MuiUnitNames_LevelUp",
      "MuiUnitNames_UpdatePlayerName",
      "MuiUnitNames_TargetChanged");
  end
end

function C_UnitPanels:SetUpUnitNames(data)
  local nameTextureFilePath = tk:GetAssetFilePath("Textures\\BottomUI\\NamePanel");
  local settings = data.settings.unitNames;
  local frameLevel = ((data.left and data.left:GetFrameLevel()) or 1) + 10;
  local frameStrata = "MEDIUM";
  local fontSize = math.max(tonumber(settings.fontSize) or 11, 8);

  data.player = tk:CreateFrame("Frame", data.left, "MUI_PlayerName");
  data.player:SetFrameStrata(frameStrata);
  data.player:SetFrameLevel(frameLevel);
  data.player.bg = tk:SetBackground(data.player, nameTextureFilePath);
  data.player.text = data.player:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  data.player.text:SetDrawLayer("OVERLAY", 7);
  data.player.text:SetJustifyH("LEFT");
  data.player.text:SetJustifyV("MIDDLE");
  data.player.text:SetWordWrap(false);
  data.player.text:SetPoint("LEFT", data.player, "LEFT", 15, 0);
  data.player.text:SetPoint("RIGHT", data.player, "RIGHT", -10, 0);
  data.player.text:SetTextColor(1, 1, 1, 1);
  data.player.text:SetShadowColor(0, 0, 0, 1);
  data.player.text:SetShadowOffset(1, -1);

  data.target = tk:CreateFrame("Frame", data.right, "MUI_TargetName");
  data.target:SetFrameStrata(frameStrata);
  data.target:SetFrameLevel(frameLevel);
  data.target.bg = tk:SetBackground(data.target, nameTextureFilePath);
  data.target.text = data.target:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  data.target.text:SetDrawLayer("OVERLAY", 7);
  data.target.text:SetJustifyH("RIGHT");
  data.target.text:SetJustifyV("MIDDLE");
  data.target.text:SetWordWrap(false);
  data.target.text:SetPoint("LEFT", data.target, "LEFT", 10, 0);
  data.target.text:SetPoint("RIGHT", data.target, "RIGHT", -15, 0);
  data.target.text:SetTextColor(1, 1, 1, 1);
  data.target.text:SetShadowColor(0, 0, 0, 1);
  data.target.text:SetShadowOffset(1, -1);

  data.player:SetSize(settings.width, settings.height);
  data.target:SetSize(settings.width, settings.height);
  tk:SetMasterFont(data.player.text, fontSize, "OUTLINE");
  tk:SetMasterFont(data.target.text, fontSize, "OUTLINE");
  data.player:ClearAllPoints();
  data.target:ClearAllPoints();
  data.player:SetPoint("BOTTOMLEFT", data.left, "TOPLEFT", settings.xOffset, 0);
  data.target:SetPoint("BOTTOMRIGHT", data.right, "TOPRIGHT", -(settings.xOffset), 0);
  data.player.text:Show();
  data.target.text:Show();

  tk:ApplyThemeColor(data.settings.alpha, data.player.bg, data.target.bg);

  tk:FlipTexture(data.target.bg, "HORIZONTAL");
  UpdateUnitNameText(data, "player");

  if (UnitExists("target")) then
    UpdateUnitNameText(data, "target");
  else
    data.target.text:SetText(tk.Strings.Empty);
  end

  data:Call("UpdateVisuals", data.player, data.settings.alpha);
  data:Call("UpdateVisuals", data.target, data.settings.alpha);

  -- Setup event handlers:
  if (not tk:IsPlayerMaxLevel()) then
    local listener = em:CreateEventListenerWithID("MuiUnitNames_LevelUp", function(listener, _, newLevel)
      UpdateUnitNameText(data, "player", newLevel);

      if (UnitGUID("player") == UnitGUID("target")) then
        UpdateUnitNameText(data, "target", newLevel);
      end

      if (tk:IsPlayerMaxLevel()) then
        listener:Destroy();
      end
    end);

    listener:RegisterEvent("PLAYER_LEVEL_UP");
  end

  local listener = em:CreateEventListenerWithID("MuiUnitNames_UpdatePlayerName", function()
    UpdateUnitNameText(data, "player");
  end);

  listener:RegisterEvents(
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
    "PLAYER_ENTERING_WORLD", "PLAYER_UPDATE_RESTING", "PLAYER_FLAGS_CHANGED");

  listener = em:CreateEventListenerWithID("MuiUnitNames_TargetChanged", function()
    if (UnitExists("target")) then
      UpdateUnitNameText(data, "target");
    elseif (obj:IsWidget(data.target) and obj:IsWidget(data.target.text)) then
      data.target.text:SetText(tk.Strings.Empty);
    end

    if (obj:IsWidget(data.target)) then
      data:Call("UpdateVisuals", data.target, data.settings.alpha);
    end
  end);

  listener:RegisterEvents("PLAYER_TARGET_CHANGED", "PLAYER_ENTERING_WORLD");
end
