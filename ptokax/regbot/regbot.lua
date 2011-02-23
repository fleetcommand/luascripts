
------------- Settings Start ---------------

-- Sz�ks�g eset�n v�ltoztass a sorrenden. Ha pl a Moderator helyett KVip-ed van
--(ami alacsonyabbrang az oper�torn�l) akkor [4] = 3, [1] = 4, [0] = 5, stb...
-- A hubon nem l�tez� profilokat kommentezd ki (--)
local tClasses = {
[-1] = 0,	-- UnRegistered
[3] = 1,	-- Registered
[2] = 2,	-- VIP
[1] = 3,	-- Operator
[0] = 4,	-- Master
--[4] = 5,	-- Moderator
--[5] = 6,	-- NetFounder
--[6] = 7,		-- Owner
}
local Class_Diff = 1	-- minimum "profilk�l�nbs�g" a regel�shez. A legmagasabb oszt�lyra  nem vonatkozik... (a p�ld�ban Master)
local sBot = SetMan.GetString(21)
local class = "0"
local bAutoRegme = false
local tReginfo = {}


local evilnicks = {
    "[%[%({]%A-op%A-[%]%)}]",
    "[%[%({].-admin.-[%]%)}]",
    "[%[%({].-elite.-[%]%)}]",
    "[%[%({].-vip.-[%]%)}]",
    "[%[%({].-bot.-[%]%)}]",
    "!�vip�!",
    "-�-�",
    "zsid�",
    "^\160",
}

------------- Settings End ---------------

dofile(Core.GetPtokaXPath().."scripts/help.lua.inc")

local GetSize = function(tTable)
	local iSize = 0
	for k in pairs(tTable) do
		iSize = iSize + 1
	end
	return iSize
end

local GetPermission = function(UserProfileID,RegProfileID)
	if tClasses[UserProfileID] and tClasses[UserProfileID] == (GetSize(tClasses)-1) then return true end
	if RegProfileID and tClasses[RegProfileID] then
		return ((tClasses[RegProfileID] + Class_Diff) > tClasses[UserProfileID]) and false or true
	else
		return false
	end
end

