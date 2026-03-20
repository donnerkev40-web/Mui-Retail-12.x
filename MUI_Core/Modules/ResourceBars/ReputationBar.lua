-- luacheck: ignore self 143 631
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore
local GetWatchedFactionInfo = _G.GetWatchedFactionInfo;
local C_Reputation = _G.C_Reputation;
local C_ReputationBar = obj:Import("MayronUI.ReputationBar");

local strformat, select = _G.string.format, _G.select;

-- Local Functions -----------------------

local function GetWatchedFactionInfoCompat()
  if (GetWatchedFactionInfo) then
    return GetWatchedFactionInfo();
  end

  if (not C_Reputation or not C_Reputation.GetWatchedFactionData) then
    return;
  end

  local factionData = C_Reputation.GetWatchedFactionData();
  if (type(factionData) ~= "table") then
    return;
  end

  local standingID = factionData.reaction or factionData.currentReaction or factionData.standingID;
  local minValue = factionData.currentReactionThreshold or factionData.reactionThreshold or factionData.barMin or 0;
  local maxValue = factionData.nextReactionThreshold or factionData.nextThreshold or factionData.barMax or 0;
  local currentValue = factionData.currentStanding or factionData.reactionProgress or factionData.barValue or 0;

  return factionData.name, standingID, minValue, maxValue, currentValue;
end

local function OnReputationBarUpdate(_, _, bar, data)
  if (not bar:CanUse()) then
    bar:SetActive(false);
    return;
  end

  if (not bar:IsActive()) then
    bar:SetActive(true);
  end

  local factionName, standingID, minValue, maxValue, currentValue = GetWatchedFactionInfoCompat();
  if (not factionName or not standingID or not maxValue or not currentValue) then
    bar:SetActive(false);
    return;
  end

  maxValue = maxValue - minValue;
  currentValue = currentValue - minValue;

  if (maxValue <= 0) then
    maxValue = 1;
  end

  if (currentValue < 0) then
    currentValue = 0;
  elseif (currentValue > maxValue) then
    currentValue = maxValue;
  end

  data.statusbar:SetMinMaxValues(0, maxValue);
  data.statusbar:SetValue(currentValue);

  local color = data.settings.standingColors[standingID] or data.settings.defaultColor;

  if (data.settings.useDefaultColor) then
    color = data.settings.defaultColor;
  end

  data.statusbar.texture:SetVertexColor(color.r or 0, color.g or 0, color.b or 0, color.a or 1);

  if (data.statusbar.text) then
      local percent = 100 - tk.Numbers:ToPrecision((currentValue / maxValue) * 100, 2);
      currentValue = tk.Strings:FormatReadableNumber(currentValue);
      maxValue = tk.Strings:FormatReadableNumber(maxValue);

      local text = strformat("%s: %s / %s (%s%% %s)", factionName, currentValue, maxValue, percent, L["remaining"]);
      data.statusbar.text:SetText(text);
  end
end

-- C_ReputationBar -----------------------

obj:DefineParams("ResourceBars", "table");
function C_ReputationBar:__Construct(_, barsModule, moduleData)
  self:CreateResourceBar(barsModule, moduleData, "reputation");
end

obj:DefineReturns("boolean");
function C_ReputationBar:CanUse()
  -- standingID 8 == exalted
  local factionName, standingID = GetWatchedFactionInfoCompat();
  local canUse = (factionName ~= nil and standingID < 8);
  return canUse;
end

obj:DefineParams("boolean");
function C_ReputationBar:SetActive(data, active)
  self:CallParentMethod("SetActive", active);

  if (active and data.notCreated) then
    local standingID = select(2, GetWatchedFactionInfoCompat());
    local color = data.settings.standingColors[standingID] or data.settings.defaultColor;

    if (data.settings.useDefaultColor) then
      color = data.settings.defaultColor;
    end

    data.statusbar.texture = data.statusbar:GetStatusBarTexture();
    data.statusbar.texture:SetVertexColor(color.r or 0, color.g or 0, color.b or 0, color.a or 1);
    data.notCreated = nil;
  end
end

obj:DefineParams("boolean");
function C_ReputationBar:SetEnabled(data, enabled)
  if (enabled) then
    if (not em:GetEventListenerByID("OnReputationBarUpdate")) then
      local listener = em:CreateEventListenerWithID("OnReputationBarUpdate", OnReputationBarUpdate, self, data);
      listener:SetCallbackArgs(self, data);
      listener:RegisterEvents("UPDATE_FACTION", "PLAYER_REGEN_ENABLED");
    end

    if (self:CanUse()) then
      if (not self:IsActive()) then
        self:SetActive(true);
      end

      -- must be triggered AFTER it has been created!
      em:TriggerEventListenerByID("OnReputationBarUpdate");
    end

  elseif (self:IsActive()) then
    self:SetActive(false);
  end

  local listener = em:GetEventListenerByID("OnReputationBarUpdate");

  if (listener) then
    listener:SetEnabled(enabled);
  end
end
