local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (obj:Import("MayronUI.UniversalWindow.KalielsTrackerAdapter", true)) then
  return;
end

local Common = obj:Import("MayronUI.UniversalWindow.Common");
local IsAddOnLoaded = _G.IsAddOnLoaded;
local math_floor, math_max = _G.math.floor, _G.math.max;
local string = _G.string;

local IsSafeWidget = Common.IsSafeWidget;
local CallOriginalWidgetMethod = Common.CallOriginalWidgetMethod;
local RoundNearest = Common.RoundNearest;
local SetPassiveVisibility = Common.SetPassiveVisibility;

local Adapter = obj:CreateInterface("KalielsTrackerAdapter", {});
Adapter.key = "kalielsTracker";
Adapter.title = L["Kaliel's Tracker"];
Adapter.toggleTitle = L["Toggle Kaliel's Tracker"];
Adapter.iconTexture = "Interface\\AddOns\\!KalielsTracker\\Media\\KT_logo";
Adapter.transparentShell = true;
Adapter.hideShellTitle = true;
Adapter.watchedAddOns = {
  ["!KalielsTracker"] = true;
};

local function GetKalielsTrackerAddon()
  if (not (tk:IsRetail() and IsAddOnLoaded("!KalielsTracker"))) then
    return nil;
  end

  if (obj:IsTable(_G.KalielsTracker) and obj:IsFunction(_G.KalielsTracker.Toggle)) then
    return _G.KalielsTracker;
  end

  return nil;
end

local function GetKalielsTrackerFrame(addon)
  local frame = obj:IsTable(addon) and addon.frame;

  if (IsSafeWidget(frame, "Frame")) then
    return frame;
  end

  frame = _G["!KalielsTrackerFrame"];
  if (IsSafeWidget(frame, "Frame")) then
    return frame;
  end

  return nil;
end

local function ForEachKalielsTrackerWidget(addon, callback)
  local frame = GetKalielsTrackerFrame(addon);

  if (IsSafeWidget(frame, "Frame")) then
    callback(frame);
  end

  if (IsSafeWidget(frame, "Frame") and IsSafeWidget(frame.Child, "Frame")) then
    callback(frame.Child);
  end

  if (IsSafeWidget(frame, "Frame") and IsSafeWidget(frame.Buttons, "Frame")) then
    callback(frame.Buttons);
  end

  if (IsSafeWidget(frame, "Frame") and IsSafeWidget(frame.ActiveFrame, "Frame")) then
    callback(frame.ActiveFrame);
  end

  if (IsSafeWidget(_G.KT_ObjectiveTrackerFrame, "Frame")) then
    callback(_G.KT_ObjectiveTrackerFrame);
  end
end

local function HideDetachedKalielWidgets()
  local detachedWidgets = {
    _G.KT_ObjectiveTrackerUIWidgetContainer;
    _G.KT_ObjectiveTrackerTopBannerFrame;
  };

  for _, widget in ipairs(detachedWidgets) do
    if (IsSafeWidget(widget, "Frame")) then
      pcall(function()
        SetPassiveVisibility(widget, false);
        CallOriginalWidgetMethod(widget, "Hide");
      end);
    end
  end
end

local function GetKalielsTrackerProfile()
  local trackerDB = _G.KalielsTrackerDB;

  if (not obj:IsTable(trackerDB)) then
    return nil;
  end

  if (type(trackerDB.profileKeys) ~= "table") then
    trackerDB.profileKeys = {};
  end

  if (type(trackerDB.profiles) ~= "table") then
    trackerDB.profiles = {};
  end

  local playerName = _G.UnitName and _G.UnitName("player");
  local realmName = _G.GetRealmName and _G.GetRealmName();

  if (not (obj:IsString(playerName) and obj:IsString(realmName))) then
    return nil;
  end

  local charKey = string.format("%s - %s", playerName, realmName);
  local profileName = trackerDB.profileKeys[charKey];

  if (not obj:IsString(profileName) or profileName == tk.Strings.Empty) then
    profileName = "MayronUI";
    trackerDB.profileKeys[charKey] = profileName;
  end

  if (type(trackerDB.profiles[profileName]) ~= "table") then
    trackerDB.profiles[profileName] = {};
  end

  return trackerDB.profiles[profileName];
end

local function GetKalielsTrackerCharacterData()
  local trackerDB = _G.KalielsTrackerDB;

  if (not obj:IsTable(trackerDB)) then
    return nil;
  end

  if (type(trackerDB.char) ~= "table") then
    trackerDB.char = {};
  end

  local playerName = _G.UnitName and _G.UnitName("player");
  local realmName = _G.GetRealmName and _G.GetRealmName();

  if (not (obj:IsString(playerName) and obj:IsString(realmName))) then
    return nil;
  end

  local charKey = string.format("%s - %s", playerName, realmName);
  if (type(trackerDB.char[charKey]) ~= "table") then
    trackerDB.char[charKey] = {};
  end

  if (type(trackerDB.char.collapsed) == "boolean"
      and trackerDB.char[charKey].collapsed == nil) then
    trackerDB.char[charKey].collapsed = trackerDB.char.collapsed;
  end

  trackerDB.char.collapsed = nil;
  return trackerDB.char[charKey];
