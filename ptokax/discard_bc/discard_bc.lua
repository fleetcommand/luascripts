-- Discard mistyped commands starting with ! and +

if os.getenv("windir") then
    lfs = require("pxlfs")
else
    lfs = require("lfs")
end

local tCmds = {
["passwd"] = true,
["ban"] = true,
["banip"] = true,
["fullban"] = true,
["fullbanip"] = true,
["nickban"] = true,
["tempban"] = true,
["tempbanip"] = true,
["fulltempban"] = true,
["fulltempbanip"] = true,
["nicktempban"] = true,
["unban"] = true,
["permunban"] = true,
["tempunban"] = true,
["getbans"] = true,
["getpermbans"] = true,
["gettempbans"] = true,
["clrpermbans"] = true,
["clrtempbans"] = true,
["rangeban"] = true,
["fullrangeban"] = true,
["rangetempban"] = true,
["fullrangetempban"] = true,
["rangeunban"] = true,
["rangepermunban"] = true,
["rangetempunban"] = true,
["getrangebans"] = true,
["getrangepermbans"] = true,
["getrangetempbans"] = true,
["clrrangepermbans"] = true,
["clrrangetempbans"] = true,
["checknickban"] = true,
["checkipban"] = true,
["checkrangeban"] = true,
["drop"] = true,
["getinfo"] = true,
["op"] = true,
["gag"] = true,
["ungag"] = true,
["restart"] = true,
["startscript"] = true,
["stopscript"] = true,
["restartscript"] = true,
["restartscripts"] = true,
["getscripts"] = true,
["reloadtxt"] = true,
["addreguser"] = true,
["delreguser"] = true,
["topic"] = true,
["massmsg"] = true,
["opmassmsg"] = true,
["me"] = true,
["myip"] = true,
["help"] = true,
["debug"] = true,
["stats"] = true,
}

function ChatArrival(tUser,data)
	local cmd = data:match("^%b<>%s*[!%+](%w+).+")
	if cmd and not tCmds[cmd] then
		local tTextfiles = {}
		for f in lfs.dir( Core.GetPtokaXPath().."texts" ) do
			if f:sub(-4) == ".txt" then
				tTextfiles[f:sub(1, -5)] = true
			end
		end
		if not tTextfiles[cmd] then
			Core.SendToUser(tUser,"<"..SetMan.GetString(21).."> Ismeretlen parancs.|")
			return true
		end
	end
end 
