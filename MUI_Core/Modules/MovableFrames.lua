-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents();

local InCombatLockdown, unpack = _G.InCombatLockdown, _G.unpack;
local pairs, ipairs, table, xpcall = _G.pairs, _G.ipairs, _G.table, _G.xpcall;
local IsAddOnLoaded, strsplit = _G.IsAddOnLoaded, _G.strsplit;
local C_Timer = _G.C_Timer;

---@class MovableModule : BaseModule
local C_MovableFramesModule = MayronUI:RegisterModule("MovableFramesModule", L["Movable Frames"]);

db:AddToDefaults("global.movable", {
  enabled = true;
  clampToScreen = true;
  positions = {};
  talkingHead = { position = "TOP"; yOffset = -50 };
});

local characterSubFrames = { "ReputationFrame" };

local BlizzardFrames = {
  "InterfaceOptionsFrame";
  "QuestFrame";
  "GossipFrame";
  "DurabilityFrame";
  "FriendsFrame";
  "MailFrame";
  "PetStableFrame";
  "SpellBookFrame";
  "PetitionFrame";
  "BankFrame";
  "TimeManagerFrame";
  "VideoOptionsFrame";
  "AddonList";
  "ChatConfigFrame";
  "LootFrame";
  "ReadyCheckFrame";
  "TradeFrame";
  "TabardFrame";
  "GuildRegistrarFrame";
  "ItemTextFrame";
  "DressUpFrame";
  "GameMenuFrame";
  "TaxiFrame";
  "HelpFrame";
  "MerchantFrame";
  "ChannelFrame";
  "WorldMapFrame";
  {
    "CharacterFrame";
    subFrames = characterSubFrames;
    clickedFrames = {
      "CharacterFrameTab1"; "CharacterFrameTab2"; "CharacterFrameTab3";
      "CharacterFrameTab4"; "CharacterFrameTab5";
    };
  };

  dontSavePosition = {
    Blizzard_DebugTools = "ScriptErrorsFrame";
    Blizzard_AuctionUI = "WowTokenGameTimeTutorial";
    Blizzard_QuestChoice = "QuestChoiceFrame";
    TradeSkillDW = "TradeSkillDW_QueueFrame";
  };

  Blizzard_GarrisonUI = {
    "GarrisonCapacitiveDisplayFrame"; "GarrisonLandingPage";
    "GarrisonMissionFrame"; "GarrisonBuildingFrame";
    "GarrisonRecruitSelectFrame"; "GarrisonRecruiterFrame";
  };

  Blizzard_CovenantRenown = { "CovenantRenownFrame" };

  Blizzard_Soulbinds = { "SoulbindViewer" };
  Blizzard_MajorFactions = {
    "ExpansionLandingPage", "MajorFactionRenownFrame", subFrames = { "MajorFactionRenownFrame.HeaderFrame" } };

  Blizzard_LookingForGuildUI = {
    hooked = {
      {
        "LookingForGuildFrame";
        funcName = "LookingForGuildFrame_CreateUIElements";
      };
    };
  };

  Blizzard_VoidStorageUI = {
    "VoidStorageFrame",
    subFrames = { "VoidStorageBorderFrame" },
    onLoad = function()
      _G.VoidStorageBorderFrameHeader:SetTexture("");
    end
  };
  Blizzard_ItemAlterationUI = "TransmogrifyFrame";
  Blizzard_GuildBankUI = { "GuildBankFrame", subFrames = { "GuildBankFrame.Emblem" }};
  Blizzard_TalentUI = { "PlayerTalentFrame"; subFrames = tk:IsWrathClassic() and { "GlyphFrame" };  };
  Blizzard_ClassTalentUI = { "ClassTalentFrame"; };
  Blizzard_GlyphUI = { "PlayerTalentFrame"; subFrames = tk:IsWrathClassic() and { "GlyphFrame" };  };
  Blizzard_MacroUI = "MacroFrame";
  Blizzard_BindingUI = "KeyBindingFrame";
  Blizzard_Calendar = "CalendarFrame";
  Blizzard_GuildUI = "GuildFrame";
  Blizzard_Professions = "ProfessionsFrame";
  Blizzard_ProfessionsBook = "ProfessionsBookFrame";
  Blizzard_PlayerSpells = { "PlayerSpellsFrame"; "SpellBookFrame"; };
  Blizzard_TradeSkillUI = "TradeSkillFrame";
  Blizzard_TalkingHeadUI = "TalkingHeadFrame";
  Blizzard_EncounterJournal = {
    "EncounterJournal";
    onLoad = function()
      local setPoint = _G.EncounterJournalTooltip.SetPoint;
      _G.EncounterJournalTooltip.SetPoint =
        function(self, p, f, rp, x, y)
          f:ClearAllPoints();
          setPoint(self, p, f, rp, x, y);
        end
    end;
  };
  Blizzard_ArchaeologyUI = "ArchaeologyFrame";
  Blizzard_AchievementUI = {
    "AchievementFrame";
    subFrames = { "AchievementFrameHeader", "AchievementFrame.Header" };
  };
  Blizzard_AuctionUI = "AuctionFrame";
  Blizzard_AuctionHouseUI = "AuctionHouseFrame";
  Blizzard_TrainerUI = "ClassTrainerFrame";
  Blizzard_GuildControlUI = "GuildControlUI";
  Blizzard_InspectUI = {"InspectFrame", subFrames = { "InspectTalentFrame" }};
  Blizzard_ItemSocketingUI = "ItemSocketingFrame";
  Blizzard_ItemUpgradeUI = "ItemUpgradeFrame";
  Blizzard_AzeriteUI = "AzeriteEmpoweredItemUI";
  Blizzard_CraftUI = "CraftFrame";

  -- TODO: These are currently bugged in Dragonflight:
  --Blizzard_Collections = "CollectionsJournal";
  --Blizzard_Communities = "CommunitiesFrame";
};

