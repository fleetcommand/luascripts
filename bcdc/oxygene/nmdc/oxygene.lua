--// WELCOME AND LICENSE //--
--[[ 
     Oxygene.lua -- Version 1.6a
     Oxygene.lua -- An all-round BCDC++ slotrules and trigger bot for NMDC hubs
     Oxygene.lua -- A.I. for BCDC++ ;)
     Oxygene.lua -- Rev 101, Last modified: Nov 17, 2008

     Copyright (C) 2004-2008 Szabolcs Molnar <fleet@elitemail.hu>
     
     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

--// CHANGELOG //--
--[[
     101/20081117: Fixed: Wrong bandwidth conversion when read from description
     ------------------------------------------------------
     Release: 1.6a
     ------------------------------------------------------
     100/20080610: Replaced mandatory description bandwidth indication with line speed based rules
     099/20071204: Fixed: tokenize function
     098/20070814: Fixed: -chsay parses parameters too
     097/20070731: Fixed: A bug when sending files to main chat from timer
     096/20070731: Fixed: The script no more starts a new line when sending file content to main chat
     ------------------------------------------------------
     Release: 1.5a
     ------------------------------------------------------
     095/20070505: Added: "reversebandwidth" config value and reverse bandwidth order checking
     094/20070504: Fixed: %-signs may have disappeared from processed texts (kick-messages, etc.)
     093/20070415: Fixed: 1,#INF points in hubstat when a user has 0 slots
     092/20070415: Added: minshare config value, so rules are only checked for those who has larger sharesize than minshare
     091/20070328: Fixed: A missing translation on -chcheckhub
     090/20070325: Fixed: Usercount bug
     089/20070228: Triggers: It is possible to use mathematical functions on the right side of expression when working with numbers
     088/20070226: Modified: Made userdata handling a little bit faster
     087/20070220: Fixed: Minimum upload limit the bot asks for will be an integer (it's rounded down)
     086/20070217: Fixed: -chrules ulimit command
     085/20070107: Added: %[userSSshort] variable, some localization
     084/20070102: Fixed: a bug which caused triggers not to work when the interval was set by the -chtrigs add command
     083/20061014: Updated hubstat - including the point statistics of the clients
     082/20061011: Slotrules violation has a pointing system. %[points], %[pointsint] added.
     081/20061011: When checking for bandwidth in description, first it looks for the proper indication. Only accepts it without measurements if not found.
     080/20061007: Fixed so that logging won't fail after a time
     079/20061007: Fixed so that "command" action parses parameters
     078/20060930: Error message is shown when files can't be opened
     077/20060925: If one trigger removes the user from the hub with "kick" or "redirect" action, the other triggers won't be activated for that user
     076/20060709: Added: trigger activation counter, -chtrigs reset command
     ------------------------------------------------------
     Release: 1.4a
     ------------------------------------------------------
     075/20060414: Modified logging
     074/20060414: The scripts automatically upgrades old format triggers
     073/20060412: Modified: New way of handling trigger variables. See documentation for %[...]-variables
     072/20060411: Modified: -chaddhub [hub], -chrmhub [hub] now works with hosts; Added: -chlisthubs; Removed: -chlistip/rmip/addip
     071/20060405: Added manual garbage collection on disconnect from a hub to free up some memory
     070/20060402: Fixed timer-based trigger auto-activation, configuration
     069/20060402: Fixed table sorting
     068/20060401: Updated to Lua 5.1
     ------------------------------------------------------
     Release: 1.3a
     ------------------------------------------------------
     067/20060211: Renamed: checkslot_settings.txt to oxygene_settings.txt
     066/20060207: Added: Raw kick-profiles
     065/20060207: Modified: Renamed the script to Oxygene.lua
     064/20060203: Added: timer-based triggers, <, <= ... between, outof conditions; date, time, ... variables; (1.2a)
     063/20060201: Added: "command" trigger action, %[myNI] parameter
     062/20060129: Modified: -chstat [full]
     061/20060129: Added: Handles error when a file can't be opened. Report goes to OpChat
     060/20060128: Fixed: Now the script correctly identifies Operators, based on $OpList. Requires 0.68something or newer.
     059/20060128: %[opcount] parameter added
     058/20060104: Default slotrules changed (maxhub_kick raised)
     ------------------------------------------------------
     Release: 1.1b
     ------------------------------------------------------
     057/20051231: Added user exceptions (protected users) (1.1b)
     ------------------------------------------------------
     Release: 1.1a
     ------------------------------------------------------
     056/20051229: Trigger intervals added (1.1a)
     055/20051229: Added mainchatfile trigger action (1.0c)
     054/20051027: Fixed %[purenick] parameter (1.0b)
     ------------------------------------------------------
     Release: 1.0a
     ------------------------------------------------------
     053/20051025: Implemented language file support (1.0a)
     052/20051025: Added 'rulesurl' config value, 'rxopchat', 'rxpm' trigger actions, fixed 'pm' trigger action to parse parameters (0.95c)
     051/20051025: Added: rxmainchat trigger action (0.95b)
     050/20050914: Modified "-chtrigs list" to provide a better view when many triggers are used (0.95a)
     049/20050805: Added: begins_with, nbegins_with, ends_with, nends_with trigger conditions; redirect trigger action (0.94a)
     048/20050729: Fixed: A bug which appears when conn_mode used in triggers (thx Zozz for reporting) (0.93b)
     047/20050722: -chtirgs and -chprofiles command added. Old ones removed (0.93a)
     046/20050721: -chnotice command modified (0.92d)
     045/20050721: Added option to disable upload limit checking. See -chgetconfig (0.92c)
     044/20050721: Updated Upload limit checking because of DCGUI indicates per-slot limit (0.92b)
     043/20050717: Now the slot rules are customizable, even the bandwidth limit checking (0.92a)
     042/20050717: -chgetconfig and -chset added, old config removed
     041/20050717: -chrules added, commands in the previous log event are removed and reorganized. Another new: -help [command] (0.91c)
     040/20050716: -chlimit and -chlistrules added
     039/20050716: Some structural modification to prepare variable slot rules (0.91a)
     038/20050701: -chaddhub and -chrmhub commands added (0.90b)
     037/20050515: Now triggers can handle "and" and "or" conditions (0.90a)
     036/20050515: trig: Actions and conditions are removable (0.89f)
     035/20050509: -chconfig modified
     034/20050508: Added: relative path to files when pming them as a trigger (0.89e)
     033/20050508: Added: condition checking to only activating triggers when desired (0.89d)
     032/20050508: Setting for Opchat name added (for using with triggers) (0.89c)
     031/20050507: Fixed: a userinfo bug which caused some special clients not to appear in userlist (robots w/out myinfo...) (0.89b)
     030/20050507: Basic trigger functions added (0.89a)
     029/20050506: Started to work with triggers, not working yet. invalid client checker removed (0.8j_a)
     028/20050420: Added -chsay command to send main chat messages (0.8i)
     027/20050401: Upgraded to run with BCDC++ 0.670 and newer (0.8h)
     026/20050218: Fixed myinfo parsing which caused wrong userdata when the script was used on x-hub with hublinking enabled (0.8g)
     025/20050206: Timer added to make the script wait 2 minutes before auto-PMing and auto-disconnecting (0.8f)
     024/20050117: -chinvalidstate, -chrefresh command added (0.8e)
     023/20050116: Structural changes (0.8d)
     022/20050116: Added "You are being disconnected: " to the start of private message (0.8c)
     021/20041222: Fixed kick message (0.8b)
     020/20041214: Checkhub (-chcheckhub) works fine (0.8a)
     019/20041207: Kick profiles work (0.7g)
     018/20041206: Preparing kick profiles (0.7f)
     017/20041205: Updated settings (0.7e)
     016/20041201: Fixed: private message sending (0.7d)
     015/20041201: Client statistics ordered (0.7c)
     014/20041130: A bug is fixed which appeared when there was many "<" or ">" character in description (0.7b)
     013/20041130: Added: client statistics (0.7a)
     012/20041129: -chnotice command added (0.6b)
     011/20041129: Storing all userinfo in a table, you can get them by using -chgetinfo <nick> command (0.6a)
     010/20041127: Updated logging (0.5b)
     009/20041127: Code and structure clear enough to get a new version (0.5a)
     008/20041117: Invalid client handlers work properly, it's possible to add/remove invalid client conditions. See Readme.
     007/20041111: Preparing trigger functions
     006/20041027: Preparing of invalid client handlers
     005/20041027: Added: invalid client list
     004/20041027: Fixed: logging, sorry :)
]]

--// Do not edit below this line unless you understand what you're doing //--

--// Initialize script //--
DC():RunTimer(1)

--// Helper functions //--

Oxygene = {}
Oxygene.lang = {}
Oxygene.internal = {}
Oxygene.internal.version = "1.6a_101"
Oxygene.internal.settingsfile = DC():GetAppPath() ..  "scripts/oxygene_settings.txt"

function Oxygene.getComma()
	local temp = 11e-1
	temp = tostring(temp)
	temp = string.sub(temp, 2, 2)
	return temp
end

--// Remaining functions //--

function Oxygene.convertToNum(text)
	if text == nil then
		return 0
	end
	local temp = ""
	local badchar = ","
	if Checkslotsettings.commachar == "," then
		badchar = "."
	end
	local pat = "(%" .. badchar .. ")"
	temp = string.gsub(text, pat, Checkslotsettings.commachar)
	local pat2 = "([%-]?[%d]*[%" .. Checkslotsettings.commachar .. "]?[%d]*)(.*)"
	temp = string.gsub(temp, pat2, "%1")
	temp = tonumber(temp)
	if temp == nil then
		temp = 0
	end
	return temp
end

function Oxygene.formatBytes(bytes)
	local ret = bytes
	local me = { [1] = "B", [2] = "KiB", [3] = "MiB", [4] = "GiB", [5] = "TiB"}
	local i = 0
	repeat
		i = i + 1
	until((i >= 5) or ( (bytes / (1024^ (i-1))) < 1024))
	ret = tostring(math.floor(100 * bytes / (1024 ^ (i-1))) / 100) .. " " .. me[i]
	return ret
end

function Oxygene.onOff(variable)
	local ret = "on"
	if (variable == 0) or (variable == nil) or (variable == false) then
		ret = "off"
	end
	return ret
end

function Oxygene.yesNo(variable)
	local ret = "yes"
	if (variable == 0) or (variable == nil) or (variable == false) then
		ret = "no"
	end
	return ret
end

function Oxygene.userCount(hub)
	-- return #hub.oxygene.userlist
	local k = 0
	for i in pairs(hub.oxygene.userlist) do
		k = k + 1
	end
	return k
end

function Oxygene.opCount(hub)
	local count = 0
	for k in pairs(hub.oxygene.userlist) do
		if hub.oxygene.userlist[k].isop then
			count = count + 1
		end
	end
	return count
end

function Oxygene.log(text, logfile)
	if not logfile then
		logfile = Checkslotsettings.logfile
	end
	local o, err = io.open( logfile, "a+" )
	if o then
		o:write( "[" .. os.date("%Y. %m. %d. - %H:%M:%S") .. "] " .. text .. "\n" )
		o:close()
	else
		DC():PrintDebug("Can't open logfile: \"" .. logfile .. "\". Error: " .. err)
	end
end

function Oxygene.saveSettings()
	pickle.store( Oxygene.internal.settingsfile, { Checkslotsettings = Checkslotsettings })
end

function Oxygene.GETSTRING(var)
	return Oxygene._LANG[var]
end

--// Manage configuration //--

function Oxygene.getConfigValue(var)
	return Checkslotsettings.config[var]
end

function Oxygene.getConfig(user)
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt(Oxygene.evaluateVariables("           Configuration\t\t\tOxygene %[chversion]", nil, nil), true)
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	for k in pairs(Checkslotsettings.config) do
		user:sendPrivMsgFmt("           " .. k .. "\t\t\t" .. Checkslotsettings.config[k], true)
	end
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return nil
end

-- returns true if setting's modified. false if remained the same or failed
function Oxygene.setConfig(user, variable, value)
	local modified = false
	local nice = true
	local state = ""
	local oldval = ""
	local vartype = type( Checkslotsettings.config[variable] )

	if vartype == "number" then
		value = Oxygene.convertToNum(value)		
	elseif vartype == "nil" then
		state = "non-existing variable"
		nice = false
	end
	if nice then
		oldval = Checkslotsettings.config[variable]
		Checkslotsettings.config[variable] = value
		Oxygene.saveSettings()
		if oldval ~= value then
			modified = true
		end
	end
	if user then
		if nice then
			user:sendPrivMsgFmt("[" .. vartype .. "][" .. tostring(oldval) .. " >> " .. tostring(Checkslotsettings.config[variable]) .. "] OK", true)
			Oxygene.log( "[CONFIG] " .. user:getNick() .. ": " .. variable .. " = " .. tostring(Checkslotsettings.config[variable]) .. " (" .. tostring(oldval) ..")")
		else
			user:sendPrivMsgFmt("[" .. state .."] Couldn't set value", true)
		end
	end
	return modified
end

--// Manage slotrules //--

function Oxygene.isRuleFor(bw)
	local ret = false
	bw = tonumber(bw)
	for k in ipairs(Checkslotsettings.bwrules) do
		if Checkslotsettings.bwrules[k].bandwidth == bw then
			ret = true
		end
	end
	return ret
end

function Oxygene.sortBwTable()
	local i = #Checkslotsettings.bwrules
	for k = 1, i-1, 1 do
		for l = k+1, i, 1 do
			if Checkslotsettings.bwrules[k].bandwidth > Checkslotsettings.bwrules[l].bandwidth then
				Checkslotsettings.bwrules[k].bandwidth, Checkslotsettings.bwrules[l].bandwidth = Checkslotsettings.bwrules[l].bandwidth, Checkslotsettings.bwrules[k].bandwidth
				Checkslotsettings.bwrules[k].minslot, Checkslotsettings.bwrules[l].minslot = Checkslotsettings.bwrules[l].minslot, Checkslotsettings.bwrules[k].minslot
				Checkslotsettings.bwrules[k].maxslot, Checkslotsettings.bwrules[l].maxslot = Checkslotsettings.bwrules[l].maxslot, Checkslotsettings.bwrules[k].maxslot
				Checkslotsettings.bwrules[k].slotrec, Checkslotsettings.bwrules[l].slotrec = Checkslotsettings.bwrules[l].slotrec, Checkslotsettings.bwrules[k].slotrec
				Checkslotsettings.bwrules[k].maxhub, Checkslotsettings.bwrules[l].maxhub = Checkslotsettings.bwrules[l].maxhub, Checkslotsettings.bwrules[k].maxhub
				Checkslotsettings.bwrules[k].maxhub_kick, Checkslotsettings.bwrules[l].maxhub_kick = Checkslotsettings.bwrules[l].maxhub_kick, Checkslotsettings.bwrules[k].maxhub_kick
			end
		end
	end
	-- put the bw -1 to the end of the list (-1 means "all other bandwidth")
	for k = 1, i-1, 1 do
		if Checkslotsettings.bwrules[k].bandwidth == -1 then
				Checkslotsettings.bwrules[k].bandwidth, Checkslotsettings.bwrules[k+1].bandwidth = Checkslotsettings.bwrules[k+1].bandwidth, Checkslotsettings.bwrules[k].bandwidth
				Checkslotsettings.bwrules[k].minslot, Checkslotsettings.bwrules[k+1].minslot = Checkslotsettings.bwrules[k+1].minslot, Checkslotsettings.bwrules[k].minslot
				Checkslotsettings.bwrules[k].maxslot, Checkslotsettings.bwrules[k+1].maxslot = Checkslotsettings.bwrules[k+1].maxslot, Checkslotsettings.bwrules[k].maxslot
				Checkslotsettings.bwrules[k].slotrec, Checkslotsettings.bwrules[k+1].slotrec = Checkslotsettings.bwrules[k+1].slotrec, Checkslotsettings.bwrules[k].slotrec
				Checkslotsettings.bwrules[k].maxhub, Checkslotsettings.bwrules[k+1].maxhub = Checkslotsettings.bwrules[k+1].maxhub, Checkslotsettings.bwrules[k].maxhub
				Checkslotsettings.bwrules[k].maxhub_kick, Checkslotsettings.bwrules[k+1].maxhub_kick = Checkslotsettings.bwrules[k+1].maxhub_kick, Checkslotsettings.bwrules[k].maxhub_kick
		end
	end
end

function Oxygene.rmBwRule(user, bw)
	local managed = false
	bw = tonumber(bw)
	for k in ipairs(Checkslotsettings.bwrules) do
		if Checkslotsettings.bwrules[k].bandwidth == bw then
			table.remove(Checkslotsettings.bwrules, k)
			managed = true
		end
	end
	if user then
		if managed then
			if Oxygene.setConfig(nil, "slotcheck", "off") then
				user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
			end
			user:sendPrivMsgFmt("OK", true)
		else
			user:sendPrivMsgFmt("The given bandwidth couldn't be removed. See -chrules list", true)
		end
	end
	Oxygene.saveSettings()
	return managed
end

function Oxygene.addBwRule(user, bw, minslot, maxslot, slotrec, maxhub, maxhub_kick)
	local nice = false
	local state = ""
	bw, minslot, maxslot, slotrec, maxhub, maxhub_kick = tonumber(bw), tonumber(minslot), tonumber(maxslot), tonumber(slotrec), tonumber(maxhub), tonumber(maxhub_kick)
	if (bw > 0 or bw == -1) and (minslot > 0) and (maxslot >= minslot) and (slotrec <= maxslot) and (slotrec >= minslot) and (maxhub > 0) and (maxhub_kick >= maxhub) then
		nice = true
	end
	if not nice then
		if user then
			user:sendPrivMsgFmt("Wrong/incorrect parameters. Ensure that maxslot shouldn't be less than minslot, etc. See -help chrules", true)
		end
		return false
	end
	if Oxygene.isRuleFor(bw) then
		state = "overwrite"
		Oxygene.rmBwRule(nil, bw)
	else
		state = "new"
	end
	local temp = {}
	temp.bandwidth = bw
	temp.minslot = minslot
	temp.maxslot = maxslot
	temp.slotrec = slotrec
	temp.maxhub = maxhub
	temp.maxhub_kick = maxhub_kick
	table.insert( Checkslotsettings.bwrules, temp)
	Oxygene.sortBwTable()
	Oxygene.saveSettings()
	if user then
		if Oxygene.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("[" .. state .. "] OK", ture)
	end
	return nil
end

function Oxygene.clearBwRules( user )
	for k = 1, #Checkslotsettings.bwrules, 1 do
		table.remove( Checkslotsettings.bwrules )
	end
	if user then
		if Oxygene.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("OK", true)
	end
	return nil
end

function Oxygene.resetBwRules( user )
	Oxygene.clearBwRules( nil )
	Oxygene.addBwRule( nil, 0.05 ,  2,  2,  2,  2,  4 )
	Oxygene.addBwRule( nil, 0.1  ,  3,  3,  3,  3,  5 )
	Oxygene.addBwRule( nil, 0.2  ,  4,  4,  4,  4,  6 )
	Oxygene.addBwRule( nil, 0.5  ,  4,  6,  5,  6,  8 )
	Oxygene.addBwRule( nil, 1    ,  6,  8,  7,  8,  10 )
	Oxygene.addBwRule( nil, 2    ,  8, 10,  9,  8, 10 )
	Oxygene.addBwRule( nil, 5    , 11, 20, 15,  8, 10 )
	Oxygene.addBwRule( nil, 10   , 18, 35, 25, 10, 12 )
	Oxygene.addBwRule( nil, 20   , 30, 50, 40, 13, 15 )
	Oxygene.addBwRule( nil, 50   , 30, 60, 40, 13, 15 )
	Oxygene.addBwRule( nil, 100  , 30, 75, 40, 13, 15 )
	Oxygene.addBwRule( nil, -1   , 30, 75, 40, 13, 15 )
	Checkslotsettings.bandwidthmultipler = "0.6"
	Checkslotsettings.minulimit = 12
	Checkslotsettings.ulimitbw = 0.1
	Checkslotsettings.minbw = 0.05
	
	if user then
		if Oxygene.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("OK", true)
	end
	return nil
end

function Oxygene.updateConfig()
	local gotupdated = false
	local needtosave = false
	for k in pairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].interval == nil then
			Checkslotsettings.triggers[k].interval = 0
			needtosave = true
		end
		if Checkslotsettings.triggers[k].lastactivation == nil then
			Checkslotsettings.triggers[k].lastactivation = 0
			needtosave = true
		end
		-- rev076
		if (Checkslotsettings.triggers[k].counter == nil) or (Checkslotsettings.triggers[k].counterreset) == nil then
			Checkslotsettings.triggers[k].counter = 0
			Checkslotsettings.triggers[k].counterreset = os.time()
			needtosave = true
		end
	end
	for k in ipairs(Checkslotsettings.kickprofiles) do
		if Checkslotsettings.kickprofiles[k].type == nil then
			Checkslotsettings.kickprofiles[k].type = "c"
			needtosave = true
		end
	end
	-- new in 1.4
	gotupdated = false
	for k in ipairs(Checkslotsettings.triggers) do
		for l in ipairs(Checkslotsettings.triggers[k].conditions) do
			if Checkslotsettings.triggers[k].conditions[l].type == "nick" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[userNI]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "description" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[userDE]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "client_type" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[client_type]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "conn_mode" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[tagM]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "connection" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[connection]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "email" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[userEM]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "chat" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[chat]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "date" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[date]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "time" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[time]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "fulldate" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[fulldate]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "client_ver" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[tagV]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "sharesize" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[userSS]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "hour" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[hour]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "min" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[min]"
				gotupdated = true
			elseif Checkslotsettings.triggers[k].conditions[l].type == "sec" then
				Checkslotsettings.triggers[k].conditions[l].type = "%[sec]"
				gotupdated = true
			end
		end
		if gotupdated then
			for l in ipairs(Checkslotsettings.triggers[k].actions) do
				string.gsub(Checkslotsettings.triggers[k].actions[l].param, "%%%[nick%]", "%%[userNI]")
				string.gsub(Checkslotsettings.triggers[k].actions[l].param, "%%%[purenick%]", "%%[userNIshort]")
			end
			needtosave = true
		end
	end
	if needtosave then
		Oxygene.saveSettings()
	end
	-- gotupdated = false
	return true
