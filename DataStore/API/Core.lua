local addonName, addon = ...

--[[ 
This file contains the core functions that manage how DataStore handles modules and their methods.
--]]

local registeredModules = {}
local registeredMethods = {}

local modulesList = {
	["DataStore"] = true,
	["DataStore_Achievements"] = true,
	["DataStore_Agenda"] = true,
	["DataStore_Auctions"] = true,
	["DataStore_Characters"] = true,
	["DataStore_Containers"] = true,
	["DataStore_Crafts"] = true,
	["DataStore_Inventory"] = true,
	["DataStore_Mails"] = true,
	["DataStore_Quests"] = true,
	["DataStore_Reputations"] = true,
	["DataStore_Spells"] = true,
	["DataStore_Talents"] = true
}

if WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
	-- Add cataclysm modules
	modulesList["DataStore_Currencies"] = true

elseif WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	-- retail, add the remaining modules
	modulesList["DataStore_Currencies"] = true
	modulesList["DataStore_Garrisons"] = true
	modulesList["DataStore_Pets"] = true
	modulesList["DataStore_Stats"] = true
end

local function GetKey(name, realm, account)
	-- default values
	name = name or UnitName("player")
	realm = realm or addon.ThisRealm
	account = account or addon.ThisAccount

	return format("%s.%s.%s", account, realm, name)
end


--[[ 
	*** Explanation of how the metatable works ***

	Whenever DataStore:MethodXXX(arg1, arg2, etc..) is called, this attempts to find the method in the registered list.
	If this method is character related, we intercept the string (ex: "Default.RealmZZZ.CharYYY"), 
	and get the associated character table in the module that owns these data.
	Since we actually pass a table to registered methods, the "conversion" is done here.

	*** Sample code ***
	local character = DataStore:GetCharacter()

	-- while the implementation of GetNumSpells in DataStore_Spells expects a table as first parameter, the string value returned by GetCharacter is converted on the fly
	-- this service prevents having to maintain a separate pointer to each character table in the respective DataStore_* modules.
	local n = DataStore:GetNumSpells(character, "Fire")
	print(n)
--]]

setmetatable(addon, { __index = function(self, key)
	return function(self, arg1, ...)
		local method = registeredMethods[key]
	
		if not method then
			-- enable this in Debug only, there's a risk that this function gets called unexpectedly
			-- print(format("DataStore : method <%s> is missing.", key))
			return
		end

		local owner = method.owner
		
		-- if this method is character related, the first expected parameter is the character
		if method.isCharacterBased then	
			-- arg1 is the current character key
			-- convert the key to the appropriate id
			local id = DataStore_CharacterIDs.Set[arg1]

			-- now from the id, get the linked table in the module
			arg1 = method.linkedTable[id]
			
			-- the table must be valid (for some character tables, we allow that they are not created, ex: DS_Stats weeklies)
			-- lastUpdate must be present in the Character part of a db, if not, data is unavailable
			-- if not arg1 or not arg1.lastUpdate then return end
			if not arg1 then return end
		
		elseif method.isIndexBased then	-- if this method is character related, but has no character table, so just send its index
			-- arg1 is the current character key
			-- convert the key to the appropriate id
			arg1 = DataStore_CharacterIDs.Set[arg1]
		
		elseif method.isGuildBased then	-- if this method is guild related, the first expected parameter is the guild
			-- arg1 is the current guild key
			-- convert the key to the appropriate id
			local id = DataStore_GuildIDs.Set[arg1]
			
			arg1 = method.linkedTable[id]
			
			if not arg1 then return end
		end
		
		return method.func(arg1, ...)
	end
end})

local function Print(moduleName, text)
	DEFAULT_CHAT_FRAME:AddMessage(format("|cff33ff99%s|r: %s", moduleName, text))
end

-- Initialize a table in the saved variables file
local function InitSVTable(tableName)
	-- Initialize the global DB object
	_G[tableName] = _G[tableName] or {}
	return _G[tableName]
end

local function SetMethodInfo(moduleObject, methodName, method, linkedTable, methodType)
	local method = addon:RegisterMethod(moduleObject, methodName, method)
	method[methodType] = true
	method.linkedTable = linkedTable
