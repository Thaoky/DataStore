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
DataStore = LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
addon.Version = "v" .. GetAddOnMetadata(addonName, "Version")

addon.ThisAccount = "Default"
addon.ThisRealm = GetRealmName()
addon.ThisChar = UnitName("player")
addon.ThisCharKey = format("%s.%s.%s", addon.ThisAccount, addon.ThisRealm, addon.ThisChar)

local commPrefix = "DataStore"
local Characters, Guilds			-- pointers to the parts of the DB that contain character, guild data

local guildMembersIndexes = {} 	-- hash table containing guild member info
local onlineMembers = {}			-- simple hash table to track online members:		["member"] = true (or nil)
local onlineMembersAlts = {}		-- simple hash table to track online members' alts:	["member"] = "alt1|alt2|alt3..."

-- Message types
local MSG_ANNOUNCELOGIN				= 1	-- broadcast at login
local MSG_LOGINREPLY					= 2	-- reply to MSG_ANNOUNCELOGIN

local AddonDB_Defaults = {
	global = {
		Guilds = {},				-- no 'magic key' ['*'] to avoid listing an additional "wrong" guild when the guild is actually on another realm
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"]
				faction = nil,
				guildName = nil,		-- nil = not in a guild, as returned by GetGuildInfo("player")
			}
		},
		SharedContent = {			-- lists the shared content
			--	["Account.Realm.Name"]  = true means the char is shared,
			--	["Account.Realm.Name.Module"]  = true means the module is shared for that char
		},
		ConnectedRealms = {},
		ShortToLongRealmNames = {
			-- relationship between "short" and "long" realm names, 
			-- ex: ["MarécagedeZangar"] = "Marécage de Zangar"
			-- necessary for guild banks on other realms..
		},
		AltGroups = {
			-- ["GroupName"] = { "Alt 1 Key", "Alt 2 Key" .. }
		},
	}
}

local function GetKey(name, realm, account)
	-- default values
	name = name or UnitName("player")
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	return format("%s.%s.%s", account, realm, name)
end

local function GetAlts(guild)
	-- returns a | delimited string containing the list of alts in the same guild
	guild = guild or GetGuildInfo("player")
	if not guild then	return end

	local out = {}
	for k, v in pairs(Characters) do
		local accountKey, realmKey, charKey = strsplit(".", k)

		if accountKey and accountKey == addon.ThisAccount then			-- same account
			if realmKey and realmKey == addon.ThisRealm then			-- same realm
				if charKey and charKey ~= UnitName("player") then	-- skip current char
					if v.guildName and v.guildName == guild then		-- same guild (to send only guilded alts, privacy concern, do not change this)
						table.insert(out, charKey)
					end
				end
			end
		end
	end

	return table.concat(out, "|")
end

local function SaveAlts(sender, alts)
	if alts then
		if strlen(alts) > 0 then	-- sender has no alts
			onlineMembersAlts[sender] = alts				-- "alt1|alt2|alt3..."
		end
		addon:SendMessage("DATASTORE_GUILD_ALTS_RECEIVED", sender, alts)
	end
end

local function GuildBroadcast(messageType, ...)
	local serializedData = addon:Serialize(messageType, ...)
	addon:SendCommMessage(commPrefix, serializedData, "GUILD")
end

local function GuildWhisper(player, messageType, ...)
	if addon:IsGuildMemberOnline(player) then
		local serializedData = addon:Serialize(messageType, ...)
		addon:SendCommMessage(commPrefix, serializedData, "WHISPER", player)
	end
end


-- *** Event Handlers ***
local currentGuildName