if (tk:IsClassic()) then
  table.insert(characterSubFrames, "HonorFrame");
else
  table.insert(characterSubFrames, "TokenFrame");
  table.insert(characterSubFrames, "TokenFrameContainer");
end

if (tk:IsRetail()) then
  table.insert(BlizzardFrames, "QuestLogPopupDetailFrame");
  table.insert(BlizzardFrames, "LFGDungeonReadyStatus");
  table.insert(BlizzardFrames, "RecruitAFriendFrame");
  table.insert(BlizzardFrames, "LFGDungeonReadyDialog");
  table.insert(BlizzardFrames, "LFDRoleCheckPopup");
  table.insert(BlizzardFrames, "GuildInviteFrame");
  table.insert(BlizzardFrames, "BonusRollMoneyWonFrame");
  table.insert(BlizzardFrames, "BonusRollFrame");
  table.insert(BlizzardFrames, "PVEFrame");
  table.insert(BlizzardFrames, "PetBattleFrame.ActiveAlly");
  table.insert(BlizzardFrames, "PetBattleFrame.ActiveEnemy");
else
  table.insert(BlizzardFrames, "QuestLogFrame");
  table.insert(BlizzardFrames, "WorldStateScoreFrame");
end

if (tk:IsBCClassic() or tk:IsWrathClassic()) then
  table.insert(characterSubFrames, "PetPaperDollFrameCompanionFrame");
  table.insert(BlizzardFrames, "LFGParentFrame");
end

local function CanMove(frame)
  if (not (obj:IsTable(frame) and obj:IsFunction(frame.RegisterForDrag))) then
    return false;
  end

  local isProtected = obj:IsFunction(frame.IsProtected) and frame:IsProtected();
  return not (isProtected and InCombatLockdown());
end

local function GetFrame(frameName)
  local frame = _G[frameName];

  if (not frame) then
    for _, key in obj:IterateArgs(strsplit(".", frameName)) do
      if (not frame) then
        frame = _G[key];
      else
        frame = frame[key];
      end
    end
  end

  -- TODO: Enable these type of errors in DevMode
  -- obj:Assert(obj:IsTable(frame), "Could not find frame '%s'", frameName);

  if (not obj:IsTable(frame)) then
    return nil;
  end

  return frame;
