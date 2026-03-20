local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore
local C_Timer = _G.C_Timer;

if (obj:Import("MayronUI.UniversalWindow.MoneyLooterAdapter", true)) then
  return;
end

local Common = obj:Import("MayronUI.UniversalWindow.Common");
local IsSafeWidget = Common.IsSafeWidget;
local SetPassiveVisibility = Common.SetPassiveVisibility;

local EMBED_INSET_LEFT = 8;
local EMBED_INSET_TOP = 8;
local EMBED_INSET_RIGHT = 8;
local EMBED_INSET_BOTTOM = 8;

local Adapter = obj:CreateInterface("MoneyLooterAdapter", {});
Adapter.key = "moneyLooter";
Adapter.title = L["MoneyLooter"];
Adapter.toggleTitle = L["Toggle MoneyLooter"];
Adapter.iconTexture = "Interface\\Icons\\INV_Misc_Coin_01";
Adapter.iconSize = 16;
Adapter.iconTexCoord = { 0.08; 0.92; 0.08; 0.92; };
Adapter.iconDesaturated = true;
Adapter.watchedAddOns = {
  ["MoneyLooter"] = true;
};

local function GetMoneyLooterFrame()
  local frame = _G.MONEYLOOTER_MAIN_FRAME;

  if (IsSafeWidget(frame, "Frame")) then
    return frame;
  end

  return nil;
end

local function ApplyEmbeddedLayout(frame, hostFrame)
  if (not (IsSafeWidget(frame, "Frame") and IsSafeWidget(hostFrame, "Frame"))) then
    return false;
  end

  pcall(function()
    frame.IsEmbeddedInMayronUI = true;
    frame.MUIEmbeddedHost = hostFrame;
    frame:SetParent(hostFrame);
    frame:ClearAllPoints();
    frame:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", EMBED_INSET_LEFT, -EMBED_INSET_TOP);
    frame:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", -EMBED_INSET_RIGHT, EMBED_INSET_BOTTOM);
    frame:SetFrameStrata(hostFrame:GetFrameStrata() or "MEDIUM");
    frame:SetFrameLevel((hostFrame:GetFrameLevel() or 1) + 5);

    if (obj:IsFunction(frame.UpdateLayout)) then
      frame:UpdateLayout(hostFrame:GetSize());
    end
  end);

  return true;
end

local function ReapplyEmbeddedLayout(frame)
  if (not IsSafeWidget(frame, "Frame")) then
    return;
  end

  local hostFrame = frame.MUIEmbeddedHost;
  if (not IsSafeWidget(hostFrame, "Frame")) then
    return;
  end

  ApplyEmbeddedLayout(frame, hostFrame);
  SetPassiveVisibility(frame, true);

  if (obj:IsFunction(frame.Show)) then
    pcall(function()
      frame:Show();
    end);
  end
end

local function EnsureResetHook(frame)
  if (frame.MUIResetHooked) then
    return;
  end

  local resetButton = frame.ResetButton;
  if (not IsSafeWidget(resetButton, "Button")) then
    return;
  end

  frame.MUIResetHooked = true;
  resetButton:HookScript("OnClick", function()
    if (obj:IsTable(C_Timer) and obj:IsFunction(C_Timer.After)) then
      C_Timer.After(0, function()
        ReapplyEmbeddedLayout(frame);
      end);

      C_Timer.After(0.1, function()
        ReapplyEmbeddedLayout(frame);
      end);
    else
      ReapplyEmbeddedLayout(frame);
    end
  end);
end

function Adapter:CanEmbed()
  return IsSafeWidget(GetMoneyLooterFrame(), "Frame");
end

function Adapter:Hide(preserveState)
  local frame = GetMoneyLooterFrame();

  if (preserveState and IsSafeWidget(frame, "Frame")) then
    SetPassiveVisibility(frame, false);
    return;
  end

  if (obj:IsTable(_G.MoneyLooterDB)) then
    _G.MoneyLooterDB.Visible = false;
    _G.MoneyLooterDB.EmbedInMayronUI = false;
  end

  if (IsSafeWidget(frame, "Frame")) then
    pcall(function()
      frame.IsEmbeddedInMayronUI = preserveState and frame.IsEmbeddedInMayronUI or false;
      frame.MUIEmbeddedHost = preserveState and frame.MUIEmbeddedHost or nil;
      frame:SetParent(_G.UIParent);
      frame:ClearAllPoints();
      frame:SetPoint("CENTER");
      frame:SetFrameStrata("MEDIUM");
      frame:SetFrameLevel(5);

      if (obj:IsFunction(frame.UpdateLayout)) then
        frame:UpdateLayout(frame.StandaloneWidth or 200, frame.StandaloneHeight or 180);
      end

      frame:Hide();
    end);
  end
end

function Adapter:Show(hostFrame)
  local frame = GetMoneyLooterFrame();

  if (not (IsSafeWidget(frame, "Frame") and IsSafeWidget(hostFrame, "Frame"))) then
    self:Hide(false);
    return false;
  end

  if (obj:IsTable(_G.MoneyLooterDB)) then
    _G.MoneyLooterDB.Visible = true;
    _G.MoneyLooterDB.EmbedInMayronUI = true;
  end

  EnsureResetHook(frame);
  ApplyEmbeddedLayout(frame, hostFrame);
  SetPassiveVisibility(frame, true);

  pcall(function()
    frame:Show();
  end);

  return true;
end

obj:Export(Adapter, "MayronUI.UniversalWindow.MoneyLooterAdapter");
