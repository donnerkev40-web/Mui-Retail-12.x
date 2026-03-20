-- luacheck: ignore self 143
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, _, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

local ChatFrame1, ChatFrame1EditBox, NUM_CHAT_WINDOWS =
  _G.ChatFrame1, _G.ChatFrame1EditBox, _G.NUM_CHAT_WINDOWS;
local InCombatLockdown, StaticPopupDialogs, hooksecurefunc, pairs, PlaySound =
 _G.InCombatLockdown, _G.StaticPopupDialogs, _G.hooksecurefunc, _G.pairs, _G.PlaySound;
local strformat, ipairs = _G.string.format, _G.ipairs;
local FCF_StopDragging, EditModeManagerFrame, C_EditMode =
  _G.FCF_StopDragging, _G.EditModeManagerFrame, _G.C_EditMode;
local C_Timer = _G.C_Timer;
local FCF_SetLocked = _G.FCF_SetLocked;
local IsAddOnLoaded, IsInRaid, IsInGroup, GetNumGroupMembers =
  _G.IsAddOnLoaded, _G.IsInRaid, _G.IsInGroup, _G.GetNumGroupMembers;
--------------------------
-- Blizzard Globals
--------------------------
_G.CHAT_FONT_HEIGHTS = obj:PopTable(8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);

-- Objects ------------------
---@class ChatFrame
local C_ChatFrame = obj:CreateClass("ChatFrame");
obj:Export(C_ChatFrame, "MayronUI.ChatModule");

---@class ChatModule : BaseModule
local C_ChatModule = MayronUI:RegisterModule("ChatModule", L["Chat"]);
local UniversalWindowTypes = obj:Import("MayronUI.UniversalWindow.WindowTypes");
local UniversalProviders = obj:Import("MayronUI.UniversalWindow.Providers");
local FeatureState = obj:Import("MayronUI.FeatureState");
local Grid2Bridge = obj:Import("MayronUI.Chat.Grid2.Bridge");
local ChatMigrations = obj:Import("MayronUI.ChatModule.Migrations");
local LayoutManager = obj:Import("MayronUI.LayoutManager");
local orderedChatAnchors = UniversalWindowTypes.OrderedChatAnchors;
local NormalizeWindowType = UniversalWindowTypes.NormalizeWindowType;
local NormalizeUniversalContentType = UniversalProviders.NormalizeContentType;

-- Database Defaults -----------------
local defaults = {
	enabled = true;
	swapInCombat = false;
	chatFrames = {
		-- these tables will contain the templateMuiChatFrame data (using SetParent)
		TOPLEFT = {
      enabled = false;
      windowType = "empty";
      xOffset = 2;
      yOffset = -2;
    };

		TOPRIGHT = {
      enabled = false;
      windowType = "empty";
      xOffset = -2;
      yOffset = -2;
    };

		BOTTOMLEFT = {
      enabled = true;
      windowType = "chat";
      xOffset = 2;
      yOffset = 2;
      buttons = {
        {
          L["Character"];
          L["Player Spells"];
          L["Dungeon Finder"];
        };
        {
          key = "C";
          L["Friends"];
          L["Guild"];
          L["Help Menu"];
        };
        {
          key = "S";
          L["PVP"];
          L["Quest Log"];
          L["Calendar"];
        };
        {
          key = "A";
          L["Macros"];
          L["World Map"];
          L["Main Menu"];
        };
        {
          key = "CS";
          L["Reputation"];
          L["PVP Score"];
          L["Currency"];
        };
      };
			tabBar = {
				yOffset = -35;
			};
			window = {
				yOffset = 12;
			}
    };

		BOTTOMRIGHT = {
      enabled = true;
      windowType = "action";
      xOffset = -2;
      yOffset = 2;
      buttons = {
        {
          L["Achievements"];
          L["Collections Journal"];
          L["Adventure Guide"];
        };
        {
          key = "C";
          L["Professions"];
          L["Store"];
          L["Character"];
        };
        {
          key = "S";
          L["Player Spells"];
          L["Dungeon Finder"];
          L["Quest Log"];
        };
        {
          key = "A";
          L["Friends"];
          L["Guild"];
          L["Help Menu"];
        };
      };
			tabBar = {
				yOffset = -35;
			};
			window = {
				yOffset = 12;
			}
		};
  };

  iconsAnchor = "BOTTOMLEFT"; -- which chat frame to align them to
  universalIconsAnchor = "BOTTOMRIGHT";
  iconsWindowType = "chat";
  universalContent = "kalielsTracker";
	icons = {
    { type = "voiceChat" };
    -- optional:
    -- { type = "deafen" };
    -- { type = "mute" };
    { type = "professions" };
    { type = "shortcuts" };
    { type = "copyChat" };
    { type = "emotes" };
    { type = "playerStatus" };
  };
  universalIcons = {
    { type = "kalielsTracker" };
    { type = "moneyLooter" };
    { type = "damageMeter" };
    { type = "zygorGuides" };
    { type = "none" };
    { type = "none" };
  };

  brightness = 0.7;
  enableAliases = true;
  aliases = {
    [_G.CHAT_MSG_GUILD] = _G.CHAT_MSG_GUILD:gsub("[a-z%s]", tk.Strings.Empty);
    [_G.CHAT_MSG_OFFICER] = _G.CHAT_MSG_OFFICER:gsub("[a-z%s]", tk.Strings.Empty);

    [_G.CHAT_MSG_PARTY] = _G.CHAT_MSG_PARTY:gsub("[a-z%s]", tk.Strings.Empty);
    [_G.CHAT_MSG_PARTY_LEADER] = _G.CHAT_MSG_PARTY_LEADER:gsub("[a-z%s]", tk.Strings.Empty);

    [_G.CHAT_MSG_RAID] = _G.CHAT_MSG_RAID:gsub("[a-z%s]", tk.Strings.Empty);
    [_G.CHAT_MSG_RAID_LEADER] = _G.CHAT_MSG_RAID_LEADER:gsub("[a-z%s]", tk.Strings.Empty);
    [_G.CHAT_MSG_RAID_WARNING] = _G.CHAT_MSG_RAID_WARNING:gsub("[a-z%s]", tk.Strings.Empty);

    [_G.INSTANCE_CHAT] = _G.INSTANCE_CHAT:gsub("[a-z%s]", tk.Strings.Empty);
    [_G.INSTANCE_CHAT_LEADER] = _G.INSTANCE_CHAT_LEADER:gsub("[a-z%s]", tk.Strings.Empty);
  };

  useTimestampColor = true;
  timestampColor = {
    r = 0.6; g = 0.6; b = 0.6;
  };

  editBox = {
    yOffset = -8;
    height = 27;
    position = "BOTTOM";
  };

	__templateChatFrame = {
    sidebarHeight = 300;
    buttons = {
      {
        L["Character"];
        L["Player Spells"];
        L["Professions"];
      };
      {
        key = "C"; -- CONTROL
        L["Reputation"];
        L[(tk:IsRetail() and "Dungeon Finder") or (tk:IsWrathClassic() and "LFG") or "Skills"];
        L["World Map"];
      };
      {
        key = "S"; -- SHIFT
        L[((tk:IsRetail() or tk:IsWrathClassic()) and "Achievements") or "Friends"];
        L[(tk:IsRetail() and "Collections Journal") or (tk:IsWrathClassic() and "Currency") or "Guild"];
        L[(tk:IsRetail() and "Adventure Guide") or "Macros"];
      };
    };

		tabBar = {
			show = true;
			yOffset = -12;
    };

		window = {
      width = 367;
      height = 248;
			yOffset = -37;
		}
	};
};