local function OnPlayerGuildUpdate()

	-- at login this event is called between OnEnable and PLAYER_ALIVE, where GetGuildInfo returns a wrong value
	-- however, the value returned here is correct
	if IsInGuild() and not currentGuildName then		-- the event may be triggered multiple times, and GetGuildInfo may return incoherent values in subsequent calls, so only save if we have no value.
		local realmName, _
		currentGuildName, _, _, realmName = GetGuildInfo("player")		-- realmName will be nil if guild is on the same realm as the character
		
		if currentGuildName then
			local guildKey
			
			if not realmName then
				-- if realm is nil (= current realm), the guild key will be a classic key
				guildKey = GetKey(currentGuildName)
				
			else
				-- if realm is not nil, the guild key will use the long realm name
				local longName = addon:GetLongRealmName(realmName)	

				if longName then
					guildKey = GetKey(currentGuildName, longName)
					
					-- Now check for a connected realm !
					if longName ~= addon.ThisRealm then
						addon.db.global.ConnectedRealms[longName] = addon.ThisRealm
						addon.db.global.ConnectedRealms[addon.ThisRealm] = longName
					end
				end
			end
			
			-- guild key may be nil if the character is on a different realm than his guild, and he never logged on to that server
			-- .. so the long realm name is unknown ..
			if guildKey then
				if not Guilds[guildKey] then
					Guilds[guildKey] = {}
				end

				Guilds[guildKey].faction = UnitFactionGroup("player")
				
				-- the first time a valid value is found, broadcast to guild, it must happen here for a standard login, but won't work here after a reloadui since this event is not triggered
				GuildBroadcast(MSG_ANNOUNCELOGIN, GetAlts(currentGuildName))
				addon:SendMessage("DATASTORE_ANNOUNCELOGIN", currentGuildName)
			end
		end
	end
	Characters[GetKey()].guildName = currentGuildName
end

local function OnPlayerAlive()
	Characters[GetKey()].faction = UnitFactionGroup("player")
	OnPlayerGuildUpdate()
end

local function OnGuildRosterUpdate()
	wipe(guildMembersIndexes)
	local numGuildMembers, numOnline = GetNumGuildMembers()
	
	for i=1, numGuildMembers do		-- browse all players (online & offline)
		local name, _, _, _, _, _, _, _, onlineStatus = GetGuildRosterInfo(i)
		
		onlineStatus = (onlineStatus) and true or nil	-- force a nil, instead of false
		
		if name then
			name = Ambiguate(name, "none")
			guildMembersIndexes[name] = i

			if onlineMembers[name] and not onlineStatus then	-- if a player was online but has now gone offline, trigger a message
				addon:SendMessage("DATASTORE_GUILD_MEMBER_OFFLINE", name)
			end
			onlineMembers[name] = onlineStatus
		end
	end
end

local msgOffline = gsub(ERR_FRIEND_OFFLINE_S, "%%s", "(.+)")		-- this turns "%s has gone offline." into "(.+) has gone offline."

local function OnChatMsgSystem(event, arg)
	if arg then
		local member = arg:match(msgOffline)
		if member then
			-- guild roster update can be triggered every 10 secs max, so if a players logs in & out right after, sending him message will result in "No player named xx"
			-- marking him as offline prevents this
			onlineMembers[member] = nil
			onlineMembersAlts[member] = nil
			addon:SendMessage("DATASTORE_GUILD_MEMBER_OFFLINE", member)
		end
	end
end

-- *** Guild Comm ***
local GuildCommCallbacks = {
	[commPrefix] = {
		[MSG_ANNOUNCELOGIN] = function(sender, alts)
				onlineMembers[sender] = true									-- sender is obviously online
				if sender ~= UnitName("player") then						-- don't send back to self
					GuildWhisper(sender, MSG_LOGINREPLY, GetAlts())		-- reply by sending my own alts ..
				end
				SaveAlts(sender, alts)											-- .. and save received data
			end,
		[MSG_LOGINREPLY] = function(sender, alts)
				SaveAlts(sender, alts)
			end,
	},
}

local function GuildCommHandler(prefix, message, distribution, sender)
	-- This handler will be used by other modules as well
	local success, msgType, arg1, arg2, arg3 = addon:Deserialize(message)

	if success and msgType and GuildCommCallbacks[prefix] then
		local func = GuildCommCallbacks[prefix][msgType]

		if func then
			sender = Ambiguate(sender, "none")
			func(sender, arg1, arg2, arg3)
		end
	end
end


function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New("DataStoreDB", AddonDB_Defaults)

	Characters = addon.db.global.Characters
	Guilds = addon.db.global.Guilds
	
	-- a hidden frame to contain all children frames of submodules, this avoids polluting _G[].
	addon.Frames = CreateFrame("Frame", "DataStoreFrames", UIParent)

	addon:SetupOptions()		-- See Options.lua
