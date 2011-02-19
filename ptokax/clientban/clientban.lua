--[[
	clientban.lua v1.1
	02/12/2011
	Authors:
	  Thor: ejjeliorjarat@gmail.com
	  FleetCommand: fleetcommand@elitemail.hu

	Changes:
	0.1.2 (Thor)
	  setlocale instead of numUtils
	  Multiple version handling (ie. 1.2.2 is 1.22)
	0.1.1 (FleetCommand)
	  Fixing so that the script won't fail if no parameter specified
	  <=, >= instead of <, >
	  Saving strings with quotation marks in them should work now
	  Added numutil.inc:
	    Now it can check the tag even on localized systems
	    Now saved data can be loaded again

	v1.0 (Thor)
	  Initial release
]]

dofile(Core.GetPtokaXPath() .. "scripts/help.lua.inc")
--dofile(Core.GetPtokaXPath() .. "scripts/numutil.inc")
os.setlocale("C","numeric")

local class = "0"
local filteredClass = {
	[-1] = true, -- Unregistered
	[0] = false, -- Master
	[1] = false, -- Op
	[2] = true, -- Vip
	[3] = true, -- Reg
}
tCB = {}

if loadfile(Core.GetPtokaXPath() .. "scripts/cb.txt") then dofile(Core.GetPtokaXPath() .. "scripts/cb.txt") end

local escapeString = function(text)
	return string.gsub(text, "\"", "\\\"")
end

local Save = function()
	local f = io.open(Core.GetPtokaXPath() .. "scripts/cb.txt", "w+")
	if f then
		f:write("tCB = {\n")
		for i, v in ipairs(tCB) do
			f:write('{"' .. escapeString(v[1]) .. '", ' .. tostring(v[2]) .. ', ' .. tostring(v[3]) .. ', "' .. escapeString(v[4]) .. '"},\n')
		end
		f:write("}")
		f:close()
	end
end

local function Clientban(params)
	if (not params[1]) then
		return "Missing parameters. See !cb help";
	elseif (params[1] == "help") then
		return "Usage:\r\n"..
		"!cb add <client> <from_version> <to_version> <message> - Bans a client with the given version.\r\n"..
		"!cb rm <index> - Removes the client with the given index from the list. See !cb list for the indexes.\r\n"..
		"!cb list - Lists banned clientversions.\r\n"
	elseif (params[1] == "add") then
		if (not tonumber(params[3]) or not tonumber(params[4])) then
			return "Versions must be numeric. Remove every character from it, decimal numbers are accepted."
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
		local list = "Currently banned clients:\r\nIndex\tclient\tfrom_version\tto_version\tmessage\r\n";
		--// To avoid end-user confusion, we use dot as a decimal separator  in !bc list
		for i, t in ipairs(tCB) do
			list = list .. i .. "\t" .. t[1] .. "\t" .. tostring(t[2]) .. "\t\t" .. tostring(t[3]) .. "\t\t" .. t[4] .. "\r\n"
		end
		return list;
	else
		return "Unknown parameter \"" .. params[1] .. "\". See !cb help";
	end
end

local function CheckVersion(user)
	if not filteredClass[user.iProfile] then
		return false
	end
	local disconnect = false
	local message = ""
	local cl, ve = Core.GetUserValue(user, 6), Core.GetUserValue(user, 7)
	-- Remove extra dots
	local i = 0
	local f = function(m) i = i + 1 return i == 1 and "." or "" end
	ve = ve:gsub("%.", f):gsub("[^%d%.]+", "")
	ve = tonumber(ve)
	-- Rename what Px has renamed
	if cl == "DC++" then cl = "++" end
	if cl == "Valknut" then cl = "DCGUI" end
	if cl == "NMDC2" then cl = "DC" end
	for i, t in ipairs(tCB) do
		if cl == "UNKNOWN TAG" then
			Core.SendToOpChat("Unable to check " .. user.sNick .. "'s client. (It might be VERY crazy! Check manually.)")
			return true
		end
		if (cl == t[1]) then
			if (t[2] == 0 and t[3] == 0) then -- time to say goodbye
				disconnect = true
				message = t[4]
				break
			end
			if ve then
				if t[3] == 0 then -- max ver is 0, check whether user's version is higher than from_version
					if ve >= t[3] then
						disconnect = true
						message = t[4]
						break
					end
				elseif ve >= t[2] and ve <= t[3] then
					disconnect = true
					message = t[4]
					break
				end
			else
				Core.SendToOpChat("Unable to check " .. user.sNick .. "'s client. Tag: " .. Core.GetUserValue(user,3))
				return true
			end
		end
	end
	if disconnect then
		Core.SendToUser(user, "<" .. SetMan.GetString(21) .. "> " .. message)
		Core.Disconnect(user)
		return true
	end
	return false
end

function ChatArrival(user, fulltext)
	if tostring(user.iProfile):match("["..class.."]") and (fulltext:match("^%b<>%s*[%+!]clientban.+$") or fulltext:match("^%b<>%s*[%+!]cb.+$"))then
		local t = {}
		if fulltext:match("[%+!]%S+%s(.+)|$") then
			fulltext:match("[%+!]%S+%s(.+)|$"):gsub("(%S+)",function(m) table.insert(t, m) end)
		end
		msg = Clientban(t)
		if msg then Core.SendToUser(user,"<" .. SetMan.GetString(21) .. "> " .. msg) end
		return true
	end
	return false
end

function UserConnected(user)
	return CheckVersion(user)
end

function RegConnected(user)
	return CheckVersion(user)
end

function OpConnected(user)
	return CheckVersion(user)
end

function OnExit()
	UnregCommand({"clientban"})
end

RegCommand("clientban", class, "Bans users because old client. See !clientban help (or !cb help)");
