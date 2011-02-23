--[=[

	PxSettings 1.0e LUA 5.1x [Strict] [API 2]

	By Mutor		03/29/08

	Get or Set all [153] SetMan Boolean, Number and String settings
	This may be helpful for use with the new PtokaX service and or remote hubs.

	- Provides context menu [right click]
	- Command permission per profile

	+Changes from 1.0	04/11/08
		+Added setup command/menu to run through *all boolean or number or string settings
			*You may stop at any point, all changes up to that point will be saved.
			*Don't not skip a setting and continue or changes after will be offset by
			the number of skipped sttings.

	+Changes from 1.0b	04/12/08
		+Added settings *backup function. Should backup fail, script will be stopped.
			*Settings will be backed up to "PtokaX/cfg/Settings.bak"

	+Changes from 1.0c	07/24/08
		+Added 48 integer, 2 boolean settings [new calls]
		+Added segmented menus for easier viewing, no menu shall be more than 25 items.
		~Changed backup function, backup file created only if non-existing.

	+Changes from 1.0d	02/15/09
		+Added commands/menus for setting profile permissions and Profiles.xml backup
		+Added 'list' commands/menu
		+Added option to enable commands per profile bit permision

		**Props and thanks to sphinx for testing for me.
]=]

-- "Botname" ["" = hub bot]
local Bot = SetMan.GetString(21)
local Menu = "Settings Manager"
local SubMenu = ""
-- Set your profiles / permissions here.
-- [#] = true/false, (true = Command(s) Enabled / false = Command(s) Disabled)
local Profiles = {
	[-1] = false,	-- Unregistered User
	[0] = true,	-- Master
	[1] = false,	-- Operator
	[2] = false,	-- Vip
	[3] = false,	-- Reg
	}
-- Rebuild Profiles table by profile bit permission. permission number / false [false = disabled]
local UsePermission = 24
local Cfg = {}
local Setup = {["Boolean"]={},["Integer"]={},["String"]={}}

local Booleans = {
	[0] = "Anti MoGlo description",
	[1] = "Hub autostart",
	[2] = "Redirect all connecting users",
	[3] = "Redirect users when hub is full",
	[4] = "Automatically register to hublist",
	[5] = "Hub for registered users only",
	[6] = "Redirect non-registered users when hub is for registered users only",
	[7] = "Redirect user when he's don't have share limit",
	[8] = "Redirect user when he's don't have slot limit",
	[9] = "Redirect user when he's don't have hub/slot ratio limit",
	[10] = "Redirect user when he's don't have max hubs limit",
	[11] = "Add user mode to MyINFO command.",
	[12] = "Add user mode to description.",
	[13] = "Strip user description.",
	[14] = "Strip user description tag.",
	[15] = "Strip user connection.",
	[16] = "Strip user email",
	[17] = "Register hub bot on hub.",
	[18] = "Use hub bot nick instead of Hub-Security.",
	[19] = "Register Opchat bot on hub.",
	[20] = "Redirect user when is temp banned.",
	[21] = "Redirect user when is perm banned.",
	[22] = "Enable scripting interface.",
	[23] = "Keep slow clients.",
	[24] = "Automatically check for new PtokaX releases on startup",
	[25] = "Enable tray icon.",
	[26] = "Start minimized.",
	[27] = "Filter kick messages.",
	[28] = "Send kick messages to OPs.",
	[29] = "Send status messages to OPs.",
	[30] = "Send status messages as private messages.",
	[31] = "Enable text files.",
	[32] = "Send text files as private messages.",
	[33] = "Stop script on error.",
	[34] = "Send MOTD as private message.",
	[35] = "Report deflood actions.",
	[36] = "Reply to hub commands with private messages.",
	[37] = "Disable MOTD.",
	[38] = "Don't allow hublist pingers.",
	[39] = "Report hublist pingers.",
	[40] = "Report 3x bad password.",
	[41] = "Advanced password protection.",
	[42] = "Listen only on single IP.",
	[43] = "Resolve hostname to IP.",
	[44] = "Redir user when he's don't have nick in length limits.",
	[45] = "Send UserIP to user on login.",
	[46] = "Send ip in ban message.",
	[47] = "Send range in ban message.",
	[48] = "Send nick in ban message.",
	[49] = "Send reason in ban message.",
	[50] = "Send who create ban in ban message.",
	[51] = "Report suspicious tag to OPs.",
	[52] = "Accept tag from unknown clients.",
	[53] = "Check IP in commands.",
	[54] = "Popup scripts window on script error.",
	[55] = "Save script errors to log.",
}

local Numbers = {
	[0] = "Max users limit",
	[1] = "Min share limit. Max 9999.",
	[2] = "Min share units. 0 = B, 1 = kB, 2 = MB, 3 = GB, 4 = TB. Max 4.",
	[3] = "Max share limit. Max 9999.",
	[4] = "Max share units. 0 = B, 1 = kB, 2 = MB, 3 = GB, 4 = TB. Max 4.",
	[5] = "Min slots limit.",
	[6] = "Max slots limit.",
	[7] = "Hubs for hub/slot ratio.",
	[8] = "Slots for hub/slot ratio.",
	[9] = "Max hubs limit.",
	[10] = "No tag option. 0 = accept, 1 = reject, 2 = redirect. Max 2.",
	[11] = "Send full MyINFO to... 0 = to all, 1 = to profile, 2 = to none. Max 2.",
	[12] = "Max chat length limit.",
	[13] = "Max chat lines limit.",
	[14] = "Max private message length limit.",
	[15] = "Max private message lines limit.",
	[16] = "Default tempban time. Must be higher than 0.",
	[17] = "Max passive search replys limit.",
	[18] = "Time before new MyINFO from user is accepted for broadcast.",
	[19] = "Main chat deflood messages count. Higher than 0, max 999.",
	[20] = "Main chat deflood time. Higher than 0, max 999.",
	[21] = "Main chat deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[22] = "Same main chat deflood messages count. Higher than 0, max 999.",
	[23] = "Same main chat deflood time. Higher than 0, max 999.",
	[24] = "Same main chat deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[25] = "Same multiline main chat deflood messages count. Min 2, max 999.",
	[26] = "Same multiline main chat deflood lines. Min 2, max 999.",
	[27] = "Same multiline main chat deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[28] = "Private message deflood messages count. Higher than 0, max 999.",
	[29] = "Private message deflood time. Higher than 0, max 999.",
	[30] = "Private message deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[31] = "Same private message deflood messages count. Higher than 0, max 999.",
	[32] = "Same private message deflood time. Higher than 0, max 999.",
	[33] = "Same private message deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[34] = "Same multiline private message deflood messages count. Min 2, max 999.",
	[35] = "Same multiline private message deflood lines. Min 2, max 999.",
	[36] = "Same multiline private message action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[37] = "Search deflood messages count. Higher than 0, max 999.",
	[38] = "Search deflood time. Higher than 0, max 999.",
	[39] = "Search deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[40] = "Same search deflood messages count. Higher than 0, max 999.",
	[41] = "Same search deflood time. Higher than 0, max 999.",
	[42] = "Same search deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[43] = "MyINFO deflood messages count. Higher than 0, max 999.",
	[44] = "MyINFO deflood time. Higher than 0, max 999.",
	[45] = "MyINFO deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[46] = "GetNickList deflood messages count. Higher than 0, max 999.",
	[47] = "GetNickList deflood time. Higher than 0, max 999.",
	[48] = "GetNickList deflood action. 0 = disabled, 1 = ignore, 2 = warn, 3 = disconnect, 4 = kick, 5 = tempban, 6 = permban. Max 6.",
	[49] = "Connection deflood connecions count. Higher than 0, max 999.",
	[50] = "Connection deflood time. Higher than 0, max 999.",
	[51] = "Deflood warnings count. Higher than 0, max 999.",
	[52] = "Deflood warnings action. 0 = disconnect, 1 = kick, 2 = tempban, 3 = permban. Max 3.",
	[53] = "Deflood tempban time. Higher than 0.",
	[54] = "Global main chat messages count. Higher than 0, max 999.",
	[55] = "Global main chat time. Higher than 0, max 999.",
	[56] = "Global main chat timeout. Higher than 0, max 999.",
	[57] = "Global main chat action. 0 = disabled, 1 = lock chat, 2 = send to ops with ips. Max 2.",
	[58] = "Min search length.",
	[59] = "Max search length.",
	[60] = "Min nick length. Max 64.",
	[61] = "Max nick length. Max 64.",
	[62] = "Brute force password protection ban type. 0 = disabled, 1 = permban, 2 = tempban. Max 2.",
	[63] = "Brute force password protection temp ban time. Higher than 0.",
	[64] = "Max pm count to same user per minute.",
	[65] = "Max simultaneous logins. Higher than 0, max 500.",
	[66] = "Secondary main chat deflood messages count. Higher than 0, max 29999.",
	[67] = "Secondary main chat deflood time. Higher than 0, max 29999.",
	[68] = "Secondary main chat deflood action. 0 = disabled.",
	[69] = "Secondary private message deflood messages count. Higher than 0, max 29999.",
	[70] = "Secondary private message deflood time. Higher than 0, max 29999.",
	[71] = "Secondary private message deflood action. 0 = disabled.",
	[72] = "Secondary search deflood messages count. Higher than 0, max 29999.",
	[73] = "Secondary search deflood time. Higher than 0, max 29999.",
	[74] = "Secondary search deflood action. 0 = disabled.",
	[75] = "Secondary myINFO deflood messages count. Higher than 0, max 29999.",
	[76] = "Secondary myINFO deflood time. Higher than 0, max 29999.",
	[77] = "Secondary myINFO deflood action. 0 = disabled.",
	[78] = "Maximum MyINFO length. Min 64, max 512.",
	[79] = "Primary ConnectToMe deflood count. Higher than 0, max 29999.",
	[80] = "Primary ConnectToMe deflood time. Higher than 0, max 29999.",
	[81] = "Primary ConnectToMe deflood action. 0 = disabled.",
	[82] = "Secondary ConnectToMe deflood count. Higher than 0, max 29999.",
	[83] = "Secondary ConnectToMe deflood time. Higher than 0, max 29999.",
	[84] = "Secondary ConnectToMe deflood action. 0 = disabled.",
	[85] = "Primary RevConnectToMe deflood count. Higher than 0, max 29999.",
	[86] = "Primary RevConnectToMe deflood time. Higher than 0, max 29999.",
	[87] = "Primary RevConnectToMe deflood action. 0 = disabled.",
	[88] = "Secondary RevConnectToMe deflood count. Higher than 0, max 29999.",
	[89] = "Secondary RevConnectToMe deflood time. Higher than 0, max 29999.",
	[90] = "Secondary RevConnectToMe deflood action. 0 = disabled.",
	[91] = "Maximum ConnectToMe length. Higher than 0, max 512.",
	[92] = "Maximum RevConnectToMe length. Higher than 0, max 512.",
	[93] = "Primary SR deflood count. Higher than 0, max 29999.",
	[94] = "Primary SR deflood time. Higher than 0, max 29999.",
	[95] = "Primary SR deflood action. 0 = disabled.",
	[96] = "Secondary SR deflood count. Higher than 0, max 29999.",
	[97] = "Secondary SR deflood time. Higher than 0, max 29999.",
	[98] = "Secondary SR deflood action. 0 = disabled.",
	[99] = "Maximum SR length. Higher than 0, max 8192.",
	[100] = "Primary received data deflood action. 0 = disabled.",
	[101] = "Primary received data deflood kB. Higher than 0, max 29999.",
	[102] = "Primary received data deflood time. Higher than 0, max 29999.",
	[103] = "Secondary received data deflood action. 0 = disabled.",
	[104] = "Secondary received data deflood kB. Higher than 0, max 29999.",
	[105] = "Secondary received data deflood time. Higher than 0, max 29999.",
	[106] = "Chat messages interval messages. Higher than 0, max 29999.",
	[107] = "Chat messages interval time. Higher than 0, max 29999.",
	[108] = "Private messages interval messages. Higher than 0, max 29999.",
	[109] = "Private messages interval time. Higher than 0, max 29999.",
	[110] = "Search interval count. Higher than 0, max 29999.",
	[111] = "Search interval time. Higher than 0, max 29999.",
	[112] = "Maximum users from same IP. Higher than 0, max 256.",
	[113] = "Minimum reconnect time in seconds. Higher than 0, max 256.",
}

local Strings = {
	[0] = "Hub name. Min length 1, max 256.",
	[1] = "Admin nick. Min length 1, max 64, $ is not allowed.",
	[2] = "Hub address. Min length 1, max 256.",
	[3] = "TCP ports. Min length 1, max 64.",
	[4] = "UDP port. Min length 1, max 5.",
	[5] = "Hub description. Max length 256.",
	[6] = "Main redirect address. Max length 256.",
	[7] = "Hublist register servers. Max length 1024.",
	[8] = "Registered users only message. Min length 1, max 256.",
	[9] = "Registered users only redirect address. Max length 256.",
	[10] = "Hub topic. Max length 256.",
	[11] = "Share limit message. Min length 1, max 256. Use %[min] for min share size and %[max] for max share size.",
	[12] = "Share limit redirect address. Max length 256.",
	[13] = "Slot limit message. Min length 1, max 256. Use %[min] for min slots and %[max] for max slots.",
	[14] = "Slot limit redirect address. Max length 256.",
	[15] = "Hub/slot ratio limit message. Min length 1, max 256. Use %[hubs] for hubs and %[slots] for slots.",
	[16] = "Hub/slot ratio limit redirect address. Max length 256.",
	[17] = "Max hubs limit message. Min length 1, max 256. Use %[hubs] for max hubs.",
	[18] = "Max hubs limit redirect address. Max length 256.",
	[19] = "No tag rule message. Min length 1, max 256.",
	[20] = "No tag rule redirect address. Max length 256.",
	[21] = "Hub bot nick. Min length 1, max 64, $ and space is not allowed.",
	[22] = "Hub bot description. Max length 64, $ is not allowed.",
	[23] = "Hub bot email. Max length 64, $ is not allowed.",
	[24] = "OpChat bot nick. Min length 1, max 64, $ and space is not allowed.",
	[25] = "OpChat bot description. Max length 64, $ is not allowed.",
	[26] = "OpChat bot email. Max length 64, $ is not allowed.",
	[27] = "Temp ban redirect address. Max length 256.",
	[28] = "Perm ban redirect address. Max length 256.",
	[29] = "Chat commands prefixes. Min length 1, max 5.",
	[30] = "Hub owner email. Max length 64.",
	[31] = "Nick limit message. Min length 1, max 256. Use %[min] for min length and %[max] for max length.",
	[32] = "Nick limit redirect address. Max length 256.",
	[33] = "Additional message to ban message. Max lenght 256.",
	[34] = "Language. When language is default then return nil."
}

Permissions ={
	[0] = "User have key / is OP",
	[1] = "No GetNickList Deflood",
	[2] = "No MyINFO Deflood",
	[3] = "No Search Deflood",
	[4] = "No PM Deflood",
	[5] = "No Main Chat Deflood",
	[6] = "Mass Message",
	[7] = "Topic",
	[8] = "TempBan",
	[9] = "Reload text files",
	[10] = "No Tag check",
	[11] = "TempUnban",
	[12] = "DelRegUser",
	[13] = "AddRegUser",
	[14] = "No ChatLimits",
	[15] = "No MaxHubs Check",
	[16] = "No Slot/Hub ratio Check",
	[17] = "No SlotCheck",
	[18] = "No ShareLimit check",
	[19] = "Clear PermBan",
	[20] = "Clear TempBan",
	[21] = "GetInfo",
	[22] = "Get Bans",
	[23] = "Start/Stop/Restart script(s)",
	[24] = "Restart hub",
	[25] = "TempOP",
	[26] = "Gag, Ungag",
	[27] = "Redirect",
	[28] = "Ban",
	[29] = "Kick",
	[30] = "Drop",
	[31] = "Enter full hub",
	[32] = "Enter hub if IP banned",
	[33] = "Allowed for OpChat",
	[34] = "Send all users IP",
	[35] = "Range ban",
	[36] = "Range unban",
	[37] = "Range temp ban",
	[38] = "Range temp unban",
	[39] = "Get range perm bans",
	[40] = "Clear range perm bans",
	[41] = "Clear range temp bans",
	[42] = "Unban",
	[43] = "No search length limits.",
	[44] = "Send full myinfos",
	[45] = "No IP checking in connection and search request.",
	[46] = "Close",
	[47] = "No ConnectToMe deflood.",
	[48] = "No RevConnectToMe deflood.",
	[49] = "No search reply deflood.",
	[50] = "No received data deflood.",
	[51] = "No chat interval.",
	[52] = "No private message interval.",
	[53] = "No search interval.",
	[54] = "No maximum users from same IP.",
	[55] = "No reconnect time.",
}

local DoBool = function(bool)
	if bool == nil then bool = false end
	return tostring(bool)
end

local DoString = function(str)
	local s = str
	if str == nil or #str == 0 then s = "not set" end
	return s
end

local Backup = function()
	local Files = {{"Settings.bak","Settings.xml"},{"Profiles.bak","Profiles.xml"}}
	local Path,Reply = Core.GetPtokaXPath().."cfg/",""
	local Settings,Profiles
	for i,v in ipairs(Files) do
		local f,e = io.open(Path..v[1])
		if f then
			f:close()
			v[3] = true
		else
			f,e = io.open(Path..v[2])
			if f then
				local s = f:read("*a") f:close()
				if s and s:len() > 0 then
					f,e = io.open(Path..v[1],"w")
					if f then
						f:write(s) f:flush() f:close()
						Reply = Reply.."\r\n\tBackup of "..Path..v[2].." succeeded."
					else
						return false,e:sub(1,-2)
					end
				end
			else
				return false,e:sub(1,-2)
			end
		end
	end
	if Files[1][3] and Files[1][3] then
		Reply = Reply..Files[1][2].." & "..Files[2][2].." have already been backed up, proceeding."
	elseif Files[1][3] then
		Reply = Reply.."\r\n\t"..Path.." Settings have already been backed up, proceeding."
	elseif Files[2][3] then
		Reply = Reply.."\r\n\t"..Path.." Profiles have already been backed up, proceeding."
	end
	if #Reply > 0 then return true,Reply end
end

OnStartup = function()
	tmr = TmrMan.AddTimer(300*1000)
	-- create backup from Profiles.xml
	local cur = io.open(Core.GetPtokaXPath().."cfg/Profiles.xml")
	if not cur then return end
	if SaveonStartup then
		local back = io.open(Core.GetPtokaXPath().."cfg/Profiles.bak","w+")
		if back then
			back:write(cur:read("*a"))
			back:flush()
			back:close()
		end
	end
	cur:close()
	if UsePermission and tonumber(UsePermission) then
		Profiles = {}
		for n,_ in ipairs(ProfMan.GetProfiles()) do
			Profiles[n-1] = ProfMan.GetProfilePermission(n-1,UsePermission)
		end
	end
	local width = 50
	local r,p = "",SetMan.GetString(29):sub(1,1)
	local b,s = Backup()
	if b then
		local bool,num,str,prf,z,x = tostring(#Booleans),tostring(#Numbers),tostring(#Strings),tostring(#Permissions)
		local z,x = "[0-25]",25
		for i = 0, #Booleans do
			if i == x+1 then
				local y = math.min(x+25,bool)
				z = "["..tostring(x+1).."-"..tostring(y).."]"
				x = y
			end
			local val,s = Booleans[i]:gsub("$",r):sub(1,width),DoBool(SetMan.GetBool(i))
			local cmd = "Boolean\\"..z.."\\"..tostring(i)..".) "..val.." ("..s..")$<%[mynick]> "..p..
			"sb"..i.." %[line: "..val.." <true/false>]"
			table.insert(Cfg,cmd)
			table.insert(Setup.Boolean,"%[line:"..val.." <true/false>]")
		end
		z,x = "[0-25]",25
		for i = 0, #Numbers do
			if i == x+1 then
				local y = math.min(x+25,num)
				z = "["..tostring(x+1).."-"..tostring(y).."]"
				x = y
			end
			local val,s = Numbers[i]:gsub("$",r):sub(1,width),tostring(SetMan.GetNumber(i))
			table.insert(Cfg,"Integer\\"..z.."\\"..tostring(i)..".) "..val.." ("..s..")$<%[mynick]> "..
			p.."sn"..i.." %[line: "..val.." <integer>]")
			table.insert(Setup.Integer,"%[line:"..val.." <integer>]")
		end
		z,x = "[0-25]",25
		for i = 0, #Strings do
			if i == x+1 then
				local y = math.min(x+25,str)
				z = "["..tostring(x+1).."-"..tostring(y).."]"
				x = y
			end
			local val,s = Strings[i]:gsub("$",r):sub(1,width),DoString(SetMan.GetString(i))
			table.insert(Cfg,"String\\"..z.."\\"..tostring(i)..".) "..val..": ("..s..")$<%[mynick]> "..
			p.."ss"..i.." %[line: "..val.." <string>]")
			table.insert(Setup.String,"%[line:"..val.." <string>]")
		end
		for n,_ in ipairs(ProfMan.GetProfiles()) do
			z,x = "[0-25]",25
			for i = 0, #Permissions do
				if i == x+1 then
					local y = math.min(x+25,prf)
					z = "["..tostring(x+1).."-"..tostring(y).."]"
					x = y
				end
				local val,s = Permissions[i]:gsub("$",r):sub(1,width),DoBool(ProfMan.GetProfilePermission(n-1,i))
				table.insert(Cfg,"Permission\\"..ProfMan.GetProfile(n-1).sProfileName.."\\"..z.."\\"..
				tostring(i)..".) "..val..": ("..s..")$<%[mynick]> "..p.."sp"..i.." "..tostring(n-1)..
				" %[line: "..val.." <true/false>]")
				table.insert(Setup.String,"%[line:"..val.." <permission>]")
			end
		end
	else
		local scp = ScriptMan.GetScript().sName
		if scp then ScriptMan.StopScript(scp) end
	end
	local t = "There are "..tostring(#Booleans+#Numbers+#Strings+(#ProfMan.GetProfiles() * #Permissions)+4).." settings available."
	OnStartup,Backup,DoBool,DoString = nil,nil,nil,nil
end

function OnTimer(tmr)
	SetMan.Save()
	RegMan.Save()
	BanMan.Save()
	local f = io.open( Core.GetPtokaXPath().."cfg/Profiles.xml","w+" )
	local buf = {'<?xml version="1.0" encoding="windows-1252" standalone="yes" ?>','<Profiles>'}
	local profiles = ProfMan.GetProfiles()
	for j in ipairs(profiles) do
		table.insert(buf,'\t<Profile>')
		table.insert(buf,'\t\t<Name>'..profiles[j].sProfileName..'</Name>')
		local profilenumber = profiles[j].iProfileNumber
		local permissions = ""	
		for i = 0, 55 do
			permissions = permissions.. (ProfMan.GetProfilePermission(profilenumber,i) and '1' or '0')
		end
		permissions = permissions..string.rep('0', 200) -- 255 - 55
		table.insert(buf,'\t\t<Permissions>'..permissions..'</Permissions>')
		table.insert(buf,'\t</Profile>')
	end
	table.insert(buf,'</Profiles>')
	f:write(table.concat(buf,"\n")..'\n')
	f:flush()
	f:close()
end

OpConnected = function(user)
	if Profiles[user.iProfile] and next(Cfg) then
		local str,stp,uc,p = "","","$UserCommand 1 1 "..Menu.."\\","&#124;|"
		for i,v in ipairs(Cfg) do str = str..uc..v..p end
		local pfx = SetMan.GetString(29):sub(1,1)
		for key,val in pairs(Setup) do
			stp = stp..uc.."Setup All\\"..key.."s$<%[mynick]> "..pfx.."sa"..key:sub(1,1):lower().." "
			for i,v in ipairs(val) do stp = stp.."<"..v:gsub("line:","%1 #"..tostring(i-1)..": ")..">" end
			stp = stp..p..uc:gsub("1 1","0 1")..p..
			uc:gsub("1 1","1 3").."List All\\"..key.."s$<%[mynick]> "..pfx.."l"..
			key:sub(1,1):lower()..p..uc:gsub("1 1","0 1")..p
		end
		if #str > 0 then Core.SendToUser(user,str) end
		if #stp > 0 then Core.SendToUser(user,stp) end
		collectgarbage("collect")
	end
end

ChatArrival = function(user,data)
	if Profiles[user.iProfile] and next(Cfg) then
		local _,_,cmd,int = data:find("^%b<> ["..SetMan.GetString(29).."]([sl][bnspia])(%d*)")
		local _,_,id = data:find("^%b<> ["..SetMan.GetString(29).."]s[bnspa]%d* (%d+) .+|$")
		local _,_,val = data:find("%d+[%d^ ]* (.+)|$")
		if cmd then
			local precmds = {sp=true,sb=true,sn=true,ss=true,sa=true,lb=true,li=true,ls=true}
			if precmds[cmd] then
				local Cmds = {
				sp = function(user,data,id,int,val)
					local b = {["true"] = {true,true},["false"] = {true,false}}
					if b[val:lower()] then
						ProfMan.SetProfilePermission(id,int,b[val:lower()][2])
						local bt = tostring(ProfMan.GetProfilePermission(id,int))
						if bt == "nil" then bt = "false" end
						msg = "Successfully updated "..ProfMan.GetProfile(id).sProfileName..
						"'s "..string.format("%q",Permissions[int])..".  Current setting: "..bt
						return msg
					else
						return "Invalid argument. Type true or false"
					end
				end,
				sb = function(user,data,int,val)
					local b = {["true"] = {true,true},["false"] = {true,false}}
					if b[val:lower()] then
						SetMan.SetBool(int,b[val:lower()][2])
						local bt = tostring(SetMan.GetBool(int))
						if bt == "nil" then bt = "false" end
						msg = "Successfully updated #"..tostring(int)..", "..Booleans[int]..". "..
						"Current setting: "..bt
						return msg
					else
						return "Invalid argument. Type true or false"
					end
				end,
				sn = function(user,data,int,val)
					if val:find("^%d+$") then
						SetMan.SetNumber(int,tonumber(val))
						msg = "Successfully updated #"..tostring(int)..", "..Numbers[int]..
						". Current setting: "..tostring(SetMan.GetNumber(int))
						return msg
					else
						return "Invalid argument. Type a number"
					end
				end,
				ss = function(user,data,int,val)
					if not val:find("[%c|]",1,true) then
						SetMan.SetString(int,val)
						msg = "Successfully updated #"..tostring(int)..", "..Strings[int]..
						". Current setting: "..tostring(SetMan.GetString(int))
						return msg
					else
						return "Invalid argument. Type a string without control characters."
					end
				end,
				sa = function(user,data)
					local _,_,cat,cmd = data:find("^%b<> %psa([bns]) ([^|]+)|$")
					if cat and cmd then
						local x,c,b = 0,0
						for arg in cmd:gmatch("%b<>") do
							if #arg > 2 then
								c = c + 1
								arg = arg:sub(2,-2)
								local s = Cmds["s"..cat](user,data,x,arg)
								if s and s:len() > 0 then
									if not b then b = true end
									Core.SendToUser(user,"<"..Bot.."> "..s.."|")
								end
							end
							x = x + 1
						end
						local types = {["b"] = {#Booleans,"boolean"},["n"] = {#Numbers,"number"},["s"]= {#Strings,"string"}}
						if b then
							SetMan.Save()
							return "A total of "..tostring(c).." of "..tostring(types[cat][1])..
							" "..types[cat][2].." settings were updated."
						end
					end
				end,
				lb = function(user,data)
					local DoBool = function(bool)
						if bool == nil then bool = false end
						return tostring(bool)
					end
					local s = ""
					for i = 0, #Booleans do
						s = s.."  "..tostring(i).."\t"..Booleans[i].."  ( "..DoBool(SetMan.GetBool(i)).." )\r\n"
					end
					return "\r\n\r\n"..s.."\r\n\r\n"
				end,
				li = function(user,data)
					local s = ""
					for i = 0, #Numbers do
						s = s.."  "..tostring(i).."\t"..Numbers[i].."  [ "..tostring(SetMan.GetNumber(i)).." ]\r\n"
					end
					return "\r\n\r\n"..s.."\r\n\r\n"
				end,
				ls = function(user,data)
					DoString = function(str)
						local s = str
						if str == nil or str:len() == 0 then s = "not set" end
						return s
					end
					local s = ""
					for i = 0, #Strings do
						s = s.."  "..tostring(i).."\t"..Strings[i].."  "..string.format(" %q ",DoString(SetMan.GetString(i))).."\r\n"
					end
					return "\r\n\r\n"..s.."\r\n\r\n"
				end,
				}
				local msg,reply = ""
				if id and int and val then
					id,int = tonumber(id),tonumber(int)
					reply = Cmds[cmd](user,data,id,int,val)
				elseif int and val and val:len() > 0 then
					int = tonumber(int)
					reply = Cmds[cmd](user,data,int,val)
				else
					reply = Cmds[cmd](user,data)
				end
				if reply and reply:len() > 0 then
					SetMan.Save()
					return Core.SendToUser(user,"<"..Bot.."> "..reply.."|"),true
				end
			end
		end
	end
end
