--// gagrange.lua for Aquila hubsoftware
--// Thor, 2010; thor@4242.hu
--// Some parts from forbid.lua by FleetCommand
--// Revision 003. Last modified: Jul 19, 2010

--// LOG //--
--[[
    001/20100209: Initial release
    002/20100508: Added IP masking & persistance & fixes
    003/20100719: Fixed masked IP listing & matching & PM filter + message
]]
dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
tGagged = {};
tEx = {};
local class = "0"

local function ToBase(iNum,iBase)
	iNum = tonumber(iNum) or 0
	local tOut,i,j = {},1,1
	local x = iNum
	while x > 0 do x = x - iBase^j; j=j+1; end
	for i=j-1,0,-1 do
		local k = math.modf(iNum/(iBase^i))
		table.insert(tOut,k)
		if k > 0 then iNum = iNum-(iBase^i*k) end
	end
	return string.format("%08d",table.concat(tOut,""))
end

local IP2BIN = function(sIP)
	local ret = ""
	for num in sIP:gmatch("%d+") do
		ret = ret..ToBase(num,2)
	end
	return ret
end

local BIN2IP = function(sNum)
	local sIP = ""
	for i=1,4 do
		sIP = sIP..tonumber(sNum:sub((i-1)*8+1,i*8),2).."."
	end
	return sIP:sub(1,-2)
end

local IsIP = function(sIP)
	local a,b,c,d = sIP:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$");
	if (a and tonumber(a) <= 0xFF and tonumber(b) <= 0xFF and tonumber(c) <= 0xFF and tonumber(d) <= 0xFF) then
		return a,b,c,d;
	else
		return nil;
	end
end

local IP2DEC = function(sIP)
	local a,b,c,d = IsIP(sIP);
	return a and a*0x1000000 + b*0x10000 + c*0x100 + d or nil
end

local DEC2IP = function(iIP)
	local i = iIP%0x1000000;
	local j = i%0x10000;
	return ("%d.%d.%d.%d"):format(iIP/0x1000000,i/0x10000,j/0x100,j%0x100);
end

local Save = function()
	local f = io.open(Core.GetPtokaXPath().."scripts/gags.txt","w+")
	if f then
		f:write("tGagged = {\n")
		for i,v in ipairs(tGagged) do
			f:write("{"..(type(v[1]) == "string" and "\""..v[1].."\"" or v[1])..","..v[2].."},\n")
		end
		f:write("}")
		f:close()
	end
	local f = io.open(Core.GetPtokaXPath().."scripts/gagex.txt","w+")
	if f then
		f:write("tEx = {\n")
		for user in pairs(tEx) do
			f:write("[\""..user.."\"] = true,\n")
		end
		f:write("}")
		f:close()
	end
end

local Log = function(what)
	local f = io.open(Core.GetPtokaXPath().."scripts/gaglog.txt","a")
	if f then
		f:write(os.date("[%Y %B %d. %H:%M:%S] ")..what.."\r\n")
		f:close()
	end
end

local MatchIP = function(IP)
	local ip = IP
	for _,tIP in ipairs(tGagged) do
		if type(tIP[1]) == "string" then
			if (tIP[1]:sub(1,tIP[2]) == IP2BIN(IP):sub(1,tIP[2])) then
				return true
			end
		else
			ip = IP2DEC(IP)
			if (ip >= tIP[1] and ip <= tIP[2]) then
				return true
			end
		end
	end
	return false
end

