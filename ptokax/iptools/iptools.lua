dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

local last = 250 -- store last x logged out users' IP
local iplog = {}
local class = "0"

function UserDisconnected(user)
	if #iplog > last then
		table.remove(iplog,1)
	end
	table.insert(iplog,{os.time(),user.sIP,user.sNick})
end
RegDisconnected,OpDisconnected = UserDisconnected,UserDisconnected

function ChatArrival(user, data)
	if tostring(user.iProfile):find("^[%"..class.."]") then
		if data:find("^%b<>%s[%+!]iplog") then
			local param = data:match("^%b<>%s[%+!]iplog%s+(%S+)|")
			if param and param:find("%d+%.%d+%.%d+%.%d+") then
				local msg = {"<"..SetMan.GetString(21).."> Logout time  :  IP  :  Nick"}
				for i=1,#iplog do
					if iplog[i][2] == param then
						table.insert(msg,os.date("%Y. %m %d. %H:%M:%S",iplog[i][1]).."  :  "..param.."  :  "..iplog[i][3].."|")
					end
				end
				Core.SendToUser(user,table.concat(msg,"\r\n").."|")
				return true
			elseif param then
				-- partial IP match, but what happens when the nick was an IP? :-/
				if param:find("^%d+%.%d+%.") then
					local msg = {"<"..SetMan.GetString(21).."> Logout time  :  IP  :  Nick"}
					for i=1,#iplog do
						if iplog[i][2]:find(param,1,1) then
							table.insert(msg,os.date("%Y. %m %d. %H:%M:%S",iplog[i][1]).."  :  "..iplog[i][2].."  :  "..iplog[i][3])
						end
					end
					Core.SendToUser(user,table.concat(msg,"\r\n").."|")
				else
					local msg = {"<"..SetMan.GetString(21).."> Logout time  :  IP  :  Nick"}
					for i=1,#iplog do
						if iplog[i][3] == param then
							table.insert(msg,os.date("%Y. %m %d. %H:%M:%S",iplog[i][1]).."  :  "..iplog[i][2].."  :  "..iplog[i][3])
						end
					end
					Core.SendToUser(user,table.concat(msg,"\r\n").."|")
				end
				return true
			else
				local msg = {"<"..SetMan.GetString(21).."> Logout time  :  IP  :  Nick"}
				for i=1,#iplog do
					table.insert(msg,os.date("%Y. %B %d. %H:%M:%S",iplog[i][1]).."  :  "..iplog[i][2].."  :  "..iplog[i][3])
				end
				Core.SendToUser(user,table.concat(msg,"\r\n"))
				return true
			end
		elseif data:find("^%b<>%s[%+!]whoip") then
			local ip = data:match("^%b<>%s[%+!]whoip%s+(%d+%.%d+%.%d+%.%d+)|$")
			if ip then
				local users = Core.GetUsers(ip)
				if users then
					local msg = "Currently "..#users.." user(s) use the IP "..ip..": "
					for i,u in ipairs(users) do msg = msg..u.sNick..", " end
					Core.SendToUser(user,"<"..SetMan.GetString(21).."> "..msg:sub(1,-3).."|")
				else
					Core.SendToUser(user,"<"..SetMan.GetString(21).."> Nobody use the IP "..ip.."|")
				end
			else
				Core.SendToUser(user,"<"..SetMan.GetString(21).."> Usage: !whoip <IP address>|")
			end
			return true
		end
	end
end

function OnExit()
	UnregCommand({"iplog","whoip"})
end

RegCommand("iplog",class,"Shows logged IPs. Usage: !iplog [<nick/IP>]")
RegCommand("whoip",class,"Returns the user using the IP")