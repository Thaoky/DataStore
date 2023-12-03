local addonName, addon = ...

local function GetAltGroups()
	return addon.db.global.AltGroups
end

function addon:CreateAltGroup(group)
	local altGroups = GetAltGroups()

	if not altGroups[group] then
		altGroups[group] = {}
		
		-- return true to confirm that the group was not already found and was created
		return true
	end
end

function addon:DeleteAltGroup(group)
	local altGroups = GetAltGroups()

	if altGroups[group] then
		altGroups[group] = nil
		
		-- return true to confirm that the group was found and deleted
		return true
	end
end

function addon:RenameAltGroup(oldGroup, newGroup)
	local altGroups = GetAltGroups()
	
	if altGroups[oldGroup] then
		-- make the new group point to the same table as the old
		altGroups[newGroup] = altGroups[oldGroup]
		
		-- delete the old reference
		altGroups[oldGroup] = nil
		
		-- return true to confirm that the group was found and renamed
		return true
	end	
end

function addon:IsAltGroupExisting(group)
	local altGroups = GetAltGroups()
	
	return (altGroups[group] ~= nil)
end

function addon:IterateAltGroups(callback)
	local altGroups = GetAltGroups()
	local sortedGroups = addon:HashToSortedArray(altGroups)

	for _, groupName in pairs(sortedGroups) do
		callback(groupName, altGroups[groupName])
	end
end

function addon:AddToAltGroup(group, character)
	local altGroups = GetAltGroups()
	
	altGroups[group] = altGroups[group] or {}
	altGroups[group][character] = true
end

function addon:RemoveFromAltGroup(group, character)
	local altGroups = GetAltGroups()
	
	if altGroups[group] then
		altGroups[group][character] = nil
	end
end

function addon:IsInAltGroup(group, character)
	local altGroups = GetAltGroups()
	
	return (altGroups[group] and altGroups[group][character])
end

function addon:GetAltGroups(character)
	local altGroups = GetAltGroups()
	local groups = {}
	
	for groupName, groupMembers in pairs(altGroups) do
		if groupMembers[character] then
			table.insert(groups, groupName)
		end
	end
	
	return table.concat(groups, ", "), groups
end
