dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
local class = "0"
tCB = {}

if loadfile(Core.GetPtokaXPath().."scripts/cb.txt") then dofile(Core.GetPtokaXPath().."scripts/cb.txt") end

local Save = function()
	local f = io.open(Core.GetPtokaXPath().."scripts/cb.txt","w+")
	if f then
		f:write("tCB = {\n")
		for i,v in ipairs(tCB) do
			f:write('{"'..v[1]..'",'..v[2]..','..v[3]..',"'..v[4]..'"},\n')
		end
		f:write("}")
		f:close()
	end
end

local function clientban(params)
	if (not params[1]) then
		return "Missing or unknown parameters. See !cb help";
	elseif (params[1] == "help") then
		return "Usage:\r\n"..
		"!cb add <client> <min_version> <max_version> <message> - Bans a client with the given version.\r\n"..
		"!cb rm <index> - Removes the client with the given index from the list. See !cb list for the indexes.\r\n"..
		"!cb list - Lists banned clientversions.\r\n"..
		"!cb up <index> - Moves up the given index.\r\n"..
		"!cb down <index> - Moves down the given index."
	elseif (params[1] == "add") then
		if (not tonumber(params[3]) or not tonumber(params[4])) then
			return "Versions must be numeric. Remove every character from it, decimal numbers are accepted"
		end
		if params[5] then
			table.insert(tCB,{params[2],tonumber(params[3]),tonumber(params[4]),table.concat(params," ",5)})
			Save();
			return params[2].." with version "..params[3].." - "..params[4].." has been banned with message: "..table.concat(params," ",5);
		else
			return "You always have to specify the message sent to the user."
		end
	elseif (params[1] == "rm") then
		if not params[2] then return "Usage: !cb rm <index>"; end
		local elem = params[2]:match("(%d+)");
		if elem and tonumber(elem) <= #tCB then
			local x = table.remove(tCB,tonumber(elem));
			Save();
			return elem..". element ("..x[1].." "..x[2].."-"..x[3]..") removed.";
		else
			return "Usage: !cb rm <index>";
		end
	elseif (params[1] == "list") then
		local list = "Currently banned clients:\r\nIndex\tclient\tmin_version\tmax_version\tmessage\r\n";
		for i,t in ipairs(tCB) do
			list = list..i.."\t"..t[1].."\t"..t[2].."\t\t"..t[3].."\t\t"..t[4].."\r\n"
		end
		return list;
	end
end

function ChatArrival(user, fulltext)
	if tostring(user.iProfile):match("["..class.."]") and (fulltext:match("^%b<>%s*[%+!]clientban.+$") or fulltext:match("^%b<>%s*[%+!]cb.+$"))then
		local t = {}
		fulltext:match("[%+!]%S+%s(.+)|$"):gsub("(%S+)",function(m) table.insert(t,m) end)
		msg = clientban(t)
		if msg then Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..msg) end
		return true
	end
	return false
end

function UserConnected(user)
	local cl,ve = Core.GetUserValue(user,6),tonumber(Core.GetUserValue(user,7))
	if cl == "DC++" then cl = "++" end
	if cl == "Valknut" then cl = "DCGUI" end
	if cl == "NMDC2" then cl = "DC" end
	for i,t in ipairs(tCB) do
		if cl == "UNKNOWN TAG" then
			Core.SendToOpChat("Unable to check "..user.sNick.."'s client. (It might be VERY crazy! Check manually.)")
			return true
		end
		if (cl == t[1]) then
			if (t[2] == 0 and t[3] == 0) then -- time to say goodbye
				Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..t[4])
				Core.Disconnect(user)
			end
			if ve then
				if t[2] == 0 then -- min ver is 0, check whether user's version is less than max_version
					if ve < t[3] then
						Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..t[4])
						Core.Disconnect(user)
						return true
					end
				elseif t[3] == 0 then -- max ver is 0, check whether user's version is higher than min_version
					if ve > t[3] then
						Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..t[4])
						Core.Disconnect(user)
						return true
					end
				elseif (t[2] == t[3] and ve == t[2]) then
					Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..t[4])
					Core.Disconnect(user)
					return true
				elseif ve > t[2] and ve < t[3] then
					Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..t[4])
					Core.Disconnect(user)
					return true
				end
			else
				Core.SendToOpChat("Unable to check "..user.sNick.."'s client. Tag: "..Core.GetUserValue(user,3))
				return true
			end
		end
	end
	return false
end

function OnExit()
	UnregCommand({"clientban"})
end

RegCommand("clientban", class, "Bans or warns users because old client. See !clientban help (or !cb help)");