end

local function CaptureOriginalPoint(frame)
  if (not obj:IsWidget(frame)) then
    return;
  end

  if (frame.__muiOriginalPoint or frame:GetNumPoints() == 0) then
    return;
  end

  local point = obj:PopTable(frame:GetPoint());

  if (obj:IsTable(point) and point[1]) then
    frame.__muiOriginalPoint = point;
  else
    obj:PushTable(point);
  end
end

local function DisablePositionPersistence(frame)
  if (not obj:IsWidget(frame)) then
    return;
  end

  if (obj:IsFunction(frame.SetUserPlaced)) then
    frame:SetUserPlaced(false);
  end

  if (obj:IsFunction(frame.SetDontSavePosition)) then
    frame:SetDontSavePosition(true);
  end

  frame.dontSave = true;
end

obj:DefineParams("string|table", "boolean=false");
function C_MovableFramesModule:ExecuteMakeMovable(_, value, dontSave)
  local madeMovable = false;

  if (obj:IsString(value)) then
    local frame = GetFrame(value);

    if (frame) then
      self:MakeMovable(dontSave, frame);
      madeMovable = true;
    end

  elseif (obj:IsTable(value)) then
    for _, innerValue in ipairs(value) do
      local frame = GetFrame(innerValue);

      if (frame) then
        self:MakeMovable(dontSave, frame, value);
        madeMovable = true;
      end
    end

    if (obj:IsTable(value.hooked)) then
      for _, hookedTbl in ipairs(value.hooked) do

        if (hookedTbl.tblName) then
          tk:HookFunc(
            _G[hookedTbl.tblName], hookedTbl.funcName, function()
              for _, frameName in ipairs(hookedTbl) do
                self:MakeMovable(dontSave, GetFrame(frameName), value);
              end

              return true;
            end);

        else
          tk:HookFunc(
            hookedTbl.funcName, function()
              for _, frameName in ipairs(hookedTbl) do
                self:MakeMovable(dontSave, GetFrame(frameName), value);
              end
              return true;
            end);
        end
      end

      madeMovable = true;
    end

    if (obj:IsFunction(value.onLoad)) then
      value.onLoad();
      madeMovable = true;
    end
  end

  return madeMovable;
end

function MayronUI:MakeMovable(frame)
  local movableModule = self:ImportModule("MovableFramesModule");
  movableModule:ExecuteMakeMovable(frame);
end

local function CreateFadingAnimations(f)
  f.fadeIn = f:CreateAnimationGroup();
  local alpha = f.fadeIn:CreateAnimation("Alpha");
  alpha:SetSmoothing("IN");
  alpha:SetDuration(0.75);
  alpha:SetFromAlpha(-1);
  alpha:SetToAlpha(1);

  f.fadeIn:SetScript("OnFinished", function()
    f:SetAlpha(1);
  end);

  f.fadeOut = f:CreateAnimationGroup();
  alpha = f.fadeOut:CreateAnimation("Alpha");
  alpha:SetSmoothing("OUT");
  alpha:SetDuration(1);
  alpha:SetFromAlpha(1);
  alpha:SetToAlpha(-1);

  f.fadeOut:SetScript("OnFinished", function()
    f:SetAlpha(0);
  end);
end

