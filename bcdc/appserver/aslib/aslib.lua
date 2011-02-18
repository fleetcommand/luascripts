if not aslib then --// #ifndef
--// WELCOME AND LICENSE //--
--[[
     aslib.lua -- Version 0.2a
     aslib.lua -- AS library implementation for BCDC++ as an AppServer.
     aslib.lua -- Revision: 012/20080501

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
		013/20080501: Added: ontimer listener, new escapes
		012/20080501: Fixed: Request clearing sessions on restart and when a session can't send commands to the bridge; GetUd() modified
		011/20080425: Added: user object and its basic methods
		010/20080419: Fixed: gud/sud matches current AS documentation, fixed processing CSE
		009/20080417: Added missing escapes, fixed so now sessions will be destroyed automatically if there's no user in them
		008/20080410: Added: session:GetLastNick(uid); Fixed: IsComplete()/IsUserComplete(); fixed: session:Destroy()
		007/20080409: Fixed a possible CSE bug; Session activity info added
		006/20071214: Escaping @ added
		005/20071203: session:IsUserComplete() added
		004/20071203: session:UserCount()
		003/20071202: aslib:Broadcast() added
		002/20071202: "cre" command removed, "gud" "sud" added along with some public aslib: functions
		001/20071127: Initial release
]]

--// Initialize //--
aslib = {}
aslib._assessions = {}
aslib._listeners = {}
aslib._session_resolver = {}

ashelper = {}

asconfig = {}
asconfig.config = {}
asconfig.config.controlhub = "control.hub.com:1234"
asconfig.config.broadcast = "1"
asconfig.config.bridge = "Bridge"
asconfig.settingsfile = DC():GetAppPath() .. "scripts\\aslib.config.lua"
asconfig.internal = {}
asconfig.internal.protocol = "AS001"
asconfig.internal.status = ""
asconfig.internal.version = ""
asconfig.internal.timer = false

--// ASHELPER PRIVATE FUNCTIONS //--

ashelper.LoadSettings = function(this)
	local file = io.open( asconfig.settingsfile, "r" )
	if file then
		dofile( asconfig.settingsfile )
		file:close()
	end
end

ashelper.SaveSettings = function(this)
	pickle.store(asconfig.settingsfile, { asconfig = asconfig })
end

ashelper.ProcessCommand = function(this, hub, user, msg, me_msg)
	local params = aslib:Tokenize(msg)
	if params[1] == "-as" then
			if (params[2] == "help" or params[2] == "?" or params[2] == "h") then
				ashelper:SendHelp(user)
			elseif (params[2] == "getconfig" or params[2] == "gc") then
					ashelper:SendConfig(user)
			elseif (params[2] == "set") then
					if params[4] then
						if ashelper:SetConfig(params[3], params[4]) then
							user:sendPrivMsgFmt("OK")
						else
							user:sendPrivMsgFmt("Couldn't set config variable \"".. params[3] .. "\". Probably non-existing variable. Enter \"-as getconfig\" for available variables.")
						end
					else
						user:sendPrivMsgFmt("Usage: -as set <variable> <value>", true)
					end
			else
				user:sendPrivMsgFmt("Wrong parameters. Enter \"-as help\" for details.")
			end
	end
end

ashelper.SendHelp = function(this, user)
	local file, err = io.open(asconfig.helpfile,"r")
	if file then
		text = file:read("*l")
		repeat
			user:sendPrivMsgFmt( text, true )
			text = file:read("*l")
		until (text == nil)
		file:close()
	else
		user:sendPrivMsgFmt("[aslib] Can't open file: \"" .. asconfig.helpfile .. "\". Error: " .. err, true)
	end
end

ashelper.SendConfig = function(this, user)
	user:sendPrivMsgFmt("        --------------------------------------------------------------------------------------------------------", true)
	user:sendPrivMsgFmt("        Configuration                                                                  ASLib " .. asconfig.internal.version, true)
	user:sendPrivMsgFmt("        --------------------------------------------------------------------------------------------------------", true)
	for variable, value in pairs(asconfig.config) do
		user:sendPrivMsgFmt("        " .. variable .. "\t\t\t\t" .. tostring(value), true)
	end
	user:sendPrivMsgFmt("        --------------------------------------------------------------------------------------------------------", true)