end

local function SetTableMethods(newModule, tables, methodType)
	if not tables then return end
	
	for name, methods in pairs(tables) do
		local svTable = InitSVTable(name)
		
		for methodName, method in pairs(methods) do
			SetMethodInfo(newModule, methodName, method, svTable, methodType)
		end
	end
end

local function SetTablesInfo(newModule, tables, storage)
	if not tables then return end
	
	-- ex: make room for a "Character" sub-table
	newModule[storage] = newModule[storage] or {}
	
	-- we only care about the table names
	for name, _ in pairs(tables) do
		newModule[storage][name] = true
	end
end


local unboundCount = 0

function addon:RegisterMethod(moduleObject, methodName, method)
	if registeredMethods[methodName] then
		print(format("DataStore:RegisterMethod() : adding method for module <%s> failed.", moduleName))
		print(format("DataStore:RegisterMethod() : method <%s> already exists !", methodName))
		return
	end
	
	if type(moduleObject) == "nil" then
		unboundCount = unboundCount + 1
		print(format("DataStore:RegisterMethod() : method <%s> is not bound to its module ! (%d)", methodName, unboundCount))
	end
	
	registeredMethods[methodName] = {
		func = method,
		owner = moduleObject, 	-- module that owns this method & associated data
	}
	
	return registeredMethods[methodName]
end

function addon:RegisterModule(options)
	assert(type(options) == "table")
	assert(type(options.addon) == "table")
	assert(type(options.addonName) == "string")
	
	local newModule = options.addon
	local moduleName = options.addonName
	
	if not modulesList[moduleName] then 
		local white	= "|cFFFFFFFF"
		local teal = "|cFF00FF9A"
		local cyan = "|cFF1CFAFE"
		local yellow = "|cFFFFFF00"
		local red = "|cFFFF0000"
		local prefix = format("%sDataStore%s: ", teal, white)

		print(format("%sError triggered by : %s%s", prefix, yellow, moduleName))
		print("You are using an unauthorized DataStore module that breaches the licensing rights of DataStore's sole author (Thaoky, EU-Marécages de Zangar).")
		print("The development and distribution of unauthorized DataStore modules outside of the official Altoholic package is prohibited by the 'All Rights Reserved' licensing terms.")
		print("|cFFFFFF00What you should do :")
		print(format("Leave the game and clear all Altoholic* and DataStore* folders from the %sInterface\\Addons%s folder, and make a manual download of the latest version of Altoholic from one of the two official sources (Curseforge and WoW Interface).", cyan, white))
		print(format("Please respect the original author's work, and do not encourage the development of modules that %scan and have already been misused%s to harm other add-ons.", red, white))
		return 
	end
	modulesList[moduleName] = nil		-- Prevent a module from registering twice
	
	if registeredModules[moduleName] then return end
	
	registeredModules[moduleName] = newModule

	-- Register tables, if any, the user may want to call that function separately from another file
	addon:RegisterTables(options)
	
	-- Simplify the life of child modules, and prepares a few pointers for them
	local key = GetKey()
	newModule.name = moduleName
	newModule.ThisCharID = DataStore_CharacterIDs.Set and DataStore_CharacterIDs.Set[key]
	newModule.Print = function(self, ...) Print(self.name, ...) end
	newModule.ListenTo = function(self, ...) addon:ListenToEvent(self, ...) end
	newModule.StopListeningTo = function(self, ...)	addon:StopListeningToEvent(self, ...) end
end

function addon:RegisterTables(options)
	-- Initialize raw tables (ie: not character or guild related)
	if options.rawTables then
		for _, tableName in pairs(options.rawTables) do
			InitSVTable(tableName)
		end
	end
	
	SetTablesInfo(options.addon, options.characterTables, "CharacterTables")
	SetTablesInfo(options.addon, options.characterIdTables, "CharacterIdTables")
	
	-- Register the character & guild based methods
	SetTableMethods(options.addon, options.characterTables, "isCharacterBased")
	SetTableMethods(options.addon, options.characterIdTables, "isIndexBased")
	SetTableMethods(options.addon, options.guildTables, "isGuildBased")
end

