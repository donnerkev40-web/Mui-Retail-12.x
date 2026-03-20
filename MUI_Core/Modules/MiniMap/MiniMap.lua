-- luacheck: ignore MayronUI self 143
local addOnName = ...;
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents();

-- Register and Import ---------

---@class MiniMapModule : BaseModule
local C_MiniMapModule = MayronUI:RegisterModule("MiniMap", L["Mini-Map"]);

local Minimap, math, table, C_Timer, Minimap_ZoomIn, Minimap_ZoomOut,
      GameTooltip, IsAltKeyDown, LoadAddOn, IsAddOnLoaded,
      ToggleDropDownMenu, PlaySound, select = _G.Minimap,
  _G.math, _G.table, _G.C_Timer, _G.Minimap_ZoomIn, _G.Minimap_ZoomOut,
  _G.GameTooltip, _G.IsAltKeyDown, _G.LoadAddOn,
  _G.IsAddOnLoaded, _G.ToggleDropDownMenu, _G.PlaySound, _G.select;

local GetTrackingTexture = _G["GetTrackingTexture"]; ---@type function
local IsInInstance, GetInstanceInfo, GetNumGroupMembers, ipairs =
  _G.IsInInstance, _G.GetInstanceInfo, _G.GetNumGroupMembers, _G.ipairs;

local strformat = _G.string.format;

local C_Garrison, C_Covenants = _G.C_Garrison, _G.C_Covenants;

do
  local backdrop = _G.MinimapBackdrop;

  if (obj:IsWidget(backdrop)) then
    backdrop:ClearAllPoints();
    backdrop:SetPoint("TOPLEFT", Minimap);
    backdrop:SetPoint("BOTTOMRIGHT", Minimap);
    backdrop.ClearAllPoints = tk.Constants.DUMMY_FUNC;
    backdrop.SetPoint = tk.Constants.DUMMY_FUNC;
    backdrop.SetAllPoints = tk.Constants.DUMMY_FUNC;
  end
end

local function HideMenu()
  if (obj:IsWidget(_G.DropDownList1)) then
    _G.DropDownList1:Hide();
  end

  if (obj:IsWidget(_G.DropDownList2)) then
    _G.DropDownList2:Hide();
  end
end

local function ShowDropDownMenu(menuList, menuFrame)
  local easyMenu = _G.EasyMenu;

  if (obj:IsFunction(easyMenu)) then
    easyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 1);
    return true;
  end

  local initialize = _G.UIDropDownMenu_Initialize;
  local createInfo = _G.UIDropDownMenu_CreateInfo;
  local addButton = _G.UIDropDownMenu_AddButton;

  if (not (obj:IsFunction(initialize) and obj:IsFunction(createInfo) and obj:IsFunction(addButton))) then
    return false;
  end

  initialize(menuFrame, function(_, level)
    local entries = menuList;

    if ((level or 1) > 1) then
      entries = _G.UIDROPDOWNMENU_MENU_VALUE;
    end

    if (not obj:IsTable(entries)) then
      return;
    end

    for _, entry in ipairs(entries) do
      local info = createInfo();

      for key, value in pairs(entry) do
        info[key] = value;
      end

      if (entry.menuList and info.value == nil) then
        info.value = entry.menuList;
      end

      addButton(info, level);
    end
  end, "MENU");

  ToggleDropDownMenu(1, nil, menuFrame, "cursor", 0, 0, nil, nil, 1);
  return true;
end

local function SkinDropDownList(listFrame)
  if (not obj:IsWidget(listFrame)) then
    return;
  end

  local r, g, b = tk:GetThemeColor();

  if (not listFrame.muiDialogApplied) then
    local originalStrata = listFrame:GetFrameStrata();
    gui:AddDialogTexture(listFrame, "High", 8);
    listFrame:SetFrameStrata(originalStrata);
    listFrame.muiDialogApplied = true;
  end

  if (obj:IsFunction(listFrame.SetGridColor)) then
    listFrame:SetGridColor(r, g, b);
  end

  for _, region in ipairs({listFrame:GetRegions()}) do
    if (obj:IsWidget(region) and region:GetObjectType() == "Texture") then
      region:SetAlpha(0);
    end
  end

  local maxButtons = _G.UIDROPDOWNMENU_MAXBUTTONS or 32;

  for i = 1, maxButtons do
    local button = _G[listFrame:GetName() .. "Button" .. i];

    if (obj:IsWidget(button)) then
      if (not button.muiSkinned) then
        local highlight = button:GetHighlightTexture();

        if (obj:IsWidget(highlight)) then
          highlight:SetColorTexture(r, g, b, 0.18);
        end

        local normalText = _G[button:GetName() .. "NormalText"];
        if (obj:IsWidget(normalText)) then
          normalText:SetFontObject("MUI_FontNormal");
        end

        local invisibleButton = _G[button:GetName() .. "InvisibleButton"];
        if (obj:IsWidget(invisibleButton)) then
          local invisibleText = _G[invisibleButton:GetName() .. "NormalText"];

          if (obj:IsWidget(invisibleText)) then
            invisibleText:SetFontObject("MUI_FontNormal");
          end
        end

        button.muiSkinned = true;
      end
    end
  end
end

local function SkinMinimapMenus()
  SkinDropDownList(_G.DropDownList1);
  SkinDropDownList(_G.DropDownList2);
  SkinDropDownList(_G.DropDownList3);
end

local function GetMissionButton()
  if (not tk:IsRetail()) then
    return nil;
  end

  return _G.ExpansionLandingPageMinimapButton or _G.GarrisonLandingPageMinimapButton;
end

local function GetTrackingWidget()
  local minimapCluster = _G.MinimapCluster;

  return _G.MiniMapTracking
    or _G.MiniMapTrackingFrame
    or (minimapCluster and minimapCluster.Tracking);
end

local function GetTrackingMenuFrame()
  return _G.MiniMapTrackingDropDown or _G.MiniMapTrackingButtonDropDown;
end

local function ToggleCalendar()
  if (not (tk:IsRetail() or tk:IsWrathClassic())) then
    return false;
  end

  if (not _G.CalendarFrame) then
    local ok = pcall(LoadAddOn, "Blizzard_Calendar");

    if (not ok) then
      return false;
    end
  end

  if (obj:IsFunction(_G.Calendar_Toggle)) then
    local ok = pcall(_G.Calendar_Toggle);
    return ok and true or false;
  end

  return false;
end

local function GetPendingCalendarInvites()
  if (not (obj:IsTable(_G.C_Calendar) and obj:IsFunction(_G.C_Calendar.GetNumPendingInvites))) then
    return 0;
  end

  local ok, invites = pcall(_G.C_Calendar.GetNumPendingInvites);

  if (ok and obj:IsNumber(invites) and invites > 0) then
    return invites;
  end

  return 0;
end

local function GetLandingPageGarrisonType()
  if (not (obj:IsTable(C_Garrison) and obj:IsFunction(C_Garrison.GetLandingPageGarrisonType))) then
    return nil;
  end

  local ok, garrisonType = pcall(C_Garrison.GetLandingPageGarrisonType);

  if (ok and obj:IsNumber(garrisonType) and garrisonType > 0) then
    return garrisonType;
  end

  return nil;
end

local function GetExpansionLandingPageInfo()
  local expansionLandingPage = _G.ExpansionLandingPage;

  if (not (obj:IsTable(expansionLandingPage)
      and obj:IsFunction(expansionLandingPage.GetOverlayMinimapDisplayInfo))) then
    return nil;
  end

  local ok, info = pcall(
    expansionLandingPage.GetOverlayMinimapDisplayInfo, expansionLandingPage);

  if (ok and obj:IsTable(info)) then
    return info;
  end

  return nil;
end

