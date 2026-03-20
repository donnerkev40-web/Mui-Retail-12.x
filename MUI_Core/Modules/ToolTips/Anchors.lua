local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj = MayronUI:GetCoreComponents();
local InCombatLockdown = _G.InCombatLockdown;
local UnitExists = _G.UnitExists;

if (obj:Import("MayronUI.Tooltips.Anchors", true)) then
  return;
end

local TooltipAnchors = obj:CreateInterface("TooltipAnchors", {});

function TooltipAnchors:CreateScreenAnchor(data)
  data.screenAnchor = tk:CreateFrame("Frame");
  data.screenAnchor:SetFrameStrata("TOOLTIP");
  tk:MakeMovable(data.screenAnchor);
  data.screenAnchor:SetSize(240, 150);

  data.screenAnchor:SetPoint(data.settings.anchors.screen.point,
    data.settings.anchors.screen.xOffset,
    data.settings.anchors.screen.yOffset);

  data.screenAnchor.bg = tk:SetBackground(data.screenAnchor, 0, 0, 0, 0.8);
  data.screenAnchor.bg:SetAllPoints(true);

  data.screenAnchor.bg.text = data.screenAnchor:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
  data.screenAnchor.bg.text:SetText("Tool-tip screen anchor point (Drag me!)");
  data.screenAnchor.bg.text:SetWidth(200);
  data.screenAnchor.bg.text:SetPoint("CENTER");

  function data.screenAnchor:Unlock()
    data.screenAnchor:ClearAllPoints();
    data.screenAnchor:SetPoint(
      data.settings.anchors.screen.point,
      data.settings.anchors.screen.xOffset,
      data.settings.anchors.screen.yOffset);

    data.screenAnchor.bg:SetAlpha(0.8);
    data.screenAnchor.bg.text:SetAlpha(1);
    data.screenAnchor:EnableMouse(true);
    data.screenAnchor:SetMovable(true);
  end

  function data.screenAnchor:Lock(dontSave)
    data.screenAnchor.bg:SetAlpha(0);
    data.screenAnchor.bg.text:SetAlpha(0);
    data.screenAnchor:EnableMouse(false);
    data.screenAnchor:SetMovable(false);

    if (not dontSave) then
      local positions = tk.Tables:GetFramePosition(data.screenAnchor);

      if (obj:IsTable(positions)) then
        db:SetPathValue("profile.tooltips.anchors.screen", {
          point = positions[1];
          xOffset = positions[4] or 0;
          yOffset = positions[5] or 0
        });
      end

      return positions;
    end
  end

  data.screenAnchor:Lock(true);
end

function TooltipAnchors:ShouldBeHidden(data, tooltip)
  local _, unitID = tooltip:GetUnit();
  local inCombat = InCombatLockdown();

  if (unitID) then
    if ((inCombat and data.settings.unitFrames.hideInCombat) or not data.settings.unitFrames.show) then
      if (unitID ~= "mouseover") then
        tooltip:Hide();
        return true;
      end
    end

    if ((inCombat and data.settings.worldUnits.hideInCombat) or not data.settings.worldUnits.show) then
      if (unitID == "mouseover") then
        tooltip:Hide();
        return true;
      end
    end
  elseif ((inCombat and data.settings.standard.hideInCombat) or not data.settings.standard.show) then
    tooltip:Hide();
    return true;
  end

  return false;
end

function TooltipAnchors:ApplyDefaultAnchor(data, tooltip, parent)
  if (not parent) then
    return;
  end

  local anchorType = data.settings.standard.anchor:lower();
  local isWorldUnit = UnitExists("mouseover") and not parent.unit;
  local isUnitFrame = parent.unit ~= nil;

  if (isWorldUnit) then
    anchorType = data.settings.worldUnits.anchor:lower();
  elseif (isUnitFrame) then
    anchorType = data.settings.unitFrames.anchor:lower();
  end

  local anchor = data.settings.anchors[anchorType];
  tooltip:ClearAllPoints();

  if (anchorType == "mouse") then
    tooltip:SetOwner(parent, anchor.point, anchor.xOffset, anchor.yOffset);
  else
    tooltip:SetOwner(parent, "ANCHOR_NONE");
    tooltip:SetPoint(anchor.point, data.screenAnchor, anchor.point);
  end
end

obj:Export(TooltipAnchors, "MayronUI.Tooltips.Anchors");
