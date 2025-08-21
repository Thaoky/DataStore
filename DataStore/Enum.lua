--[[
Global Enumerations, used by other DataStore modules or client add-ons.
--]]

local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

local API_GetSpellName = isClassic and GetSpellInfo or C_Spell.GetSpellName
local API_GetItemSubClassInfo = isClassic and GetItemSubClassInfo or C_Item.GetItemSubClassInfo

DataStore.Enum = {
	BankTypes = {
		Cooking = 1,
		Fishing = 2,
		Herb = 3,
		Cloth = 4,
		Leather = 5,
		Metal = 6,
		Elemental = 7,
		Enchanting = 8,
		Engineering = 9,
		Jewelcrafting = 10,
		Inscription = 11,
		BattlePets = 12,
		
		Minimum = 1,
		MinimumExpansion = 15,	-- use index 15 for expansion 0, 16 for 1, ..
		Maximum = 15 + GetExpansionLevel(),
		
	},
	BankTypesLabels = {
		Cooking = API_GetSpellName(2550),
		Fishing = API_GetSpellName(131474),
		Herb = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 9),
		Cloth = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 5),
		Leather = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 6),
		Metal = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 7),
		Elemental = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 10),
		Enchanting = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 12),
		Engineering = API_GetSpellName(4036),
		Jewelcrafting = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 4),
		Inscription = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 16),
		BattlePets = AUCTION_CATEGORY_BATTLE_PETS,
		[1] = API_GetSpellName(2550),
		[2] = API_GetSpellName(131474),
		[3] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 9),
		[4] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 5),
		[5] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 6),
		[6] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 7),
		[7] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 10),
		[8] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 12),
		[9] = API_GetSpellName(4036),
		[10] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 4),
		[11] = API_GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 16),
		[12] = AUCTION_CATEGORY_BATTLE_PETS,
		[15] = EXPANSION_NAME0,
		[16] = EXPANSION_NAME1,
		[17] = EXPANSION_NAME2,
		[18] = EXPANSION_NAME3,
		[19] = EXPANSION_NAME4,
		[20] = EXPANSION_NAME5,
		[21] = EXPANSION_NAME6,
		[22] = EXPANSION_NAME7,
		[23] = EXPANSION_NAME8,
		[24] = EXPANSION_NAME9,
		[25] = EXPANSION_NAME10,
	},
}

local e = DataStore.Enum

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	-- classic era
	e.ExpansionPacks = {
		EXPANSION_NAME0,	-- "Classic"
	}
	
elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
	-- bcc
	e.ExpansionPacks = {
		EXPANSION_NAME0,	-- "Classic"
		EXPANSION_NAME1,	-- "The Burning Crusade"
	}
else
	-- retail
	
	-- Ordered list of expansion packs
	e.ExpansionPacks = {
		EXPANSION_NAME0,	-- "Classic"
		EXPANSION_NAME1,	-- "The Burning Crusade"
		EXPANSION_NAME2,	-- "Wrath of the Lich King"
		EXPANSION_NAME3,	-- "Cataclysm"
		EXPANSION_NAME4,	-- "Mists of Pandaria"
		EXPANSION_NAME5,	-- "Warlords of Draenor"
		EXPANSION_NAME6,	-- "Legion"
		EXPANSION_NAME7,  -- "Battle for Azeroth"
		EXPANSION_NAME8,  -- "Shadowlands"
		EXPANSION_NAME9, 	-- "Dragonflight"
	}
end
