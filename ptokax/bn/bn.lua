--// bn.lua
--// bn.lua: Szabolcs Molnar 2006-2007; fleet@elitemail.hu
--// bn.lua: Rev 003/20060929
--// Rewritten for PtokaX by Thor
--// 2010.11.15.

--[[

  CHANGELOG:

  004/20070711: On kicking, the script displays the original form of the word even when it's a regex match
  
]]

dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
local settingsfile = Core.GetPtokaXPath().."scripts/bn.settings.txt"
local tPoints = {}
local iMax = 5

function OnStartup()
	if loadfile(settingsfile) then dofile(settingsfile) else bn = {} end
end

local function isWordAdded(word)
	for k in ipairs(bn) do
		if bn[k].original == word then
			return k
		end
	end
	return false
end

local function saveSettings(tTable, sTableName, hFile, sTab)
	sTab = sTab or "";
	hFile:write(sTab..sTableName.." = {\n" )
	for key, value in pairs(tTable) do
		local sKey = (type(key) == "string") and string.format("[%q]",key) or string.format("[%d]",key)
		if(type(value) == "table") then
			saveSettings(value, sKey, hFile, sTab.."\t")
		else
			local sValue = (type(value) == "string") and string.format("%q",value) or tostring(value)
			hFile:write( sTab.."\t"..sKey.." = "..sValue)
		end
		hFile:write( ",\n")
	end
	hFile:write( sTab.."}")
end

local function bnf(params)
	if not params[1] then
		return "Missing parameters. See !bn help"
	elseif params[1] == "help" then
		local ret = [==[
		
---------------------------------------------------------------------------------------------------------------------------------------------------------
Bn.lua                                                                                      v1.0
---------------------------------------------------------------------------------------------------------------------------------------------------------
!bn add <original expression> <replacement> [regex/plain]
!bn rm <expression>
!bn list
!bn help
---------------------------------------------------------------------------------------------------------------------------------------------------------]==]
		return ret
	elseif params[1] == "add" then
		if not params[3] then
			return "Too less parameters provided. Usage: !bn add <original expression> <replacement> [plain/regex]"
		else
			if isWordAdded(params[2]) then
				return "This word is already added. See !bn list or !bn help"
			end
			local temp = {}
			temp.original = params[2]
			temp.replaced = params[3]
			if params[4] then
				if params[4] == "regex" or params[4] == "r" then
					temp.plaintext = false
				elseif params[4] == "plain" or params[4] == "p" then
					temp.plaintext = true
				else
					return "Unknown parameter (" .. params[4] .. "). Valid choices are: plain, regex"
				end
			else
				temp.plaintext = false
			end
			table.insert(bn, temp)
			local f = io.open(settingsfile,"w+")
			if f then
				saveSettings(bn,"bn",f)
			end
			return ("OK [\"" .. params[2] .. "\" -> \"" .. params[3] .. "\"]" )
		end
	elseif params[1] == "rm" then
		if not params[2] then
			return "Missing parameters. Usage: !bn rm <expression>. See !bn help"
		else
			local pos = isWordAdded(params[2])
			if pos then
				table.remove(bn, pos)
				local f = io.open(settingsfile,"w+")
				if f then
					saveSettings(bn,"bn",f)
				end
				return "OK"
			else
				return "Expression is not added, thus it cannot be removed. See !bn list or !bn help"
			end
		end
	elseif params[1] == "list" then
		local ret = {"\r\n"}
		table.insert(ret,"-------------------------------------------------------------------------------------------\r\n")
		table.insert(ret," Original expression -> Modified expression [plain/regex]\r\n")
		table.insert(ret,"-------------------------------------------------------------------------------------------\r\n")
		for k in ipairs(bn) do
			table.insert(ret,k..". "..bn[k].original.." -> "..bn[k].replaced.." ["..(bn[k].plaintext and "Plain" or "Regex").."]\r\n")
		end
		table.insert(ret,"-------------------------------------------------------------------------------------------\r\n")
		table.insert(ret," Total: "..#bn.." items displayed\r\n")
		table.insert(ret,"-------------------------------------------------------------------------------------------\r\n")
		return table.concat(ret)
	end
	return "Unknown parameters. See !bn help"
end

function ChatArrival(user,data)
	if user.iProfile ~= -1 then
		if user.iProfile == 0 and data:find("^%b<>%s[!%+]bn ") then
			local t = {}
			data:sub(#user.sNick+8,-2):gsub("(%S+)",function(m) table.insert(t,m) end)
			local msg = bnf(t)
			if msg then Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..msg) end
			return true
		end
		return false
	end
	local original = data:sub(#user.sNick+4,-2)
	local modtext = " "..original.." "
	local text = " "..original:lower() .. " "
	local sn = user.sNick:match("^[%[%(].-[%]%)](.+)$") or user.sNick
	local reason = sn..", figyelj a helyesírásodra! A következõ szavakat így írjuk helyesen: "
	local hit,points = false,0
	for k in ipairs(bn) do
		local found = false --// Found, and the occurency start
		local occend = false --// Occurency end
		if bn[k].plaintext then
			found, occend = text:find(" "..bn[k].original:lower().." ",1,1)
			modtext = modtext:gsub(" "..bn[k].original:lower().." "," "..bn[k].replaced.." ")
			if found then 
				reason = reason..text:sub(found+1,occend-1).." helyes alakja: "..bn[k].replaced..", "
				points = points + 1
			end
		else
			-- found = string.find( text, "[%W]" .. bnsettings.words[k].original .. "[%W]")
			found, occend = text:find("[^a-záéíóöõüûÁÉÍÓÖÕÜÛ]"..bn[k].original.."[^a-záéíóöõüûÁÉÍÓÖÕÜÛ]")
			modtext = modtext:gsub(" "..bn[k].original.." "," "..bn[k].replaced.." ")
			if found then
				reason = reason..text:sub(found+1,occend-1).." helyes alakja: "..bn[k].replaced..", "
				points = points + 1
			end
		end
		if found then hit = true end
	end
	if hit then
		if not tPoints[user.sNick] then tPoints[user.sNick] = 0 end
		tPoints[user.sNick] = tPoints[user.sNick] + points
		if tPoints[user.sNick] < iMax then
			Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..reason:sub(1,-3)..". Ezt az üzenetet csak te kaptad meg, az eredeti üzeneted automatikusan javítva lett. "..
			"Viszont kaptál érte "..points.." büntetõpontot, most "..tPoints[user.sNick].." pontod van. Ha "..iMax.." pont összegyûlik, ki leszel rúgva a hubról.")
			Core.SendToAll("<"..user.sNick.."> "..modtext.."|")
		else
			tPoints[user.sNick] = nil
			Core.Kick(user,SetMan.GetString(21),"Szóltam :)")
			Core.SendToAll("<"..user.sNick.."> "..modtext.."|")
			Core.SendToAll("<"..SetMan.GetString(21).."> is kicking "..user.sNick.." because: Ügyelj a helyesírásodra :)")
		end
		return true
	else
		return false
	end
end

function OnExit()
	UnregCommand({"bn"})
end
--//
RegCommand("bn", "0", "BeszelniNehez.. !bn help")
