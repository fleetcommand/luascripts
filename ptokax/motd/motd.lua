dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

function ChatArrival(user,data)
	if user.iProfile == 0 and data:match("^%b<>%s[%+!]setmotd%s.+|") then
		local motd = data:match("^%b<>%s[%+!]setmotd%s(.+)|")
		motd = motd:gsub("|","l")
		SetMan.SetMOTD(motd)
		Core.SendToUser(user,"<"..SetMan.GetString(21).."> MOTD updated.")
		return true
	end
end

function OnExit()
	UnregCommand({"setmotd"})
end

RegCommand("setmotd","0", "Sets up the MOTD");
