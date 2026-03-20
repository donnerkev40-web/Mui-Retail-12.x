local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();
local UniversalWindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");

if (obj:Import("MayronUI.ChatModule.SideIcons", true)) then
  return;
end

local ChatSideIcons = obj:CreateInterface("ChatSideIcons", {});
local orderedChatAnchors = UniversalWindowTypes.OrderedChatAnchors;

function ChatSideIcons:NormalizeWindowType(settings, anchorName)
  local windowSettings = settings.chatFrames and settings.chatFrames[anchorName];
  local fallback = (windowSettings and windowSettings.enabled) and "chat" or "empty";
  return UniversalWindowTypes.NormalizeWindowType(windowSettings, fallback);
end

function ChatSideIcons:IsSidebarEligibleAnchor(settings, anchorName, windowType)
  local windowSettings = settings.chatFrames and settings.chatFrames[anchorName];

  return obj:IsTable(windowSettings)
    and windowSettings.enabled
    and self:NormalizeWindowType(settings, anchorName) == windowType;
end

function ChatSideIcons:GetSelectedWindowFrame(chatModule, settings, windowType, anchorName)
  local muiChatFrame = _G["MUI_ChatFrame_" .. anchorName];
  local activeAnchor = obj:IsFunction(chatModule.GetActiveWindowAnchor)
    and chatModule:GetActiveWindowAnchor(windowType);
  local selectedChatFrame;

  if (muiChatFrame and muiChatFrame:IsShown()
      and self:IsSidebarEligibleAnchor(settings, anchorName, windowType)) then
    selectedChatFrame = muiChatFrame;
  elseif (activeAnchor) then
    muiChatFrame = _G["MUI_ChatFrame_" .. activeAnchor];

    if (muiChatFrame and muiChatFrame:IsShown()
        and self:IsSidebarEligibleAnchor(settings, activeAnchor, windowType)) then
      selectedChatFrame = muiChatFrame;
    end
  end

  if (not selectedChatFrame) then
    for _, currentAnchorName in ipairs(orderedChatAnchors) do
      muiChatFrame = _G["MUI_ChatFrame_" .. currentAnchorName];

      if (muiChatFrame and muiChatFrame:IsShown()
          and self:IsSidebarEligibleAnchor(settings, currentAnchorName, windowType)) then
        selectedChatFrame = muiChatFrame;
        break;
      end
    end
  end

  return selectedChatFrame;
end

function ChatSideIcons:SetUpSideBarIcons(chatModule, settings, staticFrameApi)
  local chatFrameApi = obj:Import("MayronUI.ChatModule.ChatFrame", true);
  local resolvedStaticApi = staticFrameApi;

  if (not (obj:IsTable(resolvedStaticApi)
      and obj:IsFunction(resolvedStaticApi.PositionSideBarIcons))) then
    resolvedStaticApi = obj:IsTable(chatFrameApi) and chatFrameApi.Static or resolvedStaticApi;
  end

  if (not (obj:IsTable(resolvedStaticApi)
      and obj:IsFunction(resolvedStaticApi.PositionSideBarIcons))) then
    return;
  end

  local selectedChatFrame = self:GetSelectedWindowFrame(chatModule, settings, "chat", settings.iconsAnchor);
  local selectedUniversalFrame = self:GetSelectedWindowFrame(chatModule, settings,
    "action", settings.universalIconsAnchor);

  resolvedStaticApi:PositionSideBarIcons(settings.icons, selectedChatFrame, resolvedStaticApi.ChatIconTypes);
  resolvedStaticApi:PositionSideBarIcons(
    settings.universalIcons,
    selectedUniversalFrame,
    resolvedStaticApi.UniversalIconTypes
  );
end

obj:Export(ChatSideIcons, "MayronUI.ChatModule.SideIcons");
