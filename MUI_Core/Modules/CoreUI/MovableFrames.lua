local _G = _G;
local MayronUI = _G.MayronUI;
local _, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.CoreUI.MovableFrames", true)) then
  return;
end

obj:Export(obj:CreateInterface("CoreUIMovableFrames", {
  featurePath = "coreui.movableFrames";
}), "MayronUI.CoreUI.MovableFrames");
