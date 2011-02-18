--// WELCOME AND LICENSE //--
--[[
     bridge.lua -- Version 0.6a
     bridge.lua -- An AS implementation for BCDC++ as a Bridge.
     bridge.lua -- Revision: 053/20080713

     Copyright (C) 2007-2008 Szabolcs Molnár <fleet@elitemail.hu>
     
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
		053/20080713: Fixed: Reassign uid when adding/removing op-right for an online user (ADC)
		052/20080712: Fixed: Now able to found AppServer when control hub is ADC
		051/20080527: Fixed: Nick change
		050/20080510: Added: Spectators
		049/20080502: Added: Last seen date of registered users: updated when user comes online and when goes offline; Verify adc nick if taken by another user
		048/20080501: Fixed: Sending CSE when bridge is restarted, new escaping
		047/20080427: Modified: A lot of structural changes to ease future development and help the script bug-free
		046/20080426: Fixed: -b i shows correct user rank when a user is registered on two different ADC hubs
		045/20080425: Fixed: A possible AS detection bug on NMDC hubs; A little cleanup
		044/20080419: Fixed: Sending CSE and destroying running sessions when AppServer comes back online from offline state
		043/20080418: Fixed: Modified gud/sud according to AS specification
		042/20080417: Fixed: Added more escaping according to AS specification
		041/20071214: Fixed: Missing @-escapes added
		040/20071211: Added: -bridge getconfig, -bridge set, "broadcast" modes "regs", "main", "off
		039/20071205: Fixed: Setting up default credit on NMDC hubs
		038/20071202: Removed: cre command; Added: gud, sud (0.59a)
		037/20070508: Added: Nickchange notification when user is in session (0.5e)
		036/20070508: Fixed: Nickchanges are handled on adc-hubs (0.5d)
		035/20070507: Added: -b as rm command (0.5c)
		034/20070505: Added: -b as list, -b as add commands; Fixed: some possible problems when control hub is adc (0.5b)
		033/20070501: Added: -bridge unreg command (0.5a)
		032/20070501: Fixed: an UTF-8 issue, -b i also works correctly (0.49i)
		031/20070426: Fixed: broadcast on nmdc hubs (0.49h)
		030/20070425: Modified: Switched to utf8. message encoding works properly on both nmdc and adc hubs (0.49g)
		029/20070424: Fixed: broadcast message on adc hub (0.49f)
		028/20070424: Fixed: adc nick shown on -b stat (0.49e)
		027/20070424: Fixed: -b info on adc hub (0.49d)
		026/20070424: Fixed: All bridge<->appserver commands should convert between local cp/utf8 (0.49c)
		025/20070424: Fixed: Utf/nonutf handled correctly on msg from the AppServer (0.49b)
		024/20070423: Added: Basic ADC functionality (0.49a)
		023/20070411: Fixed: Users only stored when the appserver removes/reassigns their session OR they got a credit before they quit (0.4h)
		022/20070411: Fixed: Removing user from session when he/she quits (0.4g)
		021/20070409: Modified: Removed bloatware stats, a prettier one added (0.4f)
		020/20070409: Fixed: Userrank in -b info command. Added: @info command (0.4e)
		019/20070408: Modified: -b stat, now defaults to top20 (0.4d)
		018/20070408: Added: "@" command to send messages to the current session (0.4c)
		017/20070406: Fixed: Statistic layout: added time formatting (0.4b)
		016/20070328: Modified: user stat (0.4a)
		015/20070324: Added: -b stat, -b info (0.3a)
		014/20070310: Fixed: a memory leak (0.2c)
		013/20070226: Added: -b shortcut for -bridge command, ls instead of list sessions. (0.2b)
		012/20070226: Added: -bridge msg command, -bridge list modified. Fixed: Not trying to set Appserver to "offline" state when there is no session.
		011/20070223: Added: Storing users (0.2a)
		010/20070223: Added: appname parameter processing on ase command (0.1d)
		009/20070222: Fixed: qui only sent if there is no session for the user (0.1c)
		008/20070221: Fixed: some cre, cse bugs (0.1b)
		007/20070220: Updated: cse command: session parameter added
		006/20070220: Added: bridge sends cse when the appserver comes online at the first time, and when the appserver reconnects
		005/20070220: Added: cse command processing (0.1a)
		004/20070218: Fixed: Clearing sessions when the bridge reconnects to a hub
		003/20070218: Escaping, ase, cre, qui, msg individual/session/allexceptone are implemented
		002/20070218: UID assignment, some very basic msg implementation
		001/20070217: Initial release
]]

if not bridge then
	bridge = {}
	bridge._sessions = {}
	bridge._users = {}
	bridge._uid_resolver = {}
	bridge._uid_storage = {}
	bridge._uid_storage.c = {}
	bridge._uid_storage.m = {}
	bridge._uid_storage.o = {}
	-- setting up free uids
	for k = 1, 32000 do
		bridge._uid_storage.c[k] = true;
		bridge._uid_storage.m[k] = true;
		bridge._uid_storage.o[k] = true;
	end
end

if not bridgeconf then
	bridgeconf = {}
	bridgeconf.settingsfile = DC():GetAppPath() .. "scripts\\bridge_settings.txt"
	bridgeconf.config = {}
	bridgeconf.config.defaultcredit = "200"
	bridgeconf.config.controlhub = "my.hub.com:1411"
	bridgeconf.config.broadcast = "main" --// possible values: "regs", "main", "off"
	bridgeconf.appservers = {}
	bridgeconf.users = {}
	bridgeconf.protocol = "AS001"
	bridgeconf.internal = {}
end

--// CONFIG MANAGEMENT //--

bridge.LoadSettings = function(this)
	local o = io.open( bridgeconf.settingsfile, "r" )
	if o then
		dofile( bridgeconf.settingsfile )
		o:close()
	end
	return true
end

bridge.SaveSettings = function(this)
	pickle.store(bridgeconf.settingsfile, { bridgeconf = bridgeconf })
	return true
end

bridge.InitializeConfig = function(this)
	this:LoadSettings()
	
	--// Settings to reset every startup
	bridgeconf.settingsfile = DC():GetAppPath() .. "scripts\\bridge_settings.txt"
	bridgeconf.internal.version = "0.6a"

	--// Updates needed because of version change (remove these lines later)
	-- version 0.5
	if not bridgeconf.config.defaultcredit then bridgeconf.config.defaultcredit = "200" end
	if not bridgeconf.config.controlhub then bridgeconf.config.controlhub = "my.hub.com:1411" end
	if not bridgeconf.config.broadcast then bridgeconf.config.broadcast = "main" end --// possible values: "regs", "main", "off"
	-- version 0.6, 20080502
	for url in pairs(bridgeconf.users) do
		for id in pairs(bridgeconf.users[url].users) do
			if not bridgeconf.users[url].users[id].lastseen then
				bridgeconf.users[url].users[id].lastseen = os.time()
			end
		end
	end
	
	-- set all appservers to offline state
	for id, as in pairs(bridge:GetAppServers()) do
		as.state = "offline"
	end
end

bridge.GetConfig = function(this, variable)
	return bridgeconf.config[variable]
end

bridge.SetConfig = function(this, variable, value)
	local ret = false
	if bridgeconf.config[variable] then
		bridgeconf.config[variable] = value
		bridge:SaveSettings()
		ret = true
	end
	return ret
end

bridge.SendConfig = function(this, user)
	user:Message("       ------------------------------------------------------------------------------------------------")
	user:Message("       Cofiguration                                                        Bridge.lua" .. bridgeconf.internal.version)
	user:Message("       ------------------------------------------------------------------------------------------------")
	for var in pairs(bridgeconf.config) do
		user:Message("       " .. tostring(var) .. "\t\t\t" .. tostring(bridgeconf.config[var]) )
	end
	user:Message("       ------------------------------------------------------------------------------------------------")
end

--// APPSERVER HANDLERS //--

function bridge.IsItAppServer(url, id)
	local ret = false
	local asurl = bridge:GetConfig("controlhub")
	if asurl == url then
		for k in pairs(bridgeconf.appservers) do
			if k == id then
				ret = true
			end
		end
	end
	return ret
end

function bridge.GetAsNick(asid)
	local ret = false
	if bridgeconf.appservers[asid] then
		ret = bridgeconf.appservers[asid].nick
	end
	return ret
end

function bridge.AddAppServer(nick)
	local ret, err = false, "-"
	local chuburl = bridge:GetConfig("controlhub")
	local hub = dcpp:findHub(chuburl)
	if hub then
		local users = {}
		if hub:getProtocol() == "nmdc" then
			users = hub:findUsers(DC():FromUtf8(nick))
		else
			users = hub:findUsers(nick)
		end
		local user = false
		for k in pairs(users) do
			user = users[k]
		end
		if user then
			local id = nick
			if hub:getProtocol() == "adc" then
				id = user:getCid()
			end
			if not bridge.IsItAppServer(chuburl, id) then
				bridgeconf.appservers[id] = {}
				bridgeconf.appservers[id].state = "online"
				bridgeconf.appservers[id].nick = nick
				bridge:SaveSettings()
				if isitadc then
					err = "OK, AppServer " .. id .. " with nick " .. nick .. " added."
				else
					err = "OK, AppServer with nick " .. nick .. " added."
				end
				ret = true
			else
				err = "User is already an AppServer, cannot add twice"
			end
		else
			err = "No user found with nick " .. nick .. " on " .. chuburl .. ". Cannot add offline AppServers."
		end
	else
		DC():PrintDebug("DEBUG#250: You are not connected to control hub, cannot add AppServer")
		err = "You are not connected to control hub, cannot add any AppServer."
	end

	return ret, err
