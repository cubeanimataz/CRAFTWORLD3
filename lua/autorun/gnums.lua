--[[
gNums
by cube#5947
Addon Type: Function Library
Description: Provides a simplistic assortment of functions for handling absurdly large numbers that are way past 2^1024 (the limit of a raw number).
These BigNumbers should never contain negative values of any kind!
Version: 0.1

Notes:
The purpose of a BigNumber library is to allow programmers to work with numbers that are otherwise past the limit of a raw number.
Incremental games (like Time Warpers) are known to use these kinds of libraries to store numbers that would otherwise exceed the maximum number limit.

A BigNumber in Garry's Mod can simply be represented as a table with two numerical values.
While the numbers themselves have a limit, we can use simple methods to make the table represent a different kind of number: a BigNumber!
A BigNumber in gNums is composed of any non-negative number for the first value (the Value), and a non-negative, non-decimal number (the Power) for the second value.

Normal math won't know how to interpret this of course.
]]

--bignumnew
--Creates a new BigNumber.
function bignumnew(number, power)
	if !isnumber(power) then power = 0 end
	local num1 = bignumconvert(number)
	return {num1[1], num1[2] + power}
end

--bignumcopy
--Returns a duplicate BigNumber.
--This is required to make UNIQUE BigNumbers for seperate variables - for example, using "<var1> = <var2>" doesn't work, because it means they use the same table in memory!
--This function will create a NEW table in memory.
function bignumcopy(bnum)
	return {bnum[1], bnum[2]}
end

--bignumelevate
--Returns the difference between the powers-of-10 of BigNumber 1 and BigNumber 2.
--Called internally by some bignum functions.
function bignumelevate(bnum1, bnum2)
	return bnum1[2] - bnum2[2]
end

--bignumconvert
--Creates a BigNumber by using a raw number. Limited to 1e308.
function bignumconvert(number)
	if !isnumber(number) then error("can only convert raw numbers into BigNumber tables") end
	number = math.min(number,1e308)
	local power = 0
	local length = math.max(string.len(string.Replace(string.Comma(math.floor(number)), ",", "")) - 3, 0)
	if length > 3 then
		power = math.floor(length/3)
	end
	if power > 0 then
		number = number/(1000^power)
	end
	return {number, power}
end

--bignumwrite
--Takes a BigNumber and writes it as a readable string. For example {326.4, 2} (which equals 326.4 x 100) will be written as 32.64K.
--Very big numbers like 1 quintillion will be written as "1a". Players can question what -illion is bigger than another, so the alphabet makes for a good substitute!
--If the number exceeds 1000z#, it will loop back to the letter "a" and kick # up by 1, producing "a#+1", for example "a2".
function bignumwrite(bnum)
	local power = bnum[2]
	local term_basic =  {"K","M","B","T","Q"}
	local term = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
	if power == 0 then
		return tostring(math.Round(bnum[1],2))
	elseif power <= 5 then
		return tostring(math.Round(bnum[1],2)) .. term_basic[power]
	else
		local a = power - 5
		local b = 0
		if a > #term then
			b = math.floor(a / 26)
		end
		a = math.max(1,a - (26*b))
		local c = tostring(math.Round(bnum[1],2)) .. term[a]
		if b > 0 then
			c = c .. tostring(b)
		end
		return c
	end
end

--bignumread
--Takes a BigNumber string and converts it into a BigNumber table.
--Very useful if you want to jump to high numbers as easy as you do reading them!
--Be careful, this function has very little to no error-proofing, making it vulnerable to non-BigNumber strings!
function bignumread(bnum)
	if tonumber(bnum) then
		if tonumber(bnum) < 1000 then
			return {tonumber(bnum), 0}
		end
	end
	local chars = {}
	for a = 1, string.len(bnum) do
		table.insert(chars, string.sub(bnum,a,a))	
	end
	local num = 0
	local letterplace = 0
	for b = 1, #chars do
		if chars[b] != "0" && chars[b] != "1" && chars[b] != "2" && chars[b] != "3" && chars[b] != "4" && chars[b] != "5" && chars[b] != "6" && chars[b] != "7" && chars[b] != "8" && chars[b] != "9" && chars[b] != "." then
			letterplace = b
			num = tonumber(string.sub(bnum, 1, b-1))
		end
	end
	local power = string.sub(bnum, letterplace, string.len(bnum))
	local power2 = 0
	if string.len(power) > 1 then
		power2 = tonumber(string.sub(power, 2, string.len(power)))
		power = string.sub(power, 1, 1)
	end
	if string.upper(power) == power then
		local basicpowers = {"K","M","B","T","Q"}
		for i = 1, #basicpowers do
			if power == basicpowers[i] then
				power = i
			end
		end
		return {num, power}
	else
		local powers = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
		for i = 1, #powers do
			if power == powers[i] then
				power = i + 5
			end
		end
		power = power + (26*power2)
		return {num, power}
	end
end

--bignumcalc
--Internally called by some other bignum functions.
--Normalises a BigNumber.
--You should call this function if you rawly create or modify a BigNumber table to have a first entry value of 1000+ or a decimal number below 1.
function bignumcalc(bnum)
	if bnum[1] >= 1000 then
		local additive = math.floor(string.len(string.Replace(string.Comma(math.floor(bnum[1])), ",", ""))/3)
		bnum[2] = bnum[2]+additive
		bnum[1] = bnum[1]/(1000^additive)
	end
	if bnum[1] < 1 && bnum[2] > 0 then
		if bnum[1] == 0 then
			bnum[1] = 100
		else
			bnum[1] = bnum[1]*1000
		end
		bnum[2] = bnum[2]-1
	end
	if bnum[2] < 0 then
		bnum[2] = 0
		bnum[1] = 1
	end
	return bnum
