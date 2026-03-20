local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (obj:Import("MayronUI.UniversalWindow.ZygorGuidesAdapter", true)) then
  return;
end

local Common = obj:Import("MayronUI.UniversalWindow.Common");
local IsAddOnLoaded = _G.IsAddOnLoaded;
local IsSafeWidget = Common.IsSafeWidget;
local SetPassiveVisibility = Common.SetPassiveVisibility;

local Adapter = obj:CreateInterface("ZygorGuidesAdapter", {});
Adapter.key = "zygorGuides";
Adapter.title = L["Zygor Guides"];
Adapter.toggleTitle = L["Toggle Zygor Guides"];
Adapter.iconTexture = "Interface\\AddOns\\ZygorGuidesViewer\\Skins\\addon-icon";
Adapter.hideShellTitle = true;
Adapter.watchedAddOns = {
  ["ZygorGuidesViewer"] = true;
};

local EMBED_INSET_LEFT = 6;
local EMBED_INSET_TOP = 6;
local EMBED_INSET_RIGHT = 6;
local EMBED_INSET_BOTTOM = 6;

local function SetFrameVisualOrder(frame, frameStrata, frameLevel)
  if (not IsSafeWidget(frame, "Frame")) then
    return;
  end

  pcall(function()
    frame:SetFrameStrata(frameStrata or "MEDIUM");
  end);

  pcall(function()
    frame:SetFrameLevel(frameLevel or 1);
  end);
end

local function RefreshViewerLayout(addon, viewerFrame)
  if (IsSafeWidget(viewerFrame, "Frame") and obj:IsFunction(viewerFrame.AlignFrame)) then
    pcall(function()
      viewerFrame:AlignFrame();
    end);
  end

  if (IsSafeWidget(viewerFrame, "Frame") and obj:IsFunction(viewerFrame.OnSizeChanged)) then
    pcall(function()
      viewerFrame:OnSizeChanged();
    end);
  end

  if (obj:IsTable(addon) and obj:IsTable(addon.Tabs) and obj:IsFunction(addon.Tabs.ReanchorTabs)) then
    pcall(function()
      addon.Tabs:ReanchorTabs(true);
    end);
  end

  if (obj:IsTable(addon) and obj:IsFunction(addon.UpdateFrame)) then
    pcall(function()
      addon:UpdateFrame(true);
    end);
  end
end

local function GetZygorAddon()
  if (not IsAddOnLoaded("ZygorGuidesViewer")) then
    return nil;
  end

  if (obj:IsTable(_G.ZGV)) then
    return _G.ZGV;
  end

  if (obj:IsTable(_G.ZygorGuidesViewer)) then
    return _G.ZygorGuidesViewer;
  end

  if (obj:IsFunction(_G.LibStub)) then
    local aceAddon = _G.LibStub("AceAddon-3.0", true);

    if (obj:IsTable(aceAddon) and obj:IsFunction(aceAddon.GetAddon)) then
      local ok, addon = pcall(function()
        return aceAddon:GetAddon("ZygorGuidesViewer", true);
      end);

      if (ok and obj:IsTable(addon)) then
        return addon;
      end
    end
  end
end

local function GetZygorFrames(addon)
  local viewerFrame = obj:IsTable(addon) and addon.Frame;

  if (not IsSafeWidget(viewerFrame, "Frame")) then
    viewerFrame = _G.ZygorGuidesViewerFrame;
  end

  if (not IsSafeWidget(viewerFrame, "Frame")) then
    return nil;
  end

  local hostFrame = obj:IsTable(addon) and addon.MasterFrame;

  if (not IsSafeWidget(hostFrame, "Frame")) then
    hostFrame = _G.ZygorGuidesViewerFrameMaster;
  end

  if (not IsSafeWidget(hostFrame, "Frame")) then
    hostFrame = viewerFrame:GetParent();
  end

  if (not IsSafeWidget(hostFrame, "Frame")) then
    hostFrame = viewerFrame;
  end

  return hostFrame, viewerFrame;
end