end

function bridge.RmAppServer(nick)
	local ret, err = false, "No AppServer with nick " .. nick .. " found. See \"-bridge appserver list\"."
	for id in pairs(bridgeconf.appservers) do
		if bridgeconf.appservers[id].nick == nick then
			err = "AppServer " .. nick .. " with id " .. id .. " removed."
			ret = true
			bridgeconf.appservers[id] = nil
			bridge:SaveSettings()
			break
		end
	end
	return ret, err
end

bridge.SendASList = function(this, user)
	local counter = 0
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       AppServers                                                                                 Bridge.lua " .. bridgeconf.internal.version)
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	for id in pairs(bridgeconf.appservers) do
		user:Message("       " .. bridgeconf.appservers[id].nick .. " [" .. id .. "]")
		counter = counter + 1
	end
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       Total: " .. tostring(counter) .. " item(s).")
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
end

bridge.GetAppServers = function(this)
	return bridgeconf.appservers
end

-- state: offline, idle, online
function bridge.GetAppServerState(id)
	local ret = false
	for k in pairs(bridgeconf.appservers) do
		if k == id then
			ret = bridgeconf.appservers[k].state
		end
	end
	return ret
end

-- state: offline, idle, online
function bridge.SetAppServerState(id, state)
	local ret = false
	for k in pairs(bridgeconf.appservers) do
		if k == id then
			bridgeconf.appservers[k].state = state
			ret = true
		end
	end
	return ret
end

function bridge.SetAppServerNick(id, nick)
	local ret = false
	if bridgeconf.appservers[id] then
		bridgeconf.appservers[id].nick = nick
		bridge:SaveSettings()
		ret = true
		DC():PrintDebug("DEBUG#665: AppServer with id " .. id .. " has changed its nick. New nick: " .. nick )
	end
	return ret
end

