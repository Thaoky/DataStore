local addonName, addon = ...

--[[ 
This file contains the core functions that manage how DataStore handles modules and their methods.
--]]

local registeredModules = {}
local registeredMethods = {}

local modulesList = {
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

if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	-- Add wrath modules
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
		if not registeredMethods[key] then
			-- enable this in Debug only, there's a risk that this function gets called unexpectedly
			-- print(format("DataStore : method <%s> is missing.", key))
			return
		end

		if registeredMethods[key].isCharBased then		-- if this method is character related, the first expected parameter is the character
			local owner = registeredMethods[key].owner
			
			-- arg1 is the current character key
			arg1 = owner.Characters[arg1]						-- turns a "string" parameter into a table, fully intended.
			if not arg1.lastUpdate then return end			-- lastUpdate must be present in the Character part of a db, if not, data is unavailable
			
		elseif registeredMethods[key].isGuildBased then	-- if this method is guild related, the first expected parameter is the guild
			local owner = registeredMethods[key].owner
			
			-- arg1 is the current guild key
			arg1 = owner.Guilds[arg1]							-- turns a "string" parameter into a table, fully intended.
			if not arg1 then return end
		end
		
		return registeredMethods[key].func(arg1, ...)
	end
end})


function addon:RegisterModule(moduleName, module, publicMethods, allowOverrides)
	assert(type(moduleName) == "string")
	assert(type(module) == "table")

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
	
	-- add the module's database address (addon.db.global) to the list of known modules, if it is not already known
	if registeredModules[moduleName] then return end
	
	registeredModules[moduleName] = module
	local db = module.db.global

	-- simplifies the life of child modules, and prepares a few pointers for them
	module.ThisCharacter = db.Characters[GetKey()]
	module.Characters = db.Characters
	module.Guilds = db.Guilds

	-- register module's public method
	for methodName, method in pairs(publicMethods) do
		if registeredMethods[methodName] and not allowOverrides then
			print(format("DataStore:RegisterMethod() : adding method for module <%s> failed.", moduleName))
			print(format("DataStore:RegisterMethod() : method <%s> already exists !", methodName))
			return
		end

		registeredMethods[methodName] = {
			func = method,
			owner = module, 			-- module that owns this method & associated data
		}
	end

	-- Automatically clean orphan data in child modules (ie: data exist for a char/guild in a sub module, but no key in the main module)
	--	Tested and fixed with empty sv files on 5/08/2022
	local Characters = addon.db.global.Characters
	
	for charKey, _ in pairs(db.Characters) do
		-- if the key is not valid in the main module, kill the data
		
		-- 5/08/22 : There's an issue with the test on the faction
		-- check if it is really necessary, in any case, this second test often succeeds (when it should not) 
		-- because the sequence of events is not guaranteed, thus the faction is not available
		
		-- if not Characters[charKey] or not Characters[charKey].faction then
		if not Characters[charKey] then
			db.Characters[charKey] = nil
		end
	end
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

function addon:SetCharacterBasedMethod(methodName)
	-- flags a given method as character based
	if registeredMethods[methodName] then
		-- this will take care of error checking before calling the registered method, and pass the appropriate character table as argument
		registeredMethods[methodName].isCharBased = true
	end
end

function addon:IsCharacterBasedMethod(methodName)
	local info = registeredMethods[methodName]
	
	if info and info.isCharBased then
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

-- Warning: AceAddon already has a :IterateModules..
function addon:IterateDBModules(callback)
	for moduleName, moduleDB in pairs(registeredModules) do
		callback(moduleDB.db.global, moduleName)
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

function addon:GetModuleLastUpdateByKey(module, key)
	module = GetModuleTable(module)

	if key and type(module) == "table" then
		return module.Characters[key].lastUpdate
	end
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

function addon:SetOption(module, option, value)
	module = GetModuleTable(module)

	if type(module) == "table" then
		if module.db.global.Options then
			module.db.global.Options[option] = value
		end
	end
end

function addon:GetOption(module, option)
	module = GetModuleTable(module)

	if type(module) == "table" then
		if module.db.global.Options then
			return module.db.global.Options[option]
		end
	end
end
