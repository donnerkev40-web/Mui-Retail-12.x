local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Tooltips.Style", true)) then
  return;
end

local TooltipStyle = obj:CreateInterface("TooltipStyle", {});

function TooltipStyle:EnsureBackdropSupport(tooltip)
  if (obj:IsFunction(tooltip.SetBackdrop)) then
    return true;
  end

  if (tk:IsRetail() or not _G.BackdropTemplateMixin) then
    return false;
  end

  if (not tooltip.__MUIBackdropMixinApplied) then
    _G.Mixin(tooltip, _G.BackdropTemplateMixin);
    tooltip.__MUIBackdropMixinApplied = true;
  end

  return obj:IsFunction(tooltip.SetBackdrop);
end

function TooltipStyle:SetAccentColor(tooltip, useMuiTexture, r, g, b)
  if (useMuiTexture and obj:IsFunction(tooltip.SetGridColor)) then
    tooltip:SetGridColor(r, g, b);
  elseif (obj:IsFunction(tooltip.SetBackdropBorderColor)) then
    tooltip:SetBackdropBorderColor(r, g, b, 1);
  end
end

function TooltipStyle:ApplyBackdrop(data, tooltipStyle, gameTooltip, tooltipsToReskin)
  local settings = data.settings;
  local bgFile = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.BACKGROUND, settings.backdrop.bgFile);
  local edgeFile = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.BORDER, settings.backdrop.edgeFile);

  if (obj:IsTable(data.tooltipBackdrop)) then
    obj:PushTable(data.tooltipBackdrop);
  end

  data.tooltipBackdrop = {};
  data.tooltipBackdrop.bgFile = bgFile;
  data.tooltipBackdrop.edgeFile = edgeFile;
  data.tooltipBackdrop.edgeSize = settings.backdrop.edgeSize;
  data.tooltipBackdrop.insets = settings.backdrop.insets;

  if (settings.useMuiTexture) then
    local closeBtn = _G.ItemRefCloseButton;

    if (obj:IsWidget(closeBtn)) then
      gui:ReskinIconButton(closeBtn, "cross");
      local scale = closeBtn:GetParent():GetScale();
      closeBtn:SetSize(28 / scale, 24 / scale);
      closeBtn:SetPoint("TOPRIGHT", -5, -4);
    end
  end

  for _, tooltipName in ipairs(tooltipsToReskin) do
    local tooltip = _G[tooltipName];

    if (obj:IsTable(tooltip) and obj:IsFunction(tooltip.GetObjectType)) then
      local scale = settings.scale;

      if (tooltip == _G.FriendsTooltip) then
        scale = scale + 0.2;
      end

      tooltip:SetScale(scale);

      if (tooltip.NineSlice) then
        tk:KillElement(tooltip.NineSlice);
      elseif (tooltip ~= gameTooltip) then
        self:EnsureBackdropSupport(tooltip);
      end

      if (settings.useMuiTexture) then
        if (self:EnsureBackdropSupport(tooltip)) then
          tooltip:SetBackdrop(nil);
        end

        if (not obj:IsFunction(tooltip.SetGridTextureShown)) then
          gui:AddDialogTexture(tooltip, "High", 10);
          tooltip:SetFrameStrata("TOOLTIP");
        end
      elseif (self:EnsureBackdropSupport(tooltip)) then
        tooltip:SetBackdrop(data.tooltipBackdrop);
      end

      if (obj:IsFunction(tooltip.SetGridTextureShown)) then
        tooltip:SetGridTextureShown(settings.useMuiTexture);
      end
    end
  end
end

obj:Export(TooltipStyle, "MayronUI.Tooltips.Style");