end

--// ASHELPER PUBLIC FUNCTIONS //--

ashelper.InitializeConfig = function(this)
	this:LoadSettings()
	
	--// updates
	-- if not asconfig.config.broadcast then asconfig.config.broadcast = "1" end
	
	--// Values to reset on every load
	asconfig.settingsfile = DC():GetAppPath() .. "scripts\\aslib.config.lua"
	asconfig.helpfile = DC():GetAppPath() .. "scripts\\aslib.help.txt"
	asconfig.internal.version = "0.2a"
	asconfig.internal.status = "restart"
	asconfig.internal.timer = false
end

ashelper.GetConfig = function(this, variable)
	return asconfig.config[variable]
end

ashelper.SetConfig = function(this, variable, value)
	local ret = false
	if value then
		if asconfig.config[variable] then
			--// this ensures that we can only modify existing values and don't add anything by accident
			asconfig.config[variable] = value
			this:SaveSettings()
			ret = true
		end
	end
	return ret
end

ashelper.Escape = function(this, message, reverse)
	if reverse then
		message = string.gsub(message, "\\a", "@")
		message = string.gsub(message, "\\\\", "\\")
	else
		message = string.gsub(message, "\\", "\\\\")
		message = string.gsub(message, "@", "\\a")
	end
	return message
end

--// ASLIB PRIVATE FUNCTIONS //--

aslib.CmdToBridge = function(this, msg)
	local ret = false
	local hubaddr = ashelper:GetConfig("controlhub")
	local bridgenick = ashelper:GetConfig("bridge")
	local hub = false
	local bridge = false
	if (hubaddr and bridgenick) then
		for k,h in pairs(dcpp:getHubs()) do
			if h:getUrl() == hubaddr then
				hub = h
				break
			end
		end
		if hub then
			local tmp = hub:findUsers( bridgenick, nil )
			for k in pairs(tmp) do
				bridge = tmp[k]
			end
		else
			asconfig.internal.status = "offline"
			DC():PrintDebug("DEBUG#2101: You are not connected to control hub with url " .. hubaddr .. ". Cannot find Bridge.")
		end
		if bridge then
			if hub:getProtocol() == "nmdc" then
				msg = DC():FromUtf8(msg)
			end
			bridge:sendPrivMsgFmt(msg, true)
			ret = true
		else
			asconfig.internal.status = "offline"
			DC():PrintDebug("DEBUG#2102: There's no Bridge (with username " .. bridgenick .. ") on " .. hubaddr .. " online. Cannot send message.")
		end
	end
	return ret
end

aslib.SendAse = function(this, uid, sname, appname, msg)
	if not msg then msg = "" end
	local ret = false
	local command = "@" .. asconfig.internal.protocol .. "@ase@" .. uid .. "@" .. sname .. "@" .. appname .. "@" .. ashelper:Escape(msg)
	ret = this:CmdToBridge(command)
	if not ret then
		if sname ~= "" then
			local session = aslib:GetSession(sname)
			if session then
				session:SetStatus("offline")
			end
		end
	end
	return ret
end

aslib.SendCse = function(this, sname, msg)
	if not msg then msg = "" end
	local ret = false
	local command = "@" .. asconfig.internal.protocol .. "@cse@" .. sname .. "@" .. ashelper:Escape(msg)
	ret = this:CmdToBridge(command)
	if not ret then
		if sname ~= "" then
			local session = aslib:GetSession(sname)
			if session then
				session:SetStatus("offline")
			end
		end
	end
	return ret
end

aslib.SendMsg = function(this, uid, sname, msg)
	local ret = false
	local command = "@" .. asconfig.internal.protocol .. "@msg@" .. uid .. "@" .. sname .. "@" .. ashelper:Escape(msg)
	ret = this:CmdToBridge(command)
	if not ret then
		if sname ~= "" then
			local session = aslib:GetSession(sname)
			if session then
				session:SetStatus("offline")
			end
		end
	end
	return ret
