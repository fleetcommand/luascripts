--// forbid.lua
--// forbid.lua: For available commands, see !forbid help
--// forbid.lua: (C) Szabolcs Molnar, 2006-2007; fleet@elitemail.hu
--// forbid.lua: (C) [VH]adAsz, 2006-2007; vhadasz@yahoo.com
--// forbid.lua: You can use and distribute this script for no cost, but you are not allowed to remove this copyright notice
--// forbid.lua: Rev 008/20070108

--[[
	Changelog:
    008/20070108: vad: Added "K" for the triggers which kick the user when reporting to opchat (0.4c)
	007/20061115: fc: Fixed bug in pm filtering. Thanks OpChat for reporting this :P (0.4b)
	006/20061025: vad: Added expression checker (0.4a)
	005/20061024: fc: Fixed an issue with mainchat filtering (thanks VadAsz for noticing me)
	004/20061017: fc: Fixed pm filtering (thanks maksalaatikko for reporting this bug) (0.3a)
	003/20061001: fc: Added hit counter (0.2a)
	002/20061001: fc: If more than one filter applies to the message, all of them is checked, until there is no filters remaining or the user is kicked
	001/20060914: fc: Initial release
]]
dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

local settingsfile = "scripts/forbid.settings.txt"
local class = "0"

local function initializeSettings()
	if not forbidsettings then forbidsettings = {} end
	if not forbidwords then forbidwords = {} end
end

local function loadSettings()
	local o = io.open(settingsfile, "r" )
	if o then
		o:close()
		dofile( settingsfile )
	end
	initializeSettings()
	return true
end

Serialize = function(tTable, sTableName, hFile, sTab)
	sTab = sTab or "";
	hFile:write(sTab..sTableName.." = {\n" )
	for key, value in pairs(tTable) do
		local sKey = (type(key) == "string") and string.format("[%q]",key) or string.format("[%d]",key)
		if(type(value) == "table") then
			Serialize(value, sKey, hFile, sTab.."\t")
		else
			local sValue = (type(value) == "string") and string.format("%q",value) or tostring(value)
			hFile:write( sTab.."\t"..sKey.." = "..sValue)
		end
		hFile:write( ",\n")
	end
	hFile:write( sTab.."}")
end

local function saveSettings()
	local f = io.open(settingsfile,"w+")
	if f then
		Serialize(forbidwords,"forbidwords",f)
		f:close()
	end
	return true
end

local function updateConfig()
	-- Adding hit counter
	-- and fixing pm/mc filtering issues
	for k in pairs(forbidwords) do
		if not forbidwords[k].hits then forbidwords[k].hits = 0 end
		if not forbidwords[k].added then forbidwords[k].added = os.time() end
		if forbidwords[k].pm then
			if forbidwords[k].pm == 0 then
				forbidwords[k].pm = false
			end
		end
		if forbidwords[k].mc then
			if forbidwords[k].mc == 0 then
				forbidwords[k].mc = false
			end
		end
	end
end

local function decide(value, ret1, ret2, invert)
	if not ret1 then ret1 = "Yes" end
	if not ret2 then ret2 = "No" end
	if invert then ret2, ret1 = ret1, ret2 end

	if value then
		if value == true or value == 1 then
			return ret1
		end
	end
	return ret2
end

local function kick(user, reason)
	local nTime,bot = SetMan.GetNumber(16),SetMan.GetString(21)
	if reason:lower():match("_BAN_%d+[smhdwy]" ) then
		local tBanTimes = { ["s"] = 0.1,["m"] = 1, ["h"] = 60, ["d"] = 1440, ["w"] = 10080,["y"] = 525600 }
		local sBantime = reason:lower():gsub(".*_ban_(%d+[smhdwy]).*","%1")
		nTime = (tBanTimes[sBantime:sub(-1,-1)] * tonumber(sBantime:sub(1,-2)))
	end
	Core.SendToAll("<"..bot.."> is kicking " .. user.sNick .. " because: " .. reason)
	BanMan.TempBan(user,nTime,reason,bot,false)
end

local function getHelp()
	return [==[

---------------------------------------------------------------------------------------------------------------------------------------------------------
Forbid.lua                                                                                      0.5
---------------------------------------------------------------------------------------------------------------------------------------------------------
!forbid add <expression> [regex/plain] [main/pm/both] [filter regged users (1/0)] [kick [reason]]
!forbid mod <expression> [regex/plain] [main/pm/both] [filter regged users (1/0)] [kick [reason]]
!forbid rm <expression>
!forbid list [filter] [plaintext (1/0)]
!forbid listbyhits
!forbid chk <expression>
!forbid help
---------------------------------------------------------------------------------------------------------------------------------------------------------]==]
end

