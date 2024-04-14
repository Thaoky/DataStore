local addonName = ...
local L = DataStore:SetLocale(addonName, "koKR")
if not L then return end

L["Disabled"] = "사용 안 함"
L["Enabled"] = "사용함"
L["Memory used for %d |4character:characters;:"] = "%d 캐릭터에 사용된 메모리:"

