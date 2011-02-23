local iMinShare = 10 -- in GB
local sHubSec = SetMan.GetString(21)
local class = "01"

dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
local tBlocks = {}

function ChatArrival(tUser,sData)
	sData = sData:match("%b<>%s(.+)|")
	local cmd = sData:match("^[%+!](%w+)")
	if cmd and tostring(tUser.iProfile):match("^[%"..class.."]") then
		if (cmd == "bl" or cmd == "blocklist") then
			local msg,i = {"List of blocked users:"},0
			for key,v in pairs(tBlocks) do
				table.insert(msg,"["..i.."] Nick: "..key.."\t(Added by: "..v[2].." @ "..os.date("%Y-%m-%d %H:%M:%S)",v[1]))
				i=i+1
			end
			table.insert(msg,"Totally "..i.." users blocked.")
			Core.SendToUser(tUser,"<"..sHubSec.."> "..table.concat(msg,"\r\n").."|")
			return true
		elseif cmd == "block" then
			local user = sData:match("^[%+!]%w+%s+(%S+)")
			if not user then Core.SendToUser(tUser,"<"..sHubSec.."> Usage: !block <nick>|") return true end
			tBlocks[user] = {os.time(),tUser.sNick}
			Core.SendToUser(tUser,"<"..sHubSec.."> "..user.." has been blocked.|")
			return true
		elseif cmd == "unblock" then
			local user = sData:match("^[%+!]%w+%s+(%S+)")
			if not user then Core.SendToUser(tUser,"<"..sHubSec.."> Usage: !block <nick>|") return true end
			if tBlocks[user] then
				tBlocks[user] = nil
				Core.SendToUser(tUser,"<"..sHubSec.."> "..user.." has been unblocked.|")
			else
				Core.SendToUser(tUser,"<"..sHubSec.."> "..user.." isn't blocked.|")
			end
			return true
		end
	end
end



function UserConnected(tUser)
	if tUser.iProfile == -1 and Core.GetUserValue(tUser,16) < iMinShare*1073741824 then
		Core.SendToUser(tUser,"<"..sHubSec.."> A hubon a letöltéshez szükséges minimum megosztás "..iMinShare.." Gb.")
	end
end

function MyINFOArrival(tUser)
	if Core.GetUserValue(tUser,9) then
		if tUser.iProfile == -1 and Core.GetUserValue(tUser,16) < iMinShare*1073741824 then
			Core.SendToUser(tUser,"<"..sHubSec.."> A hubon a letöltéshez szükséges minimum megosztás "..iMinShare.." Gb.")
		end
	end
end

function ConnectToMeArrival(tUser,data)
	if (tUser.iProfile == -1 and Core.GetUserValue(tUser,16) < iMinShare*1073741824) or tBlocks[tUser.sNick] then
		return true
	end
end

RevConnectToMeArrival = ConnectToMeArrival

function OnExit()
	UnregCommand({"block","unblock","blocklist"})
end
RegCommand("block", class, "Blocks the given user's downloads");
RegCommand("unblock", class, "Unblocks the given user");
RegCommand("blocklist", class, "Lists the currently blocked users");
