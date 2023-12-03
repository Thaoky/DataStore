--[[
Global Enumerations, used by other DataStore modules or client add-ons.
--]]

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
		Maximum = 12,
	},
	BankTypesLabels = {
		Cooking = GetSpellInfo(2550),
		Fishing = GetSpellInfo(131474),
		Herb = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 9),
		Cloth = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 5),
		Leather = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 6),
		Metal = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 7),
		Elemental = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 10),
		Enchanting = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 12),
		Engineering = GetSpellInfo(4036),
		Jewelcrafting = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 4),
		Inscription = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 16),
		BattlePets = AUCTION_CATEGORY_BATTLE_PETS,
		[1] = GetSpellInfo(2550),
		[2] = GetSpellInfo(131474),
		[3] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 9),
		[4] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 5),
		[5] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 6),
		[6] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 7),
		[7] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 10),
		[8] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 12),
		[9] = GetSpellInfo(4036),
		[10] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 4),
		[11] = GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 16),
		[12] = AUCTION_CATEGORY_BATTLE_PETS,
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