db:AddToDefaults("profile.chat", defaults);

local defaultChatSideBarIconTypes = {
  "voiceChat";
  "professions";
  "shortcuts";
  "copyChat";
  "emotes";
  "playerStatus";
};

local supportedChatSideBarIconTypes = tk:IsRetail() and {
  "voiceChat";
  "deafen";
  "mute";
  "professions";
  "shortcuts";
  "copyChat";
  "emotes";
  "playerStatus";
  "none";
} or {
  "voiceChat";
  "professions";
  "shortcuts";
  "copyChat";
  "emotes";
  "playerStatus";
  "none";
};

local defaultUniversalSideBarIconTypes = UniversalProviders:GetDefaultSidebarTypes();
local supportedUniversalSideBarIconTypes = UniversalProviders:GetSupportedIconTypes();

local function NormalizeSideBarIcons(iconSettings, defaultIconTypes, supportedIconTypes)
  local normalized = {};
  local used = {};
  local supported = {};

  for _, iconType in ipairs(supportedIconTypes) do
    supported[iconType] = true;
  end

  for index = 1, #defaultIconTypes do
    local value = obj:IsTable(iconSettings) and iconSettings[index];
    local iconType = obj:IsTable(value) and value.type;
    local useCurrent = obj:IsString(iconType) and supported[iconType]
      and (iconType == "none" or not used[iconType]);

    if (useCurrent) then
      normalized[index] = { type = iconType };

      if (iconType ~= "none") then
        used[iconType] = true;
      end
    else
      local fallback = "none";

      for _, fallbackType in ipairs(defaultIconTypes) do
        if (not used[fallbackType]) then
          fallback = fallbackType;

          if (fallbackType ~= "none") then
            used[fallbackType] = true;
          end

          break;
        end
      end

      normalized[index] = { type = fallback };
    end
  end

  return normalized;
end

local function NormalizeChatSideBarIcons(iconSettings)
  return NormalizeSideBarIcons(iconSettings, defaultChatSideBarIconTypes, supportedChatSideBarIconTypes);
end

local function NormalizeUniversalSideBarIcons(iconSettings)
  return NormalizeSideBarIcons(iconSettings, defaultUniversalSideBarIconTypes,
    supportedUniversalSideBarIconTypes);
end

-- Chat Module -------------------

local function LoadEditBoxBackdrop()
  if (obj:IsFunction(ChatFrame1EditBox.OnBackdropLoaded)) then
    ChatFrame1EditBox:OnBackdropLoaded();
  end
end

local function ApplyEditBoxAppearance(data, settings)
  if (not (obj:IsWidget(ChatFrame1EditBox)
      and obj:IsTable(data)
      and obj:IsTable(data.editBoxBackdrop))) then
    return;
  end

  data.editBoxBackdrop.edgeFile = tk.Constants.BACKDROP.edgeFile;
  data.editBoxBackdrop.edgeSize = tk.Constants.BACKDROP.edgeSize;
  data.editBoxBackdrop.insets.left = 0;
  data.editBoxBackdrop.insets.right = 0;
  data.editBoxBackdrop.insets.top = 0;
  data.editBoxBackdrop.insets.bottom = 0;

  ChatFrame1EditBox.backdropInfo = data.editBoxBackdrop;
  ChatFrame1EditBox:SetBackdrop(data.editBoxBackdrop);
  LoadEditBoxBackdrop();

  ChatFrame1EditBox:SetBackdropColor(0, 0, 0, 0.6);

  local chatType = ChatFrame1EditBox:GetAttribute("chatType");
  local r, g, b = _G.GetMessageTypeColor(chatType);
  if (r and g and b) then
    ChatFrame1EditBox:SetBackdropBorderColor(r, g, b, 1);
  else
    ChatFrame1EditBox:SetBackdropBorderColor(1, 1, 1, 1);
  end