end

local function StyleKalielsTrackerFrame(frame)
  if (not IsSafeWidget(frame, "Frame")) then
    return;
  end

  if (IsSafeWidget(frame.HeaderButtons, "Frame")) then
    pcall(function()
      frame.HeaderButtons:SetAlpha(1);
      frame.HeaderButtons:Show();
    end);
  end

  if (IsSafeWidget(frame.MinimizeButton, "Frame")) then
    pcall(function()
      frame.MinimizeButton:SetAlpha(1);
      frame.MinimizeButton:Show();
    end);
  end

  if (IsSafeWidget(frame.FilterButton, "Frame")) then
    pcall(function()
      frame.FilterButton:SetAlpha(1);
      frame.FilterButton:Show();
    end);
  end

  if (IsSafeWidget(frame.QuestLogButton, "Frame")) then
    pcall(function()
      frame.QuestLogButton:Hide();
    end);
  end

  if (IsSafeWidget(frame.AchievementsButton, "Frame")) then
    pcall(function()
      frame.AchievementsButton:Hide();
    end);
  end

  if (IsSafeWidget(frame.Background, "Texture")) then
    pcall(function()
      frame.Background:SetAlpha(0);
      frame.Background:Hide();
    end);
  end

  if (IsSafeWidget(frame.Background, "Frame")) then
    pcall(function()
      frame.Background:SetAlpha(0);

      if (obj:IsFunction(frame.Background.SetBackdropColor)) then
        frame.Background:SetBackdropColor(0, 0, 0, 0);
      end

      if (obj:IsFunction(frame.Background.SetBackdropBorderColor)) then
        frame.Background:SetBackdropBorderColor(0, 0, 0, 0);
      end
    end);
  end

end

function Adapter:CanEmbed()
  local addon = GetKalielsTrackerAddon();
  return obj:IsTable(addon) and IsSafeWidget(GetKalielsTrackerFrame(addon), "Frame");
end

function Adapter:Hide(preserveState)
  local addon = GetKalielsTrackerAddon();

  -- Kaliel is the exception among Universal providers: it is safer to turn the
  -- tracker off completely when it is no longer the selected content. Leaving it
  -- passively hidden allows its own runtime updates to push visuals back on top
  -- of the active provider.
  if (obj:IsTable(addon) and obj:IsFunction(addon.Toggle)) then
    pcall(function()
      addon:Toggle(false);
    end);
  end

  ForEachKalielsTrackerWidget(addon, function(widget)
    pcall(function()
      SetPassiveVisibility(widget, false);
    end);
  end);

  HideDetachedKalielWidgets();
end

