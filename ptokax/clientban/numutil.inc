--// Returns with a . or ,

NumUtil = {}

NumUtil.getComma = function(this)
	local temp = 11e-1
	temp = tostring(temp)
	temp = string.sub(temp, 2, 2)
	return temp
end

NumUtil.comma = NumUtil:getComma()

--// Returns nil if conversation failed
NumUtil.toNumber = function(this, text)
	if text == nil then
		return nil
	end
	local temp = ""
	local badchar = ","
	if NumUtil.comma == "," then
		badchar = "."
	end
	local pat = "(%" .. badchar .. ")"
	temp = string.gsub(text, pat, NumUtil.comma)
	local pat2 = "([%-]?[%d]*[%" .. NumUtil.comma .. "]?[%d]*)(.*)"
	temp = string.gsub(temp, pat2, "%1")
	--// temp is going to be nil if the number cannot be converted
	temp = tonumber(temp)

	return temp
end

NumUtil.toString = function(this, num)
	return string.gsub(tostring(num), ",", ".")
end