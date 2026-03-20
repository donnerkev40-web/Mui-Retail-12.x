-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, obj, L = MayronUI:GetCoreComponents();
local C_DataTextModule = MayronUI:GetModuleClass("DataTextModule");
local dataTextLabels = MayronUI:GetComponent("DataTextLabels");
local pairs, string = _G.pairs, _G.string;

function C_DataTextModule:GetConfigTable()
    return nil;
end
