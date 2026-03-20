-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local C_MiniMapModule = MayronUI:GetModuleClass("MiniMap");
local widgets = {};
local function IsWidgetOptionEnabled(settings)
  if (type(settings) ~= "table") then
    return true;
  end

  if (settings.show ~= nil) then
    return settings.show;
  end

  if (settings.hide ~= nil) then
    return not settings.hide;
  end

  return true;
end

local function UpdateTestModeButton(button)
  local r, g, b = tk:GetThemeColor();

  if (db.profile.minimap.testMode) then
    button:SetText(L["Disable Test Mode"]);
    button:GetNormalTexture():SetVertexColor(r * 1.2, g * 1.2, b * 1.2);
  else
    button:SetText(L["Enable Test Mode"]);
    button:GetNormalTexture():SetVertexColor(r * 0.5, g * 0.5, b * 0.5);
  end
end

local function RefreshTestModeWidgets()
  if (not db.profile.minimap.testMode) then
    return;
  end

  local button = widgets.testModeButton;

  if (obj:IsWidget(button) and obj:IsFunction(button.GetScript)) then
    local onClick = button:GetScript("OnClick");

    if (obj:IsFunction(onClick)) then
      onClick(button);
    end
  end
end

local function AddShowOption(children, name, text)
  children[#children + 1] = {
    name = tk.Strings:JoinWithSpace(L["Show"], text);
    type = "check";
    dbPath = "show";
    height = 50;

    SetValue = function(self, value)
      if (widgets[name] and widgets[name].point) then
        widgets[name].point:SetEnabled(value);
      end

      if (widgets[name] and widgets[name].x) then
        widgets[name].x:SetEnabled(value);
      end

      if (widgets[name] and widgets[name].y) then
        widgets[name].y:SetEnabled(value);
      end

      if (widgets[name] and widgets[name].fontSize) then
        widgets[name].fontSize:SetEnabled(value);
      end

      if (widgets[name] and widgets[name].scale) then
        widgets[name].scale:SetEnabled(value);
      end

      RefreshTestModeWidgets();

      db:SetPathValue(self.dbPath, value);
    end;
  };
end

local function AddHideOption(children, name, text, func)
  children[#children + 1] = {
    name = tk.Strings:JoinWithSpace(L["Hide"], text);
    type = "check";
    dbPath = "hide";
    height = 50;

    SetValue = function(self, value)
      if (widgets[name] and widgets[name].point) then
        widgets[name].point:SetEnabled(not value);
      end

      if (widgets[name] and widgets[name].x) then
        widgets[name].x:SetEnabled(not value);
      end

      if (widgets[name] and widgets[name].y) then
        widgets[name].y:SetEnabled(not value);
      end

      if (widgets[name] and widgets[name].fontSize) then
        widgets[name].fontSize:SetEnabled(not value);
      end

      if (widgets[name] and widgets[name].scale) then
        widgets[name].scale:SetEnabled(not value);
      end

      RefreshTestModeWidgets();

      db:SetPathValue(self.dbPath, value);
      if (func) then func(); end
    end;
  };
end

local function AddFontSizeOption(children, name, settings)
  children[#children + 1] = {
    name = L["Font Size"];
    type = "slider";
    valueType = "number";
    min = 8;
    step = 1;
    max = 24;
    dbPath = "fontSize";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].fontSize = container.component;
    end;
  };
end

local function AddScaleOption(children, name, settings)
  children[#children + 1] = {
    name = L["Scale"];
    type = "slider";
    valueType = "number";
    min = 0.2;
    step = 0.1;
    max = 2;
    dbPath = "scale";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].scale = container.component;
    end;
  }
end

local function AddPositioningOptions(children, name, settings, pointOptions)
  widgets[name] = obj:PopTable();

  children[#children + 1] = {
    type = "fontstring";
    subtype = "header";
    content = L["Icon Position"];
  };

  children[#children + 1] = {
    name = L["Point"];
    type = "dropdown";
    options = pointOptions or tk.Constants.POINT_OPTIONS;
    width = 320;
    inline = true;
    dbPath = "point";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].point = container.component;
    end;
  };

  children[#children + 1] = {
    name        = L["X-Offset"];
    type        = "slider";
    dbPath = "x";
    min = -50;
    max = 50;
    step = 1;
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].x = container.component;
    end;
  };

  children[#children + 1] = {
    name        = L["Y-Offset"];
    type        = "slider";
    min = -50;
    max = 50;
    step = 1;
    dbPath      = "y";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].y = container.component;
    end;
  }
