local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhTW")
if not L then return end

L["Disabled"] = "禁用"
L["Enabled"] = "啟用"
L["Memory used for %d |4character:characters;:"] = "記憶容量已使用 %d |4角色:角色;:"