end

aslib.SendGud = function(this, uid, sname, varname)
	local ret = false
	local command = "@" .. asconfig.internal.protocol .. "@gud@" .. uid .. "@" .. sname .. "@" .. varname
	ret = this:CmdToBridge(command)
	if not ret then
		if sname ~= "" then
			local session = aslib:GetSession(sname)
			if session then
				session:SetStatus("offline")
			end
		end
	end
	return ret
end

aslib.SendSud = function(this, uid, varname, value, msg)
	if not msg then msg = "" end
	local ret = false
	local command = "@" .. asconfig.internal.protocol .. "@sud@" .. uid .. "@" .. varname .. "@" .. ashelper:Escape(value) .. "@" .. ashelper:Escape(msg)
	ret = this:CmdToBridge(command)
	if not ret then
		if sname ~= "" then
			local session = aslib:GetSession(sname)
			if session then
				session:SetStatus("offline")
			end
		end
	end
	return ret
end

aslib.GetListeners = function(this, ltype, sname)
	local ret = {}
	if sname ~= "" then
		--// Trying to get application name
		if this._listeners[ltype] then
			local session = this:GetSession(sname)
			if session then
				local appname = session:GetAppName()
				if this._listeners[ltype][appname] then
					for listener in pairs(this._listeners[ltype][appname]) do
						ret[listener] = this._listeners[ltype][appname][listener]
					end
				end
			end
		end
	else
		if this._listeners[ltype] then
			for appname in pairs(this._listeners[ltype]) do
				for listener in pairs(this._listeners[ltype][appname]) do
						ret[listener] = this._listeners[ltype][appname][listener]
				end
			end
		end
	end
	return ret
end

aslib.ActualizeSessionActivity = function(this, uid, sname)
	local ret = false
	local session = this:GetSession(sname)
	if session then
		if session._users[session._user_resolver[uid]] then
			session._users[session._user_resolver[uid]]._info.lastactivity = os.time()
			ret = true
		end
	end
	return ret
end

--// ASLIB PUBLIC FUNCTIONS //--

aslib.Debug = function(this, msg)
	DC():PrintDebug("[aslib] " .. msg)
end

aslib.Message = function(this, uid, msg)
	local ret = false
	ret = aslib:SendMsg(uid, "", msg)
	return ret
end

aslib.Broadcast = function(this, msg)
	local ret = false
	if ashelper:GetConfig("broadcast") ~= "0" then
		ret = aslib:SendMsg("", "", msg)
	else
		return false
	end
	return ret
end