end

local function AddCenteredPositioningOptions(children, name, settings, pointOptions)
  widgets[name] = obj:PopTable();

  children[#children + 1] = {
    type = "fontstring";
    subtype = "header";
    content = L["Icon Position"];
  };

  children[#children + 1] = {
    name = L["Point"];
    type = "dropdown";
    options = pointOptions;
    width = 320;
    inline = true;
    dbPath = "point";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].point = container.component;
    end;
  };

  children[#children + 1] = {
    name        = L["X-Offset"];
    type        = "slider";
    min = -50;
    max = 50;
    step = 1;
    dbPath      = "x";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].x = container.component;
    end;
  };

  children[#children + 1] = {
    name        = L["Y-Offset"];
    type        = "slider";
    min = -50;
    max = 50;
    step = 1;
    dbPath      = "y";
    enabled = IsWidgetOptionEnabled(settings);
    OnLoad = function(_, container)
      widgets[name].y = container.component;
    end;
  }
end

function C_MiniMapModule:GetConfigTable(data)
  return {
    type = "menu",
    module = "MiniMap",
    featurePath = "minimap.enabled",
    dbPath = "profile.minimap",
    tabs = {
      L["General"];
      L["Text Widgets"];
      L["Icons"];
    };
    children = {
      {
        {
          name = L["General"];
          type = "title";
          marginTop = 0;
        };
        {
          type = "fontstring";
          content = L["These settings control the Minimap itself and its global behavior."];
        };
        {
          name = L["Enabled"];
          tooltip = L["If checked, this module will be enabled."];
          type = "check";
          requiresReload = true;
          dbPath = "enabled";
        };
        {
          name = L["Move AddOn Buttons"];
          tooltip = L["MOVE_ADDON_BUTTONS_TOOLTIP"];
          type = "check";
          dbPath = "hideIcons";
        };
        {
          name = L["Points of Interest"];
          tooltip = L["If checked, the points of interest arrows will be shown."];
          type = "check";
          dbPath = "showPointsOfInterest";
          client = "not retail";
        };
        { type = "divider" };
        {
          name = L["Size"];
          type = "slider";
          valueType = "number";
          min = 120;
          max = 400;
          tooltip = L["Adjust the size of the minimap."];
          dbPath = "size";
        };
        {
          name = L["Scale"];
          type = "slider";
          valueType = "number";
          min = 0.5;
          step = 0.1;
          max = 3;
          tooltip = L["Adjust the scale of the minimap."];
          dbPath = "scale";
        };
        {
          name = L["Reset Zoom"];
          type = "check";
          dbPath = "resetZoom.enabled";
          SetValue = function(self, value)
            db:SetPathValue(self.dbPath, value);

            if (widgets.resetZoomTime) then
              widgets.resetZoomTime:SetEnabled(value);
            end
          end;
        };
        {
          name = L["Reset Zoom Delay"];
          type = "slider";
          valueType = "number";
          min = 1;
          max = 15;
          step = 1;
          dbPath = "resetZoom.time";
          enabled = db.profile.minimap.resetZoom.enabled;
          OnLoad = function(_, container)
            widgets.resetZoomTime = container.component;
          end;
        };
        {
          name = L["Enable Test Mode"];
          type = "button";
          tooltip = L["Test mode allows you to easily customize the looks and positioning of widgets by forcing all widgets to be shown."];
          OnLoad = function(_, button)
            widgets.testModeButton = button;
            UpdateTestModeButton(button);
          end;
          OnClick = function(button)
            local testMode = not db.profile.minimap.testMode;

            if (not testMode) then
              data.testModeActive = false;
            end

            db.profile.minimap.testMode = testMode;

            if (testMode) then
              data.testModeActive = true;
            else
              obj:PushTable(data.isShown);
            end

            UpdateTestModeButton(button);
          end;
        };
      };
      {
        {
          name = L["Text Widgets"];
          type = "title";
          marginTop = 0;
        };
        {
          type = "fontstring";
          content = L["These options control text shown around the Minimap."];
        };
        {
          name = L["Clock"];
          type = "submenu";
          dbPath = "widgets.clock";
          children = function()
            local children = {};
            AddHideOption(children, "clock", L["Clock"]);
            AddFontSizeOption(children, "clock", data.settings.widgets.clock);
            AddPositioningOptions(children, "clock", data.settings.widgets.clock);
            return children;
          end
        };
        {
          name = L["Dungeon Difficulty"];
          dbPath = "widgets.difficulty";
          type = "submenu";
          client = "retail,wrath";
          children = function()
            local children = {};
            AddShowOption(children, "difficulty", L["Dungeon Difficulty"]);
            AddFontSizeOption(children, "difficulty", data.settings.widgets.difficulty);
            AddPositioningOptions(children, "difficulty", data.settings.widgets.difficulty);
            return children;
          end
        };
        {
          name = L["Zone Name"];
          type = "submenu";
          dbPath = "widgets.zone";
          children = function()
            local children = {};
            local zonePointOptions = {
              [L["Top"]] = "TOP";
              [L["Bottom"]] = "BOTTOM";
            };
            AddHideOption(children, "zone", L["Zone Name"]);
            AddFontSizeOption(children, "zone", data.settings.widgets.zone);
            AddCenteredPositioningOptions(children, "zone", data.settings.widgets.zone, zonePointOptions);
            return children;
          end
        };
      };
      {
        {
          name = L["Icons"];
          type = "title";
          marginTop = 0;
        };
        {
          type = "fontstring";
          content = L["These options control the icons attached to the Minimap."];
        };
        {
          name = L["Looking For Group Icon"];
          type = "submenu";
          dbPath = "widgets.lfg";
          client = "wrath,bcc";
          children = function()
            local children = {};
            AddScaleOption(children, "lfg", data.settings.widgets.lfg);
            AddPositioningOptions(children, "lfg", data.settings.widgets.lfg);
            return children;
          end
        };
        {
          name = L["Calendar Icon"];
          type = "submenu";
          dbPath = "widgets.calendar";
          client = "retail,wrath";
          children = function()
            local children = {};
            AddHideOption(children, "calendar", L["Calendar Icon"]);
            AddScaleOption(children, "calendar", data.settings.widgets.calendar);
            AddPositioningOptions(children, "calendar", data.settings.widgets.calendar);
            return children;
          end
        };
        {
          name = L["New Mail Icon"];
          type = "submenu";
          dbPath = "widgets.mail";
          children = function()
            local children = {};
            AddScaleOption(children, "mail", data.settings.widgets.mail);
            AddPositioningOptions(children, "mail", data.settings.widgets.mail);
            return children;
          end
        };
        {
          name = L["Battlefield Icon"];
          type = "submenu";
          dbPath = "widgets.battlefield";
          children = function()
            local children = {};
            AddHideOption(children, "battlefield", L["Battlefield Icon"]);
            AddScaleOption(children, "battlefield", data.settings.widgets.battlefield);
            AddPositioningOptions(children, "battlefield", data.settings.widgets.battlefield);
            return children;
          end
        };
        {
          name = L["Missions Icon"];
          type = "submenu";
          dbPath = "widgets.missions";
          client = "retail";
          children = function()
            local children = {
              {
                type = "fontstring";
                content = L["This button opens the most relevant expansion feature or mission interface available for your character on Retail."];
              };
            };

            AddHideOption(children, "missions", L["Missions Icon"]);
            AddScaleOption(children, "missions", data.settings.widgets.missions);
            AddPositioningOptions(children, "missions", data.settings.widgets.missions);

            return children;
          end
        };
        {
          name = L["Tracking Icon"];
          type = "submenu";
          dbPath = "widgets.tracking";
          children = function()
            local children = {
              {
                type = "fontstring";
                content = L["When hidden, you can still access tracking options from the Minimap right-click menu."];
              };
            };

            AddHideOption(children, "tracking", L["Tracking Icon"], function()
              data:Call("UpdateTrackingMenuOptionVisibility");
            end);
            AddScaleOption(children, "tracking", data.settings.widgets.tracking);
            AddPositioningOptions(children, "tracking", data.settings.widgets.tracking);

            return children;
          end
        };
      };
    };
  };
end
