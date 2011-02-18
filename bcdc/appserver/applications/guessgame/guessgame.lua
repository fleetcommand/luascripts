--// WELCOME AND LICENSE //--
--[[
     guessgame.lua -- Version 0.3a
     guessgame.lua -- A Guess Game for BCDC++ which utilizes the AS LUA Library.
     guessgame.lua -- Revision: 012/20080515

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
		012/20080515: Modified: In-game commands
		011/20080501: ASLib updates
		010/20080426: ASLib updates
		009/20080417: Modified to work with the new AS library
		008/20080410: Modified: Altered in-game commands
		007/20071210: Fixed: Code optimalization
		006/20071203: Added: Possibility to win some credit.
		005/20071203: Fixed: An error when guess was not a number.
		004/20071202: Added: Notification on user quit, destroying session when empty.
		003/20071202: Changed listener type, fixed randomization
		002/20071128: Some fixes and features. Randomization added. Multiplayer option added.
		001/20071128: Initial release
]]

dofile( DC():GetAppPath() .. "scripts\\aslib.lua" )

guessgame = {}
guessgame.appname = "GuessGame"
guessgame.scounter = 0
guessgame.min = 1
guessgame.max = 300
guessgame.prize = 90
guessgame.step = 4
repeat
	guessgame.rseed1 = os.clock()
	guessgame.rseed1 = math.floor((guessgame.rseed1 - math.floor(guessgame.rseed1) ) * 1000)
until (guessgame.rseed1 ~= 0)
guessgame.rseed2 = false
guessgame.rseed = false

guessgame.GetRandom = function(this)
	if guessgame.rseed2 == false then
		-- initialize second part of random seed at first call
		repeat
			local rseed2 = os.clock()
			guessgame.rseed2 = math.floor((rseed2 - math.floor(rseed2) ) * 1000)
		until (guessgame.rseed2 ~= 0)
		guessgame.rseed = guessgame.rseed1 * guessgame.rseed2 * guessgame.rseed2
		math.randomseed( guessgame.rseed )
	end
	return math.random(guessgame.min, guessgame.max)
end

guessgame.NewGame = function(this, uid, nick)
	guessgame.scounter = guessgame.scounter + 1
	local sid = "gg" .. tostring(guessgame.scounter)
	local session = aslib:SCreate(sid, guessgame.appname)
	session:SetField("guesswhat", guessgame:GetRandom())
	session:SetField("prize", guessgame.prize)
	aslib:Broadcast( nick .. " elindított egy új Számkitalálós játékot. Ha be szeretnél lépni, írd be nekem privát üzenetként: ggjoin " .. sid )
	session:JoinUser(uid, nick, "Üdvözlünk a játékosok között! Elrejtettem egy számot. A tippeléshez írj be egy " .. tostring(guessgame.min) .. "-" .. tostring(guessgame.max) .. " közti értéket!")
	session:RequestUserData(uid, "credit")	
end

guessgame.JoinUser = function(this, uid, nick, gameid )
	local session = aslib:GetSession(gameid)
	if session then
		if (session:GetAppName() == guessgame.appname) then
			local count = session:UserCount() + 1
			if (count <= 3) then
				if session:JoinUser(uid, nick, "Üdvözlünk! A tippeléshez írj be egy " .. tostring(guessgame.min) .. "-" .. tostring(guessgame.max) .. " közti értéket! Veled együtt " .. tostring(count) .. " játékos van játékban.") then
					session:RequestUserData(uid, "credit")
					session:MessageUser(uid, nick .. " belépett a játékba!", true)	
				end
			else
				aslib:Message(uid, "Sajnálom, de a játékosok száma elérte a maximálisat. Egy játékban legfeljebb hárman vehetnek részt.")
			end
		else
			aslib:Message(uid, "Az általad megadott azonosító alatt nem Számkitalálós játék fut!")
		end
	else
		aslib:Message(uid, "Nincs " .. gameid .. " azonosítójú játék!")
	end
end

guessgame.DropUser = function(this, user, session, nick)
	
	local ret = false
	ret = user:Drop("Kiléptél a játékból.")
	if ret then
		session:Message(nick .. " kilépett a játékból. Még " .. tostring(session:UserCount()) .. " felhasználó van ebben a játékban.")
	end
	return ret
	
