local _G = _G;
local LibStub = _G.LibStub;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();
local OrbitusDB = LibStub:GetLibrary("OrbitusDB");

if (obj:Import("MayronUI.Inventory.AnchorController", true)) then
  return;
end

local GetScreenWidth = _G.GetScreenWidth;
local GetScreenHeight = _G.GetScreenHeight;

local Controller = obj:CreateInterface("InventoryAnchorController", {});

function Controller:IsFrameLocked(db)
  return db.profile:QueryType("boolean", "container.locked");
end

function Controller:CenterFrame(inventoryFrame)
  inventoryFrame:ClearAllPoints();
  inventoryFrame:SetPoint("CENTER", _G.UIParent, "CENTER");
end

function Controller:StoreFrameOffsets(inventoryFrame, db)
  local bottom = inventoryFrame:GetBottom();
  if (not obj:IsNumber(bottom)) then
    return;
  end

  local left = inventoryFrame:GetLeft();
  local height = inventoryFrame:GetHeight();
  if (obj:IsNumber(left) and obj:IsNumber(height)) then
    db.profile:Store("container.xOffset", left);
    db.profile:Store("container.yOffset", bottom + height);
  end

  local right = inventoryFrame:GetRight();
  if (obj:IsNumber(right)) then
    db.profile:Store("container.rightOffset", GetScreenWidth() - right);
    db.profile:Store("container.bottomOffset", bottom);
  end
end

function Controller:RestoreFramePosition(inventoryFrame, db)
  inventoryFrame:ClearAllPoints();

  if (self:IsFrameLocked(db)) then
    local rightOffset = db.profile:QueryType("number?", "container.rightOffset");
    local bottomOffset = db.profile:QueryType("number?", "container.bottomOffset");

    if (type(rightOffset) ~= "number") then
      rightOffset = db.global:QueryType("number?", "rightOffset");
    end

    if (type(bottomOffset) ~= "number") then
      bottomOffset = db.global:QueryType("number?", "bottomOffset");
    end

    if (type(rightOffset) == "number" and type(bottomOffset) == "number") then
      inventoryFrame:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", -rightOffset, bottomOffset);
      return;
    end
  end

  local xOffset = db.profile:QueryType("number?", "container.xOffset");
  local yOffset = db.profile:QueryType("number?", "container.yOffset");

  if (type(xOffset) ~= "number") then
    xOffset = db.global:QueryType("number?", "xOffset");
  end

  if (type(yOffset) ~= "number") then
    yOffset = db.global:QueryType("number?", "yOffset");
  end

  if (type(xOffset) == "number" and type(yOffset) == "number") then
    inventoryFrame:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", xOffset, yOffset);
  else
    self:CenterFrame(inventoryFrame);
  end
end

function Controller:RepositionFrame(inventoryFrame)
  local db = OrbitusDB:GetDatabase("MUI_InventoryDB");
  local screenBottomDistance = inventoryFrame:GetBottom();

  if (not obj:IsNumber(screenBottomDistance)) then
    return;
  end

  if (db and self:IsFrameLocked(db)) then
    local right = inventoryFrame:GetRight();
    local screenRightDistance;

    if (obj:IsNumber(right)) then
      screenRightDistance = GetScreenWidth() - right;
    else
      local storedRightOffset = db.profile:QueryType("number?", "container.rightOffset");

      if (type(storedRightOffset) ~= "number") then
        storedRightOffset = db.global:QueryType("number?", "rightOffset");
      end

      if (type(storedRightOffset) == "number") then
        screenRightDistance = storedRightOffset;
      end
    end

    if (not obj:IsNumber(screenRightDistance)) then
      return;
    end

    inventoryFrame:ClearAllPoints();
    inventoryFrame:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", -screenRightDistance, screenBottomDistance);
    return;
  end

  local screenLeftDistance = inventoryFrame:GetLeft();
  local height = inventoryFrame:GetHeight();

  if (not obj:IsNumber(screenLeftDistance) or not obj:IsNumber(height)) then
    return;
  end

  local xOffset = screenLeftDistance;
  local yOffset = screenBottomDistance + height;
  inventoryFrame:ClearAllPoints();
  inventoryFrame:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", xOffset, yOffset);
end

function Controller:EnsureFrameIsOnScreen(inventoryFrame)
  local left = inventoryFrame:GetLeft();
  local right = inventoryFrame:GetRight();
  local top = inventoryFrame:GetTop();
  local bottom = inventoryFrame:GetBottom();

  if (not (obj:IsNumber(left) and obj:IsNumber(right)
      and obj:IsNumber(top) and obj:IsNumber(bottom))) then
    return;
  end

  local screenWidth = GetScreenWidth();
  local screenHeight = GetScreenHeight();
  local hasHorizontalIntersection = right > 0 and left < screenWidth;
  local hasVerticalIntersection = top > 0 and bottom < screenHeight;

  if (not (hasHorizontalIntersection and hasVerticalIntersection)) then
    self:CenterFrame(inventoryFrame);
  end
end

function Controller:ApplyLockState(inventoryFrame, db)
  local locked = self:IsFrameLocked(db);

  if (inventoryFrame.dragger and obj:IsFunction(inventoryFrame.dragger.EnableMouse)) then
    inventoryFrame.dragger:EnableMouse(not locked);
  end

  if (inventoryFrame.titleBar and obj:IsFunction(inventoryFrame.titleBar.EnableMouse)) then
    inventoryFrame.titleBar:EnableMouse(not locked);
  end

  if (obj:IsFunction(inventoryFrame.SetMovable)) then
    inventoryFrame:SetMovable(not locked);
  end
end

obj:Export(Controller, "MayronUI.Inventory.AnchorController");
