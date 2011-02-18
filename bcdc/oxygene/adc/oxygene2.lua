--// WELCOME AND LICENSE //--
--[[ 
     oxygene2.lua -- Version 2.0beta
     oxygene2.lua -- An all-round BCDC++ slotrules and trigger bot for ADC hubs
     oxygene2.lua -- A.I. for BCDC++ ;)
     oxygene2.lua -- Rev 017, Last modified: Oct 23, 2009

     Copyright (C) 2004-2009 Szabolcs Molnár <fleet@elitemail.hu>
     
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
     017/20091023: Fixed a few null exception (thanks Pirre for reporting)
     016/20080712: Fixed minimum bandwidth checking (thanks Pirre for reporting)
     015/20080707: Upgraded to work with latest startup.lua
     014/20080627: Modified: Removed checking bandwidth in DE field
     013/20080410: Modified: AdcOxygene -> oxygene2
     012/20080107: Fixed: Kicking users without Nick (thanks Pirre for reporting), one or two other possible errors
     011/20080104: Fixed: Hub count parameters
     010/20070814: Fixed: -chsay parses parameters too
     009/20070731: Fixed: A bug when sending files to main chat from timer
     008/20070731: Fixed: The script no more starts a new line when sending file content to main chat (Oxygene.lua R096)
     007/20070517: Fixed: Cancelled fields are removed from userdata
     006/20070517: Added %[userSID], %[userCID], %[mySID], %[myCID] to trigger variables, cid protection added for -chprotect
     005/20070516: Kick profiles work, new variables added for them (%[mySID], %[myCID], %[userSID], %[userCID])
     004/20070516: More trigger fixes, upgraded to work with startup.lua 1.1.9
     003/20070516: Fixed some bugs
     002/20070516: Synced to Oxygene.lua R095
     001/20061029: Initial modifications to get this script work on ADC hubs, building userdata, -chgetinfo works
]]

--// Initialize script //--
DC():RunTimer(1)

--// Helper functions //--

oxygene2 = {}
oxygene2.lang = {}
oxygene2.internal = {}
oxygene2.internal.version = "2.0beta"
oxygene2.internal.settingsfile = DC():GetAppPath() ..  "scripts\\oxygene2_settings.txt"

oxygene2.GetComma = function(this)
	local temp = 11e-1
	temp = tostring(temp)
	temp = string.sub(temp, 2, 2)
	return temp
end

--// Remaining functions //--

oxygene2.ToNumber = function(this, text)
	if text == nil then
		return 0
	end
	local temp = ""
	local badchar = ","
	if Oxygenesettings.commachar == "," then
		badchar = "."
	end
	local pat = "(%" .. badchar .. ")"
	temp = string.gsub(text, pat, Oxygenesettings.commachar)
	local pat2 = "([%-]?[%d]*[%" .. Oxygenesettings.commachar .. "]?[%d]*)(.*)"
	temp = string.gsub(temp, pat2, "%1")
	temp = tonumber(temp)
	if temp == nil then
		temp = 0
	end
	return temp
end

oxygene2.FormatBytes = function(this, bytes)
	local ret = bytes
	local me = { [1] = "B", [2] = "KiB", [3] = "MiB", [4] = "GiB", [5] = "TiB"}
	local i = 0
	repeat
		i = i + 1
	until((i >= 5) or ( (bytes / (1024^ (i-1))) < 1024))
	ret = tostring(math.floor(100 * bytes / (1024 ^ (i-1))) / 100) .. " " .. me[i]
	return ret
end

oxygene2.OnOff = function( this, variable)
	local ret = "on"
	if (variable == 0) or (variable == nil) or (variable == false) then
		ret = "off"
	end
	return ret
end

oxygene2.YesNo = function( this, variable)
	local ret = "yes"
	if (variable == 0) or (variable == nil) or (variable == false) then
		ret = "no"
	end
	return ret
end

function oxygene2.userCount(hub)
	local k = 0
	for i in pairs(hub.oxygene2.userlist) do
		k = k + 1
	end
	return k
end

function oxygene2.opCount(hub)
	local count = 0
	for k in pairs(hub.oxygene2.userlist) do
		if hub.oxygene2.userlist[k].isop then
			count = count + 1
		end
	end
	return count
end

function oxygene2.log(text, logfile)
	if not logfile then
		logfile = Oxygenesettings.logfile
	end
	local o, err = io.open( logfile, "a+" )
	if o then
		o:write( "[" .. os.date("%Y. %m. %d. - %H:%M:%S") .. "] " .. text .. "\n" )
		o:close()
	else
		DC():PrintDebug("[oxygene2] Can't open logfile: \"" .. logfile .. "\". Error: " .. err)
	end
end

function oxygene2.saveSettings()
	pickle.store( oxygene2.internal.settingsfile, { Oxygenesettings = Oxygenesettings })
end

function oxygene2.GETSTRING(var)
	return oxygene2._LANG[var]
end

--// Manage configuration //--

function oxygene2.getConfigValue(var)
	return Oxygenesettings.config[var]
end

function oxygene2.getConfig(user)
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt(oxygene2.evaluateVariables("           Configuration\t\t\tOxygene %[version]", nil, nil), true)
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	for k in pairs(Oxygenesettings.config) do
		user:sendPrivMsgFmt("           " .. k .. "\t\t\t" .. Oxygenesettings.config[k], true)
	end
	user:sendPrivMsgFmt("           -------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return nil
end

-- returns true if setting's modified. false if remained the same or failed
function oxygene2.setConfig(user, variable, value)
	local modified = false
	local nice = true
	local state = ""
	local oldval = ""
	local vartype = type( Oxygenesettings.config[variable] )

	if vartype == "number" then
		value = oxygene2:ToNumber(value)		
	elseif vartype == "nil" then
		state = "non-existing variable"
		nice = false
	end
	if nice then
		oldval = Oxygenesettings.config[variable]
		Oxygenesettings.config[variable] = value
		oxygene2.saveSettings()
		if oldval ~= value then
			modified = true
		end
	end
	if user then
		if nice then
			user:sendPrivMsgFmt("[" .. vartype .. "][" .. tostring(oldval) .. " >> " .. tostring(Oxygenesettings.config[variable]) .. "] OK", true)
			oxygene2.log( "[CONFIG] " .. user:getNick() .. ": " .. variable .. " = " .. tostring(Oxygenesettings.config[variable]) .. " (" .. tostring(oldval) ..")")
		else
			user:sendPrivMsgFmt("[" .. state .."] Couldn't set value", true)
		end
	end
	return modified
end

--// Manage slotrules //--

function oxygene2.isRuleFor(bw)
	local ret = false
	bw = tonumber(bw)
	for k in ipairs(Oxygenesettings.bwrules) do
		if Oxygenesettings.bwrules[k].bandwidth == bw then
			ret = true
		end
	end
	return ret
end

function oxygene2.sortBwTable()
	local i = #Oxygenesettings.bwrules
	for k = 1, i-1, 1 do
		for l = k+1, i, 1 do
			if Oxygenesettings.bwrules[k].bandwidth > Oxygenesettings.bwrules[l].bandwidth then
				Oxygenesettings.bwrules[k].bandwidth, Oxygenesettings.bwrules[l].bandwidth = Oxygenesettings.bwrules[l].bandwidth, Oxygenesettings.bwrules[k].bandwidth
				Oxygenesettings.bwrules[k].minslot, Oxygenesettings.bwrules[l].minslot = Oxygenesettings.bwrules[l].minslot, Oxygenesettings.bwrules[k].minslot
				Oxygenesettings.bwrules[k].maxslot, Oxygenesettings.bwrules[l].maxslot = Oxygenesettings.bwrules[l].maxslot, Oxygenesettings.bwrules[k].maxslot
				Oxygenesettings.bwrules[k].slotrec, Oxygenesettings.bwrules[l].slotrec = Oxygenesettings.bwrules[l].slotrec, Oxygenesettings.bwrules[k].slotrec
				Oxygenesettings.bwrules[k].maxhub, Oxygenesettings.bwrules[l].maxhub = Oxygenesettings.bwrules[l].maxhub, Oxygenesettings.bwrules[k].maxhub
				Oxygenesettings.bwrules[k].maxhub_kick, Oxygenesettings.bwrules[l].maxhub_kick = Oxygenesettings.bwrules[l].maxhub_kick, Oxygenesettings.bwrules[k].maxhub_kick
			end
		end
	end
	-- put the bw -1 to the end of the list (-1 means "all other bandwidth")
	for k = 1, i-1, 1 do
		if Oxygenesettings.bwrules[k].bandwidth == -1 then
				Oxygenesettings.bwrules[k].bandwidth, Oxygenesettings.bwrules[k+1].bandwidth = Oxygenesettings.bwrules[k+1].bandwidth, Oxygenesettings.bwrules[k].bandwidth
				Oxygenesettings.bwrules[k].minslot, Oxygenesettings.bwrules[k+1].minslot = Oxygenesettings.bwrules[k+1].minslot, Oxygenesettings.bwrules[k].minslot
				Oxygenesettings.bwrules[k].maxslot, Oxygenesettings.bwrules[k+1].maxslot = Oxygenesettings.bwrules[k+1].maxslot, Oxygenesettings.bwrules[k].maxslot
				Oxygenesettings.bwrules[k].slotrec, Oxygenesettings.bwrules[k+1].slotrec = Oxygenesettings.bwrules[k+1].slotrec, Oxygenesettings.bwrules[k].slotrec
				Oxygenesettings.bwrules[k].maxhub, Oxygenesettings.bwrules[k+1].maxhub = Oxygenesettings.bwrules[k+1].maxhub, Oxygenesettings.bwrules[k].maxhub
				Oxygenesettings.bwrules[k].maxhub_kick, Oxygenesettings.bwrules[k+1].maxhub_kick = Oxygenesettings.bwrules[k+1].maxhub_kick, Oxygenesettings.bwrules[k].maxhub_kick
		end
	end
end

function oxygene2.rmBwRule(user, bw)
	local managed = false
	bw = tonumber(bw)
	for k in ipairs(Oxygenesettings.bwrules) do
		if Oxygenesettings.bwrules[k].bandwidth == bw then
			table.remove(Oxygenesettings.bwrules, k)
			managed = true
		end
	end
	if user then
		if managed then
			if oxygene2.setConfig(nil, "slotcheck", "off") then
				user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
			end
			user:sendPrivMsgFmt("OK", true)
		else
			user:sendPrivMsgFmt("The given bandwidth couldn't be removed. See -chrules list", true)
		end
	end
	oxygene2.saveSettings()
	return managed
end

function oxygene2.addBwRule(user, bw, minslot, maxslot, slotrec, maxhub, maxhub_kick)
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
	if oxygene2.isRuleFor(bw) then
		state = "overwrite"
		oxygene2.rmBwRule(nil, bw)
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
	table.insert( Oxygenesettings.bwrules, temp)
	oxygene2.sortBwTable()
	oxygene2.saveSettings()
	if user then
		if oxygene2.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("[" .. state .. "] OK", ture)
	end
	return nil
end

function oxygene2.clearBwRules( user )
	for k = 1, #Oxygenesettings.bwrules, 1 do
		table.remove( Oxygenesettings.bwrules )
	end
	if user then
		if oxygene2.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("OK", true)
	end
	return nil
end

function oxygene2.resetBwRules( user )
	oxygene2.clearBwRules( nil )
	oxygene2.addBwRule( nil, 0.05 ,  2,  2,  2,  2,  4 )
	oxygene2.addBwRule( nil, 0.1  ,  3,  3,  3,  3,  5 )
	oxygene2.addBwRule( nil, 0.2  ,  4,  4,  4,  4,  6 )
	oxygene2.addBwRule( nil, 0.5  ,  4,  6,  5,  6,  8 )
	oxygene2.addBwRule( nil, 1    ,  6,  8,  7,  8, 10 )
	oxygene2.addBwRule( nil, 2    ,  8, 10,  9,  8, 10 )
	oxygene2.addBwRule( nil, 5    , 11, 20, 15,  8, 10 )
	oxygene2.addBwRule( nil, 10   , 18, 35, 25, 10, 12 )
	oxygene2.addBwRule( nil, 20   , 30, 50, 40, 13, 15 )
	oxygene2.addBwRule( nil, 50   , 30, 60, 40, 13, 15 )
	oxygene2.addBwRule( nil, 100  , 30, 75, 40, 13, 15 )
	oxygene2.addBwRule( nil, -1   , 30, 75, 40, 13, 15 )
	Oxygenesettings.bandwidthmultipler = "0.6"
	Oxygenesettings.minulimit = 12
	Oxygenesettings.ulimitbw = 0.1
	Oxygenesettings.minbw = 0.05
	if user then
		if oxygene2.setConfig(nil, "slotcheck", "off") then
			user:sendPrivMsgFmt("Automatic slotchecking disabled. When you finished configuring the rules, don't forget to re-enable it. See -chgetconfig and -chset", true)
		end
		user:sendPrivMsgFmt("OK", true)
	end
	return nil
end

function oxygene2.updateConfig()
	local needtosave = false
	for k in pairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].interval == nil then
			Oxygenesettings.triggers[k].interval = 0
			needtosave = true
		end
		if Oxygenesettings.triggers[k].lastactivation == nil then
			Oxygenesettings.triggers[k].lastactivation = 0
			needtosave = true
		end
		-- rev076
		if (Oxygenesettings.triggers[k].counter == nil) or (Oxygenesettings.triggers[k].counterreset) == nil then
			Oxygenesettings.triggers[k].counter = 0
			Oxygenesettings.triggers[k].counterreset = os.time()
			needtosave = true
		end
	end
	for k in ipairs(Oxygenesettings.kickprofiles) do
		if Oxygenesettings.kickprofiles[k].type == nil then
			Oxygenesettings.kickprofiles[k].type = "c"
			needtosave = true
		end
	end
	if needtosave then
		oxygene2.saveSettings()
	end
	return true