end

guessgame.DecreasePrize = function(this, session)
	local currentw = session:GetField("prize")
	currentw = currentw - guessgame.step
	if currentw < 0 then
		currentw = 0
	end
	session:SetField("prize", currentw)
	return true
end

guessgame.TryToGuess = function(this, user, session, nick, guess)
	
	local guessint = tonumber(guess)
	local value = session:GetField("guesswhat")
	local uid = user:GetUid()
	
	if not guessint then
		user:Message("A tippeléshez számot írj be!")
		return false
	end
	
	if (guessint < value) then
		guessgame:DecreasePrize(session)
		session:MessageUser(uid, "A tipped túl kicsi. A megnyerhető összeg: " .. tostring(session:GetField("prize")) .. " Puták.")
		session:MessageUser(uid, nick .. " tippje: " .. tostring(guessint) .. ", ami túl kicsinek bizonyult. A megnyerhető összeg: " .. tostring(session:GetField("prize")) .. " Puták.", true)
	elseif (guessint > value) then
		guessgame:DecreasePrize(session)
		session:MessageUser(uid, "A tipped túl nagy. A megnyerhető összeg: " .. tostring(session:GetField("prize")) .. " Puták.")
		session:MessageUser(uid, nick .. " tippje: " .. tostring(guessint) .. ", ami túl nagynak bizonyult. A megnyerhető összeg: " .. tostring(session:GetField("prize")) .. " Puták.", true)
	else
		session:MessageUser(uid, "Ügyes vagy! A szám, amire gondoltam a(z) " .. tostring(value) .. "!")
		session:MessageUser(uid, nick .. " megfejtette az eldugott számot: " .. tostring(guessint) .. ".", true)
		if session:IsUserComplete(uid) then
			local value = session:GetUd(uid, "credit")
			session:SetUd(uid, "credit", tostring(tonumber(value) + session:GetField("prize")))
			session:SendUserData(uid, "credit", "A nyereményed " .. session:GetField("prize") .. " Elite Puták. Köszönjük a játékot!")
		else
			session:MessageUser(uid, "Sajnos nem tudjuk, mennyi pontod van, így a nyereményed, ami " .. session:GetField("prize") .. " Elite Puták, nem tudjuk jóváírni.")
		end
		session:Destroy("A játék véget ért.")
	end
	return true
end

aslib:SetListener("onmessage", guessgame.appname, "ggmsglistener",
	function(uid, nick, message)
		local params = aslib:Tokenize(message)
		if params[1] == "gg" then
			guessgame:NewGame(uid, nick)
		elseif params[1] == "ggjoin" then
			if params[2] then
				guessgame:JoinUser(uid, nick, params[2])
			else
				aslib:Message(uid, "A parancs használata: ggjoin <játékazonosító>")
			end
		elseif params[1] == "help" then
			aslib:Message(uid, "[GuessGame] gg: Új játék, ggjoin <id>: Belépés már meglévő játékba")
		end
	end
)

aslib:SetListener("onsessionmessage", guessgame.appname, "ggsmsglistener",
	function(user, session, nick, message)
		local params = aslib:Tokenize(message)
		if params[1] == "quit" then
			guessgame:DropUser(user, session, nick)
		elseif params[1] == "help" then
			user:Message("[GuessGame] -quit: Játék elhagyása")
		else
			guessgame:TryToGuess(user, session, nick, params[1])
		end
	end
)

aslib:SetListener("onuserdata", guessgame.appname, "ggudlistener",
	function(user, session, variable, value)
		if (variable == "credit") then
			user:Message("Jelenleg " .. value .. " Elite Putákod van." )
		end
	end
)

aslib:SetListener("onquit", guessgame.appname, "ggquitlistener",
	function(uid, sname, nick)
		local session = aslib:GetSession(sname)
		if session then
			local count = session:UserCount()
			if (count ~= 0) then
				session:Message(nick .. " kilépett a hubról. Még " .. tostring(count) .. " felhasználó van ebben a játékban.")
			end
		end
	end
)

aslib:Debug( "** Loaded guessgame.lua **" )
