local addonName, addon = ...

local TableInsert, pairs = table.insert, pairs
local realmNames

-- *** Connected Realms ***

function addon:SetLongRealmName(realm, name)
	-- relationship between "short" and "long" realm names, 
	-- ex: ["MarécagedeZangar"] = "Marécage de Zangar"
	-- necessary for guild banks on other realms..
	DataStore_RealmNames[realm] = name
end

function addon:GetLongRealmName(realm)
	-- 2021-01-21 : the 'or realm' is mandatory to properly return the info of connected realms
	return realm and realmNames[realm] or realm
end

function addon:GetRealmsConnectedWith(realm)
	local out = {}

	local autoCompleteRealms = GetAutoCompleteRealms()		-- this could return nil..
	if autoCompleteRealms then
		for _, shortName in pairs(autoCompleteRealms) do
			local longName = realmNames[shortName]
			
			if longName and longName ~= addon.ThisRealm then
				TableInsert(out, longName)
			end
		end
	end
	
	return out
end

AddonFactory:OnPlayerLogin(function()
	realmNames = DataStore_RealmNames
end)
