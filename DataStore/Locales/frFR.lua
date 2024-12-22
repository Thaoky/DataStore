local addonName = ...
local L = AddonFactory:SetLocale(addonName, "frFR")
if not L then return end

L["Disabled"] = "Désactivée"
L["Enabled"] = "Activée"
L["Memory used for %d |4character:characters;:"] = "Mémoire utilisée pour %d |4personnage:personnages;:"

