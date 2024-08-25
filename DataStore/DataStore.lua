--[[	*** DataStore ***
Written by : Thaoky, EU-Marécages de Zangar
July 15th, 2009

This is the main DataStore module, its purpose is to be a single point of contact for common operations between client addons and other DataStore modules.
For instance, it prevents client addons from calling a different :GetCharacter() in each module, as the value returned by the main module can be passed to the other ones.

Other services offered by DataStore:
	- DataStore Events ; possibility to trigger and respond to DataStore's own events (see the respective modules for details)
	- Tracks guild members status in a slightly more accurate way than with GUILD_ROSTER_UPDATE alone.
	- Guild member info can be requested by character name (DataStore:GetGuildMemberInfo(member)) rather than by index (GetGuildRosterInfo)
	- Tracks online guild members' alts, used mostly by other DataStore modules, but can also be used by client addons.
		Note: a "main" is the currently connected player, "alts" are all his other characters in the same guild. The notions of "main" & "alts" are thus only valid for live data, nothing else.
--]]

local addonName, addon = ...
DataStore = addon

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
addon.Version = format("v%s", GetAddOnMetadata(addonName, "Version"))

addon.ThisAccount = "Default"
addon.ThisRealm = GetRealmName()
addon.ThisChar = UnitName("player")
addon.ThisCharKey = format("%s.%s.%s", addon.ThisAccount, addon.ThisRealm, addon.ThisChar)
addon.ThisFaction = UnitFactionGroup("player")
-- Do not dereference GetGuildInfo("player") here, it is nil

local allCharacters, allGuilds			-- pointers to the parts of the DB that contain character, guild data
local guildNames = {}				-- Reverse lookup to get guild names by id

-- ** Mixins **
local function _GetCharacterGuildID(characterKey)
	local characterID = allCharacters.Set[characterKey]
	if characterID then
		return DataStore_CharacterGuilds[characterID]		-- ex: char is in guild 3
	end
end

local function _GetGuildName(characterKey)
	local guildID = _GetCharacterGuildID(characterKey)
	if guildID then
		return guildNames[guildID]
	end
end


DataStore:OnAddonLoaded(addonName, function()
	DataStore:RegisterModule({
		addon = addon,
		addonName = addonName,
		rawTables = {
			"DataStore_GuildIDs",
			"DataStore_GuildFactions",
			"DataStore_CharacterIDs",
			"DataStore_CharacterGUIDs",
			"DataStore_CharacterGuilds",
			"DataStore_AltGroups",
			"DataStore_ConnectedRealms",
			"DataStore_RealmNames",
		},
		-- characterTables = {
			-- ["DataStore_Characters_Info"] = {
				-- GetCharacterName = _GetCharacterName,
			-- },
		-- }
	})
	
	-- Base character information
	allCharacters = DataStore:CreateSetAndList(DataStore_CharacterIDs)
	
	local id = addon:StoreToSetAndList(allCharacters, addon.ThisCharKey)
	DataStore_CharacterGUIDs[id] = UnitGUID("player")
	addon.ThisCharID = id
	
	-- Base guild information
	allGuilds = DataStore:CreateSetAndList(DataStore_GuildIDs)
	
	-- Reverse lookup table for the guild names
	for k, guildID in pairs(allGuilds.Set) do
		if k ~= "LastID" then
			local _, _, guild = strsplit(".", k)	
			guildNames[guildID] = guild
		end
	end
	
	DataStore:RegisterMethod(addon, "GetCharacterGuildID", _GetCharacterGuildID)
	DataStore:RegisterMethod(addon, "GetGuildName", _GetGuildName)

	-- a hidden frame to contain all children frames of submodules, this avoids polluting _G[].
	addon.Frames = CreateFrame("Frame", "DataStoreFrames", UIParent)
end)

DataStore:OnPlayerLogin(function()
	addon:SetLongRealmName(addon.ThisRealm:gsub(" ", ""), addon.ThisRealm)
end)


-- *** Utility functions ***

local function GetKey(name, realm, account)
	-- default values
	name = name or UnitName("player")
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	return format("%s.%s.%s", account, realm, name)
end

-- *** Character functions ***

function addon:GetCharacter(name, realm, account)
	local key = GetKey(name, realm, account)
	if allCharacters.Set[key] then		-- if the key is known, return it to caller, it can be passed to other modules
		return key
	end
