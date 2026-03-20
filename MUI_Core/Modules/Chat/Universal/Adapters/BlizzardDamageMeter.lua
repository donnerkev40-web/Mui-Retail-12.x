local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (obj:Import("MayronUI.UniversalWindow.BlizzardDamageMeterAdapter", true)) then
  return;
end

local Common = obj:Import("MayronUI.UniversalWindow.Common");
local IsSafeWidget = Common.IsSafeWidget;
local SetPassiveVisibility = Common.SetPassiveVisibility;

local Adapter = obj:CreateInterface("BlizzardDamageMeterAdapter", {});
Adapter.key = "damageMeter";
Adapter.title = L["Damage Meter"];
Adapter.toggleTitle = L["Toggle Damage Meter"];
Adapter.iconTexture = "Interface\\Icons\\INV_Misc_EngGizmos_27";
Adapter.iconSize = 16;
Adapter.iconTexCoord = { 0.08; 0.92; 0.08; 0.92; };
Adapter.iconDesaturated = true;

local function AddUniqueFrame(frames, seen, frame)
  if (IsSafeWidget(frame, "Frame") and not seen[frame]) then
    frames[#frames + 1] = frame;
    seen[frame] = true;
  end
end

local function GetBlizzardDamageMeterFrames()
  local frames = {};
  local seen = {};

  AddUniqueFrame(frames, seen, _G.DamageMeterSessionWindow1);
  AddUniqueFrame(frames, seen, _G.DamageMeter);

  for index = 1, 4 do
    AddUniqueFrame(frames, seen, _G["DamageMeterSessionWindow" .. index]);
  end

  return frames;
end

function Adapter:CanEmbed()
  local frames = GetBlizzardDamageMeterFrames();
  return frames[1] ~= nil;
end

function Adapter:Hide(preserveState)
  local frames = GetBlizzardDamageMeterFrames();

  if (preserveState) then
    for _, frame in ipairs(frames) do
      SetPassiveVisibility(frame, false);
    end

    return;
  end

  for _, frame in ipairs(frames) do
    pcall(function()
      frame:SetParent(_G.UIParent);
      frame:ClearAllPoints();
      frame:SetPoint("CENTER");
      frame:SetFrameStrata("MEDIUM");
      frame:SetFrameLevel(5);
      frame:Hide();
    end);
  end
end

function Adapter:Show(hostFrame)
  local frames = GetBlizzardDamageMeterFrames();
  local leftInset = 2;
  local topInset = -2;
  local rightInset = -2;
  local bottomInset = 2;

  if (not (IsSafeWidget(hostFrame, "Frame") and frames[1])) then
    self:Hide(false);
    return false;
  end

  for _, frame in ipairs(frames) do
    pcall(function()
      frame:SetParent(hostFrame);
      frame:ClearAllPoints();
      frame:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", leftInset, topInset);
      frame:SetPoint("BOTTOMRIGHT", hostFrame, "BOTTOMRIGHT", rightInset, bottomInset);
      frame:SetFrameStrata(hostFrame:GetFrameStrata() or "MEDIUM");
      frame:SetFrameLevel((hostFrame:GetFrameLevel() or 1) + 5);
      frame:SetScale(1);
      frame:Show();
    end);

    SetPassiveVisibility(frame, true);
  end

  return true;
end

obj:Export(Adapter, "MayronUI.UniversalWindow.BlizzardDamageMeterAdapter");
