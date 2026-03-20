-- luacheck: ignore MayronUI self 143 631
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local C_Timer, GameTooltip, string, table, math = _G.C_Timer, _G.GameTooltip, _G.string, _G.table, _G.math;
local GetNetStats, GetFramerate = _G.GetNetStats, _G.GetFramerate;
local GetNumAddOns = _G.GetNumAddOns;
local GetAddOnInfo = _G.GetAddOnInfo;
local GetAddOnMemoryUsage = _G.GetAddOnMemoryUsage;
local UpdateAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage;
local GetAddOnCPUUsage = _G.GetAddOnCPUUsage;
local UpdateAddOnCPUUsage = _G.UpdateAddOnCPUUsage;
local GetCVar = _G.GetCVar;
local collectgarbage = _G.collectgarbage;

-- Register and Import Modules -------
local Performance = obj:CreateClass("Performance");
local MAX_TOOLTIP_ROWS = 10;
local TOOLTIP_CACHE_DURATION = 1;

-- Load Database Defaults ------------

db:AddToDefaults("profile.datatext.performance", {
  showFps = true,
  showHomeLatency = true,
  showServerLatency = false
});

-- Performance Module --------------

MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
  local sv = db.profile.datatext.performance;
  sv:SetParent(db.profile.datatext);

  local settings = sv:GetTrackedTable();
  self:RegisterComponentClass("performance", Performance, settings);
end);

function Performance:__Construct(data, settings, dataTextModule)
  data.settings = settings;
  self.TotalLabelsShown = 0;
  self.HasLeftMenu = false;
  self.HasRightMenu = false;
  self.Button = dataTextModule:CreateDataTextButton();
end

function Performance:IsEnabled(data)
  return data.enabled;
end

local function FormatLabelByLatency(label, latency)
    if (latency <= 100) then
        label = string.format("%s |cff32cd32%u|r ms", label, latency);
    end

    if (latency >= 101 and latency <= 250) then
        label = string.format("%s |cffffcc00%u|r ms", label, latency);
    end

    if (latency >= 251) then
        label = string.format("%s |cffff0000%u|r ms", label, latency);
    end

    return label;
end

local function FormatMemoryValue(memoryUsage)
  if (memoryUsage >= 1000) then
    return string.format("%.2f mb", memoryUsage / 1000);
  end

  return string.format("%.0f kb", memoryUsage);
end

local function FormatCPUValue(cpuUsage)
  if (type(cpuUsage) ~= "number") then
    return L["Unavailable"];
  end

  if (cpuUsage >= 100) then
    return string.format("%.0f ms", cpuUsage);
  elseif (cpuUsage >= 10) then
    return string.format("%.1f ms", cpuUsage);
  end

  return string.format("%.2f ms", cpuUsage);
end

local function CompareMemory(a, b)
  return a.memory > b.memory;
end

local function CompareCPU(a, b)
  return a.cpu > b.cpu;
end

local cachedTooltipSnapshot;
local tooltipPinnedByClick = false;

local function GetTooltipSnapshot()
  local now = _G.GetTime and _G.GetTime() or 0;

  if (cachedTooltipSnapshot and (now - cachedTooltipSnapshot.createdAt) < TOOLTIP_CACHE_DURATION) then
    return cachedTooltipSnapshot;
  end

  local _, _, latencyHome, latencyServer = GetNetStats();
  local cpuProfilingEnabled = GetCVar and GetCVar("scriptProfile") == "1";
  local memoryRows = {};
  local cpuRows = {};
  local totalMemory = 0;
  local totalCPU = 0;

  UpdateAddOnMemoryUsage();

  if (cpuProfilingEnabled and UpdateAddOnCPUUsage) then
    pcall(UpdateAddOnCPUUsage);
  end

  for i = 1, GetNumAddOns() do
    local addOnName, addOnTitle = GetAddOnInfo(i);
    local displayName = addOnTitle or addOnName or ("AddOn " .. tostring(i));
    local memoryUsage = GetAddOnMemoryUsage(i) or 0;
    local cpuUsage = cpuProfilingEnabled and GetAddOnCPUUsage and GetAddOnCPUUsage(i) or 0;

    totalMemory = totalMemory + memoryUsage;
    totalCPU = totalCPU + cpuUsage;

    if (memoryUsage > 0) then
      table.insert(memoryRows, {
        name = displayName;
        memory = memoryUsage;
      });
    end

    if (cpuProfilingEnabled and cpuUsage > 0) then
      table.insert(cpuRows, {
        name = displayName;
        cpu = cpuUsage;
      });
    end
  end

  table.sort(memoryRows, CompareMemory);
  if (cpuProfilingEnabled) then
    table.sort(cpuRows, CompareCPU);
  end

  cachedTooltipSnapshot = {
    createdAt = now;
    latencyHome = latencyHome;
    latencyServer = latencyServer;
    cpuProfilingEnabled = cpuProfilingEnabled;
    totalMemory = totalMemory;
    totalCPU = totalCPU;
    memoryRows = memoryRows;
    cpuRows = cpuRows;
  };

  return cachedTooltipSnapshot;
