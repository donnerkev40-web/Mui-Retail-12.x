-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI = _G.MayronUI; ---@type MayronUI
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents();
local MEDIA = tk:GetAssetFilePath("Textures\\Chat\\");

---@class ChatFrame
local C_ChatFrame = obj:Import("MayronUI.ChatModule.ChatFrame");
local ChatSideIcons = obj:Import("MayronUI.ChatModule.SideIcons");
local UniversalProviders = obj:Import("MayronUI.UniversalWindow.Providers");

local ChatMenu, UIMenu_Initialize, UIMenu_AutoSize, string, table, pairs =
	_G.ChatMenu, _G.UIMenu_Initialize, _G.UIMenu_AutoSize, _G.string, _G.table, _G.pairs;

local UIMenu_AddButton, FriendsFrame_SetOnlineStatus = _G.UIMenu_AddButton, _G.FriendsFrame_SetOnlineStatus;

local FRIENDS_TEXTURE_ONLINE, FRIENDS_TEXTURE_AFK, FRIENDS_TEXTURE_DND =
	_G.FRIENDS_TEXTURE_ONLINE, _G.FRIENDS_TEXTURE_AFK, _G.FRIENDS_TEXTURE_DND;

local FRIENDS_LIST_AVAILABLE, FRIENDS_LIST_AWAY, FRIENDS_LIST_BUSY =
  _G.FRIENDS_LIST_AVAILABLE, _G.FRIENDS_LIST_AWAY, _G.FRIENDS_LIST_BUSY;

local IsAddOnLoaded, InCombatLockdown, ipairs, tonumber =
  _G.IsAddOnLoaded, _G.InCombatLockdown, _G.ipairs, _G.tonumber;
local PlaySound = _G.PlaySound;
local EasyMenu = _G.EasyMenu;
local BNSetAFK, BNSetDND = _G.BNSetAFK, _G.BNSetDND;
local ToggleDropDownMenu = _G.ToggleDropDownMenu;

local retailMicroButtonNames = {
  "CharacterMicroButton";
  "SpellbookMicroButton";
  "TalentMicroButton";
  "PlayerSpellsMicroButton";
  "AchievementMicroButton";
  "QuestLogMicroButton";
  "GuildMicroButton";
  "LFDMicroButton";
  "CollectionsMicroButton";
  "EJMicroButton";
  "StoreMicroButton";
  "MainMenuMicroButton";
};

local function SafeClearAllPoints(widget)
  if (obj:IsWidget(widget) and obj:IsFunction(widget.ClearAllPoints)) then
    return pcall(widget.ClearAllPoints, widget);
  end

  return false;
end

local function SafeSetPoint(widget, ...)
  if (obj:IsWidget(widget) and obj:IsFunction(widget.SetPoint)) then
    return pcall(widget.SetPoint, widget, ...);
  end

  return false;
end

-- C_ChatFrame -----------------------

obj:DefineParams("string", "ChatModule", "table");
---@param anchorName string position of chat frame (i.e. "TOPLEFT")
---@param chatModule ChatModule
---@param chatModuleSettings table
function C_ChatFrame:__Construct(data, anchorName, chatModule, chatModuleSettings)
	data.anchorName = anchorName;
	data.chatModule = chatModule;
	data.chatModuleSettings = chatModuleSettings;
	data.settings = chatModuleSettings.chatFrames[anchorName];
end