--// Returns nil, if fails
aslib.SCreate = function(this, sname, appname)

	--// If session doesn't exist
	if not this._assessions[sname] then
		
		--// attributes
		this._assessions[sname] = {}
		this._assessions[sname]._users = {}
		this._assessions[sname]._fields = {}
		this._assessions[sname]._user_resolver = {}
		this._assessions[sname]._info = {}
		this._assessions[sname]._info.sname = sname
		this._assessions[sname]._info.appname = appname
		this._assessions[sname]._info.status = "online"
		this._assessions[sname]._info.date = os.time()
		
		--// methods
		--// private methods
		
		this._assessions[sname].RemoveUser = function(this, uid)
			local ret = false
			if this._user_resolver[uid] then
				--// Removing user from the session
				table.remove(this._users, this._user_resolver[uid])
				this._user_resolver[uid] = nil
				aslib._session_resolver[uid] = nil
				--// Refreshing user resolver
				for i in pairs(this._users) do
					this._user_resolver[this._users[i]._info.uid] = i
				end
				ret = true
			end
			return ret
		end
		
		this._assessions[sname].GetStatus = function(this)
			return this._info.status
		end
		
		this._assessions[sname].SetStatus = function(this, status)
			this._info.status = status
		end
		
		--// public methods

		this._assessions[sname].SetField = function(this, field, value)
			this._fields[field] = value
			return true
		end
		
		this._assessions[sname].GetField = function(this, field)
			return this._fields[field]
		end
		
		this._assessions[sname].GetAppName = function(this)
			return this._info.appname
		end
		
		this._assessions[sname].GetSName = function(this)
			return this._info.sname
		end
		
		this._assessions[sname].UserCount = function(this)
			return #this._users
		end
		
		this._assessions[sname].GetLastNick = function(this, uid)
			local ret = false
			if this._user_resolver[uid] then
				ret = this._users[this._user_resolver[uid]]._info.nick
			end
			return ret
		end
		
		this._assessions[sname].GetUser = function(this, uid)
			local ret = false
			if this._user_resolver[uid] then
				ret = this._users[this._user_resolver[uid]]
			end
			return ret
		end
		
		this._assessions[sname].GetUsers = function(this)
			return this._users
		end
		
		this._assessions[sname].GetUd = function(this, uid, variable)
			local ret = false
			if this._user_resolver[uid] then
				if this._users[this._user_resolver[uid]]._ud[variable] then
					ret = this._users[this._user_resolver[uid]]._ud[variable].value
				end
			end
			return ret
		end
		
		this._assessions[sname].SetUd = function(this, uid, variable, value, incomplete)
			local ret = false
			if this._user_resolver[uid] then
				if not this._users[this._user_resolver[uid]]._ud[variable] then
					this._users[this._user_resolver[uid]]._ud[variable] = {}
				end
				this._users[this._user_resolver[uid]]._ud[variable].value = value
				if not incomplete then
					this._users[this._user_resolver[uid]]._ud[variable].incomplete = false
				else
					this._users[this._user_resolver[uid]]._ud[variable].incomplete = incomplete
				end
				ret = true
			end
			return ret
		end
		
		this._assessions[sname].IsComplete = function(this)
			local ret = false
			for i in pairs(this._users) do
				for var in pairs(this._users[i]._ud) do
					ret = ret or this._users[i]._ud[var].incomplete
				end
			end
			return (ret == false)
		end
		
		this._assessions[sname].IsUserComplete = function(this, uid)
			local ret = false
			if this._user_resolver[uid] then
				ret = true
				for var in pairs(this._users[this._user_resolver[uid]]._ud) do
					if this._users[this._user_resolver[uid]]._ud[var].incomplete then
						ret = false
					end
				end
			end
			return ret
		end
		
		this._assessions[sname].RequestUserData = function(this, uid, variable)
			local ret = false
			if this:SetUd(uid, variable, "", true) then
				ret = aslib:SendGud(uid, this:GetSName(), variable)
			end
			return ret
		end
		
		this._assessions[sname].SendUserData = function(this, uid, variable, msg)
			local ret = false
			local value = this:GetUd(uid, variable)
			if value then
				ret = aslib:SendSud(uid, variable, value, msg)
			else
				ret = aslib:SendSud(uid, variable, "", msg)
			end
			return ret
		end
		
		this._assessions[sname].JoinUser = function(this, uid, nick, msg)
			local sname = this:GetSName()
			local ret = aslib:SendAse(uid, sname, this:GetAppName(), msg)
			if ret then
				--// Properties
				local user = {}
				user._info = {}
				user._info.uid = uid
				user._info.nick = nick
				user._info.sname = sname
				user._info.lastactivity = os.time()
				user._fields = {}
				user._ud = {}
				
				--// Private methods
				
				-- none
				
				--// Public methods
				
				user.Drop = function(this, msg)
					return this:GetSession():DropUser(this:GetUid(), msg)
				end
				
				user.GetUid = function(this)
					return this._info.uid
				end
				
				user.GetSName = function(this)
					return this._info.sname
				end
				
				user.GetSession = function(this)
					return aslib._assessions[this._info.sname]
				end
				
				user.Message = function(this, msg)
					return aslib:SendMsg(this:GetUid(), "", msg)
				end
				
				user.SetField = function(this, field, value)
					this._fields[field] = value
					return true
				end
				
				user.GetField = function(this, field)
					return this._fields[field]
				end
				
				user.GetNick = function(this)
					return this._info.nick
				end
				
				--// Insert user and updating resolvers
				table.insert(this._users, user)
				this._user_resolver[uid] = #this._users
				aslib._session_resolver[uid] = this:GetSName()
			end
			return ret
		end
		
		this._assessions[sname].GetActivity = function(this, uid)
			if this._user_resolver[uid] then
				return this._users[this._user_resolver[uid]]._info.lastactivity
			end
		end
		
		this._assessions[sname].ActualizeActivity = function(this, uid)
			local ret = false
			if this._user_resolver[uid] then
				this._users[this._user_resolver[uid]]._info.lastactivity = os.time()
				ret = true
			end
			return ret
		end
		
		--// Return true if session has any user left, false if session is destroyed
		this._assessions[sname].DropUser = function(this, uid, msg)
			local ret = true
			if aslib:SendAse(uid, "", "", msg) then
				this:RemoveUser(uid)
				if this:UserCount() == 0 then
					local sname = this:GetSName()
					DC():PrintDebug("DEBUG#3102: Session " .. tostring(sname) .. " is empty, removing")
					aslib._assessions[sname] = nil
					ret = false
				end
			end
			return ret
		end
		
		this._assessions[sname].Message = function(this, msg)
			local ret = aslib:SendMsg("", this:GetSName(), msg)
			return ret
		end
		
		this._assessions[sname].MessageUser = function(this, uid, msg, allbuthim)
			local ret = false
			if allbuthim then
				aslib:SendMsg(uid, this:GetSName(), msg)
			else
				aslib:SendMsg(uid, "", msg)
			end
			return ret
		end
		
		this._assessions[sname].Destroy = function(this, msg)
			local sname = this:GetSName()
			if not msg then msg = "" end	
			if aslib:SendCse(sname, msg) then
				aslib._assessions[sname] = nil
			end
		end

	else
		DC():PrintDebug("DEBUG#2001: Trying to add an existing session: " .. tostring(sname) .. " for application " .. tostring(appname) )
	end
	return this._assessions[sname]
