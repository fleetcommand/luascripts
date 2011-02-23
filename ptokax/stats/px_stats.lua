--|---------------------------------------------------------------------|--
--| px_stats.lua                                          2oo8. o2. 12. |--
--| Generates a statistics from the hub in PM and makes a webpage also  |--
--| author: Thor                                                        |--
--| e-mail: ejjeliorjarat@gmail.com                                     |--
--| (c) 2008 All rights reserved, GNU GPL license                       |--
--| Used codes:                                                         |--
--| css from Bluebear's BlueStats program                               |--
--|---------------------------------------------------------------------|--

local iLevel = 0
local iTimer = 10 -- web interface refresh in minutes, 0=disable
local sCSS = "orange_blue" -- The css you prefer


local tLang = {
["users"]        = "felhasználó",
["hubsstatsat"]  = "Az %%s (%%s) hub statisztikái - %Y %B %d %H:%M:%S",
["usersonhub"]   = "%s felhasználó van a hubon (%s operátor)",
["taglessusers"] = "Összesen %s felhasználó tagja nem elérhetõ (így ezek nem szerepelnek a statisztikában sem)",
["usersbymodes"] = "Felhasználók a csatlakozás módja szerint",
["usersbyconn"]  = "Felhasználók kapcsolódás szerint",
["usersbystate"] = "Felhasználók állapot szerint",
["usersareaway"] = "%i felhasználó nincs a gépnél",
["usersbyshare"] = "Felhasználók megosztás mérete szerint",
["usersshare"]   = "A hubon az összmegosztás mérete %s (átlag %s GiB)",
["usersbyhubs"]  = "Felhasználók hubok száma szerint",
["usershubs"]    = "A felhasználók összesen %s hubon vannak (átlag %s hub felhasználónként)",
["usersbyslots"] = "Felhasználók slotszám szerint",
["usersslots"]   = "A felhasználók összesen %s slotot nyitottak (átlag %s slot felhasználónként)",
["usersbyratio"] = "Felhasználók slot/hub arány szerint",
["usersratio"]   = "A felhasználók átlag slot/hub aránya %s slot hubonként",
["usersbylimit"] = "Felhasználók sebességkorlátozás szerint",
["userslimits"]  = "Összesen %s felhasználó korlátozza a sebességét, az átlag %s KiB/s",
["usersnolimit"] = "Senki sem korlátozza a sebességét",
["usersbyopen"]  = "Felhasználók automatikus slotnyitás szerint",
["usersopen"]    = "Összesen %s felhasználó nyit új slotot, ha a sebesség egy megadott érték alá süllyed (átlag %s KiB/s alatt)",
["usersnoopen"]  = "Senki nem nyit új slotot, ha a sebesség egy megadott érték alá esik",
["usersbyclient"]= "Felhasználók kliensek szerint",
["totalusers"]   = "Összes felhasználó",
["usersbycountry"]="Felhasználók országonként",
["countryname"]  = "Ország",
["gentime"]      = "Statisztika létrehozásának ideje: %s mp.",
-- HTML texts
["value"]        = "Érték",
["Users"]        = "Felhasználók",
["prate"]        = "Százalékos érték",
["hubsstats"]    = "A %s hub statisztikái",
["hubsstatsat2"] = "A <a href=\"%%s\">%%s</a> hub statisztikái - %Y. %B %d. %H:%M",
["client"]       = "Kliens",
["version"]      = "Verzió",
["rate"]         = "Arány",
["refreshtime"]  = "Az oldal %s percenként automatikusan frissül",
}


local tSTATS = {
	---- min   | text               | html colour (red,yellow,green)
	tShares = {
		{0,    "0 B",               "red"},
		{1e-5, "0.01 - 9.99 GiB",   "red"},
		{10,   "10 - 19.99 GiB",    "yellow"},
		{20,   "20 - 49.99 GiB",    "yellow"},
		{50,   "50 - 99.99 GiB",    "green"},
		{100,  "100 - 199.99 GiB",  "green"},
		{200,  "200 - 499.99 GiB",  "green"},
		{500,  "500 - 1023.99 Gib", "green"},
		{1024, "1 TiB vagy több",   "green"},
	},
	tHubs = {
		{1,  "1 - 4 hub",           "green"},
		{5,  "5 - 9 hub",           "green"},
		{10, "10 - 14 hub",         "yellow"},
		{15, "15 - 19 hub",         "yellow"},
		{20, "20 - 24 hub",         "yellow"},
		{25, "25 - 29 hub",         "red"},
		{30, "30 - 49 hub",         "red"},
		{50, "50 - 74 hub",         "red"},
		{75, "75 vagy több hub",    "red"},
	},
	tSlots = {
		{0,  "0 - 3 slot",          "yellow"},
		{4,  "4 - 6 slot",          "green"},
		{7,  "7 - 9 slot",          "green"},
		{10, "10 - 19 slot",        "yellow"},
		{20, "20 - 29 slot",        "yellow"},
		{30, "30 - 39 slot",        "red"},
		{40, "40 - 49 slot",        "red"},
		{50, "50 - 74 slot",        "red"},
		{75, "75 vagy több slot",   "red"},
	},
	tRatios = {
		{0,    "0 - 0.19",          "red"},
		{0.2,  "0.2 - 0.49",        "red"},
		{0.5,  "0.5 - 0.74",        "yellow"},
		{0.75, "0.75 - 0.99",       "yellow"},
		{1,    "1 - 1.49",          "green"},
		{1.5,  "1.5 - 1.99",        "green"},
		{2,    "2 - 2.99",          "green"},
		{3,    "3 - 4.99",          "green"},
		{5,    "5 vagy több",       "green"},
	},
	tLimits = {
		{1,   "1 - 9 Kb/s",         "red"},
		{10,  "10 - 19 Kb/s",       "yellow"},
		{20,  "20 - 29 Kb/s",       "yellow"},
		{30,  "30 - 39 Kb/s",       "yellow"},
		{40,  "40 - 79 Kb/s",       "green"},
		{80,  "80 - 99 Kb/s",       "green"},
		{100, "100 - 199 Kb/s",     "green"},
		{200, "200 - 299 Kb/s",     "green"},
		{300, "300 Kb/s vagy magasabb","green"},
	},
	tOpenSlots = {
		{1,   "1 - 5 Kb/s",         "red"},
		{6,   "6 - 9 Kb/s",         "red"},
		{10,  "10 - 19 Kb/s",       "red"},
		{20,  "20 - 29 Kb/s",       "red"},
		{30,  "30 - 39 Kb/s",       "red"},
		{40,  "40 - 79 Kb/s",       "red"},
		{80,  "80 - 99 Kb/s",       "red"},
		{100, "100 - 199 Kb/s",     "red"},
		{200, "200 Kb/s vagy magasabb","red"},
	},
}
-- Don't modify the script under this line, unless you know what are you doing!
function OnStartup()
	iTimer2 = TmrMan.AddTimer(iTimer*60000)