end

--bignumzero
--Checks if a BigNumber equates to zero (or less if it somehow is negative, in which case it shouldn't be).
function bignumzero(bnum)
	if bnum[1] <= 0 && bnum[2] <= 0 then return true else return false end
end

--bignumcompare
--Compares two BigNumbers and returns a value based on the comparison result.
--Returns 0 if both numbers are equal.
--Returns 1 if the first argument is larger than the second argument.
--Returns 2 if the second argument is larger than the first argument.
function bignumcompare(bnum1, bnum2)
	local elevate = bignumelevate(bnum1, bnum2)
	if elevate > 0 then
		return 1
	elseif elevate < 0 then
		return 2
	else
		if bnum1[1] > bnum2[1] then
			return 1
		elseif bnum1[1] < bnum2[1] then
			return 2
		else
			return 0
		end
	end
end

--bignumround
--Rounds a BigNumber to the closest unit of the current power.
--Supports an optional second argument. Supply with the string "ceil" to round it up, or "floor" to round it down. If no string is supplied, it will perform normal rounding.
function bignumround(bnum, roundingmethod)
	if !roundingmethod or !isstring(roundingmethod) then roundingmethod = "round" end
	if roundingmethod != "ceil" && roundingmethod != "floor" then roundingmethod = "round" end
	if roundingmethod == "ceil" then
		bnum[1] = math.ceil(bnum[1])
	elseif roundingmethod == "floor" then
		bnum[1] = math.floor(bnum[1])
	else
		bnum[1] = math.Round(bnum[1])
	end
	return bnum
end

--bignumadd
--Adds the second BigNumber to the first BigNumber.
function bignumadd(bnum1, bnum2)
	local elevation = bignumelevate(bnum1, bnum2)
	local num = bnum2[1]
	if elevation < 0 then
		num = num/(1000^elevation)
	else
		num = num*(1000^-elevation)
	end
	bnum1[1] = bnum1[1] + num
	return bignumcalc(bnum1)
end

--bignumsub
--Subtracts the second BigNumber from the first BigNumber.
--This cannot produce negative values, so even if BigNumber two is bigger than BigNumber one, you will still get {0, 0}!
function bignumsub(bnum1, bnum2)
	local elevation = bignumelevate(bnum1, bnum2)
	if elevation < 0 then
		bnum1[1] = 0
		bnum1[2] = 0
		return bignumcalc(bnum1)
	elseif elevation == 0 then
		if bnum2[1] >= bnum1[1] then
			bnum1[1] = 0
			bnum1[2] = 0
			return bignumcalc(bnum1)
		else
			bnum1[1] = bnum1[1] - bnum2[1]
			return bignumcalc(bnum1)
		end
	elseif elevation < 4 then
		bnum1[1] = bnum1[1] - (bnum2[1]/(1000^elevation))
		return bignumcalc(bnum1)
	end
end

--bignummult
--Multiplies a BigNumber by either another BigNumber or even a raw number.
function bignummult(bnum1, bnum2)
	if isnumber(bnum2) then
		if bnum2 <= 0 then
			bnum1[1] = 0
			bnum1[2] = 0
		else
			bnum1[1] = bnum1[1] * bnum2
		end
	elseif bignumzero(bnum2) then
		bnum1[1] = 0
		bnum1[2] = 0
	else
		bnum1[1] = bnum1[1] * bnum2[1]
		bnum1[2] = bnum1[2] + bnum2[2]
	end
	return bignumcalc(bnum1)
end

--bignumdiv
--Divides a BigNumber by either another BigNumber or even a raw number.
function bignumdiv(bnum1, bnum2)
	if isnumber(bnum2) then
		bnum1[1] = bnum1[1] / bnum2
		return bignumcalc(bnum1)
	else
		bnum1[1] = bnum1[1] / bnum2[1]
		bnum1[2] = bnum1[2] - bnum2[2]
		return bignumcalc(bnum1)
	end
end

--bignumpow
--Raises a BigNumber to the power of either another BigNumber or a raw number.
--Warning - this can output crazily large BigNumbers which can result in loss of precision!
--Make sure that none of the numbers within BigNumbers exceed or get near really huge raw values.
--Raw values for the second argument might be a bit wonky, it's better to use a BigNumber for the second argument.
function bignumpow(bnum1, bnum2)
	if isnumber(bnum2) then
		bnum1[1] = math.min(bnum1[1] ^ bnum2, 1e308)
		return bignumcalc(bnum1)
	else
		bnum1[1] =  math.min(bnum1[1] ^ bnum2[1], 1e308)
		bnum1[2] = bnum1[2] * bnum2[2]
		return bignumcalc(bnum1)
	end
end

--bignumclamp
--Restricts a BigNumber's power to be within the range of argument 2 and argument 3.
--If only supplied with one argument, it will stop the BigNumber's power from going past argument 2.
function bignumclamp(bnum, limit, limit2)
	if limit2 then
		if bnum[2] > limit2 then
			bnum[1] = 999.99
			bnum[2] = limit2
		end
		if bnum[2] < limit then
			bnum[1] = 1
			bnum[2] = limit
		end
	else
		if bnum[2] > limit then
			bnum[1] = 999.99
			bnum[2] = limit
		end
	end
end

--bignumvalid
--Checks if a table can be used as a BigNumber.
function bignumvalid(bnum)
	local isvalid = false
	if !istable(bnum) then return false end
	if #bnum == 2 then
		if isnumber(bnum[1]) && isnumber(bnum[2]) then isvalid = true end
	end
	return isvalid
end