obj:DefineParams("boolean");
---@param enabled boolean enable/disable the chat frame
function C_ChatFrame:SetEnabled(data, enabled)
	if (not data.frame and enabled) then
		data.frame = self:CreateFrame();
		self:SetUpTabBar(data.settings.tabBar);
		self:Reposition();

    if (IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
      data.chatModule:SetUpRaidFrameManager();
    else
      -- if it is not loaded, create a callback to trigger when it is loaded
      local listener = em:CreateEventListener(function(_, name)
        if (name == "Blizzard_CompactRaidFrames") then
          data.chatModule:SetUpRaidFrameManager();
        end
      end)

      listener:SetExecuteOnce(true);
      listener:RegisterEvent("ADDON_LOADED");
    end

		-- chat channel button
		data.chatModule:SetUpLayoutButton(data.frame.layoutButton);
	end

	if (data.frame) then
		data.frame:SetShown(enabled);

    if (enabled) then
			self:SetUpButtonHandler(data.settings.buttons);
      self:SetWindowType(data.settings.windowType);

      if (obj:IsWidget(_G.MUI_ChatFrameBlizzardMicroMenu)) then
        _G.MUI_ChatFrameBlizzardMicroMenu:Hide();
      end
    end

    self.Static:SetUpSideBarIcons(data.chatModule, data.chatModuleSettings);
    if (obj:IsWidget(_G.ChatFrameChannelButton)) then
      _G.ChatFrameChannelButton:DisableDrawLayer("ARTWORK");
    end

    if (tk:IsRetail()) then
      if (obj:IsWidget(_G.ChatFrameToggleVoiceMuteButton)) then
        _G.ChatFrameToggleVoiceMuteButton:DisableDrawLayer("ARTWORK");
      end

      if (obj:IsWidget(_G.ChatFrameToggleVoiceDeafenButton)) then
        _G.ChatFrameToggleVoiceDeafenButton:DisableDrawLayer("ARTWORK");
      end
    end
	end
end

obj:DefineParams("string");
function C_ChatFrame:SetWindowType(data, windowType)
  if (not data.frame) then
    return;
  end

  if (windowType ~= "action" and windowType ~= "grid2") then
    windowType = "chat";
  end

  local isChatWindow = (windowType == "chat");
  local isActionWindow = (windowType == "action");
  local isGrid2Window = (windowType == "grid2");
  data.windowType = windowType;

  if (obj:IsWidget(data.buttonsBar)) then
    data.buttonsBar:SetShown((isChatWindow or isActionWindow) and not isGrid2Window and data.frame:IsShown());
  end

  if (obj:IsWidget(data.frame.layoutButton)) then
    data.frame.layoutButton:SetShown(isChatWindow and data.frame:IsShown());
  end

  if (not data.frame.actionTitle) then
    data.frame.actionTitle = data.frame:CreateFontString(nil, "OVERLAY", "MUI_FontSmall");
    data.frame.actionTitle:SetJustifyH("CENTER");
    data.frame.actionTitle:SetText(L["Universal Window"]);
    tk:ApplyThemeColor(data.frame.actionTitle);
  end

  if (isGrid2Window) then
    data.frame.actionTitle:SetText("Grid2");
  else
    data.frame.actionTitle:SetText(L["Universal Window"]);
  end

  data.frame.actionTitle:SetShown((isActionWindow or isGrid2Window) and data.frame:IsShown());

  self:ApplyShellSizing();
  self:SetUpTabBar(data.settings.tabBar);
end

function C_ChatFrame:GetSidebarWidth(data)
  return 24;
end

function C_ChatFrame:GetSidebarGap(data)
  return 2;
end

function C_ChatFrame:GetWindowWidth(data, windowSettings)
  local baseWindowWidth = tonumber(windowSettings.width) or 367;
  return baseWindowWidth;
end

function C_ChatFrame:ApplySidebarVisual(data)
  if (not (data.frame and obj:IsWidget(data.frame.sidebar))) then
    return;
  end

  data.frame.sidebar:SetTexture(string.format("%ssidebar", MEDIA));
  data.frame.sidebar:SetVertexColor(1, 1, 1, 1);
end

function C_ChatFrame:ApplyShellSizing(data)
  if (not data.frame) then
    return;
  end

  local windowSettings = obj:IsTable(data.settings.window) and data.settings.window or {};
  local windowWidth = self:GetWindowWidth(data, windowSettings);
  local windowHeight = tonumber(windowSettings.height) or 248;
  local sidebarHeight = tonumber(data.settings.sidebarHeight) or 300;
  local sidebarWidth = self:GetSidebarWidth();
  local sidebarGap = self:GetSidebarGap();
  local outerWidth = windowWidth + sidebarWidth + sidebarGap;
  local outerHeight = math.max(sidebarHeight + 20, windowHeight + 62);

  data.frame:SetSize(outerWidth, outerHeight);
  data.frame.sidebar:SetSize(sidebarWidth, sidebarHeight);
  data.frame.window:SetSize(windowWidth, windowHeight);
  self:ApplySidebarVisual();

  if (data.tabs) then
    data.tabs:SetSize(math.max(windowWidth - 9, 60), 23);
  end

  self:Reposition();
end

function C_ChatFrame.Static:SetUpSideBarIcons(chatModule, settings)
  self.UniversalIconTypes = UniversalProviders:GetSidebarIconTypes();
  ChatSideIcons:SetUpSideBarIcons(chatModule, settings, self);
end

function C_ChatFrame.Static:SetUpBlizzardMicroMenu(chatModule, settings)
  local menuFrame = _G.MUI_ChatFrameBlizzardMicroMenu;

  if (obj:IsWidget(menuFrame)) then
    menuFrame:Hide();
  end

  if (not tk:IsRetail() or InCombatLockdown()) then
    return;
  end
end

function C_ChatFrame:DisableLegacyShortcutButtons(data)
  if (not obj:IsTable(data.buttons)) then
    return;
  end

  for _, button in ipairs(data.buttons) do
    if (obj:IsWidget(button)) then
      local normalTexture = button:GetNormalTexture();
      local highlightTexture = button:GetHighlightTexture();

      button:SetScript("OnClick", nil);
      button:SetText(tk.Strings.Empty);
      button:Disable();
      button:Hide();

      if (normalTexture) then
        normalTexture:Hide();
      end

      if (highlightTexture) then
        highlightTexture:Hide();
      end
    end
  end
end

function C_ChatFrame:CreateButtons(data)
	local butonMediaFile;
	data.buttons = obj:PopTable();

	for buttonID = 1, 3 do
		local btn = tk:CreateFrame("Button", data.buttonsBar);
		data.buttons[buttonID] = btn;

		btn:SetSize(135, 20);
		btn:SetNormalFontObject("MUI_FontSmall");
		btn:SetHighlightFontObject("GameFontHighlightSmall");
		btn:SetText(tk.Strings.Empty);

		-- position button
		if (buttonID == 1) then
			btn:SetPoint("TOPLEFT");
		else
			local previousButton = data.buttons[#data.buttons - 1];
			btn:SetPoint("LEFT", previousButton, "RIGHT");
		end

		-- get button texture (first and last buttons share the same "side" texture)
		if (buttonID == 1 or buttonID == 3) then
			-- use "side" button texture
			butonMediaFile = string.format("%ssideButton", MEDIA);
		else
			-- use "middle" button texture
			butonMediaFile = string.format("%smiddleButton", MEDIA);
		end

		btn:SetNormalTexture(butonMediaFile);
		btn:SetHighlightTexture(butonMediaFile);

		if (buttonID == 3) then
			-- flip last button texture horizontally
			btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1);
			btn:GetHighlightTexture():SetTexCoord(1, 0, 0, 1);
		end

		if (tk.Strings:Contains(data.anchorName, "BOTTOM")) then
			-- flip vertically

			if (buttonID == 3) then
				-- flip last button texture horizontally
				btn:GetNormalTexture():SetTexCoord(1, 0, 1, 0);
				btn:GetHighlightTexture():SetTexCoord(1, 0, 1, 0);
			else
				btn:GetNormalTexture():SetTexCoord(0, 1, 1, 0);
				btn:GetHighlightTexture():SetTexCoord(0, 1, 1, 0);
			end
		end
	end
end

obj:DefineReturns("Frame");
---@return Frame returns an MUI chat frame
function C_ChatFrame:CreateFrame(data)
	local muiChatFrame = tk:CreateFrame("Frame", nil, "MUI_ChatFrame_" .. data.anchorName);

  muiChatFrame:SetFrameStrata("MEDIUM");
  muiChatFrame:SetFrameLevel(5);
  muiChatFrame:SetClampedToScreen(true);
	muiChatFrame:SetSize(393, 310);
	muiChatFrame:SetPoint(data.anchorName, data.settings.xOffset, data.settings.yOffset);

	muiChatFrame.sidebar = muiChatFrame:CreateTexture(nil, "ARTWORK");
	muiChatFrame.sidebar:SetTexture(string.format("%ssidebar", MEDIA));
	muiChatFrame.sidebar:SetSize(24, 300);
	muiChatFrame.sidebar:SetPoint(data.anchorName, 0, -10);

	muiChatFrame.window = tk:CreateFrame("Frame", muiChatFrame);
  muiChatFrame.window:SetSize(367, 248);
  muiChatFrame.window:SetPoint("TOPLEFT", muiChatFrame.sidebar, "TOPRIGHT", 2, data.settings.window.yOffset);

	muiChatFrame.window.texture = muiChatFrame.window:CreateTexture(nil, "ARTWORK");
	muiChatFrame.window.texture:SetTexture(string.format("%swindow", MEDIA));
	muiChatFrame.window.texture:SetAllPoints(true);

  -- External embedded content should live above the decorative shell texture.
  -- Keep the content host as a sibling of the decorated window so parent
  -- artwork can never cover embedded addon controls such as Zygor tabs.
  muiChatFrame.window.contentHost = tk:CreateFrame("Frame", muiChatFrame);
  muiChatFrame.window.contentHost:SetPoint("TOPLEFT", muiChatFrame.window, "TOPLEFT", 0, 0);
  muiChatFrame.window.contentHost:SetPoint("BOTTOMRIGHT", muiChatFrame.window, "BOTTOMRIGHT", 0, 0);
  muiChatFrame.window.contentHost:SetFrameStrata(muiChatFrame:GetFrameStrata() or "MEDIUM");
  muiChatFrame.window.contentHost:SetFrameLevel((muiChatFrame.window:GetFrameLevel() or 1) + 15);

	muiChatFrame.layoutButton = tk:CreateFrame("Button", muiChatFrame);
	muiChatFrame.layoutButton:SetNormalFontObject("MUI_FontSmall");
	muiChatFrame.layoutButton:SetHighlightFontObject("GameFontHighlightSmall");
	muiChatFrame.layoutButton:SetText(" ");
	muiChatFrame.layoutButton:GetFontString():SetPoint("CENTER", 1, 0);
	muiChatFrame.layoutButton:SetSize(21, 120);
	muiChatFrame.layoutButton:SetPoint("LEFT", muiChatFrame.sidebar, "LEFT");
	muiChatFrame.layoutButton:SetNormalTexture(string.format("%slayoutButton", MEDIA));
	muiChatFrame.layoutButton:SetHighlightTexture(string.format("%slayoutButton", MEDIA));

	data.buttonsBar = tk:CreateFrame("Frame", muiChatFrame);
	data.buttonsBar:SetSize(135 * 3, 20);
	data.buttonsBar:SetPoint("TOPLEFT", 20, 0);
  muiChatFrame.buttonsBar = data.buttonsBar;

	tk:ApplyThemeColor(
		muiChatFrame.layoutButton:GetNormalTexture(),
		muiChatFrame.layoutButton:GetHighlightTexture()
	);

	self:CreateButtons();
  muiChatFrame.legacyButtons = data.buttons;
  self:ApplyShellSizing();

	return muiChatFrame;
end

function C_ChatFrame:SetUpTabBar(data, settings)
  if (not (obj:IsTable(data)
      and obj:IsTable(data.frame)
      and obj:IsTable(settings))) then
    return;
  end

  local shouldShow = settings.show and data.windowType ~= "action" and data.windowType ~= "grid2";

	if (shouldShow) then
		if (not data.tabs) then
			data.tabs = data.frame:CreateTexture(nil, "ARTWORK");
			data.tabs:SetSize(math.max((tonumber(data.settings.window and data.settings.window.width) or 367) - 9, 60), 23);
			data.tabs:SetTexture(string.format("%stabs", MEDIA));
		end

		SafeClearAllPoints(data.tabs);

		if (tk.Strings:Contains(data.anchorName, "RIGHT")) then
			SafeSetPoint(data.tabs, data.anchorName, data.frame.sidebar, "TOPLEFT", 0, settings.yOffset);
			data.tabs:SetTexCoord(1, 0, 0, 1);
		else
			SafeSetPoint(data.tabs, data.anchorName, data.frame.sidebar, "TOPRIGHT", 0, settings.yOffset);
		end
	end

  if (obj:IsTable(data.frame) and obj:IsWidget(data.frame.actionTitle)) then
    SafeClearAllPoints(data.frame.actionTitle);

    if (data.tabs and shouldShow) then
      SafeSetPoint(data.frame.actionTitle, "CENTER", data.tabs, "CENTER", 0, 0);
    else
      SafeSetPoint(data.frame.actionTitle, "TOP", data.frame.window, "TOP", 0, -10);
    end
  end

	if (data.tabs) then
		data.tabs:SetShown(shouldShow and data.frame:IsShown());
	end
end

function C_ChatFrame:Reposition(data)
  if (not (obj:IsTable(data)
      and obj:IsWidget(data.frame)
      and obj:IsWidget(data.frame.window)
      and obj:IsWidget(data.frame.sidebar)
      and obj:IsWidget(data.buttonsBar)
      and obj:IsTable(data.settings)
      and obj:IsTable(data.settings.window))) then
    return;
  end

  if (InCombatLockdown()) then
    return;
  end

  if ((obj:IsFunction(data.frame.IsProtected) and data.frame:IsProtected())
      or (obj:IsFunction(data.frame.window.IsProtected) and data.frame.window:IsProtected())) then
    return;
  end

  local sidebarGap = self:GetSidebarGap();
  local windowYOffset = tonumber(data.settings.window.yOffset) or -37;

	SafeClearAllPoints(data.frame);
	SafeClearAllPoints(data.frame.window);
	SafeClearAllPoints(data.frame.sidebar);
  SafeClearAllPoints(data.buttonsBar);

  SafeSetPoint(data.frame, data.anchorName, UIParent, data.anchorName,
    data.settings.xOffset, data.settings.yOffset);

	if (data.anchorName == "TOPLEFT") then
		SafeSetPoint(data.frame.sidebar, data.anchorName, data.frame, data.anchorName, 0, -10);
		SafeSetPoint(data.frame.window, "TOPLEFT", data.frame.sidebar, "TOPRIGHT", sidebarGap, windowYOffset);
		if (obj:IsWidget(data.frame.window.texture)) then
      data.frame.window.texture:SetTexCoord(0, 1, 0, 1);
    end

	elseif (data.anchorName == "TOPRIGHT") then
		SafeSetPoint(data.frame.sidebar, data.anchorName, data.frame, data.anchorName, 0 , -10);
		SafeSetPoint(data.frame.window, "TOPRIGHT", data.frame.sidebar, "TOPLEFT", -sidebarGap, windowYOffset);
		if (obj:IsWidget(data.frame.window.texture)) then
      data.frame.window.texture:SetTexCoord(1, 0, 0, 1);
    end

	elseif (tk.Strings:Contains(data.anchorName, "BOTTOM")) then
		SafeSetPoint(data.frame.sidebar, data.anchorName, data.frame, data.anchorName, 0 , 10);

		if (data.anchorName == "BOTTOMLEFT") then
			SafeSetPoint(data.frame.window,
        "BOTTOMLEFT", data.frame.sidebar, "BOTTOMRIGHT",
        sidebarGap, windowYOffset);
			if (obj:IsWidget(data.frame.window.texture)) then
        data.frame.window.texture:SetTexCoord(0, 1, 1, 0);
      end

		elseif (data.anchorName == "BOTTOMRIGHT") then
      SafeSetPoint(data.frame.window,
        "BOTTOMRIGHT", data.frame.sidebar, "BOTTOMLEFT",
        -sidebarGap, windowYOffset);
			if (obj:IsWidget(data.frame.window.texture)) then
        data.frame.window.texture:SetTexCoord(1, 0, 1, 0);
      end
		end
	end

	if (tk.Strings:Contains(data.anchorName, "RIGHT")) then
		SafeSetPoint(data.frame.layoutButton, "LEFT", data.frame.sidebar, "LEFT", 2, 0);

    local normalTexture = obj:IsWidget(data.frame.layoutButton) and data.frame.layoutButton:GetNormalTexture();
    local highlightTexture = obj:IsWidget(data.frame.layoutButton) and data.frame.layoutButton:GetHighlightTexture();

    if (obj:IsWidget(normalTexture)) then
      normalTexture:SetTexCoord(1, 0, 0, 1);
    end

    if (obj:IsWidget(highlightTexture)) then
      highlightTexture:SetTexCoord(1, 0, 0, 1);
    end

		data.frame.sidebar:SetTexCoord(1, 0, 0, 1);
		SafeSetPoint(data.buttonsBar, data.anchorName, data.frame, data.anchorName, -20, 0);
	else
		SafeSetPoint(data.buttonsBar, data.anchorName, data.frame, data.anchorName, 20, 0);
	end

  self:ApplySidebarVisual();

	self:SetUpTabBar(data.settings.tabBar);
end

obj:DefineReturns("Frame");
function C_ChatFrame:GetFrame(data)
  return data.frame;
end

do
  local CreateOrSetUpIcon = {};

  local function SetUniversalContent(contentType)
    local universalWindowModule = MayronUI:ImportModule("UniversalWindowModule", true);
    local chatModule = MayronUI:ImportModule("ChatModule", true);
    local normalizedContent = UniversalProviders.NormalizeContentType(contentType);

    if (obj:IsTable(universalWindowModule) and obj:IsFunction(universalWindowModule.SetContentType)) then
      universalWindowModule:SetContentType(normalizedContent);

      if (obj:IsTable(chatModule) and obj:IsFunction(chatModule.RefreshSideBarIcons)) then
        chatModule:RefreshSideBarIcons();
      end

      if (obj:IsTable(chatModule) and obj:IsFunction(chatModule.RefreshUniversalContent)) then
        chatModule:RefreshUniversalContent();
      end

      return;
    end

    db:SetPathValue("profile.chat.universalContent", normalizedContent);

    if (obj:IsTable(chatModule) and obj:IsFunction(chatModule.RefreshSideBarIcons)) then
      chatModule:RefreshSideBarIcons();
    end

    if (obj:IsTable(chatModule) and obj:IsFunction(chatModule.RefreshUniversalContent)) then
      chatModule:RefreshUniversalContent();
    end
  end

  local function ShowDropDownMenu(menuList, menuFrame, anchor)
    if (obj:IsFunction(EasyMenu)) then
      EasyMenu(menuList, menuFrame, anchor or "cursor", 0, 0, "MENU", 1);
      return true;
    end

    local initialize = _G.UIDropDownMenu_Initialize;
    local createInfo = _G.UIDropDownMenu_CreateInfo;
    local addButton = _G.UIDropDownMenu_AddButton;

    if (not (obj:IsFunction(initialize) and obj:IsFunction(createInfo)
        and obj:IsFunction(addButton) and obj:IsFunction(ToggleDropDownMenu))) then
      return false;
    end

    initialize(menuFrame, function(_, level)
      if ((level or 1) ~= 1 or not obj:IsTable(menuList)) then
        return;
      end

      for _, entry in ipairs(menuList) do
        local info = createInfo();

        for key, value in pairs(entry) do
          info[key] = value;
        end

        addButton(info, level);
      end
    end, "MENU");

    ToggleDropDownMenu(1, nil, menuFrame, anchor or "cursor", 0, 0, nil, nil, 1);
    return true;
  end

  local function OpenChatMenu(icon)
    local menu = _G.ChatMenu or ChatMenu;

    if (obj:IsFunction(_G.ChatFrame_ToggleMenu)) then
      local ok = pcall(_G.ChatFrame_ToggleMenu, _G.ChatFrame1);

      if (not ok) then
        pcall(_G.ChatFrame_ToggleMenu);
      end

      if (obj:IsWidget(menu) and menu:IsShown()) then
        PositionChatIconMenu(icon, menu);
        return true;
      end
    end

    if (obj:IsWidget(menu) and obj:IsFunction(_G.ChatMenu_Initialize)) then
      if (obj:IsFunction(_G.UIDropDownMenu_Initialize)
          and obj:IsFunction(ToggleDropDownMenu)) then
        _G.UIDropDownMenu_Initialize(menu, _G.ChatMenu_Initialize, "MENU");
        ToggleDropDownMenu(1, nil, menu, icon, 0, 0, nil, nil, 1);

        if (menu:IsShown()) then
          PositionChatIconMenu(icon, menu);
          return true;
        end
      end

      if (obj:IsFunction(UIMenu_Initialize)) then
        UIMenu_Initialize(menu, _G.ChatMenu_Initialize);

        if (obj:IsFunction(UIMenu_AutoSize)) then
          UIMenu_AutoSize(menu);
        end

        menu:Show();
        PositionChatIconMenu(icon, menu, true);
        return true;
      end
    end

    return false;
  end

	local function PositionChatIconMenu(icon, menu, protected)
    if (not (obj:IsWidget(icon) and obj:IsWidget(menu))) then
      return;
    end

    local chatAnchor = icon:GetParent():GetName():match(".*_(.*)$");
    menu:ClearAllPoints();

    if (protected) then
      local x, y = icon:GetCenter();

      if (chatAnchor:find("TOP")) then
        y = y + 10;
      elseif (chatAnchor:find("BOTTOM")) then
        y = y - 10;
      end

      if (chatAnchor:find("LEFT")) then
        x = x + 15;
      elseif (chatAnchor:find("RIGHT")) then
        x = x - 15;
      end

      menu:SetPoint(chatAnchor, UIParent, "BOTTOMLEFT", x, y);
    else
      local orig, new = "RIGHT", "LEFT";

      if (chatAnchor:find("LEFT")) then
        orig, new = "LEFT", "RIGHT";
      end

      local relPoint = chatAnchor:gsub(orig, new);
      menu:SetPoint(chatAnchor, icon, relPoint);
    end

		icon:GetScript("OnLeave")(icon);
	end

  local function CreateIconSafely(iconType)
    local createIcon = CreateOrSetUpIcon[iconType];
    if (not obj:IsFunction(createIcon)) then
      return;
    end

    local ok, icon = pcall(createIcon, "MUI_ChatFrameIcon_"..iconType);
    if (ok and obj:IsWidget(icon)) then
      return icon;
    end
  end

	local function PositionIcon(enabled, iconType, chatFrame, bottom, indexInGroup)
    local currentIcon = _G["MUI_ChatFrameIcon_"..iconType];

    if (iconType == "deafen" or iconType == "mute") then
      if (not currentIcon) then
				currentIcon = CreateIconSafely(iconType);
      end

      if (currentIcon) then
        currentIcon:SetVisibilityQueryFunction(function() return enabled; end);
        currentIcon:UpdateVisibleState();
      end
    end

    if (enabled) then
      if (not currentIcon) then
        currentIcon = CreateIconSafely(iconType);
      end

      if (not currentIcon) then
        return nil;
      end

			currentIcon:ClearAllPoints();
			currentIcon:SetParent(chatFrame);
      currentIcon:SetSize(24, 24); -- fixes inconsistencies with blizz buttons (e.g., voice chat icons)

      if (currentIcon.Menu) then
        currentIcon.Menu:SetParent(chatFrame);
      end

      local point = bottom and "BOTTOMLEFT" or "TOPLEFT";
      local yOffset;

      if (bottom) then
        yOffset = 14 + (((indexInGroup or 1) - 1) * 26);
      else
        yOffset = -14 - (((indexInGroup or 1) - 1) * 26);
      end

			currentIcon:SetPoint(point, chatFrame.sidebar, point, 1, yOffset);

			currentIcon:Show();
			return currentIcon;

		elseif (currentIcon) then
      currentIcon:ClearAllPoints();

      if (currentIcon.Menu and obj:IsWidget(currentIcon.Menu)) then
        currentIcon.Menu:Hide();
      end

			currentIcon:Hide();
		end

		return nil;
	end

  local chatIconTypes = {
    "voiceChat";
    "professions";
    "shortcuts";
    "copyChat";
    "emotes";
    "playerStatus";
    "none";
  };

  if (tk:IsRetail()) then
    table.insert(chatIconTypes, 2, "deafen");
    table.insert(chatIconTypes, 3, "mute");
  end

  local universalIconTypes = {
    unpack(UniversalProviders:GetSidebarIconTypes());
  };
  local supportedUniversalIconTypes = {
    unpack(UniversalProviders:GetSupportedIconTypes());
  };

  C_ChatFrame.Static.ChatIconTypes = chatIconTypes;
  C_ChatFrame.Static.UniversalIconTypes = universalIconTypes;

  function C_ChatFrame.Static:PositionSideBarIcons(iconSettings, muiChatFrame, iconTypes)
    iconTypes = iconTypes or chatIconTypes;
    local supportedTypes = {};

    -- hide all:
    for _, iconType in ipairs(iconTypes) do
      supportedTypes[iconType] = true;
      PositionIcon(false, iconType);
    end

    if (not (obj:IsTable(iconSettings) and obj:IsWidget(muiChatFrame)
        and obj:IsWidget(muiChatFrame.sidebar))) then
      return;
    end

    local visibleIconTypes = {};
    local used = {};

    for _, value in ipairs(iconSettings) do
      local iconType = obj:IsTable(value) and value.type;
      local iconSupported = iconType and (tk:IsRetail()
        or not (iconType == "deafen" or iconType == "mute"));

      if (iconSupported and supportedTypes[iconType]
          and iconType ~= "none" and not used[iconType]) then
        visibleIconTypes[#visibleIconTypes + 1] = iconType;
        used[iconType] = true;
      end
    end

    for index = 1, math.min(3, #visibleIconTypes) do
      PositionIcon(true, visibleIconTypes[index], muiChatFrame, nil, index);
    end

    local bottomIndex = 1;
    for index = #visibleIconTypes, 4, -1 do
      PositionIcon(true, visibleIconTypes[index], muiChatFrame, true, bottomIndex);
      bottomIndex = bottomIndex + 1;
    end
	end

  function CreateOrSetUpIcon.mute(name)
    local btn = _G.ChatFrameToggleVoiceMuteButton;
    if (not obj:IsWidget(btn)) then
      return nil;
    end

    _G[name] = btn;
    return btn;
  end

  function CreateOrSetUpIcon.deafen(name)
    local btn = _G.ChatFrameToggleVoiceDeafenButton;
    if (not obj:IsWidget(btn)) then
      return nil;
    end

    _G[name] = btn;
    return btn;
  end

  function CreateOrSetUpIcon.voiceChat()
    local btn = _G.ChatFrameChannelButton;
    if (not obj:IsWidget(btn)) then
      return nil;
    end

    _G.MUI_ChatFrameIcon_voiceChat = btn;

    if (not tk:IsRetail()) then
      tk:KillElement(_G.ChatFrameMenuButton);
    end

    return btn;
  end

  local function CreateUniversalProviderIcon(name, providerType)
    local metadata = UniversalProviders:GetMetadata(providerType);

    if (not (obj:IsTable(metadata) and obj:IsString(metadata.iconTexture))) then
      return nil;
    end

    local btn = tk:CreateFrame("Button", nil, name);
    btn:SetNormalTexture(metadata.iconTexture);
    btn:SetHighlightAtlas("chatframe-button-highlight");
    btn:SetPushedTexture(metadata.iconTexture);

    local normalTexture = btn:GetNormalTexture();
    local pushedTexture = btn:GetPushedTexture();
    local iconSize = obj:IsNumber(metadata.iconSize) and metadata.iconSize or 18;
    local iconOffsetX = obj:IsNumber(metadata.iconOffsetX) and metadata.iconOffsetX or 0;
    local iconOffsetY = obj:IsNumber(metadata.iconOffsetY) and metadata.iconOffsetY or 0;
    local iconTexCoord = obj:IsTable(metadata.iconTexCoord) and metadata.iconTexCoord;

    local function StyleTexture(texture, alpha)
      if (not obj:IsWidget(texture)) then
        return;
      end

      texture:ClearAllPoints();
      texture:SetPoint("CENTER", iconOffsetX, iconOffsetY);
      texture:SetSize(iconSize, iconSize);

      if (iconTexCoord and #iconTexCoord == 4) then
        texture:SetTexCoord(iconTexCoord[1], iconTexCoord[2], iconTexCoord[3], iconTexCoord[4]);
      else
        texture:SetTexCoord(0, 1, 0, 1);
      end

      if (obj:IsFunction(texture.SetDesaturated)) then
        texture:SetDesaturated(metadata.iconDesaturated == true);
      end

      texture:SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
      texture:SetAlpha(alpha or 1);
    end

    StyleTexture(normalTexture, 1);
    StyleTexture(pushedTexture, 0.8);

    local function UpdateState(self)
      local isActive = UniversalProviders:IsActiveContent(providerType);
      self:SetAlpha(isActive and 1 or 0.55);

      if (obj:IsWidget(normalTexture)) then
        normalTexture:SetAlpha(isActive and 1 or 0.85);
      end
    end

    tk:SetBasicTooltip(btn, metadata.toggleTitle or metadata.title, "ANCHOR_CURSOR_RIGHT", 16, 8);
    btn:HookScript("OnShow", UpdateState);
    btn:HookScript("OnLeave", UpdateState);

    btn:SetScript("OnClick", function()
      PlaySound(tk.Constants.CLICK);

      if (UniversalProviders:IsActiveContent(providerType)) then
        SetUniversalContent("none");
      else
        SetUniversalContent(providerType);
      end

      UpdateState(btn);
    end);

    return btn;
  end

  for _, providerType in ipairs(supportedUniversalIconTypes) do
    if (providerType ~= "none") then
      CreateOrSetUpIcon[providerType] = function(name)
        return CreateUniversalProviderIcon(name, providerType);
      end
    end
  end

  function CreateOrSetUpIcon.emotes(name)
    local toggleEmotesButton = tk:CreateFrame("Button", nil, name);
    toggleEmotesButton:SetNormalTexture(string.format("%sspeechIcon", MEDIA));
    toggleEmotesButton:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
    toggleEmotesButton:SetHighlightAtlas("chatframe-button-highlight");

    tk:SetBasicTooltip(toggleEmotesButton, L["Show Chat Menu"], "ANCHOR_CURSOR_RIGHT", 16, 8);

    toggleEmotesButton:SetScript("OnClick", function(self)
      PlaySound(tk.Constants.CLICK);

      if (not OpenChatMenu(self)) then
        MayronUI:Print("This feature is currently unavailable.");
      end
    end);

    return toggleEmotesButton;
  end

  do
    local GetProfessions = _G.GetProfessions;
    local GetProfessionInfo = _G.GetProfessionInfo;
    local select = _G.select;

    if (not tk:IsRetail()) then
      ---@type LibAddonCompat
      local LibAddonCompat = _G.LibStub("LibAddonCompat-1.0");

      GetProfessions = function()
        return LibAddonCompat:GetProfessions();
      end

      GetProfessionInfo = function(spellIndex)
        return LibAddonCompat:GetProfessionInfo(spellIndex);
      end
    end

    local function GetProfessionIDs()
      --self, text, shortcut, func, nested, value
      local prof1, prof2, _, fishing, cooking, firstAid = GetProfessions();

      local professions = obj:PopTable(prof1, prof2, fishing, cooking, firstAid);
      professions = tk.Tables:Filter(professions, function(spellIndex)
        if (spellIndex) then
          local spellbookID = select(6, GetProfessionInfo(spellIndex));
          if (obj:IsNumber(spellbookID)) then
            return true;
          end
        end
      end);

      return professions;
    end

    local menuWidth = 240;
    local buttonHeight = 32;

    local function CreateProfessionButton(profMenu, spellIndex)
      local btnName = "MUI_ProfessionsMenuButton"..spellIndex;
      local btnTemplate = tk:IsRetail() and "ProfessionButtonTemplate" or "SpellButtonTemplate";
      local btn = tk:CreateFrame("CheckButton", profMenu, btnName, btnTemplate);

      local iconFrame = tk:CreateBackdropFrame("Frame", btn);
      iconFrame:SetSize(buttonHeight - 8, buttonHeight - 8);
      iconFrame:ClearAllPoints();
      iconFrame:SetPoint("LEFT", 6, 0);
      iconFrame:SetBackdrop(tk.Constants.BACKDROP);
      iconFrame:SetBackdropBorderColor(0, 0, 0, 1);

      local iconTexture = _G[btnName.."IconTexture"];
      iconTexture:SetSize(buttonHeight - 6, buttonHeight - 6);
      iconTexture:ClearAllPoints();
      iconTexture:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1);
      iconTexture:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1);
      iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);

      btn:SetSize(menuWidth - 9, buttonHeight);
      btn:SetScript("OnEnter", _G.UIMenuButton_OnEnter);
      btn:SetScript("OnLeave", _G.UIMenuButton_OnLeave);
      tk:KillElement(btn:GetCheckedTexture());
      btn:DisableDrawLayer("BACKGROUND");
      btn:DisableDrawLayer("ARTWORK");
      btn:DisableDrawLayer("HIGHLIGHT");
      btn:SetFrameLevel(20);

      local spellName = _G[btnName.."SpellName"];
      local spellSubName = _G[btnName.."SubSpellName"];
      spellName:SetWidth(300);
      spellName:ClearAllPoints();
      spellName:SetPoint("TOPLEFT", iconTexture, "TOPRIGHT", 8, 0);
      spellSubName:SetFontObject("GameFontHighlightSmall");

      local r, g, b = tk:GetThemeColor();
      btn:SetHighlightTexture(tk.Constants.SOLID_TEXTURE, "ADD");
      btn.SetHighlightTexture = tk.Constants.DUMMY_FUNC;

      local t = btn:GetHighlightTexture();
      t.SetTexture = tk.Constants.DUMMY_FUNC;
      t:SetColorTexture(r * 0.7, g * 0.7, b * 0.7, 0.4);

      btn:HookScript("OnClick", function() profMenu:Hide() end);
      return btn;
    end

    local function ProfessionsMenuOnShow(icon, menu)
      local professionIDs = GetProfessionIDs();

      if (#professionIDs == 0) then
        obj:PushTable(professionIDs);
        MayronUI:Print(L["You have no professions."]);
        menu:Hide();
        return
      end

      PositionChatIconMenu(icon, menu, true);

      for _, btn in pairs(menu.btns) do
        btn:Hide();
      end

      local spellBookFrame = _G.SpellBookFrame;
      if (obj:IsTable(spellBookFrame)) then
        if (tk:IsRetail()) then
          spellBookFrame.bookType = _G.BOOKTYPE_PROFESSION;
        end

        spellBookFrame.selectedSkillLine = 1; -- General Tab (needed to ensure offset is 0)!
      end

      local prev;
      for _, spellIndex in ipairs(professionIDs) do
        local profName, _, skillRank, skillMaxRank, _, spellbookID = GetProfessionInfo(spellIndex);

        local btn = menu.btns[spellIndex] or CreateProfessionButton(menu, spellIndex);
        menu.btns[spellIndex] = btn;

        btn:SetID(spellbookID + 1);

        if (not tk:IsRetail() and obj:IsFunction(_G.SpellButton_UpdateButton)) then
          _G.SpellButton_UpdateButton(btn);
        else
          -- dragonflight:
          local texture;

          if (obj:IsFunction(_G.GetSpellBookItemTexture)) then
            texture = _G.GetSpellBookItemTexture(btn:GetID(), _G.BOOKTYPE_PROFESSION);
          end

          if (obj:IsTable(btn.IconTexture) and obj:IsFunction(btn.IconTexture.SetTexture)) then
            btn.IconTexture:SetTexture(texture);
          end
        end

        -- Update button text:
        local spellName = _G[btn:GetName().."SpellName"];
        local text = tk.Strings:Concat(profName, " (", skillRank, "/", skillMaxRank, ")");
        spellName:SetText(text);

        btn:ClearAllPoints();

        if (not prev) then
          btn:SetPoint("TOPLEFT", 5, -4);
        else
          btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT");
        end

        btn:Show();

        prev = btn;
      end

      menu:SetHeight((#professionIDs * (buttonHeight)) + 8);
      obj:PushTable(professionIDs);

      menu.timeleft = 2.0;
      menu.counting = 0;
    end

    function CreateOrSetUpIcon.professions(name)
      local professionsIcon = tk:CreateFrame("Button", nil, name);
      professionsIcon:SetNormalTexture(string.format("%sbook", MEDIA));
      professionsIcon:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
      professionsIcon:SetHighlightAtlas("chatframe-button-highlight");

      tk:SetBasicTooltip(professionsIcon, L["Show Professions"], "ANCHOR_CURSOR_RIGHT", 16, 8);

      local template = tk:IsClassic() and "UIMenuTemplate" or "TooltipBackdropTemplate";
      local profMenu = tk:CreateFrame("Frame", nil, "MUI_ProfessionsMenu", template);
      profMenu.btns = obj:PopTable();
      profMenu.specializationIndex = 0;
      profMenu.spellOffset = 0;

      profMenu:SetSize(menuWidth, buttonHeight);
      profMenu:SetScript("OnUpdate", _G.UIMenu_OnUpdate);
      profMenu:SetScript("OnEvent", profMenu.Hide);
      profMenu:SetFrameStrata(tk.Constants.FRAME_STRATAS.TOOLTIP);
      profMenu:RegisterEvent("PLAYER_REGEN_DISABLED");

      local missingAnchor = true;

      professionsIcon:SetScript("OnClick", function(self)
        PlaySound(tk.Constants.CLICK);

        if (InCombatLockdown()) then
          MayronUI:Print(L["Cannot toggle menu while in combat."]);
          return
        end

        if (missingAnchor) then
          -- Explicitly run show script:
          profMenu:Show(); -- might have been hidden by entering combat listener
          ProfessionsMenuOnShow(self, profMenu);

          missingAnchor = nil;
          return
        end

        profMenu:SetShown(not profMenu:IsShown());

        if (profMenu:IsShown()) then
          ProfessionsMenuOnShow(self, profMenu);
          missingAnchor = nil;
        end
      end);

      return professionsIcon;
    end
  end

  function CreateOrSetUpIcon.shortcuts(name)
    local btn = tk:CreateFrame("Button", nil, name);
    btn:SetNormalTexture(string.format("%sshortcuts", MEDIA));
    btn:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
    btn:SetHighlightAtlas("chatframe-button-highlight");

    tk:SetBasicTooltip(btn, L["Show AddOn Shortcuts"], "ANCHOR_CURSOR_RIGHT", 16, 8);
    local menu = tk:CreateFrame("Frame", btn, "MUI_ShortcutsMenu", "UIDropDownMenuTemplate");

    local lines = {
      { "MUI "..L["Config Menu"], "/mui config", function() MayronUI:TriggerCommand("config") end};
      { "MUI "..L["Install"], "/mui install", function() MayronUI:TriggerCommand("install") end};
      { "MUI "..L["Layouts"], "/mui layouts", function() MayronUI:TriggerCommand("layouts") end};
      { "MUI "..L["Clear Chat Messages"], "/mui clr", function() MayronUI:TriggerCommand("clr") end};
      { "MUI "..L["Profile Manager"], "/mui profiles", function() MayronUI:TriggerCommand("profiles") end};
      { "MUI "..L["Show Profiles"], "/mui profiles list", function() MayronUI:TriggerCommand("profiles", "list") end};
      { "MUI "..L["Version"], "/mui version", function() MayronUI:TriggerCommand("version") end};
      { "MUI "..L["Report"], "/mui report", function() MayronUI:TriggerCommand("report") end};
    };

    if (obj:IsFunction(_G.SlashCmdList.Leatrix_Plus)) then
      lines[#lines + 1] = { "Leatrix Plus", _G.SLASH_Leatrix_Plus1,
        function() _G.SlashCmdList.Leatrix_Plus("") end };

      lines[#lines + 1] = { L["Toggle Alignment Grid"], "/ltp grid",
        function() _G.SlashCmdList.Leatrix_Plus("grid") end };
    end

    if (obj:IsTable(_G.Bartender4) and obj:IsFunction(_G.Bartender4.ChatCommand)) then
      lines[#lines + 1] = { "Bartender", "/bt", _G.Bartender4.ChatCommand};
    end

    if (obj:IsFunction(_G.SlashCmdList.SHADOWEDUF)) then
      lines[#lines + 1] = { "Shadowed Unit Frames", _G.SLASH_SHADOWEDUF1,
        function() _G.SlashCmdList.SHADOWEDUF("") end};
    end

    if (obj:IsFunction(_G.SlashCmdList.MASQUE)) then
      lines[#lines + 1] = { "Masque", _G.SLASH_MASQUE1, _G.SlashCmdList.MASQUE};
    end

    if (obj:IsTable(_G.Bagnon) and
      obj:IsTable(_G.Bagnon.Commands) and
      obj:IsFunction( _G.Bagnon.Commands.OnSlashCommand)) then

      lines[#lines + 1] = { "Bagnon "..L["Bank"], "/bgn bank", function()
        _G.Bagnon.Commands.OnSlashCommand("bank");
      end };

      lines[#lines + 1] = { "Bagnon "..L["Guild Bank"], "/bgn guild", function()
        _G.Bagnon.Commands.OnSlashCommand("guild");
      end, true };

      lines[#lines + 1] = { "Bagnon "..L["Void Storage"], "/bgn vault", function()
        _G.Bagnon.Commands.OnSlashCommand("vault");
      end, true };

      lines[#lines + 1] = { "Bagnon "..L["Config Menu"], "/bgn config", function()
        _G.Bagnon.Commands.OnSlashCommand("config");
      end };
    end

    local menuItems = {};

    for _, line in pairs(lines) do
      if (not line[4] or tk:IsRetail()) then
        table.insert(menuItems, {
          text = string.format("%s  %s", line[1], line[2] or "");
          notCheckable = true;
          func = line[3];
        });
      end
    end

    btn:SetScript("OnClick", function(self)
      if (ShowDropDownMenu(menuItems, menu, self)) then
        PlaySound(tk.Constants.CLICK);
      end
    end);

    return btn;
  end

 	function CreateOrSetUpIcon.playerStatus(name)
		local playerStatusButton = tk:CreateFrame("Button", nil, name);

		local listener = em:CreateEventListener(function()
			local status = _G.FRIENDS_TEXTURE_ONLINE;
			local _, _, _, _, bnetAFK, bnetDND = _G.BNGetInfo();

			if (bnetAFK) then
				status = _G.FRIENDS_TEXTURE_AFK;
			elseif (bnetDND) then
				status = _G.FRIENDS_TEXTURE_DND;
			end

			playerStatusButton:SetNormalTexture(status);
    end);

    listener:RegisterEvent("BN_INFO_CHANGED");
    em:TriggerEventListener(listener);

		playerStatusButton:SetHighlightAtlas("chatframe-button-highlight");
		tk:SetBasicTooltip(playerStatusButton, L["Change Status"], "ANCHOR_CURSOR_RIGHT", 16, 8);

		local optionText = "\124T%s.tga:16:16:0:0\124t %s";
		local availableText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE);
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY);
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY);

		local function SetOnlineStatus(btn)
      local status = btn and btn.value;
      local changed;

      if (status == FRIENDS_TEXTURE_ONLINE) then
        if (obj:IsFunction(BNSetAFK)) then
          BNSetAFK(false);
          changed = true;
        end

        if (obj:IsFunction(BNSetDND)) then
          BNSetDND(false);
          changed = true;
        end
      elseif (status == FRIENDS_TEXTURE_AFK) then
        if (obj:IsFunction(BNSetDND)) then
          BNSetDND(false);
          changed = true;
        end

        if (obj:IsFunction(BNSetAFK)) then
          BNSetAFK(true);
          changed = true;
        end
      elseif (status == FRIENDS_TEXTURE_DND) then
        if (obj:IsFunction(BNSetAFK)) then
          BNSetAFK(false);
          changed = true;
        end

        if (obj:IsFunction(BNSetDND)) then
          BNSetDND(true);
          changed = true;
        end
      end

      if (not changed and obj:IsFunction(FriendsFrame_SetOnlineStatus)) then
			  FriendsFrame_SetOnlineStatus(btn);
      end

			playerStatusButton:SetNormalTexture(status or FRIENDS_TEXTURE_ONLINE);
		end

    local statusMenu = tk:CreateFrame("Frame", playerStatusButton, "MUI_StatusMenu", "UIDropDownMenuTemplate");
    local statusOptions = {
      { text = availableText; value = FRIENDS_TEXTURE_ONLINE; };
      { text = afkText; value = FRIENDS_TEXTURE_AFK; };
      { text = dndText; value = FRIENDS_TEXTURE_DND; };
    };
    local menuItems = {};

    for _, option in ipairs(statusOptions) do
      table.insert(menuItems, {
        text = option.text;
        notCheckable = true;
        func = function()
          SetOnlineStatus({ value = option.value });
        end;
      });
    end

    playerStatusButton:SetScript("OnClick", function(self)
      if (ShowDropDownMenu(menuItems, statusMenu, self)) then
        PlaySound(tk.Constants.CLICK);
      end
    end);

		return playerStatusButton;
	end

  do
		-- accountNameCode cannot be used as |K breaks the editBox
		local function RefreshChatText(editBox)
			local chatFrame = _G[string.format("ChatFrame%d", editBox.chatFrameID)];
			local messages = obj:PopTable();
			local totalMessages = chatFrame:GetNumMessages();
      local message, r, g, b;

			for i = 1, totalMessages do
        message, r, g, b = chatFrame:GetMessageInfo(i);

        if (obj:IsString(message) and #message > 0) then
          -- |Km26|k (BSAp) or |Kq%d+|k
          message = message:gsub("|K.*|k", tk.ReplaceAccountNameCodeWithBattleTag);
          message = tk.Strings:SetTextColorByRGB(message, r, g, b);

					table.insert(messages, message);
				end
      end

			local fullText = table.concat(messages, " \n", 1, #messages);
			obj:PushTable(messages);

			editBox:SetText(fullText);
		end

    local function CreateCopyChatFrame()
      local frame = tk:CreateFrame("Frame");
      frame:SetSize(600, 300);
      frame:SetPoint("CENTER");
      frame:Hide();

      gui:AddDialogTexture(frame);
      gui:AddCloseButton(frame);
      gui:AddTitleBar(frame, L["Copy Chat Text"]);

      local editBox = tk:CreateFrame("EditBox", frame, "MUI_CopyChatEditBox");
      editBox:SetMultiLine(true);
      editBox:SetMaxLetters(99999);
      editBox:EnableMouse(true);
      editBox:SetAutoFocus(false);
      editBox:SetFontObject("GameFontHighlight");
      editBox:SetHeight(200);
      editBox.chatFrameID = 1;

      editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus();
      end);

      local refreshButton = tk:CreateFrame("Button", frame);
      refreshButton:SetSize(18, 18);
      refreshButton:SetPoint("TOPRIGHT", frame.closeBtn, "TOPLEFT", -10, -3);
      refreshButton:SetNormalTexture(tk:GetAssetFilePath("Textures\\refresh"));
      tk:ApplyThemeColor(refreshButton:GetNormalTexture());
      refreshButton:SetHighlightAtlas("chatframe-button-highlight");
      tk:SetBasicTooltip(refreshButton, L["Refresh Chat Text"]);

      refreshButton:SetScript("OnClick", function()
        RefreshChatText(editBox);
      end);

      local dropdown = gui:CreateDropDown(frame);
      local dropdownContainer = dropdown:GetFrame();
      dropdownContainer:SetSize(150, 20);
      dropdownContainer:SetPoint("TOPRIGHT", refreshButton, "TOPLEFT", -10, 0);

      local function DropDown_OnOptionSelected(_, chatFrameID)
        editBox.chatFrameID = chatFrameID;
        RefreshChatText(editBox);
      end

      for chatFrameID = 1, _G.NUM_CHAT_WINDOWS do
        local tab = _G[string.format("ChatFrame%dTab", chatFrameID)];
        local tabText = tab.Text:GetText();

        if (obj:IsString(tabText) and #tabText > 0 and tab:IsShown()) then
          dropdown:AddOption(tabText, DropDown_OnOptionSelected, chatFrameID);
        end
      end

      local scrollFrame = gui:WrapInScrollFrame(editBox);
      scrollFrame:ClearAllPoints();
      scrollFrame:SetPoint("TOPLEFT", 10, -40);
      scrollFrame:SetPoint("BOTTOMRIGHT", -10, 10);

      scrollFrame:HookScript("OnScrollRangeChanged", function(self)
        local maxScroll = self:GetVerticalScrollRange();
        self:SetVerticalScroll(maxScroll);
      end);

      local bg = tk:SetBackground(scrollFrame, 0, 0, 0, 0.4);
      bg:ClearAllPoints();
      bg:SetPoint("TOPLEFT", -5, 5);
      bg:SetPoint("BOTTOMRIGHT", 5, -5);

      frame.editBox = editBox;
      frame.dropdown = dropdown;
      return frame;
    end

		function CreateOrSetUpIcon.copyChat(name)
			local copyChatButton = tk:CreateFrame("Button", nil, name);
			copyChatButton:SetNormalTexture(string.format("%scopyIcon", MEDIA));
			copyChatButton:GetNormalTexture():SetVertexColor(tk.Constants.COLORS.GOLD:GetRGB());
			copyChatButton:SetHighlightAtlas("chatframe-button-highlight");

			tk:SetBasicTooltip(copyChatButton, L["Copy Chat Text"], "ANCHOR_CURSOR_RIGHT", 16, 8);

			copyChatButton:SetScript("OnClick", function(self)
        PlaySound(tk.Constants.MENU_OPENED_CLICK);
				if (not self.chatTextFrame) then
					self.chatTextFrame = CreateCopyChatFrame();
				end

				-- get chat frame text:
				RefreshChatText(self.chatTextFrame.editBox);
				self.chatTextFrame:SetShown(not self.chatTextFrame:IsShown());

				local tab = _G[string.format("ChatFrame%dTab", self.chatTextFrame.editBox.chatFrameID)];
				local tabText = tab.Text:GetText();
				self.chatTextFrame.dropdown:SetLabel(tabText);

				self:GetScript("OnLeave")(self);
			end);

			return copyChatButton;
		end
	end
end