end

local tCommands = {}
local iScriptStart = os.time()
os.setlocale()

local function utf8(text)
	text = text:gsub("\195\169", "\233"):gsub("\195\89", "\201")
	text = text:gsub("\195\161", "\225"):gsub("\195\129", "\193")
	text = text:gsub("\197\177", "\251"):gsub("\197\176", "\219")
	text = text:gsub("\197\145", "\245"):gsub("\197\144", "\213")
	text = text:gsub("\195\186", "\250"):gsub("\195\154", "\218")
	text = text:gsub("\195\182", "\246"):gsub("\195\150", "\214")
	text = text:gsub("\195\188", "\252"):gsub("\195\156", "\220")
	text = text:gsub("\195\179", "\243"):gsub("\195\147", "\211")
	text = text:gsub("\195\173", "\237"):gsub("\195\141", "\205")
	return text
end


local function SortByKeys(t)
	local a,tTemp,i = {},{},0
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a)
	local iter = function ()
		i = i + 1
		return a[i] and a[i], t[a[i]] or nil
	end
	return iter
end

local FormatBytes = function(i)
	i = tonumber(i) or 0
	local j,tUnits = 1, {"B","Kb","Mb","Gb","Tb","Pb","Eb","Yb"}
	while i > 1024 do i = i/1024; j=j+1 end
	return string.format("%.2f",i).." "..(tUnits[j] or "??") 
end

local FormatExactSize = function(i)
	i = tonumber(i) or 0
	local ret,num = "",tostring(i)
	while #num > 0 do
		ret = num:sub(-3,-1).." "..ret
		num = num:sub(1,-4)
	end
	return ret
end

local FormatStatus = function(iStatus)
	iStatus = tonumber(iStatus) or 0
	local status,i = {},iStatus
	if i >= 0x20 then table.insert(status,1,"NAT");      i=i-0x20; end
	if i >= 0x10 then table.insert(status,1,"TLS");      i=i-0x10; end
	if i >= 0x08 then table.insert(status,1,"Fireball"); i=i-0x08; end
	if i >= 0x04 then table.insert(status,1,"Server");   i=i-0x04; end
	if i >= 0x02 then table.insert(status,1,"Away");     i=i-0x02; end
	if i >= 0x01 then table.insert(status,1,"Normal");   i=i-0x01; end
	return (next(status) and table.concat(status," ") or "Unknown").." ("..(iStatus)..")"
end

