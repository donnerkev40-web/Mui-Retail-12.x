-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, em, _, obj = MayronUI:GetCoreComponents(); -- luacheck: ignore
local _, C_UnitPanels = _G.MayronUI:ImportModule("UnitPanels");

local pairs = _G.pairs;
local IsAddOnLoaded, UnitExists, UnitIsPlayer = _G.IsAddOnLoaded, _G.UnitExists, _G.UnitIsPlayer;

local function ApplyGradientTexture(texture, settings, useTargetClassColor)
  if (not (texture and obj:IsTable(settings) and obj:IsTable(settings.from) and obj:IsTable(settings.to))) then
    return;
  end

  local from = settings.from;
  local to = settings.to;
  local opacity = settings.opacity or from.a or 0.5;
  local toAlpha = 0;

  if (useTargetClassColor) then
    local targetR, targetG, targetB = tk:GetClassColor("target");

    tk:SetGradient(texture, "VERTICAL",
      to.r, to.g, to.b, toAlpha,
      targetR, targetG, targetB, opacity);
  else
    tk:SetGradient(texture, "VERTICAL",
      to.r, to.g, to.b, toAlpha,
      from.r, from.g, from.b, opacity);
  end
end

local function CreateGradientFrame(sufGradients, parent)
  if (not obj:IsWidget(parent)) then
    return;
  end

  local frame = tk:CreateFrame("Frame", parent);
  frame:SetPoint("TOPLEFT", 1, -1);
  frame:SetPoint("TOPRIGHT", -1, -1);
  frame:SetFrameLevel(5);
  frame.texture = frame:CreateTexture(nil, "OVERLAY");
  frame.texture:SetAllPoints(frame);
  frame.texture:SetColorTexture(1, 1, 1, 1);
  frame:SetSize(100, sufGradients.height);
  frame:Show();

  local from = sufGradients.from;
  local to = sufGradients.to;

  ApplyGradientTexture(frame.texture, sufGradients, false);

  return frame;
end

function C_UnitPanels:RefreshPortraitGradients(data)
  if (not (obj:IsTable(data) and obj:IsTable(data.settings) and obj:IsTable(data.settings.sufGradients))) then
    return;
  end

  local settings = data.settings.sufGradients;

  if (obj:IsTable(settings.from)) then
    settings.from.a = settings.opacity or settings.from.a or 0.5;
  end

  if (obj:IsTable(settings.to)) then
    settings.to.a = 0;
  end

  if (not obj:IsTable(data.gradients)) then
    return;
  end

  for unitID, frame in pairs(data.gradients) do
    if (frame and frame.texture) then
      ApplyGradientTexture(frame.texture, settings,
        unitID == "target" and UnitIsPlayer("target") and settings.targetClassColored);
    end
  end
end

function C_UnitPanels:SetPortraitGradientsEnabled(data, enabled)
  if (not IsAddOnLoaded("ShadowedUnitFrames")
      or not (obj:IsTable(data.settings) and obj:IsTable(data.settings.sufGradients))) then
    return
  end

  if (enabled) then
    data.gradients = data.gradients or obj:PopTable();

    for i = 1, 2 do
      local unitID = i == 1 and "player" or "target";
      local parent = _G["SUFUnit" .. unitID];

      if (parent and parent.portrait) then
        data.gradients[unitID] = data.gradients[unitID] or CreateGradientFrame(data.settings.sufGradients, parent);

        if (unitID == "target") then
          local frame = data.gradients[unitID];
          local handler = em:GetEventListenerByID("MuiUnitPanels_TargetGradient");

          if (not handler) then
            handler = em:CreateEventListenerWithID("MuiUnitPanels_TargetGradient", function()
              if (not (UnitExists("target") and frame and frame.texture)) then
                return
              end

              self:RefreshPortraitGradients(data);
            end);

            handler:RegisterEvent("PLAYER_TARGET_CHANGED");
          else
            handler:SetEnabled(true);
          end

          em:TriggerEventListenerByID("MuiUnitPanels_TargetGradient");
        end

        data.gradients[unitID]:Show();
      elseif (data.gradients[unitID]) then
        data.gradients[unitID]:Hide();
      end
    end

    self:RefreshPortraitGradients(data);
  else
    if (data.gradients) then
      for _, frame in pairs(data.gradients) do
        frame:Hide();
      end
    end

    local handler = em:GetEventListenerByID("MuiUnitPanels_TargetGradient");

    if (handler) then
      handler:SetEnabled(false);
    end
  end
end