function Adapter:CanEmbed()
  local addon = GetZygorAddon();
  local hostFrame, viewerFrame = GetZygorFrames(addon);
  return obj:IsTable(addon)
    and IsSafeWidget(hostFrame, "Frame")
    and IsSafeWidget(viewerFrame, "Frame");
end

function Adapter:Hide(preserveState)
  local addon = GetZygorAddon();
  local hostFrame, viewerFrame = GetZygorFrames(addon);

  if (preserveState) then
    if (IsSafeWidget(viewerFrame, "Frame")) then
      SetPassiveVisibility(viewerFrame, false);
    end

    if (IsSafeWidget(hostFrame, "Frame") and hostFrame ~= viewerFrame) then
      SetPassiveVisibility(hostFrame, false);
    end

    return;
  end

  if (IsSafeWidget(viewerFrame, "Frame")) then
    pcall(function()
      viewerFrame:Hide();
    end);
  end

  if (IsSafeWidget(hostFrame, "Frame")) then
    pcall(function()
      hostFrame:SetParent(_G.UIParent);
      hostFrame:ClearAllPoints();
      hostFrame:SetPoint("CENTER");
      hostFrame:SetFrameStrata("MEDIUM");
      hostFrame:SetFrameLevel(5);
      hostFrame:Hide();
    end);
  end
end

function Adapter:Show(hostFrame)
  local addon = GetZygorAddon();
  local zygorHostFrame, viewerFrame = GetZygorFrames(addon);

  if (not (obj:IsTable(addon) and IsSafeWidget(zygorHostFrame, "Frame")
      and IsSafeWidget(viewerFrame, "Frame") and IsSafeWidget(hostFrame, "Frame"))) then
    self:Hide(false);
    return false;
  end

  pcall(function()
    zygorHostFrame:SetParent(hostFrame);
    zygorHostFrame:ClearAllPoints();
    zygorHostFrame:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", EMBED_INSET_LEFT, -EMBED_INSET_TOP);
    zygorHostFrame:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", -EMBED_INSET_RIGHT, EMBED_INSET_BOTTOM);
    zygorHostFrame:SetClampedToScreen(false);
    zygorHostFrame:SetMovable(false);
  end);

  local baseLevel = (hostFrame:GetFrameLevel() or 1) + 20;
  local frameStrata = hostFrame:GetFrameStrata() or "MEDIUM";

  SetFrameVisualOrder(zygorHostFrame, frameStrata, baseLevel);
  SetFrameVisualOrder(viewerFrame, frameStrata, baseLevel + 1);
  SetFrameVisualOrder(viewerFrame.Border, frameStrata, baseLevel + 2);
  SetFrameVisualOrder(viewerFrame.Border and viewerFrame.Border.TitleBar, frameStrata, baseLevel + 3);
  SetFrameVisualOrder(viewerFrame.Border and viewerFrame.Border.TabContainer, frameStrata, baseLevel + 3);
  SetFrameVisualOrder(viewerFrame.Border and viewerFrame.Border.Toolbar, frameStrata, baseLevel + 3);

  pcall(function()
    local embedWidth = math.max(10, hostFrame:GetWidth() - EMBED_INSET_LEFT - EMBED_INSET_RIGHT);
    local embedHeight = math.max(10, hostFrame:GetHeight() - EMBED_INSET_TOP - EMBED_INSET_BOTTOM);
    viewerFrame:ClearAllPoints();
    viewerFrame:SetPoint("TOPLEFT", zygorHostFrame, "TOPLEFT", 0, 0);
    viewerFrame:SetSize(embedWidth, embedHeight);
  end);

  SetPassiveVisibility(zygorHostFrame, true);
  if (viewerFrame ~= zygorHostFrame) then
    SetPassiveVisibility(viewerFrame, true);
  end

  pcall(function()
    zygorHostFrame:Show();
    viewerFrame:Show();
  end);

  RefreshViewerLayout(addon, viewerFrame);

  return true;
end

obj:Export(Adapter, "MayronUI.UniversalWindow.ZygorGuidesAdapter");
