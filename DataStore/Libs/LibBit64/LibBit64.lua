--[[	*** LibBit64 ***
Written by : Thaoky, EU-Marécages de Zangar
December 29th, 2023

License: Public Domain

This library contains functions that allow for bit manipulations on any Lua number, which internally is stored as a 64-bit value.
It is possible to address all bits from 0 to 63.

Standard functions provided by Blizzard are limited to bits 0..31.

--]]

local LIB_VERSION_MAJOR, LIB_VERSION_MINOR = "LibBit64", 1
local lib = LibStub:NewLibrary(LIB_VERSION_MAJOR, LIB_VERSION_MINOR)

if not lib then return end -- No upgrade needed

local math = math
local bAnd = bit.band

--	*** API ***

function lib:LeftShift(value, numBits)
	return value * (2 ^ numBits)
end

function lib:RightShift(value, numBits)
	return math.floor(value / 2 ^ numBits)
end

function lib:TestBit(value, pos)
	-- Tested ok up to bit 63
	-- Reminder: bit 63 = sign, so number will be negative
	local mask = 2 ^ pos
	return value % (mask + mask) >= mask
	
	-- This one works too up to bit 63, but the first version is faster
	-- return (RightShift(value, pos) % 2) == 1
end

function lib:SetBit(value, pos)
	local mask = 2 ^ pos
	
	-- inline the test bit, to save a call
	if value % (mask + mask) >= mask then	-- if the bit is already set ..
		return value								-- .. do nothing
	else
      -- .. otherwise add a LeftShift'ed 1, also inlined
      -- return value + (1 * (2 ^ pos))		
		-- .. which simplifies to :
      return value + mask
	end

	-- This only works for bits 0 .. 31, but fails from 32 on
	--return bOr(value, 2^pos)
end

function lib:ClearBit(value, pos)
	local mask = 2 ^ pos
	
	-- inline the test bit, to save a call
	if value % (mask + mask) >= mask then	-- if the bit is already set ..
      -- return value - (1 * (2 ^ pos))		-- .. subtract a LeftShift'ed 1, also inlined
      -- .. which simplifies to :
		return value - mask
	else
		return value								-- .. otherwise do nothing
	end
end

function lib:ToggleBit(value, pos)
	local mask = 2 ^ pos
	
	-- inline the test bit, to save a call
	if value % (mask + mask) >= mask then	-- if the bit is already set ..
      -- return value - (1 * (2 ^ pos))		-- .. subtract a LeftShift'ed 1, also inlined
      -- .. which simplifies to :
		return value - mask
	else
		return value + mask							-- .. otherwise set it
	end
end

function lib:GetBits(value, low, numBits)
	-- low = lowest bit
	-- numBits = number of bits starting from lowest
	-- Ex: local x = GetBits(15, 4) => returns the value of bits 15 to 18 (so 4 bits)

	local mask = (2 ^ numBits) - 1		-- ex: 2^4 = 16 - 1 = 15
	
	return bAnd(lib:RightShift(value, low), mask)
end
