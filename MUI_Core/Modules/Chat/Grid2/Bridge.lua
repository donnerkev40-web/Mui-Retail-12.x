local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();
local InCombatLockdown = _G.InCombatLockdown;

if (obj:Import("MayronUI.Chat.Grid2.Bridge", true)) then
  return;
end

local Grid2Bridge = obj:CreateInterface("ChatGrid2Bridge", {});

local function GetLayoutModule()
  if (obj:IsTable(_G.Grid2) and obj:IsFunction(_G.Grid2.GetModule)) then
    local success, module = pcall(function()
      return _G.Grid2:GetModule("Grid2Layout", true);
    end);

    if (success and obj:IsTable(module)) then
      return module;
    end
  end
end

local function GetMainFrame()
  local layout = GetLayoutModule();
  local frame = layout and layout.frame or _G.Grid2LayoutFrame;
  return frame, layout;
end

local function RefreshGrid2Frame(_, frame)
  if (obj:IsWidget(frame) and obj:IsWidget(frame.frameBack)) then
    frame.frameBack:SetParent(frame);
    frame.frameBack:Show();
  end
end

function Grid2Bridge:Hide()
  local frame = GetMainFrame();

  if (not obj:IsWidget(frame)) then
    return false;
  end

  if (obj:IsFunction(InCombatLockdown) and InCombatLockdown()) then
    return false;
  end

  if (obj:IsWidget(frame.frameBack)) then
    frame.frameBack:Hide();
  end

  local ok = pcall(function()
    frame:Hide();
    frame:SetParent(_G.UIParent);
    frame:ClearAllPoints();
    frame:SetPoint("CENTER", _G.UIParent, "CENTER");
  end);

  if (not ok) then
    return false;
  end

  return true;
end

function Grid2Bridge:Refresh(chatData, anchorName)
  if (not tk:IsRetail()) then
    return self:Hide();
  end

  if (obj:IsFunction(InCombatLockdown) and InCombatLockdown()) then
    return false;
  end

  local frame = GetMainFrame();

  if (not (obj:IsWidget(frame) and obj:IsTable(chatData))) then
    return self:Hide();
  end

  local muiChatFrame = obj:IsTable(chatData.chatFrames) and chatData.chatFrames[anchorName];
  local shellFrame = muiChatFrame and obj:IsFunction(muiChatFrame.GetFrame) and muiChatFrame:GetFrame();
  local hostFrame = shellFrame and shellFrame.window and (shellFrame.window.contentHost or shellFrame.window);

  if (not (obj:IsWidget(hostFrame) and obj:IsWidget(shellFrame) and shellFrame:IsShown())) then
    return self:Hide();
  end

  local ok = pcall(function()
    frame:SetParent(hostFrame);
    frame:ClearAllPoints();
    frame:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", 8, -8);
    frame:SetScale(1);
    frame:SetFrameStrata(hostFrame:GetFrameStrata() or "MEDIUM");
    frame:SetFrameLevel((hostFrame:GetFrameLevel() or 1) + 5);
  end);

  if (not ok) then
    return false;
  end

  RefreshGrid2Frame(nil, frame);

  if (frame:IsShown() == false) then
    frame:Show();
  end

  return true;
end

obj:Export(Grid2Bridge, "MayronUI.Chat.Grid2.Bridge");