end

function Oxygene.initializeSettings()
	-- Set default values if don't exist:
	if not Checkslotsettings then Checkslotsettings = { } end
	if not Checkslotsettings.allowedaddress then Checkslotsettings.allowedaddress = {} end
	if not Checkslotsettings.triggers then Checkslotsettings.triggers = { } end
	if not Checkslotsettings.bandwidthmultipler then Checkslotsettings.bandwidthmultipler = "0.6" end --// 75 %
	if not Checkslotsettings.minulimit then Checkslotsettings.minulimit = 12 end --// 12 KiB/sec
	if not Checkslotsettings.ulimitbw then Checkslotsettings.ulimitbw = 0.1 end --// bandwidth rule only applied for 0.1 and larger line speeds
	if not Checkslotsettings.minbw then Checkslotsettings.minbw = 0.05 end
	if not Checkslotsettings.config then Checkslotsettings.config = { } end
	if not Checkslotsettings.config.slotcheck then Checkslotsettings.config.slotcheck = "off" end
	if not Checkslotsettings.config.needbw then Checkslotsettings.config.needbw = 1 end
	if not Checkslotsettings.config.opchat_name then Checkslotsettings.config.opchat_name = "OpChat" end
	if not Checkslotsettings.config.triggers then Checkslotsettings.config.triggers = 0 end
	if not Checkslotsettings.config.inactivetime then Checkslotsettings.config.inactivetime = 120 end --// 2 minutes
	if not Checkslotsettings.config.ulimitcheck then Checkslotsettings.config.ulimitcheck = 1 end
	if not Checkslotsettings.config.minshare then Checkslotsettings.config.minshare = 0 end
	if not Checkslotsettings.config.rulesurl then Checkslotsettings.config.rulesurl = "http://www.myhub.com/slotrules.asp" end
	if not Checkslotsettings.config.language then Checkslotsettings.config.language = "US" end
	if not Checkslotsettings.config.trigcase then Checkslotsettings.config.trigcase = 0 end
	if not Checkslotsettings.config.reversebandwidth then Checkslotsettings.config.reversebandwidth = 1 end
	--// TODO
	-- if not Checkslotsettings.config.logging then Checkslotsettings.config.logging = 1 end
	
	if not Checkslotsettings.bwrules then
		Checkslotsettings.bwrules = {}
		Oxygene.resetBwRules( nil )
	end
	
	if not Checkslotsettings.userexceptions then Checkslotsettings.userexceptions = {} end
	
	if not Checkslotsettings.kickprofiles then
		Checkslotsettings.kickprofiles = { }
		local temptable = { }
		temptable.name = "RawKick"
		temptable.command = "$To: %[userNI] From: %[myNI] $<%[myNI]> You are being kicked because: %[reason]|<%[myNI]> %[myNI] is kicking %[userNI] because: %[reason]|$Kick %[userNI]|"
		temptable.type = "r"
		table.insert( Checkslotsettings.kickprofiles, temptable )
		temptable = { }
		temptable.name = "verlihub"
		temptable.command = "!drop %[userNI]"
		temptable.type = "c"
		table.insert( Checkslotsettings.kickprofiles, temptable )
		temptable = { }
		temptable.name = "dchpp"
		temptable.command = "+disconnect %[userNI]"
		temptable.type = "c"
		table.insert( Checkslotsettings.kickprofiles, temptable )

	end
	
	if not Checkslotsettings.currentprofile then Checkslotsettings.currentprofile = "RawKick" end
	
	-- this function updates the config file if any changes are made in the structure
	Oxygene.updateConfig()
	
	-- Values which needs a reset everytime
	Checkslotsettings.logfile = DC():GetAppPath() ..  "scripts/oxygene_log.log"
	Checkslotsettings.kicklog = DC():GetAppPath() ..  "scripts/oxygene_kicks.log"
	Checkslotsettings.possibleTrigVariables = Oxygene.getPossibleTrigVariables()
	Checkslotsettings.possibleTrigStrings = Oxygene.getPossibleStringConditions()
	Checkslotsettings.possibleTrigNums = Oxygene.getPossibleNumConditions()
	Checkslotsettings.dcSpeeds = Oxygene.getDcSpeeds()
	
	Checkslotsettings.hasTimerTrig = Oxygene.doesTimerTrigExist() --// 0, 1
	Checkslotsettings.commachar = Oxygene.getComma()
	if not Checkslotsettings.version then
		Checkslotsettings.version = Oxygene.internal.version
	elseif Checkslotsettings.version ~= Oxygene.internal.version then
		Oxygene.log( "[UPDATE] oxygene.lua version changed from " .. Checkslotsettings.version .. " to " .. Oxygene.internal.version .. ". Version will be stored in the setting file on the first change of any setting.")
		Checkslotsettings.version = Oxygene.internal.version
	end
	Checkslotsettings.lastupdated = os.time()
	return 1
end

function Oxygene.resetLanguage()
	Oxygene._LANG = {
		AsWellAs = "as well as",
		BadHubNumber = "you should be at most %1 hubs on instead of %2 (%3)",
		BadSlots = "Our rules ask for %1 slots. Please set the slot number to %2 instead of %3 to provide your long staying on the hub",
		BadUploadLimit = "please set the Upload Limit value to %1 KiB/sec",
		InAddition = "In addition,",
		PleaseIndicateBandwidth = "Please indicate your bandwidth in your client's Description field and set the slots number according to the rules.",
		PerSlot = "per slot",
		ReverseBandwidth = "Your bandwidth indication is in wrong order. You need to put the download bandwidth first followed by the upload bandwidth, not the other way.",
		Rules = "Our rules: ",
		YourSettingsAreWrong = "Your settings are wrong according to our rules: ",
		YourTagIsNotVisible = "Your tag is not visible. This contains important information about your settings. Please turn it on. Thank you.",
		ThisIsAnAutomessage = "This is an automatic message: ",
		GeneralStart = "oxygene.lua: Automatic checking started",
		KickBroadcast = "%1 users have been kicked because of violating slotrules"
	}
	return true
end

function Oxygene.loadLanguage()
	local ret = false
	local filename = DC():GetAppPath() ..  "scripts/oxygene.lang." .. Oxygene.getConfigValue("language") .. ".lua"
	local o = io.open( filename, "r" )
	if o then
		o:close()
		dofile ( filename )
		ret = true
	else
		-- Wrong/Missing language file, set the default values instead
		Oxygene.resetLanguage()
		Oxygene.setConfig(nil, "language", "US")
	end
	return ret
end

function Oxygene.loadSettings()
	local o = io.open( Oxygene.internal.settingsfile, "r" )
	if o then
		dofile( Oxygene.internal.settingsfile )
		o:close()
	else
		o = io.open( DC():GetAppPath() .. "scripts/checkslot_settings.txt", "r" )
		if o then
			dofile( DC():GetAppPath() .. "scripts/checkslot_settings.txt" )
			o:close()
		end
	end
	Oxygene.initializeSettings()
	Oxygene.loadLanguage()
	return 1
end

function Oxygene.isAllowed(hub)
	local allowed = false
	local url = hub:getUrl()
	for k in ipairs(Checkslotsettings.allowedaddress) do
		if url == Checkslotsettings.allowedaddress[k] then
			allowed = true
			break
		end
	end
	return allowed
end

function Oxygene.isAllowedUrl(url)
	local allowed = false
	for k in ipairs(Checkslotsettings.allowedaddress) do
		if url == Checkslotsettings.allowedaddress[k] then
			allowed = true
			break
		end
	end
	return allowed
end

function Oxygene.addUrl(url)
	table.insert(Checkslotsettings.allowedaddress, url)
	Oxygene.saveSettings()
end

function Oxygene.addHub(hub, url)
	if not url then
		-- if no second parameter we try to add the current hub
		url = hub:getUrl()
	end
	local success = false
	if not Oxygene.isAllowedUrl(url) then
		Oxygene.addUrl(url)
		success = true
	end
	return success
end

function Oxygene.rmHub(hub, url)
	if not url then
		-- if no host specified, try to remove the current hub
		url = hub:getUrl()
	end
	local success = false
	if Oxygene.isAllowedUrl(url) then
		for k in ipairs(Checkslotsettings.allowedaddress) do
			if Checkslotsettings.allowedaddress[k] == url then
				table.remove(Checkslotsettings.allowedaddress, k )
			end
		end
		success = true
	else
		success = false
	end
	Oxygene.saveSettings()
	return success
end

function Oxygene.listHubs(hub, user, pm)
	local message = "\n     -----------------------------------------------------\n     Currently allowed hubs:\n     -----------------------------------------------------\n"
	for k in ipairs(Checkslotsettings.allowedaddress) do
		message = message .. "     " .. Checkslotsettings.allowedaddress[k] .. "\n"
	end
	message = message .. "     -----------------------------------------------------"
		if pm then
			user:sendPrivMsgFmt(message, true)
		else
			hub:sendChat(message)
		end
end

function Oxygene.pmOpChat( hub, message )
	hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. message, true)
	return true
end

-- if user is nil, then sends to mainchat; target: "mainchat", "pm" or nil
function Oxygene.sendFile(hub, user, filename, relative, target)
	if relative then
		filename = DC():GetAppPath() .. filename
	end
	local fajl, err = io.open(filename,"r")
	if fajl then
		local szoveg = ""
		szoveg = fajl:read("*l")
		if (not user) or (not target) then
			target = "mainchat"
		end
		local joinedtext = ""
		local firstline = true
		repeat
			if user then
				szoveg = Oxygene.evaluateVariables(szoveg, hub, Oxygene.getUserData( hub, user:getNick() ))
			else
				szoveg = Oxygene.evaluateVariables(szoveg, hub, nil)
			end
			if target == "pm" then
				user:sendPrivMsgFmt( szoveg, true )
			else
				if firstline then
					firstline = false
				else
					joinedtext = joinedtext .. "\n"
				end
				joinedtext = joinedtext .. szoveg
			end
			szoveg = fajl:read("*l")
		until (szoveg == nil)
		fajl:close()
		if target == "mainchat" then
			hub:sendChat(joinedtext)
		end
	else
		hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> [ERROR] Can't open file: \"" .. filename.."\". Error: " .. err, true)
	end
	return true
end

function Oxygene.sendHelp(hub, user)
	Oxygene.sendFile(hub, user, DC():GetAppPath() ..  "scripts/oxygene_help." .. Oxygene.getConfigValue("language") .. ".txt", false, "pm")
	return true
end

function Oxygene.parseMyinfo(nick, myinfo)
	-- cleaning myinfo
	local num = 0
	for k = 1, string.len(myinfo), 1 do
		if string.sub(myinfo, k, k) == "<" then
			num = num + 1
		end
	end
	if num > 1 then
		myinfo = string.gsub(myinfo, "<", ".", num - 1)
	end
	num = 0
	for k = 1, string.len(myinfo), 1 do
		if string.sub(myinfo, k, k) == ">" then
			num = num + 1
		end
	end
	if num > 1 then
		myinfo = string.gsub(myinfo, ">", ".", num - 1)
	end
	local description, tag, connection, email, sharesize = "", "", "", "", 0
	local temp = string.sub(myinfo, 15 + string.len(nick), string.len(myinfo) )
	description = string.gsub(temp, "([^<]*)<?([^>]*)>?%$.%$([^%$]-)%$([^%$]-)%$([^%$]-)%$.*$?", "%1")
	tag = string.gsub(temp, "([^<]*)<?([^>]*)>?%$.%$([^%$]-)%$([^%$]-)%$([^%$]-)%$.*$?", "%2")
	connection = string.gsub(temp, "([^<]*)<?([^>]*)>?%$.%$([^%$]-)%$([^%$]-)%$([^%$]-)%$.*$?", "%3")
	connection = string.sub(connection, 1, string.len(connection)-1)
	email = string.gsub(temp, "([^<]*)<?([^>]*)>?%$.%$([^%$]-)%$([^%$]-)%$([^%$]-)%$.*$?", "%4")
	sharesize = string.gsub(temp, "([^<]*)<?([^>]*)>?%$.%$([^%$]-)%$([^%$]-)%$([^%$]-)%$.*$?", "%5")
	sharesize = tonumber(sharesize)
	return description, tag, connection, email, sharesize
