local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ActionBars.BlizzardSuppressor", true)) then
  return;
end

local BlizzardSuppressor = obj:CreateInterface("BlizzardSuppressor", {});

local function HideRegion(region, hider)
  if (not obj:IsTable(region)) then
    return;
  end

  pcall(function()
    if (obj:IsFunction(region.Hide)) then
      region:Hide();
    end

    if (obj:IsFunction(region.SetAlpha)) then
      region:SetAlpha(0);
    end

    if (obj:IsFunction(region.SetParent)) then
      region:SetParent(hider);
    end
  end);
end

local function HideFrameTree(frame, hider)
  if (not obj:IsWidget(frame)) then
    return;
  end

  pcall(function()
    if (obj:IsFunction(frame.UnregisterAllEvents)) then
      frame:UnregisterAllEvents();
    end

    if (obj:IsFunction(frame.HideBase)) then
      frame:HideBase();
    else
      frame:Hide();
    end

    frame:SetAlpha(0);
    frame:SetParent(hider);
  end);

  if (obj:IsFunction(frame.GetNumRegions) and obj:IsFunction(frame.GetRegions)) then
    local numRegions = frame:GetNumRegions() or 0;

    for i = 1, numRegions do
      HideRegion(select(i, frame:GetRegions()), hider);
    end
  end

  if (obj:IsFunction(frame.GetNumChildren) and obj:IsFunction(frame.GetChildren)) then
    local numChildren = frame:GetNumChildren() or 0;

    for i = 1, numChildren do
      local child = select(i, frame:GetChildren());

      if (obj:IsWidget(child)) then
        pcall(function()
          child:Hide();
          child:SetAlpha(0);
          child:SetParent(hider);
        end);
      else
        HideRegion(child, hider);
      end
    end
  end

  if (not frame.__muiSuppressedActionBarRemainder) then
    frame.__muiSuppressedActionBarRemainder = true;
    frame:HookScript("OnShow", function(self)
      self:SetAlpha(0);

      if (obj:IsFunction(self.HideBase)) then
        self:HideBase();
      else
        self:Hide();
      end

      if (obj:IsFunction(self.GetNumRegions) and obj:IsFunction(self.GetRegions)) then
        local numRegions = self:GetNumRegions() or 0;

        for i = 1, numRegions do
          HideRegion(select(i, self:GetRegions()), hider);
        end
      end
    end);
  end
end

function BlizzardSuppressor:SuppressActionBarRemainder()
  if (not tk:IsRetail()) then
    return;
  end

  if (not _G.MUI_BottomActionBarsHider) then
    _G.MUI_BottomActionBarsHider = _G.CreateFrame("Frame", "MUI_BottomActionBarsHider", _G.UIParent);
    _G.MUI_BottomActionBarsHider:Hide();
  end

  local hider = _G.MUI_BottomActionBarsHider;
  local frames = {
    _G.MainMenuBarArtFrame;
    _G.MainMenuBar;
    _G.MainActionBar;
    _G.MicroButtonAndBagsBar;
    _G.StatusTrackingBarManager;
    _G.MainStatusTrackingBarContainer;
    _G.StanceBarFrame;
    _G.PetActionBarFrame;
    _G.PossessBarFrame;
    _G.OverrideActionBar;
    _G.OverrideActionBarPitchFrame;
    _G.MainMenuBarVehicleLeaveButton;
    _G.BT4BarBlizzardArt;
    _G.BT4BarBlizzardArtOverlay;
  };
  local simpleElements = {
    tk.Tables:GetValueOrNil(_G, "MainMenuBarArtFrame", "Background");
    tk.Tables:GetValueOrNil(_G, "MainMenuBarArtFrame", "LeftEndCap");
    tk.Tables:GetValueOrNil(_G, "MainMenuBarArtFrame", "RightEndCap");
    tk.Tables:GetValueOrNil(_G, "MainMenuBarArtFrame", "PageNumber");
    _G.MainMenuBarArtFrameBackground;
    _G.MainMenuBarLeftEndCap;
    _G.MainMenuBarRightEndCap;
    _G.SlidingActionBarTexture0;
    _G.SlidingActionBarTexture1;
    _G.StanceBarLeft;
    _G.StanceBarMiddle;
    _G.StanceBarRight;
    _G.PossessBackground1;
    _G.PossessBackground2;
    _G.MainMenuMaxLevelBar0;
    _G.MainMenuMaxLevelBar1;
    _G.MainMenuMaxLevelBar2;
    _G.MainMenuMaxLevelBar3;
    _G.CharacterMicroButton;
    _G.SpellbookMicroButton;
    _G.TalentMicroButton;
    _G.PlayerSpellsMicroButton;
    _G.AchievementMicroButton;
    _G.QuestLogMicroButton;
    _G.GuildMicroButton;
    _G.LFDMicroButton;
    _G.CollectionsMicroButton;
    _G.EJMicroButton;
    _G.StoreMicroButton;
    _G.MainMenuMicroButton;
    _G.MainMenuBarBackpackButton;
    _G.MainMenuBarPerformanceBarFrame;
    _G.BlizzardArtLeftCap;
    _G.BlizzardArtRightCap;
    _G.BlizzardArtTex0;
    _G.BlizzardArtTex1;
    _G.BlizzardArtTex1b;
    _G.BlizzardArtTex2;
    _G.BlizzardArtTex3;
    _G.BlizzardArtTex3b;
  };

  for _, frame in ipairs(frames) do
    HideFrameTree(frame, hider);
  end

  for _, element in ipairs(simpleElements) do
    if (obj:IsWidget(element)) then
      HideFrameTree(element, hider);
    elseif (obj:IsTable(element)) then
      HideRegion(element, hider);
    end
  end
end

obj:Export(BlizzardSuppressor, "MayronUI.ActionBars.BlizzardSuppressor");
