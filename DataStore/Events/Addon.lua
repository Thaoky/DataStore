--[[ *** Add-on events ***
Support for callback methods for the in-game & custom add-on events.
--]]

local addonName, addon = ...

local TableInsert, TableRemove, ipairs = table.insert, table.remove, ipairs

local frame = CreateFrame("Frame")
local events = {}
local clearList = {}

frame:SetScript("OnEvent", function(self, eventName, arg1, ...) 
	-- if the event is one we are listening to
	if events[eventName] then
		for _, event in pairs(events[eventName]) do
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
	
	wipe(clearList)
	
	-- check all callbacks for this event, last to first
	for index, info in pairs(event) do
		local currentTag = info.tag or ""
		
		-- mark for removal if scope matches
		if info.scope == scope and currentTag == tag then
			clearList[index] = true
		end
	end

	-- Remove marked indexes
	for k, _ in pairs(clearList) do
		event[k] = nil
	end
	
	wipe(clearList)
	
	-- If no one is listening to this event anymore, do some cleanup
	if #event == 0 and C_EventUtils.IsEventValid(eventName) then
		frame:UnregisterEvent(eventName)
		events[eventName] = nil
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