end

function addon:OnEnable()
	addon:RegisterEvent("PLAYER_ALIVE", OnPlayerAlive)
	addon:RegisterEvent("PLAYER_GUILD_UPDATE", OnPlayerGuildUpdate)				-- for gkick, gquit, etc..

	if IsInGuild() then
		addon:RegisterEvent("GUILD_ROSTER_UPDATE", OnGuildRosterUpdate)
		-- we only care about "%s has come online" or "%s has gone offline", so register only if player is in a guild
		addon:RegisterEvent("CHAT_MSG_SYSTEM", OnChatMsgSystem)
		addon:RegisterComm(commPrefix, GuildCommHandler)

		-- since 4.1, required !
		if not C_ChatInfo.IsAddonMessagePrefixRegistered(commPrefix) then
			C_ChatInfo.RegisterAddonMessagePrefix(commPrefix)
		end

		local guild = GetGuildInfo("player")		-- will be nil in a standard login (called too soon), but ok for a reloadui.
		if guild then
			GuildBroadcast(MSG_ANNOUNCELOGIN, GetAlts(guild))
			addon:SendMessage("DATASTORE_ANNOUNCELOGIN", guild)
		end
	end

	addon:SetLongRealmName(addon.ThisRealm:gsub(" ", ""), addon.ThisRealm)
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("PLAYER_GUILD_UPDATE")
	addon:UnregisterEvent("GUILD_ROSTER_UPDATE")
	addon:UnregisterEvent("CHAT_MSG_SYSTEM")
end

-- *** DB functions ***
function addon:GetGuildCommHandler()
	return GuildCommHandler
end

function addon:SetGuildCommCallbacks(prefix, callbacks)
	GuildCommCallbacks[prefix] = callbacks		-- no need to create a new table, it exists already as a local table in the calling module
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

function addon:IsCurrentPlayer(playerName, realm, account)
	return (playerName == addon.ThisChar) 
		and (realm == addon.ThisRealm) 
		and (account == addon.ThisAccount)
end

function addon:IsCurrentPlayerKey(playerKey)
	return playerKey == addon.ThisCharKey
end

function addon:GetCharacter(name, realm, account)
	local key = GetKey(name, realm, account)
	if Characters[key] then		-- if the key is known, return it to caller, it can be passed to other modules
		return key
	end
end

function addon:GetCharacters(realm, account)
	-- get a list of characters on a given realm/account
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	local out = {}
	local accountKey, realmKey, charKey
	for k, v in pairs(Characters) do
		if v.faction and v.faction == "" then		-- this is an integrity check, may happen after a failed account sync.
			Characters[k] = nil							-- kill the key, don't add it to the list.
		else
			accountKey, realmKey, charKey = strsplit(".", k)

			if accountKey and realmKey then
				if accountKey == account and realmKey == realm then
					out[charKey] = k
					-- allows this kind of iteration:
						-- for characterName, character in pairs(DS:GetCharacters(realm, account)) do
							-- do stuff with characterName only
							-- or do stuff with the "character" key to pass to other DataStore functions
						-- end
				end
			end
		end
	end

	return out
end

function addon:DeleteCharacter(name, realm, account)
	local key = GetKey(name, realm, account)
	if not Characters[key] or key == addon.ThisCharKey then return end	-- never delete current character

	-- delete the character in all modules
	addon:IterateDBModules(function(moduleDB, moduleName) 
		if moduleDB.Characters then
			moduleDB.Characters[key] = nil
		end
	end)

	-- delete the key in DataStore
	Characters[key] = nil
end

function addon:GetNumCharactersInDB()
	-- a simple count of the number of character entries in the db

	local count = 0
	for _, _ in pairs(Characters) do
		count = count + 1
	end
	return count
end

function addon:GetGuild(name, realm, account)
	name = name or GetGuildInfo("player")
	local key = GetKey(name, realm, account)
	
	if Guilds[key] then		-- if the key is known, return it to caller, it can be passed to other modules
		return key
	else	-- if the key is not known, try checking the connected realm info
		key = GetKey(name, addon.db.global.ConnectedRealms[addon.ThisRealm], account)
		
		if Guilds[key] then	-- if the key is known, return it to caller, it can be passed to other modules
			return key
		end
	end
