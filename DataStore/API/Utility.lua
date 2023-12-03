local addonName, addon = ...

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
		table.insert(array, k)			-- simply insert every entry into an array ..
	end
	table.sort(array)						-- .. then sort it
	
	return array
end

function addon:HashValueToSortedArray(hash)
	local array = {}
	
	for _, v in pairs(hash) do
		table.insert(array, v)			-- simply insert every entry into an array ..
	end
	table.sort(array)						-- .. then sort it
	
	return array
end

function addon:SortedArrayClone(array)
	-- Clone an array and sort it, useful to be sure the original array is unmodified
	local clone = {}
	
	for _, v in pairs(array) do
		table.insert(clone, v)
	end
	table.sort(clone)
	
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


-- *** Bit manipulation ***
local bAnd = bit.band

function addon.LeftShift(value, numBits)
	return value * (2 ^ numBits)
end

function addon.RightShift(value, numBits)
	-- for bits beyond bit 31
	return math.floor(value / 2 ^ numBits)
end

function addon.TestBit(value, pos)
   local mask = 2 ^ pos
   
	if bAnd(value, mask) == mask then
      return true
   end
end