local function GetFirstMissionLabel(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...);

    if (type(value) == "string" and value:find("%S")) then
      return value;
    end
  end
end

local function GetMissionEntryLabel(widget, garrisonType)
  local info = GetExpansionLandingPageInfo();

  if (obj:IsTable(info)) then
    local label = GetFirstMissionLabel(
      info.tooltipTitle, info.title, info.label, info.name, info.text);

    if (label) then
      return label;
    end
  end

  local alertText;
  if (obj:IsWidget(widget) and obj:IsWidget(widget.AlertText)) then
    alertText = widget.AlertText:GetText();
  end

  if (obj:IsWidget(widget) and widget.garrisonMode) then
    if (garrisonType == 111) then
      return L["Covenant Sanctum"];
    end

    local label = GetFirstMissionLabel(widget.tooltipText, widget.title, alertText);
    if (label) then
      return label;
    end

    return L["Expansion Features"];
  end

  if (obj:IsWidget(widget)) then
    local label = GetFirstMissionLabel(widget.tooltipText, widget.title, alertText);

    if (label) then
      return label;
    end
  end

  return L["Expansion Features"];
end

local function IsWidgetActuallyShown(widget)
  if (not obj:IsWidget(widget)) then
    return false;
  end

  if (obj:IsFunction(widget.IsShown)) then
    local ok, shown = pcall(widget.IsShown, widget);

    if (ok and shown) then
      return true;
    end
  end

  return false;
end

local function CanViewMissions(widget)
  widget = widget or GetMissionButton();

  return IsWidgetActuallyShown(widget);
end

local function ResolveMissionEntry()
  local widget = GetMissionButton();
  local garrisonType = GetLandingPageGarrisonType();
  local available = CanViewMissions(widget);

  if (not obj:IsWidget(widget)) then
    return nil;
  end

  return {
    widget = widget;
    garrisonType = garrisonType;
    available = available;
    text = GetMissionEntryLabel(widget, garrisonType);
  };
end

local function OpenMissionEntry(state)
  if (not tk:IsRetail()) then
    return false;
  end

  local widget = (state and state.widget) or GetMissionButton();

  if (not IsWidgetActuallyShown(widget)) then
    return false;
  end

  if (obj:IsWidget(widget)) then
    if (obj:IsFunction(widget.ToggleLandingPage)) then
      local ok = pcall(widget.ToggleLandingPage, widget);

      if (ok) then
        return true;
      end
    end

    if (obj:IsFunction(widget.Click)) then
      local ok = pcall(widget.Click, widget);

      if (ok) then
        return true;
      end
    end

    if (obj:IsFunction(widget.GetScript)) then
      local onClick = widget:GetScript("OnClick");

      if (obj:IsFunction(onClick)) then
        local ok = pcall(onClick, widget, "LeftButton");

        if (ok) then
          return true;
        end
      end
    end
  end

  return false;
end

-- Load Database Defaults --------------

db:AddToDefaults("profile.minimap", {
  enabled = true;
  point = "TOPRIGHT";
  relativePoint = "TOPRIGHT";
  x = -4;
  y = -4;
  size = 200;
  scale = 1;
  hideIcons = true;
  testMode = false; -- for testing
  showPointsOfInterest = false;
  resetZoom = {
    enabled = false;
    time = 5;
  };

  widgets = {
    clock = {
      hide = false;
      fontSize = 12;
      point = "BOTTOMRIGHT";
      x = 0;
      y = tk:IsRetail() and 4 or 0
    };

    difficulty = {
      show = true;
      fontSize = 12;
      point = "TOPRIGHT";
      x = -8;
      y = -8;
    };

    lfg = { scale = 0.9; point = "BOTTOMLEFT"; x = 22; y = 0 };

    calendar = {
      hide = false;
      scale = 1;
      point = "TOPRIGHT";
      x = -6;
      y = -4;
    };

    mail = {
      scale = 1;
      point = "BOTTOMRIGHT";
      x = -8;
      y = 22
    };

    battlefield = {
      hide = false;
      scale = 1;
      point = "BOTTOMLEFT";
      x = 44;
      y = 0;
    };

    missions = {
      hide = false;
      scale = 0.5;
      point = "TOPLEFT";
      x = 6;
      y = -6
    };

    tracking = {
      hide = false;
      scale = (tk:IsRetail() and 1.2 or (tk:IsClassic() and 0.7 or 0.9));
      point = (tk:IsClassic() and "TOPLEFT" or "BOTTOMLEFT");
      x = tk:IsRetail() and 2 or (tk:IsClassic() and 5 or 0);
      y = tk:IsRetail() and 4 or (tk:IsClassic() and -5 or 2);
    };

    zone = { hide = true; point = "TOP"; fontSize = 10; x = 0; y = -4 };
  };
});

local Minimap_OnDragStart;
local Minimap_OnDragStop;

do
  local updateSizeText;

  local function OnResizeDragStep()
    local width = Minimap:GetWidth();
    width = (math.floor(width + 100.5) - 100);
    Minimap:SetSize(width, width);

    if (not updateSizeText) then
      Minimap.size:SetText("");
    else
      Minimap.size:SetText(width .. " x " .. width);
    end

    C_Timer.After(0.02, OnResizeDragStep);
  end

  function Minimap_OnDragStart()
    if (tk:IsModComboActive("C")) then
      if (Minimap:IsMovable()) then
        Minimap:StartMoving();
      end
    elseif (tk:IsModComboActive("S")) then
      Minimap:StartSizing();
      updateSizeText = true;
      C_Timer.After(0.1, OnResizeDragStep);
    end
  end

  function Minimap_OnDragStop(data)
    Minimap:StopMovingOrSizing();
    updateSizeText = nil;

    Minimap_ZoomIn();
    Minimap_ZoomOut();

    local width = Minimap:GetWidth();
    width = math.floor(width + 0.5);

    if (width % 2 > 0) then
      width = width + 1;
    end

    Minimap:SetSize(width, width);

    local settings = data.settings:GetTrackedTable();
    local relativeTo;

    settings.size = width;
    settings.point, relativeTo, settings.relativePoint, settings.x, settings.y = Minimap:GetPoint();

    local x = math.floor(settings.x + 0.5);
    local y = math.floor(settings.y + 0.5);

    if (x % 2 > 0) then
      x = x + 1;
    end

    if (y % 2 > 0) then
      y = y + 1;
    end

    settings.x = x;
    settings.y = y;

    Minimap:SetPoint(
      settings.point, relativeTo or _G.UIParent, settings.relativePoint,
        settings.x, settings.y);

    settings:SaveChanges();
  end
end