end

local function ButtonOnEnter(self)
  local r, g, b = tk:GetThemeColor();
  local snapshot = GetTooltipSnapshot();

  GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 2);
  GameTooltip:SetText(L["Performance Overview"]);
  GameTooltip:AddLine(" ");
  GameTooltip:AddDoubleLine(tk.Strings:SetTextColorByTheme(L["Left Click:"]), L["Show Overview"], r, g, b, 1, 1, 1);
  GameTooltip:AddDoubleLine(tk.Strings:SetTextColorByTheme(L["Right Click:"]), L["No Action"], r, g, b, 1, 1, 1);
  GameTooltip:AddLine(" ");
  GameTooltip:AddDoubleLine(L["FPS"], string.format("%.0f", GetFramerate()), r, g, b, 1, 1, 1);
  GameTooltip:AddDoubleLine(L["Home"], string.format("%d ms", snapshot.latencyHome), r, g, b, 1, 1, 1);
  GameTooltip:AddDoubleLine(L["Server"], string.format("%d ms", snapshot.latencyServer), r, g, b, 1, 1, 1);
  GameTooltip:AddDoubleLine(L["Total AddOn Memory"], FormatMemoryValue(snapshot.totalMemory), r, g, b, 1, 1, 1);

  if (collectgarbage) then
    GameTooltip:AddDoubleLine(L["Lua Memory"], FormatMemoryValue(collectgarbage("count") or 0), r, g, b, 1, 1, 1);
  end

  if (snapshot.cpuProfilingEnabled) then
    GameTooltip:AddDoubleLine(L["Total AddOn CPU"], FormatCPUValue(snapshot.totalCPU), r, g, b, 1, 1, 1);
  else
    GameTooltip:AddLine(" ");
    GameTooltip:AddLine(L["CPU Profiling Disabled"]);
  end

  GameTooltip:AddLine(" ");
  GameTooltip:AddLine(L["Top Memory AddOns"]);

  for i = 1, math.min(#snapshot.memoryRows, MAX_TOOLTIP_ROWS) do
    local row = snapshot.memoryRows[i];
    GameTooltip:AddDoubleLine(row.name, FormatMemoryValue(row.memory), 1, 1, 1, 1, 1, 1);
  end

  if (snapshot.cpuProfilingEnabled and #snapshot.cpuRows > 0) then
    GameTooltip:AddLine(" ");
    GameTooltip:AddLine(L["Top CPU AddOns"]);

    for i = 1, math.min(#snapshot.cpuRows, MAX_TOOLTIP_ROWS) do
      local row = snapshot.cpuRows[i];
      GameTooltip:AddDoubleLine(row.name, FormatCPUValue(row.cpu), 1, 1, 1, 1, 1, 1);
    end
  end

  GameTooltip:Show();
end

function Performance:Update(data, refreshSettings)
  if (refreshSettings) then
    data.settings:Refresh();
  end

  if (data.executed) then return end

  data.executed = true;

  local function loop()
    if (not data.enabled) then return end
    local _, _, latencyHome, latencyServer = GetNetStats();

    local label = "";

    if (data.settings.showFps) then
      label = string.format("|cffffffff%u|r fps", GetFramerate());
    end

    if (data.settings.showHomeLatency) then
      label = FormatLabelByLatency(label, latencyHome);
    end
    if (data.settings.showServerLatency) then
      label = FormatLabelByLatency(label, latencyServer);
    end

    self.Button:SetText(label:trim());

    C_Timer.After(3, loop);
  end

  loop();
end

function Performance:Click(_, button)
  if (button ~= "LeftButton") then
    return;
  end

  if (tooltipPinnedByClick and GameTooltip:IsOwned(self.Button)) then
    tooltipPinnedByClick = false;
    GameTooltip:Hide();
    return true;
  end

  tooltipPinnedByClick = true;
  ButtonOnEnter(self.Button);
  return true;
end

function Performance:SetEnabled(data, enabled)
  data.enabled = enabled;

  if (enabled) then
    self.Button:RegisterForClicks("LeftButtonUp");
    self.Button:SetScript("OnEnter", nil);
    self.Button:SetScript("OnLeave", nil);
  else
    data.executed = nil;
    tooltipPinnedByClick = false;
    GameTooltip:Hide();
    self.Button:SetScript("OnEnter", nil);
    self.Button:SetScript("OnLeave", nil);
  end
end
