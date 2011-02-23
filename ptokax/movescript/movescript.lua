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
				Core.SendToUser(User,"<"..SetMan.GetString(21).."> "..f.." nev� script nem l�tezik. (.lua kiterjeszt�s nem kell)")
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
	RegCommand("moveup","0","Script mozgat�sa felfel�. A .lua nem kell a v�g�re.")
	RegCommand("movedown","0","Script mozgat�sa lefel�. A .lua nem kell a v�g�re.")
end

function OnExit()
	UnregCommand({"moveup","movedown"})
end