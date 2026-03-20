-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local C_CastBarsModule = MayronUI:GetModuleClass("CastBarsModule");

local position_TextFields = obj:PopTable();
local sufAnchor_CheckButtons = obj:PopTable();
local width_TextFields = obj:PopTable();
local height_TextFields = obj:PopTable();

local tostring, string, ipairs = _G.tostring, _G.string, _G.ipairs;
local tonumber, tinsert = _G.tonumber, _G.table.insert;
local CAST_BAR_NAMES = {"Player", "Target", "Focus", "Mirror", "Pet", "Power"};
local DEFAULT_CAST_BAR_LAYOUTS = {
  Player = {
    anchorToSUF = true;
    position = {"CENTER", "UIParent", "CENTER", 0, 0};
  };
  Target = {
    anchorToSUF = true;
    position = {"CENTER", "UIParent", "CENTER", 0, 0};
  };
  Focus = {
    anchorToSUF = false;
    position = {"CENTER", "UIParent", "CENTER", 0, 0};
  };
  Pet = {
    anchorToSUF = false;
    position = {"BOTTOM", "UIParent", "BOTTOM", 0, 400};
  };
  Mirror = {
    anchorToSUF = false;
    position = {"TOP", "UIParent", "TOP", 0, -200};
  };
  Power = {
    anchorToSUF = false;
    position = {"TOP", "UIParent", "TOP", 0, -300};
  };
};

local function SetPositionTextFieldsEnabled(enabled, castBarName)
  for _, textfield in ipairs(position_TextFields[castBarName]) do
    textfield:SetEnabled(enabled);
  end

  for _, textfield in ipairs(width_TextFields[castBarName]) do
    textfield:SetEnabled(enabled);
  end

  for _, textfield in ipairs(height_TextFields[castBarName]) do
    textfield:SetEnabled(enabled);
  end
end

local function UnlockCastBar(widget, castBarName)
  local name = castBarName:gsub("^%l", string.upper);
  local castbar = _G[tk.Strings:Concat("MUI_", name, "CastBar")];

  if (not castbar) then -- might be disabled
    return
  end

  castbar.unlocked = not castbar.unlocked;

  if (not castbar) then
    tk:Print(name..L[" CastBar not enabled."]);
    return
  end

  tk:MakeMovable(castbar, nil, castbar.unlocked);

  if (not castbar.moveIndicator) then
    castbar.moveIndicator = castbar.statusbar:CreateTexture(nil, "OVERLAY");
    castbar.moveIndicator:SetColorTexture(0, 0, 0, 0.6);
    tk:ApplyThemeColor(0.6, castbar.moveIndicator);
    castbar.moveIndicator:SetAllPoints(true);
    castbar.moveLabel = castbar.statusbar:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    castbar.moveLabel:SetText(tk.Strings:Concat("<", name, " CastBar>"));
    castbar.moveLabel:SetPoint("CENTER", castbar.moveIndicator, "CENTER");
  end

  if (castbar.unlocked) then
    widget:SetText(L["Lock"]);
    castbar.moveIndicator:Show();
    castbar.moveLabel:Show();
    castbar:SetAlpha(1);
    castbar.name:SetText(tk.Strings.Empty);
    castbar.duration:SetText(tk.Strings.Empty);
    castbar.statusbar:SetStatusBarColor(0, 0, 0, 0);
  else
    widget:SetText(L["Unlock"]);
    castbar.moveIndicator:Hide();
    castbar.moveLabel:Hide();
    castbar:SetAlpha(0);

    local positions = tk.Tables:GetFramePosition(castbar);

    if (positions) then
      for index, positionWidget in ipairs(position_TextFields[castBarName]) do
        if (positionWidget:GetObjectType() == "TextField") then
          positionWidget:SetText(tostring(positions[index]));
        elseif (positionWidget:GetObjectType() == "Slider") then
          positionWidget.editBox:SetText(positions[index]);
        end
      end

      SetPositionTextFieldsEnabled(true, castBarName);

      if (sufAnchor_CheckButtons[castBarName]) then
        sufAnchor_CheckButtons[castBarName]:SetChecked(false);
        db:SetPathValue(tk.Strings:Join(".", "profile.castBars", castBarName, "anchorToSUF"), false);
      end

      db:SetPathValue(tk.Strings:Join(".", "profile.castBars", castBarName, "position"), positions);
    end
  end
end