local function UpdateTalkingHeadFrame(data)
  local f = _G.TalkingHeadFrame;

  for i, alertSubSystem in pairs(_G.AlertFrame.alertFrameSubSystems) do
    if (alertSubSystem.anchorFrame == f) then
      table.remove(_G.AlertFrame.alertFrameSubSystems, i);
      break
    end
  end

  -- uncomment these for development to prevent closing of frame
  -- f.Close = tk.Constants.DUMMY_FUNC;
  -- f:Show();
  -- f:ClearAllPoints();
  -- f:SetParent(_G.UIParent);
  -- f:SetPoint(data.settings.talkingHead.position, 0, data.settings.talkingHead.yOffset);

  -- Reskin:
  f.PortraitFrame:DisableDrawLayer("OVERLAY");
  f.MainFrame.Model:DisableDrawLayer("BACKGROUND");
  f.BackgroundFrame:DisableDrawLayer("BACKGROUND");

  local overlay = f.MainFrame.Overlay;
  _G.Mixin(overlay, _G.BackdropTemplateMixin);
  overlay:SetBackdrop(tk.Constants.BACKDROP_WITH_BACKGROUND);
  overlay:SetBackdropColor(0, 0, 0, 0.5);

  local r, g, b = tk:GetThemeColor();
  overlay:SetBackdropBorderColor(r*0.7, g*0.7, b*0.7);

  overlay:SetSize(118, 122)
  overlay:SetPoint("TOPLEFT", 20, -16);

  local frame = tk:CreateFrame("Frame", f.BackgroundFrame);
  local bg = gui:AddDialogTexture(frame);

  bg:SetPoint("TOPLEFT", 14, -10);
  bg:SetPoint("BOTTOMRIGHT", -10, 10);
  bg:SetFrameStrata("HIGH");
  bg:SetFrameLevel(1);

  CreateFadingAnimations(overlay);
  CreateFadingAnimations(bg);

  tk:KillElement(f.MainFrame.CloseButton);
  gui:AddCloseButton(frame, function()
    f.MainFrame.CloseButton:Click();
  end, true);

  tk:HookFunc(f, "PlayCurrent", function()
    f:ClearAllPoints();
    f:SetParent(_G.UIParent);
    f:SetPoint(data.settings.talkingHead.position, 0, data.settings.talkingHead.yOffset);

    overlay.fadeOut:Stop();
    bg.fadeOut:Stop();
    overlay.fadeIn:Play();
    bg.fadeIn:Play();
  end);
end

function C_MovableFramesModule:OnInitialize(data)
  db.global.movable.positions = nil;
  data.settings = db.global.movable:GetUntrackedTable();
  data.frames = obj:PopTable();

  if (obj:IsTable(_G.UIPARENT_MANAGED_FRAME_POSITIONS)) then
    _G.UIPARENT_MANAGED_FRAME_POSITIONS.TalkingHeadFrame = nil;
  end

  if (tk:IsRetail() and _G.TalkingHeadFrame) then
    UpdateTalkingHeadFrame(data);
  end

  if (db.global.movable.enabled) then
    self:SetEnabled(true);
  end
end

