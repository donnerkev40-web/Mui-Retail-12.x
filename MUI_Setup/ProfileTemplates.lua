local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.Setup.ProfileTemplates", true)) then
  return;
end

local LayoutManager = obj:Import("MayronUI.LayoutManager");
local ProfileTemplates = obj:CreateInterface("SetupProfileTemplates", {});

local externalLayoutProfiles = {
  DPS = {
    ["Bartender4"] = "MayronUI";
    ["Grid2"] = "MayronUI";
    ["ShadowUF"] = "MayronUI-DPS";
    ["MUI TimerBars"] = "Default";
  };
  Healer = {
    ["Bartender4"] = "MayronUI";
    ["Grid2"] = "MayronUI";
    ["ShadowUF"] = "MayronUI-Heal";
    ["MUI TimerBars"] = "Healer";
  };
};

function ProfileTemplates:GetProfileName(layoutName)
  return LayoutManager:GetProfileName(layoutName);
end

function ProfileTemplates:GetExternalProfiles(layoutName)
  layoutName = LayoutManager:NormalizeLayoutName(layoutName);
  return tk.Tables:Copy(externalLayoutProfiles[layoutName] or externalLayoutProfiles.DPS, true);
end

function ProfileTemplates:GetSupportedLayouts()
  return {
    "DPS";
    "Healer";
  };
end

obj:Export(ProfileTemplates, "MayronUI.Setup.ProfileTemplates");
