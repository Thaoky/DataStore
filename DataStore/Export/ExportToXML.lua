--[[	*** DataStore Export Script ***
Written by : Thaoky, EU-Marecages de Zangar
Date: 10-03-2010

READ THIS FIRST !!!

1) Prerequisites

You must have a Lua environment installed on your machine. I suggest getting LuaSocket from this address : http://luaforge.net/projects/luasocket/
Even though this script does not use any network function, LuaSocket is a useful and neat package, and other scripts I may release in the future are likely to use those features :)
Make sure to install it & configure it properly.

2) Setup a small .bat

Create a file called go.bat in this directory 
Copy this line into the file  :
	d:\Lua\lua5.1.exe export.lua

.. where d:\Lua is the directory where your Lua environment is installed

3) Set INPUT_DIR & OUTPUT_DIR to valid directories (don't forget the double backslashes !!)

INPUT_DIR must be set to the directory that contains your DataStore Saved Variables.
OUTPUT_DIR is any directory of your choice.

4) run go.bat

5) After you've ran the .bat, make sure to copy/move the .xsl that comes with the script into the OUTPUT_DIR, for your own convenience.

--]]

print("** DataStore Export **")

-- local INPUT_DIR = ""
local INPUT_DIR = "D:\\World of Warcraft\\WTF\\Account\\YOUR_ACCOUNT\\SavedVariables"
local OUTPUT_DIR = "E:\\Wow\\Export DataStore"

local USE_XSL = true				-- adds a line that refers to a basic .xsl file to display exported content, comment this line if you don't want an xsl reference.
local EMPTY_TAG_VALUE = ""		-- change this constant to whatever you want to print as value for an empty tag, ex: "", "Not Found", "Empty" ...

local format = string.format

function strsplit(delimiter, text)
	-- source : http://lua-users.org/wiki/SplitJoin
	local list = {}
	local pos = 1
	if string.find("", delimiter, 1) then -- this would result in endless loops
		error("delimiter matches empty string!")
	end
	
	if delimiter == "." then
		delimiter = "%."
	end
	
	while 1 do
		local first, last = string.find(text, delimiter, pos)
		if first then -- found?
			table.insert(list, string.sub(text, pos, first-1))
			pos = last+1
		else
			table.insert(list, string.sub(text, pos))
			break
		end
	end

	return unpack(list)
end

function CreateDir(name)
	os.execute("mkdir " .. name)
end

function ChangeDir(name)
	os.execute("chdir " .. name)
end

local function TestBit(value, pos)
	-- Typical call:  if TestBit(num, 3) then ...
	-- 0-based indexing
	
   local mask = 2^pos
	return (value % (2*mask) >= mask)
end

local function RightShift(value, numBits)
	-- for bits beyond bit 31
	return math.floor(value / 2^numBits)
end


--[[	Source:  http://lua-users.org/lists/lua-l/2002-09/msg00134.html
	Author:  Roberto Ierusalimschy 
	Note: original code is for LUA 4.0, I made the simple adjustements for 5.1
--]]

local tab = {  -- tab[i][j] = xor(i-1, j-1)
	{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, },
	{ 1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, },
	{ 2, 3, 0, 1, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, },
	{ 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12, },
	{ 4, 5, 6, 7, 0, 1, 2, 3, 12, 13, 14, 15, 8, 9, 10, 11, },
	{ 5, 4, 7, 6, 1, 0, 3, 2, 13, 12, 15, 14, 9, 8, 11, 10, },
	{ 6, 7, 4, 5, 2, 3, 0, 1, 14, 15, 12, 13, 10, 11, 8, 9, },
	{ 7, 6, 5, 4, 3, 2, 1, 0, 15, 14, 13, 12, 11, 10, 9, 8, },
	{ 8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, },
	{ 9, 8, 11, 10, 13, 12, 15, 14, 1, 0, 3, 2, 5, 4, 7, 6, },
	{ 10, 11, 8, 9, 14, 15, 12, 13, 2, 3, 0, 1, 6, 7, 4, 5, },
	{ 11, 10, 9, 8, 15, 14, 13, 12, 3, 2, 1, 0, 7, 6, 5, 4, },
	{ 12, 13, 14, 15, 8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3, },
	{ 13, 12, 15, 14, 9, 8, 11, 10, 5, 4, 7, 6, 1, 0, 3, 2, },
	{ 14, 15, 12, 13, 10, 11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1, },
	{ 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, },
}

