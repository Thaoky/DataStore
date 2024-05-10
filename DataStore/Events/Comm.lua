--[[ *** Guild communication events ***
Support for callback methods for the CHAT_MSG_ADDON events.
--]]

local addonName, addon = ...
local CTL = ChatThrottleLib

local TableInsert, TableConcat, format, match, strsub, ipairs = table.insert, table.concat, format, string.match, string.sub, ipairs
local C_ChatInfo = C_ChatInfo

local frame = CreateFrame("Frame")
frame:UnregisterAllEvents()
frame:RegisterEvent("CHAT_MSG_ADDON")

-- Headers for messages sent in multiple chunks.
-- Preseve the values used by AceComm for compatibility with older versions.
local HEADER_FIRST_MSG = "\001"
local HEADER_NEXT_MSG = "\002"
local HEADER_LAST_MSG = "\003"
local HEADER_ESCAPE_CTRL = "\004"

local callbacks = {}
local incomingChunks = {}

local function ExecuteCallbacks(prefix, content, distribution, sender)
	-- if we have callbacks for this prefix, process them
	if callbacks[prefix] then
		for _, callback in ipairs(callbacks[prefix]) do
			callback(prefix, content, distribution, sender)
		end
	end
end

frame:SetScript("OnEvent", function(self, event, prefix, message, distribution, sender)
	if event ~= "CHAT_MSG_ADDON" then return end
	
	sender = Ambiguate(sender, "none")
	
	local control, chunk = match(message, "^([\001-\009])(.*)")
	
	if control then
		local uniqueID = format("%s|%s|%s", prefix, distribution, sender)
		
		if control == HEADER_FIRST_MSG then
			incomingChunks[uniqueID] = {}
			TableInsert(incomingChunks[uniqueID], chunk)
		
		elseif control == HEADER_NEXT_MSG then
			-- if this is false, we lost the first message..
			if incomingChunks[uniqueID] then
				TableInsert(incomingChunks[uniqueID], chunk)
			end
		
		elseif control == HEADER_LAST_MSG then
			-- if this is false, we lost the first message..
			if incomingChunks[uniqueID] then
				TableInsert(incomingChunks[uniqueID], chunk)
				
				ExecuteCallbacks(prefix, TableConcat(incomingChunks[uniqueID], ""), distribution, sender)
				incomingChunks[uniqueID] = nil
			end
		elseif control == HEADER_ESCAPE_CTRL then
			ExecuteCallbacks(prefix, chunk, distribution, sender)
		end
	else
		ExecuteCallbacks(prefix, message, distribution, sender)
	end
end)

function addon:OnGuildComm(prefix, callback)
	if #prefix > 16 then
		print(format("DataStore:OnGuildComm() Prefix %s is longer than 16 characters.", prefix))
	end
	
	callbacks[prefix] = callbacks[prefix] or {}
	TableInsert(callbacks[prefix], callback)	
	
	-- Start listening for addon messages
	C_ChatInfo.RegisterAddonMessagePrefix(prefix)
end

function addon:SendChatMessage(prefix, message, distribution, target)
	-- Overall same code as AceComm in here, their code was already pretty optimized.
	
	-- Is there already a control character at the beginning ?
	if match(message, "^[\001-\009]") then
		message = HEADER_ESCAPE_CTRL .. message
	end
	
	-- Smaller message ? send directly
	if #message <= 255 then
		CTL:SendAddonMessage("NORMAL", prefix, message, distribution, target)
		return
	end
	
	-- Longer message ? we will be using one byte for the header of each chunk, so reduce the chunk size
	local maxChunkSize = 254
	
	-- First chunk
	local chunk = strsub(message, 1, maxChunkSize)
	CTL:SendAddonMessage("NORMAL", prefix, HEADER_FIRST_MSG .. chunk, distribution, target)
	
	-- Intermediate chunks
	local pos = 255
	
	while pos + maxChunkSize - 1 < #message do
		chunk = strsub(message, pos, pos + maxChunkSize - 1)
		CTL:SendAddonMessage("NORMAL", prefix, HEADER_NEXT_MSG .. chunk, distribution, target)
		pos = pos + maxChunkSize
	end
	
	-- Last chunk
	chunk = strsub(message, pos)
	CTL:SendAddonMessage("NORMAL", prefix, HEADER_LAST_MSG .. chunk, distribution, target)
end