local function ResetCastBarPosition(_, castBarName)
  local defaults = DEFAULT_CAST_BAR_LAYOUTS[castBarName];

  if (not defaults) then
    return;
  end

  local defaultPosition = {
    defaults.position[1];
    defaults.position[2];
    defaults.position[3];
    defaults.position[4];
    defaults.position[5];
  };

  local anchorPath = tk.Strings:Join(".", "profile.castBars", castBarName, "anchorToSUF");
  local positionPath = tk.Strings:Join(".", "profile.castBars", castBarName, "position");

  db:SetPathValue(anchorPath, defaults.anchorToSUF);
  db:SetPathValue(positionPath, defaultPosition);

  if (sufAnchor_CheckButtons[castBarName]) then
    sufAnchor_CheckButtons[castBarName]:SetChecked(defaults.anchorToSUF);
  end

  SetPositionTextFieldsEnabled(not defaults.anchorToSUF, castBarName);

  for index, positionWidget in ipairs(position_TextFields[castBarName] or tk.Constants.EMPTY_TABLE) do
    local value = defaultPosition[index];

    if (positionWidget:GetObjectType() == "TextField") then
      positionWidget:SetText(tostring(value));
    elseif (positionWidget:GetObjectType() == "Slider") then
      positionWidget.editBox:SetText(value);
    end
  end
end

local function AnyCastBarUnlocked()
  for _, barName in ipairs(CAST_BAR_NAMES) do
    local castbar = _G[tk.Strings:Concat("MUI_", barName, "CastBar")];

    if (castbar and castbar.unlocked) then
      return true;
    end
  end

  return false;
end

local function ToggleAllCastBarsTestMode(widget)
  local enable = not AnyCastBarUnlocked();

  for _, barName in ipairs({"player", "target", "focus", "mirror", "pet", "power"}) do
    local frameName = tk.Strings:Concat("MUI_", barName:gsub("^%l", string.upper), "CastBar");
    local castbar = _G[frameName];

    if (castbar and castbar.enabled and castbar.unlocked ~= enable) then
      UnlockCastBar(widget, barName);
    end
  end

  widget:SetText(enable and L["Disable Test Mode"] or L["Enable Test Mode"]);
end

local function SupportsCastBarName(barName)
  if (tk:IsClassic() and barName == "Focus") then
    return false;
  end

  if (not tk:IsRetail() and barName == "Power") then
    return false;
  end

  return true;
end

local function GetGlobalCastBarSetting(attribute)
  for _, barName in ipairs(CAST_BAR_NAMES) do
    if (SupportsCastBarName(barName)) then
      return db.profile.castBars[barName][attribute];
    end
  end

  return false;
end

local function SetGlobalCastBarSetting(attribute, value)
  for _, barName in ipairs(CAST_BAR_NAMES) do
    if (SupportsCastBarName(barName) and db.profile.castBars[barName]) then
      db:SetPathValue(tk.Strings:Join(".", "profile.castBars", barName, attribute), value);
    end
  end
end

local function CastBarPosition_OnLoad(config, container)
    local positionIndex = config.dbPath:match("%[(%d)%]$");
    position_TextFields[config.castBarName][tonumber(positionIndex)] = container.component;

    if (db.profile.castBars[config.castBarName].anchorToSUF) then
      container.component:SetEnabled(false);
    end
end

