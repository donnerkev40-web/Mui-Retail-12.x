local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, obj = MayronUI:GetCoreComponents();

if (obj:Import("MayronUI.ActionBars.BartenderCompatibility", true)) then
  return;
end

local BartenderCompatibility = obj:CreateInterface("BartenderCompatibility", {});

function BartenderCompatibility:GetRelevantProfiles()
  local bartenderProfiles = {
    MayronUI = true;
  };

  if (_G.Bartender4 and obj:IsTable(_G.Bartender4.db)
      and obj:IsFunction(_G.Bartender4.db.GetCurrentProfile)) then
    local ok, currentProfile = pcall(function()
      return _G.Bartender4.db:GetCurrentProfile();
    end);

    if (ok and obj:IsString(currentProfile)
        and not tk.Strings:IsNilOrWhiteSpace(currentProfile)) then
      bartenderProfiles[currentProfile] = true;
    end
  end

  return bartenderProfiles;
end

function BartenderCompatibility:ApplyProfileCompliance(profileName)
  -- Bartender should primarily be shaped by its original preset imports.
  -- Keep this compatibility layer passive to avoid drifting away from the
  -- shipped Bartender profile definitions.
  if (not (tk:IsRetail() and obj:IsString(profileName))) then
    return;
  end
end

function BartenderCompatibility:ApplyRuntimeCompliance()
  return;
end

obj:Export(BartenderCompatibility, "MayronUI.ActionBars.BartenderCompatibility");
