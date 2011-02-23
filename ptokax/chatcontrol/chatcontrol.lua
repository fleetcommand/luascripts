-- Chatlocker made by Hungarista 2oo6
-- Requested by tizperc
local chat = nil
local class = "01"
local bot = SetMan.GetString(21)

dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

function ChatArrival(user,data)
	if tostring(user.iProfile):find("^[%"..class.."]") then
		local cmd,param = data:match("^%b<>%s%p(%S+)%s*(%S*)|$")
		if cmd and cmd == "chat" then
			if param == "off" then
				if chat ~= "off" then
					chat = "off"
					Core.SendToAll("<"..bot.."> "..user.sNick .. " has disabled the main chat.")
				else
					Core.SendToUser(user,"<"..bot.."> The chat is already turned off for normal and registered users.")
				end
			elseif param == "on" then
				if chat ~= nil then
					chat = nil
					Core.SendToAll("<"..bot.."> "..user.sNick.." has enabled the main chat.")
				else
					Core.SendToUser(user,"<"..bot.."> The chat is already turned on.")
				end
			elseif param == "reg" then
				if chat ~= "reg" then
					chat = "reg"
					Core.SendToAll("<"..bot.."> "..user.sNick.." has disabled the main chat for non-registered users.") 
				else
					Core.SendToUser(user,"<"..bot.."> The chat is already reg-only state.")
				end
			else
				Core.SendToUser(user,"<"..bot.."> Unknown parameter: "..param..". Available: on/off/reg.")
			end
			return true
		end
	end
	if chat == "off" then
		if not Core.GetUserValue(user,11) then
			Core.SendToUser(user,"<"..bot.."> \r\n---------\r\nMain chat is currently enabled only for hub operators.\r\nA közös chatre jelenleg csak operátorok írhatnak.\r\n---------")
			return true
		end
	elseif chat == "reg" then
		if user.iProfile == -1 then
			Core.SendToUser(user,"<"..bot.."> \r\n---------\r\nMain chat is currently enabled only for hub registered users.\r\nA közös chatre jelenleg csak regisztrált felhasználók írhatnak.\r\n---------") 
			return true
		end
	end
end

function OnExit()
	UnregCommand({"chat"})
end

RegCommand("chat",class,"Enables/disables the mainchat. Usage: !chat <on/off/reg>")