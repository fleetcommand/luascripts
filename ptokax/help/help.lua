function ChatArrival(user,data)
	if data:match("^%b<>%s*[!%+]help|$") then
		local msg = {"<"..SetMan.GetString(21).."> Scriptekhez tartozó parancsok:"};
		local tCommands = {};
		local f,e = io.open(Core.GetPtokaXPath().."scripts/help.txt");
		if f then
			for line in f:lines() do
				local cmd,profile,description = line:match("^(.-)%$%$%$(.-)%$%$%$(.-)$");
				if cmd then
					tCommands[cmd] = {profile,description};
				end
			end
			f:close();
		end
		local SortByKeys = function(t)
			local a,tTemp,i = {},{},0
			for n in pairs(t) do table.insert(a,n) end
			table.sort(a)
			local iter = function ()
				i = i + 1
				return a[i] and a[i], t[a[i]] or nil
			end
			return iter
		end
		for cmd,params in SortByKeys(tCommands) do
			if tostring(user.iProfile):match("^[%"..params[1].."]") then
				table.insert(msg,"!"..cmd.." - "..params[2]);
			end
		end
		Core.SendToUser(user,table.concat(msg,"\r\n"));
	end
end