local function gagrange(params)
	if not params[1] then
		return "Missing or unknown parameters. See !gagrange help";
	elseif params[1] == "help" then
		return "Usage:\r\n"..
		"!gagrange add <fromIP> <toIP> - Gags the given range in main and PM.\r\n"..
		"!gagrange add <IP/mask> - Gags the given IP with the given mask in main and PM.\r\n"..
		"!gagrange rm <index> - Removes the gag from the given INDEX (see list before)\r\n"..
		"!gagrange list - Lists the gagged IP ranges / masks\r\n"..
		"!gagrange exclude <nick> - Adds or removes an user (User can write even if gagged)\r\n"..
		"!gagrange excludelist - Lists the excluded users.";
	elseif params[1] == "add" then
		if params[3] then
			if IsIP(params[2]) and IsIP(params[3]) then
				table.insert(tGagged,{IP2DEC(params[2]),IP2DEC(params[3])});
				Save();
				return params[2].." - "..params[3].." range has been gagged in main and private chat.";
			else
				return "Usage: !gagrange add <fromIP> <toIP> - IP address must be valid.";
			end
		else
			if not params[2] then return "Usage: !gagrange add <IP/mask> - IP address must be valid, mask <= 32"; end
			local IP,mask = params[2]:match("(%S+)/(%d+)$")
			if IP and IsIP(IP) and tonumber(mask) <= 32 then
				table.insert(tGagged,{IP2BIN(IP),tonumber(mask)});
				Save();
				return "IP address "..IP.." with mask "..mask.." has been gagged in main and private chat.";
			else
				return "Usage: !gagrange add <IP/mask> - IP address must be valid, mask <= 32";
			end
		end
	elseif params[1] == "rm" then
		if not params[2] then return "Usage: !gagrange rm <index>"; end
		local elem = params[2]:match("(%d+)");
		if elem and tonumber(elem) <= #tGagged then
			table.remove(tGagged,tonumber(elem));
			Save();
			return elem..". element removed.";
		else
			return "Usage: !gagrange rm <index>";
		end
	elseif params[1] == "list" then
		local list = "Currently gagged IP ranges:\r\n";
		for i,range in ipairs(tGagged) do
			if type(range[1]) == "number" then
				list = list.."\149 "..i..". "..DEC2IP(range[1]).."-"..DEC2IP(range[2]).."\r\n";
			else
				list = list.."\149 "..i..". "..BIN2IP(range[1]).."/"..tostring(range[2]).."\r\n";
			end
		end
		return list;
	elseif params[1] == "exclude" then
		if not params[2] then return "Usage: !gagrange exclude <nick>"; end
		if tEx[params[2]] then
			tEx[params[2]] = nil;
			Save();
			return params[2].." removed from excluded users.";
		else
			tEx[params[2]] = true;
			Save();
			return params[2].." has been added to the excluded users.";
		end
	elseif params[1] == "excludelist" then
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
		local list = {"Currently excluded users:"};
		for nick in SortByKeys(tEx) do
			table.insert(list,nick);
		end
		return table.concat(list,", ")
	end
	return "Unknown parameters. See !gagrange help";
end

function ChatArrival(user, fulltext)
	if tostring(user.iProfile):match("["..class.."]") and fulltext:match("^%b<>%s*[%+!]gagrange.+$") then
		local t = {}
		fulltext:sub(#user.sNick+13,-2):gsub("(%S+)",function(m) table.insert(t,m) end)
		msg = gagrange(t)
		if msg then Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..msg) end
		return true
	end
	if user.iProfile ~= -1 or not next(tGagged) or tEx[user.sNick] then
		return false;
	end
	local sIP = user.sIP;
	if MatchIP(sIP) then
		--[=[if fulltext:match("^%b<>%s[!%+]%w+") then
			if fulltext:match("^%b<>%s[%+!]chatlog") then
				ChatToNick("",nick,"Ismeretlen parancs: chatlog")
				PMToNick("","OpChat","User "..nick.." with IP ["..sIP.."] from gagged IP range wrote in mainchat: "..fulltext)
				Log("User "..nick.." with IP ["..sIP.."] from gagged IP range wrote in mainchat: "..fulltext)
				return true
			else
				return false
			end
		else]=]
			Core.SendToOpChat("User "..user.sNick.." with IP ["..sIP.."] from gagged IP range wrote in mainchat: "..fulltext)
			Log("User "..user.sNick.." with IP ["..sIP.."] from gagged IP range wrote in mainchat: "..fulltext)
			Core.SendToUser(user,fulltext.."|")
			return true
		--end
	end
	return false
end

function ToArrival(user, fullpm)
	if user.iProfile ~= -1 or not next(tGagged) or tEx[user.sNick] then
		return false
	end
	local to,text = fullpm:match("^%$To: (%S+) From: %S+ %$%b<> (.*)")
	local sIP = user.sIP
	if MatchIP(sIP) then
		Core.SendToOpChat("User "..user.sNick.." with IP ["..sIP.."] from gagged IP range wrote in private chat to "..to..": "..text)
		Log("User "..user.sNick.." with IP ["..sIP.."] from gagged IP range wrote in private chat to "..to..": "..text)
		return true
	end
	return false
end

if loadfile(Core.GetPtokaXPath().."scripts/gags.txt") then dofile(Core.GetPtokaXPath().."scripts/gags.txt") end
if loadfile(Core.GetPtokaXPath().."scripts/gagex.txt") then dofile(Core.GetPtokaXPath().."scripts/gagex.txt") end

function OnExit()
	UnregCommand({"gagrange"})
end

RegCommand("gagrange", class, "Gag user by IP range. See !gagrange help");