end

aslib.GetSession = function(this, sname)
	return this._assessions[sname]
end

aslib.GetSessions = function(this, appname)
	local ret = {}
	for sname in pairs(this._assessions) do
		if appname then
			if (this._assessions[sname]._info.appname == appname) then
				ret[sname] = this._assessions[sname]
			end
		else
			ret[sname] = this._assessions[sname]
		end
	end
	return ret
end

aslib.GetSessionForUid = function(this, uid)
	local ret = false
	if this._session_resolver[uid] then
		ret = this:GetSession(this._session_resolver[uid])
	end
	return ret
end

aslib.SetListener = function(this, ltype, appname, id, func)
	if not this._listeners[ltype] then
		this._listeners[ltype] = {}
	end
	if ltype == "ontimer" then
		aslib.timer = true
	end
	if not this._listeners[ltype][appname] then
		this._listeners[ltype][appname] = {}
	end
	this._listeners[ltype][appname][id] = func
end

aslib.ProcessCse = function(this, msg)
	local ret = false
	if string.find(msg, "^@" .. asconfig.internal.protocol .. "@cse@.*$") then
		local sname = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@cse@(.*)$", "%1")
		DC():PrintDebug("DEBUG#2398: CSE received, destroying session...")
		if sname == "" then
			local sessions = aslib:GetSessions()
			for sname in pairs(sessions) do
				DC():PrintDebug("... " .. tostring(sname) )
				aslib._assessions[sname] = nil
			end
			ret = true
		else
			local session = aslib:GetSession(sname)
			if session then
				DC():PrintDebug("... " .. tostring(sname) )
				aslib._assessions[sname] = nil
				ret = true
			else
				DC():PrintDebug("DEBUG#2401: Couldn't find session \"" .. sname .. "\"")
			end
		end
	else
		DC():PrintDebug("Invalid cse: " .. msg)
	end
	return ret
end

