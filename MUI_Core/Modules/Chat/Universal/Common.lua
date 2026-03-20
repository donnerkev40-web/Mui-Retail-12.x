local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (obj:Import("MayronUI.UniversalWindow.Common", true)) then
  return;
end

local math_floor, math_ceil = _G.math.floor, _G.math.ceil;
local Common = obj:CreateInterface("UniversalWindowCommon", {});

function Common.IsSafeWidget(value, widgetType)
  if (type(value) ~= "table") then
    return false;
  end

  if (type(value.IsObjectType) ~= "function") then
    if (obj:IsWidget(value)) then
      return true;
    end

    return false;
  end

  if (type(widgetType) == "string") then
    local ok, isWidget = pcall(function()
      return value:IsObjectType(widgetType);
    end);

    return ok and isWidget == true;
  end

  local ok, isWidget = pcall(function()
    return value:IsObjectType("Frame");
  end);

  if (ok and isWidget) then
    return true;
  end

  ok, isWidget = pcall(function()
    return value:IsObjectType("Texture");
  end);

  if (ok and isWidget) then
    return true;
  end

  ok, isWidget = pcall(function()
    return value:IsObjectType("FontString");
  end);

  return ok and isWidget == true;
end

function Common.CallOriginalWidgetMethod(widget, methodName, ...)
  if (type(widget) ~= "table" or type(methodName) ~= "string") then
    return false;
  end

  local meta = getmetatable(widget);
  local index = type(meta) == "table" and meta.__index;
  local method;

  if (type(index) == "table") then
    method = index[methodName];
  end

  if (type(method) ~= "function") then
    return false;
  end

  return pcall(method, widget, ...);
end

function Common.SetPassiveVisibility(widget, visible)
  if (type(widget) ~= "table") then
    return false;
  end

  local alpha = visible and 1 or 0;
  local success = false;

  if (Common.CallOriginalWidgetMethod(widget, "SetAlpha", alpha)) then
    success = true;
  elseif (type(widget.SetAlpha) == "function") then
    success = pcall(function()
      widget:SetAlpha(alpha);
    end);
  end

  return success;
end

function Common.RoundNearest(value)
  if (not obj:IsNumber(value)) then
    return 0;
  end

  if (value < 0) then
    return math_ceil(value - 0.5);
  end

  return math_floor(value + 0.5);
end

obj:Export(Common, "MayronUI.UniversalWindow.Common");