end

function oxygene2.initializeSettings()
	-- Set default values if don't exist:
	if not Oxygenesettings then Oxygenesettings = { } end
	if not Oxygenesettings.allowedaddress then Oxygenesettings.allowedaddress = {} end
	if not Oxygenesettings.triggers then Oxygenesettings.triggers = { } end
	if not Oxygenesettings.bandwidthmultipler then Oxygenesettings.bandwidthmultipler = "0.60" end --// 60 %
	if not Oxygenesettings.minulimit then Oxygenesettings.minulimit = 12 end --// 12 KiB/sec
	if not Oxygenesettings.ulimitbw then Oxygenesettings.ulimitbw = 0.1 end --// bandwidth rule only applied for 0.1 and larger line speeds
	if not Oxygenesettings.minbw then Oxygenesettings.minbw = 0.05 end
	if not Oxygenesettings.config then Oxygenesettings.config = { } end
	if not Oxygenesettings.config.slotcheck then Oxygenesettings.config.slotcheck = "off" end
	if not Oxygenesettings.config.opchat_name then Oxygenesettings.config.opchat_name = "OpChat" end
	if not Oxygenesettings.config.triggers then Oxygenesettings.config.triggers = 0 end
	if not Oxygenesettings.config.inactivetime then Oxygenesettings.config.inactivetime = 120 end --// 2 minutes
	if not Oxygenesettings.config.ulimitcheck then Oxygenesettings.config.ulimitcheck = 1 end
	if not Oxygenesettings.config.minshare then Oxygenesettings.config.minshare = 0 end
	if not Oxygenesettings.config.rulesurl then Oxygenesettings.config.rulesurl = "http://www.myhub.com/slotrules.asp" end
	if not Oxygenesettings.config.language then Oxygenesettings.config.language = "US" end
	if not Oxygenesettings.config.trigcase then Oxygenesettings.config.trigcase = 0 end
	if not Oxygenesettings.config.reversebandwidth then Oxygenesettings.config.reversebandwidth = 1 end
	--// TODO
	-- if not Oxygenesettings.config.logging then Oxygenesettings.config.logging = 1 end
	
	if not Oxygenesettings.bwrules then
		Oxygenesettings.bwrules = {}
		oxygene2.resetBwRules( nil )
	end
	
	if not Oxygenesettings.userexceptions then Oxygenesettings.userexceptions = {} end
	
	if not Oxygenesettings.kickprofiles then
		Oxygenesettings.kickprofiles = { }
		local temptable = { }
		temptable.name = "rawexample"
		temptable.command = "BMSG %[mySID] +kick\\\\s%[userNI]\\\\s%[reason]"
		temptable.type = "r"
		table.insert( Oxygenesettings.kickprofiles, temptable )
		temptable = { }
		temptable.name = "adchpp"
		temptable.command = "+kick %[userNI] %[reason]"
		temptable.type = "c"
		table.insert( Oxygenesettings.kickprofiles, temptable )
	end
	
	if not Oxygenesettings.currentprofile then Oxygenesettings.currentprofile = "adchpp" end


	-- this function updates the config file if any changes are made in the structure
	oxygene2.updateConfig()
	
	-- Values which needs a reset everytime
	Oxygenesettings.logfile = DC():GetAppPath() ..  "scripts\\oxygene2_log.log"
	Oxygenesettings.kicklog = DC():GetAppPath() ..  "scripts\\oxygene2_kicks.log"
	Oxygenesettings.possibleTrigVariables = oxygene2.getPossibleTrigVariables()
	Oxygenesettings.possibleTrigStrings = oxygene2.getPossibleStringConditions()
	Oxygenesettings.possibleTrigNums = oxygene2.getPossibleNumConditions()
	Oxygenesettings.dcSpeeds = oxygene2.getDcSpeeds()
	
	Oxygenesettings.hasTimerTrig = oxygene2.doesTimerTrigExist() --// 0, 1
	Oxygenesettings.commachar = oxygene2:GetComma()
	if not Oxygenesettings.version then
		Oxygenesettings.version = oxygene2.internal.version
	elseif Oxygenesettings.version ~= oxygene2.internal.version then
		oxygene2.log( "[oxygene2] Version changed from " .. Oxygenesettings.version .. " to " .. oxygene2.internal.version .. ". Version will be stored in the setting file on the first change of any setting.")
		Oxygenesettings.version = oxygene2.internal.version
	end
	Oxygenesettings.lastupdated = os.time()
	return 1
end

function oxygene2.resetLanguage()
	oxygene2._LANG = {
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
		TooSmallBw = "Your upload line speed is specified as %1 MiBit/sec. This would mean that you are able to upload only by %2 KiB/s. This is so small value that probably you set the wrong upload line speed in your settings. Please correct this!",
		ThisIsAnAutomessage = "This is an automatic message: ",
		GeneralStart = "oxygene2.lua: Automatic checking started",
		KickBroadcast = "%1 users have been kicked because of violating slotrules"
	}
	return true
end

function oxygene2.loadLanguage()
	local ret = false
	local filename = DC():GetAppPath() ..  "scripts\\oxygene2.lang." .. oxygene2.getConfigValue("language") .. ".lua"
	local o = io.open( filename, "r" )
	if o then
		o:close()
		dofile ( filename )
		ret = true
	else
		-- Wrong/Missing language file, set the default values instead
		oxygene2.resetLanguage()
		oxygene2.setConfig(nil, "language", "US")
	end
	return ret
end

function oxygene2.loadSettings()
	local o = io.open( oxygene2.internal.settingsfile, "r" )
	if o then
		dofile( oxygene2.internal.settingsfile )
		o:close()
	end
	oxygene2.initializeSettings()
	oxygene2.loadLanguage()
	return 1
end

function oxygene2.isAllowed(hub)
	local allowed = false
	local url = hub:getUrl()
	for k in ipairs(Oxygenesettings.allowedaddress) do
		if url == Oxygenesettings.allowedaddress[k] then
			allowed = true
			break
		end
	end
	return allowed
end

function oxygene2.isAllowedUrl(url)
	local allowed = false
	for k in ipairs(Oxygenesettings.allowedaddress) do
		if url == Oxygenesettings.allowedaddress[k] then
			allowed = true
			break
		end
	end
	return allowed
end

function oxygene2.addUrl(url)
	table.insert(Oxygenesettings.allowedaddress, url)
	oxygene2.saveSettings()
end

function oxygene2.addHub(hub, url)
	if not url then
		-- if no second parameter we try to add the current hub
		url = hub:getUrl()
	end
	local success = false
	if not oxygene2.isAllowedUrl(url) then
		oxygene2.addUrl(url)
		success = true
	end
	return success
end

function oxygene2.rmHub(hub, url)
	if not url then
		-- if no host specified, try to remove the current hub
		url = hub:getUrl()
	end
	local success = false
	if oxygene2.isAllowedUrl(url) then
		for k in ipairs(Oxygenesettings.allowedaddress) do
			if Oxygenesettings.allowedaddress[k] == url then
				table.remove(Oxygenesettings.allowedaddress, k )
			end
		end
		success = true
	else
		success = false
	end
	oxygene2.saveSettings()
	return success
end

function oxygene2.listHubs(hub, user, pm)
	local message = "\n     -----------------------------------------------------\n     Currently allowed hubs:\n     -----------------------------------------------------\n"
	for k in ipairs(Oxygenesettings.allowedaddress) do
		message = message .. "     " .. Oxygenesettings.allowedaddress[k] .. "\n"
	end
	message = message .. "     -----------------------------------------------------"
		if pm then
			user:sendPrivMsgFmt(message, true)
		else
			hub:sendChat(message)
		end
end

function oxygene2.pmOpChat( hub, message )
	hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), message, true)
	return true
end

-- if user is nil, then sends to mainchat; target: "mainchat", "pm" or nil
function oxygene2.sendFile(hub, user, filename, relative, target)
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
				szoveg = oxygene2.evaluateVariables(szoveg, hub, oxygene2.getUserData( hub, user:getSid() ))
			else
				szoveg = oxygene2.evaluateVariables(szoveg, hub, nil)
			end
			if target == "pm" then
				user:sendPrivMsg( szoveg, true )
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
		hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), "[ERROR] Can't open file: \"" .. filename.."\". Error: " .. err, true)
	end
	return true
end

function oxygene2.sendHelp(hub, user)
	oxygene2.sendFile(hub, user, DC():GetAppPath() ..  "scripts\\oxygene2.help." .. oxygene2.getConfigValue("language") .. ".txt", false, "pm")
	return true
end

--*****************************
--** TRIGGER functions
--*****************************

-- Resets condition table (needs executing everytime the script starts)
function oxygene2.getPossibleTrigVariables()
	local trigCon = {}
	
	--// Strings
	local tmp = {}
	tmp.name = "%[userNI]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	local tmp = {}
	tmp.name = "%[userSID]"
	tmp.type = "string"
	table.insert( trigCon, tmp )
	local tmp = {}
	tmp.name = "%[userCID]"
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
	tmp.name = "%[mySID]"
	tmp.type = "string"
	table.insert( trigCon, tmp)
	tmp = {}
	tmp.name = "%[myCID]"
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

function oxygene2.getPossibleNumConditions()
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

function oxygene2.getDcSpeeds()
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

function oxygene2.getPossibleStringConditions()
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
function oxygene2.getVariableType( parameter )
	local ret = nil
	for k in ipairs(Oxygenesettings.possibleTrigVariables) do
		if Oxygenesettings.possibleTrigVariables[k].name == parameter then
			ret = Oxygenesettings.possibleTrigVariables[k].type
		end
	end
	return ret
end

function oxygene2.isPossibleNumCondition( condition_name )
	local ret = false
	for k in ipairs(Oxygenesettings.possibleTrigNums) do
		if Oxygenesettings.possibleTrigNums[k] == condition_name then
			ret = true
		end
	end
	return ret
end

function oxygene2.isPossibleStringCondition( condition_name )
	local ret = false
	for k in ipairs(Oxygenesettings.possibleTrigStrings) do
		if Oxygenesettings.possibleTrigStrings[k] == condition_name then
			ret = true
		end
	end
	return ret
end