aslib.ProcessMsg = function(this, msg)
	--// TODO: when receiving an msg, the last nick of the user should be updated otherwise GetLastNick() won't work as expected
	local ret = false
	if string.find(msg, "^@" .. asconfig.internal.protocol .. "@msg@.*@.*@.*@.*$") then
		
		local uid = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@msg@(.*)@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@msg@(.*)@(.*)@(.*)@(.*)$", "%2")
		local nick = ashelper:Escape(string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@msg@(.*)@(.*)@(.*)@(.*)$", "%3"), true)
		local message = ashelper:Escape(string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@msg@(.*)@(.*)@(.*)@(.*)$", "%4"), true)
		
		if (sname == "") then
			--// Calling all onmessage listener
			for k,f in pairs(aslib:GetListeners("onmessage", "")) do
				f(uid, nick, message)
			end
		else
			local session = aslib:GetSession(sname)
			if session then
				--// Actualizing session activity
				if aslib:ActualizeSessionActivity(uid, sname) then
					--// Calling listeners for that session
					local user = session:GetUser(uid)
					if user then
						for k,f in pairs(aslib:GetListeners("onsessionmessage", sname)) do
							f(user, session, nick, message)
						end
					end
				else
					DC():PrintDebug("DEBUG#2402: Couldn't actualize session activity for user with nick \"" .. tostring(nick) .. "\" and uid \"" .. tostring(uid) .. "\"")
				end
			else
				DC():PrintDebug("DEBUG#4326: There's no session with sname " .. tostring(sname) .. "! Probably Bridge is out of sync!")
			end
		end

	else
		DC():PrintDebug("Invalid msg: " .. msg)
	end
	return ret
end

aslib.ProcessQui = function(this, msg)
	local ret = false
	if string.find(msg, "^@" .. asconfig.internal.protocol .. "@qui@.*@.*@.*$") then
		local uid = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@qui@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@qui@(.*)@(.*)@(.*)$", "%2")
		local nick = ashelper:Escape(string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@qui@(.*)@(.*)@(.*)$", "%3"), true)
		local session = aslib:GetSession(sname)
		if session then
			if session:RemoveUser(uid) then
				for k,f in pairs(aslib:GetListeners("onquit", sname)) do
					f(uid, sname, nick)
				end
				if session:UserCount() == 0 then
					DC():PrintDebug("DEBUG#3103: Session " .. tostring(sname) .. " is empty, removing")
					aslib._assessions[sname] = nil
				end
			end
			
		else
			DC():PrintDebug("DEBUG#2501: Couldn't find session " .. sname )
		end
	else
		DC():PrintDebug("Invalid qui: " .. msg)
	end
	return ret
end

aslib.ProcessSud = function(this, msg)
	local ret = false
	if string.find(msg, "^@" .. asconfig.internal.protocol .. "@sud@.*@.*@.*@.*$") then
		local uid = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%1")
		local sname = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%2")
		local variable = string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%3")
		local value = ashelper:Escape(string.gsub(msg, "^@" .. asconfig.internal.protocol .. "@sud@(.*)@(.*)@(.*)@(.*)$", "%4"), true)
		--// However the protocol does not expect sname to be present, but this appserver sends sname in the gud,
		--// and the protocol requires the Bridge to send back the original sname, so sname can't be empty string here.
		local session = this:GetSession(sname)
		if session then
			local user = session:GetUser(uid)
			if user then
				ret = true
				session:SetUd(uid, variable, value, false)
				for k,f in pairs(aslib:GetListeners("onuserdata", sname)) do
					f(user, session, variable, value)
				end
			else
				DC():PrintDebug("Cannot process sud, user " .. uid .. " not participating in session " .. sname)
			end
		else
			DC():PrintDebug("Cannot process sud, no session with name " .. sname .. " exists")
		end
	else
		DC():PrintDebug("Invalid sud: " .. msg)
	end
	return ret
end

aslib.ProcessCommand = function(this, msg)
	local ret = false
	if (string.len(msg) < 11) then
		-- invalid command,
		-- @AS001@...@ is at least 11 characters long
		DC():PrintDebug("Invalid command from Bridge: \"" .. msg .. "\"")
		return false
	end
	
	DC():PrintDebug(msg )
	
	if (string.sub(msg, 1, 7) ~= "@" .. asconfig.internal.protocol .. "@") then
			DC():PrintDebug("Incompatible protocol: " .. proto )
			return false
	end
	if string.find(msg, "^@" .. asconfig.internal.protocol .. "@...@") then
		local command = string.sub(msg, 8, 10)
		if command == "msg" then
			ret = this:ProcessMsg(msg)
		elseif command == "qui" then
			ret = this:ProcessQui(msg)
		elseif command == "cse" then
			ret = this:ProcessCse(msg)
		elseif command == "sud" then
			ret = this:ProcessSud(msg)
		else
			DC():PrintDebug("Invalid command: " .. command )
		end
	end
	return ret
end

aslib.Tokenize = function(this, text)
	local ret = {}
	string.gsub(text, "([^ ]+)", function(s) table.insert(ret, s) end )
	return ret
end

--// Processing incoming commands //--

dcpp:setListener( "pm", "aslibnmdcpm",
	function( hub, user, msg )
		msg = DC():ToUtf8(msg)
		if (hub:getUrl() == ashelper:GetConfig("controlhub") and user:getNick() == DC():FromUtf8(ashelper:GetConfig("bridge"))) then
			aslib:ProcessCommand(msg)
		elseif user:isOp() then
			ashelper:ProcessCommand(hub, user, msg, false)
		end
		return nil
	end
)

dcpp:setListener( "adcPm", "aslibadcpm",
	function( hub, user, msg, me_msg)
		if (hub:getUrl() == ashelper:GetConfig("controlhub") and user:getNick() == ashelper:GetConfig("bridge")) then
			aslib:ProcessCommand(msg)
		elseif user:isOp() then
			ashelper:ProcessCommand(hub, user, msg, me_msg)
		end
		return nil
	end
)

dcpp:setListener( "userMyInfo", "aslibnmdcmyinfo",
	function( hub, user, myinfo )
		
		if (hub:getUrl() == ashelper:GetConfig("controlhub")) then
			if user:getNick() == DC():FromUtf8(ashelper:GetConfig("bridge")) then
				if asconfig.internal.status == "offline" then
					for sname, session in pairs(aslib:GetSessions()) do
						if session:GetStatus() == "offline" then
							session:Destroy("Sajnos megszakadt a kapcsolat a játék-kiszolgáló és a hub között, így az alkalmazást újra kellett indítanunk. A kellemetlenségért elnézéseteket kérjük.")
						end
					end
					asconfig.internal.status = "online"
				elseif asconfig.internal.status == "restart" then
					aslib:SendCse("", "Sajnos az alkalmazás-kiszolgálót újra kellett indítanunk. A kellemetlenségért elnézéseteket kérjük.")
					asconfig.internal.status = "online"
				end
			end
		end
		return nil
	end
)

dcpp:setListener( "userInf", "aslibadcinf",
	function( hub, user, flags )
		
		if (hub:getUrl() == ashelper:GetConfig("controlhub")) then
			if user:getNick() == ashelper:GetConfig("bridge") then
				if asconfig.internal.status == "offline" then
					for sname, session in pairs(aslib:GetSessions()) do
						if session:GetStatus() == "offline" then
							session:Destroy("Sajnos megszakadt a kapcsolat a játék-kiszolgáló és a hub között, így az alkalmazást újra kellett indítanunk. A kellemetlenségért elnézéseteket kérjük.")
						end
					end
					asconfig.internal.status = "online"
				elseif asconfig.internal.status == "restart" then
					aslib:SendCse("", "Sajnos az alkalmazás-kiszolgálót újra kellett indítanunk. A kellemetlenségért elnézéseteket kérjük.")
					asconfig.internal.status = "online"
				end
			end
		end
		return nil
	end
)

dcpp:setListener( "timer", "aslibtimer",
	function()
		if asconfig.internal.timer then
			for k,f in pairs(aslib:GetListeners("ontimer", "")) do
				f()
			end
		end
	end
)

--// Entry point //--

dofile( DC():GetAppPath() .. "scripts\\libsimplepickle.lua" )
ashelper:InitializeConfig()
DC():RunTimer(1)
aslib:Debug("AS Library " .. asconfig.internal.version .. " loaded")

end --// #endif