end

function addon:GetGuilds(realm, account)
	-- get a list of guilds on a given realm/account
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	local out = {}
	local accountKey, realmKey, guildKey
	for k, _ in pairs(Guilds) do
		accountKey, realmKey, guildKey = strsplit(".", k)
		
		if accountKey and realmKey then
			if accountKey == account and realmKey == realm then
				out[guildKey] = k
				-- this allows to iterate with this kind of loop:
					-- for guildName, guild in pairs(DS:GetGuilds(realm, account)) do
						-- do stuff with guildName only
						-- or do stuff with the "guild" key to pass to other DataStore functions
					-- end
			end
		end
	end

	return out
end

function addon:GetGuildFaction(name, realm, account)
	name = name or GetGuildInfo("player")
	local key = GetKey(name, realm, account)

	if Guilds[key] then
		return Guilds[key].faction
	end
end

function addon:DeleteGuild(guildKey)
	if not Guilds[guildKey] then return end

	-- delete the guild in all modules
	addon:IterateDBModules(function(moduleDB) 
		if moduleDB.Guilds then
			moduleDB.Guilds[guildKey] = nil
		end
	end)

	-- delete the key in DataStore
	Guilds[guildKey] = nil
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
	addon:IterateDBModules(function(moduleDB) 
		WipeCharacterTable(moduleDB.Characters)
		WipeGuildTable(moduleDB.Guilds)
	end)

	-- main module data
	WipeCharacterTable(Characters)
	WipeGuildTable(Guilds)
end

function addon:GetRealms(account)
	account = account or addon.ThisAccount

	local out = {}
	local accountKey, realmKey
	for k, _ in pairs(Characters) do
		accountKey, realmKey = strsplit(".", k)

		if accountKey and realmKey then
			if accountKey == account then
				out[realmKey] = true
				-- allows this kind of iteration:
					-- for realmName in pairs(DS:GetRealms( account)) do
					-- end
			end
		end
	end
	return out
end

function addon:GetAccounts()
	local out = {}
	local accountKey
	for k, _ in pairs(Characters) do
		accountKey = strsplit(".", k)

		if accountKey then
			out[accountKey] = true
				-- allows this kind of iteration:
					-- for accountName in pairs(DS:GetAccounts()) do
					-- end
		end
	end
	return out
end

function addon:IterateCharacters(realmFilter, accountFilter, callback)
	
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

-- *** Guild stuff ***
function addon:GetGuildMemberInfo(member)
	-- returns the same info as the genuine GetGuildRosterInfo(), but it can be called by character name instead of by index.
	local index = guildMembersIndexes[member]
	if index then
		local fullName, rank, rankIndex, level, class, zone, note, officernote, online, status, englishClass, achievementPoints, achievementRank, isMobile, canSoR, reputation = GetGuildRosterInfo(index)

		if fullName then
			fullName = Ambiguate(fullName, "none")
		end

		return fullName, rank, rankIndex, level, class, zone, note, officernote, online, status, englishClass, achievementPoints, achievementRank, isMobile, canSoR, reputation
	end
end

function addon:GetGuildMemberAlts(member)
	local index = onlineMembersAlts[member]
	if index then
		return onlineMembersAlts[member]
	end
end

function addon:GetOnlineGuildMembers()
	return onlineMembers
end

function addon:IsGuildMemberOnline(member)
	if member == UnitName("player") then		-- if self, always return true, may happen if login broadcast hasn't come back yet
		return true
	end
	return onlineMembers[member]
end

function addon:GetNameOfMain(player)
	-- returns the name of the guild mate to whom an alt belongs

	-- ex, player x has alts a, b, c
	if onlineMembers[player] then			-- if x is passed ..it's the main
		return player							-- return it
	end

	for member, alts in pairs(onlineMembersAlts) do		--if b is passed, browse all online players who sent their alts
		for _, alt in pairs( { strsplit("|", alts) }) do	-- browse the list of alts
			if alt == player then								-- alt found ?
				return member										-- return the name of his main (currently connected)
			end
		end
	end
end
