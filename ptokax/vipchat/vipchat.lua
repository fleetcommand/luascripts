local vipchat = "EliteChat"
local class = "012"

function OnStartup()
	Core.RegBot(vipchat,"ECSET","",true)
end

function ToArrival(user,data)
	if tostring(user.iProfile):find("^[%"..class.."]") then
		local tonick, fromnick, nick,tomsg = data:match("^%$To:%s(%S+)%sFrom:%s(%S+)%s%$(%b<>)%s(.*)|")
		if tonick == vipchat then
			local t = {}
			for i=1,#class do 
				table.insert(t,Core.GetOnlineUsers(tonumber(class:sub(i,i))))
			end
			for i,classusers in ipairs(t) do
				for j,u in ipairs(classusers) do
					if u.sNick ~= user.sNick then
						Core.SendToUser(u,"$To: "..u.sNick.." From: "..vipchat.." $"..nick.." "..tomsg.."|")
					end
				end
			end
			return true
		end
	end
end