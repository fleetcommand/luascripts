dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")
local sMoveDown = "movedown"
local sMoveUp = "moveup"

ChatArrival = function(User,Data)
	if User.iProfile == 0 then
		local cmd,file = Data:match("%b<>%s%p([^ ]+)%s*([^|]*)")
		if not cmd then return false end
		file = string.lower(file)
		f = file..".lua"
		if cmd and ((cmd == sMoveUp) or (cmd==sMoveDown)) then
			local fobj = io.open(Core.GetPtokaXPath().."scripts/"..f)
			if not fobj then
				Core.SendToUser(User,"<"..SetMan.GetString(21).."> "..f.." nevû script nem létezik. (.lua kiterjesztés nem kell)")
				return true
			end
			fobj:close()
		    if cmd == sMoveUp then ScriptMan.MoveUp(f) else ScriptMan.MoveDown(f) end
			Core.SendToUser(User,"<"..SetMan.GetString(21).."> "..f.." "..(cmd==sMoveUp and "feljebb" or "lejjebb").." helyezve.")
			return true
		end
	end
end

function OnStartup()
	RegCommand("moveup","0","Script mozgatása felfelé. A .lua nem kell a végére.")
	RegCommand("movedown","0","Script mozgatása lefelé. A .lua nem kell a végére.")
end

function OnExit()
	UnregCommand({"moveup","movedown"})
end