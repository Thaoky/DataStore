--[[ *** Add-on events ***
Support for callback methods for the in-game & custom add-on events.
--]]

local addonName, addon = ...

local TableInsert, TableRemove, ipairs = table.insert, table.remove, ipairs

local frame = CreateFrame("Frame")
local events = {}

frame:SetScript("OnEvent", function(self, eventName, arg1, ...) 
	-- if the event is one we are listening to
	if events[eventName] then
		for _, event in ipairs(events[eventName]) do
			event.callback(eventName, arg1, ...)
		end
	end
end)

function addon:ListenToEvent(scope, eventName, callback, tag)
--[[ 
tag is optional, may be used as a unique identifier in the case where the same scope/add-on registers
the same event twice in separate files.
Listening would not be a problem, but if the user wants to stop listening to one of them, it is necessary
to be able to identify the right one otherwise scope 2 would unregister the event of scope 1.
--]]
	
	-- if no one is listening to this event yet..
	if not events[eventName] then
		-- .. make room for it
		events[eventName] = {}

		-- .. and register it
		-- DataStore internal events are obviously not known by the game, so don't register them
		if C_EventUtils.IsEventValid(eventName) then
			frame:RegisterEvent(eventName)
		end
	end

	TableInsert(events[eventName], { scope = scope, callback = callback, tag = tag })
end

function addon:StopListeningToEvent(scope, eventName, tag)
	-- wrong event ? exit
	if not events[eventName] then return end

	local event = events[eventName]
	tag = tag or ""
	
	-- check all callbacks for this event, last to first
	for i = #event, 1, -1 do
		local currentTag = event[i].tag or ""
		
		-- remove if scope matches
		if event[i].scope == scope and currentTag == tag then
			TableRemove(event, i)
			
			-- .. and unregister it
			if C_EventUtils.IsEventValid(eventName) then
				frame:UnregisterEvent(eventName)
			end
		end
	end
end

function addon:Broadcast(eventName, ...)
	local event = events[eventName]
	
	if event then
		for _, eventInfo in ipairs(event) do
			eventInfo.callback(eventName, ...)
		end
	end
end