local function isForbid(expression)
	for k in pairs(forbidwords) do
		if forbidwords[k].expression == expression then
			return true
		end
	end
	return false
end

local function rmForbid(expression)
	local ret = "Expression not found. See !forbid list or !forbid help"
	for k in pairs(forbidwords) do
		if forbidwords[k].expression == expression then
			table.remove( forbidwords, k )
			ret = expression.." removed"
			saveSettings()
			break
		end
	end
	return ret
end

local function chkForbid(expression)
	local ret = {"\r\n"}
	local counter = 0

	table.insert(ret,string.rep("-",178).."\r\n")
	table.insert(ret," Expression [T: Type] [M/P: Main/Pm] [R: Filter regusers] [K: kick] [H: hits]\r\n")
	table.insert(ret," Filtering : \"" .. expression .. "\"\r\n")
	table.insert(ret,string.rep("-",178).."\r\n")
	for k in pairs(forbidwords) do
		if expression:lower():find(forbidwords[k].expression, 1, forbidwords[k].plain ) then
			counter = counter + 1
			table.insert(ret,tostring(counter)..". \""..forbidwords[k].expression.."\" [T: "..decide(forbidwords[k].plain,"Plain","Regex").."] [M/P: "..
			decide(forbidwords[k].mc).."/"..decide(forbidwords[k].pm) .."] [R: "..tostring(forbidwords[k].regged) .. "] [K: "..decide(forbidwords[k].kick).."]")
			if forbidwords[k].kick then
				table.insert(ret," (" .. forbidwords[k].kickreason .. ")")
			end
			table.insert(ret," [H: " .. tostring(forbidwords[k].hits) .. "]\r\n")
		end
	end
	table.insert(ret,string.rep("-",178).."\r\n")
	table.insert(ret,"Total: " .. tostring(counter) .. " triggers activated\r\n")
	table.insert(ret,string.rep("-",178).."\r\n")
	return table.concat(ret)
end

function addForbid(params, onlymodify)
	local temp = {}
	temp.expression = ""
	temp.plain = false
	temp.pm = false
	temp.mc = true
	temp.regged = 0
	temp.kick = false
	temp.kickreason = ""
	temp.hits = 0
	temp.added = os.time()
	temp.expression = params[2]
	
	if params[3] then
		if params[3] == "plain" or params[3] == "p" then
			temp.plain = true
		elseif params[3] ~= "regex" and params[3] ~= "r" then
			return "Wrong parameter (" .. params[3] .."). Valid choices are: regex, plain"
		end
	end
	if params[4] then
		if params[4] == "pm" or params[4] == "p" then
			temp.pm = true
			temp.mc = false
		elseif params[4] == "both" or params[4] == "b" then
			temp.pm = true
		elseif params[4] ~= "main" and params[4] ~= "m" then
			return "Unknown parameter (" .. params[4] .. "). Valid choices are: main, pm, both"
		end
	end
	if params[5] then
		if params[5] == "1" then
			temp.regged = 1
		elseif params[5] ~= "0" then
			return "Unknown parameter (" .. params[5] .. "). Valid choices are: 1, 0"
		end
	end
	if params[6] then
		if params[6] == "kick" then
			temp.kick = 1
		else
			return "Unknown parameter (" .. params[6] .."). Valid choice: kick"
		end
	end
	if params[7] then
		temp.kickreason = params[7]
	end
	
	if onlymodify then
		if isForbid(temp.expression) then
			rmForbid(temp.expression)
		else
			return "This expression is not added, thus cannot be modified. See !forbid list"
		end
	else
		if isForbid(temp.expression) then
			return "This expression is already added. Remove or modify it. See !forbid help"
		end
	end
	
	table.insert(forbidwords, temp )
	saveSettings()
	return "OK [" .. temp.expression .. "]"
end