end

function Oxygene.parseTag(tag)
	local client_type, client_ver, conn_mode, hub1, hub2, hub3, slots, auto_open, ul_limit = "", 0, "", 0, 0, 0, 0, 0, 0
	if string.find(tag, " ") then
		client_type = string.gsub(tag, "(.-) (.*)", "%1")
	end
	if string.find(tag, "V:") then
		client_ver = string.gsub(tag, "(.*)V:([%d%.]*)(.*)", "%2")
		client_ver = Oxygene.convertToNum(client_ver)
	end
	if string.find(tag, "M:") then
		conn_mode = string.gsub(tag, "(.*)M:(.)(.*)","%2")
	end
	if string.find(tag, "H:") then
		hub1 = string.gsub(tag, "(.*)H:(%d*)/?(%d*)/?(%d*)(.*)","%2")
		hub2 = string.gsub(tag, "(.*)H:(%d*)/?(%d*)/?(%d*)(.*)","%3")
		hub3 = string.gsub(tag, "(.*)H:(%d*)/?(%d*)/?(%d*)(.*)","%4")
		hub1, hub2, hub3 = Oxygene.convertToNum(hub1), Oxygene.convertToNum(hub2), Oxygene.convertToNum(hub3)
	end
	if string.find(tag, "S:") then
		slots = string.gsub(tag, "(.*)S:([%d]*)(.*)", "%2")
		slots = Oxygene.convertToNum(slots)
	end
	if string.find(tag, "O:") then
		auto_open = string.gsub(tag, "(.*)O:([%d%-]*)(.*)", "%2")
		auto_open = Oxygene.convertToNum(auto_open)
	end
	if string.find(tag, "[BL]:") then
		ul_limit = string.gsub(tag, "(.*)[BL]:([%d%.]*)(.*)", "%2")
		ul_limit = Oxygene.convertToNum(ul_limit)
	end
	return client_type, client_ver, conn_mode, hub1, hub2, hub3, slots, auto_open, ul_limit
end

function Oxygene.toMibits(bw)
	local temp = string.lower(bw)
	local divisor = 1024
	if string.find(temp, "m") then
		divisor = 1
	end
	temp = string.gsub(temp, "(.*)[mk]?", "%1")
	temp = Oxygene.convertToNum(temp)
	return (temp / divisor)
end