local callback;
callback = tk:HookFunc("BattlefieldMap_LoadUI", function()
  if (IsAddOnLoaded("Blizzard_BattlefieldMap") and _G.BattlefieldMapFrame) then
    local updateSize;
    local originalWidth, originalHeight = 298, 199;
    local mapFrame, mapTab, mapOptions = _G.BattlefieldMapFrame, _G.BattlefieldMapTab, _G.BattlefieldMapOptions;
    local previousWidth;
    local GetMinimapZoneText = _G.GetMinimapZoneText;

    local function DragStep()
      if (not updateSize) then
        return
      end
      local width = mapFrame:GetWidth();

      if (previousWidth ~= width) then
        previousWidth = width;
        width = (math.floor(width + 100.5) - 100);

        local difference = width / originalWidth;
        local height = originalHeight * difference;
        mapFrame:SetSize(width, height);
        mapFrame.ScrollContainer:OnCanvasSizeChanged()
      end

      if (updateSize) then
        C_Timer.After(0.02, DragStep);
      end
    end

    local function update(self)
      if (self.reskinned) then
        if (self.titleBar) then
          self.titleBar.text:SetText(GetMinimapZoneText());
        end
        return
      end

      self.BorderFrame:DisableDrawLayer("ARTWORK");
      originalWidth, originalHeight = self.ScrollContainer:GetSize();

      gui:AddResizer(self);
      self.dragger:SetParent(self.BorderFrame);

      if (obj:IsFunction(self.SetMinResize)) then
        self:SetMinResize(originalWidth, originalHeight);
        self:SetMaxResize(1200, 800);
      else
        -- dragonflight:
        self:SetResizeBounds(originalWidth, originalHeight, 1200, 800);
      end

      gui:AddTitleBar(self, GetMinimapZoneText());
      self.titleBar:SetFrameStrata("HIGH");
      self.titleBar:RegisterForClicks("RightButtonUp");
      self.titleBar:SetScript("OnClick", function(self, button)
        if (button == "RightButton") then
          PlaySound(tk.Constants.CLICK);

          -- If Rightclick bring up the options menu
          if (button == "RightButton") then
            local function InitializeOptionsDropDown(self)
              self:GetParent():InitializeOptionsDropDown();
            end
            _G.UIDropDownMenu_Initialize(
              mapTab.OptionsDropDown, InitializeOptionsDropDown, "MENU");
            ToggleDropDownMenu(1, nil, mapTab.OptionsDropDown, self, 0, 0);
            return;
          end
        end
      end);

      self.dragger:SetFrameStrata("HIGH");
      mapTab:Hide();
      mapTab.Show = tk.Constants.DUMMY_FUNC;

      local container = self.ScrollContainer;
      container:SetAllPoints(self);

      self.dragger:HookScript("OnDragStop", function()
        container:ZoomIn();
        container:ZoomOut();
        updateSize = nil;
      end);

      self.dragger:HookScript("OnDragStart", function()
        updateSize = true;
        C_Timer.After(0.1, DragStep);
      end);

      self.reskinned = true;
    end

    mapFrame:SetFrameStrata("MEDIUM");
    mapFrame:HookScript("OnShow", update);
    mapFrame:HookScript("OnEvent", function(self)
      if (self.titleBar) then
        self.titleBar.text:SetText(GetMinimapZoneText());
      end
    end);

    local bgFrame = tk:CreateFrame("Frame", mapFrame, "MUI_ZoneMap");
    local bg = gui:AddDialogTexture(bgFrame);
    bg:SetAllPoints(true);
    bg:SetFrameStrata("LOW");
    bg:SetAlpha(1.0 - mapOptions.opacity);

    tk:HookFunc(mapFrame, "RefreshAlpha", function()
      local alpha = 1.0 - mapOptions.opacity;
      bg:SetAlpha(1.0 - mapOptions.opacity);
      mapFrame.titleBar:SetAlpha(math.max(alpha, 0.3));
    end);

    mapFrame.BorderFrame.CloseButtonBorder:SetTexture("");
    mapFrame.BorderFrame.CloseButton:SetPoint(
      "TOPRIGHT", mapFrame.BorderFrame, "TOPRIGHT", 5, 5);
    tk:UnhookFunc("BattlefieldMap_LoadUI", callback);
  end
end);

local function SetAddonIconsShown(showOnMinimap)
  local libDbIcons = _G.LibStub and _G.LibStub("LibDBIcon-1.0", true);
  local zygorMapIcon = _G.ZygorGuidesViewerMapIcon;

  if (obj:IsTable(libDbIcons) and obj:IsFunction(libDbIcons.GetButtonList)
      and obj:IsFunction(libDbIcons.GetMinimapButton)) then
    for _, iconName in ipairs(libDbIcons:GetButtonList()) do
      local iconButton = libDbIcons:GetMinimapButton(iconName);

      if (obj:IsWidget(iconButton)) then
        if (showOnMinimap) then
          iconButton:SetParent(Minimap);
          iconButton:Show();
        else
          iconButton:Hide();
        end
      end
    end
  end

  if (obj:IsWidget(zygorMapIcon)) then
    if (showOnMinimap) then
      zygorMapIcon:SetParent(Minimap);
      zygorMapIcon:Show();
    else
      zygorMapIcon:Hide();
    end
  end
end

local function ApplyDefaultMinimapFrameStyle(data)
  if (obj:IsFunction(Minimap.SetMaskTexture)) then
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground");
  end

  if (obj:IsWidget(data and data.container)) then
    data.container:Show();
  end

  if (obj:IsFunction(Minimap.SetBackdropBorderColor)) then
    Minimap:SetBackdropBorderColor(0, 0, 0, 1);
  end

  if (obj:IsFunction(_G.SetCVar)) then
    pcall(_G.SetCVar, "rotateMinimap", 0);
  end
end