function Adapter:Show(hostFrame, _, anchorName)
  local addon = GetKalielsTrackerAddon();
  local profile = GetKalielsTrackerProfile();
  local charData = GetKalielsTrackerCharacterData();
  local frame = GetKalielsTrackerFrame(addon);

  if (not (obj:IsTable(addon) and obj:IsTable(profile)
      and IsSafeWidget(frame, "Frame") and IsSafeWidget(hostFrame, "Frame"))) then
    self:Hide();
    return false;
  end

  local left, top = hostFrame:GetLeft(), hostFrame:GetTop();
  local width, height = hostFrame:GetWidth(), hostFrame:GetHeight();
  local uiParent = _G.UIParent;
  local uiScale = uiParent:GetEffectiveScale();
  local hostScale = hostFrame:GetEffectiveScale();
  local scaleRatio = (uiScale > 0 and hostScale > 0) and (hostScale / uiScale) or 1;

  if (not (obj:IsNumber(left) and obj:IsNumber(top)
      and obj:IsNumber(width) and obj:IsNumber(height))) then
    return false;
  end

  left = left * scaleRatio;
  top = top * scaleRatio;
  width = width * scaleRatio;
  height = height * scaleRatio;

  local right = left + width;
  local bottom = top - height;
  local uiWidth = uiParent:GetWidth();
  local uiHeight = uiParent:GetHeight();
  local resolvedAnchor = tk:ValueIsEither(anchorName, "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT")
    and anchorName or "BOTTOMRIGHT";
  local objectiveLeftInset = 4;
  local childPadding = 4;
  local extraContentWidth = 18;
  local trackerWidth;
  local xOffset, yOffset;

  if (resolvedAnchor:find("RIGHT")) then
    xOffset = right - uiWidth;
  else
    xOffset = left - objectiveLeftInset;
  end

  if (resolvedAnchor:find("TOP")) then
    yOffset = top - uiHeight;
  else
    yOffset = bottom;
  end

  profile.anchorPoint = resolvedAnchor;
  profile.xOffset = RoundNearest(xOffset);
  profile.yOffset = RoundNearest(yOffset);
  trackerWidth = math_max(math_floor(width + objectiveLeftInset + childPadding + extraContentWidth), 180);
  profile.width = trackerWidth;
  profile.maxHeight = math_max(math_floor(height), 180);
  profile.frameScale = 1;
  profile.frameStrata = "MEDIUM";
  profile.frameScrollbar = true;
  profile.hideEmptyTracker = false;
  profile.textWordWrap = true;
  profile.hdrBgr = 2;
  profile.hdrTrackerBgrShow = true;
  profile.hdrOtherButtons = false;
  profile.borderAlpha = 0;
  profile.qiBgrBorder = false;
  profile.bgrColor = profile.bgrColor or {};
  profile.bgrColor.a = 0;

  if (obj:IsTable(charData)) then
    charData.collapsed = false;
  end

  if (obj:IsFunction(addon.SetOtherButtons)) then
    pcall(function()
      addon:SetOtherButtons();
    end);
  end

  if (obj:IsFunction(addon.SetBackground)) then
    pcall(function()
      addon:SetBackground();
    end);
  end

  CallOriginalWidgetMethod(frame, "ClearAllPoints");
  CallOriginalWidgetMethod(frame, "SetPoint", resolvedAnchor, uiParent, resolvedAnchor, profile.xOffset, profile.yOffset);
  CallOriginalWidgetMethod(frame, "SetWidth", profile.width);
  CallOriginalWidgetMethod(frame, "SetHeight", profile.maxHeight);
  CallOriginalWidgetMethod(frame, "SetScale", profile.frameScale);
  CallOriginalWidgetMethod(frame, "SetFrameStrata", profile.frameStrata);
  CallOriginalWidgetMethod(frame, "SetAlpha", 1);

  if (IsSafeWidget(frame.Child, "Frame")) then
    CallOriginalWidgetMethod(frame.Child, "SetWidth", math_max(profile.width - childPadding, 1));
    CallOriginalWidgetMethod(frame.Child, "SetHeight", math_max(profile.maxHeight - 8, 1));
  end

  if (IsSafeWidget(_G.KT_ObjectiveTrackerFrame, "Frame") and IsSafeWidget(frame.Child, "Frame")) then
    CallOriginalWidgetMethod(_G.KT_ObjectiveTrackerFrame, "ClearAllPoints");
    CallOriginalWidgetMethod(_G.KT_ObjectiveTrackerFrame, "SetPoint",
      "TOPLEFT", frame.Child, "TOPLEFT", objectiveLeftInset, 0);
    CallOriginalWidgetMethod(_G.KT_ObjectiveTrackerFrame, "SetPoint",
      "BOTTOMRIGHT", frame.Child, "BOTTOMRIGHT");
  end

  if (IsSafeWidget(frame.Background, "Frame")) then
    CallOriginalWidgetMethod(frame.Background, "SetHeight", profile.maxHeight);
  end

  if (IsSafeWidget(_G.KT_ObjectiveTrackerFrame, "Frame")) then
    local trackerHeader = _G.KT_ObjectiveTrackerFrame.Header;

    if (obj:IsTable(trackerHeader)) then
      if (IsSafeWidget(trackerHeader, "Frame")) then
        pcall(function()
          trackerHeader:SetWidth(math_max(profile.width - objectiveLeftInset - childPadding, 1));
        end);
      end

      if (IsSafeWidget(trackerHeader.Text, "FontString")) then
        pcall(function()
          trackerHeader.Text:SetWidth(math_max(profile.width - 73, 1));
        end);
      end
    end
  end

  if (obj:IsFunction(addon.MoveTracker)) then
    pcall(function()
      addon:MoveTracker();
    end);
  end

  if (obj:IsFunction(addon.SetText)) then
    pcall(function()
      addon:SetText(true);
    end);
  end

  if (obj:IsFunction(addon.SetSize)) then
    pcall(function()
      addon:SetSize(true);
    end);
  end

  if (IsSafeWidget(_G.KT_ObjectiveTrackerFrame, "Frame")) then
    pcall(function()
      if (obj:IsFunction(_G.KT_ObjectiveTrackerFrame.SetCollapsed)) then
        _G.KT_ObjectiveTrackerFrame:SetCollapsed(false);
      end

      if (obj:IsFunction(_G.KT_ObjectiveTrackerFrame.MarkDirty)) then
        _G.KT_ObjectiveTrackerFrame:MarkDirty();
      end

      if (obj:IsFunction(_G.KT_ObjectiveTrackerFrame.Update)) then
        _G.KT_ObjectiveTrackerFrame:Update();
      end
    end);
  end

  if (obj:IsFunction(addon.Toggle)) then
    pcall(function()
      addon:Toggle(true);
    end);
  end

  ForEachKalielsTrackerWidget(addon, function(widget)
    pcall(function()
      SetPassiveVisibility(widget, true);
      CallOriginalWidgetMethod(widget, "Show");
    end);
  end);

  HideDetachedKalielWidgets();
  CallOriginalWidgetMethod(frame, "Show");
  StyleKalielsTrackerFrame(frame);
  return true;
end

obj:Export(Adapter, "MayronUI.UniversalWindow.KalielsTrackerAdapter");
