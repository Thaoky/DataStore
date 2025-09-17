local addonName, addon = ...

local TableInsert, TableConcat, format, pairs = table.insert, table.concat, format, pairs
local altGroups

addon.AltGroups = {}
local namespace = addon.AltGroups

function namespace:Create(group)
	if not altGroups[group] then
		altGroups[group] = {}
		
		-- return true to confirm that the group was not already found and was created
		return true
	end
end

function namespace:Delete(group)
	if altGroups[group] then
		altGroups[group] = nil
		
		-- return true to confirm that the group was found and deleted
		return true
	end
end

function namespace:Rename(oldGroup, newGroup)
	if altGroups[oldGroup] then
		-- make the new group point to the same table as the old
		altGroups[newGroup] = altGroups[oldGroup]
		
		-- delete the old reference
		altGroups[oldGroup] = nil
		
		-- return true to confirm that the group was found and renamed
		return true
	end	
end

function namespace:Exists(group)
	return (altGroups[group] ~= nil)
end

function namespace:Iterate(callback)
	local sortedGroups = addon:HashToSortedArray(altGroups)

	for _, groupName in pairs(sortedGroups) do
		callback(groupName, altGroups[groupName])
	end
end

function namespace:AddCharacter(group, character)
	-- Get the internal characterID
	local characterID = addon:GetCharacterID(character)
	if not characterID then
		addon:Print(format("Internal ID not found for %s, login with this character first", character))
		return
	end
	
	-- Add the id to this group
	altGroups[group] = altGroups[group] or {}
	addon:ArrayInsertUnique(altGroups[group], characterID)
end

function namespace:RemoveCharacter(group, character)
	-- Get the internal characterID
	local characterID = addon:GetCharacterID(character)
	
	if characterID and altGroups[group] then
		addon:ArrayRemoveValue(altGroups[group], characterID)
	end
end

function namespace:Contains(group, character)
	local characterID = addon:GetCharacterID(character)
	
	if characterID and altGroups[group] then
		return addon:ArrayContainsValue(altGroups[group], characterID)
	end
end

function namespace:Get(character)
	-- Get the internal characterID
	local characterID = addon:GetCharacterID(character) or 0
	local groups = {}
	
	for groupName, group in pairs(altGroups) do
		-- if addon:ArrayContainsValue(altGroups[groupName], characterID) then
		if addon:ArrayContainsValue(group, characterID) then
			TableInsert(groups, groupName)
		end
	end
	
	-- return the list of groups as a concatenated string, but also as a table
	return TableConcat(groups, ", "), groups
end

function namespace:IsGrouped(character)
	local characterID = addon:GetCharacterID(character) or 0
	
	for _, group in pairs(altGroups) do
		if addon:ArrayContainsValue(group, characterID) then
			return true
		end
	end
end

AddonFactory:OnPlayerLogin(function()
	altGroups = DataStore_AltGroups
end)
