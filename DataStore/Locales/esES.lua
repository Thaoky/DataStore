local addonName = ...
local L = AddonFactory:SetLocale(addonName, "esES")
if not L then return end

L["Disabled"] = "Desactivado"
L["Enabled"] = "Activado"
L["Memory used for %d |4character:characters;:"] = "Memoria utilizada para %d |4personaje:personajes;:"

