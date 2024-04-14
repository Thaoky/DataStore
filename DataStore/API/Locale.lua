local addonName, addon = ...

--[[ 
This file contains the core functions that manage localizations
--]]

local currentLocale = GetLocale()
if currentLocale == "enGB" then currentLocale = "enUS" end

local domains = {}
local currentDomain

-- https://www.lua.org/pil/13.4.4.html Proxies
local defaultProxy = setmetatable({}, {
	__newindex = function(self, key, value) 
		-- if the key does not exist, create it
		if not rawget(currentDomain, key) then
			-- allow 'true' to be used to set the key as the default value
			rawset(currentDomain, key, value == true and key or value)
		end
	end,
	__index = function(self, key)
		print("indexing: " .. (key or "nil"))
	end,
})

local localeProxy = setmetatable({}, {
	__newindex = function(self, key, value) 
		-- no checks, allow default values to be overwritten
		-- allow 'true' to be used to set the key as the default value
		rawset(currentDomain, key, value == true and key or value)
	end,
})

function addon:SetDefaultLocale(domainName, locale)
	domains[domainName] = domains[domainName] or {}
	currentDomain = domains[domainName]
	
	return defaultProxy
end

function addon:SetLocale(domainName, locale)
	-- Wrong locale ? exit
	if locale ~= currentLocale then return end
	
	currentDomain = domains[domainName]
	if not currentDomain then
		print("No default locale has been set for this add-on: " .. domainName)
		return
	end
	
	return localeProxy
end

function addon:GetLocale(domainName)
	return domains[domainName]
end