end

local function ApplyEditBoxLayout(settings)
  if (not (obj:IsWidget(ChatFrame1EditBox) and obj:IsTable(settings) and obj:IsTable(settings.editBox))) then
    return;
  end

  local editBoxSettings = settings.editBox;
  local yOffset = tonumber(editBoxSettings.yOffset) or 8;
  local height = tonumber(editBoxSettings.height) or 27;
  local position = editBoxSettings.position;

  ChatFrame1EditBox:ClearAllPoints();
  ChatFrame1EditBox:SetHeight(height);

  if (position == "BOTTOM") then
    ChatFrame1EditBox:SetPoint("TOPLEFT", _G.ChatFrame1, "BOTTOMLEFT", -3, yOffset);
    ChatFrame1EditBox:SetPoint("TOPRIGHT", _G.ChatFrame1, "BOTTOMRIGHT", 3, yOffset);
  else
    ChatFrame1EditBox:SetPoint("BOTTOMLEFT", _G.ChatFrame1, "TOPLEFT", -3, yOffset);
    ChatFrame1EditBox:SetPoint("BOTTOMRIGHT", _G.ChatFrame1, "TOPRIGHT", 3, yOffset);
  end
end

local function GetUniversalWindowModule()
  return MayronUI:ImportModule("UniversalWindowModule", true);
end

local function GetEnabledChatAnchor(chatFrames, preferredAnchor)
  local function IsChatAnchor(anchorName)
    local settings = chatFrames[anchorName];
    return obj:IsTable(settings)
      and settings.enabled
      and NormalizeWindowType(settings) == "chat";
  end

  if (preferredAnchor and IsChatAnchor(preferredAnchor)) then
    return preferredAnchor;
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    if (IsChatAnchor(anchorName)) then
      return anchorName;
    end
  end
end

local function GetEnabledAnchorByType(chatFrames, windowType, preferredAnchor)
  local function Matches(anchorName)
    local settings = chatFrames[anchorName];
    return obj:IsTable(settings)
      and settings.enabled
      and NormalizeWindowType(settings) == windowType;
  end

  if (preferredAnchor and obj:IsTable(chatFrames[preferredAnchor])
      and Matches(preferredAnchor)) then
    return preferredAnchor;
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    if (Matches(anchorName)) then
      return anchorName;
    end
  end
end

local SetPrimaryChatFramePosition;

local function GetOrCreateUniversalAnchor(data, anchorName)
  data.windowAnchors = data.windowAnchors or obj:PopTable();

  if (not data.windowAnchors[anchorName]) then
    local anchor = tk:CreateFrame("Frame", _G.UIParent, "MUI_ActionWindowAnchor_" .. anchorName);
    anchor:SetSize(1, 1);
    data.windowAnchors[anchorName] = anchor;
  end

  return data.windowAnchors[anchorName];
end

local function PositionUniversalAnchor(data, anchorName)
  if (not (obj:IsTable(data)
      and obj:IsTable(data.settings)
      and obj:IsTable(data.settings.chatFrames)
      and obj:IsTable(data.settings.chatFrames[anchorName]))) then
    return;
  end

  local settings = data.settings.chatFrames[anchorName];
  local anchor = GetOrCreateUniversalAnchor(data, anchorName);

  if (InCombatLockdown()) then
    return anchor;
  end

  anchor:ClearAllPoints();
  anchor:SetPoint(anchorName, _G.UIParent, anchorName, settings.xOffset, settings.yOffset);
  anchor:SetShown(settings.enabled and NormalizeWindowType(settings) ~= "empty");
  return anchor;
end

local function RefreshActionWindowContent(module, data)
  if (not tk:IsRetail()) then
    return;
  end

  if (not (obj:IsTable(data)
      and obj:IsTable(data.settings)
      and obj:IsTable(data.settings.chatFrames))) then
    return;
  end

  data.activeActionAnchor = GetEnabledAnchorByType(
    data.settings.chatFrames, "action", data.activeActionAnchor
  );

  local universalWindowModule = GetUniversalWindowModule();

  if (obj:IsTable(universalWindowModule) and obj:IsFunction(universalWindowModule.BindChatContext)) then
    universalWindowModule:BindChatContext(module, data);
  end

  if (obj:IsTable(universalWindowModule) and obj:IsFunction(universalWindowModule.Refresh)) then
    universalWindowModule:Refresh();
  end
end

local function RefreshGrid2WindowContent(_, data)
  if (not tk:IsRetail()) then
    if (obj:IsTable(Grid2Bridge) and obj:IsFunction(Grid2Bridge.Hide)) then
      Grid2Bridge:Hide();
    end

    return;
  end

  data.activeGrid2Anchor = GetEnabledAnchorByType(
    data.settings.chatFrames, "grid2", data.activeGrid2Anchor
  );

  if (not (obj:IsTable(Grid2Bridge) and obj:IsFunction(Grid2Bridge.Refresh))) then
    return;
  end

  if (data.activeGrid2Anchor) then
    data.grid2RefreshToken = (data.grid2RefreshToken or 0) + 1;
    local refreshToken = data.grid2RefreshToken;

    Grid2Bridge:Refresh(data, data.activeGrid2Anchor);

    local function RetryAfter(delay)
      C_Timer.After(delay, function()
        if (data.grid2RefreshToken ~= refreshToken) then
          return;
        end

        if (InCombatLockdown()) then
          return;
        end

        if (data.activeGrid2Anchor
            and obj:IsTable(Grid2Bridge)
            and obj:IsFunction(Grid2Bridge.Refresh)) then
          Grid2Bridge:Refresh(data, data.activeGrid2Anchor);
        end
      end);
    end

    -- Grid2 finalizes parts of its layout after its own world/roster init.
    -- Re-embedding shortly afterwards avoids ending up with an empty host if
    -- MUI refreshed slightly too early.
    RetryAfter(0.2);
    RetryAfter(1.0);
  elseif (obj:IsFunction(Grid2Bridge.Hide)) then
    data.grid2RefreshToken = (data.grid2RefreshToken or 0) + 1;
    Grid2Bridge:Hide();
  end