function bXor(a, b)
	local res, c = 0, 1
	while a > 0 and b > 0 do
		local a2, b2 = math.mod(a, 16), math.mod(b, 16)
		res = res + tab[a2+1][b2+1]*c
		a = (a-a2)/16
		b = (b-b2)/16
		c = c*16
	end
	res = res + a*c + b*c
	return res
end

function bAnd(a, b)
	return ((a+b) - bXor(a,b))/2
end


local rarityColors = {
	["9d9d9d"] = 0, 		-- grey
	["ffffff"] = 1, 		-- white
	["1eff00"] = 2, 		-- green
	["0070dd"] = 3, 		-- blue
	["a335ee"] = 4, 		-- purple
	["ff8000"] = 5, 		-- orange
	["e5cc80"] = 7, 		-- heirloom
}

function GetRarityFromLink(link)
	local color = link:sub(5, 10)
	if color then
		return rarityColors[color]
	end
end

-- ** xml utility **
function CreateXMLFile(fileName)
	local f = assert(io.open(OUTPUT_DIR .. "\\" .. fileName, "w"))
	f:write("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n")
	if USE_XSL then
		f:write("<?xml-stylesheet href=\"DataStore.xsl\" type=\"text/xsl\" ?>\n")
	end
	return f
end

function WriteXMLLine(file, level, text)
	file:write(format("%s%s\n", string.rep("\t", level), text:gsub("&", "&amp;")))
end

function OpenXMLTag(file, level, tag, attributes)
	if attributes then
		WriteXMLLine(file, level, format("<%s %s>", tag, attributes))
	else
		WriteXMLLine(file, level, format("<%s>", tag))
	end
end

function CloseXMLTag(file, level, tag)
	WriteXMLLine(file, level, format("</%s>", tag))
end

function SingleLineTag(file, level, tag, value, attributes)
	if attributes then
		WriteXMLLine(file, level, format("<%s %s>%s</%s>", tag, attributes, value or EMPTY_TAG_VALUE, tag))	
	else
		WriteXMLLine(file, level, format("<%s>%s</%s>", tag, value or "Not found", tag))	
	end
end

local timeFields = {
	["lastUpdate"] = true,
	["ClientTime"] = true,
	["lastLogoutTimestamp"] = true,
	["lastCheck"] = true,
	["HistoryLastUpdate"] = true,
}

local BottomLevelNames = {
	[-42000] = "Hated",
	[-6000] = "Hostile",
	[-3000] = "Unfriendly",
	[0] = "Neutral",
	[3000] = "Friendly",
	[9000] = "Honored",
	[21000] = "Revered",
	[42000] = "Exalted",
}

local BottomLevels = { -42000, -6000, -3000, 0, 3000, 9000, 21000, 42000 }

local function GetLimits(earned)
	-- return the bottom & top values of a given rep level based on the amount of earned rep
	local top = 43000
	local index = #BottomLevels
	
	while (earned < BottomLevels[index]) do
		top = BottomLevels[index]
		index = index - 1
	end
	
	return BottomLevels[index], top
end