do
  local function GetPendingKey(dontSave, value)
    return tostring(dontSave) .. ":" .. tostring(value);
  end

  local function TryProcessValue(data, self, value, dontSave)
    local pendingKey = GetPendingKey(dontSave, value);

    if (data.processed[pendingKey]) then
      return true;
    end

    local handled = self:ExecuteMakeMovable(value, dontSave);

    if (handled) then
      data.processed[pendingKey] = true;
      data.pending[pendingKey] = nil;
      return true;
    end

    data.pending[pendingKey] = {
      value = value;
      dontSave = dontSave;
    };

    return false;
  end

  local function RetryPendingFrames(data, self)
    local hasPending = false;

    for pendingKey, pendingInfo in pairs(data.pending) do
      local handled = self:ExecuteMakeMovable(pendingInfo.value, pendingInfo.dontSave);

      if (handled) then
        data.processed[pendingKey] = true;
        data.pending[pendingKey] = nil;
      else
        hasPending = true;
      end
    end

    if (not hasPending and data.retryTicker) then
      data.retryTicker:Cancel();
      data.retryTicker = nil;
    end
  end

  function C_MovableFramesModule:OnEnable(data)
    data.processed = data.processed or obj:PopTable();
    data.pending = data.pending or obj:PopTable();

    if (not data.eventListener) then
      data.eventListener = em:CreateEventListenerWithID("MovableFramesOnAddOnLoaded", function(_, _, addOnName)
        if (not obj:IsString(addOnName)) then
          return;
        end

        MayronUI:LogDebug("AddOn Loaded: ", addOnName);

        if (BlizzardFrames[addOnName]) then
          TryProcessValue(data, self, BlizzardFrames[addOnName], false);
        end

        if (BlizzardFrames.dontSavePosition[addOnName]) then
          TryProcessValue(data, self, BlizzardFrames.dontSavePosition[addOnName], true);
        end
      end);

      data.eventListener:RegisterEvent("ADDON_LOADED");

      for id, frameName in ipairs(BlizzardFrames) do
        TryProcessValue(data, self, frameName, false);
      end

      for key, frameName in pairs(BlizzardFrames.dontSavePosition) do
        if (obj:IsString(frameName)) then
          TryProcessValue(data, self, frameName, true);
        end
      end

      for key, value in pairs(BlizzardFrames) do
        if (obj:IsString(key) and value ~= BlizzardFrames.dontSavePosition and IsAddOnLoaded(key)) then
          em:TriggerEventListenerByID("MovableFramesOnAddOnLoaded", key);
        end
      end
    elseif (obj:IsFunction(data.eventListener.SetEnabled)) then
      data.eventListener:SetEnabled(true);
    end

    if (not data.retryTicker and C_Timer and obj:IsFunction(C_Timer.NewTicker)) then
      data.retryTicker = C_Timer.NewTicker(1, function()
        RetryPendingFrames(data, self);
      end);
    end
  end

  function C_MovableFramesModule:OnDisable(data)
    if (data.retryTicker and obj:IsFunction(data.retryTicker.Cancel)) then
      data.retryTicker:Cancel();
      data.retryTicker = nil;
    end

    if (data.eventListener and obj:IsFunction(data.eventListener.SetEnabled)) then
      data.eventListener:SetEnabled(false);
    end
  end
end

obj:DefineParams("Frame");
function C_MovableFramesModule:RepositionFrame(data, frame)
  RestoreDefaultPoint(frame);
end

local function RestoreDefaultPoint(frame)
  local pointData = frame and frame.__muiOriginalPoint;

  if (not (obj:IsWidget(frame) and obj:IsTable(pointData) and pointData[1])) then
    return;
  end

  local point, relativeTo, relativePoint, xOffset, yOffset = unpack(pointData);

  if (not CanMove(frame)) then
    return;
  end

  DisablePositionPersistence(frame);
  frame:ClearAllPoints();
  frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
end

