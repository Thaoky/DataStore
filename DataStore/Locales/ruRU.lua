local addonName = ...
local L = AddonFactory:SetLocale(addonName, "ruRU")
if not L then return end

L["Disabled"] = "Отключено"
L["Enabled"] = "Включено"
L["Memory used for %d |4character:characters;:"] = "Памяти использовано на %d |4персонажа:персонажей;:"

