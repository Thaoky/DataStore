local addonName, addon = ...

--[[ 
This file contains the core functions that manage guild communications
--]]

local commPrefix = "DataStore"
local onlineMembers = {}			-- simple hash table to track online members:		["member"] = true (or nil)
local onlineMembersAlts = {}		-- simple hash table to track online members' alts:	["member"] = "alt1|alt2|alt3..."
local guildMembersIndexes = {} 	-- hash table containing guild member info
local currentGuildName

local LibSerialize = LibStub:GetLibrary("LibSerialize")

local DataStore = DataStore
local TableInsert, TableConcat, format, strsplit, gsub, pairs = table.insert, table.concat, format, strsplit, gsub, pairs
local GetGuildInfo, GetGuildRosterInfo, GetNumGuildMembers, UnitName, C_ChatInfo = GetGuildInfo, GetGuildRosterInfo, GetNumGuildMembers, UnitName, C_ChatInfo

-- Message types
local MSG_ANNOUNCELOGIN				= 1	-- broadcast at login
local MSG_LOGINREPLY					= 2	-- reply to MSG_ANNOUNCELOGIN

local function GetKey(name, realm, account)
	-- default values
	name = name or UnitName("player")
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	return format("%s.%s.%s", account, realm, name)
end

local function GetAlts()

	local guild = GetGuildInfo("player")
	if not guild then	return end
	
	local guildKey = GetKey(guild)
	local guildID = addon:StoreToSetAndList(DataStore_GuildIDs, guildKey)
	
	local out = {}
	for k, charID in pairs(DataStore_CharacterIDs.Set) do
		local account, realm, char = strsplit(".", k)

		if account and account == addon.ThisAccount		-- same account
			and realm and realm == addon.ThisRealm			-- same realm
			and char and char ~= addon.ThisChar then		-- skip current char

			local characterGuildID = DataStore_CharacterGuilds[charID]

			-- same guild (to send only guilded alts, privacy concern, do not change this)
			if characterGuildID and characterGuildID == guildID then
				TableInsert(out, char)
			end
		end
	end

	-- returns a | delimited string containing the list of alts in the same guild
	return TableConcat(out, "|")
end

local function SaveAlts(sender, alts)
	if alts then
		if strlen(alts) > 0 then	-- sender has no alts
			onlineMembersAlts[sender] = alts				-- "alt1|alt2|alt3..."
		end
		DataStore:Broadcast("DATASTORE_GUILD_ALTS_RECEIVED", sender, alts)
	end
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
				DataStore:Broadcast("DATASTORE_GUILD_MEMBER_OFFLINE", name)
			end
			onlineMembers[name] = onlineStatus
		end
	end
end

local function OnPlayerGuildUpdate()
	-- at login this event is called between OnEnable and PLAYER_ALIVE, where GetGuildInfo returns a wrong value
	-- however, the value returned here is correct
	
	-- If a guild name is already known, or if the character is not in a guild, leave.
	if currentGuildName or not IsInGuild() then return end
	
	local realmName, _
	currentGuildName, _, _, realmName = GetGuildInfo("player")		-- realmName will be nil if guild is on the same realm as the character

	-- the event may be triggered multiple times, and GetGuildInfo may return incoherent values in subsequent calls, leave if we have no usable value
	if not currentGuildName then return end
		
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
				DataStore_ConnectedRealms[longName] = addon.ThisRealm
				DataStore_ConnectedRealms[addon.ThisRealm] = longName
			end
		end
	end
	
	local guildID
	
	-- guild key may be nil if the character is on a different realm than his guild, and he never logged on to that server
	-- .. so the long realm name is unknown ..
	if guildKey then
		guildID = addon:StoreToSetAndList(DataStore_GuildIDs, guildKey)
		DataStore_GuildFactions[guildID] = addon.ThisFaction
		
		-- the first time a valid value is found, broadcast to guild, it must happen here for a standard login, but won't work here after a reloadui since this event is not triggered
		addon:GuildBroadcast(commPrefix, MSG_ANNOUNCELOGIN, GetAlts())
		addon:Broadcast("DATASTORE_ANNOUNCELOGIN", currentGuildName)
	end
	
	local id = addon:StoreToSetAndList(DataStore_CharacterIDs, addon.ThisCharKey)
	DataStore_CharacterGuilds[id] = guildID
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
			DataStore:Broadcast("DATASTORE_GUILD_MEMBER_OFFLINE", member)
		end
	end
end

-- *** Guild Comm ***
function addon:GuildWhisper(prefix, player, messageType, ...)
	-- be sure the target is online..
	if addon:IsGuildMemberOnline(player) then 
		local data = LibSerialize:Serialize(messageType, ...)
		addon:SendChatMessage(prefix, data, "WHISPER", player)
	end
end

function addon:GuildBroadcast(prefix, messageType, ...)
	local data = LibSerialize:Serialize(messageType, ...)
	addon:SendChatMessage(prefix, data, "GUILD")
end

local commCallbacks = {
	[commPrefix] = {
		[MSG_ANNOUNCELOGIN] = function(sender, alts)
				onlineMembers[sender] = true									-- sender is obviously online
				if sender ~= UnitName("player") then						-- don't send back to self
					addon:GuildWhisper(commPrefix, sender, MSG_LOGINREPLY, GetAlts())		-- reply by sending my own alts ..
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
	local success, msgType, arg1, arg2, arg3 = LibSerialize:Deserialize(message)
	if success and msgType and commCallbacks[prefix] then
		local func = commCallbacks[prefix][msgType]

		if func then
			func(sender, arg1, arg2, arg3)
		end
	end
end

DataStore:OnPlayerLogin(function()
	addon:ListenTo("PLAYER_ALIVE", OnPlayerGuildUpdate)
	addon:ListenTo("PLAYER_GUILD_UPDATE", OnPlayerGuildUpdate)				-- for gkick, gquit, etc..

	if not IsInGuild() then return end

	addon:ListenTo("GUILD_ROSTER_UPDATE", OnGuildRosterUpdate)
	-- we only care about "%s has come online" or "%s has gone offline", so register only if player is in a guild
	addon:ListenTo("CHAT_MSG_SYSTEM", OnChatMsgSystem)

	addon:OnGuildComm(commPrefix, GuildCommHandler)

	-- since 4.1, required !
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(commPrefix) then
		C_ChatInfo.RegisterAddonMessagePrefix(commPrefix)
	end

	-- will be nil in a standard login (called too soon), but ok for a reloadui.
	local guild = GetGuildInfo("player")
	
	if guild then
		addon:GuildBroadcast(commPrefix, MSG_ANNOUNCELOGIN, GetAlts())
		addon:Broadcast("DATASTORE_ANNOUNCELOGIN", guild)
	end
end)


-- *** API ***
function addon:GetGuildCommHandler()
	return GuildCommHandler
end

function addon:SetGuildCommCallbacks(prefix, callbacks)
	-- no need to create a new table, it exists already as a local table in the calling module
	commCallbacks[prefix] = callbacks
end

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
	-- if self, always return true, may happen if login broadcast hasn't come back yet
	return member == UnitName("player") and true or onlineMembers[member]
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
