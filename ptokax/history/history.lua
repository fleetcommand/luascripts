local tHistory = {}
local historyMax = 150
local historyDefault = 20

dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

function ChatArrival(user, data)
	if not data:find("^%b<>%s[%+!].+$") and not data:find("is kicking %S+ because:") then
		if #tHistory > historyMax then table.remove(tHistory, 1) end
		table.insert(tHistory, os.date("[%H:%M:%S] ") .. data:sub(1, -2))
	end
	if data:find("^%b<>%s[%+!]history.*$") or data:find("^%b<>%s[%+!]chatlog.*$") then
		local msgToSend = historyDefault

		if data:match("[%+!]%S+%s(.+)|$") then
			local params = {}
			data:match("[%+!]%S+%s(.+)|$"):gsub("(%S+)", function(s) table.insert(params, s) end)
			if params[1] then
				if params[1]:match("^%d+$") then
					msgToSend = tonumber(params[1])
				else
					Core.SendToUser(user, "<" .. SetMan.GetString(21) .."> Usage: !history [number]")
					return true
				end
			end
		end
		Core.SendToUser(user, "<" .. SetMan.GetString(21) .. "> Displaying " .. math.min(#tHistory, msgToSend) .. " of " .. #tHistory .. " messages:\r\n" .. table.concat(tHistory, "\r\n", math.max(#tHistory - msgToSend + 1, 1)))
		return true
	end
end

function OnExit()
	UnregCommand({"history"})
end

RegCommand("history", "-10123", "Shows the latest chat messages")