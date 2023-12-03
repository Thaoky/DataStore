local addonName, addon = ...

-- *** Connected Realms ***
local function GetRealmNames()
	return addon.db.global.ShortToLongRealmNames
end

function addon:SetLongRealmName(realm, name)
	local names = GetRealmNames()
	
	names[realm] = name
end

function addon:GetLongRealmName(realm)
	local names = GetRealmNames()
	
	-- 2021-01-21 : the 'or realm' is mandatory to properly return the info of connected realms
	return (realm) and names[realm] or realm
end

function addon:GetRealmsConnectedWith(realm)
	local names = GetRealmNames()
	local out = {}

	local autoCompleteRealms = GetAutoCompleteRealms()		-- this could return nil..
	if autoCompleteRealms then
		for _, shortName in pairs(autoCompleteRealms) do
			local longName = names[shortName]
			
			if longName and longName ~= addon.ThisRealm then
				table.insert(out, longName)
			end
		end
	end
	
	return out
end