function Oxygene.getBw(description)
	local down_bw, up_bw = 0, 0
	
	local found = false
	if string.find( description, "[%d%.%,]+[KkMm][%+]?/[%d%.%,]+[KkMm][%+]?" ) then
		-- Proper indication of bandwidth like: 1M/128K
		down_bw = string.gsub(description, "(.-)([%d%.%,]+[KkMm])[%+]?/([%d%.%,]+[KkMm])[%+]?(.*)", "%2")
		up_bw = string.gsub(description, "(.-)([%d%.%,]+[KkMm])[%+]?/([%d%.%,]+[KkMm])[%+]?(.*)", "%3")
		found = true
	elseif string.find( description, "[%d%.%,]+[KkMm]?[%+]?/[%d%.%,]+[KkMm]?[%+]?") then
		-- Improper indication of bandwidth like: 1000/128
		down_bw = string.gsub(description, "(.-)([%d%.%,]+[KkMm]?)[%+]?/([%d%.%,]+[KkMm]?)[%+]?(.*)", "%2")
		up_bw = string.gsub(description, "(.-)([%d%.%,]+[KkMm]?)[%+]?/([%d%.%,]+[KkMm]?)[%+]?(.*)", "%3")
		found = true
	end

	if found then
		down_bw = Oxygene.toMibits(down_bw)
		up_bw = Oxygene.toMibits(up_bw)
		
		--// Round the bandwidth...
		local selected = 0
		local tempdiff1 = 0
		local tempdiff2 = 0
		local matched = false
		
		for i = 1, (#Checkslotsettings.dcSpeeds - 1) do
			if Checkslotsettings.dcSpeeds[i+1] >= down_bw then
				matched = true
				tempdiff1 = Checkslotsettings.dcSpeeds[i] - down_bw
				tempdiff2 = Checkslotsettings.dcSpeeds[i+1] - down_bw
				if (tempdiff1 < 0) then
					tempdiff1 = tempdiff1 * -1
				end
				if (tempdiff2 < 0) then
					tempdiff2 = tempdiff2 * -1
				end
				if tempdiff1 < tempdiff2 then
					selected = Checkslotsettings.dcSpeeds[i]
				else
					selected = Checkslotsettings.dcSpeeds[i+1]
				end
				break
			end
		end
		
		if matched then
			down_bw = selected
		else
			down_bw = Checkslotsettings.dcSpeeds[#Checkslotsettings.dcSpeeds]
		end
		
		selected = 0
		tempdiff1 = 0
		tempdiff2 = 0
		matched = false
		
		for i = 1, (#Checkslotsettings.dcSpeeds - 1) do
			if Checkslotsettings.dcSpeeds[i+1] >= up_bw then
				matched = true
				tempdiff1 = Checkslotsettings.dcSpeeds[i] - up_bw
				tempdiff2 = Checkslotsettings.dcSpeeds[i+1] - up_bw
				if (tempdiff1 < 0) then
					tempdiff1 = tempdiff1 * -1
				end
				if (tempdiff2 < 0) then
					tempdiff2 = tempdiff2 * -1
				end
				if tempdiff1 < tempdiff2 then
					selected = Checkslotsettings.dcSpeeds[i]
				else
					selected = Checkslotsettings.dcSpeeds[i+1]
				end
				break
			end
		end
		
		if matched then
			up_bw = selected
		else
			up_bw = Checkslotsettings.dcSpeeds[#Checkslotsettings.dcSpeeds]
		end
	end --// if found
	
	return down_bw, up_bw
end

--*****************************
--** TRIGGER functions
--*****************************

-- Resets condition table (needs executing everytime the script starts)
function Oxygene.getPossibleTrigVariables()
	local trigCon = {}
	
	--// Strings
	local tmp = {}
	tmp.name = "%[userNI]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	tmp = {}
	tmp.name = "%[userNIshort]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	tmp = {}
	tmp.name = "%[userDE]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	tmp = {}
	tmp.name = "%[userTAG]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	tmp = {}
	tmp.name = "%[userSSshort]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[client_type]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagVE]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagM]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[connection]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[userEM]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[chat]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[myNI]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[time]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[date]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[fulldate]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	
	--// Numeric conditions
	tmp = {}
	tmp.name = "%[tagV]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagHN]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagHR]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagHO]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagSL]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagB]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[tagO]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[userSS]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[downBW]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[upBW]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[hour]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[min]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[sec]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[usercount]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[opcount]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[points]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[pointsint]"
	tmp.type = "num"
	table.insert( trigCon, tmp)
	
	
	--// Special conditions
	tmp = {}
	tmp.name = "user"
	tmp.type = "special"
	table.insert( trigCon, tmp)
	
	return trigCon
end

function Oxygene.getPossibleNumConditions()
	local trigCon = {}
	
	table.insert( trigCon, "=" )
	table.insert( trigCon, "==" ) --/ it means like the above one, but this is better
	table.insert( trigCon, "!=")
	table.insert( trigCon, "~=")
	table.insert( trigCon, "<")
	table.insert( trigCon, "<=")
	table.insert( trigCon, ">")
	table.insert( trigCon, ">=")
	table.insert( trigCon, "between")
	table.insert( trigCon, "outof")
	
	return trigCon
end

function Oxygene.getDcSpeeds()
	local speeds = {}
	
	speeds[1] =   0.005
	speeds[2] =   0.01
	speeds[3] =   0.02
	speeds[4] =   0.05
	speeds[5] =   0.1
	speeds[6] =   0.2
	speeds[7] =   0.5
	speeds[8] =   1
	speeds[9] =   2
	speeds[10]=   5
	speeds[11]=  10
	speeds[12]=  20
	speeds[13]=  50
	speeds[14]= 100
	
	return speeds
end

function Oxygene.getPossibleStringConditions()
	local trigAct = {}
	
	table.insert( trigAct, "is" )
	table.insert( trigAct, "isnot" )
	table.insert( trigAct, "contains" )
	table.insert( trigAct, "ncontains" )
	table.insert( trigAct, "similar_to" )
	table.insert( trigAct, "nsimilar_to" )
	table.insert( trigAct, "begins_with" )
	table.insert( trigAct, "nbegins_with" )
	table.insert( trigAct, "ends_with" )
	table.insert( trigAct, "nends_with" )
	
	return trigAct
end

-- Return values: "num", "string", "special"; nil if parameter is not found
function Oxygene.getVariableType( parameter )
	local ret = nil
	for k in ipairs(Checkslotsettings.possibleTrigVariables) do
		if Checkslotsettings.possibleTrigVariables[k].name == parameter then
			ret = Checkslotsettings.possibleTrigVariables[k].type
		end
	end
	return ret
end

function Oxygene.isPossibleNumCondition( condition_name )
	local ret = false
	for k in ipairs(Checkslotsettings.possibleTrigNums) do
		if Checkslotsettings.possibleTrigNums[k] == condition_name then
			ret = true
		end
	end
	return ret
end

function Oxygene.isPossibleStringCondition( condition_name )
	local ret = false
	for k in ipairs(Checkslotsettings.possibleTrigStrings) do
		if Checkslotsettings.possibleTrigStrings[k] == condition_name then
			ret = true
		end
	end
	return ret
end

function Oxygene.isVariableBetween( condition_type, value, condition_string )
	local indomain = false
	local pattern = "^([%d%.,]+)\-([%d%.,]+)"
	local invert = false
	if string.find( condition_string, pattern ) then
		local min = Oxygene.convertToNum(string.gsub( condition_string, "^([%d%.,]+)\-([%d%.,]+)$", "%1"))
		local max = Oxygene.convertToNum(string.gsub( condition_string, "^([%d%.,]+)\-([%d%.,]+)$", "%2"))
		-- Check for exceptions
		if max < min then
			invert = true
			min, max = max, min
		end
		if (value >= min) and (value <= max) then
			indomain = true
		end
		if invert then
			indomain = not indomain
		end
	end
	return indomain
end

function Oxygene.isTrigBlocked( triggertable, listener_type )
	local block = false
	local allismissing = true
	local anywrongfound = false

	if listener_type == "INF" then
		for k in ipairs(triggertable.conditions) do
			local ccon = triggertable.conditions[k].type
			if ccon == "%[chat]" then
				anywrongfound = true
				break
			elseif string.find(ccon, "%%%[user.*%]") or string.find(ccon, "%%%[tag.*%]") or ccon == "%[client_type]" or ccon == "%[connection]" or ccon == "%[downBW]" or ccon == "%[upBW]" then
				allismissing = false
			end
		end
	elseif listener_type == "MSG" then
		for k in ipairs(triggertable.conditions) do
			if triggertable.conditions[k].type == "%[chat]" then
				allismissing = false
			end
		end
	elseif listener_type == "timer" then
		-- if the timer listener calls the trigger, it should only activated if doesn't contain any userdata-dependent variable in the condition
		for k in ipairs(triggertable.conditions) do
			local ccon = triggertable.conditions[k].type
			if ccon == "%[date]" or ccon == "%[time]" or ccon == "%[fulldate]" or ccon == "%[hour]" or ccon == "%[min]" or ccon == "%[sec]" then
				allismissing = false
			elseif ccon ~= "%[chversion]" and ccon ~= "%[myNI]" and ccon ~= "%[usercount]" and ccon ~= "%[opcount]" then
				anywrongfound = true
				break
			end
		end
	else
		-- bzz
	end
	if allismissing or anywrongfound then
		block = true
	end
	return block
end

-- return true if timer trigger is found
function Oxygene.doesTimerTrigExist()
	local exists = 0
	for k in ipairs(Checkslotsettings.triggers) do
		if not Oxygene.isTrigBlocked( Checkslotsettings.triggers[k], "timer" ) then
			exists = 1
		end
	end
	return exists
end

-- Getting variables. Return with the value and the type ("string" or "num")
function Oxygene.getValue(variable, hub, userdata)
	local ret, vartype = "", ""
	if userdata then
		if variable == "%[userNI]" then
			ret = userdata.nick
			vartype = "string"
		elseif variable == "%[userNIshort]" then
			ret = userdata.nick
			if string.find( ret, "%[.-%]." ) then
				ret = string.gsub(ret,"%[.-%](.+)","%1")
			end
			vartype = "string"
		elseif variable == "%[userSSshort]" then
			ret = Oxygene.formatBytes(Oxygene.convertToNum(userdata.sharesize))
			vartype = "string"
		elseif variable == "%[userDE]" then
			ret = userdata.description
			vartype = "string"
		elseif variable == "%[userTAG]" then
			ret = userdata.tag.text
			vartype = "string"
		elseif variable == "%[client_type]" then
			ret = userdata.tag.client_type
			vartype = "string"
		elseif variable == "%[tagV]" then
			ret = Oxygene.convertToNum(userdata.tag.client_ver)
			vartype = "num"
		elseif variable == "%[tagVE]" then
			ret = userdata.tag.client_type .. " " .. tostring(userdata.tag.client_ver)
			vartype = "string"
		elseif variable == "%[tagM]" then
			ret = userdata.tag.conn_mode
			vartype = "string"
		elseif variable == "%[tagHN]" then
			ret = Oxygene.convertToNum(userdata.tag.hub1)
			vartype = "num"
		elseif variable == "%[tagHR]" then
			ret = Oxygene.convertToNum(userdata.tag.hub2)
			vartype = "num"
		elseif variable == "%[tagHO]" then
			ret = Oxygene.convertToNum(userdata.tag.hub3)
			vartype = "num"
		elseif variable == "%[tagSL]" then
			ret = Oxygene.convertToNum(userdata.tag.slots)
			vartype = "num"
		elseif variable == "%[tagO]" then
			ret = Oxygene.convertToNum(userdata.tag.auto_open)
			vartype = "num"
		elseif variable == "%[tagB]" then
			ret = Oxygene.convertToNum(userdata.tag.ul_limit)
			vartype = "num"
		elseif variable == "%[connection]" then
			ret = userdata.connection
			vartype = "string"
		elseif variable == "%[userEM]" then
			ret = userdata.email
			vartype = "string"
		elseif variable == "%[userSS]" then
			ret = Oxygene.convertToNum(userdata.sharesize)
			vartype = "num"
		elseif variable == "%[downBW]" then
			ret = Oxygene.convertToNum(userdata.down_bw)
			vartype = "num"
		elseif variable == "%[upBW]" then
			ret = Oxygene.convertToNum(userdata.up_bw)
			vartype = "num"
		elseif variable == "%[hour]" then
			ret = Oxygene.convertToNum(os.date("%H"))
			vartype = "num"
		elseif variable == "%[min]" then
			ret = Oxygene.convertToNum(os.date("%M"))
			vartype = "num"
		elseif variable == "%[sec]" then
			ret = Oxygene.convertToNum(os.date("%S"))
			vartype = "num"
		elseif variable == "%[chat]" then
			ret = userdata.chatmsg
			vartype = "string"
		elseif variable == "%[date]" then
			ret = os.date("%Y%m%d")
			vartype = "string"
		elseif variable == "%[time]" then
			ret = os.date("%H%M%S")
			vartype = "string"
		elseif variable == "%[fulldate]" then
			ret = os.date("%Y%m%d%H%M%S")
			vartype = "string"
		elseif variable == "%[chversion]" then
			ret = Checkslotsettings.version
			vartype = "string"
		elseif variable == "%[points]" then
			ret = userdata.diffrules
			vartype = "num"
		elseif variable == "%[pointsint]" then
			ret = math.floor(userdata.diffrules)
			vartype = "num"
		else
			ret = nil
		end
	else
		if variable == "%[hour]" then
			ret = Oxygene.convertToNum(os.date("%H"))
			vartype = "num"
		elseif variable == "%[min]" then
			ret = Oxygene.convertToNum(os.date("%M"))
			vartype = "num"
		elseif variable == "%[sec]" then
			ret = Oxygene.convertToNum(os.date("%S"))
			vartype = "num"
		elseif variable == "%[date]" then
			ret = os.date("%Y%m%d")
			vartype = "string"
		elseif variable == "%[time]" then
			ret = os.date("%H%M%S")
			vartype = "string"
		elseif variable == "%[fulldate]" then
			ret = os.date("%Y%m%d%H%M%S")
			vartype = "string"
		elseif variable == "%[chversion]" then
			ret = Checkslotsettings.version
			vartype = "string"
		else
			ret = nil
		end
	end
	if hub then
		if variable == "%[myNI]" then
			ret = hub:getOwnNick()
			vartype = "string"
		elseif variable == "%[usercount]" then
			ret = Oxygene.userCount(hub)
			vartype = "num"
		elseif variable == "%[opcount]" then
			ret = Oxygene.opCount(hub)
			vartype = "num"
		end
	end
	return ret, vartype
end

function Oxygene.evaluateExpression(expression)
	-- DC():PrintDebug("Expression: " .. expression )
	expression = string.gsub(tostring(expression), "([%d]+),([%d]+)", "%1.%2")
	local func = loadstring( "return (" .. expression .. ")")
	local suc, res = pcall(func)
	return suc, res
end

function Oxygene.evaluateVariables(text, hub, userdata)
	local variables = {}
	local modmessage = text
	string.gsub( text, "(%%%[[a-zA-Z_]-%])", function( s ) table.insert( variables, s ) end )
	for k in pairs(variables) do
		local value = Oxygene.getValue(variables[k], hub, userdata)
		if value then
			value = string.gsub(value, "%%", "%%%%")
			local escaped = string.gsub(variables[k], "%]", "%%%]")
			escaped = string.gsub(escaped, "%%%[", "%%%%%%%[")
			-- DC():PrintDebug("XX: " .. escaped)
			modmessage = string.gsub(modmessage, escaped, value)
		end
	end

	-- \[
	modmessage = string.gsub ( modmessage, "\\%[", "[" )
	-- \]
	modmessage = string.gsub ( modmessage, "\\%]", "]" )	
	-- \\
	modmessage = string.gsub ( modmessage, "\\\\", "\\")
	return modmessage
end

-- Checking conditions
function Oxygene.checkTrigger( hub, userdata, triggertable, listener_type )
	local allconditionsmet, tmpfulfilled = true, true
	local anyconditionsmet, retvalue = false, false
	local blocktrigger = Oxygene.isTrigBlocked( triggertable, listener_type )
	if triggertable.state == "-" then
		-- disabled condition, assume as 
		return false
	end
	if blocktrigger then
		return false
	end
	
	-- anyway needs checking...
	
	for k in ipairs(triggertable.conditions) do
		tmpfulfilled = Oxygene.checkCondition(hub, userdata, triggertable.conditions[k], listener_type)
		if not tmpfulfilled then
			allconditionsmet = false
		else
			anyconditionsmet = true
		end
	end
	if triggertable.type == "and" then
		retvalue = allconditionsmet
	elseif triggertable.type == "or" then
		retvalue = anyconditionsmet
	else
		Oxygene.log("#ERR004: " .. triggertable.type .. " is not a valid value.. ")
	end
	return retvalue
end

-- Checking a condition
--// listener_type possible values are: "MSG", "INF", "timer"
function Oxygene.checkCondition(hub, userdata, ctable, listener_type)
	local ctype, ccondition, cwhat = "", "", ""
	local ctemp, vartype, special = "", "num", false
	local fulfilled = false
	
	ctype, ccondition, cwhat = ctable.type, ctable.condition, ctable.what

	--// For debugging reasons:
	local cwhat_original = cwhat

	cwhat = Oxygene.evaluateVariables(cwhat, hub, userdata)

	--// First check for special conditions
	if userdata then
		if ctype == "user" then
			special = true
			if cwhat == "op" then
				if ccondition == "is" then
					if userdata.isop then
						fulfilled = true
					end
				elseif ccondition == "isnot" then
					if not userdata.isop then
						fulfilled = true
					end
				end
			end
		end
		if special then
			return fulfilled
		end
	
		--// Check for regular conditions
		ctemp, vartype = Oxygene.getValue(ctype, hub, userdata)
		if not ctemp then
			Oxygene.log("# STRUCTURE ERROR 1: Invalid condition type [regular]: " .. ctype)
		end
	else
		ctemp, vartype = Oxygene.getValue(ctype, hub, nil)
		if not ctemp then
			Oxygene.log("# STRUCTURE ERROR 1: Invalid condition type [timer][" .. listener_type .."][" .. ctype .. ccondition .. cwhat .. "]: " .. ctype)
		end
	end
	
	if vartype == "string" then
		if Oxygene.getConfigValue("trigcase") == 0 then
			ctemp = string.lower( ctemp )
			cwhat = string.lower( cwhat )
		end
		if ccondition == "is" then
			if ctemp == cwhat then
				fulfilled = true
			end
		elseif ccondition == "isnot" then
			if ctemp ~= cwhat then
				fulfilled = true
			end			
		elseif ccondition == "contains" then
			if string.find(ctemp, cwhat, 1, 1) then
				fulfilled = true
			end
		elseif ccondition == "ncontains" then
			if not string.find(ctemp, cwhat, 1, 1) then
				fulfilled = true
			end			
		elseif ccondition == "similar_to" then
			if string.find(ctemp, cwhat) then
				fulfilled = true
			end
		elseif ccondition == "nsimilar_to" then
			if not string.find(ctemp, cwhat) then
				fulfilled = true
			end
		elseif ccondition == "begins_with" then
			local len = string.len(cwhat)
			if string.sub(ctemp, 1, len) == cwhat then
				fulfilled = true
			end
		elseif ccondition == "nbegins_with" then
			local len = string.len(cwhat)
			if string.sub(ctemp, 1, len) ~= cwhat then
				fulfilled = true
			end
		elseif ccondition == "ends_with" then
			local len = string.len(cwhat)
			local len2 = string.len(ctemp)
			if len2 >= len then
				if string.sub(ctemp, len2 - len + 1, len2) == cwhat then
					fulfilled = true
				end
			end
		elseif ccondition == "nends_with" then
			local len = string.len(cwhat)
			local len2 = string.len(ctemp)
			if len2 >= len then
				if string.sub(ctemp, len2 - len + 1, len2) ~= cwhat then
					fulfilled = true
				end
			end
		else
			Oxygene.log("# STRUCTURE ERROR 2: Invalid condition for " .. ctype .. ": " .. ccondition)
		end
	else
		if ccondition ~= "between" and ccondition ~= "outof" then
			local suc, res = Oxygene.evaluateExpression(cwhat)
			if suc then
				cwhat = res
			else
				local message = "Can't process expression: \"" .. cwhat .. "\". The following error happened: " .. res .. ". The original expression was: " .. cwhat_original
				if hub then
					Oxygene.pmOpChat( hub, message )
				end
				Oxygene.log( message )
			end
		end

		cwhat = string.lower( cwhat )
		local cwhatString = cwhat
		cwhat = Oxygene.convertToNum(cwhat)
		if (ccondition == "==") or (ccondition == "=") or (ccondition == "is") then -- "is": abandoned
			if ctemp == cwhat then
				fulfilled = true
			end
		elseif (ccondition == "~=") or (ccondition == "isnot") then -- "isnot": abandoned
			if ctemp ~= cwhat then
				fulfilled = true
			end
		elseif (ccondition == "<") or (ccondition == "smaller_than") then -- "smaller_that": abandoned
			if ctemp < cwhat then
				fulfilled = true
			end
		elseif ccondition == "<=" then
			if ctemp <= cwhat then
				fulfilled = true
			end
		elseif (ccondition == ">") or (ccondition == "larger_than") then -- "larger_that": abandoned
			if ctemp > cwhat then
				fulfilled = true
			end
		elseif ccondition == ">=" then
			if ctemp >= cwhat then
				fulfilled = true
			end
		elseif ccondition == "between" then
			fulfilled = Oxygene.isVariableBetween( ctype, ctemp, cwhatString )
		elseif ccondition == "outof" then
			fulfilled = not Oxygene.isVariableBetween( ctype, ctemp, cwhatString )
		else
			Oxygene.log("# STRUCTURE ERROR 2: Invalid condition for " .. ctype .. ": " .. ccondition)
		end
	end

	return fulfilled
end

-- do all the actions which stored in the conditions table for a condition
-- NOTE: Returns true if the user was kicked with the "kick" or "redirect" action
function Oxygene.doActions(hub, userdata, triggertable, listener_type)
	local ret = false
	local tempaction, tempparam = "", ""
	if userdata and Oxygene.isNickProtectedAgainst(userdata.nick, "ignorealltriggers") then
	  -- hmmz
	elseif ((os.time() - triggertable.lastactivation) >= triggertable.interval) or (userdata and userdata.isop) or (userdata and Oxygene.isNickProtectedAgainst(userdata.nick, "ignoretriginterval")) then	
	
		for k in ipairs(triggertable.actions) do
			tempaction = triggertable.actions[k].action
			tempparam = triggertable.actions[k].param
			if userdata then
				if tempaction == "kick" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					Oxygene.disconnect(hub, userdata, tempchat)
					ret = true
				elseif tempaction == "mainchat" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					hub:sendChat(tempchat)
				elseif tempaction == "rxmainchat" or tempaction == "rxopchat" or tempaction == "rxpm" then
					local text = Oxygene.evaluateVariables(string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%1"), hub, userdata)
					local searchpattern = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%2")
					local replacestring = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%3")
					local tempchat = string.gsub(text, searchpattern, replacestring)
					tempchat = Oxygene.evaluateVariables(tempchat, hub, userdata)
					if tempaction == "rxmainchat" then
						hub:sendChat(tempchat)
					elseif tempaction == "rxopchat" then
						hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
					else -- rxpm
						hub:sendPrivMsgTo(userdata.nick, "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
					end
				elseif tempaction == "pm" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					hub:sendPrivMsgTo(userdata.nick, "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
				elseif tempaction == "pmfile" then
					Oxygene.sendFile(hub, hub:getUser(userdata.nick), tempparam, true, "pm")
				elseif tempaction == "mainchatfile" then
					Oxygene.sendFile(hub, hub:getUser(userdata.nick), tempparam, true, "mainchat")
				elseif tempaction == "opchat" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
				elseif tempaction == "redirect" then
					tempparam = string.gsub( tempparam, "%$", "&#36;")
					tempparam = string.gsub( tempparam, "|", "&#124;")
					local params = Oxygene.tokenize(tempparam)
					local hubaddr = params[1]
					local reason = Oxygene.evaluateVariables(string.sub( tempparam, string.len(params[1]) + 2, string.len(tempparam) ) , hub, userdata)
					DC():SendHubMessage( hub:getId(), "$OpForceMove $Who:" .. userdata.nick .. "$Where:" .. hubaddr .. "$Msg:" .. reason .. "|" )
					ret = true
				elseif tempaction == "command" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					Oxygene.commandParser( hub, nil, tempchat )
				end
			else
				if tempaction == "command" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, userdata)
					Oxygene.commandParser( hub, nil, tempchat )
				elseif tempaction == "mainchatfile" then
					Oxygene.sendFile(hub, nil, tempparam, true, "mainchat")
				elseif tempaction == "opchat" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, nil)
					hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
				elseif tempaction == "mainchat" then
					local tempchat = Oxygene.evaluateVariables(tempparam, hub, nil)
					hub:sendChat(tempchat)
				elseif tempaction == "rxmainchat" or tempaction == "rxopchat" then
					local text = Oxygene.evaluateVariables(string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%1"), hub, nil)
					local searchpattern = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%2")
					local replacestring = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%3")
					local tempchat = string.gsub(text, searchpattern, replacestring)
					tempchat = Oxygene.evaluateVariables(tempchat, hub, nil)
					if tempaction == "rxmainchat" then
						hub:sendChat(tempchat)
					elseif tempaction == "rxopchat" then
						hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. tempchat, true)
					end
				end
			end
		end
		triggertable.lastactivation = os.time()
		triggertable.counter = triggertable.counter + 1
		Oxygene.saveSettings()
	else
		if listener_type ~= "timer" then
			hub:sendPrivMsgTo(Oxygene.getConfigValue("opchat_name"), "<" .. hub:getOwnNick() .. "> " .. "[REPORT]: Trigger (" .. triggertable.name .. ") ignored for " .. userdata.nick .. " (activating too often)", true)
		end
	end
	return ret
end

-- Call this
function Oxygene.activateTriggers(hub, nick, listener_type)
	-- don't check triggers, if disabled
	if (Checkslotsettings.config.triggers == 0) then
		return false
	end
	local matched = false
	local kicked = false
	local userdata = false
	if nick then
		userdata = Oxygene.getUserData( hub, nick )
	end
	
	for k in ipairs(Checkslotsettings.triggers) do
		matched = Oxygene.checkTrigger(hub, userdata, Checkslotsettings.triggers[k], listener_type)
		if (matched == true) and (kicked == false) then
			kicked = Oxygene.doActions(hub, userdata, Checkslotsettings.triggers[k], listener_type)
		end
	end
	return matched
end

function Oxygene.doesTrigExist(trigname)
	local exist = false
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			exist = true
		end
	end
	return exist
end

function Oxygene.addTrigger(user, trigname, trigtype, interval)
	if not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter: <trig_name>. See -help or documentation.", true)
		end
		return false
	end
	if not trigtype then
		trigtype = "and"
	end
	if not interval then
		interval = 0
	end
	if trigtype ~= "and" and trigtype ~= "or" then
		if user then
			user:sendPrivMsgFmt("Wrong parameter: <type> must be \"and\" or \"or\". See -help or documentation.", true)
		end
		return false	
	end
	if Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger already exist. See -help or -chtrigs list.", true)
		end
		return false
	end
	local temp = {}
	temp.state = "-" -- disabled by default
	temp.name = trigname
	temp.type = trigtype
	temp.conditions = {}
	temp.actions = {}
	temp.interval = tonumber(interval)
	temp.lastactivation = 0
	temp.counter = 0
	temp.counterreset = os.time()
	table.insert(Checkslotsettings.triggers, temp)
	if user then
		user:sendPrivMsgFmt("\"" .. trigname .. "\" added. Use -chtrigs addc or -chtrigs addcondition to add a condition then -chtrigs adda or -chtrigs addaction to add an action to it.", true)
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return true
end

function Oxygene.rmTrigger(user, trigname)
	if not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter: <trigger_name>. See -help or documentation.", true)
		end
		return false
	end
	local managed = false
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. See -chtrigs list or -help.", true)
		end
	end
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			table.remove( Checkslotsettings.triggers, k )
			managed = true
		end
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function Oxygene.setTrigType(user, trigname, parameter)
	local managed = false
	if (not trigname) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return managed
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. Use -chtrigs list or -help instead.", true)
		end
		return managed
	end
	if parameter == "and" or parameter == "or" then
		for k in ipairs(Checkslotsettings.triggers) do
			if Checkslotsettings.triggers[k].name == trigname then
				Checkslotsettings.triggers[k].type = parameter
				managed = true
			end
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameter \"" .. parameter .. "\". Must be \"and\" or \"or\". Use -help or check the documentation.", true)
		end
		return managed	
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function Oxygene.setTrigInterval(user, trigname, parameter)
	local managed = false
	if (not trigname) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return managed
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. Use -chtrigs list or -help instead.", true)
		end
		return managed
	end
	local interval = Oxygene.convertToNum(parameter)
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			Checkslotsettings.triggers[k].interval = interval
			managed = true
		end
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK [".. tostring(interval) .. "]", true)
	end
	return managed
end

function Oxygene.resetTrigCounter(user, trigname)
	if not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter: <trigger_name>. See -help or documentation.", true)
		end
		return false
	end
	local managed = false
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. See -chtrigs list or -help.", true)
		end
	end
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			Checkslotsettings.triggers[k].counter = 0
			Checkslotsettings.triggers[k].counterreset = os.time()
			managed = true
		end
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function Oxygene.trigAddCondition(user, trigname, ctype, condition, parameter)
	local managed = false
	local nicecondition = false
	local temp = {}
	local current_condition = "" --// "string", "num", "special"
	if (not trigname) or (not ctype) or (not condition) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help.", true)
		end
		return false
	end
	
	current_condition = Oxygene.getVariableType( ctype )
	if not current_condition then
		if user then
			user:sendPrivMsgFmt("Wrong variable (" .. ctype .. "). See documentation", true)
		end
	end


	if current_condition == "string" then
		if Oxygene.isPossibleStringCondition( condition ) then
			nicecondition = true
		end
	elseif current_condition == "num" then
		if Oxygene.isPossibleNumCondition( condition ) then
			nicecondition = true
		end
	elseif current_condition == "special" then
		if (ctype == "user") and (condition == "is" or condition == "isnot") and (parameter == "op") then
			nicecondition = true
		end
	else
		if user and current_condition then
			user:sendPrivMsgFmt("#ERR001", true)
		end
		return false
	end
	
	if not nicecondition then
		if current_condition ~= "special" then
			if user then
				user:sendPrivMsgFmt( ctype .. " is a " .. current_condition .. " value. Condition \"" .. condition .. "\" isn't valid for that.", true)
			end
		else
			if user then
				user:sendPrivMsgFmt( ctype .. " is a " .. current_condition .. " value. See documentation.", true)
			end
		end
		return false
	end
	-- Seems to be OK, build the table then add it to the selected trigger
	temp.type = ctype
	temp.condition = condition
	temp.what = parameter
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			table.insert(Checkslotsettings.triggers[k].conditions, temp)
			managed = true
		end
	end
	if not managed then
		if user then
			user:sendPrivMsgFmt("#ERR002", true)
		end
		return managed
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK")
	end
	-- need update
	Checkslotsettings.hasTimerTrig = Oxygene.doesTimerTrigExist()
	return managed
end

function Oxygene.trigAddAction(user, trigname, action, parameter)
	local managed = false
	local niceaction = false
	local temp = {}
	if (not trigname) or (not action) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help.", true)
		end
		return false
	end
	if action == "kick" or action == "mainchat" or action == "pm" or action == "pmfile" or action == "mainchatfile" or action == "opchat" or action == "redirect" or action == "rxmainchat" or action == "rxopchat" or action == "rxpm" or action == "command" then
		niceaction = true
	end
	if not niceaction then
		if user then
			user:sendPrivMsgFmt( action .. " is not a valid action. See -help or documentation for more information", true)
		end
		return false
	end
	-- Check parameters (where needed)
	local params = Oxygene.tokenize(parameter)
	if action == "redirect" and params[2] == nil then
		if user then
			user:sendPrivMsgFmt( "Missing parameter: you need to provide the redirect hub and a reason too", true)
		end
		return false
	elseif action == "rxmainchat" or action == "rxopchat" or action == "rxpm" then
		local temp = string.gsub(parameter, "\".*\"; \".*\"; \".*\"", "ok")
		if temp ~= "ok" then
			user:sendPrivMsgFmt( "Wrong paramters. You need to provide three parameters for regex. See documentation." )
			return false
		else
			user:sendPrivMsgFmt( "Original text: " .. string.gsub(parameter, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%1") )
			user:sendPrivMsgFmt( "SearchPattern: " .. string.gsub(parameter, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%2") )
			user:sendPrivMsgFmt( "ReplaceString: " .. string.gsub(parameter, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%3") )
		end
	end
	-- Everything seems to be nice, add the action..
	temp.action = action
	temp.param = parameter
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			table.insert(Checkslotsettings.triggers[k].actions, temp)
			managed = true
		end
	end
	if not managed then
		if user then
			user:sendPrivMsgFmt("#ERR003", true)
		end
		return managed
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

-- trigtosend possible values: "_NONE", "_ALL", or a name of a trigger
function Oxygene.sendTriggerListTo(user, trigtosend)
	local count, countall, subcount1, subcount2 = 0, 0, 0, 0
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          [Enabled] (Cnt) Name", true)
	if (trigtosend  ~= "_NONE") then
	user:sendPrivMsgFmt("          [Conditions/Actions]", true)
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Checkslotsettings.triggers) do
		countall = countall + 1
		if (trigtosend == "_ALL") or (trigtosend == "_NONE") or (trigtosend == Checkslotsettings.triggers[k].name) then
			count = count + 1
			user:sendPrivMsgFmt("           [" ..Checkslotsettings.triggers[k].state .. "] (" .. tostring(count) .. ") ".. Checkslotsettings.triggers[k].name, true)
			if (trigtosend == "_ALL") or (trigtosend == Checkslotsettings.triggers[k].name) then
				subcount1, subcount2 = 0, 0
				for l in ipairs(Checkslotsettings.triggers[k].conditions) do
					subcount1 = subcount1 + 1
					user:sendPrivMsgFmt("           [C" .. tostring(subcount1) .."] " .. Checkslotsettings.triggers[k].conditions[l].type .. " " .. Checkslotsettings.triggers[k].conditions[l].condition .. " " .. Checkslotsettings.triggers[k].conditions[l].what, true)
				end
				for l in ipairs(Checkslotsettings.triggers[k].actions) do
					subcount2 = subcount2 + 1
					user:sendPrivMsgFmt("           [A" .. tostring(subcount2) .. "] " .. Checkslotsettings.triggers[k].actions[l].action .. ": " .. Checkslotsettings.triggers[k].actions[l].param, true)
				end
			user:sendPrivMsgFmt("                C: " .. tostring(subcount1) .. ", A: " .. tostring(subcount2) .. ", T: " .. Checkslotsettings.triggers[k].type .. ", Interval: " .. tostring(Checkslotsettings.triggers[k].interval) .. ", Activated " .. tostring(Checkslotsettings.triggers[k].counter) .. " times since " .. os.date("%m. %d. %Y. - %H:%M:%S", Checkslotsettings.triggers[k].counterreset), true)
			end
		end
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Total: " .. tostring(count) .. " (of " .. tostring(countall) .. ") triggers listed", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	if (trigtosend  == "_NONE") then
	user:sendPrivMsgFmt("          Note: Use -chtrigs list all command to list all triggers detailed, or -chtrigs list <trigger_name> to see a specified trigger", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	end
	user:sendPrivMsgFmt("OK", true)
	return count
end

function Oxygene.enableTrigger(user, trigname, desiredstate)
	local managed = false
	if (not trigname) or (not desiredstate) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help.", true)
		end
		return false
	end
	if (desiredstate ~= "+") and (desiredstate ~= "-") then
		if user then
			user:sendPrivMsgFmt("The latest parameter should be \"+\" for enabling or \"-\" for disabling trigger", true)
		end
		return false
	end
	for k in ipairs(Checkslotsettings.triggers) do
		if Checkslotsettings.triggers[k].name == trigname then
			Checkslotsettings.triggers[k].state = desiredstate
			managed = true
		end
	end
	Oxygene.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function Oxygene.rmTriggerCondition(user, trigname, num)
	local managed = false
	local cnt = 0
	if not num or not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s), see -help chtrigs or documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help chtrigs.", true)
		end
		return false
	end
	if string.lower(num) == "all" then
		num = "-1"
	end
	local removable = tonumber(num)
	if not removable then
		if user then
			user:sendPrivMsgFmt("Wrong parameter. Last parameter must be a number or \"all\". See -help chtrigs or documentation.", true)
		end
		return false
	end
	if removable == -1 then
		for k in ipairs(Checkslotsettings.triggers) do
			if Checkslotsettings.triggers[k].name == trigname then
				for i = 1, #Checkslotsettings.triggers[k].conditions do
					table.remove(Checkslotsettings.triggers[k].conditions)
					cnt = cnt + 1
				end
				managed = true
			end
		end
	else
		for k in ipairs(Checkslotsettings.triggers) do
			if Checkslotsettings.triggers[k].name == trigname then
				if Checkslotsettings.triggers[k].conditions[removable] then
					table.remove(Checkslotsettings.triggers[k].conditions, removable)
					cnt = cnt + 1
					managed = true
				end
			end
		end
	end
	if user then
		user:sendPrivMsgFmt(tostring(cnt) .. " condition(s) removed succesfully.", true)
		user:sendPrivMsgFmt("OK", true)
	end
	Oxygene.saveSettings()
	-- needs reset
	Checkslotsettings.hasTimerTrig = Oxygene.doesTimerTrigExist()
	return managed
end

function Oxygene.rmTriggerAction(user, trigname, num)
	local managed = false
	local cnt = 0
	if not num or not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s), see -help or documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help chtrigs.", true)
		end
		return false
	end
	if string.lower(num) == "all" then
		num = "-1"
	end
	local removable = tonumber(num)
	if not removable then
		if user then
			user:sendPrivMsgFmt("Wrong parameter. Last parameter must be a number or \"all\". See -help chtrigs or documentation.", true)
		end
		return false
	end
	if not Oxygene.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help chtrigs.", true)
		end
		return false
	end
	if removable == -1 then
		for k in ipairs(Checkslotsettings.triggers) do
			if Checkslotsettings.triggers[k].name == trigname then
				for i = 1, #Checkslotsettings.triggers[k].actions do
					table.remove(Checkslotsettings.triggers[k].actions)
					cnt = cnt + 1
				end
				managed = true
			end
		end
	else
		for k in ipairs(Checkslotsettings.triggers) do
			if Checkslotsettings.triggers[k].name == trigname then
				if Checkslotsettings.triggers[k].actions[removable] then
					table.remove(Checkslotsettings.triggers[k].actions, removable)
					cnt = cnt + 1
					managed = true
				end
			end
		end
	end
	if user then
		user:sendPrivMsgFmt(tostring(cnt) .. " action(s) removed succesfully.", true)
		user:sendPrivMsgFmt("OK", true)
	end
	Oxygene.saveSettings()
	return managed
end

function Oxygene.listExceptions(user)
	local count = 0
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("           Nick patterns", true)
	user:sendPrivMsgFmt("           [M:Mode][K:Protect against kick][S:Ignore Slotrules][A:Ignore all triggers][T:Ignore TrigInterval]", true)
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Checkslotsettings.userexceptions) do
	user:sendPrivMsgFmt("           " .. Checkslotsettings.userexceptions[k].nick .. " [M:" .. tostring(Checkslotsettings.userexceptions[k].mode) .. "][K:" .. tostring(Checkslotsettings.userexceptions[k].againstkick) .. "][S:" .. tostring(Checkslotsettings.userexceptions[k].ignoreslotrules) .. "][A:" .. tostring(Checkslotsettings.userexceptions[k].ignorealltriggers) .. "][T:" .. tostring(Checkslotsettings.userexceptions[k].ignoretriginterval) .. "]", true)
		count = count + 1
	end
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("           Modes: [0: regex][1: partial match][2: exact match]", true)
	user:sendPrivMsgFmt("           Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	return true
end

function Oxygene.doesExceptionExist(exception)
	local matched = false
	for k in ipairs(Checkslotsettings.userexceptions) do
		if Checkslotsettings.userexceptions[k].nick == exception then
			matched = true
		end
	end
	return matched
end

function Oxygene.rmException(exception)
	local success = false
	local debugmsg = "Exception (" .. exception .. ") doesn't exist. Try -chprotect list instead."
	for k in ipairs(Checkslotsettings.userexceptions) do
		if Checkslotsettings.userexceptions[k].nick == exception then
			table.remove( Checkslotsettings.userexceptions, k)
			Oxygene.saveSettings()
			debugmsg = "OK"
			success = true
		end
	end
	return success, debugmsg
end

-- againstwhat: "againstkick", "ignoreslotrules", "ignorealltriggers", "ignoretriginterval"
function Oxygene.isNickProtectedAgainst(nick, againstwhat)
	local protected = false
	local match = false
	for k in ipairs(Checkslotsettings.userexceptions) do
		match = false
		if (Checkslotsettings.userexceptions[k].mode == 0) and (string.find(nick, Checkslotsettings.userexceptions[k].nick)) then
			match = true
		elseif (Checkslotsettings.userexceptions[k].mode == 1) and (string.find(nick, Checkslotsettings.userexceptions[k].nick, 1, 1)) then
			match = true
		elseif (Checkslotsettings.userexceptions[k].mode == 2) and (nick == Checkslotsettings.userexceptions[k].nick) then
			match = true
		end
		if (match) and (Checkslotsettings.userexceptions[k][againstwhat] == 1) then
			protected = true
		end
	end
	return protected
end

function Oxygene.getProtectionList(nick)
	local debugmsg = "Not protected"
	local protected = false
	
	if Oxygene.isNickProtectedAgainst(nick, "againstkick") then
		debugmsg = "Protections: Kick-protection"
		protected = true
	end
	if Oxygene.isNickProtectedAgainst(nick, "ignoreslotrules") then
		if protected then
			debugmsg = debugmsg .. ", "
		else
			debugmsg = "Protections: "
			protected = true
		end
		debugmsg = debugmsg .. "Ignoring slotrules"
	end
	if Oxygene.isNickProtectedAgainst(nick, "ignorealltriggers") then
		if protected then
			debugmsg = debugmsg .. ", "
		else
			debugmsg = "Protections: "
			protected = true
		end
		debugmsg = debugmsg .. "Ignoring all triggers"
	end
	if Oxygene.isNickProtectedAgainst(nick, "ignoretriginterval") then
		if protected then
			debugmsg = debugmsg .. ", "
		else
			debugmsg = "Protections: "
			protected = true
		end
		debugmsg = debugmsg .. "Ignoring trigger intervals"
	end	
	return protected, debugmsg
end

-- -chprotect add nick mode againstkick ignoreslotrules ignorealltriggers ignoretriginterval
-- -chprotect add ^\[VIP\] 0 1 0 0 1
function Oxygene.addException(user, parameter)
	local success = false
	local debugmsg = "Wrong/missing parameters. See -help chprotect"
	-- parsing parameter
	if string.find(parameter, "^(%S+ [012] [01] [01] [01] [01])$") then
		local nick = string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%1")
		local mode = Oxygene.convertToNum( string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%2") )
		local againstkick = Oxygene.convertToNum( string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%3") )
		local ignoreslotrules = Oxygene.convertToNum( string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%4") )
		local ignorealltriggers = Oxygene.convertToNum( string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%5") )
		local ignoretriginterval = Oxygene.convertToNum( string.gsub(parameter, "(%S+) ([012]) ([01]) ([01]) ([01]) ([01])", "%6") )
		if nil then --// if user then
			user:sendPrivMsgFmt("nick: " .. nick )
			user:sendPrivMsgFmt("mode: " .. mode )
			user:sendPrivMsgFmt("againstkick: " .. againstkick )
			user:sendPrivMsgFmt("ignoreslotrules: " .. ignoreslotrules )
			user:sendPrivMsgFmt("ignorealltriggers: " .. ignorealltriggers )
			user:sendPrivMsgFmt("ignoretriginterval: " .. ignoretriginterval )
		end
		debugmsg = "Params OK"
		if Oxygene.doesExceptionExist(nick) then
			Oxygene.rmException(exception)
		end
		-- Create ExceptionTable
		local tmp = {}
		tmp.nick = nick
		tmp.mode = mode
		tmp.againstkick = againstkick
		tmp.ignoreslotrules = ignoreslotrules
		tmp.ignorealltriggers = ignorealltriggers
		tmp.ignoretriginterval = ignoretriginterval
		table.insert(Checkslotsettings.userexceptions, tmp)
		Oxygene.saveSettings()
		success = true
	end
	return success, debugmsg
end

function Oxygene.checkSlotNumber(userdata)
	local valid, diffrules = true, 0
	local minslot, maxslot, slotrec, maxhub, minul_limit, kickmsg= 0, 0, 0, 0, 0, "OK"
	local isset = false
	local ulimitperslot = false
	
	-- Only check rules if share size is larger than the "minshare" config value)
	if (userdata.sharesize >= Checkslotsettings.config.minshare) then
		for k = 1, #Checkslotsettings.bwrules, 1 do
			if (userdata.up_bw <= Checkslotsettings.bwrules[k].bandwidth) or (Checkslotsettings.bwrules[k].bandwidth == -1) then
				minslot = Checkslotsettings.bwrules[k].minslot
				maxslot = Checkslotsettings.bwrules[k].maxslot
				slotrec = Checkslotsettings.bwrules[k].slotrec
				maxhub = Checkslotsettings.bwrules[k].maxhub
				maxhub_kick = Checkslotsettings.bwrules[k].maxhub_kick
				minul_limit = math.floor( userdata.up_bw * 1024 / 8 * Oxygene.convertToNum( Checkslotsettings.bandwidthmultipler ) )
				if minul_limit < Checkslotsettings.minulimit then minul_limit = Checkslotsettings.minulimit end
				isset = true
				break
			end
		end
		if not isset then
			minslot, maxslot, slotrec, maxhub, maxhub_kick, minul_limit = 31, 50, 40, 13, 14, 960
		end
		if userdata.tag.client_type == "DCGUI" then
			ulimitperslot = true
		end
		if ulimitperslot then
			minul_limit = minul_limit / userdata.tag.slots
		end
		
		kickmsg = Oxygene.GETSTRING("YourSettingsAreWrong")
		if (userdata.tag.slots < minslot) or (userdata.tag.slots > maxslot) then
			valid = false
			if (math.min(userdata.tag.slots, slotrec) ~= 0) then
				diffrules = diffrules + (( math.max(userdata.tag.slots, slotrec) / math.min(userdata.tag.slots, slotrec) - 1) * 10 )
			else
				diffrules = diffrules + (math.abs(math.max(userdata.tag.slots, slotrec))) * 10
			end
			local ReplaceString = Oxygene.GETSTRING("BadSlots")
			local SearchPattern = "(%S+) (%S+) (%S+)"
			local SlotRules = tostring(slotrec) .. " "
			if minslot == maxslot then
				SlotRules = SlotRules .. tostring(maxslot)
			else
				SlotRules = SlotRules .. tostring(minslot) .. "-" .. tostring(maxslot)
			end
			SlotRules = SlotRules .. " " .. tostring(userdata.tag.slots)
			kickmsg = kickmsg .. string.gsub(SlotRules, SearchPattern, ReplaceString)
		end
	
		-- here we could put the minimum upload limit check
		if (Checkslotsettings.config.ulimitcheck ~= 0) then
			
			if userdata.tag.ul_limit < minul_limit and userdata.up_bw >= Checkslotsettings.ulimitbw and userdata.tag.ul_limit > 0 then
				diffrule = diffrules + (minul_limit / userdata.tag.ul_limit - 1) * 10
				if valid == false then
					kickmsg = kickmsg .. ", " .. Oxygene.GETSTRING("AsWellAs") .. " "
				else
					valid = false
				end
				kickmsg = kickmsg .. string.gsub( tostring(minul_limit), "(.+)", Oxygene.GETSTRING("BadUploadLimit") )
			end
			if ulimitperslot then
				kickmsg = kickmsg .. " " .. Oxygene.GETSTRING("PerSlot")
			end
			
		end
		local sumhub1, sumhub2 = userdata.tag.hub1 + userdata.tag.hub2, userdata.tag.hub1 + userdata.tag.hub2 + userdata.tag.hub3
		if sumhub1 > maxhub_kick then
			diffrules = diffrules + (sumhub1 / maxhub - 1 ) * 5
			if valid == false then
				kickmsg = kickmsg .. "! " .. Oxygene.GETSTRING("InAddition") .. " "
			else
				valid = false
			end
			local ReplaceString = Oxygene.GETSTRING("BadHubNumber")
			local SearchPattern = "^([0-9]+) ([0-9]+) ([0-9]+)$"
			local Values = tostring(maxhub) .. " " .. tostring(sumhub1) .. " " .. tostring(sumhub2)
			kickmsg = kickmsg .. string.gsub(Values, SearchPattern, ReplaceString)
		end
		kickmsg = kickmsg .. ". " .. Oxygene.GETSTRING("Rules") .. Oxygene.getConfigValue("rulesurl")
		
		-- Too small bandwidth indicated
		if userdata.up_bw < Checkslotsettings.minbw then
			valid = false
			local ReplaceString = Oxygene.GETSTRING("TooSmallBw")
			local SearchPattern = "^([0-9,%.]+) ([0-9,%.]+)$"
			local Values = tostring(userdata.up_bw) .. " " .. tostring(userdata.up_bw * 128)
			kickmsg = string.gsub(Values, SearchPattern, ReplaceString) .. " " .. Oxygene.GETSTRING("Rules") .. Oxygene.getConfigValue("rulesurl")
			diffrules = 100
		end
		
		-- No bandwidth indicated
		if userdata.up_bw == 0 then
			valid = false
			kickmsg = Oxygene.GETSTRING("PleaseIndicateBandwidth") .. " " .. Oxygene.GETSTRING("Rules") .. Oxygene.getConfigValue("rulesurl")
			diffrules = 100
		end
		
		-- Reverse bandwidth indication
		if (Checkslotsettings.config.reversebandwidth ~= 0 and userdata.down_bw ~= 0 and userdata.up_bw > userdata.down_bw) then
			valid = false
			kickmsg = Oxygene.GETSTRING("ReverseBandwidth") .. " " .. Oxygene.GETSTRING("Rules") .. Oxygene.getConfigValue("rulesurl")
			diffrules = 60
		end
		
		-- Invisible tag
		if userdata.tag.text == "" or userdata.tag.client_ver == 0 then
				valid = false
				kickmsg = Oxygene.GETSTRING("YourTagIsNotVisible")
		end
		-- rounding diffrules
		diffrules = math.floor(diffrules * 100) / 100
	
	end -- if	(userdata.sharesize >= Checkslotsettings.config.minshare) ...
	return valid, kickmsg, diffrules
end

function Oxygene.setThreshold(user, percentage, minulimit, minbandwidth)
	percentage = math.floor( Oxygene.convertToNum( percentage ) )
	minulimit = math.floor( Oxygene.convertToNum( minulimit ) )
	minbandwidth = math.floor( Oxygene.convertToNum( minbandwidth ) )
	if percentage < 100 and percentage > 0 and minulimit > 0 and minbandwidth > 0 then
		if percentage < 10 then
			percentage = "0" .. tostring(percentage)
		else
			percentage = tostring(percentage)
		end
		Checkslotsettings.bandwidthmultipler = "0." .. percentage
		Checkslotsettings.minulimit = minulimit
		Checkslotsettings.ulimitbw = minbandwidth
		if user then
			user:sendPrivMsgFmt("OK", true)
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameters. Percentage should be between 0 and 100, and min ulimit and min bandwidth parameters should be positives.", true)
		end
		return false
	end
	Oxygene.saveSettings()
	return true
end

function Oxygene.setMinBw(user, minbandwidth)
	minbandwidth = Oxygene.convertToNum( minbandwidth )
	if minbandwidth >= 0 then
		Checkslotsettings.minbw = minbandwidth
		if user then
			user:sendPrivMsgFmt("OK", true)
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameters. Minimum bandwidth should be greater or equal than 0.", true)
		end
		return false
	end
	Oxygene.saveSettings()
	return true
end

function Oxygene.sendSlotRules(user)
	local count = 0
	local baw = ""
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Upload speed\tmin. slot\tmax. slot\trec. slot\tmax. hub\tmax-hub kick", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Checkslotsettings.bwrules) do
		count = count + 1
		if Checkslotsettings.bwrules[k].bandwidth == -1 then
			baw = "Above that:"
		else
			baw = "Up to " .. tostring( Checkslotsettings.bwrules[k].bandwidth) .. " mbps:"
		end
		user:sendPrivMsgFmt("           " .. baw .."\t".. tostring(Checkslotsettings.bwrules[k].minslot) .. "\t" .. tostring(Checkslotsettings.bwrules[k].maxslot) .. "\t" .. tostring(Checkslotsettings.bwrules[k].slotrec .. "\t" .. tostring(Checkslotsettings.bwrules[k].maxhub .. "\t" .. tostring(Checkslotsettings.bwrules[k].maxhub_kick))), true )
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Minimum allowed upload bandwidth: " .. tostring( Checkslotsettings.minbw ), true)
	user:sendPrivMsgFmt("          Upload threshold: " .. tostring( Oxygene.convertToNum( Checkslotsettings.bandwidthmultipler ) * 100 ) .. " % - Min. limit: " .. tostring( Checkslotsettings.minulimit ) .. " KiB/sec - Applied for: " .. tostring( Checkslotsettings.ulimitbw ) .. " mbps and above", true)
	user:sendPrivMsgFmt("          Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return count
end

function Oxygene.getDefaultProfile()
	return Checkslotsettings.currentprofile
end

function Oxygene.isItProfile( text )
	local ret = false
	for k in ipairs(Checkslotsettings.kickprofiles) do
		if Checkslotsettings.kickprofiles[k].name == text then
			ret = true
		end
	end
	return ret
end

-- profiletype: c: chat; r: raw
function Oxygene.addProfile( user, profilename, profiletype, command )
	local managed = false
	if profiletype ~= "c" and profiletype ~= "r" then
		if user then
			user:sendPrivMsgFmt( "Wrong profile type. Must be \"c\" for chat commands or \"r\" for raw.", true )
		end
	elseif Oxygene.isItProfile( profilename ) then
		if user then
			user:sendPrivMsgFmt( "Profile already added. Please remove it first.", true )
		end
	else
		local temptable = { }
		temptable.name = profilename
		temptable.command = command
		temptable.type = profiletype
		table.insert( Checkslotsettings.kickprofiles, temptable )
		Oxygene.saveSettings()
		managed = true
		if user then
			user:sendPrivMsgFmt( "OK", true )
		end
	end
	return managed
end

function Oxygene.rmProfile( user, profile )
	local managed = false
	if Oxygene.isItProfile( profile ) and ( Checkslotsettings.currentprofile ~= profile ) then
		for k in ipairs(Checkslotsettings.kickprofiles) do
			if Checkslotsettings.kickprofiles[k].name == profile then
				table.remove( Checkslotsettings.kickprofiles, k )
				managed = true
			end
		end
		if user then
			user:sendPrivMsgFmt( "OK", true )
		end
	else
		if user then
			user:sendPrivMsgFmt( "Profil doesn't exist, or set to default. Can't remove non-existing or current default profile. See -chprofiles list and -help", true )
		end
	end
	return managed
end

function Oxygene.sendKickProfilesTo(user)
	local count = 0
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Profile name [type] (Command)", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Checkslotsettings.kickprofiles) do
		count = count + 1
		user:sendPrivMsgFmt("           (" .. tostring(count) .. ") ".. Checkslotsettings.kickprofiles[k].name .. " [" .. Checkslotsettings.kickprofiles[k].type .."] (" .. Checkslotsettings.kickprofiles[k].command .. ")", true )
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Default profile: " .. Oxygene.getDefaultProfile(), true )
	user:sendPrivMsgFmt("          Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return count
end

function Oxygene.selectProfile( user, profile )
	local managed = false
	if Oxygene.isItProfile( profile ) then
		managed = true
		Checkslotsettings.currentprofile = profile
		Oxygene.saveSettings()
		if user then
			user:sendPrivMsgFmt( "Profile '" .. profile .. "' selected" )
		end
	else
		if user then
			user:sendPrivMsgFmt( "Profile not found. Use -chprofiles list and -help for more information." )
		end
	end
	return managed
end

function Oxygene.getKickMsg(hub, userdata, reason, profile)
	local kickmsg = ""
	local profiletype = ""
	if not profile then profile = Checkslotsettings.currentprofile end
	for k in ipairs(Checkslotsettings.kickprofiles) do
		if Checkslotsettings.kickprofiles[k].name == profile then
			kickmsg = Checkslotsettings.kickprofiles[k].command
			profiletype = Checkslotsettings.kickprofiles[k].type
		end
	end
	-- %[myNI]
	local replace = hub:getOwnNick()
	replace = string.gsub(replace, "%%", "%%%%")
	kickmsg = string.gsub( kickmsg, "%%%[myNI%]", replace )
	-- %[userNI]
	replace = userdata.nick
	replace = string.gsub(replace, "%%", "%%%%")
	kickmsg = string.gsub ( kickmsg, "%%%[userNI%]", replace)
	-- %[reason]
	replace = reason
	replace = string.gsub(replace, "%%", "%%%%")
	kickmsg = string.gsub ( kickmsg, "%%%[reason%]", replace)
	if kickmsg == "" then
		Oxygene.log("# STRUCTURE ERROR 3: Invalid kick profile")
	end
	return kickmsg, profiletype
end

function Oxygene.disconnect(hub, userdata, reason, profile)
	local managed = false
	local debugmsg = "OK"
	if (userdata.isop) or (Oxygene.isNickProtectedAgainst(userdata.nick, "againstkick")) then
		managed = false
		debugmsg = "User is an Operator or protected"
	else
		hub:sendPrivMsgTo(userdata.nick, "<" .. hub:getOwnNick() .. "> You are being disconnected because: " .. reason, true)
		Oxygene.log("[KICK] Disconnected: " .. userdata.nick .. " because: " .. reason, Checkslotsettings.kicklog)
		local kickmsg, kicktype = Oxygene.getKickMsg( hub, userdata, reason, profile )
		if kicktype == "c" then
			hub:sendChat( kickmsg )
		else
			DC():SendHubMessage( hub:getId(), kickmsg )
		end
		managed = true
	end
	return managed, debugmsg
end

function Oxygene.private(hub, userdata, reason)
	local managed = false
	if userdata.isop then
		--
		managed = false
	else
		hub:sendPrivMsgTo(userdata.nick, "<" .. hub:getOwnNick() .. "> " .. Oxygene.GETSTRING("ThisIsAnAutomessage") .. reason, true)
		managed = true
	end
	return managed
end

function Oxygene.tokenize(text)
	local ret = {}
	string.gsub(text, "([^ ]+)", function(s) table.insert(ret, s) end )
	return ret
end

function Oxygene.buildUserData(hub, user, basedon, data)
	-- userdata is a table which stores every important information about the current user
	local userdata = {}
	local nicktmp = user:getNick()
	-- basedon possible values (maybe more adéded later):
	-- "myinfo", "chatmsg"

	-- Check if it's new user
	local newuser = true
	if Oxygene.isUserOnHub(hub, nicktmp) then
		newuser = false
	end

	-- if it's a new user, we need to build a clean userdata table
	if newuser then
		-- initializing variables:
		userdata.nick = ""
		userdata.chatmsg = ""
		userdata.isop = false
		userdata.description, userdata.tag, userdata.connection, userdata.email, userdata.sharesize = {}, {}, "", "", 0
		userdata.down_bw, userdata.up_bw = 0, 0
		userdata.description = ""
		userdata.tag.text,userdata.tag.client_type, userdata.tag.client_ver, userdata.tag.conn_mode, userdata.tag.hub1, userdata.tag.hub2, userdata.tag.hub3, userdata.tag.slots, userdata.tag.auto_open, userdata.tag.ul_limit = "", "", 0, "", 0, 0, 0, 0, 0, 0
		userdata.isvalid_slots, userdata.kickmsg_slots = true, ""
		userdata.diffrules = 0
		userdata.logintime = os.time()
	else
		userdata = Oxygene.getUserData( hub, nicktmp )
	end

	-- filling/updating the table

	-- in every case

	-- isop may change, update it at every myinfo/chatmsg
	if user:isOp() then
		userdata.isop = true
	end
	-- if nick was change, that would be horrible, but this can't happen otherwise someting went wrong
	userdata.nick = nicktmp

	if basedon == "myinfo" then

		-- if a new myinfo is sent
		userdata.description, userdata.tag.text, userdata.connection, userdata.email, userdata.sharesize = Oxygene.parseMyinfo(userdata.nick, data)
		userdata.tag.client_type, userdata.tag.client_ver, userdata.tag.conn_mode, userdata.tag.hub1, userdata.tag.hub2, userdata.tag.hub3, userdata.tag.slots, userdata.tag.auto_open, userdata.tag.ul_limit = Oxygene.parseTag(userdata.tag.text)
		-- Check if the connection is number
		if string.find(userdata.connection, "^[0-9%.]+$") then
			userdata.down_bw = 0
			userdata.up_bw = Oxygene.convertToNum(userdata.connection)
		else
			userdata.down_bw, userdata.up_bw = Oxygene.getBw(userdata.description)
		end

		-- check slot numbers
		userdata.isvalid_slots, userdata.kickmsg_slots, userdata.diffrules = Oxygene.checkSlotNumber(userdata)
		
		if (not userdata.isvalid_slots) and (hub.oxygene.state.active) and (not Oxygene.isNickProtectedAgainst(userdata.nick, "ignoreslotrules")) then
			if Checkslotsettings.config.slotcheck == "kick" then
				Oxygene.disconnect(hub, userdata, userdata.kickmsg_slots)
			elseif Checkslotsettings.config.slotcheck == "pm" then
				Oxygene.private(hub, userdata, userdata.kickmsg_slots)
			end
		end

	elseif basedon == "chatmsg" then
		-- if user entered someting to the main chat
		userdata.chatmsg = data
	end

	return userdata
end

function Oxygene.updateHubStat( hubstat, userdata )
	local alreadyadded = false
	local tempclient_type = ""
	local nv_tempclient_type = ""
	local tempconn_mode = ""

	tempclient_type = userdata.tag.client_type .. " " .. tostring( userdata.tag.client_ver )
	nv_tempclient_type = userdata.tag.client_type
	tempconn_mode = userdata.tag.conn_mode
	if userdata.tag.client_type == "" then
		tempclient_type = "Missing tag"
		nv_tempclient_type = "Missing tag"
	end
	if tempconn_mode == "" then
		tempconn_mode = "Missing tag"
	end
	-- user count
	hubstat.usercount = hubstat.usercount + 1
	-- rule violating
	
	hubstat.points = hubstat.points + userdata.diffrules
	
	--// TODO: Remove
	-- DC():PrintDebug("userdata.diffrules: " .. tostring(userdata.diffrules))
	-- DC():PrintDebug("hubstat.points: " .. tostring(hubstat.points))
	
	if not userdata.isvalid_slots then
		if Oxygene.isNickProtectedAgainst(userdata.nick, "ignoreslotrules") then
			hubstat.protectedslots = hubstat.protectedslots + 1
		end
		hubstat.badslots = hubstat.badslots + 1
	end
	-- check whether client-type is added already
	alreadyadded = false
	for k in ipairs(hubstat.client_type) do
		if hubstat.client_type[k].text == tempclient_type then
			alreadyadded = true
			hubstat.client_type[k].count = hubstat.client_type[k].count + 1
			hubstat.client_type[k].points = hubstat.client_type[k].points + userdata.diffrules
		end
	end
	if not alreadyadded then
		local temptable = {}
		temptable.text = tempclient_type
		temptable.count = 1
		temptable.points = userdata.diffrules
		table.insert ( hubstat.client_type, temptable)
	end
	-- check whether the non-versioned client_type is added already
	alreadyadded = false
	for k in ipairs(hubstat.nvclient_type) do
		if hubstat.nvclient_type[k].text == nv_tempclient_type then
			alreadyadded = true
			hubstat.nvclient_type[k].count =  hubstat.nvclient_type[k].count + 1
			hubstat.nvclient_type[k].points = hubstat.nvclient_type[k].points + userdata.diffrules
		end
	end
	if not alreadyadded then
		local temptable = {}
		temptable.text = nv_tempclient_type
		temptable.count = 1
		temptable.points = userdata.diffrules
		table.insert ( hubstat.nvclient_type, temptable)
	end
	-- check whether connection mode is added already
	alreadyadded = false
	for k in ipairs(hubstat.conn_mode) do
		if hubstat.conn_mode[k].text == tempconn_mode then
			alreadyadded = true
			hubstat.conn_mode[k].count = hubstat.conn_mode[k].count + 1
			hubstat.conn_mode[k].points = hubstat.conn_mode[k].points + userdata.diffrules
		end
	end
	if not alreadyadded then
		local temptable = {}
		temptable.text = tempconn_mode
		temptable.count = 1
		temptable.points = userdata.diffrules
		table.insert( hubstat.conn_mode, temptable )
	end
	return hubstat
end

function Oxygene.getHubStat( hub )
	local hubstat = {}
	hubstat.usercount = 0
	hubstat.badclient = 0
	hubstat.badslots = 0
	hubstat.protectedslots = 0
	hubstat.points = 0
	hubstat.client_type = {}
	hubstat.conn_mode = {}
	hubstat.nvclient_type = {}
	-- create hubstat
	for k in pairs(hub.oxygene.userlist) do
		hubstat = Oxygene.updateHubStat( hubstat,  hub.oxygene.userlist[k] )
	end
	-- order hubstat (part1)
	local i = #hubstat.client_type
	for k = 1, i-1, 1 do
		for l = k+1, i, 1 do
			if hubstat.client_type[k].text > hubstat.client_type[l].text then
				hubstat.client_type[k], hubstat.client_type[l] = hubstat.client_type[l], hubstat.client_type[k]
			end
		end
	end
	-- order nonversioned client_type table...
	i = #hubstat.nvclient_type
	for k = 1, i-1, 1 do
		for l = k+1, i, 1 do
			if hubstat.nvclient_type[k].text > hubstat.nvclient_type[l].text then
				hubstat.nvclient_type[k], hubstat.nvclient_type[l] = hubstat.nvclient_type[l], hubstat.nvclient_type[k]
			end
		end
	end
	return hubstat
end

-- fullstat: Defines whether to show percentages in Client Statistic
function Oxygene.processHubStat( hub, user, hubstat, fullstat )
	local text = ""
	text = text .. "\r\n          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          General hub statistics                                                                     Oxygene %[chversion]\r\n"
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          Autochecking active: " .. Oxygene.yesNo( hub.oxygene.state.active ) .. "\r\n"
	text = text .. "          Usercount: " .. tostring( hubstat.usercount ) .. " users\r\n"
	text = text .. "          Bad slotrules: " .. tostring( hubstat.badslots ) .. " users"
	if hubstat.protectedslots > 0 then
		text = text .. " (" .. tostring( hubstat.protectedslots ) .. " protected)"
	end
	text = text .. "\r\n"
	--// TODO: Remove
	-- DC():PrintDebug("hubstat.points: " .. tostring(hubstat.points))
	-- DC():PrintDebug("hubstat.usercount: " .. tostring(hubstat.usercount))
	
	text = text .. "          Average points: " .. math.floor(hubstat.points / hubstat.usercount * 100) / 100 .. "\r\n"
	for k in ipairs(hubstat.conn_mode) do
	text = text .. "          " .. hubstat.conn_mode[k].text .. ": " .. tostring( hubstat.conn_mode[k].count )
	if fullstat then
		text = text .. " (" .. tostring(math.floor((hubstat.conn_mode[k].count / hubstat.usercount) * 100 * 100) / 100) .. " %)"
	end
	text = text .. "\r\n"
	end
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          Detailed client statistics\r\n"
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	for k in ipairs(hubstat.client_type) do
	text = text .. "          " .. hubstat.client_type[k].text .. ": " .. tostring( hubstat.client_type[k].count )
	if fullstat then
		text = text .. " (" .. tostring(math.floor((hubstat.client_type[k].count / hubstat.usercount) * 100 * 100) / 100) .. " %)"
	end
	text = text .. "\r\n"
	end
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          Average points statistics\r\n"
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	for k in ipairs(hubstat.nvclient_type) do
	text = text .. "          " .. hubstat.nvclient_type[k].text .. ": " .. tostring(math.floor(hubstat.nvclient_type[k].points / hubstat.nvclient_type[k].count * 100 ) /100)
	if fullstat then
		text = text .. " (" .. tostring(math.floor((hubstat.nvclient_type[k].count / hubstat.usercount) * 100 * 100) / 100) .. " %, " .. tostring( hubstat.nvclient_type[k].count ) .. " clients)"
	end
	text = text .. "\r\n"
	end
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\nOK"
	text = Oxygene.evaluateVariables(text, hub, Oxygene.getUserData( hub, user:getNick() ) )
	return text
end

function Oxygene.sendHubStat( hub, user, pm, fullstat )
	local hubstat = Oxygene.getHubStat( hub )
	local message = Oxygene.processHubStat( hub, user, hubstat, fullstat )
	if pm then
		user:sendPrivMsgFmt( message, true)
	else
		hub:sendChat( message )
	end
	return 1
end

function Oxygene.getUserData( hub, nick )
	local userdata = false
	if hub.oxygene.userlist[nick] then
		userdata = hub.oxygene.userlist[nick]
	end
	--[[
	for k in ipairs(hub.oxygene.userlist) do
		if hub.oxygene.userlist[k].nick == nick then
			userdata = hub.oxygene.userlist[k]
		end
	end
	]]
	return userdata
end

function Oxygene.refreshAllUserData(hub)
	local counter = 0
	for k in pairs(hub.oxygene.userlist) do
		local userdata = Oxygene.getUserData( hub, k )
		userdata.isvalid_slots, userdata.kickmsg_slots, userdata.diffrules = Oxygene.checkSlotNumber(userdata)
		Oxygene.updateUser(hub, userdata)
		counter = counter + 1
	end
	return counter
end

function Oxygene.getUserInfo( userdata )
	local message = ""
	message = "\r\n          -----------------------------------------------------------------------------------------------------\r\n"
	message = message .. "          Userinfo (" .. userdata.nick .. "):\r\n          -----------------------------------------------------------------------------------------------------\r\n"
	if string.len(userdata.description) > 0 then
		message = message .. "          Description: " .. userdata.description .. "\r\n"
	end
	message = message .. "          Bandwidth: " .. tostring(userdata.down_bw) .. "M/" .. tostring(userdata.up_bw).."M\r\n"
	message = message .. "          Operator: " .. Oxygene.yesNo(userdata.isop) .. "\r\n"
	if string.len(userdata.tag.text) > 0 then
		message = message .. "          Tag: " .. userdata.tag.text .. "\r\n"
	end
	message = message .. "          Connection: " .. userdata.connection .. "\r\n"
	if string.len(userdata.email) > 0 then
		message = message .. "          E-mail: " .. userdata.email .. "\r\n"
	end
	message = message .. "          Sharesize: " .. Oxygene.formatBytes(userdata.sharesize) .. " (" .. tostring(userdata.sharesize) .. " B)\r\n"
	if string.len(userdata.chatmsg) > 0 then
		message = message .. "          Latest chat message: \"" .. userdata.chatmsg .. "\"\r\n"
	end
	message = message .. "          Added: " .. os.date("%x %X", userdata.logintime) .. "\r\n"
	message = message .. "          "
	local prot, dbg = Oxygene.getProtectionList(userdata.nick)
	message = message .. dbg .. "\r\n"
	message = message .. "          Slotrules: "
	if userdata.isvalid_slots then
		message = message .. "OK\r\n"
	else
		message = message .. "\r\n          ".. userdata.kickmsg_slots .. "\r\n"
	end
	message = message .. "          Points for slotrules violation: " .. tostring(userdata.diffrules) .. "\r\n"
	message = message .. "          -----------------------------------------------------------------------------------------------------\r\n"
	message = message .. "OK"
	return message
end

function Oxygene.sendUserInfo(hub, user, nick_to_send, pm)
	local counter = 0
	local message = ""
	local userdata = nil
	userdata = Oxygene.getUserData(hub, nick_to_send)
	if not userdata then
			if pm then
				user:sendPrivMsgFmt("User (".. nick_to_send .. ") is not found", true)
			else
				hub:sendChat("User (".. nick_to_send..") is not found")
			end
	else
		message = Oxygene.getUserInfo(userdata)
		if pm then
			user:sendPrivMsgFmt(message, true)
		else
			hub:sendChat(message)
		end
	end
	return userdata
end

function Oxygene.isUserOnHub(hub, nick)
	--[[
	local ret = false
		for k in pairs(hub.oxygene.userlist) do
			if hub.oxygene.userlist[k].nick == nick then
				ret = true
			end
		end
	return ret
	]]


	--// Returns true if user is in
	local ret = false
	if hub.oxygene.userlist[nick] then
		ret = true
	end
	return ret
end

--// used internally, call updateUser instead!
function Oxygene.addUserToHub(hub, userdata)
	local ret = false
	if userdata.nick then
		hub.oxygene.userlist[userdata.nick] = userdata
		ret = true
	else
		DC():PrintDebug("DEBUG#001: Can't add user without nick")
	end
	--[[
		table.insert(hub.oxygene.userlist, userdata)
		local ret = true
	]]
	return ret
end

function Oxygene.setUserData(pointer, userdata)
	local ret = false
	pointer = userdata
	local ret = true
end

function Oxygene.updateUser(hub, userdata)
	--// Return values:
	--// 0: some error happened
	--// 1: new user
	--// 2: updated user
	local ret = 0
	if Oxygene.isUserOnHub(hub, userdata.nick) then
		ret = 2
		Oxygene.setUserData( hub.oxygene.userlist[userdata.nick], userdata )
		--[[
		for k in pairs(hub.oxygene.userlist) do
			if hub.oxygene.userlist[k].nick == nick then
				Oxygene.setUserdata( hub.oxygene.userlist[k], userdata )
				break
			end
		end
		]]
		-- Oxygene.removeUserFromHub(hub, userdata.nick)
	else
		ret = 1
		Oxygene.addUserToHub(hub, userdata)
	end
	
	return ret
end

function Oxygene.removeUserFromHub(hub, nick)
	--// Returns true if any user are removed
	local ret = false
	if hub.oxygene.userlist[nick] then
		hub.oxygene.userlist[nick] = nil
		ret = true
	else
		DC():PrintDebug("DEBUG#101: Can't remove user from hub: " .. tostring(nick) )
	end
	--[[
		for k in ipairs(hub.oxygene.userlist) do
			if hub.oxygene.userlist[k].nick == nick then
				table.remove( hub.oxygene.userlist, k )
				ret = true
			end
		end
	]]
	return ret
end

function Oxygene.noticeUser( hub, user, nick_to_check, method )
	local success = false
	local userdata = Oxygene.getUserData(hub, nick_to_check)
	local kickmsg = ""
	local message = ""
	if not userdata then
		if user then
			user:sendPrivMsgFmt("User (".. nick_to_check .. ") is not found", true)
		end
	else
		if userdata.isop then
			message = nick_to_check .. " is an Operator. You can't notice him or her"
		elseif Oxygene.isNickProtectedAgainst(userdata.nick, "ignoreslotrules") then
			message = nick_to_check .. " is Protected"
		else
			if userdata.isvalid_slots then
				message = nick_to_check .. " has right settings"
			else
				message = nick_to_check .. " gets " .. method .. "ed because of violating slotrules"
				kickmsg = userdata.kickmsg_slots
				
				if method == "pm" then
					Oxygene.private(hub, userdata, kickmsg)
					success = true
				else
					local kicprofile = ""
					if Oxygene.isItProfile( method ) then
						kickprofile = method
						message = "[" .. kickprofile .."] "
					elseif method == "default" then
						kickprofile = Oxygene.getDefaultProfile()
						message = "[" .. kickprofile .."] "
					else
						kickprofile = Oxygene.getDefaultProfile()
						message = "[Wrong profile: using default] "
					end
					local ret, dbg = Oxygene.disconnect(hub, userdata, kickmsg, kickprofile)
					if ret then
						message = message .. userdata.nick
						success = true
						Oxygene.log("[KICK] " .. user:getNick() .. " kicked [" .. kickprofile .."] " .. userdata.nick .. " because: " .. kickmsg, Checkslotsettings.logfile)
					else
						message = dbg
						Oxygene.log("[KICK] " .. user:getNick() .. " wanted to kick " .. userdata.nick .. ", but he/she is protected. Reason: " .. kickmsg, Checkslotsettings.logfile)
					end
				end
			end
		end
		if user then
			user:sendPrivMsgFmt( message, true )
		end
	end
	return success
end

function Oxygene.checkHub( hub, user, num, profile )
	local success = false
	local kickmsg, nice = "", true
	local currkicked, maxkick = 0, tonumber(num)
	if not maxkick then
		if user then
			user:sendPrivMsgFmt( "Wrong parameter: <num> must be a number. Example: -chcheckhub 700", true )
		end
	elseif maxkick < 1 then
		if user then
			user:sendPrivMsgFmt( "Wrong parameter: <num> must be a positive integer. Example: -chcheckhub 700", true )
		end
	else
		if not profile then
			profile = Checkslotsettings.currentprofile
			if user then
				user:sendPrivMsgFmt("Missing parameter [profile]. Using profile '" .. profile .. "' for disconnecting.", true )
			end
		end
		if not Oxygene.isItProfile( profile ) then
			if user then
				user:sendPrivMsgFmt("Wrong profile name (" .. profile .. "). Check profile list using -chprofiles list command.", true )
			end
		else
			Oxygene.log( "[KICK] " .. user:getNick() .. " wants to disconnect " .. tostring(num) .. " users using profile '" .. profile .. "'")
			-- kicking users
			for k in pairs(hub.oxygene.userlist) do
				kickmsg = ""
				nice = true
				if not hub.oxygene.userlist[k].isvalid_slots then
					kickmsg = kickmsg .. hub.oxygene.userlist[k].kickmsg_slots
					nice = false
				end
				if not nice then
					local userdata = Oxygene.getUserData( hub, k )
					local ret, dbg = Oxygene.disconnect(hub, userdata, kickmsg, profile)
					-- We don't count protected users since they are not kicked
					if ret then
						currkicked = currkicked+ 1
					end
					success = true
					if currkicked >= maxkick then
						Oxygene.log( "[KICK] -chcheckhub: queue completed. " .. tostring(currkicked) .. " users were disconnected")
						if user then
							user:sendPrivMsgFmt("OK", true)
						end
						hub:sendChat(string.gsub( tostring(currkicked), "(.+)", Oxygene.GETSTRING("KickBroadcast") ))
						return success
					end
				end
			end
		end
	end
	Oxygene.log( "[KICK] -chcheckhub: queue completed. " .. tostring(currkicked) .. " users were disconnected")
	if success then
		if user then
			user:sendPrivMsgFmt("OK", true)
		end
		hub:sendChat(string.gsub( tostring(currkicked), "(.+)", Oxygene.GETSTRING("KickBroadcast") ))
	end
	return success
end

function Oxygene.getHelpFor(user, command)
	local help = { }
	local tmp = { }
	tmp.command = "chrules"
	tmp.desc = "Usage: -chrules <list/add/rm/ulimit/minbw/clearall/reset> [params]\r\n\r\n-chrules list\r\nLists the current active slotrules table\r\n\r\n-chrules add <upper_bandwidth> <minslot> <maxslot> <slotrec> <maxhub> <maxhub_kick>\r\nAdds or overwrites a new/existing rule. Use -1 as bandwidth for the \"Above that\" rule.\r\n\r\n-chrules rm <bandwidth>\r\nRemoves the given bandwidth from the table. Use -1 to remove the \"Above that\" rule.\r\n\r\n-chrules ulimit <percent> <min_limit> <applied_from>\r\nSets the upload limit config values.\r\nThe users shouldn't limit their upload limit below the given <percent> of their nominal upload bandwidth but at least <min_limit> KiB/sec.\r\nFor convenience (for example because of users with dial-up modems) the rule is only applied for users with at least <applied_from> upload bandwidth. The others don't get hurt.\r\n\r\n-chrules minbw <bandwidth>\r\nSpecifies the minimum allowed upload bandwidth (MiBits/s)-chrules clearall\r\nClears the whole slotrules table\r\n\r\n-chrules reset\r\nRestores the original slotrules"
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "chnotice"
	tmp.desc = "Usage: -chnotice <nick> <pm/profile_name>\r\n\r\n-chnotice <nick> <pm/profile_name>\r\nNotices or kicks the user if he/she's violating the slot rules. If the second parameter is pm then the script only sends a PM to him/her.\r\nIf you provide a profile name as second parameter, the user will be kicked using the given profile. Use \"default\" for the default profile."
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "chtrigs"
	tmp.desc = "Usage: -chtrigs <list/addtrig/rmtrig/addc/rmc/adda/rma/enable/settype/setinterval> [params]\r\n\r\n-chtrigs list [all/trigger_name]\r\n\r\n-chtrigs addtrig <trigger_name> [type] [interval]\r\n\r\n-chtrigs rmtrig <trigger_name>\r\n\r\n-chtrigs addc <trigger_name> <variable> <condition> <value>\r\n-chtrigs addcondition <trigger_name> <variable> <condition> <value>\r\n\r\n-chtrigs rmc <trigger_name> <C_num/all>\r\n-chtrigs rmcondition <trigger_name> <C_num/all>\r\n\r\n-chtrigs adda <trigger_name> <action> <parameters>\r\n-chtrigs addaction <trigger_name> <action> <parameters>\r\n\r\n-chtrigs rma <trigger_name> <A_num/all>\r\n-chtrigs rmaction <trigger_name> <A_num/all>\r\n\r\n-chtrigs enable <trigger_name> <+/->\r\n\r\n-chtrigs settype <trigger_name> <and/or>\r\n\r\n-chtrigs setinterval <trigger_name> <interval_in_sec>\r\n\r\n-chtrigs reset <trigger_name>"
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "chprofiles"
	tmp.desc = "Usage: -chprofiles <list/add/rm/setdefault>\r\n\r\n-chprofiles list\r\n\r\n-chprofiles add <profile_name> <profile_type> <command>\r\n\r\n<profile_type>: \"r\" for raw, \"c\" for chat command\r\n<command> can include %[userNI] and %[reason] parameters\r\n\r\n-chprofiles rm <profile_name>\r\n\r\n-chprofiles setdefault <profile_name>"
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "chprotect"
	tmp.desc = "Usage: -chprotect <list/add/rm> [params]\r\n\r\n-chprotect list\r\n\r\n-chprotect add <pattern> <mode> <kickprotection> <ignore slot rules> <ignore all triggers> <ignore trigger timing>\r\n<pattern> cannot contain spaces\r\nAvailable <mode>s: 0 for regex, 1 for partial match, 2 for exact match\r\n<kickprotection> <ignore slot rules> <ignore all triggers> <ignore trigger timing> can be 0 or 1\r\n\r\n-chprotect rm <pattern>"
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "chstat"
	tmp.desc = "Usage: -chstat [full]\r\nIf you ask for a full stat, you get percentages too."
	table.insert( help, tmp )
	tmp = { }
	tmp.command = "" ------
	local matched = false
	local texttosend = ""
	for k in ipairs(help) do
		if help[k].command == command then
			texttosend = help[k].desc
			matched = true
		end
	end
	if matched then
		user:sendPrivMsgFmt("\r\n-----------------------------------------------------------------------------------------------------\r\n" .. "-" .. command .."\r\n-----------------------------------------------------------------------------------------------------\r\n" .. texttosend .. "\r\n-----------------------------------------------------------------------------------------------------", true)
	else
		local known = ""
		for k in ipairs(help) do
			known = known .. " " .. help[k].command
		end
		user:sendPrivMsgFmt("\r\n-----------------------------------------------------------------------------------------------------\r\nNo help entry for \"" .. command .. "\" yet. Non-existing command or unfinished help. Known commands:\r\n" .. known .. "\r\n-----------------------------------------------------------------------------------------------------", true)
	end
	return nil
end

function Oxygene.fixOpList( hub, text )
	for nick in string.gmatch( string.sub( text, 9 ), "[^$]+") do
		local ud = Oxygene.getUserData( hub, nick )
		if ud then
			ud.isop = true
			Oxygene.updateUser( hub, ud )
		else
			DC():PrintDebug("[OPLIST] No Myinfo for " .. nick .. " yet. I can't process $OpList.") -- buggy hub?
		end
	end
end

-- if user is nil, everything goes to opchat if set
function Oxygene.commandParser( hub, user, command )
	local params = Oxygene.tokenize(command)
	if not user then
		local utable = hub:findUsers( Oxygene.getConfigValue("opchat_name"), nil )
		-- it should contain at most one nick
		for k in ipairs(utable) do
			user = utable[k]
		end
	end
		if params[1] == "-help" or params[1] == "-?" then
			if user then
				if params[2] then
					Oxygene.getHelpFor(user, params[2])
				else
					Oxygene.sendHelp(hub, user)
				end
			end
		elseif params[1] == "-chtrigs" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "list" then
					if not params[3] then
						if user then
							Oxygene.sendTriggerListTo( user , "_NONE" )
						end
					elseif params[3] == "all" then
						if user then
							Oxygene.sendTriggerListTo( user , "_ALL" )
						end
					else
						if user then
							Oxygene.sendTriggerListTo( user , params[3] )
						end
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "addtrig" then
					Oxygene.addTrigger( user, params[3], params[4], params[5] )
				elseif params[2] == "rmtrig" then
					Oxygene.rmTrigger( user, params[3] )
				elseif params[2] == "reset" then
					Oxygene.resetTrigCounter( user, params[3] )
				elseif not params[4] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "enable" then
					Oxygene.enableTrigger(user, params[3], params[4])
				elseif params[2] == "settype" then
					Oxygene.setTrigType(user, params[3], params[4])
				elseif params[2] == "setinterval" then
					Oxygene.setTrigInterval(user, params[3], params[4])
				elseif params[2] == "rma" or params[2] == "rmaction" then
					Oxygene.rmTriggerAction(user, params[3], params[4])
				elseif params[2] == "rmc" or params[2] == "rmcondition" then
					Oxygene.rmTriggerCondition(user, params[3], params[4])
				elseif params[2] == "adda" or params[2] == "addaction" then
					Oxygene.trigAddAction(user, params[3], params[4], string.sub(command, string.len(params[3]) + string.len(params[4]) + string.len(params[1]) + string.len(params[2]) + 5, string.len(command) ))
				elseif not params[5] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "addc" or params[2] == "addcondition" then
					Oxygene.trigAddCondition(user, params[3], params[4], params[5], string.sub(command, string.len(params[3]) + string.len(params[4]) + string.len(params[5]) + string.len(params[1]) + string.len(params[2]) + 6, string.len(command) ) )
				end
			elseif params[1] == "-chprotect" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chprotect", true )
					end
				elseif params[2] == "list" then
					if user then
						Oxygene.listExceptions(user)
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt( "Missing/wrong parameters. See -help chprotect", true )
					end
				elseif params[2] == "rm" then
					local ret, dbg = Oxygene.rmException(params[3])
					if user then
						if not ret then
							user:sendPrivMsgFmt("Error: " .. dbg, true)
						else
							user:sendPrivMsgFmt("OK")
						end
					end
				elseif params[2] == "add" then
					local ret, dbg = Oxygene.addException(user, string.sub(command, string.len(params[1]) + string.len(params[2]) + 3, string.len(command)) )
					if user then
						if not ret then
							user:sendPrivMsgFmt("Error: " .. dbg, true)
						else
							user:sendPrivMsgFmt("OK")
						end
					end
				end
			elseif params[1] == "-chgetinfo" then
				if params[2] then
					if user then
						Oxygene.sendUserInfo(hub, user, params[2], true)
					end
				else
					if user then
						user:sendPrivMsgFmt("Wrong paramters. See: -help", true)
					end
				end
			elseif params[1] == "-chnotice" then
				if params[2] and params[3] then
					Oxygene.noticeUser( hub, user, params[2], params[3] )
				else
					if user then
						user:sendPrivMsgFmt("Missing parameters. See -help chnotice", true)
					end
				end
			elseif params[1] == "-chcheckhub" then
				if params[2] then
					Oxygene.checkHub( hub, user, params[2], params[3] )
				else
					if user then
						user:sendPrivMsgFmt("Wrong paramter. See -help", true)
					end
				end
			elseif params[1] == "-chstat" then
				if params[2] then
					if params[2] == "full" then
						if user then
							Oxygene.sendHubStat( hub, user, true, true )
						end
					else
						if user then
							user:sendPrivMsgFmt("Wrong parameters. See -help chstat", true)
						end
					end
				else
					if user then
						Oxygene.sendHubStat( hub, user, true, false )
					end
				end
			elseif params[1] == "-chrules" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "list" then
					if user then
						Oxygene.sendSlotRules( user )
					end
				elseif params[2] == "clearall" then
					Oxygene.clearBwRules( user )
				elseif params[2] == "reset" then
					Oxygene.resetBwRules( user )
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "rm" then
					Oxygene.rmBwRule(user, params[3])
				elseif not params[4] or not params[5] then
				elseif params[2] == "ulimit" then
					Oxygene.setThreshold( user, params[3], params[4], params[5] )
				elseif params[2] == "minbw" then
					Oxygene.setMinBw( user, params[3] )
				elseif not params[6] or not params[7] or not params[8] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "add" then
						-- <upper_bandwidth> <minslot> <maxslot> <slotrec> <maxhub> <maxhub_kick>
						Oxygene.addBwRule(user, params[3], params[4], params[5], params[6], params[7], params[8])
				else
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				end
			elseif params[1] == "-chprofiles" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt("Missing parameters. See -help chprofiles", true)
					end
				elseif params[2] == "list" then
					if user then
						Oxygene.sendKickProfilesTo(user)
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif params[2] == "rm" then
					Oxygene.rmProfile(user, params[3])
				elseif params[2] == "setdefault" then
					Oxygene.selectProfile(user, params[3])
				elseif not params[4] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif not params[5] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif params[2] == "add" then
					Oxygene.addProfile( user, params[3], params[4], string.sub( command, 5 + string.len( params[1] ) + string.len( params[2] ) + string.len( params[3] ) + string.len( params[4] ), string.len( command ) ) )
					-- Oxygene.addProfile( user, params[3], string.sub( command, 4 + string.len( params[1] ) + string.len( params[2] ) + string.len( params[3] ), string.len( command ) ) )
				else
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chprofiles", true)
					end
				end
			elseif params[1] == "-chgetconfig" then
				if user then
					Oxygene.getConfig(user)
				end
			elseif params[1] == "-chset" then
				if params[2] and params[3] then
					Oxygene.setConfig(user, params[2], params[3])
				else
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help", true)
					end
				end
			elseif params[1] == "-chreload" then
				if Oxygene.loadLanguage() then
					if user then
						user:sendPrivMsgFmt( "Language file loaded", true)
					end
					local counter = Oxygene.refreshAllUserData(hub)
					if user then
						user:sendPrivMsgFmt( tostring(counter) .. " userdata updated", true)
						user:sendPrivMsgFmt( "OK" )
					end
				else
					if user then
						user:sendPrivMsgFmt( "Non-existing language-file. Default (US) language is loaded instead.", true)
					end
				end
			elseif params[1] == "-chsay" then
					local chattext = string.sub(command, string.len(params[1]) + 2, string.len(command) )
					if string.len(chattext) > 0 then
						hub:sendChat(Oxygene.evaluateVariables(chattext, hub, nil))
					else
						if user then
							user:sendPrivMsgFmt( "Empty message, not sent.", true)
						end
					end
			end	
end

--// Initializing //--

dofile(DC():GetAppPath() ..  "scripts/libsimplepickle.lua")
Oxygene.loadSettings()

--// Listeners //--

dcpp:setListener("connected", "oxygene_conn", 
	function (hub)
		local tolog = "[CONN] Connected to hub: " .. hub:getUrl()
		if not hub.oxygene then
			hub.oxygene = {}
			hub.oxygene.state = { }
			hub.oxygene.state.started = os.date("%Y. %m. %d - %H:%M:%S")
			hub.oxygene.state.connected = os.time()
			hub.oxygene.state.active = false --// provides 2 minutes inactivity to avoid pm-flooding, some hubs don't like that
			hub.oxygene.userlist = {}
		end
		if Oxygene.isAllowed( hub ) then
			tolog = tolog .. ". The hub is added to the allowed hubs' list."
			-- hub:sendChat("Checkslot " .. Checkslotsettings.version .. " has launched (on ..). Az Elite-hub alapszabálya: Viselkedj úgy, ahogy szeretnéd, hogy mások veled viselkedjenek.")
		end
		Oxygene.log(tolog)
	end
)

dcpp:setListener("disconnected", "oxygene_disc", 
	function (hub)
		-- freeing up some memory
		local mem1 = collectgarbage("count")
		collectgarbage("collect")
		Oxygene.log("[CONN] Disconnected from hub: " .. hub:getUrl())
		Oxygene.log("[TRIG] " .. math.floor(mem1 - (collectgarbage("collect")) * 100)/100 .. " KiB memory has been freed" )
	end
)

dcpp:setListener( "pm", "oxygene_pm",
	function( hub, user, text )
		local isop = user:isOp()
		local isallowed = Oxygene.isAllowed( hub )
		local params = Oxygene.tokenize(text)
		if isop and isallowed then
			Oxygene.commandParser(hub, user, text)
		end
		if isop then
			if params[1] == "-chaddhub" then
				if Oxygene.addHub(hub, params[2]) then
					user:sendPrivMsgFmt( "OK. Reconnect to the hub with the client running this script to get correct userlist and stat.", true )
				else
					user:sendPrivMsgFmt( "The hub couldn't be added (probably it's already done). See -chlisthubs", true)
				end
			elseif params[1] == "-chrmhub" then
				if Oxygene.rmHub(hub, params[2]) then
					user:sendPrivMsgFmt( "OK", true )
				else
					user:sendPrivMsgFmt( "The hub couldn't be removed (probably it's even not added to the list). See -chlisthubs", true)
				end
			elseif params[1] == "-chlisthubs" then
				Oxygene.listHubs(hub, user, true)
			end
		end
	end
)

dcpp:setListener( "chat", "oxygene_chat",
	function( hub, user, text )
		local isop = user:isOp()
		local isallowed = Oxygene.isAllowed( hub )
		if isallowed then
			local userdata = Oxygene.buildUserData( hub, user, "chatmsg", text )
			Oxygene.updateUser(hub, userdata)
			Oxygene.activateTriggers( hub, user:getNick(), "MSG" )
		end
		if isop and isallowed then
			local params = Oxygene.tokenize(text)
			if params[1] == "-help" or params[1] == "-?" then
				if params[2] then
					Oxygene.getHelpFor(user, params[2])
				else
					Oxygene.sendHelp(hub, user)
				end
			elseif params[1] == "-scripts" then
				hub:sendChat("oxygene.lua: Running on this hub since: " .. hub.oxygene.state.started .. " (" .. Checkslotsettings.version .. ")")
			end
		end
	end
)

dcpp:setListener( "userMyInfo", "oxygene_myinfo",
	function( hub, user, myinfo )
		if Oxygene.isAllowed( hub ) then
			-- DC():PrintDebug( "$MyINFO: [" .. hub:getUrl() .. "]: " .. user:getNick() )
			local userdata = Oxygene.buildUserData(hub, user, "myinfo", myinfo)
			Oxygene.updateUser(hub, userdata)
			Oxygene.activateTriggers( hub, user:getNick(), "INF" )
		end
	return nil
	end
)

dcpp:setListener( "userQuit", "oxygene_userquit",
	function( hub, nick )
		if Oxygene.isAllowed( hub ) then
			Oxygene.removeUserFromHub(hub, nick )
		end
	return nil
	end
)

dcpp:setListener( "raw", "oxygene_raw",
	function( hub, line )
		if string.sub(line, 1, 7) == "$OpList" then
			if Oxygene.isAllowed( hub ) then
				-- DC():PrintDebug("[OPLIST] " .. line)
				Oxygene.fixOpList( hub, line )
			end
		end
	return nil
	end
)

dcpp:setListener( "timer", "oxygene_timer",
	function()
		if os.time() >= ( Checkslotsettings.lastupdated + Checkslotsettings.config.inactivetime ) then
			Checkslotsettings.lastupdated = os.time()
			for k,hub in pairs(dcpp:getHubs()) do
				if os.time() >= ( hub.oxygene.state.connected + Checkslotsettings.config.inactivetime ) then
					if (not hub.oxygene.state.active) then
						hub.oxygene.state.active = true
						if Oxygene.isAllowed( hub ) then
							hub:sendChat(Oxygene.GETSTRING("GeneralStart"))
						end
					end
				end
			end
		end
		if Checkslotsettings.hasTimerTrig ~= 0 then
			for k,hub in pairs(dcpp:getHubs()) do
				if Oxygene.isAllowed( hub ) then
					Oxygene.activateTriggers(hub, nil, "timer")
				end
			end
		end
	end																			
)

DC():PrintDebug( "  ** Loaded oxygene.lua **" )