local PassCode = function(int)--By Mutor
	local t = {{48,57},{65,90},{97,122}} -- ASCII range(s)
	local msg = {}
	math.randomseed(os.time())
	for i=1, int do
		local r = math.random(1,#t)
		table.insert(msg,string.char(math.random(t[r][1],t[r][2])))
	end
	return table.concat(msg)
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

function OnStartup()
	if loadfile(Core.GetPtokaXPath().."scripts/regusers.txt") then
		dofile(Core.GetPtokaXPath().."scripts/regusers.txt")
	else
		tRegisteredUsers = {}
	end
	local f = io.open(Core.GetPtokaXPath().."scripts/reginfo.db")
	if f then
		for line in f:lines() do
			local n,rb,rt,li,lo,ip = line:match("(%S+)$$(%S*)$$(%d+)$$(%d+)$$(%d+)$$(%S*)")
			if n then
				tReginfo[n] = {rb,tonumber(rt),tonumber(li),tonumber(lo),ip}
			end
		end
		f:close()
	end
end

function ChatArrival(curUser,data)
	data = data:sub(1,-2)
	local cmd = data:match("^%b<>%s*%p(%S+)")
	if cmd then
		local tCommands = {["regnew"]=true,["regdelete"]=true,["reglist"]=true,["regpasswd"]=true,["genpass"]=true,
		["reginfo"]=true,["oldregs"]=true,["addreguser"]=true,["delreguser"]=true}
		if tostring(curUser.iProfile):find("^[%"..class.."]") and tCommands[cmd] then
			local tCmds = {
			["addreguser"] = function(curUser,data)
				Core.SendToUser(curUser,"<"..sBot.."> A parancs le van tiltva, haszn�ld a !regnew <nick> <profil> parancsot.")
				return true
			end,
			["delreguser"] = function(curUser,data)
				Core.SendToUser(curUser,"<"..sBot.."> A parancs le van tiltva, haszn�ld a !regdelete <nick> parancsot.")
				return true
			end,
			["regnew"] = function(curUser, data)
				local nick,class = data:match("^%b<>%s*%p%S+%s(%S+)%s*(%S*)")
				if nick then
					if class == "" then class = "reg" end
					if RegMan.GetReg(nick) then
						Core.SendToUser(curUser,"<"..sBot.."> "..nick.." m�r regisztr�lt ("..(ProfMan.GetProfile((RegMan.GetReg(nick) and RegMan.GetReg(nick).iProfile)) and ProfMan.GetProfile((RegMan.GetReg(nick) and RegMan.GetReg(nick).iProfile)).sProfileName)..") felhaszn�l�. Ha �j "..
						"oszt�lyba szeretn�d regisztr�lni, el�sz�r t�r�ld a !regdelete <nick> paranccsal.")
					else
						if not tRegisteredUsers[nick] then
							if ProfMan.GetProfile(class) and ProfMan.GetProfile(class).iProfileNumber ~= -1 then
								if GetPermission(curUser.iProfile,ProfMan.GetProfile(class).iProfileNumber) then
									tRegisteredUsers[nick] = {["nick"] = nick, ["class"] = ProfMan.GetProfile(class).iProfileNumber}
									Core.SendToUser(curUser,"<"..sBot.."> "..nick.." sikeresen regisztr�lva, "..class.." oszt�lyba.")
									local user = Core.GetUser(nick,true)
									if user then
										Core.SendPmToUser(user,sBot,"Regisztr�lva lett�l "..class.." oszt�lyba. "..
										"Add meg a jelszavad a +passwd <jelsz�> paranccsal. "..
										"Ha nem adsz meg jelsz�t, automatikusan gener�l�dik egy biztons�gos jelsz�. Jelsz� k�sz�t�shez "..
										"haszn�ld a +genpass <hossz> parancsot, ahol a hossz egy 4 �s 20 k�z�tti eg�sz sz�m.")
									end
									tReginfo[nick] = {curUser.sNick,os.time()}
								else
									Core.SendToUser(curUser,"<"..sBot.."> Nincs jogod a m�velet v�grehajt�s�hoz!")
								end
							else
								local profiles = {}
								for k,v in pairs(ProfMan.GetProfiles()) do
									table.insert(profiles,k.sProfileName)
								end
								Core.SendToUser(curUser,"<"..sBot.."> Nincsen "..class.." nev� felhaszn�l�i oszt�ly. (Haszn�lhat�ak: "..table.concat(profiles,", ")..")")
							end
						else
							Core.SendToUser(curUser,"<"..sBot.."> "..nick.." m�r regisztr�lva van.")
						end
					end
				else
					Core.SendToUser(curUser,"<"..sBot.."> A parancs haszn�lata: !regnew <n�v> <oszt�ly>")
				end
				return true
			end,
			["regdelete"] = function(curUser,data)
				local nick = data:match("^%b<>%s*%p%S+%s(%S+)$")
				if nick then
					if tRegisteredUsers[nick] then
						if GetPermission(curUser.iProfile,tRegisteredUsers[nick]["class"]) then
							tRegisteredUsers[nick] = nil
							tReginfo[nick] = nil
							Core.SendToUser(curUser,"<"..sBot.."> "..nick.." regisztr�ci�ja t�r�lve.")
						else
							Core.SendToUser(curUser,"<"..sBot.."> Nincs jogod a m�velet v�grehajt�s�hoz!")
						end
					elseif RegMan.GetReg(nick) then
						if GetPermission(curUser.iProfile,RegMan.GetReg(nick).iProfile) then
							RegMan.DelReg(nick)
							tReginfo[nick] = nil
							RegMan.Save()
							Core.SendToUser(curUser,"<"..sBot.."> "..nick.." regisztr�ci�ja t�r�lve.")
						else
							Core.SendToUser(curUser,"<"..sBot.."> Nincs jogod a m�velet v�grehajt�s�hoz!")
						end
					else
						Core.SendToUser(curUser,"<"..sBot.."> "..nick.." nincs a regisztr�lt felhaszn�l�k list�j�n.")
					end
				else
					Core.SendToUser(curUser,"<"..sBot.."> A parancs haszn�lata: !regdelete <nick>")
				end
				return true
			end,
			["reglist"] = function(curUser,data)
				local profile = data:match("^%b<>%s*%p%S+%s(%S+)$")
				if not profile then
					if GetSize(tRegisteredUsers) > 0 then
						local msg = {"Jelenleg regisztr�lt, de m�g jelszavukat be nem �ll�t� felhaszn�l�k list�ja:\r\n"}
						for k in pairs(tRegisteredUsers) do
							table.insert(msg,"\149 "..tRegisteredUsers[k]["nick"].." - "..(ProfMan.GetProfile(tRegisteredUsers[k]["class"]) and ProfMan.GetProfile(tRegisteredUsers[k]["class"]).sProfileName).."\r\n")
						end
						Core.SendPmToUser(curUser,sBot,table.concat(msg))
					else
						Core.SendPmToUser(curUser,sBot,"A regisztr�lt, de m�g jelszavukat be nem �ll�t� felhaszn�l�k list�ja �res.")
					end
				elseif ProfMan.GetProfile(profile) and ProfMan.GetProfile(profile).iProfileNumber <= #ProfMan.GetProfiles() and ProfMan.GetProfile(profile).iProfileNumber ~= -1 then
					local msg = {ProfMan.GetProfile(profile).sProfileName.." oszt�lyba regisztr�lt felhaszn�l�k:\r\n"}
					for i,v in ipairs(RegMan.GetRegs()) do
						if (ProfMan.GetProfile(v.iProfile).sProfileName:lower() == profile:lower()) then
							table.insert(msg,"\149 "..v["sNick"].."\r\n")
						end
					end
					Core.SendPmToUser(curUser,sBot,table.concat(msg))
				elseif profile == "all" then
					local tUsers = {}
					local msg = {"A hubon regisztr�lt �sszes felhaszn�l�:\r\n  Profil\t\tNickn�v\r\n"}
					for i,v in ipairs(RegMan.GetRegs()) do
						tUsers[v["sNick"]] = (ProfMan.GetProfile(v["iProfile"]) and ProfMan.GetProfile(v["iProfile"]).sProfileName)

					end
					for i,v in ipairs(ProfMan.GetProfiles()) do
						table.insert(msg,"\r\n"..string.rep("Z",40).."\r\n\t\t"..v.sProfileName.." felhaszn�l�k\r\n"..string.rep("Z",40).."\r\n")
						for k in SortByKeys(tUsers) do
							local space = "\t\t"
							if #tUsers[k] > 6 then space = "\t" end
							if tUsers[k] == v.sProfileName then
								table.insert(msg," \149 "..tUsers[k]..space..k.."\r\n")
							end
						end
					end
					Core.SendPmToUser(curUser,sBot,table.concat(msg))
				else
				local profiles = {}
				for k,v in pairs(ProfMan.GetProfiles()) do
					table.insert(profiles,k.sProfileName)
				end
				Core.SendPmToUser(curUser,sBot,"Haszn�lat: !reglist [<profil/all>] (El�rhet� profilok: "..table.concat(profiles,", ")..")")
				end
				return true
			end,
			["regpasswd"] = function(curUser,data)
				local nick,passwd = data:match("^%b<>%s*%p%S+%s(%S+)%s*(%S*)")
				if passwd == "" then passwd = PassCode(8) end
				if nick then
					if RegMan.GetReg(nick) then
						if GetPermission(curUser.iProfile,RegMan.GetReg(nick).iProfile) then
							RegMan.ChangeReg(nick,passwd,RegMan.GetReg(nick).iProfile)
							RegMan.Save()
							local user = Core.GetUser(nick)
							if user then
								Core.SendPmToUser(user,sBot,"A jelszavad meg lett v�ltoztatva a k�vetkez�re: "..passwd.." M�dos�tsd adataidat a kedvenc hubokn�l.")
							end
							Core.SendPmToUser(curUser,sBot,nick.." jelszava megv�ltoztatva erre: "..passwd)
						else
							Core.SendPmToUser(curUser,sBot,"Nincs jogod a m�velet v�grehajt�s�hoz!")
						end
					elseif tRegisteredUsers[nick] then
						if GetPermission(curUser.iProfile,tRegisteredUsers[nick]["class"]) then
							RegMan.AddReg(nick,passwd,tRegisteredUsers[nick]["class"])
							tRegisteredUsers[nick] = nil
							local user = Core.GetUser(nick)
							if user then
								Core.SendPmToUser(user,sBot,"A jelszavad be lett �ll�tva: "..passwd.." Add meg a kedvenc hubokn�l.")
							end
							Core.SendPmToUser(curUser,sBot,nick.." jelszava be�ll�tva: "..passwd)
						else
							Core.SendPmToUser(curUser,sBot,"Nincs jogod a m�velet v�grehajt�s�hoz!")
						end
					else
						Core.SendPmToUser(curUser,sBot,nick.." nem regisztr�lt felhaszn�l�, el�sz�r regisztr�lnod kell!")
					end
				else
					Core.SendPmToUser(curUser,sBot,"Haszn�lat: !regpasswd <nick> <jelsz�>")
				end
				return true
			end,
			["reginfo"] = function(curUser,data)
				local nick = data:match("^%b<>%s*%p%S+%s(%S+)")
				if (RegMan.GetReg(nick) or tRegisteredUsers[nick]) and tReginfo[nick] then
					local u = tReginfo[nick]
					local msg = {"Inform�ci�k "..nick.." regisztr�lt felhaszn�l�r�l:"}
					table.insert(msg,"Regisztr�lta: "..(u[1] == "" and "N/A" or u[1]))
					if RegMan.GetReg(nick) then
						table.insert(msg,"Profil: "..ProfMan.GetProfile(RegMan.GetReg(nick).iProfile).sProfileName)
					elseif tRegisteredUsers[nick] then
						table.insert(msg,"Profil: "..ProfMan.GetProfile(tRegisteredUsers[nick].class).sProfileName)
					end
					table.insert(msg,"Regiszt�ci� ideje: "..os.date("%Y. %m. %d. %H:%M:%S",u[2]))
					table.insert(msg,"Utols� bel�p�s ideje: "..os.date("%Y. %m. %d. %H:%M:%S",u[3]))
					if Core.GetUser(nick) then
						table.insert(msg,"Utols� kil�p�s ideje: Jeleneg is online")
					else
						table.insert(msg,"Utols� kil�p�s ideje: "..os.date("%Y. %m. %d. %H:%M:%S",u[4]))
					end
					table.insert(msg,"Utolj�ra haszn�lt IP: "..((not u[5] or u[5] == "") and "N/A" or u[5]).." ("..(u[5] and IP2Country.GetCountryName(u[5]) or "N/A")..")")
					Core.SendToUser(curUser,"<"..SetMan.GetString(21).."> "..table.concat(msg,"\r\n"))
				else
					Core.SendToUser(curUser,"<"..SetMan.GetString(21).."> "..nick.." nem regisztr�lt felhaszn�l�.")
				end
				return true
			end,
			["oldregs"] = function(curUser,data)
				local msg = {"Azok a felhaszn�l�k, akik t�bb, mint 30 napja l�ptek ki a hubr�l:"}
				local u = {}
				for i,v in ipairs(RegMan.GetRegs()) do
					if not tReginfo[v.sNick] and not Core.GetUser(v.sNick) then u[v.sNick] = "Soha" end
				end
				for nick,data in pairs(tReginfo) do
					if data[4] and os.difftime(os.time(),data[4]) > 2592000 then -- 2592000 = 30 days in seconds
						u[nick] = os.date("%Y. %m. %d. %H:%M:%S",data[4])
					end
				end
				if next(u) then
					for a,b in pairs(u) do if RegMan.GetReg(a) then table.insert(msg,a.." (Utols� kil�p�s: "..b..")") end end
					Core.SendToUser(curUser,"<"..SetMan.GetString(21).."> "..table.concat(msg,"\r\n"))
				else
					table.insert(msg,"Nincs ilyen felhaszn�l�.")
					Core.SendToUser(curUser,"<"..SetMan.GetString(21).."> "..table.concat(msg,"\r\n"))
				end
				return true
			end,
			["genpass"] = function(curUser,data)
				local length = data:match("^%p%S+%s(%d+)")
				if length then
					if tonumber(length) <= 20 then
						if tonumber(length) >= 4 then
							Core.SendToUser(curUser,"<"..sBot.."> Gener�lt jelsz�: "..PassCode(tonumber(length)))
						else
							Core.SendToUser(curUser,"<"..sBot.."> A minim�lis jelsz�hossz 4 karakter.")
						end
					else
						Core.SendToUser(curUser,"<"..sBot.."> A maxim�lis jelsz�hossz 20 karakter.")
					end
				else
					Core.SendToUser(curUser,"<"..sBot.."> Gener�lt jelsz�: "..PassCode(8))
				end
				return true
			end,
			}
			--tCmds["rn"] = tCmds["regnew"] tCmds["rd"] = tCmds["regdelete"] tCmds["rl"] = tCmds["reglist"]
			--tCmds["rp"] = tCmds["regpasswd"] tCmds["rc"] = tCmds["regclass"]
			if tCmds[cmd] then
				return tCmds[cmd](curUser,data)
			end
		end
		local tCmds = {
		["passwd"] = function(curUser,data)
			local passwd = data:match("^%b<>%s%p%S+%s(%S+)")
			if tRegisteredUsers[curUser.sNick] then
				if not passwd then passwd = PassCode(8) end
				RegMan.AddReg(curUser.sNick,passwd,tRegisteredUsers[curUser.sNick]["class"])
				RegMan.Save()
				Core.SendPmToUser(curUser,sBot,"Jelszavad be�ll�t�sa sikeres. Jelszavad: "..passwd)
				tRegisteredUsers[curUser.sNick] = nil
			--[[elseif RegMan.GetReg(curUser.sNick) then
				if not passwd then passwd = PassCode(8) end
				RegMan.AddReg(curUser.sNick,passwd,curUser.iProfile)
				Core.SendPmToUser(curUser,sBot,"Jelszavad sikeresen friss�tve. Jelszavad: "..passwd)]]
				return true
			end
		end,
		["genpass"] = function(curUser,data)
			local length = data:match("^%b<>%s%p%S+%s(%d+)")
			if length then
				if tonumber(length) <= 20 then
					if tonumber(length) >= 4 then
						Core.SendPmToUser(curUser,sBot,"Gener�lt jelsz�: "..PassCode(tonumber(length)))
					else
						Core.SendPmToUser(curUser,sBot,"A minim�lis jelsz�hossz 4 karakter.")
					end
				else
					Core.SendPmToUser(curUser,sBot,"A maxim�lis jelsz�hossz 20 karakter.")
				end
			else
				Core.SendPmToUser(curUser,sBot,"Gener�lt jelsz�: "..PassCode(8))
			end
			return true
		end,
		--[==[["regme"] = function(curUser,data)
			local _,_,passwd = string.find(data,"^%p%S+%s(%S+)")
			if RegMan.GetReg(curUser.sNick) then
				Core.SendPmToUser(curUser,sBot,"M�r regisztr�lva vagy mint "..(ProfMan.GetProfile(curUser.iProfile) and ProfMan.GetProfile(curUser.iProfile).sProfileName)..".")
			else
				if tRegisteredUsers[curUser.sNick] then
					Core.SendPmToUser(curUser,sBot,"M�r regisztr�lva vagy, �ll�tsd be a jelszavad a +passwd <jelsz�> paranccsal. "..
					"Ha nem adsz meg jelsz�t, automatikusan gener�l�dik egy biztons�gos jelsz�. Jelsz� k�sz�t�shez haszn�ld a +genpass <hossz> parancsot, ahol a hossz egy 4 �s 20 k�z�tti eg�sz sz�m.")
				else
					if bAutoRegme then
						if passwd then
							RegMan.AddReg(curUser.sNick,passwd,ProfMan.GetProfile("Reg") and ProfMan.GetProfile("Reg").iProfileNumber)
							Core.SendPmToUser(curUser,sBot,"Sikeresen regisztr�ltad magad Reg oszt�lyba a k�vetkez� jelsz�val: "..passwd)
						else
							tRegisteredUsers[curUser.sNick] = {
							["nick"] = curUser.sNick,
							["class"] = ProfMan.GetProfile("Reg") and ProfMan.GetProfile("Reg").iProfileNumber,
							}
							Core.SendPmToUser(curUser,sBot,"Sikeresen regisztr�ltad magad Reg oszt�lyba, �ll�tsd be a jelszavad a +passwd <jelsz�> paranccsal. "..
							"Ha nem adsz meg jelsz�t, automatikusan gener�l�dik egy biztons�gos jelsz�. Jelsz� k�sz�t�shez haszn�ld a +genpass <hossz> parancsot, ahol a hossz egy 4 �s 20 k�z�tti eg�sz sz�m.")
						end
					else
						Core.SendPmToUser(curUser,sBot,"Nem regisztr�lhatod magad, mivel a regme funkci� ki van kapcsolva, k�rj meg egy Oper�tort, hogy regisztr�ljons.")
					end
				end
			end
			return true
		end,]==]
		}
		if tCmds[cmd] then
			return tCmds[cmd](curUser,data)
		end
	end
end

function ToArrival(curUser,data)
	local nickto,data = data:match("^%$To:%s(%S+)%sFrom:%s%S+%s%$(.*)")
	if nickto == sBot then
		ChatArrival(curUser,data)
	end
end

function UserConnected(curUser)
	local nick = curUser.sNick
	if curUser.iProfile == -1 and not tRegisteredUsers[nick] then
		for i,sample in ipairs(evilnicks) do
		    if nick:lower():find(sample) then
				Core.SendToUser(curUser,"<"..SetMan.GetString(21).."> A be�ll�tott nicked \""..nick.."\" nem enged�lyezett elemeket tartalmaz, k�r�nk, v�lassz m�sikat! Ha megvagy, szeretettel v�runk vissza! // Your chosen nick \"" .. nick .. "\" contains invalid elements. Please fix it before reconnecting. Thank you.")
				Core.SendToOpChat("[prefixprotect.lua] User "..nick.." ["..curUser.sIP.."] has invalid nick.")
				Core.Disconnect(curUser)
		    end
		end
	end
	if tRegisteredUsers[nick] then
		Core.SendPmToUser(curUser,sBot,"Regisztr�lva lett�l, add meg a jelszavad MOST! Parancsa: +passwd <jelszavad>"..
		" Ha nem adsz meg jelsz�t, automatikusan gener�l�dik egy biztons�gos jelsz�. Jelsz� k�sz�t�shez haszn�ld a "..
		" +genpass <hossz> parancsot, ahol a hossz egy 4 �s 20 k�z�tti eg�sz sz�m.")
	end
	local msg = "Your info:\r\nNick: "..nick.."\r\n"
	if curUser.iProfile ~= -1 then
		if not tReginfo[nick] then tReginfo[nick] = {"",0} end
		tReginfo[nick][3] = os.time()
		tReginfo[nick][5] = curUser.sIP
		msg = msg.."Class: "..ProfMan.GetProfile(curUser.iProfile).sProfileName.." ("..curUser.iProfile..")".."\r\n"
	end
	msg = msg.."IP: "..curUser.sIP.."\r\nCountry: "..IP2Country.GetCountryName(curUser).."|"
	Core.SendToUser(curUser,"<"..sBot.."> "..msg)
end
OpConnected = UserConnected
RegConnected = UserConnected

function RegDisconnected(curUser)
	local nick = curUser.sNick
	if not tReginfo[nick] then tReginfo[nick] = {"",0} end
	tReginfo[nick][4] = os.time()
end

function OpDisconnected(curUser)
	local nick = curUser.sNick
	if not tReginfo[nick] then tReginfo[nick] = {"",0} end
	tReginfo[nick][4] = os.time()
	local file = io.open(Core.GetPtokaXPath().."scripts/regusers.db","w+")
	Serialize = function(tTable, sTableName, hFile, sTab)
		sTab = sTab or "";
		hFile:write(sTab..sTableName.." = {\n" )
		for key, value in pairs(tTable) do
			local sKey = (type(key) == "string") and string.format("[%q]",key) or string.format("[%d]",key)
			if(type(value) == "table") then
				Serialize(value, sKey, hFile, sTab.."\t")
			else
				local sValue = (type(value) == "string") and string.format("%q",value) or tostring(value)
				hFile:write( sTab.."\t"..sKey.." = "..sValue)
			end
			hFile:write( ",\n")
		end
		hFile:write( sTab.."}")
	end
	Serialize(tRegisteredUsers,"tRegisteredUsers",file)
	file:close()
	local f = io.open(Core.GetPtokaXPath().."scripts/reginfo.db","w+")
	for nick,data in pairs(tReginfo) do
		f:write(nick.."$$"..(data[1] or "").."$$"..(data[2] or "0").."$$"..(data[3] or "0").."$$"..(data[4] or "0").."$$"..(data[5] or "").."\r\n")
	end
	f:close()
end

function OnExit()
	UnregCommand({"regnew","regdelete","reglist","regpasswd","genpass","reginfo","oldregs"})
end

RegCommand("regnew <nick> [<class>]",class,"Felhaszn�l� regisztr�l�sa a megadott oszt�lyba. Ha nincs megadva oszt�ly, automatikusan reg lesz.")
RegCommand("regdelete <nick>",class,"Felhaszn�l� regisztr�ci�j�nak t�rl�se.")
RegCommand("reglist [<profil/all>]",class,"Param�ter n�lk�l megmutatja a regisztr�lt, de m�g jelsz� n�lk�li felhaszn�l�kat. Ha van megadott profil, az adott oszt�llyal rendelkez�"..
		"felhaszn�l�k ker�lnek list�z�sra. Ha a param�ter all, az �sszes regisztr�lt felhaszn�l� ki lesz list�zva, profilonk�nt.")
RegCommand("regpasswd <nick> [<jelsz�>]",class,"Adott felhaszn�l� jelszav�nak be�ll�t�sa / megv�ltoztat�sa. Ha nincs megadva jelsz�, 8 karakteres biztons�gos jelsz� gener�l�dik.")
RegCommand("genpass [<hossz>]",class,"Adott hossz�s�g� biztons�gos jelsz� gener�l�sa. Ha nincs hossz, akkor 8 karakter lesz. (minimum 4, maximum 20 karakter lehet)")
RegCommand("reginfo <nick>",class,"Regisztr�ci�s indorm�ci�k az adott nickr�l.")
RegCommand("oldregs",class,"Kilist�zza a r�g�ta nem haszn�lt regisztr�ci�kat.")