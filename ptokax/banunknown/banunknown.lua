function OnStartup()
	tmr = TmrMan.AddTimer(3*60000)
	count = 0
	start = 0
	last = 0
end

function UnknownArrival(tUser, sData)
	if sData:sub(1,7) == "$UserIP" then
		Core.SendToUser(tUser, "<" .. SetMan.GetString(21) .. "> Túl régi klienst használsz, cseréld le újabbra.\r\nYou are using a very outdated client, please upgrade.")
	elseif sData:sub(1,7) == "$MyNick" then
		count = count + 1
		if count == 1 then
			Core.SendToOpChat("DDoS attack detected...")
			start = os.time()
		end
		last = os.time()
	elseif #sData:match("^(%S+)") > 15 then
		count = count + 1
		if count == 1 then
			Core.SendToOpChat("Unknown commands detected...")
			start = os.time()
		end
		last = os.time()
	end
	BanMan.TempBanIP(tUser.sIP, 60, "", "", true)
	return true
end

function OnTimer(tmr)
	if count > 0 and os.difftime(os.time(), last) > 180 then
		Core.SendToOpChat("Attack end. Count: " .. count .. " (" .. string.format("%.2f", last-start) .. " seconds)")
		count = 0
		start = 0
		last = 0
	end
end