function oxygene2.isVariableBetween( condition_type, value, condition_string )
	local indomain = false
	local pattern = "^([%d%.,]+)\-([%d%.,]+)"
	local invert = false
	if string.find( condition_string, pattern ) then
		local min = oxygene2:ToNumber(string.gsub( condition_string, "^([%d%.,]+)\-([%d%.,]+)$", "%1"))
		local max = oxygene2:ToNumber(string.gsub( condition_string, "^([%d%.,]+)\-([%d%.,]+)$", "%2"))
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

function oxygene2.isTrigBlocked( triggertable, listener_type )
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
			elseif ccon ~= "%[version]" and ccon ~= "%[myNI]" and ccon ~= "%[mySID]" and ccon ~= "%[myCID]" and ccon ~= "%[usercount]" and ccon ~= "%[opcount]" then
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
function oxygene2.doesTimerTrigExist()
	local exists = 0
	for k in ipairs(Oxygenesettings.triggers) do
		if not oxygene2.isTrigBlocked( Oxygenesettings.triggers[k], "timer" ) then
			exists = 1
		end
	end
	return exists
end

-- Getting variables. Return with the value and the type ("string" or "num")
function oxygene2.getValue(variable, hub, userdata)
	local ret, vartype = "", ""
	if userdata then
		if variable == "%[userNI]" then
			if userdata.fields.NI then
				ret = userdata.fields.NI
			else
				ret = ""
			end
			vartype = "string"
		elseif variable == "%[userSID]" then
			ret = userdata.sid
			vartype = "string"
		elseif variable == "%[userCID]" then
			ret = userdata.fields.ID
			vartype = "string"
		elseif variable == "%[userNIshort]" then
			if userdata.fields.NI then
				ret = userdata.fields.NI
				if ret and string.find( ret, "%[.-%]." ) then
					ret = string.gsub(ret,"%[.-%](.+)","%1")
				end
			else
				ret = ""
			end
			vartype = "string"
		elseif variable == "%[userSSshort]" then
			ret = userdata.fields.SS
			if ret then
				ret = oxygene2:FormatBytes(oxygene2:ToNumber(ret))
			end
			vartype = "string"
		elseif variable == "%[userDE]" then
			ret = userdata.fields.DE
			vartype = "string"
		elseif variable == "%[client_type]" then
			if userdata.fields.VE then
				local temptable = oxygene2.tokenize(userdata.fields.VE)
				ret = temptable[1]
			end
			vartype = "string"
		elseif variable == "%[tagV]" then
			if userdata.fields.VE then
				local temptable = oxygene2.tokenize(userdata.fields.VE)
				if temptable[2] then
					ret = temptable[2]
				end
			end
			ret = oxygene2:ToNumber(userdata.tag.client_ver)
			vartype = "num"
		elseif variable == "%[tagVE]" then
			ret = userdata.fields.VE
			vartype = "string"
		elseif variable == "%[tagM]" then
			if userdata.fields.I4 then
				ret = "A"
			else
				ret = "P"
			end
			vartype = "string"
		elseif variable == "%[tagHN]" then
			ret = oxygene2:ToNumber(userdata.fields.HN)
			vartype = "num"
		elseif variable == "%[tagHR]" then
			ret = oxygene2:ToNumber(userdata.fields.HR)
			vartype = "num"
		elseif variable == "%[tagHO]" then
			ret = oxygene2:ToNumber(userdata.fields.HO)
			vartype = "num"
		elseif variable == "%[tagSL]" then
			ret = oxygene2:ToNumber(userdata.fields.SL)
			vartype = "num"
		elseif variable == "%[tagO]" then
			--// TODO: Fix this
			ret = oxygene2:ToNumber(userdata.tag.auto_open)
			vartype = "num"
		elseif variable == "%[connection]" then
			--// TODO
			ret = userdata.connection
			vartype = "string"
		elseif variable == "%[userEM]" then
			ret = userdata.fields.EM
			vartype = "string"
		elseif variable == "%[userSS]" then
			ret = oxygene2:ToNumber(userdata.fields.SS)
			vartype = "num"
		elseif variable == "%[downBW]" then
			ret = oxygene2:ToNumber(userdata.down_bw)
			vartype = "num"
		elseif variable == "%[upBW]" then
			ret = oxygene2:ToNumber(userdata.up_bw)
			vartype = "num"
		elseif variable == "%[hour]" then
			ret = oxygene2:ToNumber(os.date("%H"))
			vartype = "num"
		elseif variable == "%[min]" then
			ret = oxygene2:ToNumber(os.date("%M"))
			vartype = "num"
		elseif variable == "%[sec]" then
			ret = oxygene2:ToNumber(os.date("%S"))
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
		elseif variable == "%[version]" then
			ret = Oxygenesettings.version
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
			ret = oxygene2:ToNumber(os.date("%H"))
			vartype = "num"
		elseif variable == "%[min]" then
			ret = oxygene2:ToNumber(os.date("%M"))
			vartype = "num"
		elseif variable == "%[sec]" then
			ret = oxygene2:ToNumber(os.date("%S"))
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
		elseif variable == "%[version]" then
			ret = Oxygenesettings.version
			vartype = "string"
		else
			ret = nil
		end
	end
	if hub then
		if variable == "%[myNI]" then
			ret = hub:getOwnNick()
			vartype = "string"
		elseif variable == "%[mySID]" then
			ret = hub:getOwnSid()
			vartype = "string"
		elseif variable == "%[myCID]" then
			ret = hub:getOwnCid()
			vartype = "string"
		elseif variable == "%[usercount]" then
			ret = oxygene2.userCount(hub)
			vartype = "num"
		elseif variable == "%[opcount]" then
			ret = oxygene2.opCount(hub)
			vartype = "num"
		end
	end
	if not ret then
		if vartype == "string" then
			ret = ""
		elseif vartype == "num" then
			ret = 0
		end
	end
	return ret, vartype
end

function oxygene2.evaluateExpression(expression)
	-- DC():PrintDebug("Expression: " .. expression )
	expression = string.gsub(tostring(expression), "([%d]+),([%d]+)", "%1.%2")
	local func = loadstring( "return (" .. expression .. ")")
	local suc, res = pcall(func)
	return suc, res
end

function oxygene2.evaluateVariables(text, hub, userdata)
	local variables = {}
	local modmessage = text
	string.gsub( text, "(%%%[[a-zA-Z_]-%])", function( s ) table.insert( variables, s ) end )
	for k in pairs(variables) do
		local value = oxygene2.getValue(variables[k], hub, userdata)
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
function oxygene2.checkTrigger( hub, userdata, triggertable, listener_type )
	local allconditionsmet, tmpfulfilled = true, true
	local anyconditionsmet, retvalue = false, false
	local blocktrigger = oxygene2.isTrigBlocked( triggertable, listener_type )
	if triggertable.state == "-" then
		-- disabled condition, assume as 
		return false
	end
	if blocktrigger then
		return false
	end
	
	-- anyway needs checking...
	
	for k in ipairs(triggertable.conditions) do
		tmpfulfilled = oxygene2.checkCondition(hub, userdata, triggertable.conditions[k], listener_type)
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
		oxygene2.log("#ERR004: " .. triggertable.type .. " is not a valid value.. ")
	end
	return retvalue
end

-- Checking a condition
--// listener_type possible values are: "MSG", "INF", "timer"
function oxygene2.checkCondition(hub, userdata, ctable, listener_type)
	local ctype, ccondition, cwhat = "", "", ""
	local ctemp, vartype, special = "", "num", false
	local fulfilled = false
	
	ctype, ccondition, cwhat = ctable.type, ctable.condition, ctable.what

	--// For debugging reasons:
	local cwhat_original = cwhat
	
	cwhat = oxygene2.evaluateVariables(cwhat, hub, userdata)
	

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
		ctemp, vartype = oxygene2.getValue(ctype, hub, userdata)
		if not ctemp then
			oxygene2.log("# STRUCTURE ERROR 1: Invalid condition type [regular]: " .. ctype)
		end
	else
		ctemp, vartype = oxygene2.getValue(ctype, hub, nil)
		if not ctemp then
			oxygene2.log("# STRUCTURE ERROR 1: Invalid condition type [timer][" .. listener_type .."][" .. ctype .. ccondition .. cwhat .. "]: " .. ctype)
		end
	end
	
	if vartype == "string" then
		if oxygene2.getConfigValue("trigcase") == 0 then
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
			oxygene2.log("# STRUCTURE ERROR 2: Invalid condition for " .. ctype .. ": " .. ccondition)
		end
	else
		if ccondition ~= "between" and ccondition ~= "outof" then
			local suc, res = oxygene2.evaluateExpression(cwhat)
			if suc then
				cwhat = res
			else
				local message = "Can't process expression: \"" .. cwhat .. "\". The following error happened: " .. res .. ". The original expression was: " .. cwhat_original
				if hub then
					oxygene2.pmOpChat( hub, message )
				end
				oxygene2.log( message )
			end
		end

		cwhat = string.lower( cwhat )
		local cwhatString = cwhat
		cwhat = oxygene2:ToNumber(cwhat)
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
			fulfilled = oxygene2.isVariableBetween( ctype, ctemp, cwhatString )
		elseif ccondition == "outof" then
			fulfilled = not oxygene2.isVariableBetween( ctype, ctemp, cwhatString )
		else
			oxygene2.log("# STRUCTURE ERROR 2: Invalid condition for " .. ctype .. ": " .. ccondition)
		end
	end

	return fulfilled
end

-- do all the actions which stored in the conditions table for a condition
-- NOTE: Returns true if the user was kicked with the "kick" or "redirect" action
function oxygene2.doActions(hub, userdata, triggertable, listener_type)
	local ret = false
	local tempaction, tempparam = "", ""
	if userdata and oxygene2.isUserProtectedAgainst(userdata, "ignorealltriggers") then
	  -- hmmz
	elseif ((os.time() - triggertable.lastactivation) >= triggertable.interval) or (userdata and userdata.isop) or (userdata and oxygene2.isUserProtectedAgainst(userdata, "ignoretriginterval")) then	
	
		for k in ipairs(triggertable.actions) do
			tempaction = triggertable.actions[k].action
			tempparam = triggertable.actions[k].param
			if userdata then
				if tempaction == "kick" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					oxygene2.disconnect(hub, userdata, tempchat)
					ret = true
				elseif tempaction == "mainchat" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					hub:sendChat(tempchat)
				elseif tempaction == "rxmainchat" or tempaction == "rxopchat" or tempaction == "rxpm" then
					local text = oxygene2.evaluateVariables(string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%1"), hub, userdata)
					local searchpattern = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%2")
					local replacestring = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%3")
					local tempchat = string.gsub(text, searchpattern, replacestring)
					tempchat = oxygene2.evaluateVariables(tempchat, hub, userdata)
					if tempaction == "rxmainchat" then
						hub:sendChat(tempchat)
					elseif tempaction == "rxopchat" then
						hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), tempchat, true)
					else -- rxpm
						hub:sendPrivMsgTo(userdata.sid, tempchat, true)
					end
				elseif tempaction == "pm" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					hub:sendPrivMsgTo(userdata.sid, tempchat, true)
				elseif tempaction == "pmfile" then
					oxygene2.sendFile(hub, hub:getUser(userdata.sid), tempparam, true, "pm")
				elseif tempaction == "mainchatfile" then
					oxygene2.sendFile(hub, hub:getUser(userdata.sid), tempparam, true, "mainchat")
				elseif tempaction == "opchat" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), tempchat, true)
				elseif tempaction == "redirect" then
					--// TODO: Fix
					tempparam = string.gsub( tempparam, "%$", "&#36;")
					tempparam = string.gsub( tempparam, "|", "&#124;")
					local params = oxygene2.tokenize(tempparam)
					local hubaddr = params[1]
					local reason = oxygene2.evaluateVariables(string.sub( tempparam, string.len(params[1]) + 2, string.len(tempparam) ) , hub, userdata)
					DC():SendHubMessage( hub:getId(), "$OpForceMove $Who:" .. userdata.fields.NI .. "$Where:" .. hubaddr .. "$Msg:" .. reason .. "|" )
					ret = true
				elseif tempaction == "command" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					oxygene2.commandParser( hub, nil, tempchat )
				end
			else
				if tempaction == "command" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, userdata)
					oxygene2.commandParser( hub, nil, tempchat )
				elseif tempaction == "mainchatfile" then
					oxygene2.sendFile(hub, nil, tempparam, true, "mainchat")
				elseif tempaction == "opchat" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, nil)
					hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), tempchat, true)
				elseif tempaction == "mainchat" then
					local tempchat = oxygene2.evaluateVariables(tempparam, hub, nil)
					hub:sendChat(tempchat)
				elseif tempaction == "rxmainchat" or tempaction == "rxopchat" then
					local text = oxygene2.evaluateVariables(string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%1"), hub, nil)
					local searchpattern = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%2")
					local replacestring = string.gsub(tempparam, "\"(.*)\"; \"(.*)\"; \"(.*)\"", "%3")
					local tempchat = string.gsub(text, searchpattern, replacestring)
					tempchat = oxygene2.evaluateVariables(tempchat, hub, nil)
					if tempaction == "rxmainchat" then
						hub:sendChat(tempchat)
					elseif tempaction == "rxopchat" then
						hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), tempchat, true)
					end
				end
			end
		end
		triggertable.lastactivation = os.time()
		triggertable.counter = triggertable.counter + 1
		oxygene2.saveSettings()
	else
		if listener_type ~= "timer" then
			hub:sendPrivMsgTo(hub:getSidbyNick(oxygene2.getConfigValue("opchat_name")), "[REPORT]: Trigger (" .. triggertable.name .. ") ignored for " .. tostring(userdata.fields.NI) .. " (activating too often)", true)
		end
	end
	return ret
