
function RegCommand(cmd_name,profile,description)
	local tCommands = {}
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
	tCommands[cmd_name] = {profile,description};
	local f,e = io.open(Core.GetPtokaXPath().."scripts/help.txt","w+");
	if not f then
		error("Nem lehet megnyitni a következõ fájlt: "..Core.GetPtokaXPath().."scripts/help.txt. Hibaüzenet: "..tostring(e));
		return
	end
	for cmd,params in pairs(tCommands) do
		f:write(cmd.."$$$"..params[1].."$$$"..params[2].."\n");
	end
	f:close();
end

function UnregCommand(tCmds)
	local tCommands = {}
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
	for i,v in ipairs(tCmds) do
		for a,b in pairs(tCommands) do
			if a:find("^"..v) then
				tCommands[a] = nil;
			end
		end
	end
	local f,e = io.open(Core.GetPtokaXPath().."scripts/help.txt","w+");
	if not f then
		error("Nem lehet megnyitni a következõ fájlt: "..Core.GetPtokaXPath().."scripts/help.txt. Hibaüzenet: "..tostring(e));
		return
	end
	for cmd,params in pairs(tCommands) do
		f:write(cmd.."$$$"..params[1].."$$$"..params[2].."\n");
	end
	f:close();
end