-- returns with a table of online appservers (as dcusers)
-- if cmdtype == "se", then appserver for session
-- if cmdtype == "as" then param is the appserver dcuser itself
-- if param is empty string, returns with all online appservers, disregarding cmdtype
function bridge.GetOnlineAppServers(cmdtype, param)
	-- trying to get AppServer hub..
	local url = bridge:GetConfig("controlhub")
	local hub = false
	local ret = {}
	for k,h in pairs(dcpp:getHubs()) do
		if h:getUrl() == url then
			hub = h
			break
		end
	end
	if hub then
		if param == "" then
			-- multiple servers
			for asid in pairs(bridgeconf.appservers) do
				local tmp = {}
				if hub:getProtocol() == "nmdc" then
					tmp = hub:findUsers( DC():FromUtf8(asid), nil )
					for k in pairs(tmp) do
						table.insert(ret, tmp[k])
					end
				else
					tmp = hub:getUserByCid(asid)
					table.insert(ret, tmp)
				end

			end
		else
			if cmdtype == "se" then
				local session = bridge:GetSession(param)
				local asid = session:GetASId()
				local asnick = bridge.GetAsNick(asid)
				-- trying to find the user
				if hub:getProtocol() == "nmdc" then
					ret = hub:findUsers( DC():FromUtf8(asnick), nil )
				else
					table.insert(ret, hub:getUserByCid(asid))
				end
			elseif cmdtype == "as" then
				--[[
				-- trying to find the user
				if hub:getProtocol() == "nmdc" then
					ret = hub:findUsers( DC():FromUtf8(param:getNick()), nil)
				else
					table.insert(ret, hub:getUserByCid( param:getCid(), nil)
				end
				]]
				table.insert(ret, param)
			end
		end
	else
		DC():PrintDebug("[bridge.lua] You are not connected to control hub (" .. url .. "), cannot find AppServers" )
	end
	return ret
end

--// USER FUNCTIONS //--

bridge.UCreate = function(this, hub, dcuser)
	
	local class = "c"
	if dcuser:isOp() then
		class = "o"
	elseif false then
		--// TODO: Make class m available
		class = "m"
	end
	
	local val = 0
	--// Get first available id
	for k in pairs(bridge._uid_storage[class]) do
		if bridge._uid_storage[class][k] then
			val = k
			break
		end
	end
	local uid = class .. tostring(val)
	local id = ""
	local nick = dcuser:getNick()
	local url = hub:getUrl()
	local sid = false
	local cid = false
	local cidornick = false
	local protocol = false
	
	--// Reserving UID in uid storage
	bridge._uid_storage[class][val] = false

	if dcuser:getProtocol() == "adc" then
		sid = dcuser:getSid()
		id = sid
		cid = dcuser:getCid()
		protocol = "adc"
		cidornick = cid
	else
		nick = DC():ToUtf8(nick)
		id = nick
		protocol = "nmdc"
		cidornick = nick
	end
	
	bridge._uid_resolver[url][id] = uid
	
	--// User object
	
	--// Properties
	
	bridge._users[uid] = {}
	bridge._users[uid]._info = {}
	bridge._users[uid]._info.sname = ""
	bridge._users[uid]._info.nick = nick
	bridge._users[uid]._info.url = url
	bridge._users[uid]._info.sid = sid
	bridge._users[uid]._info.cid = cid
	bridge._users[uid]._info.protocol = protocol
	bridge._users[uid]._info.uid = uid
	bridge._users[uid]._fields = {}
	bridge._users[uid]._spect = {}
	bridge._users[uid]._ud = {}
	bridge._users[uid]._dcuser = dcuser
	
	--// Methods
	
	bridge._users[uid].ChangeNick = function(this, nick)
		local oldnick = this:GetNick()
		if oldnick ~= nick then
			local session = this:GetSession()
			local cid = this:GetCid()
			local url = this:GetUrl()
			
			--// Checking if my new nick is registered by another user. If so, then change it.
			while bridge:IsNickRegistered(url, nick) do
				nick = nick .. "0"
			end
			
			this._info.nick = nick
			
			--// Notify the session about nickchange
			if session then
				session:Message("*** " .. oldnick .. " is now known as " .. nick)
			end
			
			--// Change the saved nick
			if bridgeconf.users[url] and bridgeconf.users[url].users[cid]  then
				bridgeconf.users[url].users[cid].nick = nick
				bridge:SaveSettings()
			end
		end
	end
	
	bridge._users[uid].FixCT = function(this)
		local ret = false
		local uid = this:GetUid()
		local class = string.sub(uid, 1, 1)
		local dcuser = this:GetDCUser()
		if dcuser:isOp() then
			if class ~= "o" then
				bridge:ReassignUid(uid, "o")
			end
		else
			if class == "o" then
				--// TODO: class "m"?
				bridge:ReassignUid(uid, "c")
			end
		end
		return ret
	end
	
	bridge._users[uid].GetField = function(this, field)
		return this._fields[field]
	end
	
	bridge._users[uid].GetNick = function(this)
		return this._info.nick
	end
	
	bridge._users[uid].GetSName = function(this)
		return this._info.sname
	end
	
	bridge._users[uid].GetSession = function(this)
		return bridge._sessions[this:GetSName()]
	end
	
	bridge._users[uid].GetUrl = function(this)
		return this._info.url
	end
	
	bridge._users[uid].GetSid = function(this)
		return this._info.sid
	end
	
	bridge._users[uid].GetCid = function(this)
		return this._info.cid
	end
	
	bridge._users[uid].GetDCUser = function(this)
		return this._dcuser
	end
	
	bridge._users[uid].GetUid = function(this)
		return this._info.uid
	end
	
	bridge._users[uid].GetProtocol = function(this)
		return this._info.protocol
	end
	
	bridge._users[uid].GetId = function(this)
		if this:GetProtocol() == "adc" then
			return this._info.sid
		else
			return this._info.nick
		end
	end
	
	bridge._users[uid].GetUd = function(this, variable)
		return this._ud[variable]
	end
	
	bridge._users[uid].GetAllUd = function(this)
		return this._ud
	end
	
	bridge._users[uid].IsRegistered = function(this)
		local ret = false
		local url = this:GetUrl()
		local id = ""
		if bridgeconf.users[url] then
			if this:GetProtocol() == "adc" then
				id = this:GetCid()
			else
				id = this:GetNick()
			end
			if bridgeconf.users[url].users[id] then
				ret = true
			end
		end
		return ret
	end
	
	bridge._users[uid].Message = function(this, msg, spect)
		local ret = false
		local dcuser = this:GetDCUser()
		
		if spect then
			local session = this:GetSession()
			if session then
				local sname = session:GetSName()
				local spectlist = session:GetSpectList()
				local uid = this:GetUid()
				for spectuid in pairs(spectlist) do
					local spectator = bridge:GetUser(spectuid)
					if spectator then
						spectator:Message("[" .. sname .. "] -> [" .. uid .. "]: " .. msg)
					end
				end
			end
		end
		if this:GetProtocol() == "nmdc" then
			msg = DC():FromUtf8(msg)
		end
		dcuser:sendPrivMsgFmt(msg, true)
		return ret
	end
	
	bridge._users[uid].Destroy = function(this, save)
		
		local url = this:GetUrl()
		local id = this:GetId()
		local uid = this:GetUid()
		
		--// Remove spectator assignments
		local spectlist = this:GetSpectList()
		for sname in pairs(spectlist) do
			local session = bridge:GetSession(sname)
			session:RmSpectator(uid)
		end
		
		--// If the user is a session participant save settings
		if this:GetSName() ~= "" and save then
			this:Store()
		end
		
		if this:IsRegistered() then
			this:UpdateStat()
		end
		
		--// Freeing up resolvers and uid
		bridge._uid_resolver[url][id] = nil
		bridge:FreeUpUid(uid)
			
		--// Kill myself
		bridge._users[uid] = nil
	end
	
	bridge._users[uid].SetField = function(this, field, value)
		this._fields[field] = value
	end
	
	bridge._users[uid].SetSName = function(this, sname)
		this._info.sname = sname
		return true
	end
	
	bridge._users[uid].SetUd = function(this, variable, value)
		this._ud[variable] = value
		return true
	end
	
	bridge._users[uid].Store = function(this)
		
		local session = this:GetSession()
		if session then
			local url = this:GetUrl()
			local protocol = this:GetProtocol()
			local nick = this:GetNick()
			
			local id = ""
			if protocol == "adc" then
				id = this:GetCid()
			else
				id = this:GetNick()
			end
			
			local joindate = this:GetField("joindate")
			local partdate = os.time()
			local startcredit = this:GetField("startcredit")
			local endcredit = tonumber(this:GetUd("credit"))
			local appname = session:GetAppName()

			if not bridgeconf.users[url] then
				bridgeconf.users[url] = {}
				bridgeconf.users[url].type = protocol
				bridgeconf.users[url].users = {}
			end

			if not bridgeconf.users[url].users[id] then
				bridgeconf.users[url].users[id] = {}
				bridgeconf.users[url].users[id].added = os.time()
				bridgeconf.users[url].users[id].lastseen = 0
				bridgeconf.users[url].users[id].stat = {}
				bridgeconf.users[url].users[id].stat.totaltimeplayed = 0
				bridgeconf.users[url].users[id].stat.totalnumberofsessions = 0
				bridgeconf.users[url].users[id].stat.won = 0
				bridgeconf.users[url].users[id].stat.lost = 0
				bridgeconf.users[url].users[id].stat.drawn = 0
				bridgeconf.users[url].users[id].ud = {}
			end

			-- General info update:
			bridgeconf.users[url].users[id].ud.credit = tostring(endcredit)
			bridgeconf.users[url].users[id].lastplayed = partdate
			-- Last played nick
			bridgeconf.users[url].users[id].nick = nick

			-- Game stat update
			bridgeconf.users[url].users[id].stat.totaltimeplayed = bridgeconf.users[url].users[id].stat.totaltimeplayed + partdate - joindate
			bridgeconf.users[url].users[id].stat.totalnumberofsessions = bridgeconf.users[url].users[id].stat.totalnumberofsessions + 1
			if endcredit > startcredit then
				bridgeconf.users[url].users[id].stat.won = bridgeconf.users[url].users[id].stat.won + 1
			elseif endcredit == startcredit then
				bridgeconf.users[url].users[id].stat.drawn = bridgeconf.users[url].users[id].stat.drawn + 1
			else
				bridgeconf.users[url].users[id].stat.lost = bridgeconf.users[url].users[id].stat.lost + 1
			end

			bridge:SaveSettings()

		else
			DC():PrintDebug("DEBUG#6302: Trying to save userdata for user " .. this:GetUid() .. " but she doesn't have any session assignment" )
		end
	end
	
	--// Update last seen stat (maybe more later)
	bridge._users[uid].UpdateStat = function(this)
		ret = false
		if this:IsRegistered() then
			local url = this:GetUrl()
			local id = ""
			if this:GetProtocol() == "adc" then
				id = this:GetCid()
			else
				id = this:GetNick()
			end
			bridgeconf.users[url].users[id].lastseen = os.time()
			bridge:SaveSettings()
			ret = true
		end
		return ret
	end
	
	bridge._users[uid].Spectate = function(this, sname)
		local ret = false
		local ownsname = this:GetSName()
		if ownsname ~= sname then
			local session = bridge:GetSession(sname)
			if session then
				ret = session:AddSpectator(this:GetUid())
				if ret then
					this._spect[sname] = true
				end
			end
		end
		return ret
	end
	
	bridge._users[uid].UnSpectate = function(this, sname)
		local ret = false
		local session = bridge:GetSession(sname)
		if session then
			ret = session:RmSpectator(this:GetUid())
			if ret then
				this._spect[sname] = nil
			end
		end
		return ret
	end
	
	bridge._users[uid].GetSpectList = function(this)
		return this._spect
	end
	
	--// CONSTRUCTOR
	
	if bridge._users[uid]:IsRegistered() then
		--// Update last seen time
		bridge._users[uid]:UpdateStat()
		
		--// Copy UD values to memory
		for variable, value in pairs(bridgeconf.users[url].users[cidornick].ud) do
			bridge._users[uid]._ud[variable] = value
		end
	end
	
	if not bridge._users[uid]._ud.credit then
		bridge._users[uid]._ud.credit = bridge:GetConfig("defaultcredit")
	end
	
	--// If we are a non-registered ADC user, maybe our nick can be taken by a registered one
	--// In this case, we should change our nick to someone else
	if (bridge._users[uid]:GetProtocol() == "adc" and (not bridge._users[uid]:IsRegistered())) then
		if bridge:IsNickRegistered(url, bridge._users[uid]:GetNick()) then
			local oldnick = bridge._users[uid]:GetNick()
			bridge._users[uid]:ChangeNick(oldnick)
			local newnick = bridge._users[uid]:GetNick()
			DC():PrintDebug("DEBUG#6674: Nick " .. oldnick .. " is taken! New nick is " .. newnick .. "0")
		end
	end

	--// END OF CONSTRUCTOR
	
	return bridge._users[uid]
	
end

bridge.GetUser = function(this, uid)
	return bridge._users[uid]
end

bridge.GetUsers = function(this, requrl)
	local ret = {}
	for url in pairs(bridge._uid_resolver) do
		if url == requrl then
			for id, uid in pairs(bridge._uid_resolver[url]) do
				ret[uid] = bridge:GetUser(uid)
			end
		end
	end
	return ret
end

bridge.FreeUpUid = function(this, uid )
	local class = string.sub(uid, 1, 1)
	local id = tonumber(string.sub(uid, 2))
	
	local ret = false
	if not bridge._uid_storage[class][id] then
		ret = true
		bridge._uid_storage[class][id] = true
	end
	
	return ret
end

--// id: nick or sid
bridge.GetUid = function(this, url, id)
	
	local ret = false
	if bridge._uid_resolver[url] then
		if bridge._uid_resolver[url][id] then
			ret = bridge._uid_resolver[url][id]
		end
	end
	return ret
	
end

bridge.IsNickRegistered = function(this, url, nick)
	local ret = false
	if bridgeconf.users[url] then
		for id in pairs(bridgeconf.users[url].users) do
			if bridgeconf.users[url].users[id].nick == nick then
				ret = true
			end
		end
	end
	return ret
end

function bridge.GetCidforReg(nick, url)
	local ret = false
	if bridgeconf.users[url] then
		if bridgeconf.users[url].type == "adc" then
			for cid in pairs(bridgeconf.users[url].users) do
				if bridgeconf.users[url].users[cid].nick == nick then
					ret = cid
					break
				end
			end
		else
			DC():PrintDebug("DEBUG#1000: This hub is not ADC, cannot get CID: " .. url)
		end
	else
		DC():PrintDebug("DEBUG#1001: No hub with url: " .. url)
	end
	return ret
end

function bridge.FixOpList( hub, text )
	for nick in string.gmatch( string.sub( text, 9 ), "[^$]+") do
		local uid = bridge:GetUid(hub:getUrl(), nick )
		if uid then
			if string.sub(uid, 1, 1 ) ~= "o" then
				DC():PrintDebug("Reassigning uid " .. uid .. " to class o")
				local tmp = bridge:ReassignUid( uid, "o" )
				DC():PrintDebug("New uid: " .. tmp )
			end
		end
	end
end

bridge.ReassignUid = function(this, uid, newclass)
	
	local user = bridge:GetUser(uid)
	local url = user:GetUrl()
	local newuid = false
	local id = user:GetId()
	
	local session = user:GetSession()
	if session then
		bridge.SendQui( uid, session:GetSName() )
		user:Store()
		session:RmUser(uid)
	end
	
	local newid = 0
	--// Get first available id
	for k in pairs(bridge._uid_storage[newclass]) do
		if bridge._uid_storage[newclass][k] then
			newid = k
			break
		end
	end
	newUid = newclass .. tostring(newid)
	
	-- reserving new id
	bridge._uid_storage[newclass][newid] = false
	
	-- moving user to new uid
	bridge._uid_resolver[url][id] = newUid
	bridge._users[newUid] = bridge._users[uid]
	bridge._users[newUid]._info.uid = newUid
	bridge._users[uid] = nil
	
	-- freeing up old uid
	bridge:FreeUpUid(uid)
	
	return newUid
end

bridge.DelReg = function(this, nick, url)
	local ret = false
	local err = "OK"
	local cidornick = ""
	if bridgeconf.users[url] then
		if (bridgeconf.users[url].type == "adc") then
			cidornick = bridge.GetCidforReg(nick, url)
		else
			cidornick = nick
		end
		
		if bridgeconf.users[url].users[cidornick] then
			
			-- Check if we are connected to the hub
			local hub = dcpp:findHub(url)
			if hub then
				local id = false
				if hub:getProtocol() == "adc" then
					id = hub:getSidbyCid(cidornick)
				else
					id = cidornick
				end
				
				-- Check if the user is online.. If it is, set his credits back to the default value
				local uid = bridge:GetUid(url, id)
				if uid then
					local user = bridge:GetUser(uid)
					user:SetUd("credit", bridge:GetConfig("defaultcredit"))
				end
			end
			
			--// Delete user from table
			bridgeconf.users[url].users[cidornick] = nil
			bridge:SaveSettings()
			
			ret = true
		else
			err = "No user with cid/nick " .. cidornick .. " found on hub " .. url
		end
	else
		err = "Hub " .. url .. " doesn't exist or has no users registered."
	end
	return ret, err
end

--// SESSION FUNCTIONS //--

bridge.SCreate = function(this, asid, sname, appname)
	
	bridge._sessions[sname] = {}
	bridge._sessions[sname]._users = {}
	bridge._sessions[sname]._spect = {}
	bridge._sessions[sname]._info = {}
	bridge._sessions[sname]._info.asid = asid
	bridge._sessions[sname]._info.appname = appname
	bridge._sessions[sname]._info.sname = sname
	bridge._sessions[sname]._info.date = os.time()
	
	--// Methods
	
	bridge._sessions[sname].AddUser = function(this, uid)
		local ret = false
		local user = bridge:GetUser(uid)
		if user then
			ret = true
			user:SetSName(this:GetSName())
			user:SetField("startcredit", tonumber(user:GetUd("credit")))
			user:SetField("joindate", os.time())
			this._users[uid] = user
			
			--// Checking if the joining user is already a spectator
			if this:IsSpectator(uid) then
				this:RmSpectator(uid)
				this:Message("*** Joins: Previously spectator " .. user:GetNick() .. "!")
				user:Message("You are not allowed to further spectate this session!")
			end
			
			--// Message for spectators
			local sname = this:GetSName()
			local spectlist = this:GetSpectList()
			for spectuid in pairs(spectlist) do
				local spectator = bridge:GetUser(spectuid)
				if spectator then
					spectator:Message("[" .. sname .. "] *** Joins: " .. user:GetNick() .. " [" .. uid .. "]")
				end
			end
			
		end
		return ret
	end
	
	bridge._sessions[sname].RmUser = function(this, uid)
		local ret = false
		if this._users[uid] then
			
			ret = true
			local user = bridge:GetUser(uid)
			user:SetSName("")
			this._users[uid] = nil
			
			--// Message for spectators
			local sname = this:GetSName()
			local spectlist = this:GetSpectList()
			for spectuid in pairs(spectlist) do
				local spectator = bridge:GetUser(spectuid)
				if spectator then
					spectator:Message("[" .. sname .. "] *** Parts: " .. user:GetNick() .. " [" .. uid .. "]")
				end
			end
			
			--// auto-destroy session if usercount is 0
			if this:UserCount() == 0 then
				DC():PrintDebug("DEBUG#6374: Session .. " .. this:GetSName() .. " is empty, removing.")
				this:Destroy()
			end
		end
		return ret
	end
	
	bridge._sessions[sname].GetAppName = function(this, uid)
		return this._info.appname
	end
	
	bridge._sessions[sname].GetASId = function(this, uid)
		return this._info.asid
	end
	
	bridge._sessions[sname].GetSName = function(this, uid)
		return this._info.sname
	end
	
	bridge._sessions[sname].GetUser = function(this, uid)
		return this._users[uid]
	end
	
	bridge._sessions[sname].GetUsers = function(this)
		return this._users
	end
	
	bridge._sessions[sname].UserCount = function(this)
		local count = 0
		for k in pairs(this._users) do
			count = count + 1
		end
		return count
	end
	
	bridge._sessions[sname].Message = function(this, msg, spect)
		ret = false
		
		if spect then
			local sname = this:GetSName()
			local spectlist = this:GetSpectList()
			for spectuid in pairs(spectlist) do
				local spectator = bridge:GetUser(spectuid)
				if spectator then
					spectator:Message("[" .. sname .. "] -> [session]: " .. msg)
				end
			end
		end
		
		for uid, user in pairs(this:GetUsers()) do
			ret = user:Message(msg) or ret
		end
		return ret
	end
	
	bridge._sessions[sname].MessageUser = function(this, uid, msg, allbuthim, spect)
		local ret = false
		if allbuthim then
			--// a session message to everyone who is not with uid
			if spect then
				local sname = this:GetSName()
				local spectlist = this:GetSpectList()
				for spectuid in pairs(spectlist) do
					local spectator = bridge:GetUser(spectuid)
					if spectator then
						spectator:Message("[" .. sname .. "] -> [session but " .. uid .. "]: " .. msg)
					end
				end
			end
			for useruid, user in pairs(this:GetUsers()) do
				if useruid ~= uid then
					user:Message(msg)
				end
			end
		else
			--// a single user message
			local user = this:GetUser(uid)
			user:Message(msg, spect)
		end
		local user = this:GetUser(uid)
		if user then
			ret = true
			
		end
		return ret
	end
	
	bridge._sessions[sname].AddSpectator = function(this, uid)
		local ret = false
		if not this._spect[uid] then
			ret = true
			this._spect[uid] = true
		end
		return ret
	end
	
	bridge._sessions[sname].IsSpectator = function(this, uid)
		local ret = false
		if this._spect[uid] then
			ret = true
		end
		return ret
	end
	
	bridge._sessions[sname].RmSpectator = function(this, uid)
		local ret = false
		if this._spect[uid] then
			ret = true
			this._spect[uid] = nil
		end
		return ret
	end
	
	bridge._sessions[sname].GetSpectList = function(this)
		return this._spect
	end
	
	bridge._sessions[sname].Destroy = function(this, msg)
		
		local sname = this:GetSName()
		
		--// Removing spectators
		local spectlist = this:GetSpectList()
		
		--// Broadcast message, if any
		if msg then
			this:Message(msg, true)
		end
		
		--// Spectator message
		for uid in pairs(spectlist) do
			local user = bridge:GetUser(uid)
			user:Message("[" .. sname .. "] Destroying session.")
			user:UnSpectate(sname)
		end
		
		--// Removing session assignment from users
		for uid, user in pairs(this:GetUsers()) do
			user:SetSName("")
		end
		
		--// Kill myself
		bridge._sessions[sname] = nil

	end
	
	return bridge._sessions[sname]
	
end

bridge.GetSession = function(this, sname)
	return bridge._sessions[sname]
end

--// asid is optional. if absent, return all sessions
bridge.GetSessions = function(this, asid)
	if not asid then
		return bridge._sessions
	else
		local ret = {}
		for sname, session in pairs(bridge._sessions) do
			if session:GetASId() == asid then
				ret[sname] = bridge._sessions[sname]
			end
		end
		return ret
	end
end

--// UTILITES //--

bridge.Tokenize = function(this, str)
	local ret = {}
	string.gsub( str, "([^ ]+)", function( s ) table.insert( ret, s ) end )
	return ret
end

bridge.Escape = function(this, message, inverse)
	if inverse then
		message = string.gsub(message, "\\a", "@")
		message = string.gsub(message, "\\\\", "\\")
	else
		message = string.gsub(message, "\\", "\\\\")
		message = string.gsub(message, "@", "\\a")
	end
	return message
end

function bridge.FormatTime(seconds)
	-- perc: 60 sec
	-- óra: 3600 sec
	-- nap: 86400 sec
	local ret = ""

	local rem = seconds
	local day = math.floor(rem / 86400)
	rem = rem - day * 86400
	local hour = math.floor(rem / 3600)
	rem = rem - hour * 3600
	local min = math.floor(rem / 60)
	rem = rem - min * 60
	local sec = rem
	local flag = false

	if day > 0 then
		ret = tostring(day) .. " nap"
		flag = true
	end
	if hour > 0 then
		if flag then
			ret = ret .. ", "
		else
			flag = true
		end
		ret = ret .. tostring(hour) .. " óra"
	end

	if min > 0 then
		if flag then
			ret = ret .. ", "
		else
			flag = true
		end
		ret = ret .. tostring(min) .. " perc"
	end
	
	if sec > 0 then
		if flag then
			ret = ret .. ", "
		else
			flag = true
		end
		ret = ret .. tostring(sec) .. " másodperc"
	end
	
	return ret
end

--// BRIDGE -> APPSERVER COMMANDS //--

-- cmdtype: "as" for appserver specified sending, "se" for session-specified sending
function bridge.SendCommand(cmdtype, param, command)
	local ret = false
	local controlhub = dcpp:findHub(bridge:GetConfig("controlhub"))
	if controlhub then
		local astable = bridge.GetOnlineAppServers(cmdtype, param)
		if #astable > 0 then
			for k, asuser in pairs(astable) do
				if asuser:getProtocol() == "adc" then
					asuser:sendPrivMsgFmt(command, true)
				else
					asuser:sendPrivMsgFmt(DC():FromUtf8(command), true)
				end
			end
			ret = true
		else
			if cmdtype == "se" and param ~= "" then
				local session = bridge:GetSession(param)
				local asid = session:GetASId()
				bridge.SetAppServerState(asid, "offline")
				DC():PrintDebug("DEBUG#101: Appserver " .. tostring(asid) .. " is offline. Command not sent: " .. command )
			elseif cmdtype == "as" then
				bridge.SetAppServerState(param, "offline")
				DC():PrintDebug("DEBUG#102: Appserver " .. tostring(param) .. " is offline. Commmand not sent: " .. command )
			else --// cmdtype == "se", param == "" ..
				DC():PrintDebug("DEBUG#102: All appservers are offline. Commmand not sent: " .. command )
			end
		end
	else
		DC():PrintDebug("DEBUG#103: You are not connected to Control hub, cannot get AS list")
	end
	return ret
end

function bridge.SendQui( uid, sname )
	local ret = false
	local user = bridge:GetUser(uid)
	
	if user then
		local nick = user:GetNick()
		local text = "@" .. bridgeconf.protocol .. "@qui@" .. uid .. "@" .. sname .. "@" .. bridge:Escape(nick)
		ret = bridge.SendCommand("se", sname, text)
	else
		DC():PrintDebug("DEBUG#1041: No user found with uid " .. uid)
	end
	
	return ret
end

function bridge.SendCse( appserver, sname )
	local ret = false
	
	local text = "@" .. bridgeconf.protocol .. "@cse@" .. sname
	ret = bridge.SendCommand("as", appserver, text)

	return ret
end

function bridge.SendSud( appserver, uid, sname, variable )
	local ret = false
	
	local user = bridge:GetUser(uid)
	if user then
		local value = user:GetUd(variable)
		if value then
			local text = "@" .. bridgeconf.protocol .. "@sud@" .. uid .. "@" .. sname .. "@" .. variable .. "@" .. bridge:Escape(tostring(value))
			ret = bridge.SendCommand("as", appserver, text)
		else
			local text = "@" .. bridgeconf.protocol .. "@sud@" .. uid .. "@" .. sname .. "@" .. variable .. "@"
			ret = bridge.SendCommand("as", appserver, text)
		end
	end
	
	return ret
end

--// APPSERVER -> BRIDGE COMMAND PROCESSOR //--

function bridge.ProcessAS(hub, appserver, message)
	DC():PrintDebug("DEBUG: \"" .. message .. "\"")
	if string.len(message) < 11 then
		-- invalid command,
		-- @AS001@...@ is at least 11 characters long
		DC():PrintDebug("Invalid message: \"" .. message .. "\"")
		return false
	end
	
	local proto = string.sub(message, 1, 7)
	if proto ~= "@" .. bridgeconf.protocol .. "@" then
		DC():PrintDebug("[bridge] Incompatible protocol: " .. proto )
		return false
	end
	if string.find(message, "^@" .. bridgeconf.protocol .. "@...@") then
		local command = string.sub(message, 8, 10)
		
		if command == "ase" then
			bridge.ProcessAse(hub, appserver, message)
		elseif command == "cse" then
			bridge.ProcessCse(hub, appserver, message)
		elseif command == "msg" then
			bridge.ProcessMsg(hub, message)
		elseif command == "gud" then
			bridge.ProcessGud(hub, appserver, message)
		elseif command == "sud" then
			bridge.ProcessSud(hub, message)
		else
			DC():PrintDebug("Invalid command: " .. command )
		end
	end
	return true
end

function bridge.ProcessAse(controlhub, appserver, message)
	if string.find(message, "^@" .. bridgeconf.protocol .. "@ase@.*@.*@.*@.*$") then
		local uid = string.gsub(message, "^@" .. bridgeconf.protocol .. "@ase@(.*)@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@ase@(.*)@(.*)@(.*)@(.*)$", "%2")
		local appname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@ase@(.*)@(.*)@(.*)@(.*)$", "%3")
		local msg = bridge:Escape(string.gsub(message, "^@" .. bridgeconf.protocol .. "@ase@(.*)@(.*)@(.*)@(.*)$", "%4"), true)

		if uid == "" then
			DC():PrintDebug("[bridge]: Empty uid in \"ase\": " .. message)
		else
			local user = bridge:GetUser(uid)
			
			--// If user was previously part of a session, save user data and remove
			local usersession = user:GetSession()
			if usersession then
				user:Store()
				usersession:RmUser(uid)
			end
			
			--// If got a new session assignment, add:
			if sname ~= "" then
				-- add user for session
				local session = bridge:GetSession(sname)
				if session then
					session:AddUser(uid)
				else
					local asid = ""
					if controlhub:getProtocol() == "adc" then
						asid = appserver:getCid()
					else
						asid = appserver:getNick()
					end
					session = bridge:SCreate(asid, sname, appname)
					session:AddUser(uid)
				end
			end
			
			--// Forward message
			if msg ~= "" then
				user:Message(msg, true)
			end
			
		end
	else
		DC():PrintDebug("Invalid \"ase\": " .. message)
	end
	return true
end

function bridge.ProcessCse(controlhub, appserver, message)
	if string.find(message, "^@" .. bridgeconf.protocol .. "@cse@.*@.*$") then
		
		local sname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@cse@(.*)@(.*)$", "%1")
		local msg = bridge:Escape(string.gsub(message, "^@" .. bridgeconf.protocol .. "@cse@(.*)@(.*)$", "%2"), true)
		local asid = ""
		
		if controlhub:getProtocol() == "adc" then
			asid = appserver:getCid()
		else
			asid = appserver:getNick()
		end
		if sname == "" then
			local sessions = bridge:GetSessions(asid)
			for snameb, session in pairs(sessions) do
				for uid, user in pairs(session:GetUsers()) do
					user:Store()
				end
				session:Destroy(msg)
			end
		else
			local session = bridge:GetSession(sname)
			for uid, user in pairs(session:GetUsers()) do
				user:Store()
			end
			session:Destroy(msg)
		end
		
	else
		DC():PrintDebug("Invalid \"cse\": " .. message)
	end
	return true
end

function bridge.ProcessMsg(hub, message)
	if string.find(message, "^@" .. bridgeconf.protocol .. "@msg@.*@.*@.*$") then
		local uid = string.gsub(message, "^@" .. bridgeconf.protocol .. "@msg@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@msg@(.*)@(.*)@(.*)$", "%2")
		local msg = string.gsub(message, "^@" .. bridgeconf.protocol .. "@msg@(.*)@(.*)@(.*)$", "%3")
		
		msg = bridge:Escape(msg, true)

		if uid == "" and sname ~= "" then
			--// Session Message
			local session = bridge:GetSession(sname)
			if session then
				session:Message(msg, true)
			else
				DC():PrintDebug("DEBUG#7001: No session found with the name " .. tostring(sname))
			end
		elseif uid ~= "" and sname == "" then
			--// Single User Message
			local user = bridge:GetUser(uid)
			if user then
				user:Message(msg, true)
			else
				DC():PrintDebug("DEBUG#7002: No user found with the uid " .. tostring(uid))
			end
		elseif uid ~= "" and sname ~= "" then
			--// Session Message to every participants except the one with the uid
			local session = bridge:GetSession(sname)
			if session then
				session:MessageUser(uid, msg, true, true)
			else
				DC():PrintDebug("DEBUG#7003: No session found with the name " .. tostring(sname))
			end
		else
			bridge:Broadcast(msg)
		end
	else
		DC():PrintDebug("Invalid \"msg\": " .. message)
		return false
	end
	return true
end

function bridge.ProcessGud(hub, appserver, message)
	if string.find(message, "^@" .. bridgeconf.protocol .. "@gud@.*@.*@.*$") then
		local uid = string.gsub(message, "^@" .. bridgeconf.protocol .. "@gud@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@gud@(.*)@(.*)@(.*)$", "%2")
		local varname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@gud@(.*)@(.*)@(.*)$", "%3")
		bridge.SendSud( appserver, uid, sname, varname )
	else
		DC():PrintDebug("Invalid \"gud\": " .. message)
		return false
	end
	return true
end

function bridge.ProcessSud(hub, message)
	local ret = false
	if string.find(message, "^@" .. bridgeconf.protocol .. "@sud@.*@.*@.*@.*$") then
		
		local uid = string.gsub(message, "^@" .. bridgeconf.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%1")
		local varname = string.gsub(message, "^@" .. bridgeconf.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%2")
		local value = string.gsub(message, "^@" .. bridgeconf.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%3")
		local msg = bridge:Escape(string.gsub(message, "^@" .. bridgeconf.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%4"), true)
		
		local user = bridge:GetUser(uid)
		if user then
			ret = true
			user:SetUd(varname, value)
			if msg ~= "" then
				user:Message(msg)
			end
		else
			DC():PrintDebug("DEBUG#7211: Couldn't find user with uid " .. tostring(uid))
		end
		
	else
		DC():PrintDebug("Invalid \"sud\": " .. message)
	end
	return ret
end

bridge.Broadcast = function(this, msg)
	local ret = false
	local mode = bridge:GetConfig("broadcast")
	if mode == "regs" then
		for url in pairs(bridgeconf.users) do
			for id in pairs(bridgeconf.users[url].users) do
				if bridgeconf.users[url].type == "adc" then
					local hub = dcpp:findHub(url)
					if hub then
						local sid = hub:getSidbyCid(id)
						if sid then
							local uid = bridge:GetUid(url, sid)
							local user = bridge:GetUser(uid)
							if user then
								ret = user:Message(msgmsg) or ret
							end
						end
					end
				else
					local uid = bridge:GetUid(url, id)
					local user = bridge:GetUser(uid)
					if user then
						ret = user:Message(msg) or ret
					end
				end
			end
		end
	elseif mode == "main" then
		for k,hub in pairs(dcpp:getHubs()) do
			if hub:getProtocol() == "adc" then
				hub:sendChat(msg)
			else
				hub:sendChat(DC():FromUtf8(msg))
			end
		end
	elseif mode ~= "off" then
		DC():PrintDebug("DEBUG#1111: Invalid config value for broadcast: " .. tostring(mode) )
	end
	return ret
end

bridge.ListSessions = function(this, user)
	local scount = 0
	local ucount = 0
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       Currently opened sessions                                                                 Bridge " .. bridgeconf.internal.version)
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	for sname, session in pairs(bridge:GetSessions()) do
		user:Message("       Session: \"" .. sname .. "\" with appserver \"" .. tostring(bridge.GetAsNick(session:GetASId()))  .. "\" running a(n) " .. session:GetAppName() )
		local subcount = 0
		for uid, sessionuser in pairs(session:GetUsers()) do
			ucount = ucount + 1
			subcount = subcount + 1
			user:Message("                  " .. tostring(subcount) .. ". " .. tostring(uid) .. ": " .. sessionuser:GetNick())
		end
		scount = scount + 1
	end
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       Total: " .. tostring(scount) .. " sessions, " .. tostring(ucount) .. " users")
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	return true
end

bridge.ListUsers = function(this, user)
	local uc = 0 --// User counter
	local hc = 0 --// Hub counter
	local comp = 0 --// offline compensation
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       Registered users                                                                                Bridge " .. bridgeconf.internal.version)
	user:Message("                  Last seen\t\t\tNick")
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	for url in pairs(bridgeconf.users) do
		hc = hc + 1
		user:Message("       Hub: \"" .. url .. "\":")
		local hub = dcpp:findHub( url )
		local hubtype = bridgeconf.users[url].type
		
		for id in pairs(bridgeconf.users[url].users) do
			local uid = false
			local lastseen = os.date("%y.%m.%d. %H:%M", bridgeconf.users[url].users[id].lastseen)
			
			if hub then
				if hubtype == "adc" then
					sid = hub:getSidbyCid( id )
					uid = bridge:GetUid(url, sid)
				else
					uid = bridge:GetUid(url, id)
				end
			end
			
			if uid then
				user:Message("                  online\t\t\t" .. bridgeconf.users[url].users[id].nick .. " [" .. uid .. "]")
			else
				user:Message("                  " .. lastseen .. "\t\t" .. bridgeconf.users[url].users[id].nick)
				comp = comp - 1
			end
			
			uc = uc + 1
		end
	end
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	user:Message("       Total: " .. tostring(uc) .. " (" .. tostring(uc + comp) .." online) registered users on " .. tostring(hc) .. " hubs")
	user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
end

--// STATISTICS FUNCTIONS //--

function bridge.GetStat(requested_url)
	local stat = {}
	stat.users = {}
	for url in pairs(bridgeconf.users) do
		local isitadc = (bridgeconf.users[url].type == "adc")
		if (not requested_url) or (requested_url == url) then
			for k in pairs(bridgeconf.users[url].users) do
				local tmp = {}
				tmp.nick = bridgeconf.users[url].users[k].nick
				tmp.credit = tonumber(bridgeconf.users[url].users[k].ud.credit)
				if isitadc then
					tmp.cid = k
				end
				tmp.url = url
				table.insert(stat.users, tmp)
			end
		end
	end

	-- Sorting table
	local n = #stat.users
	for i = 1, (n-1) do
		for j = (i+1), n do
			if stat.users[j].credit > stat.users[i].credit then
				stat.users[i], stat.users[j] = stat.users[j], stat.users[i]
			end
		end
	end
	return stat
end

--// cid or nick
function bridge.GetUserRank(id, url)
	local ret = false
	local stattable = bridge.GetStat()
	for k in ipairs(stattable.users) do
		if stattable.users[k].cid then
			if ((stattable.users[k].cid == id) and (stattable.users[k].url == url)) then
				ret = k
				break
			end
		else
			if ((stattable.users[k].nick == id) and (stattable.users[k].url == url)) then
				ret = k
				break
			end
		end
	end
	return ret
end

function bridge.GetUserStat(rid, rurl)
	local ret = false
	for url in pairs(bridgeconf.users) do
		if url == rurl then
			for id in pairs(bridgeconf.users[url].users) do
				if id == rid then
					ret = {}
					ret.rank = bridge.GetUserRank(id, url)
					ret.credit = tonumber(bridgeconf.users[url].users[id].ud.credit)
					ret.registered = bridgeconf.users[url].users[id].added
					ret.lastplayed = bridgeconf.users[url].users[id].lastplayed
					ret.lastnick = bridgeconf.users[url].users[id].nick
					ret.applications = {}
					ret.applications.total = bridgeconf.users[url].users[id].stat.totalnumberofsessions
					ret.applications.won = bridgeconf.users[url].users[id].stat.won
					ret.applications.drawn = bridgeconf.users[url].users[id].stat.drawn
					ret.applications.lost = bridgeconf.users[url].users[id].stat.lost
					ret.applications.time = bridgeconf.users[url].users[id].stat.totaltimeplayed
				end
			end
			break
		end
	end
	return ret
end

bridge.SendStat = function(this, user, counter, url)
	
	local n = 20
	if counter then
		if string.find(counter, "^[0-9]*$") then
			n = tonumber(counter)
		else
			user:Message("Az n paraméter csak pozitív egész szám lehet!")
		end
	end
	
	local stattable = bridge.GetStat(url)
	user:Message("       ----------------------------------------------------------------------------------------------------------------")
	if n == 0 then
		if url then
			user:Message("       Top list for " .. url)
			user:Message("       Rangsor, Puták\t\tNick")
		else
			user:Message("       Top list")
			user:Message("       Rangsor, Puták\t\tNick [Hub]")
		end
	else
		if url then
			user:Message("       Top " .. tostring(n) .. " users on " .. url)
			user:Message("       Rangsor, Puták\t\tNick")
		else
			user:Message("       Top " .. tostring(n) .. " users")
			user:Message("       Rangsor, Puták\t\tNick")
		end
	end
	
	user:Message("       ----------------------------------------------------------------------------------------------------------------")
	for k in ipairs(stattable.users) do
		if (n ~= 0) and (k > n) then
			break
		end
		if url then
			user:Message("       " .. tostring(k) .. ". " .. tostring(stattable.users[k].credit) .. "\t\t" .. stattable.users[k].nick)
		else
			user:Message("       " .. tostring(k) .. ". " .. tostring(stattable.users[k].credit) .. "\t\t" .. stattable.users[k].nick .. " [" .. stattable.users[k].url .. "]")
		end
	end
	user:Message("       ----------------------------------------------------------------------------------------------------------------")
	if url then
		user:Message("       Összesen " .. tostring(#stattable.users) .. " regisztrált felhasználó a(z) " .. url .. " hubon")
	else
		user:Message("       Összesen " .. tostring(#stattable.users) .. " regisztrált felhasználó")
	end
	user:Message("       ----------------------------------------------------------------------------------------------------------------")
	
end

bridge.SendUserStat = function(this, user, nick, url)
	if bridgeconf.users[url] then
		
		local isitadc = (bridgeconf.users[url].type == "adc")
		local statid = nick
		if isitadc then
			statid = bridge.GetCidforReg(nick, url)
		end

		local stattable = bridge.GetUserStat(statid, url)
		if stattable then
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
			user:Message("       User information                                                                     Bridge " .. bridgeconf.internal.version)
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
			user:Message("       Nick: " .. tostring(stattable.lastnick))
			user:Message("       Hub: " .. url)
			user:Message("       Rangsor: " .. tostring(stattable.rank))
			user:Message("       Puták: " .. tostring(stattable.credit))
			user:Message("       Regisztrálva: " .. os.date("%c", stattable.registered))
			user:Message("       Utolsó játék: " .. os.date("%c", stattable.lastplayed))
			user:Message("       Összes játékkal töltött idő: " .. bridge.FormatTime(stattable.applications.time))
			user:Message("       Nyert/Vesztett/Döntetlen játék: " .. stattable.applications.won .. "/" .. stattable.applications.lost .. "/" .. stattable.applications.drawn)
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
		else
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
			user:Message("                                                                                                     Bridge " .. bridgeconf.internal.version)
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
			local uid = bridge:GetUid(url, statid)
			if uid then
				local class = string.sub(uid, 1, 1)
				if class == "c" then
					user:Message("       Nem vagy regisztrálva. A regisztrációhoz legalább egy játékot le kell játszanod.")
				else
					user:Message("       User " .. nick .. " is not registered on " .. url)
				end
			else
				user:Message("       No user logged in with nick " .. tostring(nick) .. " on " .. tostring(url))
			end
			user:Message("       ----------------------------------------------------------------------------------------------------------------")
		end
	else --// if bridgeconf.users[url]
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("                                                                                                     Bridge " .. bridgeconf.internal.version)
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Nincs " .. tostring(url) .. " című hub vagy az adott hubon nincsenek regisztrált felhasználók.")
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
	end

end

function bridge.SendSessionInfo(user, sname)
	
	local session = bridge:GetSession(sname)
	if session then
		local spectators = 0
		local spectlist = session:GetSpectList()
		for k in pairs(spectlist) do
			spectators = spectators + 1
		end
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Session information for " .. sname .. "                                                  Bridge " .. bridgeconf.internal.version)
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Application name: " .. session:GetAppName())
		user:Message("       Spectators: " .. tostring(spectators))
		user:Message("       Users:")
		local users = session:GetUsers()
		local counter = 0
		for uid, sessionuser in pairs(users) do
			counter = counter + 1
			user:Message("       *  " .. sessionuser:GetNick() .. " [" .. sessionuser:GetUid() .. "] [" .. sessionuser:GetUrl() .. "]")
		end
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Total: " .. tostring(counter) .. " users in this session")
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
	else
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Session information                                                                Bridge " .. bridgeconf.internal.version)
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
		user:Message("       Session not found. Possible reasons: You are not participating in any session or provided a wrong command parameter.")
		user:Message("       ----------------------------------------------------------------------------------------------------------------")
	end
	
end

--// CONTROL FUNCTIONS //--

function bridge.ProcessCommand(user, message)
	
	local params = bridge:Tokenize(message)
	
	local uid = user:GetUid()
	local url = user:GetUrl()
	
	if (params[2]) and (params[1] == "-bridge" or params[1] == "-b") then
		
		local nick = user:GetNick()
		local class = string.sub(user:GetUid(), 1, 1)
		
		if class == "o" then
			-- op commands
			if params[2] == "msg" then
				if params[3] and (params[3] == "reg") then
					local msg = "<" .. nick .. "> [reg] " .. string.sub(message, string.len(params[1]) + string.len(params[2]) + string.len(params[3]) + 4)
					if bridge:Broadcast(msg) then
						user:Message("OK")
					else
						user:Message("Message couldn't sent. Probably there are no registered users online.")
					end
				elseif params[5] and (params[3] == "session" or params[3] == "s") then
					local msg = "<" .. nick .. "> [session] " .. string.sub(message, string.len(params[1]) + string.len(params[2]) + string.len(params[3]) + string.len(params[4]) + 5)
					local remotesession = bridge:GetSession(params[4])
					if remotesession then
						remotesession:Message(msg)
						user:Message("OK")
					else
						user:Message("Message coudldn't sent. No session with name " .. tostring(sname) .. " found.")
					end
				elseif params[5] and (params[3] == "user" or params[3] == "u") then
					local msg = "<" .. nick .. "> [user] " .. string.sub(message, string.len(params[1]) + string.len(params[2]) + string.len(params[3]) + string.len(params[4]) + 5)
					local remoteuser = bridge:GetUser(params[4])
					if remoteuser then
						remoteuser:Message(msg)
						user:Message("OK")
					else
						user:Message("Message coudldn't sent. No user with uid " .. tostring(uid) .. " found.")
					end
				else
					user:Message("Wrong or missing parameters. See \"-bridge help\" for details!")
				end
			elseif params[2] == "help" or params[2] == "h" or params[2] == "?" then
					bridge.SendHelp(user, class)
			elseif params[2] == "ls" then
				bridge:ListSessions(user)
			elseif params[2] == "lu" then
				bridge:ListUsers(user)
			elseif params[2] == "stat" or params[2] == "s" then
				bridge:SendStat(user, params[3], params[4])
			elseif params[2] == "info" or params[2] == "i" then
				if params[4] then
					bridge:SendUserStat(user, params[3], params[4])
				elseif params[3] then
					bridge:SendUserStat(user, params[3], url)
				else
					bridge:SendUserStat(user, nick, url)
				end
			elseif params[2] == "delreg" then
				if params[4] then
					local suc, err = bridge:DelReg(params[3], params[4])
					if suc then
						user:Message("OK, " .. params[3] .. " (" .. params[4] .. ") removed from registered users' list")
					else
						user:Message("Couldn't remove user: " .. err)
					end
				elseif params[3] then
					local suc, err = bridge:DelReg(params[3], url)
					if suc then
						user:Message("OK, " .. params[3] .. " (" .. url .. ") removed from registered users' list")
					else
						user:Message("Couldn't remove user: " .. err)
					end
				else
					user:Message("Usage: -bridge delreg [nick] [url]")
				end
			elseif params[2] == "appserver" or params[2] == "as" then
				if params[3] then
					if params[3] == "list" then
						bridge:SendASList(user)
					elseif params[3] == "rm" then
						if params[4] then
							local suc, err = bridge.RmAppServer(params[4])
							user:Message(err)
						else
							user:Message("Usage: -bridge appserver rm <nick>")
						end
					elseif params[3] == "add" then
						if params[4] then
							local suc, err = bridge.AddAppServer(params[4])
							user:Message(err)
						else
							user:Message("Usage: -bridge appserver add <nick>")
						end
					else
						user:Message("Usage: -bridge appserver <add/rm/list> [nick]")
					end
				else
					user:Message("Usage: -bridge appserver <add/rm/list> [nick]")
				end
			elseif params[2] == "getconfig" or params[2] == "gc" then
				bridge:SendConfig(user)
			elseif params[2] == "set" then
				if params[4] then
					local ret = bridge:SetConfig(params[3], params[4])
					if ret then
						user:Message("OK")
					else
						user:Message("Couldn't set config value. Probably non-existing variable. Enter \"-bridge getconfig\" to see current config.")
					end
				else
					user:Message("Usage: -bridge set <variable> <value>")
				end
			elseif params[2] == "sp" then
				if params[3] then
					if user:Spectate(params[3]) then
						user:Message("OK")
					else
						user:Message("Couldn't spectate session " .. tostring(params[3]) .. ".")
					end
				else
					user:Message("Usage: -bridge sp <sname>")
				end
			elseif params[2] == "usp" then
				if params[3] then
					if user:UnSpectate(params[3]) then
						user:Message("OK")
					else
						user:Message("No session with name " .. tostring(params[3]) .. " exists or you are not a spectator in that.")
					end
				else
					user:Message("Usage: -bridge usp <sname>")
				end
			else
				user:Message("Wrong parameters. See \"-bridge help\" for details!")
			end
		elseif class == "m" then
			-- moderator commands
			if params[2] == "help" or params[2] == "h" or params[2] == "?" then
					bridge.SendHelp(user, class)
			elseif params[2] == "stat" or params[2] == "s" then
				bridge:SendStat(user, params[3], params[4])
			elseif params[2] == "info" or params[2] == "i" then
				if params[4] then
					bridge:SendUserStat(user, params[3], params[4])
				elseif params[3] then
					bridge:SendUserStat(user, params[3], url)
				else
					bridge:SendUserStat(user, nick, url)
				end
			else
				user:Message("Wrong parameters. See \"-bridge help\" for details!")
			end
		elseif class == "c" then
			if params[2] == "help" or params[2] == "h" or params[2] == "?" then
					bridge.SendHelp(user, class)
			elseif params[2] == "stat" or params[2] == "s" then
				bridge:SendStat(user, params[3])
			elseif params[2] == "info" or params[2] == "i" then
				bridge:SendUserStat(user, nick, url)
			else
				user:Message("Wrong parameters. See \"-bridge help\" for details!")
			end
		end
	end
	if params[1] == "@" then
	
		local nick = user:GetNick()
		local session = user:GetSession()
		if session then
			if not session:MessageUser(uid, "<" .. nick .. "> " .. string.sub(message, 3), true) then
				user:Message("Az üzeneted elküldése sikertelen. Valószínűleg egyedül vagy ebben az alkalmazásban (lásd: \"@info\")")
			end
		else
			user:Message("Nem veszel részt egyetlen alkalmazásban sem, így az üzeneted elküldése nem lehetséges.")
		end
		
	elseif params[1] == "@info" then
		bridge.SendSessionInfo(user, user:GetSName())
	end
	return true
end

function bridge.SendHelp(user, class)
	if class == "o" then
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Help (o)                                                                                                           Bridge " .. bridgeconf.internal.version)
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       -bridge help                                                                                            Displays this help (h, ?)")
		user:Message("       -bridge ls                                                                                          Lists current sessions")
		user:Message("       -bridge lu                                                                                           Lists registered users")
		user:Message("       -bridge stat [n] [url]                                                                Shows ranks (n=0: full stat) (s)")
		user:Message("       -bridge info [nick] [url]                                                             Displays the user's statistics (i)")
		user:Message("       -bridge msg <session/user/reg> [params] <msg>                        Sends message to users")
		user:Message("       -bridge appserver <list/add/rm> [nick]                   Lists/removes/adds a new AppServer (as)")
		user:Message("       -bridge delreg [nick] [url]                         Removes a user from the registered users' list")
		user:Message("       -bridge getconfig                                                            Shows the current configuration (gc)")
		user:Message("       -bridge sp <sname>                                                                    Spectate session sname")
		user:Message("       -bridge usp  <sname>                                                   Stop spectating of session sname")
		user:Message("       -bridge set <variable> <value>                                                 Modifies a config variable")
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Session commands")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
		user:Message("       @ <text>                                                             Message to the current session")
		user:Message("       @info                                                                                          Get session info")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	elseif class == "m" then
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Help (m)                                                                                                           Bridge " .. bridgeconf.internal.version)
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       -bridge help                                                                               Displays this help (h, ?)")
		user:Message("       -bridge stat [n] [url]                                                  Shows ranks (n=0: full stat) (s)")
		user:Message("       -bridge info [nick] [url]                                               Displays the user's statistics (i)")
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Session commands")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
		user:Message("       @ <text>                                                             Message to the current session")
		user:Message("       @info                                                                                          Get session info")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	else
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Help (c)                                                                                                           Bridge " .. bridgeconf.internal.version)
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       -bridge help                                                                               Displays this help (h, ?)")
		user:Message("       -bridge stat [n]                                                                                       Shows ranks (s)")
		user:Message("       -bridge info                                                                               Displays your statistics (i)")
		user:Message("       -----------------------------------------------------------------------------------------------------------------------------------------")
		user:Message("       Session commands")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
		user:Message("       @ <text>                                                             Message to the current session")
		user:Message("       @info                                                                                          Get session info")
		user:Message("       ----------------------------------------------------------------------------------------------------------------------------")
	end
	
	return true
end


-- // Listeners //--

dcpp:setListener( "userMyInfo", "ase_bridge",
	function( hub, dcuser, myinfo )
		
		local url = hub:getUrl()
		local nick = DC():ToUtf8(dcuser:getNick())
		
		if not bridge:GetUid(url, nick) then
			bridge:UCreate( hub, dcuser)
		end
		
		if bridge.IsItAppServer(url, nick) then
			local astate = bridge.GetAppServerState(nick)
			if astate == "offline" then
				bridge.SendCse( dcuser, "" )
				local sessions = bridge:GetSessions(nick)
				for sname, session in pairs(sessions) do
					session:Destroy("Az AppServer újraindult, sajnos a futó alkalmazás leállításra került. A kellemetlenségért elnézéseteket kérjük.")
				end
				bridge.SetAppServerState(nick, "online")
				
			elseif astate == "idle" then
				bridge.SetAppServerState(nick, "online")
			end
			
		end
		return nil
	
	end
)

dcpp:setListener( "userInf", "ase_bridge",
	function( hub, dcuser, flags )
		
		local url = hub:getUrl()
		local cid = dcuser:getCid()
		local sid = dcuser:getSid()
		local nick = dcuser:getNick()
		
		if not bridge:GetUid(url, sid) then
			bridge:UCreate(hub, dcuser)
		end
		
		if flags["NI"] then
			local uid = bridge:GetUid(url, sid)
			local user = bridge:GetUser(uid)
			user:ChangeNick(nick)			
		end
		
		if flags["CT"] then
			local uid = bridge:GetUid(url, sid)
			local user = bridge:GetUser(uid)
			user:FixCT()
		end
		
		if bridge.IsItAppServer(url, cid) then
			
			local astate = bridge.GetAppServerState(cid)
			if astate == "offline" then
				
				bridge.SendCse( dcuser, "" )
				local sessions = bridge:GetSessions(cid)
				for sname, session in pairs(sessions) do
					session:Destroy("Az AppServer újraindult, sajnos a futó alkalmazás leállításra került. A kellemetlenségért elnézéseteket kérjük.")
				end
				bridge.SetAppServerState(cid, "online")
				
			elseif astate == "idle" then
				bridge.SetAppServerState(cid, "online")
			end
			
			if flags["NI"] then
				bridge.SetAppServerNick(cid, nick)
			end
			
		end
		
		return nil
	
	end
)

dcpp:setListener( "userQuit", "ase_bridge",
	function( hub, nick )
		
		local url = hub:getUrl()
		nick = DC():ToUtf8(nick)
		local uid = bridge:GetUid(url, nick)
		
		if uid then
			local user = bridge:GetUser(uid)
			
			if bridge.IsItAppServer(url, nick) then
				bridge.SetAppServerState(nick, "idle")
			end
		
			local sname = user:GetSName()
			if sname ~= "" then
				bridge.SendQui( uid, sname )
			end
			user:Destroy(true)
		else
			DC():PrintDebug("Couldn't get UID for " .. nick )
		end
		
		return nil
	
	end
)

dcpp:setListener( "adcUserQui", "ase_bridge",
	function( hub, sid )
		
		local url = hub:getUrl()
		local uid = bridge:GetUid(url, sid)
		
		if uid then
			local user = bridge:GetUser(uid)
			local cid = user:GetCid()
			
			if bridge.IsItAppServer(url, cid) then
				bridge.SetAppServerState(cid, "idle")
			end
			
			local sname = user:GetSName()
			if sname ~= "" then
				bridge.SendQui( uid, sname )
			end
			user:Destroy(true)
		else
			DC():PrintDebug("Couldn't get UID for " .. sid )
		end
		
		return nil
		
	end
)

dcpp:setListener( "raw", "ase_bridge",
	function( hub, line )
		
		if string.sub(line, 1, 7) == "$OpList" then
			bridge.FixOpList( hub, DC():ToUtf8(line) )
		end
		return nil
	
	end
)

dcpp:setListener("connected", "ase_bridge",
	function(hub)
		local url = hub:getUrl()

		-- make sure we have no users on the hub when we connect:
		-- this is requied because on reconnects, sometimes the ondisconnected listener fails to run
		
		local users = bridge:GetUsers(url)
		for uid, user in pairs(users) do
			local sname = user:GetSName()
			if sname ~= "" then
				bridge.SendQui( uid, sname )
			end
			user:Destroy(false)
		end
		
		--// Initializing _uid_resolver for this hub
		bridge._uid_resolver[url] = {}
		
		return nil
		
	end
)

dcpp:setListener("disconnected", "ase_bridge",
	function(hub)
		
		local url = hub:getUrl()
		if url == bridge:GetConfig("controlhub") then
			DC():PrintDebug("[bridge.lua] Disconnected from control hub. Please reconnect as soon as possible")
		end
		
		local users = bridge:GetUsers(url)
		for uid, user in pairs(users) do
			--// Don't save users this time
			local sname = user:GetSName()
			if sname ~= "" then
				bridge.SendQui( uid, sname )
			end
			user:Destroy(false)
		end
		
	end
)

dcpp:setListener("chat", "ase_bridge",
	function( hub, user, text )
		
		local nick = user:getNick()
		if user:isOp() and text == "-scripts" then
			hub:sendChat("bridge.lua " .. bridgeconf.internal.version .. "")
		end
		return nil
		
	end
)

dcpp:setListener("adcChat", "ase_bridge",
	function( hub, user, text, me_msg )
		
		if user:isOp() and text == "-scripts" then
			hub:sendChat("bridge.lua " .. bridgeconf.internal.version .. "")
		end
		return nil
		
	end
)

dcpp:setListener("pm", "ase_bridge",
	function( hub, dcuser, message )
		
		local dcnick = DC():ToUtf8(dcuser:getNick())
		message = DC():ToUtf8(message)
		
		if bridge.IsItAppServer(hub:getUrl(), dcnick) then
			bridge.ProcessAS(hub, dcuser, message)
		else
			
			local uid = bridge:GetUid(hub:getUrl(), dcnick)
			local user = bridge:GetUser(uid)
			local nick = user:GetNick()
			
			if string.sub(message, 1, 8) == "-bridge " or string.sub(message, 1, 3) == "-b " or string.sub(message, 1, 1) == "@" then
				bridge.ProcessCommand(user, message)
			else
				
				local sname = user:GetSName()
				local text = "@" .. bridgeconf.protocol .. "@msg@" .. uid .. "@" .. sname .. "@" .. bridge:Escape(nick) .. "@" .. bridge:Escape(message)
				
				if bridge.SendCommand("se", sname, text) then
					if sname ~= "" then
						--// Allow spectators to see the chat
						local session = bridge:GetSession(sname)
						if session then
							local spectlist = session:GetSpectList()
							for spectuid in pairs(spectlist) do
								local spectator = bridge:GetUser(spectuid)
								if spectator then
									spectator:Message("[" .. sname .. "] <- [" .. uid .. "]: <" .. nick .. "> " .. message)
								end
							end
						end
					end
				else
					if sname == "" then
						user:Message("Az üzeneted nem lett feldolgozva. Sajnos az összes AppServer offline van...")
					else
						user:Message("Az üzeneted nem lett feldolgozva, sajnos az alkalmazáshoz tartozó AppServer offline van...")
					end
				end
				
			end
			
		end
		return nil
		
	end
)

dcpp:setListener("adcPm", "ase_bridge",
	function( hub, dcuser, message, me_msg )
		
		local sid = dcuser:getSid()
		
		if bridge.IsItAppServer(hub:getUrl(), dcuser:getCid()) then
			bridge.ProcessAS(hub, dcuser, message)
		else
		
			local uid = bridge:GetUid(hub:getUrl(), sid)
			local user = bridge:GetUser(uid)
			local nick = user:GetNick()
		
			if string.sub(message, 1, 8) == "-bridge " or string.sub(message, 1, 3) == "-b " or string.sub(message, 1, 1) == "@" then
				bridge.ProcessCommand(user, message)
			else
			
				local uid = bridge:GetUid(hub:getUrl(), sid)
				local sname = user:GetSName()
				local text = "@" .. bridgeconf.protocol .. "@msg@" .. uid .. "@" .. sname .. "@" .. bridge:Escape(nick) .. "@" .. bridge:Escape(message)
				
				if bridge.SendCommand("se", sname, text) then
					if sname ~= "" then
						--// Allow spectators to see the chat
						local session = bridge:GetSession(sname)
						if session then
							local spectlist = session:GetSpectList()
							for spectuid in pairs(spectlist) do
								local spectator = bridge:GetUser(spectuid)
								if spectator then
									spectator:Message("[" .. sname .. "] <- [" .. uid .. "]: <" .. nick .. "> " .. message)
								end
							end
						end
					end
				else
					if sname == "" then
						user:Message("Az üzeneted nem lett feldolgozva. Sajnos az összes AppServer offline van...")
					else
						user:Message("Az üzeneted nem lett feldolgozva, sajnos az alkalmazáshoz tartozó AppServer offline van...")
					end
				end
				
			end
			
		end
		return nil
		
	end
)

dofile( DC():GetAppPath() .. "scripts\\libsimplepickle.lua" )
bridge:InitializeConfig()

DC():PrintDebug( "  ** Loaded bridge.lua " .. tostring(bridgeconf.internal.version) .. " **" )