end

function addon:GetCharacterID(key)
	return allCharacters.Set[key]			-- return the ID from the key
end

function addon:GetCharacterIDByGUID(guid)
	-- Find a character ID by its GUID
	for index, characterGUID in pairs(DataStore_CharacterGUIDs) do
		if characterGUID == guid then
			return index
		end
	end
end

function addon:GetCharacterKey(id)
	return allCharacters.List[id]			-- return the key from the ID
end

function addon:GetCharacterInfoByID(id)
	return strsplit(".", addon:GetCharacterKey(id))
end

function addon:GetCharacters(realm, account)
	-- get a list of characters on a given realm/account
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	local out = {}
	
	for k, v in pairs(allCharacters.Set) do
		local accountKey, realmKey, charKey = strsplit(".", k)

		if accountKey and accountKey == account and realmKey and realmKey == realm then
			out[charKey] = k
			--[[
				allows this kind of iteration:
				for characterName, character in pairs(DS:GetCharacters(realm, account)) do
					do stuff with characterName only
					or do stuff with the "character" key to pass to other DataStore functions
				end
			--]]
		end
	end

	return out
end

function addon:GetRealms(account)
	-- Ex: for realmName in pairs(DataStore:GetRealms(account)) do ... end
	account = account or addon.ThisAccount

	local out = {}

	for k, _ in pairs(allCharacters.Set) do
		local accountKey, realmKey = strsplit(".", k)

		if accountKey and accountKey == account and realmKey then
			out[realmKey] = true
		end
	end
	
	return out
end

function addon:GetAccounts()
	-- Ex: for accountName in pairs(DataStore:GetAccounts()) do ... end
	
	local out = {}

	for k, _ in pairs(allCharacters.Set) do
		local accountKey = strsplit(".", k)

		if accountKey then
			out[accountKey] = true
		end
	end
	
	return out
end

function addon:IsCurrentPlayer(playerName, realm, account)
	return (playerName == addon.ThisChar) 
		and (realm == addon.ThisRealm) 
		and (account == addon.ThisAccount)
end

function addon:IsCurrentPlayerKey(playerKey)
	return playerKey == addon.ThisCharKey
end

function addon:GetNumCharactersInDB()
	return allCharacters.Count or 0
end

function addon:IterateCharacters(callback)
	-- Raw version, really iterate all characters
	
	local account, realm, name
	
	for key, id in pairs(allCharacters.Set) do
		callback(key, id)
	end
end

function addon:IterateCharactersSorted(realmFilter, accountFilter, callback)
	
	-- to do : take the filters into account in the loop
	
	local accounts = addon:GetAccounts()							-- Get the accounts
	accounts[addon.ThisAccount] = nil								-- Remove the current account, because we want to put it first in the list
	
	local sortedAccounts = addon:HashToSortedArray(accounts)	-- Sort the remaining accounts in alphabetical order
	table.insert(sortedAccounts, 1, addon.ThisAccount)			-- Then add the current account in first position

	for _, account in pairs(sortedAccounts) do
		local realms = addon:GetRealms(account)					-- Get the realms
		realms[addon.ThisRealm] = nil									-- Remove the current realm, because we want to put it first in the list
		
		local sortedRealms = addon:HashToSortedArray(realms)	-- Sort the remaining realms in alphabetical order
		table.insert(sortedRealms, 1, addon.ThisRealm)			-- Then add the current realm in first position
	
		for _, realm in pairs(sortedRealms) do
			local sortedCharacters = addon:HashToSortedArray(addon:GetCharacters(realm, account))
			
			for _, characterName in ipairs(sortedCharacters) do
				callback(account, realm, characterName, addon:GetCharacter(characterName, realm, account))
			end		
		end
	end
end

-- *** Guild functions ***

function addon:GetGuild(name, realm, account)
	name = name or GetGuildInfo("player")
	local key = GetKey(name, realm, account)
	
	if allGuilds.Set[key] then		-- if the key is known, return it to caller, it can be passed to other modules
		return key
	else	-- if the key is not known, try checking the connected realm info
		key = GetKey(name, DataStore_ConnectedRealms[addon.ThisRealm], account)
		
		if allGuilds.Set[key] then	-- if the key is known, return it to caller, it can be passed to other modules
			return key
		end
	end
