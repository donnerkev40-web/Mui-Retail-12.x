-- luacheck: ignore self 143
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

local ipairs = _G.ipairs;
local FeatureState = obj:Import("MayronUI.FeatureState");

local WindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");
local Providers = obj:Import("MayronUI.UniversalWindow.Providers");
local Common = obj:Import("MayronUI.UniversalWindow.Common");

local orderedChatAnchors = WindowTypes.OrderedChatAnchors;
local NormalizeWindowType = WindowTypes.NormalizeWindowType;
local IsSafeWidget = Common.IsSafeWidget;

---@class UniversalWindowModule : BaseModule
local C_UniversalWindow = MayronUI:RegisterModule("UniversalWindowModule");

local function SyncChatSettings(data)
  if (obj:IsTable(data) and obj:IsTable(db.profile.chat)) then
    data.settings = db.profile.chat;
  end

  if (obj:IsTable(data) and obj:IsTable(data.chatData) and obj:IsTable(db.profile.chat)) then
    data.chatData.settings = db.profile.chat;
  end
end

local function GetActionWindowContext(data)
  SyncChatSettings(data);

  if (not (obj:IsTable(data.chatData) and obj:IsTable(data.chatData.chatFrames))) then
    return nil;
  end

  local chatData = data.chatData;
  local anchorName = chatData.activeActionAnchor;

  if (not anchorName) then
    for _, candidateAnchor in ipairs(orderedChatAnchors) do
      local settings = chatData.settings.chatFrames[candidateAnchor];

      if (obj:IsTable(settings)
          and settings.enabled
          and NormalizeWindowType(settings) == "action") then
        anchorName = candidateAnchor;
        chatData.activeActionAnchor = candidateAnchor;
        break;
      end
    end
  end

  if (not anchorName) then
    return nil;
  end

  local muiChatFrame = chatData.chatFrames[anchorName];
  local frame = muiChatFrame and muiChatFrame:GetFrame();
  local hostFrame = frame and frame.window
    and (frame.window.contentHost or frame.window);

  if (not (IsSafeWidget(frame, "Frame") and IsSafeWidget(hostFrame, "Frame") and frame:IsShown())) then
    return nil;
  end

  return anchorName, hostFrame, frame;
end

local function GetFallbackActionWindowContext()
  local chatSettings = db.profile.chat;
  local chatFrames = obj:IsTable(chatSettings) and chatSettings.chatFrames;

  if (not obj:IsTable(chatFrames)) then
    return nil;
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    local settings = chatFrames[anchorName];

    if (obj:IsTable(settings)
        and settings.enabled
        and NormalizeWindowType(settings) == "action") then
      local frame = _G["MUI_ChatFrame_" .. anchorName];
      local hostFrame = frame and frame.window
        and (frame.window.contentHost or frame.window);

      if (IsSafeWidget(frame, "Frame")
          and IsSafeWidget(hostFrame, "Frame")
          and frame:IsShown()) then
        return anchorName, hostFrame, frame;
      end
    end
  end
end

local function HideAllExternalContent(exceptKey)
  for _, contentType in ipairs(Providers:GetSupportedIconTypes()) do
    if (contentType ~= "none" and contentType ~= exceptKey) then
      local adapter = Providers:GetAdapter(contentType);

      if (obj:IsTable(adapter) and obj:IsFunction(adapter.Hide)) then
        -- Switching the visible Universal content should not shut down the
        -- underlying addon logic. Adapters therefore receive a "preserveState"
        -- flag and should only hide their visuals in this path.
        adapter:Hide(true);
      end
    end
  end
end

local function SetShellAppearance(shellFrame, contentType)
  if (not (IsSafeWidget(shellFrame, "Frame") and IsSafeWidget(shellFrame.window, "Frame"))) then
    return;
  end

  local metadata = Providers:GetMetadata(contentType);
  local transparentShell = obj:IsTable(metadata) and metadata.transparentShell;
  local hideShellTitle = obj:IsTable(metadata) and metadata.hideShellTitle;
  local title = obj:IsTable(metadata) and metadata.title or L["Universal Window"];

  if (IsSafeWidget(shellFrame.window.texture, "Texture")) then
    shellFrame.window.texture:SetAlpha(transparentShell and 0 or 1);
  end

  if (IsSafeWidget(shellFrame.actionTitle, "FontString")) then
    shellFrame.actionTitle:SetText(title);
    shellFrame.actionTitle:SetShown(shellFrame:IsShown() and not hideShellTitle);
  end
end

local function IsBoundChatContext(data)
  return obj:IsTable(data)
    and obj:IsTable(data.chatData)
    and obj:IsTable(data.chatData.settings)
    and obj:IsTable(data.chatData.chatFrames);
end

local function ResolveContext(self, data)
  if (IsBoundChatContext(data)) then
    return data;
  end

  if (IsBoundChatContext(self.data)) then
    return self.data;
  end
end