local FactionUIDs = {
	"Darnassus",
	"Exodar",
	"Gnomeregan",
	"Ironforge",
	"Stormwind",
	"Darkspear Trolls",
	"Orgrimmar",
	"Thunder Bluff",
	"Undercity",
	"Silvermoon City",
	"The League of Arathor",
	"Silverwing Sentinels",
	"Stormpike Guard",
	"The Defilers",
	"Warsong Outriders",
	"Frostwolf Clan",
	"Booty Bay",
	"Everlook",
	"Gadgetzan",
	"Ratchet",
	"Argent Dawn",
	"Bloodsail Buccaneers",
	"Brood of Nozdormu",
	"Cenarion Circle",
	"Darkmoon Faire",
	"Gelkis Clan Centaur",
	"Hydraxian Waterlords",
	"Magram Clan Centaur",
	"Ravenholdt",
	"Shen'dralar",
	"Syndicate",
	"Thorium Brotherhood",
	"Timbermaw Hold",
	"Tranquillien",
	"Wintersaber Trainers",
	"Zandalar Tribe",
	"Ashtongue Deathsworn",
	"Cenarion Expedition",
	"The Consortium",
	"Honor Hold",
	"Kurenai",
	"The Mag'har",
	"Netherwing",
	"Ogri'la",
	"Sporeggar",
	"Thrallmar",
	"Lower City",
	"Sha'tari Skyguard",
	"Shattered Sun Offensive",
	"The Aldor",
	"The Scryers",
	"The Sha'tar",
	"Keepers of Time",
	"The Scale of the Sands",
	"The Violet Eye",
	"Argent Crusade",
	"Kirin Tor",
	"The Kalu'ak",
	"The Wyrmrest Accord",
	"Knights of the Ebon Blade",
	"The Sons of Hodir",
	"The Ashen Verdict",
	"Alliance Vanguard",
	"Explorers' League",
	"The Frostborn",
	"The Silver Covenant",
	"Valiance Expedition",
	"Horde Expedition",
	"The Hand of Vengeance",
	"The Sunreavers",
	"The Taunka",
	"Warsong Offensive",
	"Frenzyheart Tribe",
	"The Oracles",
	"Alliance",
	"Horde",
	"Gilneas",
	"Bilgewater Cartel",
	"Guardians of Hyjal",
	"The Earthen Ring",
	"Therazane",
	"Wildhammer Clan",
	"Ramkahen",
	"Baradin's Wardens",
	"Dragonmaw Clan",
	"Hellscream's Reach",
}


