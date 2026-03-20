-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore
local C_PetBattles = _G.C_PetBattles;
local pcall = _G.pcall;

-- Register and Import Modules -----------
local C_Container = MayronUI:RegisterModule("MainContainer", L["Unit Frame Panels"]);

-- Add Database Defaults -----------------

db:AddToDefaults("profile.bottomui", {
  width = 750;
  enabled = true;
  frameStrata = "LOW";
  frameLevel = 5;
  xOffset = 0;
  yOffset = -1;
});

-- C_Container ------------------

function C_Container:OnInitialize(data)
  if (not MayronUI:IsInstalled()) then return end

  self:RegisterUpdateFunctions(db.profile.bottomui, {
    width = function(value)
      data.container:SetSize(value, 1);

      local dataTextModule = MayronUI:ImportModule("DataTextModule");

      if (dataTextModule and dataTextModule:IsEnabled()) then
        dataTextModule:PositionDataTextButtons();
      end
    end;
    frameLevel = function(value)
      data.container:SetFrameLevel(value);
    end;
    frameStrata = function(value)
      data.container:SetFrameStrata(value);
    end;
    yOffset = function(value)
      data.container:SetPoint("BOTTOM", data.settings.xOffset, value);
    end;
    xOffset = function(value)
      data.container:SetPoint("BOTTOM", value, data.settings.yOffset);
    end;
  });
end

function C_Container:OnInitialized(data)
  if (data.settings.enabled) then
    self:SetEnabled(true);
  end
end

function C_Container:OnEnable(data)
  if (not data.container) then
    data.container = tk:CreateFrame("Frame", nil, "MUI_BottomContainer");
    data.container:SetSize(data.settings.width, 1);
    data.container:SetPoint("BOTTOM", data.settings.xOffset, data.settings.yOffset);
    data.container:SetFrameStrata(data.settings.frameStrata);
    data.container:SetFrameLevel(data.settings.frameLevel);
    data.container:Show();
    tk:HideInPetBattles(data.container);
  end

  if (not data.subModules) then
    data.subModules = obj:PopTable();

    if (MayronUI:IsFeatureEnabled("resourceBars.enabled")) then
      data.subModules.ResourceBars = MayronUI:ImportModule("ResourceBars");
    end

    if (MayronUI:IsFeatureEnabled("actionbars.bottomBars")) then
      data.subModules.ActionBarPanel = MayronUI:ImportModule("BottomActionBars");
    end

    if (MayronUI:IsFeatureEnabled("unitPanels.enabled")) then
      data.subModules.UnitPanels = MayronUI:ImportModule("UnitPanels");
    end

    local function SafeInitializeSubModule(subModuleKey)
      local subModule = data.subModules[subModuleKey];

      if (not (subModule and obj:IsFunction(subModule.Initialize))) then
        data.subModules[subModuleKey] = nil;
        return;
      end

      local ok = pcall(subModule.Initialize, subModule, self, data.subModules);
      if (not ok) then
        data.subModules[subModuleKey] = nil;
      end
    end

    SafeInitializeSubModule("ActionBarPanel");
    SafeInitializeSubModule("ResourceBars");
    SafeInitializeSubModule("UnitPanels");
  end

  self:RepositionContent();
end

function C_Container:RepositionContent(data)
  local dataTextModule = MayronUI:ImportModule("DataTextModule");
  local anchorFrame = data.container;

  if (dataTextModule and dataTextModule:IsEnabled() and obj:IsWidget(_G.MUI_DataTextBar)) then
    anchorFrame = _G.MUI_DataTextBar;
  end

  if (data.subModules.ResourceBars and data.subModules.ResourceBars:IsEnabled()) then
    local friendData = data:GetFriendData(data.subModules.ResourceBars);
    local resourceContainer = friendData and friendData.barsContainer;

    if (obj:IsWidget(resourceContainer)) then
      resourceContainer:ClearAllPoints();
      resourceContainer:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, -1);
      resourceContainer:SetPoint("BOTTOMRIGHT", anchorFrame, "TOPRIGHT", 0, -1);
      anchorFrame = resourceContainer;
    end
  end

  local actionBarsModule = data.subModules.ActionBarPanel; ---@type BottomActionBarsModule

  if (actionBarsModule and actionBarsModule:IsEnabled()) then
    local actionBarPanel = actionBarsModule:GetPanel();

    if (obj:IsWidget(actionBarPanel)) then
      actionBarPanel:ClearAllPoints();
      actionBarPanel:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, -1);
      actionBarPanel:SetPoint("BOTTOMRIGHT", anchorFrame, "TOPRIGHT", 0, -1);

      local startPoint = actionBarPanel:GetBottom();
      data.subModules.ActionBarPanel:SetUpExpandRetract(startPoint);
      anchorFrame = actionBarPanel;
    end
  end

  if (data.subModules.UnitPanels and data.subModules.UnitPanels:IsEnabled()) then
    local unitHeight = db.profile.unitPanels.unitHeight;
    local leftUnitPanel = _G["MUI_UnitPanelLeft"];
    local rightUnitPanel = _G["MUI_UnitPanelRight"];

    if (obj:IsWidget(leftUnitPanel) and obj:IsWidget(rightUnitPanel)) then
      leftUnitPanel:ClearAllPoints();
      rightUnitPanel:ClearAllPoints();
      leftUnitPanel:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, unitHeight);
      rightUnitPanel:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, unitHeight);
    end
  end
end
