local addonName, addon = ...

local TableInsert, TableRemove, TableSort, pairs, ipairs = table.insert, table.remove, table.sort, pairs, ipairs

-- *** Table management ***
function addon:GetHashSize(hash)
	local count = 0
	
	for _, _ in pairs(hash) do
		count = count + 1
	end
	
	return count
end

function addon:HashToSortedArray(hash)
	local array = {}
	
	for k, _ in pairs(hash) do
		TableInsert(array, k)			-- simply insert every entry into an array ..
	end
	TableSort(array)						-- .. then sort it
	
	return array
end

function addon:HashValueToSortedArray(hash)
	local array = {}
	
	for _, v in pairs(hash) do
		TableInsert(array, v)			-- simply insert every entry into an array ..
	end
	TableSort(array)						-- .. then sort it
	
	return array
end

function addon:SortedArrayClone(array)
	-- Clone an array and sort it, useful to be sure the original array is unmodified
	local clone = {}
	
	for _, v in pairs(array) do
		TableInsert(clone, v)
	end
	TableSort(clone)
	
	return clone
end

function addon:CopyTable(source, destination)
	for k, v in pairs(source) do
	
		if type(v) == "table" then
			destination[k] = {}
			CopyTable(v, destination[k])
		else
			destination[k] = v
		end
	end
end

function addon:ArrayInsertUnique(array, value)
	-- Check if the element already exists in the array
	for _, v in ipairs(array) do
		-- Element already exists, do nothing
		if v == value then return end
	end

	-- Element doesn't exist, add it to the end of the array
	TableInsert(array, value)
end

function addon:ArrayRemoveValue(array, value)
	for i = #array, 1, -1 do
		if array[i] == value then
			TableRemove(array, i)
			return
		end
	end
end

function addon:ArrayContainsValue(array, value)
	for i = 1, #array do
		if array[i] == value then
			return true
		end
	end
end

function addon:AddOrGetAutoID(hash, value)
	-- is the value already known ?
	if not hash[value] then
		hash.LastID = hash.LastID or 0	-- Initialize the autoID if necessary
		hash.LastID = hash.LastID + 1		-- Increment it
		
		hash[value] = hash.LastID			-- Assign the new autoID
	end
	
	return hash[value]
end


-- ** Set & List **
function addon:CreateSetAndList(container)
	container.Set = container.Set or {}
	container.List = container.List or {}
	container.Count = container.Count or 0
	
	return container
end

function addon:StoreToSetAndList(container, value)
	local set = container.Set

	-- if this value is not yet referenced ..
	if not set[value] then
		local list = container.List
		
		TableInsert(list, value)		-- ex: [1] = "Shadowlands"
		set[value] = #list				-- ["Shadowlands"] = 1
		
		-- keep track of the item count separately, the table size will not do when we remove entries
		container.Count = container.Count + 1
	end
	
	return set[value]			-- return this list's index
end

function addon:RemoveFromSetAndList(container, value)
	local set = container.Set

	-- find the index from the Set
	local index = set[value]
	if index then
		TableRemove(container.List, index)	-- Delete the entry from the list
		set[value] = nil							-- .. and also from the set
		
		container.Count = container.Count - 1
	end
end