end

function addon:GetGuilds(realm, account)
	-- get a list of guilds on a given realm/account
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	local out = {}

	for k, _ in pairs(allGuilds.Set) do
		local accountKey, realmKey, guildKey = strsplit(".", k)
		
		if accountKey and accountKey == account and realmKey and realmKey == realm then
			out[guildKey] = k
			--[[
			this allows to iterate with this kind of loop:
				for guildName, guild in pairs(DS:GetGuilds(realm, account)) do
					do stuff with guildName only
					or do stuff with the "guild" key to pass to other DataStore functions
				end
			--]]
		end
	end

	return out
end

function addon:GetGuildFaction(name, realm, account)
	name = name or GetGuildInfo("player")
	local key = GetKey(name, realm, account)

	if allGuilds.Set[key] then
		return DataStore_GuildFactions[allGuilds.Set[key]]
	end
end

function addon:GetThisGuildKey()
	-- return the correct guild key to use, with support for connected realms
	local guild, _, _, realm = GetGuildInfo("player")
	if not guild then return end
	
	if not realm then
		-- realm = nil : guild is on the same realm as the player
		return format("%s.%s.%s", addon.ThisAccount, addon.ThisRealm, guild)
	end
	
	-- realm not nil : guild is on a connected realm
	
	-- guild "unknwon" if it's not possible to match its short name to its long name
	local longName = addon:GetLongRealmName(realm)
	if not longName then return end
	
	return format("%s.%s.%s", addon.ThisAccount, longName, guild)
end

-- *** Cleanup functions ***

function addon:DeleteCharacter(name, realm, account)
	local key = GetKey(name, realm, account)
	if not allCharacters.Set[key] or key == addon.ThisCharKey then return end	-- never delete current character

	-- Get the index of the character we are about to delete
	local index = allCharacters.Set[key]

	-- delete the character in all modules
	addon:IterateModules(function(moduleTable, moduleName) 
		
		-- iterate all modules except the main DataStore module
		if moduleName ~= "DataStore" then
			if moduleTable.CharacterTables then
				-- iterate character tables
				for name, _ in pairs(moduleTable.CharacterTables) do
					_G[name][index] = nil
				end
			end
			
			if moduleTable.CharacterIdTables then
				-- iterate character id tables
				for name, _ in pairs(moduleTable.CharacterIdTables) do
					_G[name][index] = nil
				end
			end
		end
	end)

	-- delete the key in DataStore : only delete from the Set, keep it in the list, to preserve indexes.
	allCharacters.Set[key] = nil
	
end

function addon:DeleteGuild(guildKey)
	if not allGuilds.Set[guildKey] then return end

	-- This needs review, might not be necessary anymore, we have DeleteGuildBank

	-- delete the guild in all modules
	addon:IterateModules(function(moduleDB) 
	
		-- for k, v in pairs(moduleDB) do
			-- print(k)
		-- end
	
		if moduleDB.Guilds then
			moduleDB.Guilds[guildKey] = nil
		end
	end)

	-- delete the key in DataStore
	-- allGuilds.Set[guildKey] = nil
	-- also delete in all tables !
end

function addon:DeleteRealm(realm, account)
	for name, _ in pairs(addon:GetCharacters(realm, account)) do
		addon:DeleteCharacter(name, realm, account)
	end

	for name, _ in pairs(addon:GetGuilds(realm, account)) do
		addon:DeleteGuild(name, realm, account)
	end
end

local function WipeCharacterTable(t)
	if not t then return end

	for key, v in pairs(t) do	-- key is the character key
		if key ~= addon.ThisCharKey then	-- only delete an entry if it is not the current character
			t[key] = nil
		end
	end
end

local function WipeGuildTable(t)
	if not t then return end

	for key, v in pairs(t) do	-- key is the guild key
		t[key] = nil
	end
end

function addon:ClearAllData()

	-- sub-module data
	addon:IterateModules(function(moduleDB) 
		WipeCharacterTable(moduleDB.Characters)
		WipeGuildTable(moduleDB.Guilds)
	end)

	-- main module data
	WipeCharacterTable(allCharacters)
	WipeGuildTable(allGuilds)
end