end

local function RefreshUniversalWindowSlots(module, data)
  for _, anchorName in ipairs(orderedChatAnchors) do
    local settings = data.settings.chatFrames[anchorName];
    local muiChatFrame = data.chatFrames[anchorName];
    local usesShell = ChatMigrations:UsesChatShell(settings);

    settings.windowType = NormalizeWindowType(settings);
    PositionUniversalAnchor(data, anchorName);

    if (usesShell and not muiChatFrame) then
      muiChatFrame = C_ChatFrame(anchorName, module, data.settings);
      data.chatFrames[anchorName] = muiChatFrame;
    end

    if (muiChatFrame) then
      if (obj:IsFunction(muiChatFrame.SetWindowType)) then
        muiChatFrame:SetWindowType(settings.windowType);
      end

      muiChatFrame:SetEnabled(usesShell);
    end
  end

  data.activeChatAnchor = GetEnabledChatAnchor(data.settings.chatFrames, data.activeChatAnchor);
  SetPrimaryChatFramePosition(data, data.activeChatAnchor);
  RefreshActionWindowContent(module, data);
  RefreshGrid2WindowContent(module, data);
  C_ChatFrame.Static:SetUpSideBarIcons(module, data.settings);
end

local function ApplyCurrentPhaseChatWindowPolicy(chatSettings)
  if (not obj:IsTable(chatSettings) or not obj:IsTable(chatSettings.chatFrames)) then
    return;
  end

  if (FeatureState:IsEnabled("chat.universal.enabled")) then
    return;
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    local settings = chatSettings.chatFrames[anchorName];

    if (obj:IsTable(settings)) then
      local windowType = NormalizeWindowType(settings);

      if (windowType == "action" or windowType == "grid2") then
        settings.enabled = false;
        settings.windowType = "empty";
      end
    end
  end

  if (obj:IsTable(chatSettings.chatFrames.BOTTOMLEFT)) then
    chatSettings.chatFrames.BOTTOMLEFT.enabled = true;
    chatSettings.chatFrames.BOTTOMLEFT.windowType = "chat";
  end

  chatSettings.iconsAnchor = "BOTTOMLEFT";
  chatSettings.iconsWindowType = "chat";
  chatSettings.universalContent = "none";
end

local function UpdateDockedChatTabs()
  local dock = _G.GENERAL_CHAT_DOCK;
  if (not (obj:IsWidget(dock) and obj:IsTable(dock.DOCKED_CHAT_FRAMES))) then
    return;
  end

  local prev;

  for _, chatFrame in ipairs(dock.DOCKED_CHAT_FRAMES) do
    local chatTab = _G[chatFrame:GetName() .. "Tab"];

    if (obj:IsWidget(chatTab)) then
      pcall(chatTab.ClearAllPoints, chatTab);

      if (prev) then
        pcall(chatTab.SetPoint, chatTab, "LEFT", prev, "RIGHT", 1, 0);
      else
        pcall(chatTab.SetPoint, chatTab, "BOTTOMLEFT", dock, "BOTTOMLEFT", 0, 0);
      end

      prev = chatTab;
    end
  end

  for _, chatFrameName in ipairs(_G.CHAT_FRAMES) do
    local chatTab = _G[chatFrameName .. "Tab"];

    if (obj:IsWidget(chatTab) and obj:IsWidget(chatTab:GetFontString())) then
      chatTab:SetAlpha(1);
      chatTab:SetWidth(chatTab:GetFontString():GetStringWidth() + 28);
      chatTab:SetFrameStrata(tk.Constants.FRAME_STRATAS.MEDIUM);
    end
  end
end

local function SyncChatTabTexture(frame, anchorName)
  local tabs = frame and frame.tabs;
  local dock = _G.GENERAL_CHAT_DOCK;

  if (not (obj:IsWidget(tabs) and tabs:IsShown() and obj:IsWidget(dock))) then
    return;
  end

  pcall(tabs.ClearAllPoints, tabs);
  pcall(tabs.SetPoint, tabs, "BOTTOMLEFT", dock, "BOTTOMLEFT", -14, -4);
  pcall(tabs.SetPoint, tabs, "TOPRIGHT", dock, "TOPRIGHT", 14, 6);

  if (tk.Strings:Contains(anchorName, "RIGHT")) then
    tabs:SetTexCoord(1, 0, 0, 1);
  else
    tabs:SetTexCoord(0, 1, 0, 1);
  end
end