local function ResetToPreferredDefaultContent(data)
  SyncChatSettings(data);

  if (not (obj:IsTable(data)
      and obj:IsTable(data.chatData)
      and obj:IsTable(data.chatData.settings))) then
    return;
  end

  local preferredContent = Providers:GetPreferredDefaultContent();
  data.chatData.settings.universalContent = preferredContent;
  db:SetPathValue("profile.chat.universalContent", preferredContent);
end

function C_UniversalWindow:BindChatContext(chatModule, chatData)
  if (not obj:IsTable(chatData)) then
    return;
  end

  SyncChatSettings(chatData);
  chatData.chatModule = chatModule;
  chatData.chatData = chatData;
  self.data = chatData;

  if (chatData.listener) then
    return;
  end

  local watchedAddOns = Providers:GetWatchedAddOnNames();
  local listener = em:GetEventListenerByID("MUI_UniversalWindow_Update");

  if (not listener) then
    listener = em:CreateEventListenerWithID("MUI_UniversalWindow_Update", function(_, event, addonName)
      local context = ResolveContext(self);

      if (not IsBoundChatContext(context)) then
        return;
      end

      if (event == "PLAYER_ENTERING_WORLD") then
        -- Universal content should always boot into the preferred default
        -- instead of restoring a previously active provider from before reload.
        ResetToPreferredDefaultContent(context);
      end

      if (event == "ADDON_LOADED" and not watchedAddOns[addonName]) then
        return;
      end

      self:Refresh(context);
    end);

    listener:RegisterEvent("PLAYER_ENTERING_WORLD");
    listener:RegisterEvent("ADDON_LOADED");
  end

  chatData.listener = listener;
end

function C_UniversalWindow:SetContentType(data, contentType)
  if (not FeatureState:IsEnabled("chat.universal.enabled")) then
    HideAllExternalContent();
    return;
  end

  if (contentType == nil and obj:IsString(data)) then
    contentType = data;
    data = nil;
  end

  data = ResolveContext(self, data);
  SyncChatSettings(data);

  if (not (obj:IsTable(data)
      and obj:IsTable(data.chatData)
      and obj:IsTable(data.chatData.settings))) then
    if (contentType ~= nil) then
      db:SetPathValue("profile.chat.universalContent", Providers:GetCurrentContent(contentType));
      self:Refresh({
        chatData = {
          settings = db.profile.chat;
          chatFrames = {};
        };
      });
    end

    return;
  end

  local normalizedContent = Providers:GetCurrentContent(contentType);
  local currentContent = Providers:GetCurrentContent(data.chatData.settings.universalContent);

  data.chatData.settings.universalContent = normalizedContent;

  if (currentContent == normalizedContent) then
    self:Refresh(data);

    if (obj:IsTable(data.chatModule) and obj:IsFunction(data.chatModule.RefreshSideBarIcons)) then
      data.chatModule:RefreshSideBarIcons();
    end

    return;
  end

  db:SetPathValue("profile.chat.universalContent", normalizedContent);

  self:Refresh(data);

  if (obj:IsTable(data.chatModule) and obj:IsFunction(data.chatModule.RefreshSideBarIcons)) then
    data.chatModule:RefreshSideBarIcons();
  end
end

function C_UniversalWindow:Refresh(data)
  data = ResolveContext(self, data);
  SyncChatSettings(data);

  if (not tk:IsRetail()) then
    return;
  end

  if (not FeatureState:IsEnabled("chat.universal.enabled")) then
    HideAllExternalContent();
    return;
  end

  if (not (obj:IsTable(data)
      and obj:IsTable(data.chatData)
      and obj:IsTable(data.chatData.settings))) then
    if (obj:IsTable(db.profile.chat)) then
      data = {
        chatData = {
          settings = db.profile.chat;
          chatFrames = {};
        };
      };
    else
      HideAllExternalContent();
      return;
    end
  end

  local anchorName, hostFrame, shellFrame = GetActionWindowContext(data);
  local chatData = data.chatData;

  if (not anchorName) then
    anchorName, hostFrame, shellFrame = GetFallbackActionWindowContext();
  end

  if (not obj:IsTable(chatData) or not obj:IsTable(chatData.settings)) then
    chatData = data;
  end

  local currentValue = obj:IsTable(chatData.settings) and chatData.settings.universalContent
    or db.profile.chat.universalContent;
  local universalContent = Providers:GetCurrentContent(currentValue);

  if (not IsSafeWidget(hostFrame, "Frame")) then
    HideAllExternalContent();
    return;
  end

  SetShellAppearance(shellFrame, universalContent);

  local adapter = Providers:GetAdapter(universalContent);
  local success = false;

  if (universalContent == "none") then
    HideAllExternalContent();
    return;
  end

  if (obj:IsFunction(adapter.Show)) then
    local ok, result = pcall(function()
      return adapter:Show(hostFrame, shellFrame, anchorName);
    end);

    success = ok and result == true;
  end

  if (success) then
    HideAllExternalContent(universalContent);
  else
    SetShellAppearance(shellFrame, "none");
  end
end