do
  local widgetMethods = {};
  local positioningMethods = {"SetParent"; "ClearAllPoints"; "SetPoint"; "SetScale"};
  local visibilityMethods = {"Show"; "Hide"; "SetShown"};

  local function CallWidgetMethod(method, widget, ...)
    if (obj:IsWidget(widget) and obj:IsFunction(method)) then
      local ok = pcall(method, widget, ...);
      return ok;
    end

    return false;
  end

  function C_MiniMapModule.Private:SetUpWidget(data, name, widget)
    local methods = widgetMethods[name];
    local settings = data.settings.widgets[name];

    if (not widget or not obj:IsTable(settings)) then
      return;
    end

    if (not methods or methods.__widget ~= widget) then
      methods = obj:PopTable();
      widgetMethods[name] = methods;
      methods.__widget = widget;

      for _, m in ipairs(positioningMethods) do
        methods[m] = obj:IsFunction(widget[m]) and widget[m] or nil;

        if (methods[m]) then
          widget[m] = tk.Constants.DUMMY_FUNC;
        end
      end
    end

    CallWidgetMethod(methods.SetParent, widget, Minimap);
    CallWidgetMethod(methods.ClearAllPoints, widget);

    if (name == "zone") then
      local anchor = (settings.point == "BOTTOM") and "BOTTOM" or "TOP";
      local x = settings.x or 0;
      local y = settings.y or 0;
      CallWidgetMethod(methods.SetPoint, widget, anchor.."LEFT", Minimap, anchor.."LEFT", 6 + x, y);
      CallWidgetMethod(methods.SetPoint, widget, anchor.."RIGHT", Minimap, anchor.."RIGHT", -6 + x, y);

      if (obj:IsFunction(widget.SetHeight)) then
        widget:SetHeight(math.max((settings.fontSize or 10) + 8, 18));
      end
    else
      CallWidgetMethod(methods.SetPoint, widget, settings.point, settings.x, settings.y);
    end

    if (settings.scale) then
      CallWidgetMethod(methods.SetScale, widget, settings.scale);
    end

    if (data.testModeActive) then
      return
    end

    if (data.settings.testMode) then
      data.isShown = data.isShown or obj:PopTable();

      if (name == "difficulty") then
        data.previousDifficulty = widget:GetText() or "";
        widget:SetText("25H");
      else
        data.isShown[name] = widget:IsShown();

        if (obj:IsFunction(widget.Show) and widget.Show ~= tk.Constants.DUMMY_FUNC) then
          widget:Show();
        else
          CallWidgetMethod(methods.Show, widget);
        end
      end
    else
      if (name == "difficulty" and data.previousDifficulty ~= nil) then
        widget:SetText(data.previousDifficulty);
        data.previousDifficulty = nil;
      else
        if (obj:IsTable(data.isShown) and data.isShown[name] ~= nil) then
          if (obj:IsFunction(widget.SetShown) and widget.SetShown ~= tk.Constants.DUMMY_FUNC) then
            widget:SetShown(data.isShown[name]);
          else
            CallWidgetMethod(methods.SetShown, widget, data.isShown[name]);
          end
          data.isShown[name] = nil;
        end
      end

      -- if nil, then let it show/hide naturally
      local shown = nil;
      if (settings.hide or settings.show == false) then
        -- blizzard element or something we want to hide perminently
        shown = false;
      elseif (settings.hide == false or settings.show) then
        if (name == "missions") then
          local missionEntry = ResolveMissionEntry();
          shown = obj:IsTable(missionEntry) and missionEntry.available and missionEntry.widget == widget;
        else
          -- if show, custom MUI widget that should be shown
          shown = true;
        end
      end

      if (shown ~= nil) then
        if (obj:IsFunction(widget.SetShown) and widget.SetShown ~= tk.Constants.DUMMY_FUNC) then
          widget:SetShown(shown);

          for _, m in ipairs(visibilityMethods) do
            methods[m] = obj:IsFunction(widget[m]) and widget[m] or methods[m];

            if (obj:IsFunction(widget[m])) then
              widget[m] = tk.Constants.DUMMY_FUNC;
            end
          end
        else
          CallWidgetMethod(methods.SetShown, widget, shown);
        end
      end
    end
  end

  local function SetUpWidgetText(fontstring, settings)
    local point = obj:IsString(settings.point) and settings.point or "CENTER";

    if (point:find("LEFT")) then
      fontstring:SetJustifyH("LEFT");
    elseif (point:find("RIGHT")) then
      fontstring:SetJustifyH("RIGHT");
    else
      fontstring:SetJustifyH("CENTER");
    end

    fontstring:SetFontObject("MUI_FontNormal");
    tk:SetFontSize(fontstring, settings.fontSize);

    if (fontstring:GetParent() ~= Minimap) then
      fontstring:ClearAllPoints();

      if (point:find("LEFT")) then
        fontstring:SetPoint("LEFT", 7, 0);
      elseif (point:find("RIGHT")) then
        fontstring:SetPoint("RIGHT", -7, 0);
      else
        fontstring:SetPoint("CENTER");
      end
    end
  end

  local function SetDungeonDifficultyShown(data)
    if (not (tk:IsRetail() or tk:IsWrathClassic())) then
      return
    end

    local widgets = data.settings.widgets;

    if (not data.dungeonDifficulty and not widgets.difficulty.show) then
      return
    end

    if (not data.dungeonDifficulty) then
      data.dungeonDifficulty = Minimap:CreateFontString(nil, "OVERLAY");

      local listener = em:CreateEventListenerWithID("DungeonDifficultyText", function()
        if (not IsInInstance()) then
          data.dungeonDifficulty:SetText("");
          return
        end

        local difficultyID = select(3, GetInstanceInfo());

        if (difficultyID == 2 or difficultyID == 5 or difficultyID == 6 or difficultyID == 15) then
          difficultyID = "H";
        elseif (difficultyID == 8 or difficultyID == 16 or difficultyID == 23) then
          difficultyID = "M";
        elseif (difficultyID == 7) then
          difficultyID = "RF";
        else
          difficultyID = "";
        end

        local players = GetNumGroupMembers();
        players = (players > 0 and players) or 1;
        data.dungeonDifficulty:SetText(players .. difficultyID); -- localization possible?
      end);

      listener:RegisterEvents(
        "PLAYER_DIFFICULTY_CHANGED",
        "UPDATE_INSTANCE_INFO",
        "GROUP_ROSTER_UPDATE");
    else
      if (widgets.difficulty.show) then
        em:EnableEventListeners("DungeonDifficultyText");
      else
        em:DisableEventListeners("DungeonDifficultyText");
      end
    end

    data:Call("SetUpWidget", "difficulty", data.dungeonDifficulty);
    SetUpWidgetText(data.dungeonDifficulty, widgets.difficulty);
  end

  local function HandleTrackingChanged(self)
    local texture = GetTrackingTexture();
    self.icon:SetTexture(texture);

    if (texture) then
      self.bg:Show();
    else
      self.bg:Hide();
    end
  end

  function C_MiniMapModule.Private:SetUpWidgets(data)
    local widgets = data.settings.widgets;
    local minimapCluster = _G.MinimapCluster;

    -- clock:
    local clock = _G.TimeManagerClockButton;
    if (obj:IsWidget(clock)) then
      clock:DisableDrawLayer("BORDER");
      data:Call("SetUpWidget", "clock", clock);

      if (obj:IsWidget(_G.TimeManagerClockTicker)) then
        _G.TimeManagerClockTicker:SetParent(clock);
        _G.TimeManagerClockTicker:ClearAllPoints();
        _G.TimeManagerClockTicker:SetPoint("CENTER");
        SetUpWidgetText(_G.TimeManagerClockTicker, widgets.clock);
      end
    end

    -- calendar:
    local calendarButton = _G.GameTimeFrame;
    if (obj:IsWidget(calendarButton)) then
      data:Call("SetUpWidget", "calendar", calendarButton);
    end

    -- difficulty:
    SetDungeonDifficultyShown(data);

    -- lfg:
    if (tk:IsRetail()) then
      if (not data.reskinnedLFG) then
        tk:KillElement(_G.MiniMapInstanceDifficulty);
        tk:KillElement(_G.GuildInstanceDifficulty);
        tk:KillElement(_G.QueueStatusMinimapButtonBorder);

        data.reskinnedLFG = true;
      end

      if (_G.QueueStatusMinimapButton) then
        data:Call("SetUpWidget", "lfg", _G.QueueStatusMinimapButton);
      end
    elseif (_G.MiniMapLFGFrame) then
      if (not data.reskinnedLFG) then
        local border = _G.MiniMapLFGBorder or _G.MiniMapLFGFrameBorder;
        if (obj:IsWidget(border)) then
          tk:KillElement(border);
        end
        data.reskinnedLFG = true;
      end
      data:Call("SetUpWidget", "lfg", _G.MiniMapLFGFrame);
    end

    local mailFrame = _G.MiniMapMailFrame or (minimapCluster and minimapCluster.MailFrame);
    if (mailFrame) then
      -- dragonflight removed all this:
      data:Call("SetUpWidget", "mail", mailFrame);
      mailFrame:SetSize(18, 13);
      mailFrame:SetAlpha(0.9);

      if (_G.MiniMapMailBorder) then
        _G.MiniMapMailBorder:Hide();
      end

      local icon = _G.MiniMapMailIcon;

      if (obj:IsWidget(icon) and icon:GetObjectType() == "Texture") then
        icon:ClearAllPoints();
        icon:SetAllPoints(mailFrame);
        icon:SetTexture(tk:GetAssetFilePath("Icons\\mail"));
      end
    end

    -- battlefield:
    local battlefieldFrame = _G.MiniMapBattlefieldFrame;
    if (obj:IsWidget(battlefieldFrame)) then
      local battlefieldBorder = _G.MiniMapBattlefieldBorder
        or _G.MiniMapBattlefieldFrameBorder;

      if (obj:IsWidget(battlefieldBorder)) then
        tk:KillElement(battlefieldBorder);
      end

      local battlefieldIcon = _G.MiniMapBattlefieldIcon;
      if (obj:IsWidget(battlefieldIcon) and obj:IsFunction(battlefieldIcon.SetTexCoord)) then
        battlefieldIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
      end

      data:Call("SetUpWidget", "battlefield", battlefieldFrame);
    end

    -- missions icon:
    local missionBtn = GetMissionButton();
    if (tk:IsRetail() and obj:IsWidget(missionBtn)) then
      -- dragonflight removed this:
      data:Call("SetUpWidget", "missions", missionBtn);
      -- prevents popup from showing:
      missionBtn:DisableDrawLayer("OVERLAY");
      missionBtn:DisableDrawLayer("HIGHLIGHT");
      -- missionBtn:DisableDrawLayer("BORDER");
      if (obj:IsWidget(missionBtn.SideToastGlow)) then
        missionBtn.SideToastGlow:SetTexture("");
      end

      if (not missionBtn.garrisonMode) then
        -- dragonflight
        local textures = {
          missionBtn:GetNormalTexture(),
          missionBtn:GetPushedTexture(),
          missionBtn:GetHighlightTexture()
        };

        for i = 1, 3 do
          local texture = textures[i];

          if (obj:IsWidget(texture)) then
            texture:SetTexCoord(0.2, 0.8, 0.2, 0.8);
            texture:ClearAllPoints();
            texture:SetPoint("TOPLEFT", 2, -2);
            texture:SetPoint("BOTTOMRIGHT", -2, 2);
          end
        end

        _G.Mixin(missionBtn, _G.BackdropTemplateMixin);
        missionBtn:SetBackdrop(tk.Constants.BACKDROP_WITH_BACKGROUND);
        missionBtn:SetBackdropBorderColor(0, 0, 0);
        missionBtn:SetBackdropColor(0, 0, 0);
      end
    end

    -- tracking:
    local tracking = GetTrackingWidget();

    if (obj:IsWidget(tracking)) then
      local icon = _G["MiniMapTrackingIcon"]; ---@type Texture

      if (obj:IsWidget(icon)) then
        tk:KillElement(_G["MiniMapTrackingIconOverlay"]);

        if (tk:IsClassic()) then
          icon:SetDrawLayer("ARTWORK", 7);
          icon:ClearAllPoints();
          icon:SetPoint("TOPLEFT", tracking, "TOPLEFT", 2, -2);
          icon:SetPoint("BOTTOMRIGHT", tracking, "BOTTOMRIGHT", -2, 2);

          -- for classic era:
          if (GetTrackingTexture) then
            if (not icon:GetTexture()) then
              local texture = GetTrackingTexture();

              if (texture) then
                icon:SetTexture(texture);
              end
            end

            if (obj:IsFunction(icon.SetTexCoord)) then
              icon:SetTexCoord(0.075, 0.925, 0.075, 0.925);
              local bg = tk:SetBackground(tracking, 0, 0, 0);
              tracking.bg = bg;
              tracking.icon = icon;
              tracking:HookScript("OnEvent", HandleTrackingChanged);
              HandleTrackingChanged(tracking);
            end
          end
        end
      end

      tk:KillElement(_G.MiniMapTrackingBorder or _G.MiniMapTrackingButtonBorder);
      local clusterTracking = minimapCluster and minimapCluster.Tracking;
      tk:KillElement(_G.MiniMapTrackingBackground or (clusterTracking and clusterTracking.Background));

      local border = _G.MiniMapTrackingBorder or _G.MiniMapTrackingButtonBorder;
      if (obj:IsWidget(border)) then
        tk:KillElement(border);
      end

      data:Call("SetUpWidget", "tracking", tracking);
    end

    -- zone:
    local zoneBtn = _G.MinimapZoneTextButton or (minimapCluster and minimapCluster.ZoneTextButton);

    if (zoneBtn) then
      data:Call("SetUpWidget", "zone", zoneBtn);
    end

    if (obj:IsWidget(_G.MinimapZoneText)) then
      SetUpWidgetText(_G.MinimapZoneText, widgets.zone);
      pcall(_G.MinimapZoneText.ClearAllPoints, _G.MinimapZoneText);

      local zoneParent = _G.MinimapZoneText:GetParent();
      if (not obj:IsWidget(zoneParent)) then
        zoneParent = zoneBtn or Minimap;
      end

      pcall(_G.MinimapZoneText.SetPoint, _G.MinimapZoneText, "CENTER", zoneParent, "CENTER", 0, 0);

      if (obj:IsFunction(_G.MinimapZoneText.SetWidth)) then
        local width = obj:IsWidget(zoneParent) and zoneParent:GetWidth() or Minimap:GetWidth();
        pcall(_G.MinimapZoneText.SetWidth, _G.MinimapZoneText, math.max(width - 12, 1));
      end

      if (obj:IsFunction(_G.MinimapZoneText.SetJustifyH)) then
        pcall(_G.MinimapZoneText.SetJustifyH, _G.MinimapZoneText, "CENTER");
      end
    end

    data:Call("UpdateMissionsMenuOption");
  end