function forbid(params )
	if not params[1] then
		return "Missing or unknown parameters. See !forbid help"
	elseif params[1] == "help" then
		return getHelp()
	elseif params[1] == "chk" then
		if params[2] then
			local k = 2
			local first = true
			local allparams = ""
			while params[k] do
				if first then first = false

				else allparams = allparams .. " "
				end
				if string.find(params[k], " ") then
					allparams = allparams .. "\"" .. params[k] .. "\""
				else
					allparams = allparams .. "" .. params[k]
				end
				k = k + 1
			end
			return chkForbid(allparams)
		else
			return "Usage: !forbid chk <expression>"
		end
    elseif params[1] == "add" then
		if params[2] then
			return addForbid(params)
		else
			return "Usage: !forbid add <expression> [regex/plain] [main/pm/both] [filter regged users (1/0)] [kick [reason]]"
		end
	elseif params[1] == "rm" then
		if params[2] then
			return rmForbid(params[2])
		else
			return "Usage: !forbid rm <expression>"
		end
	elseif params[1] == "mod" then
		if params[2] then
			return addForbid(params, true)
		else
			return "Usage: !forbid mod <expression> [regex/plain] [main/pm/both] [filter regged users (1/0)] [kick [reason]]"
		end
	elseif params[1] == "list" then
		if params[2] and params[2]:find("^%d+") and tonumber(params[2]:match("^(%d+)$")) < #forbidwords then
			local num = tonumber(params[2]:match("^(%d+)$"))
			if forbidwords[num] then
				local f = forbidwords[num]
				return string.rep("-",178).."\r\n Expression [T: Type] [M/P: Main/Pm] [R: Filter regusers] [K: kick] [H: hits] [L: Last hit]\r\n"..
				num..". \""..f.expression.."\" [T: "..decide(f.plain,"Plain","Regex").."] [M/P: "..
				decide(f.mc).."/"..decide(f.pm).."] [R: "..tostring(f.regged).."] [K: "..decide(f.kick).."] [H: "..f.hits.."]"..
				"L: "..(f.lasthit and os.date("%y/%m/%d %H:%M:%S",f.lasthit) or "Never").."]\r\n"..string.rep("-",178)
			else
				return "There is no forbid word with ID "..num
			end
		else
			local filter = params[2]
			local plain = params[3]
			local exp = ""
			local plaintext = false
			if filter then
				exp = filter
				if plain then
					if plain == "1" then
						plaintext = true
					elseif plain ~= "0" then
						return "Unkown parameter (" .. plain .. "). Valid choices are: 1, 0. See !forbid help"
					end
				end
			end
			local ret = {"\r\n"}
			table.insert(ret,string.rep("-",178).."\r\n")
			table.insert(ret," Expression [T: Type] [M/P: Main/Pm] [R: Filter regusers] [K: kick] [H: hits] [L: Last hit]\r\n")
			if exp ~= "" then
				table.insert(ret," Filtered for: \"" .. exp .. "\"\r\n")
			end
			table.insert(ret,string.rep("-",178).."\r\n")
			local counter = 0
			for k in ipairs(forbidwords) do
				local f = forbidwords[k]
				if f.expression:find(exp, 1, plaintext) then
					counter = counter + 1
					table.insert(ret,k..". \""..f.expression.."\" [T: "..decide(f.plain,"Plain","Regex").."] [M/P: "..
					decide(f.mc).."/"..decide(f.pm).."] [R: "..tostring(f.regged).."] [K: "..decide(f.kick).."]")
					if f.kick then
						table.insert(ret," (" .. f.kickreason .. ")")
					end
					table.insert(ret," [H: " .. tostring(f.hits) .. "]")
					table.insert(ret," [L: "..(f.lasthit and os.date("%y/%m/%d %H:%M:%S",f.lasthit) or "Never").."]\r\n")
				end
			end
			table.insert(ret,string.rep("-",178).."\r\n")
			table.insert(ret,"Total: " .. tostring(counter) .. " items\r\n")
			table.insert(ret,string.rep("-",178).."\r\n")
			return table.concat(ret)
		end
	elseif params[1] == "listbyhits" then
		local o,ret = {},{"\r\n"..string.rep("-",178).."\r\n Expression [T: Type] [M/P: Main/Pm] "..
		"[R: Filter regusers] [K: kick] [H: hits] [L: Last hit]\r\n"..string.rep("-",178).."\r\n"}
		local SortByKeys = function(t)
			local a,tTemp,i = {},{},0
			for n in pairs(t) do table.insert(a,n) end
			table.sort(a)
			local iter = function ()
				i = i + 1
				return a[i] and a[i], t[a[i]] or nil
			end
			return iter
		end
		for i,v in pairs(forbidwords) do
			if not o[v["hits"]] then
				o[v["hits"]] = {i}
			else
				table.insert(o[v["hits"]],i)
			end
		end
		for hit,ids in SortByKeys(o) do
			table.sort(ids,function(a,b) return a<b end)
			for i,id in ipairs(ids) do
				local f = forbidwords[id]
				table.insert(ret,id..". \""..f.expression.."\" [T: "..decide(f.plain,"Plain","Regex").."] [M/P: "..
				decide(f.mc).."/"..decide(f.pm).."] [R: "..f.regged.."] [K: "..decide(f.kick).."] [H: "..f.hits.."] "..
				"L: "..(f.lasthit and os.date("%y/%m/%d %H:%M:%S",f.lasthit) or "Never").."]\r\n")
			end
		end
		table.insert(ret,string.rep("-",178))
		return table.concat(ret)
	end
	return "Unknown parameters. See !forbid help"
