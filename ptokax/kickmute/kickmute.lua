
dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
local class = "012"
local bot = SetMan.GetString(21)
local tMutes = {}

function ChatArrival(user,data)
	if tostring(user.iProfile):find("^[%"..class.."]") then
		local cmd,param1,param2 = data:match("%b<>%s(%S*)%s*(%S*)%s*(.*)|")
		if cmd and cmd:lower() == "!kick" then
			if param1 ~= "" then
				local tUser = Core.GetUser(param1)
				if tUser then
					local tBanTimes = { ["s"] = 0.1,["m"] = 1, ["h"] = 60, ["d"] = 1440, ["w"] = 10080,["y"] = 525600 }
					local nTime=SetMan.GetNumber(16)
					if param2 == "" then param2 = "No reason given" end
					if param2:lower():find("_ban_%d+[smhdwy]") then
						if ProfMan.GetProfilePermission(user.iProfile,8) then
							local sBantime = param2:lower():gsub(".*_ban_(%d+[smhdwy]).*","%1")
							nTime = (tBanTimes[sBantime:sub(-1,-1)] * tonumber(sBantime:sub(1,-2)))
						else
							Core.SendToUser(user,"<"..bot.."> You have no right to use _BAN_xx, banning user for default time (".. tostring(nTime) .. " min).|")
						end
					end
					Core.SendPmToUser(tUser,bot,"You are being kicked because: "..param2.."|")
					if nTime < 6 then
						Core.Disconnect(param1)
					else
						BanMan.TempBan(tUser,nTime,param2,user.sNick,false)
					end
					--Core.SendToAll("<"..user.sNick.."> is kicking "..param1.." because: "..param2.."|")
				else
					Core.SendToUser(user,"<"..bot.."> User "..param1.." not found.|")
				end
			else
				Core.SendToUser(user,"<"..bot.."> Usage: !kick <nick> <reason>|")
			end
			return true
		elseif cmd:lower() == "!drop" then
			if param1 ~= "" then
				if Core.GetUser(param1) then
					Core.Disconnect(param1)
					Core.SendToUser(user,"<"..bot.."> "..param1.." disconnected.|")
				else
					Core.SendToUser(user,"<"..bot.."> User "..param1.." not found.|")
				end
			else
				Core.SendToUser(user,"<"..bot.."> Usage: !drop <nick>|")
			end
			return true
		elseif cmd:lower() == "!gag" then
			if param1 ~= "" then
				tMutes[param1] = true
				Core.SendToUser(user,"<"..bot.."> "..param1.." has been gagged (hidden).|")
				Core.SendToOpChat(user.sNick.." gagged (hidden) "..param1..".|")
			else
				Core.SendToUser(user,"<"..bot.."> Usage: !gag <nick>|")
			end
			return true
		elseif cmd:lower() == "!ungag" then
			if param1 ~= "" then
				if tMutes[param1] then
					tMutes[param1] = nil
					Core.SendToUser(user,"<"..bot.."> "..param1.." has been gagged.|")
					Core.SendToOpChat(user.sNick.." ungagged "..param1..".|")
				else
					Core.SendToUser(user,"<"..bot.."> "..param1.." isn't gagged.|")
				end
			else
				Core.SendToUser(user,"<"..bot.."> Usage: !ungag <nick>|")
			end
			return true
		elseif cmd:lower() == "!gaglist" then
			local msg = {"Currently gagged users:\r\n"}
			for k,v in pairs(tMutes) do table.insert(msg,k) end
			Core.SendToUser(user,"<"..bot.."> "..table.concat(msg).."|")
			return true
		elseif cmd:lower() == "!say" then
			local msg = data:match("%b<>%s!say%s(.*)")
			if msg then Core.SendToAll("<"..bot.."> "..msg) end
			return true
		end
	else
		if tMutes[user.sNick] then
			Core.SendToUser(user,data)
			Core.SendToOpChat("Gagged user wrote in mainchat: "..data)
			return true
		end
	end
end

function ToArrival(user,data)
	if tMutes[user.sNick] then
		local tonick, tomsg = data:find("^%$To:%s(%S+)%sFrom:%s%S+%s%$%b<>%s(.*)|")
		Core.SendToOpChat("Gagged user wrote in private chat to "..tonick..": "..tomsg)
		return true
	end
end

function OnExit()
	UnregCommand({"kick","gag","ungag","gaglist","say"})
end

RegCommand("kick", class, "Kicks user from hub. Usage: !kick <nick> [<reason>]")
RegCommand("gag", class, "Hidden-gags the user, he will see his own messages. Usage: !gag <nick>")
RegCommand("ungag", class, "Ungags a user. Usage: !ungag <nick>")
RegCommand("gaglist", class, "Lists gagged users")
RegCommand("say", class, "Say something in the name of the hubsecurity. Usage: !say <message>")