local function PositionChatDock(frame, anchorName)
  local dock = _G.GENERAL_CHAT_DOCK;

  if (not (obj:IsWidget(dock) and obj:IsWidget(ChatFrame1))) then
    return;
  end

  pcall(dock.ClearAllPoints, dock);

  if (obj:IsWidget(frame) and obj:IsWidget(frame.tabs) and frame.tabs:IsShown()
      and tk.Strings:Contains(anchorName, "BOTTOM")) then
    pcall(dock.SetPoint, dock, "BOTTOMLEFT", frame.tabs, "BOTTOMLEFT", 14, 3);
    pcall(dock.SetPoint, dock, "BOTTOMRIGHT", frame.tabs, "BOTTOMRIGHT", -14, 3);
  else
    pcall(dock.SetPoint, dock, "BOTTOMLEFT", ChatFrame1, "TOPLEFT", 16, 12);
    pcall(dock.SetPoint, dock, "BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 0, 12);
  end
end

SetPrimaryChatFramePosition = function(chatModuleData, anchorName)
  if (MayronUI.__suppressAutoInstallerOnProfileReset
      or not anchorName
      or InCombatLockdown()
      or not obj:IsWidget(ChatFrame1)) then
    return;
  end

  local muiChatFrame = chatModuleData.chatFrames[anchorName];
  local frame = muiChatFrame and muiChatFrame:GetFrame();
  local window = frame and frame.window;
  if (not obj:IsWidget(window)) then
    return;
  end

  muiChatFrame:SetUpTabBar(chatModuleData.settings.chatFrames[anchorName].tabBar);

  local xOffset = tk.Strings:Contains(anchorName, "RIGHT") and -6 or 6;
  local yOffset = tk.Strings:Contains(anchorName, "TOP") and -6 or 6;

  if (not tk:IsRetail()) then
    ChatFrame1:SetMovable(true);
    ChatFrame1:SetUserPlaced(true);
    ChatFrame1:SetClampedToScreen(false);
  end
  ChatFrame1:SetWidth(window:GetWidth() + 8);
  ChatFrame1:SetHeight(math.max(window:GetHeight() - 8, 100));

  if (obj:IsFunction(FCF_SetLocked)) then
    pcall(FCF_SetLocked, ChatFrame1, 1);
  end

  pcall(ChatFrame1.ClearAllPoints, ChatFrame1);
  local ok = pcall(ChatFrame1.SetPoint, ChatFrame1, anchorName, window, anchorName, xOffset, yOffset);

  if (not ok) then
    return;
  end

  if (obj:IsFunction(FCF_StopDragging)) then
    pcall(FCF_StopDragging, ChatFrame1);
  end

  local dock = _G.GENERAL_CHAT_DOCK;
  if (obj:IsWidget(dock)) then
    PositionChatDock(frame, anchorName);

    if (obj:IsFunction(_G.FCFDock_UpdateTabs)) then
      pcall(_G.FCFDock_UpdateTabs, dock);
    end

    UpdateDockedChatTabs();

    if (not tk.Strings:Contains(anchorName, "BOTTOM")) then
      SyncChatTabTexture(frame, anchorName);
    end
  end

  if (obj:IsWidget(_G.ChatAlertFrame)) then
    pcall(_G.ChatAlertFrame.ClearAllPoints, _G.ChatAlertFrame);

    if (tk.Strings:Contains(anchorName, "TOP")) then
      pcall(_G.ChatAlertFrame.SetPoint, _G.ChatAlertFrame, "TOPLEFT", ChatFrame1, "BOTTOMLEFT", 0, -60);
    else
      pcall(_G.ChatAlertFrame.SetPoint, _G.ChatAlertFrame, "BOTTOMLEFT", _G.ChatFrame1Tab, "TOPLEFT", 0, 10);
    end
  end

  if (obj:IsWidget(_G.BNToastFrame) and obj:IsWidget(_G.ChatAlertFrame)) then
    pcall(_G.BNToastFrame.ClearAllPoints, _G.BNToastFrame);
    pcall(_G.BNToastFrame.SetPoint, _G.BNToastFrame, "BOTTOMLEFT", _G.ChatAlertFrame, "BOTTOMLEFT", 0, 0);
  end

end

function C_ChatModule:OnInitialize(data)
  data.chatFrames = obj:PopTable();

  local currentLayout = db.profile.layout;
  if (currentLayout) then
    if (not LayoutManager:LayoutExists(currentLayout)) then
      db.profile.layout = nil;
    end
  end

	local setupOptions = {
    onExecuteAll = {
      ignore = {
        "icons", "iconsAnchor";
      }
    };
		groups = {
      {
        patterns = {
          "editBox.position";
          "editBox.yOffset";
          "editBox.height";
        };
				value = function()
					ApplyEditBoxLayout(data.settings);
				end
			},
		}
	};

  if (not db.profile.chat.highlighted) then
    db:RemoveAppended(db.profile, "chat.highlighted");
  end

  db:AppendOnce("profile.chat.highlighted", nil, {
    {
      "healers", "healer", "healz", "heals", "heal", "healing",
      color = { 0.1; 1; 0.1; };
      sound = false;
      upperCase = false;
    },
    {
      "tanks", "tank", "tanking",
      color = { 1; 0.1; 0.1; };
      sound = false;
      upperCase = false;
    },
    {
      "dps";
      color = { 1; 1; 0; };
      sound = false;
      upperCase = false;
    },
    {
      _G.UnitName("player");
      color = { 1, 0.04, 0.78 };
      sound = tk.Constants.SOUND_OPTIONS[L["Whisper Received"]];
      upperCase = false;
    },
  });

  -- must be before data.settings gets initialised from RegisterUpdateFunctions
  local iconSettings = db.profile.chat.icons:GetUntrackedTable();
  local normalizedIcons = NormalizeChatSideBarIcons(iconSettings);
  local shouldResetIcons = (#iconSettings ~= #normalizedIcons);

  if (not shouldResetIcons) then
    for index = 1, #normalizedIcons do
      local currentType = obj:IsTable(iconSettings[index]) and iconSettings[index].type;

      if (currentType ~= normalizedIcons[index].type) then
        shouldResetIcons = true;
        break;
      end
    end
  end

  if (shouldResetIcons) then
    db:SetPathValue("profile.chat.icons", normalizedIcons, nil, false);
  end

  local universalIconSettings = db.profile.chat.universalIcons:GetUntrackedTable();
  local normalizedUniversalIcons = NormalizeUniversalSideBarIcons(universalIconSettings);
  local shouldResetUniversalIcons = (#universalIconSettings ~= #normalizedUniversalIcons);

  if (not shouldResetUniversalIcons) then
    for index = 1, #normalizedUniversalIcons do
      local currentType = obj:IsTable(universalIconSettings[index]) and universalIconSettings[index].type;

      if (currentType ~= normalizedUniversalIcons[index].type) then
        shouldResetUniversalIcons = true;
        break;
      end
    end
  end

  if (shouldResetUniversalIcons) then
    db:SetPathValue("profile.chat.universalIcons", normalizedUniversalIcons, nil, false);
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    db.profile.chat.chatFrames[anchorName]:SetParent(db.profile.chat.__templateChatFrame);
  end

  for _, anchorName in ipairs(orderedChatAnchors) do
    local settings = db.profile.chat.chatFrames[anchorName];
    local normalizedWindowType = NormalizeWindowType(settings);
    settings.windowType = (normalizedWindowType == "empty") and "chat" or normalizedWindowType;
  end

  if (FeatureState:IsEnabled("chat.universal.enabled")) then
    ChatMigrations:ApplyDefaultDPSWindowLayout(db.profile.chat.chatFrames, db.profile.chat);
    ChatMigrations:ApplyDefaultHealerWindowLayout(db.profile.chat.chatFrames, db.profile.chat);
  end

  ApplyCurrentPhaseChatWindowPolicy(db.profile.chat);
  ChatMigrations:ApplyDefaultDPSWindowButtons(db.profile.chat.chatFrames);

  ChatMigrations:ModernizeRetailChatButtons(db.profile.chat.__templateChatFrame.buttons);

  for _, anchorName in ipairs(orderedChatAnchors) do
    ChatMigrations:ModernizeRetailChatButtons(db.profile.chat.chatFrames[anchorName].buttons);
  end

  for _, anchorName in obj:IterateArgs("BOTTOMLEFT", "BOTTOMRIGHT") do
    local tabBarSettings = db.profile.chat.chatFrames[anchorName].tabBar;

    if (obj:IsTable(tabBarSettings) and tabBarSettings.yOffset == -43) then
      tabBarSettings.yOffset = -35;
    end
  end

  local hasEnabledChatFrame = false;
  for _, anchorName in ipairs(orderedChatAnchors) do
    local chatFrameSettings = db.profile.chat.chatFrames[anchorName];

    if (obj:IsTable(chatFrameSettings) and ChatMigrations:UsesPrimaryChat(chatFrameSettings)) then
      hasEnabledChatFrame = true;
      break;
    end
  end

  if (not hasEnabledChatFrame and obj:IsTable(db.profile.chat.chatFrames.BOTTOMLEFT)) then
    db.profile.chat.chatFrames.BOTTOMLEFT.enabled = true;
    db.profile.chat.chatFrames.BOTTOMLEFT.windowType = "chat";
    db.profile.chat.chatFrames.BOTTOMLEFT.xOffset = 2;
    db.profile.chat.chatFrames.BOTTOMLEFT.yOffset = 2;
  end

  local savedIconsAnchor = db.profile.chat.chatFrames[db.profile.chat.iconsAnchor];
  if (not obj:IsTable(savedIconsAnchor)
      or NormalizeWindowType(savedIconsAnchor) ~= "chat") then
    db.profile.chat.iconsAnchor = GetEnabledAnchorByType(
      db.profile.chat.chatFrames, "chat", "BOTTOMLEFT"
    ) or db.profile.chat.iconsAnchor;
  end

  local savedUniversalIconsAnchor = db.profile.chat.chatFrames[db.profile.chat.universalIconsAnchor];
  if (not obj:IsTable(savedUniversalIconsAnchor)
      or NormalizeWindowType(savedUniversalIconsAnchor) ~= "action") then
    db.profile.chat.universalIconsAnchor = GetEnabledAnchorByType(
      db.profile.chat.chatFrames, "action", "BOTTOMRIGHT"
    ) or db.profile.chat.universalIconsAnchor;
  end

  if (db.profile.chat.iconsWindowType ~= "chat" and db.profile.chat.iconsWindowType ~= "action") then
    db.profile.chat.iconsWindowType = "chat";
  end

  if (not obj:IsString(db.profile.chat.universalContent)) then
    if (db.profile.chat.universalTrackerVisible == false) then
      db.profile.chat.universalContent = "none";
    else
      db.profile.chat.universalContent = UniversalProviders:GetPreferredDefaultContent();
    end
  end

  db.profile.chat.universalContent =
    UniversalProviders:GetCurrentContent(db.profile.chat.universalContent);

  self:RegisterUpdateFunctions(db.profile.chat, {
    iconsWindowType = function()
      if (data.settings.iconsWindowType == "action") then
        data.settings.universalIconsAnchor = GetEnabledAnchorByType(
          data.settings.chatFrames, "action", data.settings.universalIconsAnchor
        ) or data.settings.universalIconsAnchor;
      else
        data.settings.iconsAnchor = GetEnabledAnchorByType(
          data.settings.chatFrames, "chat", data.settings.iconsAnchor
        ) or data.settings.iconsAnchor;
      end

      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    iconsAnchor = function()
      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    universalIconsAnchor = function()
      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    icons = function()
      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    universalIcons = function()
      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    universalContent = function()
      RefreshActionWindowContent(self, data);
      C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
    end;

    chatFrames = function(value, keysList)
      if (keysList:GetSize() == 1) then
        RefreshUniversalWindowSlots(self, data);
      else
        local keys = keysList:ToTable();
        local anchorName = keys[2];
        local muiChatFrame = data.chatFrames[anchorName];
        local settingName = keys[3];

        if (not (anchorName and settingName)) then
          obj:PushTable(keys);
          return;
        end

        if (settingName == "enabled" or settingName == "windowType") then
          RefreshUniversalWindowSlots(self, data);
          obj:PushTable(keys);
          return
        end

        if (settingName == "xOffset" or settingName == "yOffset") then
    if (ChatMigrations:UsesChatShell(data.settings.chatFrames[anchorName]) and muiChatFrame) then
            local frame = muiChatFrame:GetFrame();

            if (frame) then
              local p, rf, rp, x, y = frame:GetPoint();
              local xOffset = (settingName == "xOffset" and value) or x;
              local yOffset = (settingName == "yOffset" and value) or y;
              frame:SetPoint(p, rf, rp, xOffset, yOffset);
            end
          end

          PositionUniversalAnchor(data, anchorName);
          RefreshActionWindowContent(self, data);

          if (data.activeChatAnchor == anchorName) then
            SetPrimaryChatFramePosition(data, anchorName);
          end

          obj:PushTable(keys);
          return;
        end

    if (not muiChatFrame or not ChatMigrations:UsesChatShell(data.settings.chatFrames[anchorName])) then
          obj:PushTable(keys);
          return;
        end

        if (settingName == "buttons") then
          local buttonKey = keys[4];
          local buttonID = keys[5];

          if (not buttonKey or not buttonID) then
            em:TriggerEventListenerByID(anchorName.."_OnModifierStateChanged");
          end

          if (buttonID ~= "key") then
            em:TriggerEventListenerByID(anchorName.."_OnModifierStateChanged");
          end

        elseif (settingName == "tabBar") then
          muiChatFrame:SetUpTabBar(data.settings.chatFrames[anchorName].tabBar);

          if (data.activeChatAnchor == anchorName) then
            SetPrimaryChatFramePosition(data, anchorName);
          end

        elseif (settingName == "window") then
          if (obj:IsFunction(muiChatFrame.ApplyShellSizing)) then
            muiChatFrame:ApplyShellSizing();
          end
          RefreshActionWindowContent(self, data);

          if (data.activeChatAnchor == anchorName) then
            SetPrimaryChatFramePosition(data, anchorName);
          end

        elseif (settingName == "sidebarHeight") then
          if (obj:IsFunction(muiChatFrame.ApplyShellSizing)) then
            muiChatFrame:ApplyShellSizing();
          end
          RefreshActionWindowContent(self, data);

          if (data.activeChatAnchor == anchorName) then
            SetPrimaryChatFramePosition(data, anchorName);
          end
        end

        obj:PushTable(keys);
      end
    end;

    editBox = {
      height = function(value)
        ApplyEditBoxLayout(data.settings);
        ApplyEditBoxAppearance(data, data.settings);
      end;
    };
  }, setupOptions);
end

----------------------------------
-- Override Blizzard Functions:
----------------------------------
function C_ChatModule:OnInitialized(data)
  if (not data.settings.enabled) then return end

  -- perform migration if old settings are found:
  if (not tk.Tables:All(data.settings.icons, obj.IsTable)) then
    db:SetPathValue("profile.chat.icons", nil, nil, false);
  end

  -- Override Blizzard Stuff -----------------------
  hooksecurefunc("ChatEdit_UpdateHeader", function()
    local chatType = ChatFrame1EditBox:GetAttribute("chatType");
    local r, g, b = _G.GetMessageTypeColor(chatType);
    ChatFrame1EditBox:SetBackdropBorderColor(r, g, b, 1);
  end);

  if (not data.syncChatDockHooked and obj:IsFunction(_G.FCFDock_UpdateTabs)) then
    hooksecurefunc("FCFDock_UpdateTabs", function()
      local anchorName = data.activeChatAnchor;
      local muiChatFrame = anchorName and data.chatFrames[anchorName];
      local frame = muiChatFrame and muiChatFrame:GetFrame();

      if (obj:IsWidget(frame)) then
        PositionChatDock(frame, anchorName);
      end

      UpdateDockedChatTabs();

      if (obj:IsWidget(frame) and obj:IsWidget(frame.tabs) and frame.tabs:IsShown()
          and not tk.Strings:Contains(anchorName, "BOTTOM")) then
        SyncChatTabTexture(frame, anchorName);
      end
    end);

    data.syncChatDockHooked = true;
  end

  local universalWindowModule = GetUniversalWindowModule();
  if (obj:IsTable(universalWindowModule) and obj:IsFunction(universalWindowModule.BindChatContext)) then
    universalWindowModule:BindChatContext(self, data);
  end

  RefreshUniversalWindowSlots(self, data);

  self:SetEnabled(true);
end

function C_ChatModule:OnEnable(data)
  if (data.editBoxBackdrop) then return end

	StaticPopupDialogs["MUI_Link"] = {
		text = tk.Strings:Join(
			"\n", tk.Strings:SetTextColorByTheme("MayronUI"), L["(CTRL+C to Copy, CTRL+V to Paste)"]
		);
		button1 = "Close";
		hasEditBox = true;
		maxLetters = 1024;
		editBoxWidth = 350;
		hideOnEscape = 1;
		timeout = 0;
		whileDead = 1;
		preferredIndex = 3;
	};

  data.editBoxBackdrop = obj:PopTable();

  -- default setup
  data.editBoxBackdrop.edgeFile = tk.Constants.BACKDROP.edgeFile;
  data.editBoxBackdrop.edgeSize = tk.Constants.BACKDROP.edgeSize;
	data.editBoxBackdrop.bgFile = tk.Constants.BACKDROP_WITH_BACKGROUND.bgFile;
	data.editBoxBackdrop.insets = obj:PopTable();

	-- Kill all blizzard unwanted elements (textures, fontstrings, frames, etc...)
	for i = 1, 20 do
		local staticPopupEditBox = strformat("StaticPopup%dEditBox", i);

		if (not _G[staticPopupEditBox]) then
			break;
		end

		tk:KillAllElements(
			_G[strformat("%sLeft", staticPopupEditBox)],
			_G[strformat("%sMid", staticPopupEditBox)],
			_G[strformat("%sRight", staticPopupEditBox)]
		);
	end

  tk:KillAllElements(
		ChatFrame1EditBox.focusLeft, ChatFrame1EditBox.focusRight, ChatFrame1EditBox.focusMid,
		_G.ChatFrame1EditBoxLeft, _G.ChatFrame1EditBoxMid, _G.ChatFrame1EditBoxRight,
		_G.ChatFrameMenuButton,	_G.QuickJoinToastButton
	);

  ApplyEditBoxLayout(data.settings);
  ApplyEditBoxAppearance(data, data.settings);

  -- rename stuff here:

  self:SetUpAllBlizzardFrames();
end

obj:DefineReturns("table");
function C_ChatModule:GetChatFrames(data)
	return data.chatFrames;
end

function C_ChatModule:GetActiveChatAnchor(data)
  return data.activeChatAnchor;
end

function C_ChatModule:GetActiveWindowAnchor(data, windowType)
  if (windowType == "action") then
    return data.activeActionAnchor;
  end

  if (windowType == "grid2") then
    return data.activeGrid2Anchor;
  end

  return data.activeChatAnchor;
end

function C_ChatModule:RefreshSideBarIcons(data)
  C_ChatFrame.Static:SetUpSideBarIcons(self, data.settings);
end

function C_ChatModule:RefreshUniversalContent(data)
  RefreshActionWindowContent(self, data);
end

do
	local function LayoutButton_OnEnter(self)
		if (self.hideTooltip) then
			return
		end

		_G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 8, -38);
    _G.GameTooltip:SetText(L["MUI Layout Button"]);

		_G.GameTooltip:AddDoubleLine(tk.Strings:SetTextColorByTheme(
      L["Left Click:"]), L["Switch Layout"], 1, 1, 1);

		_G.GameTooltip:AddDoubleLine(tk.Strings:SetTextColorByTheme(
      L["Right Click:"]), L["Show Layout Config Tool"], 1, 1, 1);

		_G.GameTooltip:Show();
	end

	local function LayoutButton_OnLeave()
		_G.GameTooltip:Hide();
	end

	local function GetNextLayout()
		local firstLayout, firstData;
		local foundCurrentLayout;
		local currentLayout = db.profile.layout;

    for layoutName, layoutData in LayoutManager:IterateLayouts() do
			if (obj:IsTable(layoutData)) then
				if (not firstLayout) then
					firstLayout = layoutName;
					firstData = layoutData;
				end

				if (currentLayout == layoutName) then -- the next layout
					foundCurrentLayout = true;

				elseif (foundCurrentLayout) then
					-- Found the next layout!
					return layoutName, layoutData;
				end
			end
		end

		-- The next layout must be back to the first layout
		return firstLayout, firstData;
	end

	local function LayoutButton_OnMouseUp(self, module, btnPressed)
		if (not _G.MouseIsOver(self)) then
			return;
		end

		if (btnPressed == "LeftButton") then
			if (InCombatLockdown()) then
				tk:Print(L["Cannot switch layouts while in combat."]);
				return;
			end

			local layoutName, layoutData = GetNextLayout();
			module:SwitchLayouts(layoutName, layoutData);
			PlaySound(tk.Constants.CLICK);

		elseif (btnPressed == "RightButton") then
			MayronUI:TriggerCommand("layouts");
		end
	end

	obj:DefineParams("Button");
	function C_ChatModule:SetUpLayoutButton(data, layoutButton)
		local layoutName = db.profile.layout;

		layoutButton:SetText(layoutName:sub(1, 1):upper());

		data.layoutButtons = data.layoutButtons or obj:PopTable();
		table.insert(data.layoutButtons, layoutButton);

		layoutButton:RegisterForClicks("LeftButtonDown", "RightButtonDown", "MiddleButtonDown");
		layoutButton:SetScript("OnEnter", LayoutButton_OnEnter);
		layoutButton:SetScript("OnLeave", LayoutButton_OnLeave);
		layoutButton:SetScript("OnMouseUp", function(_, btnPressed)
			LayoutButton_OnMouseUp(layoutButton, self, btnPressed);
		end);
	end
end

obj:DefineParams("string", "?table");
function C_ChatModule:SwitchLayouts(data, layoutName, layoutData)
  if (InCombatLockdown()) then
    tk:Print(L["Cannot switch layouts while in combat."]);
    return;
  end

  MayronUI:SwitchLayouts(layoutName, layoutData);

  for _, btn in ipairs(data.layoutButtons) do
    btn:SetText(layoutName:sub(1, 1):upper());
  end

  tk:Print(tk.Strings:SetTextColorByRGB(layoutName, 0, 1, 0), L["Layout enabled!"]);
end

-- must be before chat is initialized!
for i = 1, NUM_CHAT_WINDOWS do
  _G["ChatFrame"..i]:SetClampRectInsets(0, 0, 0, 0);
  local editBox = _G["ChatFrame"..i.."EditBox"];

  if (_G.BackdropTemplateMixin) then
    _G.Mixin(editBox, _G.BackdropTemplateMixin);
    editBox:OnBackdropLoaded();
    editBox:SetScript("OnSizeChanged", editBox.OnBackdropSizeChanged);
  end
end