function addon:GetCharacterDB(dbName, initTable)
	local db = _G[dbName]
	local id = DataStore_CharacterIDs.Set[GetKey()]	
	
	-- Initialize the table for this character
	if initTable then
		db[id] = db[id] or {}		-- be sure the table is created, not required for all tables.
	end
	
	return db[id], id
end

function addon:SetDefaults(tableName, defaultValues)
	-- Get the table
	local t = _G[tableName]
	if not t then return end
	
	for k, v in pairs(defaultValues) do
		if type(t[k]) == "nil" then			-- If the key does not exist yet..
			t[k] = v									-- .. set it
		end
	end
	
	return t
end


-- returns owning module's name or nil if method is not registered
function addon:GetMethodOwner(methodName)
	local info = registeredMethods[methodName]
	local ownerName
	
	if info then
		local owner = info.owner
		if owner.GetName then
			-- implemented for any AceAddon addon or module
			ownerName = owner:GetName()
		else
			for moduleName, moduleTable in pairs(registeredModules) do
				if moduleTable == owner then
					ownerName = moduleName
					break
				end
			end
		end
	end
	
	return ownerName
end

function addon:IsCharacterBasedMethod(methodName)
	local info = registeredMethods[methodName]
	
	if info and info.isCharacterBased then
		return true
	end
end

function addon:SetGuildBasedMethod(methodName)
	if registeredMethods[methodName] then
		registeredMethods[methodName].isGuildBased = true		-- same as above for guilds
	end
end

function addon:IsGuildBasedMethod(methodName)
	local info = registeredMethods[methodName]
	
	if info and info.isGuildBased then
		return true
	end
end

function addon:GetMethodInfo(methodName)
	return addon:GetMethodOwner(methodName), addon:IsCharacterBasedMethod(methodName), addon:IsGuildBasedMethod(methodName)
end

function addon:IsModuleEnabled(name)
	assert(type(name) == "string")

	if registeredModules[name] then
		return true
	end
end

function addon:IterateModules(callback)
	for moduleName, moduleTable in pairs(registeredModules) do
		callback(moduleTable, moduleName)
	end
end

local function GetModuleTable(module)
	-- module can be either the module name (string) or the module table
	-- ex: DS:GetCharacterTable("DataStore_Containers", ...) or DS:GetCharacterTable(DataStore_Containers, ...)

	if type(module) == "string" then
		module = registeredModules[module]
	end
	
	return module
end

function addon:GetCharacterTable(module, name, realm, account)
	module = GetModuleTable(module)
	
	return module.Characters[GetKey(name, realm, account)]
end

function addon:GetModuleLastUpdate(module, name, realm, account)
	module = GetModuleTable(module)

	local key = GetKey(name, realm, account)
	if key then
		return module.Characters[key].lastUpdate
	end
end

function addon:GetModuleLastUpdateByKey(moduleName, key)
	local characterID = addon:GetCharacterID(key)
	local db = _G[format("%s_Characters", moduleName)]
	
	if db and db[characterID] then
		return db[characterID].lastUpdate
	end
	
	-- module = GetModuleTable(module)

	-- if key and type(module) == "table" then
		-- return module.Characters[key].lastUpdate
	-- end
end

function addon:ImportData(module, data, name, realm, account)
	module = GetModuleTable(module)
	
	-- CopyTable is necessary rather than assignment, without it, ace DB wildcards are not applied.
	addon:CopyTable(data, module.Characters[GetKey(name, realm, account)])
end

function addon:ImportCharacter(key, faction, guild)
	-- after data has been imported, add a player entry to the DB, so that it becomes "visible" to the outside world.
	-- in other words, the correct sequence of operations should be something like:
	--	DataStore:ImportData(DataStore_Talents)
	--	DataStore:ImportData(DataStore_Spells)
	--	DataStore:ImportCharacter(key, faction, guild)

	local characters = addon.db.global.Characters
	
	characters[key].faction = faction
	characters[key].guildName = guild

	-- Ensure a key is created for every module, even those which were not imported. 
	-- Required for proper UI support without extra validation of every method
	addon:IterateDBModules(function(moduleDB) 
		if moduleDB.Characters then
			moduleDB.Characters[key].lastUpdate = time()
		end
	end)
end