function C_CastBarsModule:GetConfigTable()
    return {
        tabs = {
          L["General"];
          L["Appearance"];
          L["Individual Cast Bar Options"];
        };
        module = "CastBarsModule",
        featurePath = "castBars.enabled",
        children = {
          {
            {
              name = L["General"],
              type = "title",
              marginTop = 0;
            },
            {
              type = "fontstring";
              content = L["These settings control the cast bar module itself and shared behavior."];
            },
            {   name = L["Enabled"],
                tooltip = L["If checked, this module will be enabled."],
                type = "check",
                requiresReload = true,
                dbPath = "profile.castBars.enabled",
            },
            {   name = L["Show Food and Drink"],
                tooltip = L["If checked, the food and drink buff will be displayed as a castbar."],
                type = "check",
                requiresReload = true,
                dbPath = "global.castBars.showFoodDrink",
            },
            {   name = L["Hide Blizzard Cast Bars"],
                tooltip = L["If checked, the default Blizzard cast bars will be hidden while MayronUI cast bars are active."],
                type = "check",
                requiresReload = true,
                dbPath = "global.castBars.hideBlizzard",
            },
            {   name = L["Show Spell Name"],
                type = "check",
                GetValue = function()
                  return GetGlobalCastBarSetting("showName");
                end,
                SetValue = function(_, newValue)
                  SetGlobalCastBarSetting("showName", newValue);
                end,
            },
            {   name = L["Show Icon"],
                type = "check",
                GetValue = function()
                  return GetGlobalCastBarSetting("showIcon");
                end,
                SetValue = function(_, newValue)
                  SetGlobalCastBarSetting("showIcon", newValue);
                end,
            },
            {   name = L["Show Latency Bar"],
                type = "check",
                requiresReload = true,
                dbPath = "profile.castBars.Player.showLatency",
            },
            {
              name = L["Enable Test Mode"],
              type = "button",
              tooltip = L["Test mode allows you to easily customize the looks and positioning of widgets by forcing all widgets to be shown."],
              OnLoad = function(_, container)
                container.component:SetText(AnyCastBarUnlocked() and L["Disable Test Mode"] or L["Enable Test Mode"]);
              end,
              OnClick = ToggleAllCastBarsTestMode,
            },
          },
          {
            {   name = L["Appearance"],
                type = "title",
                marginTop = 0;
            },
            {
              type = "fontstring";
              content = L["These settings control the shared look of all MayronUI cast bars."];
            },
            {   name = L["Bar Texture"],
                type = "dropdown",
                media = "statusbar";
                dbPath = "profile.castBars.appearance.texture"
            },
            {   name = L["Blend Mode"],
                tooltip = L["Changing the blend mode will affect how alpha channels blend with the background."];
                type = "dropdown",
                options = {
                  Normal = "BLEND";
                  Add = "ADD";
                },
                dbPath = "profile.castBars.appearance.blendMode"
            },
            {   name = L["Border"],
                type = "dropdown",
                media = "border";
                dbPath = "profile.castBars.appearance.border",
            },
            {   type = "divider"
            },
            {   name = L["Border Size"],
                type = "slider",
                min = 0,
                max = 10,
                dbPath = "profile.castBars.appearance.borderSize"
            },
            {   name = L["Frame Inset"],
                type = "slider",
                min = 0,
                max = 10,
                tooltip = L["Set the spacing between the status bar and the background."],
                dbPath = "profile.castBars.appearance.inset"
            },
            {   name = L["Font Size"],
                type = "slider",
                step = 1;
                min = 8;
                max = 24;
                dbPath = "profile.castBars.appearance.fontSize"
            },
            {   type = "fontstring",
                content = L["Colors"],
                subtype = "header",
            },
            {   name = L["Normal Casting"],
                type = "color",
                width = 160,
                hasOpacity = true;
                dbPath = "profile.castBars.appearance.colors.normal"
            },
            {   name = L["Not Interruptible"],
                type = "color",
                width = 160,
                hasOpacity = true;
                dbPath = "profile.castBars.appearance.colors.notInterruptible"
            },
            {   name = L["Finished Casting"],
                type = "color",
                hasOpacity = true;
                width = 160,
                dbPath = "profile.castBars.appearance.colors.finished"
            },
            {   name = L["Interrupted"],
                type = "color";
                hasOpacity = true;
                width = 160,
                dbPath = "profile.castBars.appearance.colors.interrupted"
            },
            {   name = L["Latency"],
                type = "color",
                hasOpacity = true;
                width = 160,
                dbPath = "profile.castBars.appearance.colors.latency"
            },
            {   name = L["Border"],
                type = "color",
                hasOpacity = true;
                width = 160,
                dbPath = "profile.castBars.appearance.colors.border"
            },
            {   name = L["Background"],
                type = "color",
                hasOpacity = true;
                width = 160,
                dbPath = "profile.castBars.appearance.colors.background"
            },
          },
          {
            {   name = L["Individual Cast Bar Options"],
                type = "title",
                marginTop = 0;
            },
            {
              type = "fontstring";
              content = L["These settings control each individual cast bar separately."];
            },
            {   type = "loop",
                args = { "Player", "Target", "Focus", "Mirror", "Pet", "Power" },
                func = function(_, name)
                if (tk:IsClassic() and name == "Focus") then return end
                if (not tk:IsRetail() and name == "Power") then return end

                local config =
                {
                  name = L[name],
                  type = "submenu",
                  OnLoad = function()
                    position_TextFields[name] = obj:PopTable();
                    width_TextFields[name] = obj:PopTable();
                    height_TextFields[name] = obj:PopTable();
                  end,
                  module = "CastBars",
                  children = {
                    {
                      name = L["Enable Bar"],
                      type = "check",
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".enabled");
                    },
                    -- 2: Remove for Mirror and Power
                    {
                      name = L["Show Icon"],
                      type = "check",
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".showIcon")
                    },
                    -- 3: Remove for anything that's not "Player"
                    {
                      name = L["Show Latency Bar"],
                      type = "check",
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".showLatency");

                      GetValue = function(self, value)
                        if (self.enabled) then
                          return value;
                        else
                          return false;
                        end
                      end
                    },
                    -- 4: Remove for Mirror and Power
                    {
                      name = L["Anchor to SUF Portrait Bar"],
                      type = "check",
                      OnLoad = function(_, container)
                        sufAnchor_CheckButtons[name] = container.btn;
                      end,
                      shown = name ~= "Mirror",
                      tooltip = string.format(
                        L["If enabled the Cast Bar will be fixed to the %s Unit Frame's Portrait Bar (if it exists)."], name),
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".anchorToSUF"),

                      SetValue = function(self, newValue)
                        local unitframe = _G["SUFUnit"..name:lower()];

                        if (newValue and not (unitframe and unitframe.portrait)) then
                          self.container.btn:SetChecked(false);
                          tk:Print(string.format(L["The %s Unit Frames's Portrait Bar needs to be enabled to use this feature."], name));
                          return;
                        end

                        db:SetPathValue(self.dbPath, newValue);
                        SetPositionTextFieldsEnabled(not newValue, name);
                      end
                    },
                    -- 5: Remove for Power
                    {
                      name = L["Left to Right"],
                      type = "check",
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".leftToRight")
                    },
                    { type = "divider" },
                    {
                      name = L["Unlock"],
                      type = "button",
                      data = { name },
                      OnClick = UnlockCastBar
                    },
                    {
                      name = L["Reset to default"],
                      type = "button",
                      data = { name },
                      OnClick = ResetCastBarPosition
                    },
                    {
                      type = "divider"
                    },
                    {
                      name = L["Width"],
                      tooltip = L["Only takes effect if the Cast Bar is not anchored to a SUF Portrait Bar."],
                      type = "slider",
                      min = 100,
                      max = 500,
                      step = 10,
                      OnLoad = function(_, container)
                        if (db.profile.castBars[name].anchorToSUF) then
                          container.component:SetEnabled(false);
                        end

                        tinsert(width_TextFields[name], container.component);
                      end,
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".width")
                    },
                    {
                      name = L["Height"],
                      tooltip = L["Only takes effect if the Cast Bar is not anchored to a SUF Portrait Bar."],
                      type = "slider",
                      min = 100,
                      max = 500,
                      step = 10,
                      OnLoad = function(_, container)
                        if (db.profile.castBars[name].anchorToSUF) then
                          container.component:SetEnabled(false);
                        end

                        tinsert(height_TextFields[name], container.component);
                      end,
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".height")
                    },
                    {
                      type = "divider",
                    },
                    {
                      name = L["Frame Strata"],
                      type = "dropdown",
                      options = tk.Constants.ORDERED_FRAME_STRATAS,
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".frameStrata")
                    },
                    {
                      name = L["Frame Level"],
                      type = "slider",
                      min = 1,
                      max = 50,
                      step = 1,
                      dbPath = tk.Strings:Concat("profile.castBars.", name, ".frameLevel")
                    },
                    {
                      name = L["Manual Positioning"],
                      type = "title",
                    },
                    {
                      type = "fontstring",
                      content = L["Manual positioning only works if the CastBar is not anchored to a SUF Portrait Bar."],
                    },
                    {
                      type = "loop";
                      args = { L["Point"], L["Relative Frame"], L["Relative Point"], L["X-Offset"], L["Y-Offset"] };
                      func = function(index, arg)
                        local config = {
                          name = arg;
                          type = "textfield";
                          valueType = "string";
                          dbPath = string.format("profile.castBars.%s.position[%d]", name, index);
                          castBarName = name;
                          pointID = index;
                          OnLoad = CastBarPosition_OnLoad,
                        };

                        if (index > 3) then
                          config.type = "slider";
                          config.min = -300;
                          config.max = 300;
                        end

                        return config;
                      end
                    };
                  }
                };

                if (name == "Mirror" or name == "Power") then
                  config.children[2] = nil;
                  config.children[4] = nil;
                  config.children[15] = nil;
                end

                if (name ~= "Player") then
                  config.children[3] = nil;
                end

                return config;
              end,
            }
          }
        }
    };
end