local FormatTimeDiff = function(i)
	local dateFormat = {{"nap",i/60/60/24},{"óra",i/60/60%24},{"perc",i/60%60},{"másodperc",i%60}}
	local out = {}
	for k, v in ipairs(dateFormat) do
		local val = math.floor(v[2])
		if(val > 0) then
			table.insert(out,(#out > 0 and ', ' or '')..val..' '..v[1])
		end
	end
 
	return table.concat(out)
end

local function GenerateStats()
	local tStats = {}
	tStats.tClients = {}
	tStats.tModes = {}
	tStats.tHubs = {}
	tStats.tSlots = {}
	tStats.tRatios = {}
	tStats.tLimits = {}
	tStats.tStates = {}
	tStats.tOpenSlots = {}
	tStats.tConnections = {}
	tStats.tShares = {}
	tStats.tCountries = {}
    tStats.iTagless = 0
	tStats.iIPless = 0
	tStats.iFullShare = 0
    tStats.iFullHubs = 0
	tStats.iFullSlots = 0
	tStats.iFullLimit = 0
	tStats.iFullOpen = 0
	tStats.iAway = 0
	tStats.iOpCount = #Core.GetOnlineOps()
	tStats.iUserCount = Core.GetUsersCount()
	local usercount = tStats.iUserCount
	local function ParseMyINFO(User)
		local t = {
		sTag = Core.GetUserValue(User,3),
		sConnection = Core.GetUserValue(User,4),
		iMagicByte = Core.GetUserValue(User,24),
		iShareSize = Core.GetUserValue(User,16),
		sClient = Core.GetUserValue(User,6),
		sClientVersion = Core.GetUserValue(User,7),
		sMode = Core.GetUserValue(User,0),
		iHubs = Core.GetUserValue(User,17),
		iSlots = Core.GetUserValue(User,21),
		iRatio = (Core.GetUserValue(User,21) or 0)/(Core.GetUserValue(User,17) or 1),
		iLlimit = Core.GetUserValue(User,22),
		sIP = User.sIP,
		}
		if Core.GetUserValue(User,3):find("O:%d+") then local iOpenSlots = Core.GetUserValue(User,3):match("O:(%d+)") t.iOpenSlots = tonumber(iOpenSlots) end
		return t
	end
	for i,v in ipairs(Core.GetOnlineUsers()) do
		local userdata = ParseMyINFO(v)
		if userdata.sConnection then
			if tStats.tConnections[userdata.sConnection] then
				tStats.tConnections[userdata.sConnection] = tStats.tConnections[userdata.sConnection] + 1
			else
				tStats.tConnections[userdata.sConnection] = 1
			end
		end
		if userdata.iMagicByte then
			if tStats.tStates[userdata.iMagicByte] then
				tStats.tStates[userdata.iMagicByte] = tStats.tStates[userdata.iMagicByte] + 1
			else
				tStats.tStates[userdata.iMagicByte] = 1
			end
			local tAway = {3,7,11,19,23,27,39,47,51,55,59,63,}
			for a,b in ipairs(tAway) do if userdata.iMagicByte == b then tStats.iAway = tStats.iAway + 1 end end
		end
		if userdata.iShareSize then -- Funny if not :-D
			table.insert(tStats.tShares,userdata.iShareSize)
		end
		if userdata.sTag then
			if userdata.sClient and userdata.sClientVersion then
				if tStats.tClients[userdata.sClient] then
					if tStats.tClients[userdata.sClient][userdata.sClientVersion] then
						tStats.tClients[userdata.sClient][userdata.sClientVersion] = tStats.tClients[userdata.sClient][userdata.sClientVersion] + 1
					else
						tStats.tClients[userdata.sClient][userdata.sClientVersion] = 1
					end
				else
					tStats.tClients[userdata.sClient] = {}
					tStats.tClients[userdata.sClient][userdata.sClientVersion] = 1
				end
			end
			if userdata.iHubs then
				table.insert(tStats.tHubs,userdata.iHubs)
			end
			if userdata.iSlots then
				table.insert(tStats.tSlots,userdata.iSlots)
			end
			if userdata.iRatio then
				table.insert(tStats.tRatios,userdata.iRatio)
			end
			if userdata.iLlimit and userdata.iLlimit > 0 then
				table.insert(tStats.tLimits,userdata.iLlimit)
			end
			if userdata.iOpenSlots then
				table.insert(tStats.tOpenSlots,userdata.iOpenSlots)
			end
			if userdata.sMode then
				if tStats.tModes[userdata.sMode] then
					tStats.tModes[userdata.sMode] = tStats.tModes[userdata.sMode] + 1
				else
					tStats.tModes[userdata.sMode] = 1
				end
			end
			if userdata.sIP then
				local IP = userdata.sIP
				local cc,county = IP2Country.GetCountryCode(IP),IP2Country.GetCountryName(IP)
				if tStats.tCountries[county] then
					tStats.tCountries[county][1] = tStats.tCountries[county][1] + 1
				else
					if #cc > 2 then cc = "--" end
					tStats.tCountries[county] = {1,cc}
				end
			else
				tStats.iIPless = tStats.iIPless + 1
			end
		else
			tStats.iTagless = tStats.iTagless + 1
		end
	end
	local r = function(field,i) tStats[field][i] = tStats[field][i] + 1 end
	tStats.aShares = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tShares do
		tStats.iFullShare = tStats.iFullShare + tStats.tShares[i]
		for j=9,1,-1 do
			if tStats.tShares[i]/1073741824 >= tSTATS.tShares[j][1] then r("aShares",j) break end
		end
	end
	tStats.aHubs = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tHubs do
		tStats.iFullHubs = tStats.iFullHubs + tStats.tHubs[i]
		for j=9,1,-1 do
			if tStats.tHubs[i] >= tSTATS.tHubs[j][1] then r("aHubs",j) break end
		end
	end
	tStats.aSlots = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tSlots do
		tStats.iFullSlots = tStats.iFullSlots + tStats.tSlots[i]
		for j=9,1,-1 do
			if tStats.tSlots[i] >= tSTATS.tSlots[j][1] then r("aSlots",j) break end
		end
	end
	tStats.aRatios = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tRatios do
		for j=9,1,-1 do
			if tStats.tRatios[i] >= tSTATS.tRatios[j][1] then r("aRatios",j) break end
		end
	end
	tStats.aLimits = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tLimits do
		tStats.iFullLimit = tStats.iFullLimit + tStats.tLimits[i]
		for j=9,1,-1 do
			if tStats.tLimits[i] >= tSTATS.tLimits[j][1] then r("aLimits",j) break end
		end
	end
	tStats.aOpenSlots = {0,0,0,0,0,0,0,0,0}
	for i=1,#tStats.tOpenSlots do
		tStats.iFullOpen = tStats.iFullOpen + tStats.tOpenSlots[i]
		for j=9,1,-1 do
			if tStats.tOpenSlots[i] >= tSTATS.tOpenSlots[j][1] then r("aOpenSlots",j) break end
		end
	end
	return tStats
end

local function CreateHTML()
	local iStart = os.clock()
	local sUrl = SetMan.GetString(2)..":"..SetMan.GetString(3):sub(SetMan.GetString(3):find("^(%d+)"))
	local sHubname = SetMan.GetString(0)
	if not sUrl:find("://") then sUrl = "dchub://"..sUrl end
	local ret = {}
	local function GetHeader(txt)
	return '\n  <thead>'..
		   '\n    <tr>'..
		   '\n      <th style="width: 30%;">'..txt..'</th>'..
		   '\n      <th style="width: 30%;">'..tLang["value"]..'</th>'..
		   '\n      <th style="width: 20%;">'..tLang["Users"]..'</th>'..
		   '\n      <th style="width: 20%;">'..tLang["prate"]..'</th>'..
		   '\n    </tr>'..
		   '\n  </thead>\n'
	end
	local tStats = GenerateStats()
	local usercount = tStats.iUserCount
	local function p(t,a,n,b) -- table t, array values, int count, bool stateformat
		local i,ret = 1,""
		for k,v in SortByKeys(t) do
			local j = 1
			if n and n>0 then
				j=n
			elseif usercount-tStats.iTagless>0 then
				j = usercount-tStats.iTagless
			end
			local perc1 = ("%.02f"):format((v/j)*100)
			local perc2 = ("%i"):format(tonumber(perc1))
			local val = ((a and ((type(a[i]) == "table" and a[i][2]) or a[i])) or k)
			if b then val = FormatStatus(val) end
			ret = ret..'\n  <tr>'..
			'\n    <td style="width: 40%;"><img src="'..(a and a[i][3] or "blue")..'-v.png" width="'..perc2..'%" height="12" alt="'..perc1..' %" /></td>'..
			'\n    <td class="small" style="width: 20%;">'..val..'</td>'..
			'\n    <td style="width: 20%;">'..v..' '..tLang["users"]..'</td>'..
			'\n    <td style="width: 20%;">'..perc1..' %</td>'..
			'\n  </tr>\n'
			i = i + 1
		end
		return ret
	end
	
	table.insert(ret,'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'..
	'\n<html lang="hu" xmlns="http://www.w3.org/1999/xhtml">'..
	'\n  <head>'..
	'\n    <meta http-equiv="content-type" content="text/html; charset=ISO-8859-2" />'..
	'\n    <title>'..tLang["hubsstats"]:format(sHubname):gsub("<","&lt;"):gsub(">","&gt;")..'</title>')
	if iTimer>0 then
		--table.insert(ret,'\n    <META HTTP-EQUIV="Refresh" CONTENT='..(iTimer*60)..'>')
	end
	table.insert(ret,'\n    <link type="text/css" rel="stylesheet" href="'..sCSS..'.css" />'..
	'\n  </head>'..
	'\n  <body>')
	--'\n  <script type="text/javascript" src="wz_tooltip.js"></script>\n'..
	table.insert(ret,'<h1>'..utf8(os.date(tLang["hubsstatsat2"])):format(sUrl,sHubname:gsub("<","&lt;"):gsub(">","&gt;"))..'</h1>'..
	'\n      <h2>'..tLang["usersonhub"]:format(usercount,tStats.iOpCount)..'</h2>')
	if tStats.iTagless > 0 then
		table.insert(ret,'\n      <p>'..tLang["taglessusers"]:format(tStats.iTagless)..'</p>')
	end
	table.insert(ret,'\n  <table>' .. GetHeader(tLang["usersbymodes"])..
	'\n  <tbody>'..p(tStats.tModes)..'\n</tbody>\n</table>')
	table.insert(ret,'\n  <table>'..GetHeader(tLang["usersbyconn"])..
	'\n  <tbody>'..p(tStats.tConnections)..'\n</tbody>\n</table>'..
	'\n  <table>'..GetHeader(tLang["usersbystate"])..
	'\n  <tbody>'..p(tStats.tStates,nil,usercount,true)..'</tbody>\n</table>')
	table.insert(ret,'\n  <p class="note">'..tLang["usersareaway"]:format(tStats.iAway)..'</p>'..
	'\n  <table>'..GetHeader(tLang["usersbyshare"])..
	'\n  <tbody>'..p(tStats.aShares,tSTATS.tShares,usercount)..'</tbody>\n</table>'..
	'\n  <p class="note">'..tLang["usersshare"]:format(FormatBytes(tStats.iFullShare),("%.02f"):format(tStats.iFullShare/1073741824/usercount)))
	table.insert(ret,'</p>'..
	'\n  <table>'..GetHeader(tLang["usersbyhubs"])..
	'\n  <tbody>'..p(tStats.aHubs,tSTATS.tHubs)..'</tbody>\n</table>'..
	'\n  <p class="note">'..tLang["usershubs"]:format(FormatExactSize(tStats.iFullHubs),("%.02f"):format(tStats.iFullHubs/(usercount-tStats.iTagless)))..'</p>'..
	'\n  <table>'..GetHeader(tLang["usersbyslots"])..
	'\n  <tbody>'..p(tStats.aSlots,tSTATS.tSlots)..'</tbody>\n</table>'..
	'\n  <p class="note">'..tLang["usersslots"]:format(FormatExactSize(tStats.iFullSlots),("%.02f"):format(tStats.iFullSlots/(usercount-tStats.iTagless)))..'</p>'..
	'\n  <table>'..GetHeader(tLang["usersbyratio"])..
	'\n  <tbody>'..p(tStats.aRatios,tSTATS.tRatios)..'</tbody>\n</table>'..
	'\n  <p class="note">'..tLang["usersratio"]:format(("%.02f"):format(tStats.iFullSlots/tStats.iFullHubs))..'</p>')
	if next(tStats.tLimits) then
		local i= #tStats.tLimits
		table.insert(ret,'\n  <table>'..GetHeader(tLang["usersbylimit"])..'\n  <tbody>'..
		p(tStats.aLimits,tSTATS.tLimits,i)..'\n  </tbody>\n</table>\n'..
		'  <p class="note">'..tLang["userslimits"]:format(i,("%.02f"):format(tStats.iFullLimit/i))..'</p>\n')
	else
		table.insert(ret,'\n  <table>\n    <thead>'..tLang["usersnolimit"]..'\n      </thead>\n  </table>\n')
	end
	
	if next(tStats.tOpenSlots) then
		local i = #tStats.tOpenSlots
		table.insert(ret,'\n  <table>'..GetHeader(tLang["usersbyopen"])..'\n  <tbody>')
		table.insert(ret,p(tStats.aOpenSlots,tSTATS.tOpenSlots,i)..'\n  </tbody>\n</table>\n'..
		'  <p class="note">'..tLang["usersopen"]:format(i,("%.02f"):format(tStats.iFullOpen/i))..'</p>\n  ')
	else
		table.insert(ret,'\n  <table>\n    <thead>'..tLang["usersnoopen"]..'\n    </thead>\n  </table>\n  ')
	end
	table.insert(ret,'\n  <table>'..
	'\n  <thead>'..
	'\n  <tr>'..
	'\n    <th colspan="5">'..tLang["usersbycountry"]..'</th>'..
	'\n  </tr>'..
	'\n  <tr>'..
	'\n    <th style="width: 2%;">Flag</th>'..
	'\n    <th style="width: 25%;">'..tLang["countryname"]..'</th>'..
	'\n    <th style="width: 43%;">'..tLang["rate"]..'</th>'..
	'\n    <th style="width: 15%;">'..tLang["Users"]..'</th>'..
	'\n    <th style="width: 15%;">'..tLang["prate"]..'</th>'..
	'\n  </tr>'..
	'\n  </thead>'..
	'\n  <tbody>')
	for country,t in SortByKeys(tStats.tCountries) do
		local p = ("%.02f"):format((t[1]/(usercount-tStats.iIPless))*100)
		if t[2] == "??" then t[2] = "--" end
		local img = "./flags/"..t[2]:lower()..".png"
		table.insert(ret,'\n  <tr>'..
		'\n    <td><img src="'..img..'" alt="'..t[2]..'" /></td>'..
		'\n    <td>'..country..'</td>'..
		'\n    <td><img src="blue-v.png" width="'..math.floor(p)..'%" height="12px" alt="'..p..' %" /></td>'..
		'\n    <td>'..t[1]..' '..tLang["users"]..'</td>'..
		'\n    <td>'..p..' %</td>'..
		'\n  </tr>\n')
	end
	table.insert(ret,'</tbody>\n</table>'..
	'\n  <table>'..
	'\n    <thead>'..
	'\n      <tr>'..
	'\n         <th colspan="6">'..tLang["usersbyclient"]..'</th>'..
	'\n      </tr>\n'..
	'\n      <tr>'..
	'\n         <th style="width: 15%;">'..tLang["client"]..'</th>'..
	'\n         <th style="width: 15%;">'..tLang["version"]..'</th>'..
	'\n         <th style="width: 30%;">'..tLang["rate"]..'</th>'..
	'\n         <th style="width: 15%;">'..tLang["Users"]..'</th>'..
	'\n         <th style="width: 10%;">'..tLang["prate"]..'</th>'..
	'\n         <th style="width: 20%;">'..tLang["totalusers"]..'</th>'..
	'\n      </tr>'..
	'\n    </thead>'..
	'\n    <tbody>\n      <tr>')
	local iCounter = 0
	for client,t in SortByKeys(tStats.tClients) do
		local bAdded = false
		local iCount,iTotal = 0,0
		for a,b in pairs(t) do iCount=iCount+1 iTotal = iTotal + b end
		for version,count in SortByKeys(t) do
			iCounter=iCounter+1
			local td = "client"..(iCounter%2)
			if not bAdded then
				table.insert(ret,'\n         <td rowspan="'..iCount..'">'..client..'</td>')
			end
			local perc = ("%i"):format((count/(usercount-tStats.iTagless))*100)
			table.insert(ret,
			'\n         <td class="'..td..'" style="width: 15%;">'..version..'</td>'..
			'\n         <td class="'..td..'" style="width: 30%;"><img src="blue-v.png" width="'..perc..'%" height="12" alt="'..perc..' %" /></td>'..
			'\n         <td class="'..td..'" style="width: 15%;">'..count..' '..tLang["users"]..'</td>'..
			'\n         <td class="'..td..'" style="width: 10%;">'..("%.02f"):format(perc)..' %</td>')
			if not bAdded then
				table.insert(ret,'\n         <td style="width: 20%; text-align: center;" rowspan="'..iCount..'">'..iTotal..' '..tLang["users"]..'</td>\n      </tr>\n      <tr>')
				bAdded = true
			else
				table.insert(ret,'\n      </tr>\n      <tr>')
			end
		end
	end
	ret[#ret] = ret[#ret]:sub(1,-5)..'\n    </tbody>\n  </table>\n'
	--[==[if tSTATS.bUsers then
		local esc = function(ent)
			return ent:gsub("<","&amp;lt;"):gsub(">","&amp;gt;"):gsub("'","&amp;apos;")
		end
		table.insert(ret,
		'<br />\n<table width="30%" cellpadding="1" cellspacing="2" border="1">'..
		'\n  <tr>'..
		'\n    <td class="headtext" colspan="6">'..tLang["Users"]..'</td>'..
		'\n  </tr>\n')
		for a,user in SortByKeys(tStats["tUsers"]) do 
			if user:isSet("OP") then 
				local tt = '<b>Description:</b> '..esc(user:get("DE"))..'<br />'..
				'<b>Tag:</b> '..esc(user:get("TA"))..'<br />'
				if adc then
					tt=tt..'<b>Status:</b> '..dcpp.Utils.formatClientType(user:get("CT"))..'<br />'
				else
					tt=tt..'<b>Status:</b> '..dcpp.Utils.formatStatus(user:get("CT"))..'<br />'
				end
				tt=tt..'<b>Sharesize:</b> '..dcpp.Utils.formatBytes(user:get("SS"))..' ('..FormatExactSize(user:isSet("SS") and user:get("SS") or 0)..' B)<br />'
				if user:isSet("SF") then
					tt = tt..'<b>Shared files:</b> '..user:get("SF")..'<br />'
				end
				if user:isSet("DS") then
					tt = tt..'<b>Download speed:</b> '..dcpp.Utils.formatBytes(user:get("DS"))..'/s<br />'
				end
				if user:isSet("US") then
					tt = tt..'<b>Upload speed:</b> '..dcpp.Utils.formatBytes(user:get("US"))..'/s<br />'
				end
				local cc=dcpp.Utils.getIpCountry(user:get("I4"))
				tt = tt..'<b>County:</b> <img src=\\\'./flags/'..cc..'.gif\\\'></img> ('..dcpp.Utils.getIpCountry(user:get("I4"),true)..')<br />'
				table.insert(ret,'\n      <tr><td style="text-align: center;"><a style="color: #FF0000;font-weight: bold;" onmouseover="Tip(\''..tt..'\',TITLE,'..
				'\'Informations about '..user:get("NI"):gsub("'","\\'")..'\',BGCOLOR,\''..tSTATS.ttColor..'\')"'..
				'onmouseout="UnTip()" href="#">'..user:get("NI")..'</a></td></tr>')
			end
		end
		for id,user in SortByKeys(tStats["tUsers"]) do
			if not user:isSet("OP") then
				local tt = '<b>Description:</b> '..esc(user:get("DE"))..'<br />'..
				'<b>Tag:</b> '..esc(user:get("TA"))..'<br />'
				if adc then
					tt = tt..'<b>Status:</b> '..dcpp.Utils.formatClientType(user:get("CT"))..'<br />'
				else
					tt = tt..'<b>Status:</b> '..dcpp.Utils.formatStatus(user:get("CT"))..'<br />'
					if user:isSet("CO") then
						tt = tt..'<b>Connection:</b>'..user:get("CO")..'<br />'
					end
				end
				tt=tt..'<b>Sharesize:</b> '..dcpp.Utils.formatBytes(user:get("SS"))..' ('..FormatExactSize(user:isSet("SS") and user:get("SS") or 0)..' B)<br />'
				if user:isSet("SF") then
					tt = tt..'<b>Shared files:</b> '..user:get("SF")..'<br />'
				end
				if user:isSet("DS") then
					tt = tt..'<b>Download speed:</b> '..dcpp.Utils.formatBytes(user:get("DS"))..'/s<br />'
				end
				if user:isSet("US") then
					tt = tt..'<b>Upload speed:</b> '..dcpp.Utils.formatBytes(user:get("US"))..'/s<br />'
				end
				local cc=dcpp.Utils.getIpCountry(user:get("I4"))
				tt = tt..'<b>County:</b> <img src=\\\'./flags/'..cc..'.gif\\\'></img> ('..dcpp.Utils.getIpCountry(user:get("I4"),true)..')<br />'
				table.insert(ret,'\n      <tr><td style="text-align: center;"><a onmouseover="Tip(\''..tt..'\',TITLE,\'Informations about '..
				user:get("NI"):gsub("'","\\'")..'\',BGCOLOR,\''..tSTATS.ttColor..'\')" onmouseout="UnTip()" href="#">'..
				user:get("NI")..'</a></td></tr>')
			end
		end]==]
		--table.insert(ret,'\n  </table>')
	local iCommandCount = 0
	for a,b in pairs(tCommands) do
		if type(b) == "table" then
			for x in pairs(b) do iCommandCount = iCommandCount + b[x] end
		else iCommandCount = iCommandCount + b end
	end
	local function p2(s,i)
		local perc = string.format("%.2f",i/iCommandCount*100)
		local c = "green"
		if tonumber(perc) > 66 then c = "red" elseif tonumber(perc) > 33 then c = "yellow" end
		return '\n      <tr>\n        <td style="width: 25%;">'..s..'</td>\n        <td style="width: 35%;"><img src="'..c..'-v.png" width="'..perc..'%" height="12" alt="'..perc..' %" />'..
		'</td>\n        <td style="width: 15%;">'..i..'</td>\n        <td style="width: 15%;">'..perc..' %</td>\n      </tr>'
	end
	local logins = (tCommands["UserConnected"] or 0) + (tCommands["RegConnected"] or 0) + (tCommands["OpConnected"] or 0)
	table.insert(ret,'\n  <table>\n    <thead>'..
	'\n      <tr>'..
	'\n        <th colspan="5">Parancsok statisztikája '..utf8(os.date("%Y %B %d. %H:%M:%S óta",iScriptStart))..'</th>'..
	'\n      </tr>'..
	'\n      <tr>'..
	'\n        <th style="width: 27%;">Parancs</th>'..
	'\n        <th style="width: 43%;">'..tLang["rate"]..'</th>'..
	'\n        <th style="width: 15%;">'..tLang["value"]..'</th>'..
	'\n        <th style="width: 15%;">'..tLang["prate"]..'</th>'..
	'\n      </tr>'..
	'\n    </thead>'..
	'\n    <tbody>'..
	p2("Felhasználói belépések",tCommands["UserConnected"] or 0)..
	p2("Regisztrált belépések",tCommands["RegConnected"] or 0)..
	p2("Operátori belépések",tCommands["OpConnected"] or 0)..
	p2("Felhasználói kilépések",tCommands["UserDisconnected"] or 0)..
	p2("Regisztrált kilépések",tCommands["RegDisconnected"] or 0)..
	p2("Operátori kilépések",tCommands["OpDisconnected"] or 0)..
	p2("Supports parancsok",tCommands["SupportsArrival"] or 0)..
	p2("Key parancsok",tCommands["KeyArrival"] or 0)..
	p2("ValidateNick parancsok",tCommands["ValidateNickArrival"] or 0)..
	p2("Hublista pinger belépések",tCommands["BotINFOArrival"] or 0)..
	p2("Password parancsok",tCommands["PasswordArrival"] or 0)..
	p2("Version parancsok",tCommands["VersionArrival"] or 0)..
	p2("GetNickList parancsok",tCommands["GetNickListArrival"] or 0)..
	p2("GetINFO parancsok",tCommands["GetINFOArrival"] or 0)..
	p2("MyINFO parancsok",tCommands["OnMyINFO"] or 0)..
	p2("Hibás bejelentkezések/tiltások",((tCommands["SupportsArrival"] or 0) - logins))..
	p2("Közös chat üzenetek",tCommands["ChatArrival"] or 0)..
	p2("Privát üzenetek",tCommands["ToArrival"] or 0)..
	p2("Keresések",tCommands["SearchArrival"] or 0)..
	p2("Passzív keresési találatok",tCommands["SRArrival"] or 0)..
	p2("Aktív csatlakozási kérelmek",tCommands["ConnectToMeArrival"] or 0)..
	p2("Passzív csatlakozási kérelmek",tCommands["RevConnectToMeArrival"] or 0)..
	p2("Átirányítások",tCommands["OpForceMoveArrival"] or 0)..
	p2("Kirúgások",tCommands["KickArrival"] or 0)..
	p2("Szétkapcsolások",tCommands["CloseArrival"] or 0))
	
	local iUnknownCommands = 0
	if tCommands["UnknownArrival"] then
		for cmd in pairs(tCommands["UnknownArrival"]) do
			iUnknownCommands = iUnknownCommands + tCommands["UnknownArrival"][cmd]
		end
	end
	table.insert(ret,p2("Ismeretlen NMDC parancsok",iUnknownCommands))
	local function p3(s,i)
		local perc = string.format("%i",i/iUnknownCommands*100)
		return "\n      <tr>\n        <td width=\"15%\">&nbsp;&nbsp;&nbsp;&nbsp;"..s.."</td>\n        <td width=\"35%\"><img src=\"red-v.png\" width=\""..perc.."%\" height=\"12\" alt=\""..perc.." %\" />"..
		"</td>\n        <td width=\"15%\">"..i.."</td>\n        <td width=\"15%\">"..perc.." %</td>\n      </tr>"
	end
	if iUnknownCommands > 0 then
		table.insert(ret,'\n        <td colspan=\"4\"><strong>Ismeretlen parancsok típusonként:</strong></td>')
		for cmd in SortByKeys(tCommands["UnknownArrival"]) do
			table.insert(ret,p3(cmd,tCommands["UnknownArrival"][cmd]))
		end
	end
	table.insert(ret,'\n    </tbody>\n  </table>')
	if iTimer>0 then
		table.insert(ret,'\n  <p class="timer">'..tLang["refreshtime"]:format(iTimer)..'</p>')
	end
	table.insert(ret,'\n    <p class="footer">by <a href="http://dcpp.hu">Thor</a> &#169; 2008-'..os.date("%Y")..'<br />'..
	'\n    Generated by PtokaX '..Core.Version..' in '..string.format("%.04f",os.clock()-iStart)..' seconds<br />'..
	'\n    Hub uptime: '..FormatTimeDiff(Core.GetUpTime())..'<br />'..
	'\n    Script uptime: '..FormatTimeDiff(os.time()-iScriptStart)..'</p>'..
	'\n  </body>\n</html>')
	return table.concat(ret)
end

local function GetHubStats()
	local ret = {};
	local iStart = os.clock()
	local tStats = GenerateStats()
	local usercount = Core.GetUsersCount()
	local sHubname = SetMan.GetString(0)
	local sHubaddress = SetMan.GetString(2)..":"..SetMan.GetString(3):sub(SetMan.GetString(3):find("^(%d+)"))
	local function p(t,a,n) -- Percentage calculator
		local i,sret = 1,""
		for k,v in SortByKeys(t) do
			local j = 1
			if n and n>0 then j=n
			elseif usercount-tStats.iTagless>0 then j = usercount-tStats.iTagless
			end
			local perc1 = ("%.02f"):format((v/j)*100)
			local perc2 = ("%i"):format(tonumber(perc1))
			sret = sret.."[ "..("["):rep(perc2).."&#124;"..(" "):rep(100-perc2).." ] "..
			((a and ((type(a[i]) == "table" and a[i][2]) or a[i])) or k).." - "..v.." "..tLang["users"]..
			" ("..("%.2f"):format(perc2).." %)\r\n"
			
			i = i + 1
		end
		return sret
	end
	local border = string.rep(string.char(0xAB,0xBB),40)
	table.insert(ret,"\r\n"..border.."\r\n"..utf8(os.date(tLang["hubsstatsat"])):format(sHubname,sHubaddress)..
	"\r\n"..border.."\r\n"..tLang["usersonhub"]:format(usercount,tStats.iOpCount).."\r\n"..border.."\r\n")
	if tStats.iTagless > 0 then
		table.insert(ret,tLang["taglessusers"]:format(tStats.iTagless).."\r\n")
	end
	-- Modes
	table.insert(ret,border.."\r\n"..tLang["usersbymodes"]..":\r\n"..p(tStats.tModes).."\r\n")
	-- Connections
	table.insert(ret,border.."\r\n"..tLang["usersbyconn"]..":\r\n"..p(tStats.tConnections).."\r\n")
	-- States
	table.insert(ret,border.."\r\n"..tLang["usersbystate"]..":\r\n"..p(tStats.tStates,nil,usercount).."\r\n")
	table.insert(ret,tLang["usersareaway"]:format(FormatExactSize(tStats.iAway)).."\r\n"..border.."\r\n")
	-- Shares
	table.insert(ret,tLang["usersbyshare"]..":\r\n"..p(tStats.aShares,tSTATS.tShares,usercount).."\r\n"..tLang["usersshare"]:format(FormatBytes(tStats.iFullShare),
	("%.02f"):format(tStats.iFullShare/1073741824/usercount)).."\r\n"..border.."\r\n")
	-- Hubs
	local div = usercount-tStats.iTagless
	table.insert(ret,tLang["usersbyhubs"]..":\r\n"..p(tStats.aHubs,tSTATS.tHubs).."\r\n"..tLang["usershubs"]:format(FormatExactSize(tStats.iFullHubs),
	("%.02f"):format(tStats.iFullHubs/(div > 0 and div or 1))).."\r\n"..border.."\r\n"..
	-- Slots
	tLang["usersbyslots"]..":\r\n"..p(tStats.aSlots,tSTATS.tSlots).."\r\n"..tLang["usersslots"]:format(FormatExactSize(tStats.iFullSlots),
	("%.02f"):format(tStats.iFullSlots/(div > 0 and div or 1))).."\r\n"..border.."\r\n"..
	-- Ratio
	tLang["usersbyratio"]..":\r\n"..p(tStats.aRatios,tSTATS.tRatios).."\r\n"..tLang["usersratio"]:format(("%.02f"):format(tStats.iFullSlots/(tStats.iFullHubs>0 and tStats.iFullHubs or 1))).."\r\n"..border.."\r\n")
	if next(tStats.tLimits) then
		local i= #tStats.tLimits
		table.insert(ret,tLang["usersbylimit"]..":\r\n"..p(tStats.aLimits,tSTATS.tLimits,i).."\r\n"..
		tLang["userslimits"]:format(i,("%.02f"):format(tStats.iFullLimit/i)).."\r\n"..border.."\r\n")
	else
		table.insert(ret,tLang["usersbylimit"].."\r\n"..tLang["usersnolimit"].."\r\n"..border.."\r\n")
	end
	if next(tStats.tOpenSlots) then
		local i = #tStats.tOpenSlots
		table.insert(ret,tLang["usersbyopen"]..":\r\n"..p(tStats.aOpenSlots,tSTATS.tOpenSlots,i).."\r\n"..
		tLang["usersopen"]:format(i,("%.02f"):format(tStats.iFullOpen/i)).."\r\n"..border.."\r\n")
	else
		table.insert(ret,tLang["usersbyopen"].."\r\n"..tLang["usersnoopen"].."\r\n"..border.."\r\n")
	end
	table.insert(ret,tLang["usersbycountry"]..":\r\n")
	for country,t in SortByKeys(tStats.tCountries) do
		local p = ("%.02f"):format((t[1]/(usercount-tStats.iIPless))*100)
		table.insert(ret," [ "..("["):rep(math.floor(p)).."&#124;"..(" "):rep(100-math.floor(p)).." ] "..country..
		" - "..t[1].." "..tLang["users"].." ("..p.." %)\r\n")
	end
	table.insert(ret,border.."\r\n"..tLang["usersbyclient"]..":\r\n"..border.."\r\n")
	local function ComputeTabs(str)
		if #str < 9 then return str.."\t\t"
		elseif #str < 18 then return str.."\t"
		else return str end
	end
	for client,t in SortByKeys(tStats.tClients) do
		local iTotal = 0
		for a,b in pairs(t) do iTotal = iTotal + b end
		table.insert(ret,client..": ("..iTotal.." "..tLang["users"].." ["..string.format("%.2f",(iTotal/(usercount-tStats.iTagless)*100)).." %])\r\n\t")
		for version,count in SortByKeys(t) do
			table.insert(ret,ComputeTabs(version).." - "..count.." "..tLang["users"].." ("..("%.02f"):format(count/(usercount-tStats.iTagless)*100).." %)\r\n\t")
		end
		ret[#ret] = ret[#ret]:sub(1,-2).."\r\n"
	end
	local logins = (tCommands["UserConnected"] or 0) + (tCommands["RegConnected"] or 0) + (tCommands["OpConnected"] or 0)
	table.insert(ret,"Parancs statisztikák a script futása ("..utf8(os.date("%Y. %B %d. - %H:%M:%S",iScriptStart))..") óta:\r\n"..border.."\r\n"..
	"Felhasználói belépések: "..(tCommands["UserConnected"] or 0).."×\r\n"..
	"Regisztrált belépések: "..(tCommands["RegConnected"] or 0).."×\r\n"..
	"Operátori belépések: "..(tCommands["OpConnected"] or 0).."×\r\n"..
	"Felhasználói kilépések: "..(tCommands["UserDisconnected"] or 0).."×\r\n"..
	"Regisztrált kilépések: "..(tCommands["RegDisconnected"] or 0).."×\r\n"..
	"Operátori kilépések: "..(tCommands["OpDisconnected"] or 0).."×\r\n"..
	"Supports parancsok: "..(tCommands["SupportsArrival"] or 0).."×\r\n"..
	"Key parancsok: "..(tCommands["KeyArrival"] or 0).."×\r\n"..
	"ValidateNick parancsok: "..(tCommands["ValidateNickArrival"] or 0).."×\r\n"..
	"Hublista pinger belépések: "..(tCommands["BotINFOArrival"] or 0).."×\r\n"..
	"Password parancsok: "..(tCommands["PasswordArrival"] or 0).."×\r\n"..
	"Version parancsok: "..(tCommands["VersionArrival"] or 0).."×\r\n"..
	"GetNickList parancsok: "..(tCommands["GetNickListArrival"] or 0).."×\r\n"..
	"GetINFO parancsok: "..(tCommands["GetINFOArrival"] or 0).."×\r\n"..
	"MyINFO parancsok: "..(tCommands["OnMyINFO"] or 0).."×\r\n"..
	"Hibás bejelentkezések/tiltások: "..((tCommands["SupportsArrival"] or 0) - logins).."×\r\n"..
	"Közös chat üzenetek: "..(tCommands["ChatArrival"] or 0).."×\r\n"..
	"Privát üzenetek: "..(tCommands["ToArrival"] or 0).."×\r\n"..
	"Keresések: "..(tCommands["SearchArrival"] or 0).."×\r\n"..
	"Passzív keresési találatok: "..(tCommands["SRArrival"] or 0).."×\r\n"..
	"Aktív csatlakozási kérelmek: "..(tCommands["ConnectToMeArrival"] or 0).."×\r\n"..
	"Passzív csatlakozási kérelmek: "..(tCommands["RevConnectToMeArrival"] or 0).."×\r\n"..
	"Átirányítások: "..(tCommands["OpForceMoveArrival"] or 0).."×\r\n"..
	"Kirúgások: "..(tCommands["KickArrival"] or 0).."×\r\n"..
	"Szétkapcsolások: "..(tCommands["CloseArrival"] or 0).."×\r\n")
	local iUnknownCommands = 0
	if tCommands["UnknownArrival"] then
		for cmd in pairs(tCommands["UnknownArrival"]) do
			iUnknownCommands = iUnknownCommands + tCommands["UnknownArrival"][cmd]
		end
	end
	table.insert(ret,"Ismeretlen NMDC parancsok: "..iUnknownCommands.."×\r\n\t")
	if iUnknownCommands > 0 then
		for cmd in pairs(tCommands["UnknownArrival"]) do
			table.insert(ret,"\t"..cmd.." - "..tCommands["UnknownArrival"][cmd].."× ("..string.format("%.02f",tCommands["UnknownArrival"][cmd]/iUnknownCommands*100).."%)\r\n\t")
		end
	end
	table.insert(ret,border.."\r\n"..tLang["gentime"]:format(("%.04f"):format(os.clock()-iStart)).."\r\n"..border.."\r\n")
	table.insert(ret,"Hub uptime: "..FormatTimeDiff(Core.GetUpTime()).."\r\n")
	table.insert(ret,"Script uptime: "..FormatTimeDiff(os.time()-iScriptStart))
	return table.concat(ret)
end

function OnTimer(iTimer2)
	local f,e = io.open(Core.GetPtokaXPath().."scripts/stat.html","w+")
	if f then
		f:write(CreateHTML())
		f:close()
	end
end

function UserConnected(User)
	if not tCommands["UserConnected"] then tCommands["UserConnected"] = 1 else
	tCommands["UserConnected"] = tCommands["UserConnected"] + 1 end
	return false
end

function RegConnected(User)
	if not tCommands["RegConnected"] then tCommands["RegConnected"] = 1 else
	tCommands["RegConnected"] = tCommands["RegConnected"] + 1 end
	return false
end

function OpConnected(User)
	if not tCommands["OpConnected"] then tCommands["OpConnected"] = 1 else
	tCommands["OpConnected"] = tCommands["OpConnected"] + 1 end
	if User.iProfile == iLevel then
		Core.SendToUser(User,"$UserCommand 1 3 Statisztikák megtekintése$<%[mynick]> !getstat&#124;|")
	end
	return false
end

function UserDisconnected()
	if not tCommands["UserDisconnected"] then tCommands["UserDisconnected"] = 1 else
	tCommands["UserDisconnected"] = tCommands["UserDisconnected"] + 1 end
	return false
end

function RegDisconnected()
	if not tCommands["RegDisconnected"] then tCommands["RegDisconnected"] = 1 else
	tCommands["RegDisconnected"] = tCommands["RegDisconnected"] + 1 end
	return false
end

function OpDisconnected()
	if not tCommands["OpDisconnected"] then tCommands["OpDisconnected"] = 1 else
	tCommands["OpDisconnected"] = tCommands["OpDisconnected"] + 1 end
	return false
end

function SupportsArrival()
	if not tCommands["SupportsArrival"] then tCommands["SupportsArrival"] = 1 else
	tCommands["SupportsArrival"] = tCommands["SupportsArrival"] + 1 end
	return false
end

function KeyArrival()
	if not tCommands["KeyArrival"] then tCommands["KeyArrival"] = 1 else
	tCommands["KeyArrival"] = tCommands["KeyArrival"] + 1 end
	return false
end

function ValidateNickArrival()
	if not tCommands["ValidateNickArrival"] then tCommands["ValidateNickArrival"] = 1 else
	tCommands["ValidateNickArrival"] = tCommands["ValidateNickArrival"] + 1 end
	return false
end

function PasswordArrival()
	if not tCommands["PasswordArrival"] then tCommands["PasswordArrival"] = 1 else
	tCommands["PasswordArrival"] = tCommands["PasswordArrival"] + 1 end
	return false
end

function VersionArrival()
	if not tCommands["VersionArrival"] then tCommands["VersionArrival"] = 1 else
	tCommands["VersionArrival"] = tCommands["VersionArrival"] + 1 end
	return false
end

function GetNickListArrival()
	if not tCommands["GetNickListArrival"] then tCommands["GetNickListArrival"] = 1 else
	tCommands["GetNickListArrival"] = tCommands["GetNickListArrival"] + 1 end
	return false
end

function MyINFOArrival()
	if not tCommands["MyINFOArrival"] then tCommands["MyINFOArrival"] = 1 else
	tCommands["MyINFOArrival"] = tCommands["MyINFOArrival"] + 1 end
	return false
end

function GetINFOArrival()
	if not tCommands["GetINFOArrival"] then tCommands["GetINFOArrival"] = 1 else
	tCommands["GetINFOArrival"] = tCommands["GetINFOArrival"] + 1 end
	return false
end

function ToArrival()
	if not tCommands["ToArrival"] then tCommands["ToArrival"] = 1 else
	tCommands["ToArrival"] = tCommands["ToArrival"] + 1 end
	return false
end

function ConnectToMeArrival()
	if not tCommands["ConnectToMeArrival"] then tCommands["ConnectToMeArrival"] = 1 else
	tCommands["ConnectToMeArrival"] = tCommands["ConnectToMeArrival"] + 1 end
	return false
end

function MultiConnectToMeArrival()
	if not tCommands["MultiConnectToMeArrival"] then tCommands["MultiConnectToMeArrival"] = 1 else
	tCommands["MultiConnectToMeArrival"] = tCommands["MultiConnectToMeArrival"] + 1 end
	return false
end

function RevConnectToMeArrival()
	if not tCommands["RevConnectToMeArrival"] then tCommands["RevConnectToMeArrival"] = 1 else
	tCommands["RevConnectToMeArrival"] = tCommands["RevConnectToMeArrival"] + 1 end
	return false
end

function SearchArrival()
	if not tCommands["SearchArrival"] then tCommands["SearchArrival"] = 1 else
	tCommands["SearchArrival"] = tCommands["SearchArrival"] + 1 end
	return false
end

function MultiSearchArrival()
	if not tCommands["MultiSearchArrival"] then tCommands["MultiSearchArrival"] = 1 else
	tCommands["MultiSearchArrival"] = tCommands["MultiSearchArrival"] + 1 end
	return false
end

function SRArrival()
	if not tCommands["SRArrival"] then tCommands["SRArrival"] = 1 else
	tCommands["SRArrival"] = tCommands["SRArrival"] + 1 end
	return false
end

function KickArrival()
	if not tCommands["KickArrival"] then tCommands["KickArrival"] = 1 else
	tCommands["KickArrival"] = tCommands["KickArrival"] + 1 end
	return false
end

function OpForceMoveArrival()
	if not tCommands["OpForceMoveArrival"] then tCommands["OpForceMoveArrival"] = 1 else
	tCommands["OpForceMoveArrival"] = tCommands["OpForceMoveArrival"] + 1 end
	return false
end

function BotINFOArrival()
	if not tCommands["BotINFOArrival"] then tCommands["BotINFOArrival"] = 1 else
	tCommands["BotINFOArrival"] = tCommands["BotINFOArrival"] + 1 end
	return false
end

function CloseArrival()
	if not tCommands["CloseArrival"] then tCommands["CloseArrival"] = 1 else
	tCommands["CloseArrival"] = tCommands["CloseArrival"] + 1 end
	return false
end

function UnknownArrival(User,data)
	local _,_,cmd = data:find("^(%$%w+)")
	if cmd then
		if not tCommands["UnknownArrival"] then
			tCommands["UnknownArrival"] = {}
			tCommands["UnknownArrival"][cmd] = 1
		else
			if not tCommands["UnknownArrival"][cmd] then
				tCommands["UnknownArrival"][cmd] = 0
			end
			tCommands["UnknownArrival"][cmd] = tCommands["UnknownArrival"][cmd] + 1
		end
	end
	return false
end

function ChatArrival(User,data)
	if not tCommands["ChatArrival"] then tCommands["ChatArrival"] = 1 else
	tCommands["ChatArrival"] = tCommands["ChatArrival"] + 1 end
    data = data:sub(1,-2)
	if User.iProfile==0 then
		if data:find("^%b<> [+!]getstat$") then
			Core.SendPmToUser(User,SetMan.GetString(21),GetHubStats())
			return true
		elseif data:find("^%b<> [+!]getstat html$") then
			local f = io.open(Core.GetPtokaXPath().."scripts/stat.html","wb+")
			if f then
				f:write(CreateHTML())
				f:close()
				Core.SendToUser(User,"<"..SetMan.GetString(21).."> Stat saved.")
			end
			return true
		end
	end
	return false
end