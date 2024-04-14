--[[ *** Loading events ***
Support for callback methods for the ADDON_LOADED & PLAYER_LOGIN events.
Possibility to have multiple callback methods in different files when a given add-on is loaded.
--]]

local addonName, addon = ...

local TableInsert, ipairs = table.insert, ipairs

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local callbacks = {}
local loginQueue = {}

-- Handler for loading events
frame:SetScript("OnEvent", function(self, event, arg1, ...)
	-- ADDON_LOADED triggered once per add-on
	if event == "ADDON_LOADED" then
		
		-- if we have callbacks for this add-on, process them
		if callbacks[arg1] then
			for _, callback in ipairs(callbacks[arg1]) do
				callback()
			end
			
			-- when all callbacks for this add-on have been processed, clear the entry.
			callbacks[arg1] = nil
		end
		
	-- PLAYER_LOGIN triggered only once.
	elseif event == "PLAYER_LOGIN" then
		-- Process all callbacks
		for _, callback in ipairs(loginQueue) do
			callback()
		end
		
		-- Then delete the queue
		loginQueue = nil
	end
end)

function addon:OnAddonLoaded(name, callback)
	-- hash["DataStore"] = { callback1, callback2, .. }
	callbacks[name] = callbacks[name] or {}
	TableInsert(callbacks[name], callback)
end

function addon:OnPlayerLogin(callback)
	TableInsert(loginQueue, callback)
end