-- ** Module specific export functions ** 
local specificExport = {
	["DataStore_Achievements"] = {
		["Partial"] = function(file, level, source, character)
				OpenXMLTag(file, level, "PartialAchievements")
				for index, data in pairs(source) do
					local attrib = format("id=\"%s\"", index)
					SingleLineTag(file, level+1, "Achievement", data, attrib)
				end
				CloseXMLTag(file, level, "PartialAchievements")
			end,
		["Completed"] = function(file, level, source, character)
				OpenXMLTag(file, level, "CompletedAchievements")
				for index, data in pairs(source) do
					local achievementID
					
					-- index [1] holds achievements 1-32
					-- index [2] holds achievements 33-64
					-- etc..
					
					for bitPos = 0, 31 do	-- parse the first 32 bits of the number
						if TestBit(data, bitPos) then		-- if this bit is set, achievement is completed
							
							-- 32, 64, etc.. are stored in bit 0
							-- [1]   =  32, 1, 2 , ..... , 31
							-- [2]   =  64, 32, 33 , ..... , 63
							
							if bitPos == 0 then
								achievementID = index * 32
							else
								achievementID = (index - 1) * 32
								achievementID = achievementID + bitPos
							end
							
							local attrib = format("id=\"%s\"", achievementID)
							local month, day, year = character.CompletionDates[achievementID]:match("(%d+):(%d+):(%d+)")
							year = tonumber(year) + 2000
								
							attrib = format("%s completionDate=\"%s/%s/%s\"", attrib, month, day, year)
							SingleLineTag(file, level+1, "Achievement", "true", attrib)
						end
					end
				end
				CloseXMLTag(file, level, "CompletedAchievements")
			end,
	},
	["DataStore_Auctions"] = {
		["Auctions"] = function(file, level, source)
				OpenXMLTag(file, level, "Auctions")
				for index, data in pairs(source) do
					local isGoblin, itemID, count, highBidder, startPrice, buyoutPrice, timeLeft = strsplit("|", data)
					
					local attrib = format("count=\"%s\" highBidder=\"%s\" startPrice=\"%s\" buyoutPrice=\"%s\" timeLeft=\"%s\"", count, highBidder, startPrice, buyoutPrice, timeLeft)
					if isGoblin == "1" then
						attrib = format("%s GoblinAH=\"true\"", attrib)
					end
					SingleLineTag(file, level+1, "Auction", itemID, attrib)
				end
				CloseXMLTag(file, level, "Auctions")
			end,
		["Bids"] = function(file, level, source)
				OpenXMLTag(file, level, "Bids")
				for index, data in pairs(source) do
					local isGoblin, itemID, count, ownerName, bidPrice, buyoutPrice, timeLeft = strsplit("|", data)
					
					local attrib = format("count=\"%s\" ownerName=\"%s\" bidPrice=\"%s\" buyoutPrice=\"%s\" timeLeft=\"%s\"", count, ownerName, bidPrice, buyoutPrice, timeLeft)
					if isGoblin == "1" then
						attrib = format("%s GoblinAH=\"true\"", attrib)
					end
					SingleLineTag(file, level+1, "Auction", itemID, attrib)
				end
				CloseXMLTag(file, level, "Bids")
			end,
	},
	["DataStore_Containers"] = {
		["Containers"] = function(file, level, source)
				OpenXMLTag(file, level, "Containers")
				for bagIndex, bag in pairs(source) do
					local bagID = tonumber(bagIndex:sub(4))
					OpenXMLTag(file, level+1, "Bag", format("id=\"%s\"", bagID))

					for key, value in pairs(bag) do
						if type(value) == "number" then
							SingleLineTag(file, level+2, key, value)
						elseif type(value) == "string" then
							SingleLineTag(file, level+2, key, value)
						elseif type(value) == "boolean" then
							SingleLineTag(file, level+2, key, (value) and "true" or "false")
						elseif type(value) == "table" then
							if key == "ids" then		-- ids is the main table, the two others (links & counts) are complement
								OpenXMLTag(file, level+2, "Content")
								for slotID, itemID in pairs(value) do

									local text = format("Item %d", itemID)
									local count = 1
									if bag.counts and bag.counts[slotID] then
										count = bag.counts[slotID]
									end
									
									local attrib =	format("slot=\"%s\" count=\"%s\" id=\"%s\"", slotID, count, itemID)
									if bag.links and bag.links[slotID] then
										local link = bag.links[slotID]
										text = link:match("%[(.+)%]")		-- this gets the itemName
										local rarity = GetRarityFromLink(link)
										
										attrib = format("%s rarity=\"%s\" link=\"%s\"", attrib, rarity, link)
									end
								
									SingleLineTag(file, level+3, "Item", text, attrib)
								end
								CloseXMLTag(file, level+2, "Content")
							end
						end
					end
					CloseXMLTag(file, level+1, "Bag")
				end
				CloseXMLTag(file, level, "Containers")
			end,
		["Tabs"] = function(file, level, source)
				OpenXMLTag(file, level, "Tabs")
				for tabID, tab in pairs(source) do
					OpenXMLTag(file, level+1, "Tab", format("id=\"%s\"", tabID))

					for key, value in pairs(tab) do
						if type(value) == "number" then
							if timeFields[key] then
								SingleLineTag(file, level+2, key, os.date("%m/%d/%Y %X", value))
							else
								SingleLineTag(file, level+2, key, value)
							end
						elseif type(value) == "string" then
							SingleLineTag(file, level+2, key, value)
						elseif type(value) == "boolean" then
							SingleLineTag(file, level+2, key, (value) and "true" or "false")
						elseif type(value) == "table" then
							if key == "ids" then		-- ids is the main table, the two others (links & counts) are complement
								OpenXMLTag(file, level+2, "Content")
								for slotID, itemID in pairs(value) do

									local text = format("Item %d", itemID)
									local count = 1
									if tab.counts and tab.counts[slotID] then
										count = tab.counts[slotID]
									end
									
									local attrib =	format("slot=\"%s\" count=\"%s\" id=\"%s\"", slotID, count, itemID)
									if tab.links and tab.links[slotID] then
										local link = tab.links[slotID]
										text = link:match("%[(.+)%]")		-- this gets the itemName
										local rarity = GetRarityFromLink(link)
										
										attrib = format("%s rarity=\"%s\" link=\"%s\"", attrib, rarity, link)
									end
								
									SingleLineTag(file, level+3, "Item", itemID, attrib)
								end
								CloseXMLTag(file, level+2, "Content")
							end
						end
					end
					CloseXMLTag(file, level+1, "Tab")
				end				
				CloseXMLTag(file, level, "Tabs")
			end,
	},
	["DataStore_Crafts"] = {
		["Professions"] = function(file, level, source)
				OpenXMLTag(file, level, "Professions")
				for professionName, profession in pairs(source) do
					OpenXMLTag(file, level+1, "Profession", format("name=\"%s\"", professionName))
					
					for key, value in pairs(profession) do
						if type(value) == "number" then
							SingleLineTag(file, level+2, key, value)
						elseif type(value) == "string" then
							SingleLineTag(file, level+2, key, value)
						elseif type(value) == "boolean" then
							SingleLineTag(file, level+2, key, (value) and "true" or "false")
						elseif type(value) == "table" then
							if key == "Crafts" then		-- there shouldn't be any other
								OpenXMLTag(file, level+2, "Crafts")

								local currentHeader
								for index, craft in ipairs(value) do
									if type(craft) == "string" then
										if currentHeader then
											CloseXMLTag(file, level+3, "Category")
										end
										OpenXMLTag(file, level+3, "Category", format("name=\"%s\"", craft))
										currentHeader = craft
									else
										local spellID = RightShift(craft, 2)	--  first 2 bits = color, other bits = spell id
									
										SingleLineTag(file, level+4, "Spell", spellID)
									end
								end
								
								if currentHeader then
									CloseXMLTag(file, level+3, "Category")
								end
								CloseXMLTag(file, level+2, "Crafts")
							end
						end
					end
					CloseXMLTag(file, level+1, "Profession")
				end
				CloseXMLTag(file, level, "Professions")
			end,
	},
	["DataStore_Currencies"] = {
		["Currencies"] = function(file, level, source)
				OpenXMLTag(file, level, "Currencies")
				
				local ref = DataStore_CurrenciesDB.global.Reference
				
				local currentCategory
				for index, data in ipairs(source) do
					local isHeader = TestBit(data , 0)
					local count = RightShift(data, 7)
					local refIndex = RightShift(data, 1) - (count *64)	-- since bAnd is not available, proceed otherwise
					
					local info = ref.Currencies[refIndex]
					local name = strsplit("|", info)
					
					if isHeader then
						if currentCategory then
							CloseXMLTag(file, level+1, "Category")
						end
						OpenXMLTag(file, level+1, "Category", format("name=\"%s\"", name))
						currentCategory = name
					else
						SingleLineTag(file, level+2, "Currency", name, format("count=\"%s\"", count))
					end
				end
				if currentCategory then
					CloseXMLTag(file, level+1, "Category")
				end
				CloseXMLTag(file, level, "Currencies")
			end,
	},
	["DataStore_Inventory"] = {
		["Inventory"] = function(file, level, source)
				OpenXMLTag(file, level, "Inventory")
				for index, item in pairs(source) do
					local attrib = format("index=\"%s\"", index)
					local text, itemID
					
					if type(item) == "number" then
						itemID = item
						text = format("Item %d", itemID)
					else
						itemID = tonumber(item:match("item:(%d+)"))
						text = item:match("%[(.+)%]")		-- this gets the itemName
						local rarity = GetRarityFromLink(item)
						
						attrib = format("%s rarity=\"%s\" link=\"%s\"", attrib, rarity, item)
					end
					
					attrib = format("%s id=\"%s\"", attrib, itemID)
					SingleLineTag(file, level+1, "Item", text, attrib)
				end
				CloseXMLTag(file, level, "Inventory")
			end,
	},
	["DataStore_Mails"] = {
		["Mails"] = function(file, level, source)
				OpenXMLTag(file, level, "Mails")
				for index, mail in pairs(source) do
					OpenXMLTag(file, level+1, "Mail")
					
					for key, value in pairs(mail) do
						if timeFields[key] then
							SingleLineTag(file, level+2, key, os.date("%m/%d/%Y %X", value))
						else
							SingleLineTag(file, level+2, key, value)
						end
					end
					CloseXMLTag(file, level+1, "Mail")
				end
				CloseXMLTag(file, level, "Mails")
			end,
	},
	["DataStore_Pets"] = {
		["CRITTER"] = function(file, level, source)
				OpenXMLTag(file, level, "Companions")
				
				local RefSpells = DataStore_PetsDB.global.Reference.Spells
				
				for _, spellID in pairs(source) do
					local modelID = RefSpells[spellID]
					local attrib = format("modelID=\"%s\"", modelID or "?")	-- model id may be unknown for imported accounts
					
					SingleLineTag(file, level+1, "Spell", spellID, attrib)
				end
				CloseXMLTag(file, level, "Companions")
			end,
		["MOUNT"] = function(file, level, source)
				OpenXMLTag(file, level, "Mounts")
				
				local RefSpells = DataStore_PetsDB.global.Reference.Spells
				
				for _, spellID in pairs(source) do
					local modelID = RefSpells[spellID]
					local attrib = format("modelID=\"%s\"", modelID or "?")
					
					SingleLineTag(file, level+1, "Spell", spellID, attrib)
				end
				CloseXMLTag(file, level, "Mounts")
			end,
	},
	["DataStore_Quests"] = {
		["History"] = function(file, level, source)
				OpenXMLTag(file, level, "History")
				for index, data in pairs(source) do
					local questID
					
					-- index [1] holds quests 1-32
					-- index [2] holds quests 33-64
					-- etc..
					
					for bitPos = 0, 31 do	-- parse the first 32 bits of the number
						if TestBit(data, bitPos) then		-- if this bit is set, quest is completed
							
							-- 32, 64, etc.. are stored in bit 0
							-- [1]   =  32, 1, 2 , ..... , 31
							-- [2]   =  64, 32, 33 , ..... , 63
							
							if bitPos == 0 then
								questID = index * 32
							else
								questID = (index - 1) * 32
								questID = questID + bitPos
							end
				
							SingleLineTag(file, level+1, "ID", questID)
						end
					end
				end
				CloseXMLTag(file, level, "History")
			end,
		["Quests"] = function(file, level, source, character)
				OpenXMLTag(file, level, "QuestLog")
				for index, data in pairs(source) do
					local attrib = format("index=\"%s\"", index)
					local text
					
					local isHeader, questTag, groupSize, money = strsplit("|", data)
					groupSize = tonumber(groupSize)
					money = tonumber(money)
					
					if isHeader == "0" then
						text = questTag		-- catagory name
						attrib = format("%s isHeader=\"true\"", attrib)
					else
						if questTag ~= "" then
							attrib = format("%s tag=\"%s\"", attrib, questTag)
						end
					end
					
					if groupSize and groupSize > 0 then
						attrib = format("%s groupSize=\"%s\"", attrib, groupSize)
					end
					if money and money > 0 then
						attrib = format("%s money=\"%s\"", attrib, money)
					end
					
					-- Fully functional, uncomment if there's demand.
					local link = character.QuestLinks[index]
					if link then
						local questID, questLevel = link:match("quest:(%d+):(-?%d+)")
						text = link:match("%[(.+)%]")		-- this gets the questName
						attrib = format("%s id=\"%s\" level=\"%s\"", attrib, questID, questLevel)
					end
					
					if character.Rewards then
						local rewards = character.Rewards[index]
						if rewards then
							attrib = format("%s rewards=\"%s\"", attrib, rewards)
						end
					end
					
					SingleLineTag(file, level+1, "Quest", text, attrib)
				end
				CloseXMLTag(file, level, "QuestLog")
			end,
	},
	["DataStore_Reputations"] = {
		["Factions"] = function(file, level, source)
				OpenXMLTag(file, level, "Factions")
				for index, earned in pairs(source) do
					local name = FactionUIDs[index]
					local bottom, top = GetLimits(earned)
				
					SingleLineTag(file, level+1, "Faction", name, format("rank=\"%s\" numPoints=\"%s\" maxPoints=\"%s\"", BottomLevelNames[bottom], (earned - bottom), (top - bottom)))
				end
				CloseXMLTag(file, level, "Factions")
			end,
	},
	["DataStore_Spells"] = {
		["Spells"] = function(file, level, source)
				OpenXMLTag(file, level, "Spells")
				for schoolName, school in pairs(source) do
					OpenXMLTag(file, level+1, "School", format("name=\"%s\"", schoolName))
					
					local attrib
					for index, value in ipairs(school) do
						local id = RightShift(value, 8)
					
						attrib = format("index=\"%s\"", index)
						SingleLineTag(file, level+2, "Spell", id, attrib)
					end
					CloseXMLTag(file, level+1, "School")
				end
				CloseXMLTag(file, level, "Spells")
			end,
	},
	["DataStore_Stats"] = {
		["Stats"] = function(file, level, source)
				-- to do : improve this, needs some specific code per stat type (if there's demand)
				OpenXMLTag(file, level, "Stats")
				for name, data in pairs(source) do
					SingleLineTag(file, level+1, name, data)
				end
				CloseXMLTag(file, level, "Stats")
			end,
	},
	["DataStore_Talents"] = {
		["Glyphs"] = function(file, level, source)
				OpenXMLTag(file, level, "Glyphs")
				for index, glyph in pairs(source) do
				
					-- bit 0 : enabled
					-- bits 1-2 : glyphType
					-- bits 3-19 : spellID (yes, 17 bits, not 16, just in case spell ids go beyond 65k)
					-- bits 20-22 : tooltip index. So far only 0, 1, 2, but let's use 3 bits to play it safe.
					-- bits 23- : glyphID
								
					local enabled = bAnd(glyph, 1)
					local glyphType = bAnd(RightShift(glyph, 1), 3)
					local spell = bAnd(RightShift(glyph, 3), 131071)	-- 17 bits mask
					local glyphID = RightShift(glyph, 23)
					
					if enabled == 1 and spell ~= 0 then
						if glyphType == 1 then
							glyphType = "major"
						elseif glyphType == 2 then
							glyphType = "minor"
						elseif glyphType == 3 then
							glyphType = "prime"
						end
						
						local spec = (index <= 9) and "primary" or "secondary"
					
						SingleLineTag(file, level+1, "Glyph", glyphID, format("spec=\"%s\" glyphType=\"%s\" spellID=\"%s\"", spec, glyphType, spell))
					end
				end
				CloseXMLTag(file, level, "Glyphs")
			end,
		["TalentTrees"] = function(file, level, source, character)
				OpenXMLTag(file, level, "TalentTrees")
				
				for treeIndex, data in pairs(source) do
					local treeName, spec = strsplit("|", treeIndex)
					spec = (spec == "1") and "primary" or "secondary"
					local classRef = DataStore_TalentsRefDB.global[character.Class]			-- this points to the class info from the ref table
					
					if classRef.Trees[treeName] then		-- might fail if db contains different locales
					
						local talentRef = classRef.Trees[treeName].talents		-- this points to talent info from the ref table

						OpenXMLTag(file, level+1, "TalentTree", format("name=\"%s\" spec=\"%s\"", treeName, spec))
						
						local talentIndex = 1
						while data ~= 0 do
							local points = bAnd(data, 3)	-- add the lowest 2 bits ..
							
							local id, name, _, _, _, maximumRank = strsplit("|", talentRef[talentIndex])
							
							SingleLineTag(file, level+2, "Talent", name, format("index=\"%s\" id=\"%s\" pointsSpent=\"%s\" maximumRank=\"%s\"", talentIndex, id, points, maximumRank))
							
							data = RightShift(data, 2)		-- shift 2 bits to the right
							talentIndex = talentIndex + 1
						end
					
						CloseXMLTag(file, level+1, "TalentTree")
					end
				end
				CloseXMLTag(file, level, "TalentTrees")
			end,
	},
}

function ExportCharacters(moduleName, file)
	OpenXMLTag(file, 1, "Characters")
	
	local db = _G[moduleName .."DB"]
	local level = 2

	for characterKey, character in pairs(db.global.Characters) do
		local account, realm, characterName = strsplit(".", characterKey)
		OpenXMLTag(file, level, format("Character name=\"%s\" realm=\"%s\" account=\"%s\"", characterName, realm, account))

		for key, value in pairs(character) do
			if type(value) == "number" then
				if timeFields[key] then
					SingleLineTag(file, level+1, key, os.date("%m/%d/%Y %X", value))
				else
					SingleLineTag(file, level+1, key, value)
				end
			elseif type(value) == "string" then
				SingleLineTag(file, level+1, key, value)
			elseif type(value) == "table" then
				if specificExport[moduleName] and specificExport[moduleName][key] then	-- ex: if specificExport["DataStore_Reputations"]["Factions"] exists, call it
				
					specificExport[moduleName][key](file, level+1, value, character)
				end
			end
		end
		
		CloseXMLTag(file, level, "Character")
	end
	CloseXMLTag(file, 1, "Characters")
end

function ExportGuilds(moduleName, file)
	OpenXMLTag(file, 1, "Guilds")
	
	local db = _G[moduleName .."DB"]
	local level = 2

	for guildKey, guild in pairs(db.global.Guilds) do
		local account, realm, guildName = strsplit(".", guildKey)
		OpenXMLTag(file, level, format("Guild name=\"%s\" realm=\"%s\" account=\"%s\"", guildName, realm, account))
		
		for key, value in pairs(guild) do
			if type(value) == "number" then
				SingleLineTag(file, level+1, key, value)
			elseif type(value) == "string" then
				SingleLineTag(file, level+1, key, value)
			elseif type(value) == "table" then
				if specificExport[moduleName] and specificExport[moduleName][key] then	-- ex: if specificExport["DataStore_Reputations"]["Factions"] exists, call it
				
					specificExport[moduleName][key](file, level+1, value)
				end
			end
		end
		
		CloseXMLTag(file, level, "Guild")
	end
	
	CloseXMLTag(file, 1, "Guilds")
end

function ExportModule(moduleName)
	dofile(INPUT_DIR .. "\\"..moduleName .. ".lua")
	
	print(format("Exporting %s ...", moduleName))
	local f = CreateXMLFile(moduleName..".xml")
	OpenXMLTag(f, 0, format("DataStorePage Title=\"%s\"", moduleName))
	ExportCharacters(moduleName, f)
	
	if moduleName == "DataStore" or moduleName == "DataStore_Containers" then
		ExportGuilds(moduleName, f)
	end
	
	CloseXMLTag(f, 0, "DataStorePage")
	f:close()
end

local modules = {
	"DataStore",
	"DataStore_Achievements",
	"DataStore_Auctions",
	"DataStore_Characters",
	"DataStore_Containers",
	"DataStore_Crafts",
	"DataStore_Currencies",
	"DataStore_Inventory",
	"DataStore_Mails",
	"DataStore_Pets",
	"DataStore_Quests",
	"DataStore_Reputations",
	"DataStore_Spells",
	"DataStore_Stats",
	"DataStore_Talents",
}

for _, moduleName in pairs(modules) do
	ExportModule(moduleName)
end

print("Export complete !")