end

-- Call this
function oxygene2.activateTriggers(hub, sid, listener_type)
	-- don't check triggers, if disabled
	if (Oxygenesettings.config.triggers == 0) then
		return false
	end
	local matched = false
	local kicked = false
	local userdata = false
	if sid then
		userdata = oxygene2.getUserData( hub, sid )
	end
	
	for k in ipairs(Oxygenesettings.triggers) do
		matched = oxygene2.checkTrigger(hub, userdata, Oxygenesettings.triggers[k], listener_type)
		if (matched == true) and (kicked == false) then
			kicked = oxygene2.doActions(hub, userdata, Oxygenesettings.triggers[k], listener_type)
		end
	end
	return matched
end

function oxygene2.doesTrigExist(trigname)
	local exist = false
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			exist = true
		end
	end
	return exist
end

function oxygene2.addTrigger(user, trigname, trigtype, interval)
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
	if oxygene2.doesTrigExist(trigname) then
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
	table.insert(Oxygenesettings.triggers, temp)
	if user then
		user:sendPrivMsgFmt("\"" .. trigname .. "\" added. Use -chtrigs addc or -chtrigs addcondition to add a condition then -chtrigs adda or -chtrigs addaction to add an action to it.", true)
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return true
end

function oxygene2.rmTrigger(user, trigname)
	if not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter: <trigger_name>. See -help or documentation.", true)
		end
		return false
	end
	local managed = false
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. See -chtrigs list or -help.", true)
		end
	end
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			table.remove( Oxygenesettings.triggers, k )
			managed = true
		end
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function oxygene2.setTrigType(user, trigname, parameter)
	local managed = false
	if (not trigname) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return managed
	end
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. Use -chtrigs list or -help instead.", true)
		end
		return managed
	end
	if parameter == "and" or parameter == "or" then
		for k in ipairs(Oxygenesettings.triggers) do
			if Oxygenesettings.triggers[k].name == trigname then
				Oxygenesettings.triggers[k].type = parameter
				managed = true
			end
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameter \"" .. parameter .. "\". Must be \"and\" or \"or\". Use -help or check the documentation.", true)
		end
		return managed	
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function oxygene2.setTrigInterval(user, trigname, parameter)
	local managed = false
	if (not trigname) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return managed
	end
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. Use -chtrigs list or -help instead.", true)
		end
		return managed
	end
	local interval = oxygene2:ToNumber(parameter)
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			Oxygenesettings.triggers[k].interval = interval
			managed = true
		end
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK [".. tostring(interval) .. "]", true)
	end
	return managed
end

function oxygene2.resetTrigCounter(user, trigname)
	if not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter: <trigger_name>. See -help or documentation.", true)
		end
		return false
	end
	local managed = false
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist. See -chtrigs list or -help.", true)
		end
	end
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			Oxygenesettings.triggers[k].counter = 0
			Oxygenesettings.triggers[k].counterreset = os.time()
			managed = true
		end
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function oxygene2.trigAddCondition(user, trigname, ctype, condition, parameter)
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
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help.", true)
		end
		return false
	end
	
	current_condition = oxygene2.getVariableType( ctype )
	if not current_condition then
		if user then
			user:sendPrivMsgFmt("Wrong variable (" .. ctype .. "). See documentation", true)
		end
	end


	if current_condition == "string" then
		if oxygene2.isPossibleStringCondition( condition ) then
			nicecondition = true
		end
	elseif current_condition == "num" then
		if oxygene2.isPossibleNumCondition( condition ) then
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
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			table.insert(Oxygenesettings.triggers[k].conditions, temp)
			managed = true
		end
	end
	if not managed then
		if user then
			user:sendPrivMsgFmt("#ERR002", true)
		end
		return managed
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK")
	end
	-- need update
	Oxygenesettings.hasTimerTrig = oxygene2.doesTimerTrigExist()
	return managed
end

function oxygene2.trigAddAction(user, trigname, action, parameter)
	local managed = false
	local niceaction = false
	local temp = {}
	if (not trigname) or (not action) or (not parameter) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return false
	end
	if not oxygene2.doesTrigExist(trigname) then
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
	local params = oxygene2.tokenize(parameter)
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
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			table.insert(Oxygenesettings.triggers[k].actions, temp)
			managed = true
		end
	end
	if not managed then
		if user then
			user:sendPrivMsgFmt("#ERR003", true)
		end
		return managed
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

-- trigtosend possible values: "_NONE", "_ALL", or a name of a trigger
function oxygene2.sendTriggerListTo(user, trigtosend)
	local count, countall, subcount1, subcount2 = 0, 0, 0, 0
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          [Enabled] (Cnt) Name", true)
	if (trigtosend  ~= "_NONE") then
	user:sendPrivMsgFmt("          [Conditions/Actions]", true)
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Oxygenesettings.triggers) do
		countall = countall + 1
		if (trigtosend == "_ALL") or (trigtosend == "_NONE") or (trigtosend == Oxygenesettings.triggers[k].name) then
			count = count + 1
			user:sendPrivMsgFmt("           [" ..Oxygenesettings.triggers[k].state .. "] (" .. tostring(count) .. ") ".. Oxygenesettings.triggers[k].name, true)
			if (trigtosend == "_ALL") or (trigtosend == Oxygenesettings.triggers[k].name) then
				subcount1, subcount2 = 0, 0
				for l in ipairs(Oxygenesettings.triggers[k].conditions) do
					subcount1 = subcount1 + 1
					user:sendPrivMsgFmt("           [C" .. tostring(subcount1) .."] " .. Oxygenesettings.triggers[k].conditions[l].type .. " " .. Oxygenesettings.triggers[k].conditions[l].condition .. " " .. Oxygenesettings.triggers[k].conditions[l].what, true)
				end
				for l in ipairs(Oxygenesettings.triggers[k].actions) do
					subcount2 = subcount2 + 1
					user:sendPrivMsgFmt("           [A" .. tostring(subcount2) .. "] " .. Oxygenesettings.triggers[k].actions[l].action .. ": " .. Oxygenesettings.triggers[k].actions[l].param, true)
				end
			user:sendPrivMsgFmt("                C: " .. tostring(subcount1) .. ", A: " .. tostring(subcount2) .. ", T: " .. Oxygenesettings.triggers[k].type .. ", Interval: " .. tostring(Oxygenesettings.triggers[k].interval) .. ", Activated " .. tostring(Oxygenesettings.triggers[k].counter) .. " times since " .. os.date("%m. %d. %Y. - %H:%M:%S", Oxygenesettings.triggers[k].counterreset), true)
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

function oxygene2.enableTrigger(user, trigname, desiredstate)
	local managed = false
	if (not trigname) or (not desiredstate) then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s). Use -help or see documentation.", true)
		end
		return false
	end
	if not oxygene2.doesTrigExist(trigname) then
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
	for k in ipairs(Oxygenesettings.triggers) do
		if Oxygenesettings.triggers[k].name == trigname then
			Oxygenesettings.triggers[k].state = desiredstate
			managed = true
		end
	end
	oxygene2.saveSettings()
	if user then
		user:sendPrivMsgFmt("OK", true)
	end
	return managed
end

function oxygene2.rmTriggerCondition(user, trigname, num)
	local managed = false
	local cnt = 0
	if not num or not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s), see -help chtrigs or documentation.", true)
		end
		return false
	end
	if not oxygene2.doesTrigExist(trigname) then
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
		for k in ipairs(Oxygenesettings.triggers) do
			if Oxygenesettings.triggers[k].name == trigname then
				for i = 1, #Oxygenesettings.triggers[k].conditions do
					table.remove(Oxygenesettings.triggers[k].conditions)
					cnt = cnt + 1
				end
				managed = true
			end
		end
	else
		for k in ipairs(Oxygenesettings.triggers) do
			if Oxygenesettings.triggers[k].name == trigname then
				if Oxygenesettings.triggers[k].conditions[removable] then
					table.remove(Oxygenesettings.triggers[k].conditions, removable)
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
	oxygene2.saveSettings()
	-- needs reset
	Oxygenesettings.hasTimerTrig = oxygene2.doesTimerTrigExist()
	return managed
end

function oxygene2.rmTriggerAction(user, trigname, num)
	local managed = false
	local cnt = 0
	if not num or not trigname then
		if user then
			user:sendPrivMsgFmt("Missing parameter(s), see -help or documentation.", true)
		end
		return false
	end
	if not oxygene2.doesTrigExist(trigname) then
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
	if not oxygene2.doesTrigExist(trigname) then
		if user then
			user:sendPrivMsgFmt("Trigger \"" .. trigname .. "\" doesn't exist, use -chtrigs list command or -help chtrigs.", true)
		end
		return false
	end
	if removable == -1 then
		for k in ipairs(Oxygenesettings.triggers) do
			if Oxygenesettings.triggers[k].name == trigname then
				for i = 1, #Oxygenesettings.triggers[k].actions do
					table.remove(Oxygenesettings.triggers[k].actions)
					cnt = cnt + 1
				end
				managed = true
			end
		end
	else
		for k in ipairs(Oxygenesettings.triggers) do
			if Oxygenesettings.triggers[k].name == trigname then
				if Oxygenesettings.triggers[k].actions[removable] then
					table.remove(Oxygenesettings.triggers[k].actions, removable)
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
	oxygene2.saveSettings()
	return managed
end

