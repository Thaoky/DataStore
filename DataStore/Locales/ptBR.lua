local addonName = ...
local L = DataStore:SetLocale(addonName, "ptBR")
if not L then return end

L["Disabled"] = "Desativado"
L["Enabled"] = "Ativado"
L["Memory used for %d |4character:characters;:"] = "Memória usada para %d |4personagem:personagens;:"