end

function C_MiniMapModule.Private:UpdateTrackingMenuOptionVisibility(data)
  local tracking = GetTrackingWidget();
  local oldIndex = 0;

  for id, option in ipairs(data.menuList) do
    if (option.text == L["Tracking Menu"]) then
      oldIndex = id;
      break
    end
  end

  if (not obj:IsWidget(tracking)) then
    if (oldIndex > 0) then
      table.remove(data.menuList, oldIndex);
    end

    return
  end

  if (not data.settings.widgets.tracking.hide and oldIndex > 0) then
    table.remove(data.menuList, oldIndex);
  end

  if (data.settings.widgets.tracking.hide and oldIndex == 0) then
    table.insert(
      data.menuList, 1, {
        text = L["Tracking Menu"];
        notCheckable = true;
        func = function()
          local menuFrame = GetTrackingMenuFrame();

          if (obj:IsWidget(menuFrame)) then
            local anchorName = tracking:GetName() or "MiniMapTracking";
            ToggleDropDownMenu(1, nil, menuFrame, anchorName, 0, -5);
          elseif (obj:IsFunction(tracking.Click)) then
            pcall(tracking.Click, tracking);
          elseif (obj:IsFunction(tracking.GetScript)) then
            local onMouseDown = tracking:GetScript("OnMouseDown");
            local onClick = tracking:GetScript("OnClick");

            if (obj:IsFunction(onMouseDown)) then
              pcall(onMouseDown, tracking, "LeftButton");
            elseif (obj:IsFunction(onClick)) then
              pcall(onClick, tracking, "LeftButton");
            end
          end

          PlaySound(tk.Constants.CLICK);
        end;
      });
  end
end

function C_MiniMapModule.Private:UpdateMissionsMenuOption(data)
  if (not (tk:IsRetail() and obj:IsTable(data.menuList))) then
    return;
  end

  local oldIndex = 0;

  for id, option in ipairs(data.menuList) do
    if (option.muiMissionEntry) then
      oldIndex = id;
      break
    end
  end

  local missionEntry = ResolveMissionEntry();

  if (not (obj:IsTable(missionEntry) and missionEntry.available)) then
    if (oldIndex > 0) then
      table.remove(data.menuList, oldIndex);
    end

    return;
  end

  local menuItem = (oldIndex > 0 and data.menuList[oldIndex]) or {
    muiMissionEntry = true;
    notCheckable = true;
  };

  menuItem.text = missionEntry.text;
  menuItem.func = function()
    local currentEntry = ResolveMissionEntry();

    if (not (obj:IsTable(currentEntry) and currentEntry.available and OpenMissionEntry(currentEntry))) then
      HideMenu();
    end
  end;

  if (oldIndex == 0) then
    local insertIndex = 1;

    for id, option in ipairs(data.menuList) do
      insertIndex = id;

      if (option.text == L["Calendar"]) then
        insertIndex = id + 1;
        break
      end
    end

    table.insert(data.menuList, insertIndex, menuItem);
  end
end