function oxygene2.listExceptions(user)
	local count = 0
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("           Nick patterns", true)
	user:sendPrivMsgFmt("           [M:Mode][K:Protect against kick][S:Ignore Slotrules][A:Ignore all triggers][T:Ignore TrigInterval]", true)
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Oxygenesettings.userexceptions) do
	user:sendPrivMsgFmt("           " .. Oxygenesettings.userexceptions[k].pattern .. " [M:" .. tostring(Oxygenesettings.userexceptions[k].mode) .. "][K:" .. tostring(Oxygenesettings.userexceptions[k].againstkick) .. "][S:" .. tostring(Oxygenesettings.userexceptions[k].ignoreslotrules) .. "][A:" .. tostring(Oxygenesettings.userexceptions[k].ignorealltriggers) .. "][T:" .. tostring(Oxygenesettings.userexceptions[k].ignoretriginterval) .. "]", true)
		count = count + 1
	end
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("           Modes: [0: regex][1: partial match][2: exact match][3: CID]", true)
	user:sendPrivMsgFmt("           Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("           ----------------------------------------------------------------------------------------------------------------------------", true)
	return true
end

function oxygene2.doesExceptionExist(exception)
	local matched = false
	for k in ipairs(Oxygenesettings.userexceptions) do
		if Oxygenesettings.userexceptions[k].pattern == exception then
			matched = true
		end
	end
	return matched
end

function oxygene2.rmException(exception)
	local success = false
	local debugmsg = "Exception (" .. tostring(exception) .. ") doesn't exist. Try -chprotect list instead."
	for k in ipairs(Oxygenesettings.userexceptions) do
		if Oxygenesettings.userexceptions[k].pattern == exception then
			table.remove( Oxygenesettings.userexceptions, k)
			oxygene2.saveSettings()
			debugmsg = "OK"
			success = true
		end
	end
	return success, debugmsg
end

-- againstwhat: "againstkick", "ignoreslotrules", "ignorealltriggers", "ignoretriginterval"
function oxygene2.isUserProtectedAgainst(userdata, againstwhat)
	local protected = false
	local match = false
	local nick = userdata.fields.NI
	local cid = userdata.fields.ID
	for k in ipairs(Oxygenesettings.userexceptions) do
		match = false
		if nick then
			if (Oxygenesettings.userexceptions[k].mode == 0) and (string.find(nick, Oxygenesettings.userexceptions[k].pattern)) then
				match = true
			elseif (Oxygenesettings.userexceptions[k].mode == 1) and (string.find(nick, Oxygenesettings.userexceptions[k].pattern, 1, 1)) then
				match = true
			elseif (Oxygenesettings.userexceptions[k].mode == 2) and (nick == Oxygenesettings.userexceptions[k].pattern) then
				match = true
			end
		end
		if cid then
			if (Oxygenesettings.userexceptions[k].mode == 3) and (cid == Oxygenesettings.userexceptions[k].pattern) then
				match = true
			end
		end
		if (match) and (Oxygenesettings.userexceptions[k][againstwhat] == 1) then
			protected = true
		end
	end
	return protected
end

function oxygene2.getProtectionList(userdata)
	local debugmsg = "Not protected"
	local protected = false
	
	if oxygene2.isUserProtectedAgainst(userdata, "againstkick") then
		debugmsg = "Protections: Kick-protection"
		protected = true
	end
	if oxygene2.isUserProtectedAgainst(userdata, "ignoreslotrules") then
		if protected then
			debugmsg = debugmsg .. ", "
		else
			debugmsg = "Protections: "
			protected = true
		end
		debugmsg = debugmsg .. "Ignoring slotrules"
	end
	if oxygene2.isUserProtectedAgainst(userdata, "ignorealltriggers") then
		if protected then
			debugmsg = debugmsg .. ", "
		else
			debugmsg = "Protections: "
			protected = true
		end
		debugmsg = debugmsg .. "Ignoring all triggers"
	end
	if oxygene2.isUserProtectedAgainst(userdata, "ignoretriginterval") then
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
function oxygene2.addException(user, parameter)
	local success = false
	local debugmsg = "Wrong/missing parameters. See -help chprotect"
	-- parsing parameter
	if string.find(parameter, "^([^ ]+ [0123] [01] [01] [01] [01])$") then
		local pattern = string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%1")
		local mode = oxygene2:ToNumber( string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%2") )
		local againstkick = oxygene2:ToNumber( string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%3") )
		local ignoreslotrules = oxygene2:ToNumber( string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%4") )
		local ignorealltriggers = oxygene2:ToNumber( string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%5") )
		local ignoretriginterval = oxygene2:ToNumber( string.gsub(parameter, "([^ ]+) ([0123]) ([01]) ([01]) ([01]) ([01])", "%6") )
		if nil then --// if user then
			user:sendPrivMsgFmt("pattern: " .. pattern )
			user:sendPrivMsgFmt("mode: " .. mode )
			user:sendPrivMsgFmt("againstkick: " .. againstkick )
			user:sendPrivMsgFmt("ignoreslotrules: " .. ignoreslotrules )
			user:sendPrivMsgFmt("ignorealltriggers: " .. ignorealltriggers )
			user:sendPrivMsgFmt("ignoretriginterval: " .. ignoretriginterval )
		end
		debugmsg = "Params OK"
		if oxygene2.doesExceptionExist(pattern) then
			oxygene2.rmException(pattern)
		end
		-- Create ExceptionTable
		local tmp = {}
		tmp.pattern = pattern
		tmp.mode = mode
		tmp.againstkick = againstkick
		tmp.ignoreslotrules = ignoreslotrules
		tmp.ignorealltriggers = ignorealltriggers
		tmp.ignoretriginterval = ignoretriginterval
		table.insert(Oxygenesettings.userexceptions, tmp)
		oxygene2.saveSettings()
		success = true
	end
	return success, debugmsg
end

function oxygene2.checkSlotNumber(userdata)
	local valid, diffrules = true, 0
	local minslot, maxslot, slotrec, maxhub, minul_limit, kickmsg= 0, 0, 0, 0, 0, "OK"
	local isset = false
	-- local ulimitperslot = false
	
	-- Only check rules if share size is larger than the "minshare" config value)
	if (oxygene2:ToNumber(userdata.fields.SS) >= Oxygenesettings.config.minshare) then
		for k = 1, #Oxygenesettings.bwrules, 1 do
			if (userdata.up_bw <= Oxygenesettings.bwrules[k].bandwidth) or (Oxygenesettings.bwrules[k].bandwidth == -1) then
				minslot = Oxygenesettings.bwrules[k].minslot
				maxslot = Oxygenesettings.bwrules[k].maxslot
				slotrec = Oxygenesettings.bwrules[k].slotrec
				maxhub = Oxygenesettings.bwrules[k].maxhub
				maxhub_kick = Oxygenesettings.bwrules[k].maxhub_kick
				minul_limit = math.floor( userdata.up_bw * 1024 / 8 * oxygene2:ToNumber( Oxygenesettings.bandwidthmultipler ) )
				if minul_limit < Oxygenesettings.minulimit then minul_limit = Oxygenesettings.minulimit end
				isset = true
				break
	
			end
		end
		if not isset then
			minslot, maxslot, slotrec, maxhub, maxhub_kick, minul_limit = 31, 50, 40, 13, 14, 960
		end
	--[[
	-- DCGUI doesn't support ADC yet
		if userdata.tag.client_type == "DCGUI" then
			ulimitperslot = true
		end	
	
		if ulimitperslot then
			minul_limit = minul_limit / userdata.tag.slots
		end
	]]	
		kickmsg = oxygene2.GETSTRING("YourSettingsAreWrong")
		if userdata.fields.SL then
			local currentslots = tonumber(userdata.fields.SL)
			if (currentslots < minslot) or (currentslots > maxslot) then
				valid = false
				if (math.min(currentslots, slotrec) ~= 0) then
					diffrules = diffrules + (( math.max(currentslots, slotrec) / math.min(currentslots, slotrec) - 1) * 10 )
				else
					diffrules = diffrules + (math.abs(math.max(currentslots, slotrec))) * 10
				end
				local ReplaceString = oxygene2.GETSTRING("BadSlots")
				local SearchPattern = "(%S+) (%S+) (%S+)"
				local SlotRules = tostring(slotrec) .. " "
				if minslot == maxslot then
					SlotRules = SlotRules .. tostring(maxslot)
				else
					SlotRules = SlotRules .. tostring(minslot) .. "-" .. tostring(maxslot)
				end
				SlotRules = SlotRules .. " " .. tostring(currentslots)
				kickmsg = kickmsg .. string.gsub(SlotRules, SearchPattern, ReplaceString)
			end
		end
	--[[
		-- here we could put the minimum upload limit check
		--// TODO
		if (Oxygenesettings.config.ulimitcheck ~= 0) then
			
			if userdata.tag.ul_limit < minul_limit and userdata.up_bw >= Oxygenesettings.ulimitbw and userdata.tag.ul_limit > 0 then
				diffrule = diffrules + (minul_limit / userdata.tag.ul_limit - 1) * 10
				if valid == false then
					kickmsg = kickmsg .. ", " .. oxygene2.GETSTRING("AsWellAs") .. " "
				else
					valid = false
				end
				kickmsg = kickmsg .. string.gsub( tostring(minul_limit), "(.+)", oxygene2.GETSTRING("BadUploadLimit") )
			end
			if ulimitperslot then
				kickmsg = kickmsg .. " " .. oxygene2.GETSTRING("PerSlot")
		end
		
		end
	]]
		local sumhub1, sumhub2 = 0, 0
		if userdata.fields.HN then
			sumhub1, sumhub2 = sumhub1 + tonumber(userdata.fields.HN), sumhub2 + tonumber(userdata.fields.HN)
		end
		if userdata.fields.HR then
			sumhub1, sumhub2 = sumhub1 + tonumber(userdata.fields.HR), sumhub2 + tonumber(userdata.fields.HR)
		end
		if userdata.fields.HO then
			sumhub2 = sumhub2 + tonumber(userdata.fields.HO)
		end
		if sumhub1 > maxhub_kick then
			diffrules = diffrules + (sumhub1 / maxhub - 1 ) * 5
			if valid == false then
				kickmsg = kickmsg .. "! " .. oxygene2.GETSTRING("InAddition") .. " "
			else
				valid = false
			end
			local ReplaceString = oxygene2.GETSTRING("BadHubNumber")
			local SearchPattern = "^([0-9]+) ([0-9]+) ([0-9]+)$"
			local Values = tostring(maxhub) .. " " .. tostring(sumhub1) .. " " .. tostring(sumhub2)
			kickmsg = kickmsg .. string.gsub(Values, SearchPattern, ReplaceString)
		end
		kickmsg = kickmsg .. ". " .. oxygene2.GETSTRING("Rules") .. oxygene2.getConfigValue("rulesurl")

		-- Too small bandwidth indicated
		if userdata.up_bw < Oxygenesettings.minbw then
			valid = false
			local ReplaceString = oxygene2.GETSTRING("TooSmallBw")
			local SearchPattern = "^([0-9,%.]+) ([0-9,%.]+)$"
			local Values = tostring(userdata.up_bw) .. " " .. tostring(userdata.up_bw * 128)
			kickmsg = string.gsub(Values, SearchPattern, ReplaceString) .. " " .. oxygene2.GETSTRING("Rules") .. oxygene2.getConfigValue("rulesurl")
			diffrules = 100
		end
		
		-- Reverse bandwidth indication
		if (Oxygenesettings.config.reversebandwidth ~= 0 and userdata.down_bw ~= 0 and userdata.up_bw > userdata.down_bw) then
			valid = false
			kickmsg = oxygene2.GETSTRING("ReverseBandwidth") .. " " .. oxygene2.GETSTRING("Rules") .. oxygene2.getConfigValue("rulesurl")
			diffrules = 60
		end
		-- rounding diffrules
		diffrules = math.floor(diffrules * 100) / 100
	
	end -- if	(userdata.sharesize >= Oxygenesettings.config.minshare) ...
	return valid, kickmsg, diffrules
end

function oxygene2.setThreshold(user, percentage, minulimit, minbandwidth)
	percentage = math.floor( oxygene2:ToNumber( percentage ) )
	minulimit = math.floor( oxygene2:ToNumber( minulimit ) )
	minbandwidth = math.floor( oxygene2:ToNumber( minbandwidth ) )
	if percentage < 100 and percentage > 0 and minulimit > 0 and minbandwidth > 0 then
		if percentage < 10 then
			percentage = "0" .. tostring(percentage)
		else
			percentage = tostring(percentage)
		end
		Oxygenesettings.bandwidthmultipler = "0." .. percentage
		Oxygenesettings.minulimit = minulimit
		Oxygenesettings.ulimitbw = minbandwidth
		if user then
			user:sendPrivMsgFmt("OK", true)
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameters. Percentage should be between 0 and 100, and min ulimit and min bandwidth parameters should be positives.", true)
		end
		return false
	end
	oxygene2.saveSettings()
	return true
end

function oxygene2.setMinBw(user, minbandwidth)
	minbandwidth = oxygene2.convertToNum( minbandwidth )
	if minbandwidth >= 0 then
		Oxygenesettings.minbw = minbandwidth
		if user then
			user:sendPrivMsgFmt("OK", true)
		end
	else
		if user then
			user:sendPrivMsgFmt("Wrong parameters. Minimum bandwidth should be greater or equal than 0.", true)
		end
		return false
	end
	oxygene2.saveSettings()
	return true
end

function oxygene2.sendSlotRules(user)
	local count = 0
	local baw = ""
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Upload speed\tmin. slot\tmax. slot\trec. slot\tmax. hub\tmax-hub kick", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Oxygenesettings.bwrules) do
		count = count + 1
		if Oxygenesettings.bwrules[k].bandwidth == -1 then
			baw = "Above that:"
		else
			baw = "Up to " .. tostring( Oxygenesettings.bwrules[k].bandwidth) .. " mbps:"
		end
		user:sendPrivMsgFmt("           " .. baw .."\t".. tostring(Oxygenesettings.bwrules[k].minslot) .. "\t" .. tostring(Oxygenesettings.bwrules[k].maxslot) .. "\t" .. tostring(Oxygenesettings.bwrules[k].slotrec .. "\t" .. tostring(Oxygenesettings.bwrules[k].maxhub .. "\t" .. tostring(Oxygenesettings.bwrules[k].maxhub_kick))), true )
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Minimum allowed upload bandwidth: " .. tostring( Oxygenesettinsg.minbw ), true)
	user:sendPrivMsgFmt("          Upload threshold: " .. tostring( oxygene2:ToNumber( Oxygenesettings.bandwidthmultipler ) * 100 ) .. " % - Min. limit: " .. tostring( Oxygenesettings.minulimit ) .. " KiB/sec - Applied for: " .. tostring( Oxygenesettings.ulimitbw ) .. " mbps and above", true)
	user:sendPrivMsgFmt("          Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return count
end

function oxygene2.getDefaultProfile()
	return Oxygenesettings.currentprofile
end

function oxygene2.isItProfile( text )
	local ret = false
	for k in ipairs(Oxygenesettings.kickprofiles) do
		if Oxygenesettings.kickprofiles[k].name == text then
			ret = true
		end
	end
	return ret
end

-- profiletype: c: chat; r: raw
function oxygene2.addProfile( user, profilename, profiletype, command )
	local managed = false
	if profiletype ~= "c" and profiletype ~= "r" then
		if user then
			user:sendPrivMsgFmt( "Wrong profile type. Must be \"c\" for chat commands or \"r\" for raw.", true )
		end
	elseif oxygene2.isItProfile( profilename ) then
		if user then
			user:sendPrivMsgFmt( "Profile already added. Please remove it first.", true )
		end
	else
		local temptable = { }
		temptable.name = profilename
		temptable.command = command
		temptable.type = profiletype
		table.insert( Oxygenesettings.kickprofiles, temptable )
		oxygene2.saveSettings()
		managed = true
		if user then
			user:sendPrivMsgFmt( "OK", true )
		end
	end
	return managed
end

function oxygene2.rmProfile( user, profile )
	local managed = false
	if oxygene2.isItProfile( profile ) and ( Oxygenesettings.currentprofile ~= profile ) then
		for k in ipairs(Oxygenesettings.kickprofiles) do
			if Oxygenesettings.kickprofiles[k].name == profile then
				table.remove( Oxygenesettings.kickprofiles, k )
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

function oxygene2.sendKickProfilesTo(user)
	local count = 0
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Profile name [type] (Command)", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	for k in ipairs(Oxygenesettings.kickprofiles) do
		count = count + 1
		user:sendPrivMsgFmt("           (" .. tostring(count) .. ") ".. Oxygenesettings.kickprofiles[k].name .. " [" .. Oxygenesettings.kickprofiles[k].type .."] (" .. Oxygenesettings.kickprofiles[k].command .. ")", true )
	end
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("          Default profile: " .. oxygene2.getDefaultProfile(), true )
	user:sendPrivMsgFmt("          Total: " .. tostring(count) .. " items", true)
	user:sendPrivMsgFmt("          ----------------------------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("OK", true)
	return count
end

function oxygene2.selectProfile( user, profile )
	local managed = false
	if oxygene2.isItProfile( profile ) then
		managed = true
		Oxygenesettings.currentprofile = profile
		oxygene2.saveSettings()
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

function oxygene2.getKickMsg(hub, userdata, reason, profile)
	local kickmsg = ""
	local profiletype = ""
	if not profile then profile = Oxygenesettings.currentprofile end
	for k in ipairs(Oxygenesettings.kickprofiles) do
		if Oxygenesettings.kickprofiles[k].name == profile then
			kickmsg = Oxygenesettings.kickprofiles[k].command
			profiletype = Oxygenesettings.kickprofiles[k].type
		end
	end
	
	-- unescape
	if profiletype == "r" then
		kickmsg = dcu:AdcEscape( kickmsg, true )
	end
	
	-- %[myNI]
	local replace = hub:getOwnNick()
	replace = string.gsub(replace, "%%", "%%%%")
	if profiletype == "r" then
		replace = dcu:AdcEscape( replace, false )
	end
	kickmsg = string.gsub( kickmsg, "%%%[myNI%]", replace )
	-- %[mySID]
	local replace = hub:getOwnSid()
	kickmsg = string.gsub( kickmsg, "%%%[mySID%]", replace )
	-- %[myCID]
	local replace = hub:getOwnCid()
	kickmsg = string.gsub( kickmsg, "%%%[myCID%]", replace )
	-- %[userNI]
	local replace = userdata.fields.NI
	replace = string.gsub(replace, "%%", "%%%%")
	if profiletype == "r" then
		replace = dcu:AdcEscape( replace, false )
	end
	kickmsg = string.gsub ( kickmsg, "%%%[userNI%]", replace)
	-- %[userSID]
	local replace = userdata.sid
	kickmsg = string.gsub ( kickmsg, "%%%[userSID%]", replace)
	-- %[userCID]
	local replace = userdata.fields.ID
	kickmsg = string.gsub ( kickmsg, "%%%[userCID%]", replace)
	-- %[reason]
	replace = reason
	replace = string.gsub(replace, "%%", "%%%%")
	if profiletype == "r" then
		replace = dcu:AdcEscape( replace, false )
	end
	kickmsg = string.gsub ( kickmsg, "%%%[reason%]", replace)
	if kickmsg == "" then
		oxygene2.log("# STRUCTURE ERROR 3: Invalid kick profile")
	end
	return kickmsg, profiletype
end

function oxygene2.disconnect(hub, userdata, reason, profile)
	local managed = false
	local debugmsg = "OK"
	if (userdata.isop) or (oxygene2.isUserProtectedAgainst(userdata, "againstkick")) then
		managed = false
		debugmsg = "User is an Operator or protected"
	else
		hub:sendPrivMsgTo(userdata.sid, "You are being disconnected because: " .. reason, true)
		if (userdata.fields.NI) then
			oxygene2.log("[KICK] Disconnected: " .. userdata.fields.NI .. " because: " .. reason, Oxygenesettings.kicklog)
		elseif (userdata.fields.ID) then
			oxygene2.log("[KICK] Disconnected: " .. userdata.fields.ID .. " because: " .. reason, Oxygenesettings.kicklog)
		end
		local kickmsg, kicktype = oxygene2.getKickMsg( hub, userdata, reason, profile )
		if kicktype == "c" then
			hub:sendChat( kickmsg )
		else
			-- DC():PrintDebug("kickmsg: " .. kickmsg)
			DC():SendHubMessage( hub:getId(), kickmsg .. "\n" )
		end
		managed = true
	end
	return managed, debugmsg
end

function oxygene2.private(hub, userdata, reason)
	local managed = false
	if userdata.isop then
		--
		managed = false
	else
		hub:sendPrivMsgTo(userdata.sid, oxygene2.GETSTRING("ThisIsAnAutomessage") .. reason, true)
		managed = true
	end
	return managed
end

function oxygene2.tokenize(text)
	local ret = {}
	string.gsub(text, "([^ ]+)", function(s) table.insert(ret, s) end )
	return ret
end

function oxygene2.buildUserData(hub, user, basedon, data)
	-- userdata is a table which stores every important information about the current user
	local userdata = {}
	local sidtmp = user:getSid()
	-- basedon possible values (maybe more added later):
	-- "INF", "chatmsg"

	-- Check if it's new user
	local newuser = true
	if oxygene2.isUserOnHub(hub, sidtmp) then
		newuser = false
	end

	-- if it's a new user, we need to build a clean userdata table
	if newuser then
		-- initializing variables:
		userdata.sid = sidtmp
		userdata.fields = {}
		userdata.down_bw = 0
		userdata.up_bw = 0
		userdata.chatmsg = ""
		userdata.isop = user:isOp()
		userdata.isvalid_slots, userdata.kickmsg_slots = true, ""
		userdata.diffrules = 0
		userdata.logintime = os.time()
	else
		userdata = oxygene2.getUserData( hub, sidtmp )
	end

	-- filling/updating the table

	if basedon == "INF" then

		-- a new INF is sent.. add the fields
		for field, value in pairs(data) do
			userdata.fields[field] = dcu:AdcEscape( value, true )
		end
		
		-- cancel empty fields
		for field, value in pairs(userdata.fields) do
			if value == "" then
				userdata.fields[field] = nil
				DC():PrintDebug("[oxygene2] DEBUG#666: Field cancelled: " .. field )
			end
		end

		if userdata.fields.DS then
			userdata.down_bw = tonumber(userdata.fields.DS)
		end
		
		if userdata.fields.US then
			userdata.up_bw = tonumber(userdata.fields.US)
			if not userdata.up_bw then
				DC():PrintDebug("[oxygene2] DEBUG#2666: US field: " .. tostring(userdata.fields.US))
			end
		end
		
		-- check slot numbers
		userdata.isvalid_slots, userdata.kickmsg_slots, userdata.diffrules = oxygene2.checkSlotNumber(userdata)
		
		if (not userdata.isvalid_slots) and (hub.oxygene2.state.active) and (not oxygene2.isUserProtectedAgainst(userdata, "ignoreslotrules")) then
			if Oxygenesettings.config.slotcheck == "kick" then
				oxygene2.disconnect(hub, userdata, userdata.kickmsg_slots)
			elseif Oxygenesettings.config.slotcheck == "pm" then
				oxygene2.private(hub, userdata, userdata.kickmsg_slots)
			end
		end

	elseif basedon == "chatmsg" then
		-- if user entered someting to the main chat
		userdata.chatmsg = data
	end

	return userdata
end

function oxygene2.updateHubStat( hubstat, userdata )
	local alreadyadded = false
	local tempclient_type = ""
	local nv_tempclient_type = ""
	local tempconn_mode = ""

	-- tempclient_type = userdata.fields.VE .. " " .. tostring( userdata.tag.client_ver )
	tempclient_type = userdata.fields.VE
	if tempclient_type then
		local temptable = oxygene2.tokenize(tempclient_type)
		if temptable[2] then
			nv_tempclient_type = temptable[1]
		end
	else
		tempclient_type = "VE field is missing"
		nv_tempclient_type = "VE field is missing"
	end

	if userdata.fields.I4 then
		tempconn_mode = "Active"
	else
		tempconn_mode = "Passive"
	end

	-- user count
	hubstat.usercount = hubstat.usercount + 1
	-- rule violating
	
	hubstat.points = hubstat.points + userdata.diffrules
	if not userdata.isvalid_slots then
		if oxygene2.isUserProtectedAgainst(userdata, "ignoreslotrules") then
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

function oxygene2.getHubStat( hub )
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
	for k in pairs(hub.oxygene2.userlist) do
		hubstat = oxygene2.updateHubStat( hubstat,  hub.oxygene2.userlist[k] )
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
function oxygene2.processHubStat( hub, user, hubstat, fullstat )
	local text = ""
	text = text .. "\r\n          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          General hub statistics                                                                     Oxygene %[version]\r\n"
	text = text .. "          ----------------------------------------------------------------------------------------------------------------------------\r\n"
	text = text .. "          Autochecking active: " .. oxygene2:YesNo( hub.oxygene2.state.active ) .. "\r\n"
	text = text .. "          Usercount: " .. tostring( hubstat.usercount ) .. " users\r\n"
	text = text .. "          Bad slotrules: " .. tostring( hubstat.badslots ) .. " users"
	if hubstat.protectedslots > 0 then
		text = text .. " (" .. tostring( hubstat.protectedslots ) .. " protected)"
	end
	text = text .. "\r\n"
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
	text = oxygene2.evaluateVariables(text, hub, oxygene2.getUserData( hub, user:getSid() ) )
	return text
end

function oxygene2.sendHubStat( hub, user, pm, fullstat )
	local hubstat = oxygene2.getHubStat( hub )
	local message = oxygene2.processHubStat( hub, user, hubstat, fullstat )
	if pm then
		user:sendPrivMsgFmt( message, true)
	else
		hub:sendChat( message )
	end
	return 1
end

function oxygene2.getUserData( hub, sid )
	local userdata = false
	if hub.oxygene2.userlist[sid] then
		userdata =  hub.oxygene2.userlist[sid]
	end
	return userdata
end

function oxygene2.refreshAllUserData(hub)
	local counter = 0
	for sid in pairs(hub.oxygene2.userlist) do
		local userdata = oxygene2.getUserData( hub, sid )
		userdata.isvalid_slots, userdata.kickmsg_slots, userdata.diffrules = oxygene2.checkSlotNumber(userdata)
		oxygene2.updateUser(hub, userdata)
		counter = counter + 1
	end
	return counter
end

function oxygene2.getUserInfo( userdata )
	local nick = "nick not set"
	-- Building a virtual tag:
	-- <++ V:0.800,M:A,H:0/1/7,S:4>
	local tmptag = "<"
	tmptag = tmptag .. (userdata.fields.VE or "")
	if userdata.fields.I4 or userdata.fields.I6 then
		tmptag = tmptag .. ",M:A"
	else
		tmptag = tmptag .. ",M:P"
	end
	local hub1, hub2, hub3 = userdata.fields.HN, userdata.fields.HR, userdata.fields.HO
	tmptag = tmptag .. ",H:" .. (hub1 or "0") .. "/" .. (hub2 or "0") .. "/" .. (hub3 or "0" )
	if userdata.fields.SL then
		tmptag = tmptag .. ",S:" .. userdata.fields.SL
	end
	tmptag = tmptag .. ">"

	if userdata.fields.NI then
		nick = userdata.fields.NI
	end
	local message = ""
	message = "\r\n          -----------------------------------------------------------------------------------------------------\n"
	message = message .. "          Userinfo [" .. nick .. "]:\n          -----------------------------------------------------------------------------------------------------\n"
	message = message .. "          Current SID: " .. userdata.sid.."\n"
	if userdata.fields.ID then
		message = message .. "          CID: " .. userdata.fields.ID .. "\n"
	end
	if userdata.fields.I4 then
		message = message .. "          IPv4: " .. userdata.fields.I4 .. "\n"
	end
	if userdata.fields.I6 then
		message = message .. "          IPv6: " .. userdata.fields.I6 .. "\n"
	end
	if userdata.fields.DE then
		message = message .. "          Description: " .. userdata.fields.DE .. "\n"
	end
	message = message .. "          Virtual tag: " .. tmptag .. "\n"
	message = message .. "          Bandwidth: " .. tostring(userdata.down_bw) .. "M/" .. tostring(userdata.up_bw).."M\n"
	message = message .. "          Operator: " .. oxygene2:YesNo(userdata.isop) .. "\n"
	if userdata.fields.EM then
		message = message .. "          E-mail: " .. userdata.fields.EM .. "\n"
	end
	if userdata.fields.SF or userdata.fields.SS then
		message = message .. "          Shared: "
		if userdata.fields.SS then
			message = message .. oxygene2:FormatBytes( tonumber(userdata.fields.SS ) ) .. " (" .. userdata.fields.SS .. " B) "
		end
		if userdata.fields.SF and userdata.fields.SS then
			local avg = "0 B"
			local sf = tonumber(userdata.fields.SF)
			local ss = tonumber(userdata.fields.SS)
			if sf and (sf > 0) then
				avg = oxygene2:FormatBytes( ss/sf )
			end
			message = message .. "\n          Files: " .. userdata.fields.SF .. " shared. Average file size: " .. avg
		end
		message = message .. "\n"
	end

	if string.len(userdata.chatmsg) > 0 then
		message = message .. "          Latest chat message: \"" .. userdata.chatmsg .. "\"\n"
	end
	message = message .. "          Added: " .. os.date("%x %X", userdata.logintime) .. "\n"
	message = message .. "          "
	local prot, dbg = oxygene2.getProtectionList(userdata)
	message = message .. dbg .. "\n"
	message = message .. "          Slotrules: "
	if userdata.isvalid_slots then
		message = message .. "OK\n"
	else
		message = message .. "\n          ".. userdata.kickmsg_slots .. "\n"
	end
	message = message .. "          Points for slotrules violation: " .. tostring(userdata.diffrules) .. "\n"
	message = message .. "          -----------------------------------------------------------------------------------------------------\n"
	message = message .. "OK"
	return message
end

function oxygene2.sendUserInfo(hub, user, nick_to_send, pm)
	local counter = 0
	local message = ""
	local userdata = nil
	userdata = oxygene2.getUserData(hub, hub:getSidbyNick(nick_to_send))
	if not userdata then
			if pm then
				user:sendPrivMsgFmt("User (".. nick_to_send .. ") is not found", true)
			else
				hub:sendChat("User (".. nick_to_send..") is not found")
			end
	else
		message = oxygene2.getUserInfo(userdata)
		if pm then
			user:sendPrivMsgFmt(message, true)
		else
			hub:sendChat(message)
		end
	end
	return userdata
end

--// Returns true if user is online
function oxygene2.isUserOnHub(hub, sid)
	local ret = false
	if hub.oxygene2.userlist[sid] then
		ret = true
	end
	return ret
end

--// used internally, call updateUser instead!
function oxygene2.addUserToHub(hub, userdata)
	local ret = false
	if userdata.sid then
		hub.oxygene2.userlist[userdata.sid] = userdata
		ret = true
	end
	return ret
end

function oxygene2.setUserData(pointer, userdata)
	local ret = false
	pointer = userdata
	local ret = true
end

function oxygene2.updateUser(hub, userdata)
	--// Return values:
	--// 0: some error happened
	--// 1: new user
	--// 2: updated user
	local ret = 0
	if oxygene2.isUserOnHub(hub, userdata.sid) then
		ret = 2
		oxygene2.setUserData( hub.oxygene2.userlist[userdata.sid], userdata )
	else
		ret = 1
		oxygene2.addUserToHub(hub, userdata)
	end
	
	return ret
end

--// Returns true if any user is removed
function oxygene2.removeUserFromHub(hub, sid)
	local ret = false
	if hub.oxygene2.userlist[sid] then
		hub.oxygene2.userlist[sid] = nil
		ret = true
	end

	return ret
end

function oxygene2.noticeUser( hub, user, nick_to_check, method )
	local success = false
	local userdata = oxygene2.getUserData(hub, hub:getSidbyNick(nick_to_check))
	local kickmsg = ""
	local message = ""
	if not userdata then
		if user then
			user:sendPrivMsgFmt("User (".. nick_to_check .. ") is not found", true)
		end
	else
		if userdata.isop then
			message = nick_to_check .. " is an Operator. You can't notice him or her"
		elseif oxygene2.isUserProtectedAgainst(userdata, "ignoreslotrules") then
			message = nick_to_check .. " is Protected"
		else
			if userdata.isvalid_slots then
				message = nick_to_check .. " has correct settings"
			else
				message = nick_to_check .. " gets " .. method .. "ed because of violating slotrules"
				kickmsg = userdata.kickmsg_slots
				
				if method == "pm" then
					oxygene2.private(hub, userdata, kickmsg)
					success = true
				else
					local kicprofile = ""
					if oxygene2.isItProfile( method ) then
						kickprofile = method
						message = "[" .. kickprofile .."] "
					elseif method == "default" then
						kickprofile = oxygene2.getDefaultProfile()
						message = "[" .. kickprofile .."] "
					else
						kickprofile = oxygene2.getDefaultProfile()
						message = "[Wrong profile: using default] "
					end
					local ret, dbg = oxygene2.disconnect(hub, userdata, kickmsg, kickprofile)
					if ret then
						message = message .. tostring(userdata.fields.NI)
						success = true
						oxygene2.log("[KICK] " .. user:getNick() .. " kicked [" .. kickprofile .."] " .. tostring(userdata.fields.NI) .. " because: " .. kickmsg, Oxygenesettings.logfile)
					else
						message = dbg
						oxygene2.log("[KICK] " .. user:getNick() .. " wanted to kick " .. tostring(userdata.fields.NI) .. ", but he/she is protected. Reason: " .. kickmsg, Oxygenesettings.logfile)
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

function oxygene2.checkHub( hub, user, num, profile )
	local success = false
	local kickmsg, nice = "", true
	local currkicked, maxkick = 0, tonumber(num)
	if not maxkick then
		if user then
			user:sendPrivMsg( "Wrong parameter: <num> must be a number. Example: -chcheckhub 700", true )
		end
	elseif maxkick < 1 then
		if user then
			user:sendPrivMsg( "Wrong parameter: <num> must be a positive integer. Example: -chcheckhub 700", true )
		end
	else
		if not profile then
			profile = Oxygenesettings.currentprofile
			if user then
				user:sendPrivMsg("Missing parameter [profile]. Using profile '" .. profile .. "' for disconnecting.", true )
			end
		end
		if not oxygene2.isItProfile( profile ) then
			if user then
				user:sendPrivMsg("Wrong profile name (" .. profile .. "). Check profile list using -chprofiles list command.", true )
			end
		else
			oxygene2.log( "[KICK] " .. user:getNick() .. " wants to disconnect " .. tostring(num) .. " users using profile '" .. profile .. "'")
			-- kicking users
			for k in pairs(hub.oxygene2.userlist) do
				kickmsg = ""
				nice = true
				if not hub.oxygene2.userlist[k].isvalid_slots then
					kickmsg = kickmsg .. hub.oxygene2.userlist[k].kickmsg_slots
					nice = false
				end
				if not nice then
					local userdata = oxygene2.getUserData( hub, hub.oxygene2.userlist[k].sid )
					local ret, dbg = oxygene2.disconnect(hub, userdata, kickmsg, profile)
					-- We don't count protected users since they are not kicked
					if ret then
						currkicked = currkicked+ 1
					end
					success = true
					if currkicked >= maxkick then
						oxygene2.log( "[KICK] -chcheckhub: queue completed. " .. tostring(currkicked) .. " users were disconnected")
						if user then
							user:sendPrivMsg("OK", true)
						end
						hub:sendChat(tostring(currkicked) .. " users have been kicked because of violating slotrules")
						return success
					end
				end
			end
		end
	end
	oxygene2.log( "[KICK] -chcheckhub: queue completed. " .. tostring(currkicked) .. " users were disconnected")
	if success then
		if user then
			user:sendPrivMsg("OK", true)
		end
		hub:sendChat(tostring(currkicked) .. " users have been kicked because of violating slotrules")
	end
	return success
end

function oxygene2.getHelpFor(user, command)
	local help = { }
	local tmp = { }
	tmp.command = "chrules"
	tmp.desc = "Usage: -chrules <list/add/rm/ulimit/minbw/clearall/reset> [params]\r\n\r\n-chrules list\r\nLists the current active slotrules table\r\n\r\n-chrules add <upper_bandwidth> <minslot> <maxslot> <slotrec> <maxhub> <maxhub_kick>\r\nAdds or overwrites a new/existing rule. Use -1 as bandwidth for the \"Above that\" rule.\r\n\r\n-chrules rm <bandwidth>\r\nRemoves the given bandwidth from the table. Use -1 to remove the \"Above that\" rule.\r\n\r\n-chrules ulimit <percent> <min_limit> <applied_from>\r\nSets the upload limit config values.\r\nThe users shouldn't limit their upload limit below the given <percent> of their nominal upload bandwidth but at least <min_limit> KiB/sec.\r\nFor convenience (for example because of users with dial-up modems) the rule is only applied for users with at least <applied_from> upload bandwidth. The others don't get hurt.\r\n\r\n-chrules clearall\r\nClears the whole slotrules table\r\n\r\n-chrules reset\r\nRestores the original slotrules"
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
	tmp.desc = "Usage: -chprotect <list/add/rm> [params]\r\n\r\n-chprotect list\r\n\r\n-chprotect add <pattern> <mode> <kickprotection> <ignore slot rules> <ignore all triggers> <ignore trigger timing>\r\n<pattern> cannot contain spaces\r\nAvailable <mode>s: 0 for regex, 1 for partial match, 2 for exact match, 3 for CID protection\r\n<kickprotection> <ignore slot rules> <ignore all triggers> <ignore trigger timing> can be 0 or 1\r\n\r\n-chprotect rm <pattern>"
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

-- if user is nil, everything goes to opchat if set
function oxygene2.commandParser( hub, user, command )
	local params = oxygene2.tokenize(command)
	if not user then
		local utable = hub:findUsers( oxygene2.getConfigValue("opchat_name"), nil )
		-- it should contain at most one nick
		for k in ipairs(utable) do
			user = utable[k]
		end
	end
		if params[1] == "-help" or params[1] == "-?" then
			if user then
				if params[2] then
					oxygene2.getHelpFor(user, params[2])
				else
					oxygene2.sendHelp(hub, user)
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
							oxygene2.sendTriggerListTo( user , "_NONE" )
						end
					elseif params[3] == "all" then
						if user then
							oxygene2.sendTriggerListTo( user , "_ALL" )
						end
					else
						if user then
							oxygene2.sendTriggerListTo( user , params[3] )
						end
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "addtrig" then
					oxygene2.addTrigger( user, params[3], params[4], params[5] )
				elseif params[2] == "rmtrig" then
					oxygene2.rmTrigger( user, params[3] )
				elseif params[2] == "reset" then
					oxygene2.resetTrigCounter( user, params[3] )
				elseif not params[4] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "enable" then
					oxygene2.enableTrigger(user, params[3], params[4])
				elseif params[2] == "settype" then
					oxygene2.setTrigType(user, params[3], params[4])
				elseif params[2] == "setinterval" then
					oxygene2.setTrigInterval(user, params[3], params[4])
				elseif params[2] == "rma" or params[2] == "rmaction" then
					oxygene2.rmTriggerAction(user, params[3], params[4])
				elseif params[2] == "rmc" or params[2] == "rmcondition" then
					oxygene2.rmTriggerCondition(user, params[3], params[4])
				elseif params[2] == "adda" or params[2] == "addaction" then
					oxygene2.trigAddAction(user, params[3], params[4], string.sub(command, string.len(params[3]) + string.len(params[4]) + string.len(params[1]) + string.len(params[2]) + 5, string.len(command) ))
				elseif not params[5] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chtrigs", true )
					end
				elseif params[2] == "addc" or params[2] == "addcondition" then
					oxygene2.trigAddCondition(user, params[3], params[4], params[5], string.sub(command, string.len(params[3]) + string.len(params[4]) + string.len(params[5]) + string.len(params[1]) + string.len(params[2]) + 6, string.len(command) ) )
				end
			elseif params[1] == "-chprotect" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help chprotect", true )
					end
				elseif params[2] == "list" then
					if user then
						oxygene2.listExceptions(user)
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt( "Missing/wrong parameters. See -help chprotect", true )
					end
				elseif params[2] == "rm" then
					local ret, dbg = oxygene2.rmException(params[3])
					if user then
						if not ret then
							user:sendPrivMsgFmt("Error: " .. dbg, true)
						else
							user:sendPrivMsgFmt("OK")
						end
					end
				elseif params[2] == "add" then
					local ret, dbg = oxygene2.addException(user, string.sub(command, string.len(params[1]) + string.len(params[2]) + 3, string.len(command)) )
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
						oxygene2.sendUserInfo(hub, user, params[2], true)
					end
				else
					if user then
						user:sendPrivMsgFmt("Wrong paramters. See: -help", true)
					end
				end
			elseif params[1] == "-chnotice" then
				if params[2] and params[3] then
					oxygene2.noticeUser( hub, user, params[2], params[3] )
				else
					if user then
						user:sendPrivMsgFmt("Missing parameters. See -help chnotice", true)
					end
				end
			elseif params[1] == "-chcheckhub" then
				if params[2] then
					oxygene2.checkHub( hub, user, params[2], params[3] )
				else
					if user then
						user:sendPrivMsgFmt("Wrong paramter. See -help", true)
					end
				end
			elseif params[1] == "-chstat" then
				if params[2] then
					if params[2] == "full" then
						if user then
							oxygene2.sendHubStat( hub, user, true, true )
						end
					else
						if user then
							user:sendPrivMsgFmt("Wrong parameters. See -help chstat", true)
						end
					end
				else
					if user then
						oxygene2.sendHubStat( hub, user, true, false )
					end
				end
			elseif params[1] == "-chrules" then
				if not params[2] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "list" then
					if user then
						oxygene2.sendSlotRules( user )
					end
				elseif params[2] == "clearall" then
					oxygene2.clearBwRules( user )
				elseif params[2] == "reset" then
					oxygene2.resetBwRules( user )
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "rm" then
					oxygene2.rmBwRule(user, params[3])
				elseif not params[4] or not params[5] then
				elseif params[2] == "ulimit" then
					oxygene2.setThreshold( user, params[3], params[4], params[5] )
				elseif params[2] == "minbw" then
					oxygene2.setMinBw( user, params[3] )
				elseif not params[6] or not params[7] or not params[8] then
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chrules", true)
					end
				elseif params[2] == "add" then
						-- <upper_bandwidth> <minslot> <maxslot> <slotrec> <maxhub> <maxhub_kick>
						oxygene2.addBwRule(user, params[3], params[4], params[5], params[6], params[7], params[8])
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
						oxygene2.sendKickProfilesTo(user)
					end
				elseif not params[3] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif params[2] == "rm" then
					oxygene2.rmProfile(user, params[3])
				elseif params[2] == "setdefault" then
					oxygene2.selectProfile(user, params[3])
				elseif not params[4] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif not params[5] then
					if user then
						user:sendPrivMsgFmt("Missing or wrong parameters. See -help chprofiles", true)
					end
				elseif params[2] == "add" then
					oxygene2.addProfile( user, params[3], params[4], string.sub( command, 5 + string.len( params[1] ) + string.len( params[2] ) + string.len( params[3] ) + string.len( params[4] ), string.len( command ) ) )
					-- oxygene2.addProfile( user, params[3], string.sub( command, 4 + string.len( params[1] ) + string.len( params[2] ) + string.len( params[3] ), string.len( command ) ) )
				else
					if user then
						user:sendPrivMsgFmt("Wrong parameters. See -help chprofiles", true)
					end
				end
			elseif params[1] == "-chgetconfig" then
				if user then
					oxygene2.getConfig(user)
				end
			elseif params[1] == "-chset" then
				if params[2] and params[3] then
					oxygene2.setConfig(user, params[2], params[3])
				else
					if user then
						user:sendPrivMsgFmt( "Missing parameters. See -help", true)
					end
				end
			elseif params[1] == "-chreload" then
				if oxygene2.loadLanguage() then
					if user then
						user:sendPrivMsgFmt( "Language file loaded", true)
					end
					local counter = oxygene2.refreshAllUserData(hub)
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
						hub:sendChat(oxygene2.evaluateVariables(chattext, hub, nil))
					else
						if user then
							user:sendPrivMsgFmt( "Empty message, not sent.", true)
						end
					end
			end	
end

--// Initializing //--

dofile(DC():GetAppPath() ..  "scripts/libsimplepickle.lua")
oxygene2.loadSettings()

--// Listeners //--

dcpp:setListener("connected", "oxygene2_conn", 
	function (hub)
		local tolog = "[CONN] Connected to hub: " .. hub:getUrl()
		if not hub.oxygene2 then
			hub.oxygene2 = {}
			hub.oxygene2.state = { }
			hub.oxygene2.state.started = os.date("%Y. %m. %d - %H:%M:%S")
			hub.oxygene2.state.connected = os.time()
			hub.oxygene2.state.active = false --// provides 2 minutes inactivity to avoid pm-flooding, some hubs don't like that
			hub.oxygene2.userlist = {}
		end
		if oxygene2.isAllowed( hub ) then
			tolog = tolog .. ". The hub is added to the allowed hubs' list."
		end
		oxygene2.log(tolog)
	end
)

dcpp:setListener("disconnected", "oxygene2_disc", 
	function (hub)
		-- freeing up some memory
		local mem1 = collectgarbage("count")
		collectgarbage("collect")
		oxygene2.log("[CONN] Disconnected from hub: " .. hub:getUrl())
		oxygene2.log("[TRIG] " .. math.floor(mem1 - (collectgarbage("collect")) * 100)/100 .. " KiB memory has been freed" )
	end
)

dcpp:setListener( "adcPm", "oxygene2_pm",
	function( hub, user, text )
		local isop = user:isOp()
		local isallowed = oxygene2.isAllowed( hub )
		local params = oxygene2.tokenize(text)
		if isop and isallowed then
			oxygene2.commandParser(hub, user, text)
		end
		if isop then
			if params[1] == "-chaddhub" then
				if oxygene2.addHub(hub, params[2]) then
					user:sendPrivMsg( "OK. Reconnect to the hub with the client running this script to get correct userlist and stat.", true )
				else
					user:sendPrivMsg( "The hub couldn't be added (probably it's already done). See -chlisthubs", true)
				end
			elseif params[1] == "-chrmhub" then
				if oxygene2.rmHub(hub, params[2]) then
					user:sendPrivMsgFmt( "OK", true )
				else
					user:sendPrivMsg( "The hub couldn't be removed (probably it's even not added to the list). See -chlisthubs", true)
				end
			elseif params[1] == "-chlisthubs" then
				oxygene2.listHubs(hub, user, true)
			end
		end
	end
)

dcpp:setListener( "adcChat", "oxygene2_chat",
	function( hub, user, text )
		local isop = user:isOp()
		local isallowed = oxygene2.isAllowed( hub )
		if isallowed then
			local userdata = oxygene2.buildUserData( hub, user, "chatmsg", text )
			oxygene2.updateUser(hub, userdata)
			oxygene2.activateTriggers( hub, user:getSid(), "MSG" )
		end
		if isop and isallowed then
			local params = oxygene2.tokenize(text)
			if params[1] == "-help" or params[1] == "-?" then
				if params[2] then
					oxygene2.getHelpFor(user, params[2])
				else
					oxygene2.sendHelp(hub, user)
				end
			elseif params[1] == "-scripts" then
				hub:sendChat("oxygene2.lua: Running on this hub since: " .. hub.oxygene2.state.started .. " (" .. Oxygenesettings.version .. ")")
			end
		end
	end
)

dcpp:setListener( "userInf", "oxygene2_inf",
	function( hub, user, flags )
		if oxygene2.isAllowed( hub ) then
			local userdata = oxygene2.buildUserData(hub, user, "INF", flags)
			oxygene2.updateUser(hub, userdata)
			oxygene2.activateTriggers( hub, user:getSid(), "INF" )
		end
	return nil
	end
)

dcpp:setListener( "adcUserQui", "oxygene2_userquit",
	function( hub, sid )
		if oxygene2.isAllowed( hub ) then
			oxygene2.removeUserFromHub(hub, sid )
		end
	return nil
	end
)

dcpp:setListener( "timer", "oxygene2_timer",
	function()
		if os.time() >= ( Oxygenesettings.lastupdated + Oxygenesettings.config.inactivetime ) then
			Oxygenesettings.lastupdated = os.time()
			for k,hub in pairs(dcpp:getHubs()) do
				if os.time() >= ( hub.oxygene2.state.connected + Oxygenesettings.config.inactivetime ) then
					if (not hub.oxygene2.state.active) then
						hub.oxygene2.state.active = true
						if oxygene2.isAllowed( hub ) then
							hub:sendChat(oxygene2.GETSTRING("GeneralStart"))
						end
					end
				end
			end
		end
		if Oxygenesettings.hasTimerTrig ~= 0 then
			for k,hub in pairs(dcpp:getHubs()) do
				if oxygene2.isAllowed( hub ) then
					oxygene2.activateTriggers(hub, nil, "timer")
				end
			end
		end
	end																			
)

DC():PrintDebug( "  ** Loaded oxygene2.lua **" )