do
  local settings;
  local SubFrame_OnDragStart;
  local SubFrame_OnDragStop;
  local commonDragProxyKeys = {
    "TitleContainer";
    "Header";
    "HeaderContainer";
    "TitleBar";
    "PortraitContainer";
  };

  local function AttachDragProxy(proxy, anchoredFrame)
    if (not (obj:IsWidget(proxy) and obj:IsWidget(anchoredFrame))) then
      return;
    end

    if (proxy.__muiAnchoredFrame == anchoredFrame and proxy:GetScript("OnDragStart") == SubFrame_OnDragStart
        and proxy:GetScript("OnDragStop") == SubFrame_OnDragStop) then
      return;
    end

    proxy:EnableMouse(true);
    proxy:RegisterForDrag("LeftButton");
    proxy.anchoredFrame = anchoredFrame;
    proxy.__muiAnchoredFrame = anchoredFrame;
    proxy:SetScript("OnDragStart", SubFrame_OnDragStart);
    proxy:SetScript("OnDragStop", SubFrame_OnDragStop);
  end

  local function Frame_OnHide(self)
    if (settings and settings.enabled) then
      RestoreDefaultPoint(self);
    end
  end

  local function Frame_OnShow(self)
    CaptureOriginalPoint(self);
    DisablePositionPersistence(self);
  end

  local function Frame_OnDragStop(self, ...)
    if (settings and settings.enabled) then
      if (obj:IsFunction(self.StopMovingOrSizing)) then
        self:StopMovingOrSizing();
      end
      DisablePositionPersistence(self);
    end

    if (obj:IsFunction(self.oldOnDragStop) and CanMove(self)) then
      self.oldOnDragStop(self, ...);
    end
  end

  local function Frame_OnDragStart(self, ...)
    if (settings and settings.enabled and CanMove(self)) then
      CaptureOriginalPoint(self);

      if (not self:IsMovable()) then
        self:SetMovable(true);
        self:EnableMouse(true);
      end

      if (obj:IsFunction(self.StartMoving)) then
        self:StartMoving();
      end
    end

    if (obj:IsFunction(self.oldOnDragStart) and CanMove(self)) then
      self.oldOnDragStart(self, ...);
    end
  end

  function SubFrame_OnDragStart(self)
    if (settings and settings.enabled and obj:IsWidget(self.anchoredFrame)) then
      local onDragStart = self.anchoredFrame:GetScript("OnDragStart");

      if (obj:IsFunction(onDragStart)) then
        onDragStart(self.anchoredFrame);
      end
    end
  end

  function SubFrame_OnDragStop(self)
    if (settings and settings.enabled and obj:IsWidget(self.anchoredFrame)) then
      local onDragStop = self.anchoredFrame:GetScript("OnDragStop");

      if (obj:IsFunction(onDragStop)) then
        onDragStop(self.anchoredFrame);
      end
    end
  end

  local function ClickedFrame_OnClick(self)
    if (settings and settings.enabled) then
      self.module:RepositionFrame(self.anchoredFrame);
    end
  end

  obj:DefineParams("boolean", "?Frame", "?table");
  function C_MovableFramesModule:MakeMovable(data, dontSave, frame, tbl)
    if (not obj:IsWidget(frame) or not CanMove(frame)) then
      return
    end

    if (not tk.Tables:Contains(data.frames, frame)) then
      if (frame:IsShown() and not frame.__muiOriginalPoint) then
        CaptureOriginalPoint(frame);
      end

      frame:SetMovable(true);
      frame:EnableMouse(true);
      frame:RegisterForDrag("LeftButton");
      DisablePositionPersistence(frame);

      if (data.settings.clampToScreen) then
        frame:SetClampedToScreen(true);
        frame:SetClampRectInsets(-10, 10, 10, -10);
      else
        frame:SetClampedToScreen(false);
      end

      settings = data.settings;

      table.insert(data.frames, frame);

      frame.oldOnDragStart = frame:GetScript("OnDragStart");
      frame.oldOnDragStop = frame:GetScript("OnDragStop");
      frame:HookScript("OnShow", Frame_OnShow);
      frame:HookScript("OnHide", Frame_OnHide);
      frame:SetScript("OnDragStart", Frame_OnDragStart);
      frame:SetScript("OnDragStop", Frame_OnDragStop);
    end

    if (not tbl) then
      return;
    end

    if (tbl.subFrames) then
      for _, subFrame in ipairs(tbl.subFrames) do
        subFrame = GetFrame(subFrame);

        if (subFrame) then
          AttachDragProxy(subFrame, frame);
        end
      end
    end

    for _, key in ipairs(commonDragProxyKeys) do
      AttachDragProxy(frame[key], frame);
    end

    if (obj:IsTable(frame.NineSlice)) then
      AttachDragProxy(frame.NineSlice.TitleContainer, frame);
      AttachDragProxy(frame.NineSlice.Header, frame);
    end

    if (tbl.clickedFrames) then
      for _, clickedFrame in ipairs(tbl.clickedFrames) do
        clickedFrame = GetFrame(clickedFrame);

        if (clickedFrame) then
          clickedFrame.module = self;
          clickedFrame.anchoredFrame = frame;

          if (not clickedFrame.__muiResetHooked) then
            clickedFrame:HookScript("OnClick", ClickedFrame_OnClick);
            clickedFrame.__muiResetHooked = true;
          end
        end
      end
    end
  end
end

function C_MovableFramesModule:ResetPositions(data)
  for _, frame in ipairs(data.frames) do
    RestoreDefaultPoint(frame);
  end
end