function C_MiniMapModule:GetRightClickMenuList()
  local menuList = obj:PopTable();

  if (tk:IsRetail() or tk:IsWrathClassic()) then
    table.insert(menuList, {
      text = L["Calendar"];
      notCheckable = true;
      func = function()
        if (not ToggleCalendar()) then
          HideMenu();
        end
      end;
    });
  end

  local function TriggerCommand(_, arg1, arg2)
    MayronUI:TriggerCommand(arg1, arg2);
    HideMenu();
  end

  table.insert(menuList, {
    text = tk.Strings:SetTextColorByTheme("MayronUI");
    notCheckable = true;
    keepShownOnClick = true;
    hasArrow = true;
    menuList = {
      {
        notCheckable = true;
        text = L["Config Menu"];
        arg1 = "config";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Install"];
        arg1 = "install";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Layouts"];
        arg1 = "layouts";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Profile Manager"];
        arg1 = "profiles";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Show Profiles"];
        arg1 = "profiles";
        arg2 = "list";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Version"];
        arg1 = "version";
        func = TriggerCommand;
      }; {
        notCheckable = true;
        text = L["Report"];
        arg1 = "report";
        func = TriggerCommand;
      };
    };
  });

  local libDbIcons = _G.LibStub("LibDBIcon-1.0", true);

  if (db.profile.minimap.hideIcons) then
    local addonMenuList = obj:PopTable();
    local knownAddOnsText = {
      ["Leatrix_Plus"] = tk.Strings:SetTextColorByHex("Leatrix Plus", "70db70");
      ["Questie"] = tk.Strings:SetTextColorByHex("Questie", "ffc50f");
      ["Hardcore"] = tk.Strings:SetTextColorByHex("Hardcore", "b0040e");
      ["Bartender4"] = tk.Strings:SetTextColorByHex("Bartender4", "ee873a");
      ["DBM"] = tk.Strings:SetTextColorByHex("Deadly Boss Mods", "ff5656");
      ["RareScannerMinimapIcon"] = tk.Strings:SetTextColorByHex(
        "Rare Scanner", "ff0f6f");
      ["Plater"] = tk.Strings:SetTextColorByHex("Plater", "e657ff");
      ["BigWigs"] = tk.Strings:SetTextColorByHex("BigWigs Bossmods", "ff5656");
      ["TradeSkillMaster"] = tk.Strings:SetTextColorByHex(
        "Trade Skill Master", "a05ff4");
      ["WeakAuras"] = tk.Strings:SetTextColorByHex("Weak Auras", "9900ff");
      ["HealBot"] = tk.Strings:SetTextColorByHex("HealBot", "3af500");
      ["AtlasLoot"] = tk.Strings:SetTextColorByHex("Atlas Loot", "f0c092");
      ["ZygorGuidesViewer"] = tk.Strings:SetTextColorByHex("Zygor Guides", "f0c34a");
    };

    local function MoveAddonIconToMenu(name)
      local iconButton = libDbIcons:GetMinimapButton(name);
      iconButton:Hide();

      local customBtn = tk:CreateFrame(
        "Button", nil, "MUI_MinimapButton_" .. name, "UIDropDownCustomMenuEntryTemplate");
      customBtn:Hide();

      customBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");

      local height = _G.UIDROPDOWNMENU_BUTTON_HEIGHT;
      customBtn:SetHeight(height);

      customBtn.icon = customBtn:CreateTexture(nil, "ARTWORK");
      customBtn.icon:SetSize(height, height);
      customBtn.icon:SetTexture(iconButton.icon:GetTexture());
      customBtn.icon:SetPoint("RIGHT", 0, 0);

      local fs = customBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      fs:SetPoint("LEFT", 4, 0);
      fs:SetText(knownAddOnsText[name] or name);
      fs:SetJustifyH("LEFT");
      customBtn:SetWidth(fs:GetUnboundedStringWidth() + height + 10);

      customBtn:SetScript("OnShow", function()
        customBtn:SetPoint("RIGHT", -14, 0);
      end);

      customBtn:SetScript("OnEnter", function()
        local list = customBtn:GetParent();
        list.showTimer = nil; -- prevents hiding tooltip after 2 seconds

        if (obj:IsWidget(_G.DropDownList3)) then
          _G.DropDownList3:Hide();
        end

        SkinMinimapMenus();

        if (obj:IsFunction(iconButton.dataObject.OnTooltipShow)) then
          GameTooltip:SetOwner(list, "ANCHOR_BOTTOM", 0, -2);
          iconButton.dataObject.OnTooltipShow(GameTooltip);
          GameTooltip:Show();

        elseif (obj:IsFunction(iconButton.dataObject.OnEnter)) then
          iconButton.dataObject.OnEnter(iconButton);
        end
      end);

      iconButton.Show = function()
        local entry = tk.Tables:First(addonMenuList, function(value)
          return value.customFrame == customBtn;
        end);

        entry.text = name;
        HideMenu();
      end

      iconButton.Hide = function()
        local entry = tk.Tables:First(addonMenuList, function(value)
          return value.customFrame == customBtn;
        end);

        entry.text = nil;
        HideMenu();
      end

      customBtn:SetScript("OnLeave", function()
        GameTooltip:Hide();

        if (obj:IsFunction(iconButton.dataObject.OnLeave)) then
          iconButton.dataObject.OnLeave(iconButton);
        end
      end);

      customBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");

      customBtn:SetScript("OnClick", function(_, buttonName)
        if (obj:IsFunction(iconButton.dataObject.OnClick)) then
          iconButton.dataObject.OnClick(iconButton, buttonName);
        end

        HideMenu();
      end);

      table.insert(addonMenuList, { text = name; customFrame = customBtn });
    end

    local function AddAddonCompartmentEntry(name, text, texturePath, onClick, onEnter, onLeave)
      if (tk.Tables:First(addonMenuList, function(entry)
        return entry.value == name;
      end)) then
        return;
      end

      local customBtn = tk:CreateFrame(
        "Button", nil, "MUI_MinimapButton_" .. name, "UIDropDownCustomMenuEntryTemplate");
      customBtn:Hide();

      customBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");

      local height = _G.UIDROPDOWNMENU_BUTTON_HEIGHT;
      customBtn:SetHeight(height);

      customBtn.icon = customBtn:CreateTexture(nil, "ARTWORK");
      customBtn.icon:SetSize(height, height);
      customBtn.icon:SetTexture(texturePath);
      customBtn.icon:SetPoint("RIGHT", 0, 0);

      local fs = customBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      fs:SetPoint("LEFT", 4, 0);
      fs:SetText(text or knownAddOnsText[name] or name);
      fs:SetJustifyH("LEFT");
      customBtn:SetWidth(fs:GetUnboundedStringWidth() + height + 10);

      customBtn:SetScript("OnShow", function()
        customBtn:SetPoint("RIGHT", -14, 0);
      end);

      customBtn:SetScript("OnEnter", function()
        local list = customBtn:GetParent();
        list.showTimer = nil;

        if (obj:IsWidget(_G.DropDownList3)) then
          _G.DropDownList3:Hide();
        end

        SkinMinimapMenus();

        if (obj:IsFunction(onEnter)) then
          onEnter(name, customBtn);
        end
      end);

      customBtn:SetScript("OnLeave", function()
        GameTooltip:Hide();

        if (obj:IsFunction(onLeave)) then
          onLeave(name, customBtn);
        end
      end);

      customBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");

      customBtn:SetScript("OnClick", function(_, buttonName)
        if (obj:IsFunction(onClick)) then
          local normalizedButtonName = buttonName and buttonName:gsub("Up$", "") or buttonName;
          onClick(name, normalizedButtonName, customBtn);
        end

        HideMenu();
      end);

      table.insert(addonMenuList, {
        text = name;
        value = name;
        customFrame = customBtn;
      });
    end

    if (obj:IsTable(libDbIcons)) then
      for _, iconName in ipairs(libDbIcons:GetButtonList()) do
        MoveAddonIconToMenu(iconName);
      end
    end

    if (_G.C_AddOns and _G.C_AddOns.IsAddOnLoaded("ZygorGuidesViewer")
      and obj:IsFunction(_G.ZygorGuidesViewer_OnAddonCompartmentClick))
    then
      if (obj:IsWidget(_G.ZygorGuidesViewerMapIcon)) then
        _G.ZygorGuidesViewerMapIcon:Hide();
      end

      AddAddonCompartmentEntry(
        "ZygorGuidesViewer",
        knownAddOnsText["ZygorGuidesViewer"],
        "Interface\\AddOns\\ZygorGuidesViewer\\Skins\\addon-icon",
        _G.ZygorGuidesViewer_OnAddonCompartmentClick,
        _G.ZygorGuidesViewer_OnAddonCompartmentEnter,
        _G.ZygorGuidesViewer_OnAddonCompartmentLeave
      );
    end

    if (#addonMenuList > 0) then
      table.insert(menuList, {
        text = "AddOns";
        notCheckable = true;
        keepShownOnClick = true;
        hasArrow = true;
        menuList = addonMenuList;
      });
    end

    if (obj:IsTable(libDbIcons) and obj:IsFunction(libDbIcons.RegisterCallback)) then
      libDbIcons.RegisterCallback(addOnName, "LibDBIcon_IconCreated",
        function(_, _, iconName)
          MoveAddonIconToMenu(iconName);
        end);
    end
  end

  return menuList;
end

function C_MiniMapModule:OnInitialize(data)
  if (db.profile.minimap.testMode) then
    db.profile.minimap.testMode = false;
  end

  if (not obj:IsTable(db.profile.minimap.widgets)) then
    db.profile.minimap.widgets = {};
  end

  if (not obj:IsTable(db.profile.minimap.widgets.zone)) then
    db.profile.minimap.widgets.zone = {};
  end

  if (not obj:IsString(db.profile.minimap.widgets.zone.point)
      or (db.profile.minimap.widgets.zone.point ~= "TOP"
        and db.profile.minimap.widgets.zone.point ~= "BOTTOM")) then
    db.profile.minimap.widgets.zone.point = "TOP";
  end

  if (not obj:IsNumber(db.profile.minimap.widgets.zone.x)) then
    db.profile.minimap.widgets.zone.x = 0;
  end

  if (not obj:IsNumber(db.profile.minimap.widgets.zone.y)) then
    db.profile.minimap.widgets.zone.y = -4;
  end

  self:RegisterUpdateFunctions(
    db.profile.minimap, {
      size = function(value)
        Minimap:SetSize(value, value);
        Minimap_ZoomIn();
        Minimap_ZoomOut();
      end;

      showPointsOfInterest = function(value)
        if (obj:IsFunction(Minimap.SetStaticPOIArrowTexture)) then
          local arrowTexture = "";

          if (value) then
            arrowTexture = tk:GetAssetFilePath("Textures\\MinimapStaticArrow");
          end

          Minimap:SetStaticPOIArrowTexture(arrowTexture);
        end
      end;

      scale = function(value)
        Minimap:SetScale(value);
      end;

      hideIcons = function(value)
        SetAddonIconsShown(not value);
        data.menuList = self:GetRightClickMenuList();
        data:Call("UpdateTrackingMenuOptionVisibility");
        data:Call("UpdateMissionsMenuOption");
      end;

      widgets = function()
        data:Call("SetUpWidgets");
        data:Call("UpdateTrackingMenuOptionVisibility");
        data:Call("UpdateMissionsMenuOption");
      end;

      resetZoom = function()
      end;

      testMode = function()
        data:Call("SetUpWidgets");
      end;
    }, { onExecuteAll = { ignore = { "widgets" } } });
end

function C_MiniMapModule:OnInitialized(data)
  if (data.settings.enabled) then
    self:SetEnabled(true);
  end
end

function C_MiniMapModule:OnEnable(data)
  local function EnsureMinimapContainer()
    if (not obj:IsWidget(data.container)) then
      data.container = tk:CreateBackdropFrame("Frame", _G.UIParent, "MUI_MinimapContainer");
      data.container:SetFrameStrata("LOW");
    end

    data.container:SetBackdrop({
      edgeFile = tk:GetAssetFilePath("Borders\\Solid.tga");
      edgeSize = 1;
    });
    data.container:SetBackdropBorderColor(0, 0, 0, 1);
    data.container:SetBackdropColor(0, 0, 0, 0);

    data.container:SetFrameLevel(math.max(Minimap:GetFrameLevel() - 1, 1));
    data.container:ClearAllPoints();
    data.container:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, 2);
    data.container:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, -2);
    data.container:Show();
  end

  local function ReApplyMUISkin()
    if (not obj:IsWidget(Minimap)) then
      return;
    end

    Minimap:SetBackdrop({
      edgeFile = tk:GetAssetFilePath("Borders\\Solid.tga");
      edgeSize = 1;
    });
    Minimap:SetBackdropBorderColor(0, 0, 0, 1);
    Minimap:SetBackdropColor(0, 0, 0, 0);
    ApplyDefaultMinimapFrameStyle(data);

    if (obj:IsWidget(_G.MinimapBackdrop)) then
      _G.MinimapBackdrop:SetAlpha(0);
      _G.MinimapBackdrop:Hide();
    end

    if (obj:IsWidget(_G.MinimapCluster) and obj:IsWidget(_G.MinimapCluster.BorderTop)) then
      _G.MinimapCluster.BorderTop:Hide();
    end
  end

  if (obj:IsWidget(_G.MinimapBorder)) then
    tk:KillElement(_G.MinimapBorder);
    tk:KillElement(_G.MinimapBorderTop);
    tk:KillElement(_G.MinimapZoomIn);
    tk:KillElement(_G.MinimapZoomOut);
    tk:KillElement(_G.MinimapNorthTag);
  end

  if (tk:IsRetail() and obj:IsWidget(_G.MinimapCluster) and obj:IsWidget(_G.MinimapCluster.BorderTop)) then
    _G.MinimapCluster.BorderTop:Hide();
    tk:KillElement(_G.MinimapCompassTexture);
    tk:KillElement(_G.Minimap.ZoomIn);
    tk:KillElement(_G.Minimap.ZoomOut);
    tk:KillElement(_G.MinimapCluster.BorderTop);
  end

  tk:KillElement(_G.MiniMapWorldMapButton);

  if (_G.MinimapToggleButton) then
    tk:KillElement(_G.MinimapToggleButton);
  end

  if (_G.BackdropTemplateMixin) then
    _G.Mixin(Minimap, _G.BackdropTemplateMixin);
    Minimap:OnBackdropLoaded();
    Minimap:SetScript("OnSizeChanged", Minimap.OnBackdropSizeChanged);
  end

  if (not obj:IsWidget(Minimap.size)) then
    Minimap.size = Minimap:CreateFontString(nil, "ARTWORK");
    Minimap.size:SetFontObject("GameFontNormalLarge");
  end

  Minimap.size:ClearAllPoints();
  Minimap.size:SetPoint("TOP", Minimap, "BOTTOM", 0, 40);

  Minimap:ClearAllPoints();
  Minimap:SetPoint(data.settings.point, _G.UIParent, 
    data.settings.relativePoint, data.settings.x, data.settings.y);

  if (obj:IsWidget(_G.MinimapCluster) and obj:IsFunction(_G.MinimapCluster.EnableMouse)) then
    _G.MinimapCluster:EnableMouse(false);
  end

  Minimap:EnableMouse(true);
  Minimap:EnableMouseWheel(true);
  Minimap:SetResizable(true);
  Minimap:SetMovable(true);
  Minimap:SetUserPlaced(true);
  Minimap:RegisterForDrag("LeftButton");

  if (obj:IsFunction(Minimap.SetMinResize)) then
    Minimap:SetMinResize(120, 120);
    Minimap:SetMaxResize(400, 400);
  else
    -- dragonflight:
    Minimap:SetResizeBounds(120, 120, 400, 400);
  end

  Minimap:SetClampedToScreen(true);
  Minimap:SetClampRectInsets(-3, 3, 3, -3);

  if (tk:IsRetail()) then
    if (obj:IsFunction(Minimap.SetArchBlobRingScalar)) then
      Minimap:SetArchBlobRingScalar(0);
    end

    if (obj:IsFunction(Minimap.SetQuestBlobRingScalar)) then
      Minimap:SetQuestBlobRingScalar(0);
    end
  end

  Minimap:SetBackdrop({
    edgeFile = tk:GetAssetFilePath("Borders\\Solid.tga");
    edgeSize = 1;
  });

  Minimap:SetBackdropBorderColor(0, 0, 0, 1);
  Minimap:SetBackdropColor(0, 0, 0, 0);
  ApplyDefaultMinimapFrameStyle(data);

  Minimap:SetScript("OnMouseWheel", function(_, value)
      local zoomIn = _G.MinimapZoomIn or (obj:IsWidget(_G.Minimap) and _G.Minimap.ZoomIn);
      local zoomOut = _G.MinimapZoomOut or (obj:IsWidget(_G.Minimap) and _G.Minimap.ZoomOut);

      if (value > 0 and obj:IsWidget(zoomIn) and obj:IsFunction(zoomIn.Click)) then
        zoomIn:Click();
      elseif (value < 0 and obj:IsWidget(zoomOut) and obj:IsFunction(zoomOut.Click)) then
        zoomOut:Click();
      end

      if (data.settings.resetZoom and data.settings.resetZoom.enabled) then
        data.zoomResetToken = (data.zoomResetToken or 0) + 1;
        local token = data.zoomResetToken;
        local delay = tonumber(data.settings.resetZoom.time) or 5;

        C_Timer.After(delay, function()
          if (data.zoomResetToken ~= token) then
            return;
          end

          if (obj:IsFunction(Minimap.GetZoom) and obj:IsFunction(Minimap.SetZoom)) then
            local ok, zoom = pcall(Minimap.GetZoom, Minimap);

            if (ok and obj:IsNumber(zoom) and zoom > 0) then
              pcall(Minimap.SetZoom, Minimap, 0);
            end
          end
        end);
      end
    end);

  Minimap:SetScript("OnDragStart", Minimap_OnDragStart);
  Minimap:SetScript("OnDragStop", function()
    Minimap_OnDragStop(data)
  end);

  if (not data.minimapHooksInstalled) then
    Minimap:HookScript("OnEnter", function(self)
      if (data.settings.Tooltip) then
        -- helper tooltip (can be hidden)
        return
      end

      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -2)
      GameTooltip:SetText("MUI MiniMap"); -- This sets the top line of text, in gold.
      GameTooltip:AddDoubleLine(L["CTRL + Drag:"], L["Move Minimap"], 1, 1, 1);
      GameTooltip:AddDoubleLine(
        L["SHIFT + Drag:"], L["Resize Minimap"], 1, 1, 1);
      GameTooltip:AddDoubleLine(L["Left Click:"], L["Ping Minimap"], 1, 1, 1);
      GameTooltip:AddDoubleLine(L["Right Click:"], L["Show Menu"], 1, 1, 1);
      GameTooltip:AddDoubleLine(L["Mouse Wheel:"], L["Zoom in/out"], 1, 1, 1);
      GameTooltip:AddDoubleLine(
        L["ALT + Left Click:"], L["Toggle this Tooltip"], 1, 0, 0, 1, 0, 0);
      GameTooltip:Show();
    end);

    Minimap:HookScript("OnMouseDown", function(_, button)
      if ((IsAltKeyDown()) and (button == "LeftButton")) then
        local tracker = data.settings:GetTrackedTable();

        if (tracker.Tooltip) then
          tracker.Tooltip = nil;
          Minimap:GetScript("OnEnter")(Minimap);
        else
          tracker.Tooltip = true;
          GameTooltip:Hide();
        end

        tracker:SaveChanges();
      end
    end);

    data.minimapHooksInstalled = true;
  end

  if (tk:IsRetail() or tk:IsWrathClassic()) then
    local eventBtn = data.eventButton;

    if (not obj:IsWidget(eventBtn)) then
      eventBtn = tk:CreateFrame("Button", Minimap);
      data.eventButton = eventBtn;
      eventBtn:SetNormalFontObject("GameFontNormal");
      eventBtn:SetHighlightFontObject("GameFontHighlight");

      eventBtn:SetScript("OnClick", function()
        ToggleCalendar();
      end);

      eventBtn:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES");
      eventBtn:RegisterEvent("CALENDAR_ACTION_PENDING");
      eventBtn:RegisterEvent("PLAYER_ENTERING_WORLD");
      eventBtn:SetScript("OnEvent", function(self)
        local numPendingInvites = GetPendingCalendarInvites();

        if (numPendingInvites > 0) then
          self:SetText(strformat("%s (%i)", L["New Event!"], numPendingInvites));
          self:Show();
        else
          self:SetText("");
          self:Hide();
        end
      end);
    end

    eventBtn:SetParent(Minimap);
    eventBtn:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -18);
    eventBtn:SetSize(100, 20);
    eventBtn:Hide();
  end

  -- Drop down List:
  data.menuList = self:GetRightClickMenuList();
  data:Call("UpdateTrackingMenuOptionVisibility");
  data:Call("UpdateMissionsMenuOption");

  local menuFrame = data.menuFrame;

  if (not obj:IsWidget(menuFrame)) then
    menuFrame = tk:CreateFrame("Frame", nil, "MinimapRightClickMenu", "UIDropDownMenuTemplate");
    data.menuFrame = menuFrame;
  end

  if (not data.minimapMouseUpHookInstalled) then
    Minimap:HookScript("OnMouseUp", function(self, btn)
      if (btn == "RightButton") then
        HideMenu();

        if (ShowDropDownMenu(data.menuList, menuFrame)) then
          SkinMinimapMenus();
          C_Timer.After(0, SkinMinimapMenus);
          PlaySound(tk.Constants.CLICK);
        end
      else
        HideMenu();
      end
    end);

    data.minimapMouseUpHookInstalled = true;
  end

  EnsureMinimapContainer();
  ReApplyMUISkin();
  SetAddonIconsShown(not data.settings.hideIcons);

  -- Ensure widget re-parenting/skinning runs on first enable as well.
  data:Call("SetUpWidgets");
  data:Call("UpdateMissionsMenuOption");
  C_Timer.After(0.05, function()
    EnsureMinimapContainer();
    ReApplyMUISkin();
    SetAddonIconsShown(not data.settings.hideIcons);
    data:Call("SetUpWidgets");
    data:Call("UpdateMissionsMenuOption");
  end);

  C_Timer.After(1, function()
    SetAddonIconsShown(not data.settings.hideIcons);
    data:Call("UpdateMissionsMenuOption");
  end);
  C_Timer.After(5, function()
    SetAddonIconsShown(not data.settings.hideIcons);
    data:Call("UpdateMissionsMenuOption");
  end);

  if (tk:IsRetail()) then
    local missionsListener = data.missionsListener or em:GetEventListenerByID("MUI_MiniMap_Missions_Refresh");

    if (not missionsListener) then
      missionsListener = em:CreateEventListenerWithID("MUI_MiniMap_Missions_Refresh",
        function(_, _, loadedAddon)
          if (loadedAddon and loadedAddon ~= "Blizzard_GarrisonUI"
              and loadedAddon ~= "Blizzard_ExpansionLandingPage") then
            return;
          end

          data:Call("SetUpWidgets");
          data:Call("UpdateMissionsMenuOption");
        end);
    else
      missionsListener:SetEnabled(true);
    end

    missionsListener:RegisterEvents("PLAYER_ENTERING_WORLD", "GARRISON_UPDATE", "ADDON_LOADED");
    data.missionsListener = missionsListener;
  end

  Minimap:Show();
end