end

--//

function ToArrival(user, fullpm)
	if Core.GetUserValue(user,11) then
		return false
	end
	local target,text = fullpm:match("^%$To: ([^ ]+) From: [^ ]+ %$%b<> (.*)")
	local regged = user.iProfile == -1 and 0 or 1
	local hitwords = ""
	local ret = false
	local iskicked = false
	
	for k in pairs(forbidwords) do
		if iskicked then
			break
		end
		if forbidwords[k].pm then
			if text:lower():find(forbidwords[k].expression, 1, forbidwords[k].plain ) then
				if forbidwords[k].regged >= regged then
					hitwords = hitwords.." "..forbidwords[k].expression
					if forbidwords[k].kick then
						local reason = forbidwords[k].kickreason
						if reason == "" then reason = "Ön most nem nyert centrifugát" end
						kick(user, reason)
						iskicked = true
						hitwords = hitwords .. "K"
						forbidwords[k].hits = forbidwords[k].hits + 1
						ret = true
						break
					end
					forbidwords[k].hits = forbidwords[k].hits + 1
					forbidwords[k].lasthit = os.time()
					ret = true
				end
			end
		end
	end
	if ret then 
		Core.SendToOpChat("["..user.sIP.."] Forbidden message ["..hitwords.." ] in private chat to "..target..": <"..user.sNick.."> "..text)
	end

	-- saving Hit Counter
	if ret then
		saveSettings()
	end
	return ret
end

function ChatArrival(user, fulltext)
	if tostring(user.iProfile):match("^[%"..class.."]") and fulltext:match("^%b<>%s*[%+!]forbid.+$") then
		local t = {}
		fulltext:sub(#user.sNick+11,-2):gsub("(%S+)",function(m) table.insert(t,m) end)
		local msg = forbid(t)
		if msg then Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..msg) end
		return true
	end
	if Core.GetUserValue(user,11) then
		return false
	end

	local text = fulltext:sub(#user.sNick + 4,-2)
	local regged = user.iProfile == -1 and 0 or 1
	local hitwords = ""
	local ret = false
	local iskicked = false
	for k in pairs(forbidwords) do
		if iskicked then
			break
		end
		if forbidwords[k].mc then
			if text:lower():find(forbidwords[k].expression, 1, forbidwords[k].plain ) then
				if forbidwords[k].regged >= regged then
					hitwords = hitwords.." "..forbidwords[k].expression 
					if forbidwords[k].kick then
						local reason = forbidwords[k].kickreason
						if reason == "" then reason = "Ön most nem nyert centrifugát" end
						kick(user, reason)
						iskicked = true
						hitwords = hitwords .. "K"
						forbidwords[k].hits = forbidwords[k].hits + 1
						ret = true
						break
					end
					forbidwords[k].hits = forbidwords[k].hits + 1
					forbidwords[k].lasthit = os.time()
					ret = true
				end
			end
		end
	end
	if ret then 
		Core.SendToOpChat("["..user.sIP.."] Forbidden message ["..hitwords.." ] to main chat: "..fulltext)
		Core.SendToUser(user, fulltext .. "|" )
	end

	-- saving Hit Counter
	if ret then
		saveSettings()
	end
	return ret
end

function OnStartup()
	RegCommand("forbid", class, "Chat/PM filter. See !forbid help")
	loadSettings()
	updateConfig()
end

function OnExit()
	UnregCommand({"forbid"})
end

