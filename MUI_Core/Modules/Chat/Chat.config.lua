-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local _, C_ChatModule = MayronUI:ImportModule("ChatModule");
local table, string, unpack, tostring, ipairs = _G.table, _G.string, _G.unpack, _G.tostring, _G.ipairs;
local tremove, PlaySound, GetChannelList = _G.table.remove, _G.PlaySound, _G.GetChannelList;
local BetterDate, SetCVar, GetCVar, time = _G.BetterDate, _G.SetCVar, _G.GetCVar, _G.time;

---@param configModule ConfigMenu
function C_ChatModule:GetConfigTable(_, configModule)
  local highlightFrames;
  local chatIconDropdowns = {};

  local function CreateDefaultChatButtonStates()
    if (tk:IsRetail()) then
      return {
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
    end

    return {
      {
        L["Character"];
        L["Spell Book"];
        L["Talents"];
      };
      {
        key = "C";
        L["Reputation"];
        L[(tk:IsWrathClassic() and "LFG") or "Skills"];
        L["Quest Log"];
      };
      {
        key = "S";
        L[((tk:IsRetail() or tk:IsWrathClassic()) and "Achievements") or "Friends"];
        L[(tk:IsWrathClassic() and "Currency") or "Guild"];
        L["Macros"];
      };
    };
  end

  local function NormalizeChatButtonValue(value, fallback)
    local function IsAllowedOption(optionValue)
      if (not obj:IsString(optionValue) or optionValue == tk.Strings.Empty) then
        return false;
      end

      for _, option in ipairs(C_ChatModule.Static.ButtonNames or {}) do
        if (option == optionValue) then
          return true;
        end
      end

      return false;
    end

    local function GetLocalizedAlias(optionValue)
      if (not obj:IsString(optionValue)) then
        return nil;
      end

      local localizedOptions = {
        ["Character"] = L["Character"];
        ["Bags"] = L["Bags"];
        ["Friends"] = L["Friends"];
        ["Guild"] = L["Guild"];
        ["Help Menu"] = L["Help Menu"];
        ["Main Menu"] = L["Main Menu"];
        ["Store"] = L["Store"];
        ["PVP"] = L["PVP"];
        ["Player Spells"] = L["Player Spells"];
        ["Professions"] = L["Professions"];
        ["Achievements"] = L["Achievements"];
        ["Quest Log"] = L["Quest Log"];
        ["Calendar"] = L["Calendar"];
        ["Dungeon Finder"] = L["Dungeon Finder"];
        ["Adventure Guide"] = L["Adventure Guide"];
        ["Collections Journal"] = L["Collections Journal"];
        ["Macros"] = L["Macros"];
        ["World Map"] = L["World Map"];
        ["Reputation"] = L["Reputation"];
        ["PVP Score"] = L["PVP Score"];
        ["Currency"] = L["Currency"];
        ["Spell Book"] = L["Spell Book"];
        ["Talents"] = L["Talents"];
        ["Raid"] = L["Raid"];
        ["Skills"] = L["Skills"];
        ["Glyphs"] = L["Glyphs"];
        ["LFG"] = L["LFG"];
      };

      return localizedOptions[optionValue];
    end

    if (IsAllowedOption(value)) then
      return value;
    end

    local localizedValue = GetLocalizedAlias(value);

    if (IsAllowedOption(localizedValue)) then
      return localizedValue;
    end

    if (IsAllowedOption(fallback)) then
      return fallback;
    end

    local localizedFallback = GetLocalizedAlias(fallback);

    if (IsAllowedOption(localizedFallback)) then
      return localizedFallback;
    end

    return C_ChatModule.Static.ButtonNames and C_ChatModule.Static.ButtonNames[1];
  end

  local function EnsurePrimaryChatButtons()
    local chatFrame = obj:IsTable(db.profile.chat) and obj:IsTable(db.profile.chat.chatFrames)
      and db.profile.chat.chatFrames.BOTTOMLEFT;

    if (not obj:IsTable(chatFrame)) then
      return CreateDefaultChatButtonStates();
    end

    local buttonStates = chatFrame.buttons and chatFrame.buttons:GetUntrackedTable();
    local defaults = CreateDefaultChatButtonStates();
    local changed;

    if (not obj:IsTable(buttonStates)) then
      buttonStates = {};
      changed = true;
    end

    for index, defaultState in ipairs(defaults) do
      local state = buttonStates[index];

      if (not obj:IsTable(state)) then
        buttonStates[index] = tk.Tables:Copy(defaultState, true);
        changed = true;
      else
        local left = NormalizeChatButtonValue(state[1], defaultState[1]);
        local middle = NormalizeChatButtonValue(state[2], defaultState[2]);
        local right = NormalizeChatButtonValue(state[3], defaultState[3]);

        if (left ~= state[1] or middle ~= state[2] or right ~= state[3]) then
          state[1] = left;
          state[2] = middle;
          state[3] = right;
          changed = true;
        end

        if (defaultState.key and not obj:IsString(state.key)) then
          state.key = defaultState.key;
          changed = true;
        end
      end
    end

    if (changed) then
      db:SetPathValue("profile.chat.chatFrames.BOTTOMLEFT.buttons", buttonStates);
    end

    return buttonStates;
  end

  local function RefreshHighlightFrameIndexes()
    if (not obj:IsTable(highlightFrames)) then
      return;
    end

    for index, highlightFrame in ipairs(highlightFrames) do
      if (obj:IsWidget(highlightFrame)) then
        highlightFrame.__muiHighlightIndex = index;
      end
    end
  end

  local iconOptionLabels = {
    L["Chat Channels"];
    L["Professions"];
    L["AddOn Shortcuts"];
    L["Copy Chat"];
    L["Emotes"];
    L["Online Status"];
    L["None"]
  }

  local iconOptions = {
    [iconOptionLabels[1]]   = "voiceChat";
    [iconOptionLabels[2]]   = "professions";
    [iconOptionLabels[3]]   = "shortcuts";
    [iconOptionLabels[4]]   = "copyChat";
    [iconOptionLabels[5]]   = "emotes";
    [iconOptionLabels[6]]   = "playerStatus";
    [iconOptionLabels[7]]   = "none";
  };

  if (tk:IsRetail()) then
    table.insert(iconOptionLabels, 2, L["Deafen"]);
    table.insert(iconOptionLabels, 3, L["Mute"]);
    iconOptions[iconOptionLabels[2]] = "deafen";
    iconOptions[iconOptionLabels[3]] = "mute";
  end

  local function RefreshSideBarIcons()
    local chatModule = MayronUI:ImportModule("ChatModule");

    if (obj:IsTable(chatModule) and obj:IsFunction(chatModule.RefreshSideBarIcons)) then
      chatModule:RefreshSideBarIcons();
    end
  end

  local function CreateIconDropdownConfig(id, pathRoot, options, dropdowns, collection)
    return {
      name = tk.Strings:Concat("Icon ", id);
      type = "dropdown";
      dbPath = tk.Strings:Concat(pathRoot, "[", id, "].type");
      options = options;
      OnLoad = function(_, container)
        dropdowns[id] = container.component;
      end;
      GetValue = function(_, value)
        local _, label = tk.Tables:First(options, function(v) return v == value end);
        return label;
      end;
      SetValue = function(self, newType, oldType)
        local oldIcon = _G["MUI_ChatFrameIcon_"..tostring(oldType)];

        if (obj:IsWidget(oldIcon)) then
          oldIcon:ClearAllPoints();
          oldIcon:Hide();
        end

        if (newType ~= "none") then
          for otherId, otherValue in collection:Iterate() do
            local otherType = otherValue.type;

            if (otherId ~= id and newType == otherType) then
              local otherPath = tk.Strings:Concat(pathRoot, "[", otherId, "].type");
              db:SetPathValue(otherPath, oldType, nil, true);

              local dropdown = dropdowns[otherId]; ---@type DropDownMenu
              if (dropdown) then
                local _, label = tk.Tables:First(options, function(v) return v == oldType end);
                dropdown:SetLabel(label);
              end
            end
          end
        end

        db:SetPathValue(self.dbPath, newType);
        RefreshSideBarIcons();
      end;
    };
  end

  -- Config Data ----------------------
  local function GetButtonStateTitle(buttonID, buttonState)
    if (buttonID == 1 or not (obj:IsTable(buttonState) and obj:IsString(buttonState.key))) then
      return L["Standard Chat Buttons"];
    end

    local labels = {};

    if (buttonState.key:find("C")) then
      labels[#labels + 1] = L["Control"];
    end

    if (buttonState.key:find("S")) then
      labels[#labels + 1] = L["Shift"];
    end

    if (buttonState.key:find("A")) then
      labels[#labels + 1] = L["Alt"];
    end

    if (not labels[1]) then
      return string.format(L["Chat Buttons with Modifier Key %d"], buttonID);
    end

    return tk.Strings:JoinWithSpace(L["Chat Buttons"], "(", table.concat(labels, " + "), ")");
  end

  local function CreateButtonConfigTable(dbPath, buttonID, buttonState, enabledWhen, addWidget)
    local configTable = obj:PopTable();
    local defaultState = CreateDefaultChatButtonStates()[buttonID] or CreateDefaultChatButtonStates()[1] or {};

    if (not obj:IsTable(buttonState)) then
      buttonState = defaultState;
    end

    table.insert(configTable, {
      name = GetButtonStateTitle(buttonID, buttonState),
      type = "title"
    });

    table.insert(configTable, {
      name = L["Left Button"],
      type = "dropdown",
      dbPath = string.format("%s.buttons[%d][1]", dbPath, buttonID),
      options = C_ChatModule.Static.ButtonNames,
      enabled = enabledWhen,
      GetValue = function(_, value)
        return NormalizeChatButtonValue(value, buttonState[1] or defaultState[1]);
      end,
      OnLoad = addWidget
    });

    table.insert(configTable, {
      name = L["Middle Button"],
      type = "dropdown",
      dbPath = string.format("%s.buttons[%d][2]", dbPath, buttonID),
      options = C_ChatModule.Static.ButtonNames,
      enabled = enabledWhen,
      GetValue = function(_, value)
        return NormalizeChatButtonValue(value, buttonState[2] or defaultState[2]);
      end,
      OnLoad = addWidget
    });

    table.insert(configTable, {
      name = L["Right Button"],
      type = "dropdown",
      dbPath = string.format("%s.buttons[%d][3]", dbPath, buttonID),
      options = C_ChatModule.Static.ButtonNames,
      enabled = enabledWhen,
      GetValue = function(_, value)
        return NormalizeChatButtonValue(value, buttonState[3] or defaultState[3]);
      end,
      OnLoad = addWidget
    });

    table.insert(configTable, { type = "divider" });

    if (buttonID == 1) then
      return unpack(configTable);
    end

    for _, modKey in obj:IterateArgs("Control", "Shift", "Alt") do
      local modKeyFirstChar = string.sub(modKey, 1, 1);

      table.insert(configTable, {
        name = L[modKey],
        height = 40,
        type = "check",
        dbPath = string.format("%s.buttons[%d].key", dbPath, buttonID),
        enabled = enabledWhen,
        OnLoad = addWidget,

        GetValue = function(_, currentValue)
          if (obj:IsString(currentValue) and currentValue:find(modKeyFirstChar)) then
            return true;
          end

          return false;
        end,

        SetValue = function(self, checked, oldValue)
          if (checked) then
            -- add it
            local newValue = (oldValue and tk.Strings:Concat(oldValue, modKeyFirstChar)) or modKeyFirstChar;
            db:SetPathValue(self.dbPath, newValue);

          elseif (oldValue and oldValue:find(modKeyFirstChar)) then
            -- remove it
            local newValue = oldValue:gsub(modKeyFirstChar, tk.Strings.Empty);
            db:SetPathValue(self.dbPath, newValue);
          end
        end
      });
    end

    return unpack(configTable);
  end

  local function BuildChatButtonsConfigTable()
    local children = obj:PopTable();
    local function IsPrimaryChatWindowEnabled()
      return obj:IsTable(db.profile.chat.chatFrames.BOTTOMLEFT)
        and db.profile.chat.chatFrames.BOTTOMLEFT.enabled;
    end

    local buttonStates = EnsurePrimaryChatButtons();
    local totalStates = math.max(#buttonStates, 1);

    for buttonID = 1, totalStates do
      tk.Tables:AddAll(children,
        CreateButtonConfigTable("profile.chat.chatFrames.BOTTOMLEFT", buttonID,
          buttonStates[buttonID], IsPrimaryChatWindowEnabled));
    end

    return children;
  end

  local function GetMutableHighlightTable(dbPath)
    local parsedValue = db:ParsePathValue(dbPath);
    local highlightTable = parsedValue and parsedValue.GetUntrackedTable
      and parsedValue:GetUntrackedTable();

    if (not obj:IsTable(highlightTable)) then
      highlightTable = {};
    end

    return highlightTable;
  end

  local function ListFrame_OnAddItem(_, item, getPath, updateFontString)
    local newText = item.name:GetText();
    local dbPath = getPath();
    local highlightTable = GetMutableHighlightTable(dbPath);

    highlightTable[#highlightTable + 1] = newText;
    db:SetPathValue(dbPath, highlightTable);

    updateFontString();
  end

  local function ListFrame_OnRemoveItem(_, item, getPath, updateFontString)
    local deleteText = item.name:GetText();
    local dbPath = getPath();
    local highlightTable = GetMutableHighlightTable(dbPath);

    local index = tk.Tables:IndexOf(highlightTable, deleteText);

    if (obj:IsNumber(index)) then
      tremove(highlightTable, index);
      db:SetPathValue(dbPath, highlightTable);
    end

    updateFontString();
  end

  local ShowListFrame;
  do
    ---@param self ListFrame
    ---@param dbPath string
    local function ListFrame_OnShow(self, getPath)
      local dbPath = getPath();
      local highlightTable = GetMutableHighlightTable(dbPath);

      for _, text in ipairs(highlightTable) do
        self:AddItem(text);
      end
    end

    function ShowListFrame(btn, getPath, updateFontString)
      if (btn.listFrame) then
        btn.listFrame:SetShown(true);
        return
      end

      ---@type ListFrame
      local C_ListFrame = obj:Import("MayronUI.ListFrame");

      btn.listFrame = C_ListFrame(btn.name, getPath, updateFontString);
      btn.listFrame:AddRowText(L["Enter text to highlight:"]);
      btn.listFrame:SetScript("OnShow", ListFrame_OnShow);
      btn.listFrame:SetShown(true);

      btn.listFrame:SetScript("OnRemoveItem", ListFrame_OnRemoveItem);
      btn.listFrame:SetScript("OnAddItem", ListFrame_OnAddItem);
    end
  end

  local GetTextHighlightingFrameConfigTable;
  do
    local function GetTextToHighlightLabel(highlighted)
      if (not highlighted[1]) then
        return L["NO_HIGHLIGHT_TEXT_ADDED"];
      end

      local color = obj:IsTable(highlighted.color) and highlighted.color or {1, 1, 1};
      local coloredText = obj:PopTable();

      for index, text in ipairs(highlighted) do
        coloredText[index] = tk.Strings:SetTextColorByRGB(text, unpack(color));
      end

      local label = tk.Strings:Join(" | ", coloredText); -- this pushes the table
      return tk.Strings:JoinWithSpace(L["Text to Highlight (case insensitive):"], label);
    end

    local function GetDbPath(frame)
      local id = frame and frame.__muiHighlightIndex or tk.Tables:IndexOf(highlightFrames, frame);

      if (not obj:IsNumber(id)) then
        id = 1;
      end

      return "profile.chat.highlighted[" .. id .. "]";
    end

    function GetTextHighlightingFrameConfigTable(tbl)
      local fontString, frame;

      local function UpdateFontString()
        local path = GetDbPath(frame);
        local newTbl = GetMutableHighlightTable(path);
        local newContent = GetTextToHighlightLabel(newTbl);
        fontString:SetText(newContent);
      end

      local function RemoveTextHighlighting()
        local highlighted = db.profile.chat.highlighted:GetUntrackedTable();

        if (not obj:IsTable(highlighted)) then
          return;
        end

        local id = tk.Tables:IndexOf(highlightFrames, frame);

        if (not obj:IsNumber(id)) then
          return;
        end

        tremove(highlighted, id);
        tremove(highlightFrames, id);
        RefreshHighlightFrameIndexes();

        db:SetPathValue("profile.chat.highlighted", highlighted);
        configModule:RemoveComponent(frame);
      end

      local frameConfig = {
        type = "frame";
        OnLoad = function(_, f)
          frame = f:GetFrame();
          table.insert(highlightFrames, frame);
          RefreshHighlightFrameIndexes();
        end;
        OnClose = RemoveTextHighlighting;
        children = {
          { type = "fontstring";
            content = GetTextToHighlightLabel(tbl);
            OnLoad = function(_, container)
              fontString = container.content;
            end;
          };
          { type = "check";
            name = L["Show in Upper Case"];
            dbPath = function() return tk.Strings:Join(".", GetDbPath(frame), "upperCase"); end;
          };
          { type = "color";
            useIndexes = true;
            name = L["Set Color"];
            dbPath = function() return tk.Strings:Join(".", GetDbPath(frame), "color"); end;
            OnValueChanged = UpdateFontString;
          };
          { type = "button";
            name = L["Edit Text"];
            padding = 15;
            OnClick = function(btn)
              local getPath = function() return GetDbPath(frame) end;
              ShowListFrame(btn, getPath, UpdateFontString);
            end;
          },
          { type = "divider"; };
          { type = "dropdown";
            name = L["Play Sound"];
            dbPath = function() return tk.Strings:Join(".", GetDbPath(frame), "sound"); end;
            tooltip = L["Play a sound effect when any of the selected text appears in chat."];
            options = tk.Constants.SOUND_OPTIONS;
          },
          { type = "button";
            texture = "Interface\\COMMON\\VOICECHAT-SPEAKER";
            width = 20;
            height = 40;
            texHeight = 20;
            OnClick = function()
              local soundPath = tk.Strings:Join(".", GetDbPath(frame), "sound");
              local sound = db:ParsePathValue(soundPath);

              if (obj:IsNumber(sound)) then
                PlaySound(sound);
              end
            end
          }
        };
      };

      return frameConfig;
    end
  end

  local function AddTextHighlighting()
    highlightFrames = highlightFrames or obj:PopTable();
    local highlighted = db.profile.chat.highlighted:GetUntrackedTable();
    local id = #highlighted + 1;

    highlighted[id] = obj:PopTable();
    highlighted[id].color = obj:PopTable(1, 0, 0);
    highlighted[id].sound = false;
    highlighted[id].upperCase = false;

    db.profile.chat.highlighted = highlighted;
    local config = GetTextHighlightingFrameConfigTable(highlighted[id]);
    configModule:RenderComponent(nil, config);
  end

  local channelNames = obj:PopTable();
  for _, channelName in obj:IterateValues(GetChannelList()) do
    if (obj:IsString(channelName)) then
      channelNames[#channelNames + 1] = channelName;
    end
  end

  local customTimestampColor;

  local generalChildren = obj:PopTable();
  tk.Tables:AddAll(generalChildren,
    { type = "title"; name = L["Chat"]; marginTop = 0; },
    {
      type = "fontstring";
      content = L["These settings control the main chat window and its general behavior."];
    },
    { name = L["Enabled"];
      tooltip = "If checked, this module will be enabled.";
      type = "check";
      requiresReload = true;
      dbPath = "enabled",
    },
    { type = "divider" },
    { type = "fontstring"; subtype = "header"; content = L["Edit Box (Message Input Box)"]; },
    { name = L["Top"];
      type = "radio";
      groupName = "editBox_tabPositions";
      dbPath = "profile.chat.editBox.position";
      GetValue = function(_, value) return value == "TOP"; end;
      SetValue = function(self)
        db:SetPathValue(self.dbPath, "TOP");
        db:SetPathValue("profile.chat.editBox.yOffset", 8);
      end;
    },
    { name = L["Bottom"];
      type = "radio";
      groupName = "editBox_tabPositions";
      dbPath = "profile.chat.editBox.position";
      GetValue = function(_, value) return value == "BOTTOM"; end;
      SetValue = function(self)
        db:SetPathValue(self.dbPath, "BOTTOM");
        db:SetPathValue("profile.chat.editBox.yOffset", -8);
      end;
    },
    { name = L["Height"];
      type = "slider";
      min = 20; max = 50;
      tooltip = L["The height of the edit box."];
      dbPath = "profile.chat.editBox.height";
    },
    { type = "divider" },
    { type = "fontstring"; subtype = "header"; content = L["Timestamps"]; },
    { name = _G.OPTION_TOOLTIP_TIMESTAMPS;
      type = "dropdown";
      GetValue = function() return GetCVar("showTimestamps"); end;
      SetValue = function(_, value)
        SetCVar("showTimestamps", value);
        _G.CHAT_TIMESTAMP_FORMAT = (value == "none") and nil or value;
      end;
      options = {
        [L["None"]] = "none";
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMM, time())] = _G.TIMESTAMP_FORMAT_HHMM;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMMSS, time())] = _G.TIMESTAMP_FORMAT_HHMMSS;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMM_AMPM, time())] = _G.TIMESTAMP_FORMAT_HHMM_AMPM;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMMSS_AMPM, time())] = _G.TIMESTAMP_FORMAT_HHMMSS_AMPM;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMM_24HR, time())] = _G.TIMESTAMP_FORMAT_HHMM_24HR;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMMSS_24HR, time())] = _G.TIMESTAMP_FORMAT_HHMMSS_24HR;
        [BetterDate(_G.TIMESTAMP_FORMAT_HHMM, time())] = _G.TIMESTAMP_FORMAT_HHMM;
      };
    },
    { type = "check";
      name = L["Use Fixed Timestamp Color"];
      width = 230;
      dbPath = "profile.chat.useTimestampColor";
      OnValueChanged = function(value)
        if (customTimestampColor) then
          customTimestampColor:SetEnabled(value);
        end
      end
    },
    { type = "color";
      name = L["Set Timestamp Color"];
      dbPath = "profile.chat.timestampColor";
      enabled = db.profile.chat.useTimestampColor;
      OnLoad = function(_, widget) customTimestampColor = widget; end;
    },
    { type = "divider" },
    {
      name = L["Button Swapping in Combat"];
      type = "check";
      dbPath = "profile.chat.swapInCombat";
      tooltip = L["Allow the use of modifier keys to swap chat buttons while in combat."];
    }
  );

  local buttonsChildren = obj:PopTable();
  local chatButtonChildren = BuildChatButtonsConfigTable();

  tk.Tables:AddAll(buttonsChildren,
    { name = L["Chat Buttons"]; type = "title"; marginTop = 0; },
    {
      type = "fontstring";
      content = L["These settings control the three shortcut buttons on the active main chat window."];
    }
  );
  tk.Tables:AddAll(buttonsChildren, unpack(chatButtonChildren));

  local iconChildren = obj:PopTable();
  tk.Tables:AddAll(iconChildren,
    { name = L["Icons"]; type = "title"; marginTop = 0; },
    {
      type = "fontstring";
      content = L["These settings control the vertical sidebar icons attached to the chat window."];
    },
    { type = "fontstring"; subtype = "header"; content = L["Vertical Side Icons"]; },
    { type = "fontstring";
      content = L["These icons belong to the main chat window and are shown vertically on its sidebar."];
    },
    { type = "loop",
      loops = 6,
      func = function(id)
        return CreateIconDropdownConfig(id, "profile.chat.icons", iconOptions,
          chatIconDropdowns, db.profile.chat.icons);
      end
    }
  );

  local textChildren = obj:PopTable();
  tk.Tables:AddAll(textChildren,
    { name = L["Text Highlighting"]; type = "title"; marginTop = 0; },
    {
      type = "fontstring";
      content = L["These settings control highlighted text and custom chat channel aliases."];
    },
    { type = "fontstring"; subtype = "header"; content = L["Text Highlighting"]; },
    { type = "fontstring";
      content = L["MANAGE_TEXT_HIGHLIGHTING"]:gsub("\n", " ");
    },
    { type = "loop";
      args = db.profile.chat.highlighted:GetUntrackedTable();
      func = function(_, tbl)
        highlightFrames = highlightFrames or obj:PopTable();
        return GetTextHighlightingFrameConfigTable(tbl, configModule);
      end
    },
    { type = "button";
      name = L["Add Text Highlighting"];
      OnClick = AddTextHighlighting;
    },
    { type = "divider"; },
    { type = "fontstring"; subtype = "header"; content = L["Channel Name Aliases"]; },
    { type = "fontstring";
      content = L["Set short, custom aliases for chat channel names."];
      width = "fill";
    },
    { type = "check";
      name = L["Enable Custom Aliases"];
      dbPath = "profile.chat.enableAliases";
    },
    { type = "slider";
      name = L["Alias Brightness"];
      dbPath = "profile.chat.brightness";
      min = 0;
      max = 1;
      step = 0.1;
    },
    { name = _G.CHAT_MSG_GUILD;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_GUILD .. "]";
    },
    { name = _G.CHAT_MSG_OFFICER;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_OFFICER .. "]";
    },
    { name = _G.CHAT_MSG_PARTY;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_PARTY .. "]";
    },
    { name = _G.CHAT_MSG_PARTY_LEADER;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_PARTY_LEADER .. "]";
    },
    { name = _G.CHAT_MSG_RAID;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_RAID .. "]";
    },
    { name = _G.CHAT_MSG_RAID_LEADER;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_RAID_LEADER .. "]";
    },
    { name = _G.CHAT_MSG_RAID_WARNING;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.CHAT_MSG_RAID_WARNING .. "]";
    },
    { name = _G.INSTANCE_CHAT;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.INSTANCE_CHAT .. "]";
      client = "retail";
    },
    { name = _G.INSTANCE_CHAT_LEADER;
      type = "textfield";
      dbPath = "profile.chat.aliases[" .. _G.INSTANCE_CHAT_LEADER .. "]";
      client = "retail";
    },
    { type = "fontstring";
      subtype = "header";
      content = L["Server Channels"];
      width = "fill";
    },
    { type = "loop";
      args = channelNames;
      func = function(_, channelName)
        return {
          name = tk.Strings:SplitByCamelCase(channelName);
          type = "textfield";
          dbPath = tk.Strings:Concat("profile.chat.aliases[", channelName, "]");
        };
      end;
    }
  );

  return {
    type = "menu",
    module = "ChatModule",
    name = L["Chat"],
    dbPath = "profile.chat",
    tabs = {
      L["General"];
      L["Chat Buttons"];
      L["Icons"];
      L["Text Highlighting"];
    };
    children = {
      generalChildren;
      buttonsChildren;
      iconChildren;
      textChildren;
    }
  };
end
