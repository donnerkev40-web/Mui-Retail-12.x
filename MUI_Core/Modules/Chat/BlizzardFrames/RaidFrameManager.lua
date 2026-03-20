-- luacheck: ignore MayronUI self 143
-- Setup namespaces ------------------
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, obj = MayronUI:GetCoreComponents();

local _, C_ChatModule = MayronUI:ImportModule("ChatModule");
local CompactRaidFrameManager, GetNumGroupMembers = _G.CompactRaidFrameManager, _G.GetNumGroupMembers;
local IsAddOnLoaded, InCombatLockdown = _G.IsAddOnLoaded, _G.InCombatLockdown;
local radians = _G.math.rad;
--------------------------------------
local function OnArrowButtonEvent(self)
  if (not IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
    return
  end

  local inGroup = GetNumGroupMembers() > 0;
  self:SetShown(inGroup);
end

local function OnArrowButtonClick(self)
  if (not obj:IsWidget(self.displayFrame)) then
    return;
  end

  -- toggle compact raid frame manager
  if (self.displayFrame:IsVisible()) then
    self.displayFrame:Hide();
    self.icon:SetRotation(radians(-90));
  else
    self.displayFrame:Show();
    self.icon:SetRotation(radians(90));
  end

  if (obj:IsWidget(self.manager)) then
    self.displayFrame:SetWidth(self.manager:GetWidth());
    self.displayFrame:SetHeight(self.manager:GetHeight());
  end
end

local function OnArrowButtonEnter(self)
  local r, g, b = self.icon:GetVertexColor();
  self.icon:SetVertexColor(r * 1.2, g * 1.2, b * 1.2);

  if (self.showOnMouseOver) then
    self:SetAlpha(1);
  end
end

local function OnArrowButtonLeave(self)
  tk:ApplyThemeColor(self.icon);
  if (self.showOnMouseOver) then
    self:SetAlpha(0);
  end
end

function C_ChatModule:SetUpRaidFrameManager(data)
  if (data.raidFrameManager) then
    return;
  end

  local compactRaidFrameManager = _G.CompactRaidFrameManager or CompactRaidFrameManager;
  if (not obj:IsWidget(compactRaidFrameManager)) then
    return;
  end

  local displayFrame = compactRaidFrameManager.displayFrame or _G.CompactRaidFrameManagerDisplayFrame;
  if (not obj:IsWidget(displayFrame)) then
    return;
  end

  if (tk:IsRetail()) then
    local managerProtected = obj:IsFunction(compactRaidFrameManager.IsProtected)
      and compactRaidFrameManager:IsProtected();

    local displayProtected = obj:IsFunction(displayFrame.IsProtected)
      and displayFrame:IsProtected();

    -- Retail EditMode owns this system. Avoid reparenting or overriding manager widgets.
    if (InCombatLockdown() or managerProtected or displayProtected) then
      data.raidFrameManager = "retail-protected-skip";
      return;
    end
  end

  -- Hide Blizzard Compact Manager:
  compactRaidFrameManager:DisableDrawLayer("ARTWORK");
  compactRaidFrameManager:EnableMouse(false);

  if (obj:IsWidget(compactRaidFrameManager.toggleButton)) then
    tk:KillElement(compactRaidFrameManager.toggleButton);
  end

  local headerDelineator = _G.CompactRaidFrameManagerDisplayFrameHeaderDelineator;
  if (obj:IsWidget(headerDelineator)) then
    headerDelineator:SetTexture("");
    headerDelineator.SetTexture = tk.Constants.DUMMY_FUNC;
  end

  local filterFooterDelineator = _G.CompactRaidFrameManagerDisplayFrameFilterOptionsFooterDelineator;
  if (obj:IsWidget(filterFooterDelineator)) then
    filterFooterDelineator:SetTexture("");
    filterFooterDelineator.SetTexture = tk.Constants.DUMMY_FUNC;
  end

  local headerBackground = _G.CompactRaidFrameManagerDisplayFrameHeaderBackground;
  if (obj:IsWidget(headerBackground)) then
    headerBackground:Hide();
    headerBackground.Show = tk.Constants.DUMMY_FUNC;
  end

  -- button to toggle compact raid frame manager
  local btn = tk:CreateFrame("Button", nil, "MUI_RaidFrameManagerButton");

  btn:SetSize(15, 100);
  btn:SetPoint("LEFT");
  btn:SetNormalTexture(tk:GetAssetFilePath("Textures\\SideBar\\SideButton"));
  btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1);

  btn.icon = btn:CreateTexture(nil, "OVERLAY");
  btn.icon:SetSize(12, 8);
  btn.icon:SetPoint("CENTER");
  btn.icon:SetTexture(tk:GetAssetFilePath("Icons\\arrow"));
  btn.icon:SetRotation(radians(-90));
  tk:ApplyThemeColor(btn.icon);

  btn:RegisterEvent("ADDON_LOADED");
  btn:RegisterEvent("GROUP_ROSTER_UPDATE");
  btn:RegisterEvent("PLAYER_ENTERING_WORLD");

  btn:SetScript("OnClick", OnArrowButtonClick);
  btn:SetScript("OnEvent", OnArrowButtonEvent);
  btn:SetScript("OnEnter", OnArrowButtonEnter);
  btn:SetScript("OnLeave", OnArrowButtonLeave);

  btn.manager = compactRaidFrameManager;
  btn.displayFrame = displayFrame;
  btn.displayFrame:SetParent(btn);
  btn.displayFrame:ClearAllPoints();
  btn.displayFrame:SetPoint("TOPLEFT", btn, "TOPRIGHT", 5, 0);

  gui:AddDialogTexture(btn.displayFrame);
  tk:MakeMovable(btn.displayFrame);

  OnArrowButtonEvent(btn);
  data.raidFrameManager = true;
end
