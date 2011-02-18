--// WELCOME AND LICENSE //--
--[[
     hangman.lua -- Version 0.5b
     hangman.lua -- A Hangman Game for BCDC++ which utilizes the AS LUA Library.
     hangman.lua -- Revision: 019/20080515

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
		019/20080519: Modified: In-game commands
		018/20080501: ASLib updates
		017/20080425: ASLib updates
		016/20080417: Modified to work with the new AS library
		015/20080410: Fixed: Missing session status messages in championship mode; altered in-game commands
		014/20080409: Added: Timeout for guessing in championship mode; allowing comments in data file
		013/20080409: Fixed: Now checking for next player and allowing to play further when someone leaves the game
		012/20080104: Modified: Allowing multi-word categories
		011/20071224: Fixed: Scoring when maxing out letters
		010/20071224: Fixed: When a user requests a letter for second time, the reply won't get broadcasted to the whole session
		009/20071224: Fixed: Send solution after solving
		008/20071224: Added: Don't have to type punctuates when solving, checking for duplicated solutions
		007/20071214: Added: Championship mode (-hmc)
		006/20071212: Modified: Scoring system
		005/20071211: Modified: New character for hidden chars
		004/20071211: Added: Last letters for new users, crediting prize, max 5 players per session, special characters, broadcast
		003/20071211: Added: Categorization, -hmcat, -hm [category]
		002/20071211: Added: Possible solutions loaded from a file
		001/20071210: Initial release
]]

dofile( DC():GetAppPath() .. "scripts\\aslib.lua" )

hangman = {}
hangman.alphabet1 = false
hangman.alphabet2 = false
hangman.specials = false
hangman.appname = "Hangman"
hangman.maxplayers = 5 --// max. number of players
hangman.scounter = 0
hangman.score_solve = 100 --// base score for solving
hangman.score_letter = 10 --// base score for letters
hangman.timeout = 180 --// maximum time in seconds for inactivity in championship mode
hangman.nexttimer = false --// time the timer next called (about every 15 seconds). no need to call if false (eg. there's no session)
hangman.textfile = DC():GetAppPath() .. "scripts\\hangman.data.txt"
hangman.data = {}
hangman.data._all = {}
hangman.dcount = 0
repeat
	hangman.rseed1 = os.clock()
	hangman.rseed1 = math.floor((hangman.rseed1 - math.floor(hangman.rseed1) ) * 1000)
until (hangman.rseed1 ~= 0)
hangman.rseed2 = false
hangman.rseed = false

hangman.InitializeAlphabet1 = function(this)
	local table = {}
	table["b"] = "B"
	table["c"] = "C"
	table["d"] = "D"
	table["f"] = "F"
	table["g"] = "G"
	table["h"] = "H"
	table["j"] = "J"
	table["k"] = "K"
	table["l"] = "L"
	table["m"] = "M"
	table["n"] = "N"
	table["p"] = "P"
	table["q"] = "Q"
	table["r"] = "R"
	table["s"] = "S"
	table["t"] = "T"
	table["v"] = "V"
	table["w"] = "W"
	table["x"] = "X"
	table["y"] = "Y"
	table["z"] = "Z"
	return table
end

hangman.InitializeAlphabet2 = function(this)
	local table = {}
	table["a"] = "A"
	table["á"] = "Á"
	table["e"] = "E"
	table["é"] = "É"
	table["i"] = "I"
	table["í"] = "Í"
	table["o"] = "O"
	table["ó"] = "Ó"
	table["ö"] = "Ö"
	table["ő"] = "Ő"
	table["u"] = "U"
	table["ú"] = "Ú"
	table["ü"] = "Ü"
	table["ű"] = "Ű"
	return table
end

hangman.InitializeSpecials = function(this)
	local table = {}
	table["a'"] = "á"
	table["e'"] = "é"
	table["i'"] = "í"
	table["o'"] = "ó"
	table["u'"] = "ú"
	table["o\""] = "ő"
	table["u\""] = "ű"
	return table
end

hangman.FixSpecials = function(this, text)
	for spec in pairs(hangman.specials) do
		if string.find(text, spec) then
			text = string.gsub(text, spec, hangman.specials[spec])
		end
	end
	return text
end

hangman.LoadData = function(this)
	local file, err = io.open(hangman.textfile,"r")
	if file then
		text = file:read("*l")
		repeat
			if (string.sub(text, 1, 1) ~= "#") then
				hangman.dcount = hangman.dcount + 1
				if string.find(text, "^[^@]-@.*$") then
					hangman.data._all[hangman.dcount] = {}
					local soltype = string.gsub(text, "^([^@]-)@(.*)$", "%1")
					local solution = string.gsub(text, "^([^@]-)@(.*)$", "%2")
					hangman.data._all[hangman.dcount].soltype = soltype
					hangman.data._all[hangman.dcount].solution = solution
					if not hangman.data[soltype] then
						hangman.data[soltype] = {}
					end
					table.insert(hangman.data[soltype], hangman.dcount)
				else
					aslib:Debug("[hangman.lua] Bad data file format (" .. tostring(hangman.dcount) .. "): " .. tostring(text) )
				end	
			end
			text = file:read("*l")
		until (text == nil)
		aslib:Debug("[hangman.lua] " .. tostring(hangman.dcount) .. " items loaded from file")

		-- Checking for dupes
		local tmp = {}
		local dupes = 0
		for k in pairs(hangman.data._all) do
			local sol_original = hangman.data._all[k].solution
			local sol_modded = hangman:RemoveNonAlpha(hangman:Lower(sol_original))
			if tmp[sol_modded] then
				dupes = dupes + 1
				aslib:Debug("[hangman.lua] Dupe found: " .. sol_original )
			else
				tmp[sol_modded] = true
			end
		end
		if dupes > 0 then
			aslib:Debug("[hangman.lua] " .. tostring(dupes) .. " dupes found")
		else
			aslib:Debug("[hangman.lua] No dupes found" )
		end
	else
		aslib:Debug("[hangman.lua] Can't open file: \"" .. hangman.textfile .. "\". Error: " .. err)
	end
end

hangman.Lower = function(this, text)
	local mod = text
	for k in pairs(hangman.alphabet1) do
		if string.find(text, hangman.alphabet1[k]) then
			mod = string.gsub(mod, hangman.alphabet1[k], k)
		end
	end
	for k in pairs(hangman.alphabet2) do
		if string.find(text, hangman.alphabet2[k]) then
			mod = string.gsub(mod, hangman.alphabet2[k], k)
		end
	end
	return mod
end

hangman.RemoveNonAlpha = function(this, text)
	local maxlen = string.len(text)
	local mod = ""
	local i = 1
	while (i <= maxlen) do
		local found = false
		for j = i, maxlen do
			local curr = string.sub(text, i, j)
			for k in pairs(hangman.alphabet1) do
				if (hangman.alphabet1[k] == curr) or (k == curr) then
					mod = mod .. curr
					found = true
					break
				end
			end
			if not found then
				for k in pairs(hangman.alphabet2) do
					if (hangman.alphabet2[k] == curr) or (k == curr) then
						mod = mod .. curr
						found = true
						break
					end
				end
			end
			if found then
				i = j + 1
				break
			end
		end
		if not found then
			i = i + 1
		end
	end

	return mod
end

hangman.GetCurrentString = function(this, session)
	local current = session:GetField("current")
	local ret = ""
	local first = true
	for k in ipairs(current) do
		if first then
			first = false
		else
			ret = ret .. " "
		end
		ret = ret .. current[k]
		if current[k] == " " then
			ret = ret .. "  "
		end
	end
	return ret
end

hangman.GetSolutionString = function(this, session, formatted)
	local solution = session:GetField("solution")
	local ret = ""
	if formatted then
		local first = true
		for k in ipairs(solution) do
			if first then
				first = false
			else
				ret = ret .. " "
			end
			ret = ret .. solution[k]
			if solution[k] == " " then
				ret = ret .. "  "
			end
		end
	else
		for k in ipairs(solution) do
			ret = ret .. solution[k]
		end
	end
	return ret
end

hangman.GetLetterString = function(this, session)
	local letters = session:GetField("letters")
	local ret = ""
	local first = true
	for k in pairs(letters) do
		if first then
			first = false
		else
			ret = ret .. ", "
		end
		ret = ret .. k
	end
	return ret
end

hangman.GetPlayerList = function(this, session)
	local ret = ""
	local playerlist = session:GetField("playerlist")
	local first = true
	for k in pairs(playerlist) do
		if first then
			first = false
		else
			ret = ret .. "; "
		end
		ret = ret .. playerlist[k].nick .. ": " .. tostring(playerlist[k].score) .. " EP"
	end
	return ret
end

hangman.GetRandom = function(this, type)
	if hangman.rseed2 == false then
		-- initialize second part of random seed at first call
		repeat
			local rseed2 = os.clock()
			hangman.rseed2 = math.floor((rseed2 - math.floor(rseed2) ) * 1000)
		until (hangman.rseed2 ~= 0)
		hangman.rseed = hangman.rseed1 * hangman.rseed2 * hangman.rseed2
		math.randomseed( hangman.rseed )
	end
	local ret = math.random(1, hangman.dcount)
	if type then
		if hangman.data[type] then
			ret = hangman.data[type][math.random(1, #hangman.data[type])]
		else
			ret = false
		end
	end
	return ret
end

hangman.ListCats = function(this, uid)
	local text = ""
	local first = true
	for category in pairs(hangman.data) do	
		if category ~= "_all" then
			if first then
				first = false
			else
				text = text .. ", "
			end
			text = text .. category .. " (" .. tostring(#hangman.data[category]) .. ")"
		end
	end
	aslib:Message(uid, text)
end

hangman.BuildSolution = function(this, session, text)
	local maxlen = string.len(text)
	local solution = {}
	local current = {}
	local lettercount = 0
	local solved = 0
	local i = 1
	while (i <= maxlen) do
		local found = false
		for j = i, maxlen do
			local curr = string.sub(text, i, j)
			for k in pairs(hangman.alphabet1) do
				if (hangman.alphabet1[k] == curr) or (k == curr) then
					lettercount = lettercount + 1
					solution[lettercount] = curr
					current[lettercount] = "_"
					found = true
					break
				end
			end
			if not found then
				for k in pairs(hangman.alphabet2) do
					if (hangman.alphabet2[k] == curr) or (k == curr) then
						lettercount = lettercount + 1
						solution[lettercount] = curr
						current[lettercount] = "_"
						found = true
						break
					end
				end
			end
			if found then
				i = j + 1
				break
			end
		end
		if not found then
			lettercount = lettercount + 1
			solved = solved + 1
			solution[lettercount] = string.sub(text, i, i)
			current[lettercount] = string.sub(text, i, i)
			i = i + 1
		end
	end
	
	session:SetField("solution", solution) -- the original solution
	session:SetField("current", current) -- the progress where the user is
	session:SetField("lettercount", lettercount) -- the total number of letters
	session:SetField("solved", solved) -- the solved letters
	session:SetField("prize", 0)
	return true
end

hangman.NewGame = function(this, uid, nick, stype, gtype, players)
	
	local count = hangman:GetRandom(stype)
	if count then
		hangman.scounter = hangman.scounter + 1
		local sid = "hm" .. tostring(hangman.scounter)
		local session = aslib:SCreate(sid, hangman.appname)
		session:SetField("gametype", gtype)
		session:SetField("letters", {} )
		session:SetField("soltype", hangman.data._all[count].soltype)
		hangman:BuildSolution(session, hangman.data._all[count].solution)
		if (gtype == "free") then
			aslib:Broadcast( nick .. " elindított egy új Akasztófa játékot. Ha be szeretnél lépni, írd be nekem privát üzenetként: hmjoin " .. sid )
			session:JoinUser(uid, nick, "Üdvözlünk a játékosok között! A feladvány a(z) " .. session:GetField("soltype") .. " témakörből: \"" .. hangman:GetCurrentString(session) .. "\"")
			session:RequestUserData(uid, "credit")
		elseif (gtype == "championship") then
			session:SetField("players", players) --// required number of players
			local playerlist = {}
			local tmp = {}
			tmp.uid = uid
			tmp.nick = nick
			tmp.score = 0
			table.insert(playerlist, tmp)
			session:SetField("playerlist", playerlist)
			session:SetField("next", uid) --// the first player is the next one
			session:JoinUser(uid, nick, "Üdvözlünk az Akasztófa játékban. Ahhoz, hogy a játék elinduljon, szükség van még " .. tostring(players - 1) .. " játékosra. A játékostársaidnak mondd meg, hogy adják ki privát üzenetként a \"hmjoin " .. sid .. "\" parancsot a belépéshez!")
			session:RequestUserData(uid, "credit")
		end
	else
		aslib:Message(uid, "Nincsen az adatbázisban \"" .. tostring(stype) .. "\" típusú feladvány. A lehetséges kategóriákat a hmcats paranccsal kérheted le.")
	end
	
end

hangman.JoinUser = function(this, uid, nick, gameid )
	
	local session = aslib:GetSession(gameid)
	if session then
		if session:GetAppName() == hangman.appname then
			local gtype = session:GetField("gametype")
			if gtype == "free" then
				local count = session:UserCount() + 1
				if (count <= hangman.maxplayers) then
					if session:JoinUser(uid, nick, "Üdvözlünk! Az aktuális feladvány a(z) " .. session:GetField("soltype") .. " témakörből: \"" .. hangman:GetCurrentString(session) .. "\". Veled együtt " .. tostring(count) .. " játékos van játékban.") then
						session:RequestUserData(uid, "credit")
						session:MessageUser(uid, nick .. " belépett a játékba!", true)
						session:MessageUser(uid, "Eddig a többiek az alábbi betűkre tippeltek: " .. hangman:GetLetterString(session) )
					end
				else
					aslib:Message(uid, "Sajnálom, de a játékosok száma elérte a maximálisat. Egy játékban legfeljebb " .. tostring(hangman.maxplayers) .. " résztvevő lehet!")
				end
			elseif gtype == "championship" then
				local count = session:UserCount() --// current number of players
				local players = session:GetField("players") --// required number of players
				if (count < players) then
					if session:JoinUser(uid, nick, "Üdvözlünk! Jelenleg a játékban veled együtt " .. tostring(count + 1) .. " játékos van.") then
						session:RequestUserData(uid, "credit")
						session:MessageUser(uid, nick .. " belépett a játékba!", true)
						local playerlist = session:GetField("playerlist")
						local tmp = {}
						tmp.uid = uid
						tmp.nick = nick
						tmp.score = 0
						table.insert(playerlist, tmp)
						--// don't need since playerlist is a reference
						-- session:SetField("playerlist", playerlist)

						if ((count + 1) == players) then
							hangman.nexttimer = os.time() + 15
							session:Message("Pontozás: Minden helyes mássalhangzó " .. tostring(math.floor(hangman.score_letter * 1.5)) .. " EP. A jó megfejtésért " .. tostring(hangman.score_solve * 2) .. " EP jár. Magánhangzó " .. tostring(hangman.score_letter * 2) .. " EP-ért vásárolható, rossz megfejtésért pedig " .. tostring(math.floor(hangman.score_solve / 2)) .. " EP levonás jár.")
							session:Message("A játék elindult. A feladvány a(z) " .. session:GetField("soltype") .. " témakörből: \"" .. hangman:GetCurrentString(session) .. "\"")
							local playerlist = session:GetField("playerlist")
							local nextuid = session:GetField("next")
							for k in pairs(playerlist) do
								if playerlist[k].uid == nextuid then
									session:MessageUser( playerlist[k].uid, playerlist[k].nick .. " kezdheti a játékot!", true)
									session:MessageUser( playerlist[k].uid, "Te kezdheted a játékot!")
									session:ActualizeActivity( playerlist[k].uid )
								end
							end
						else
							session:Message("Még " .. tostring(players - count + 1) .. " játékosra várunk.")
						end
					end
				else
					aslib:Message(uid, "Sajnálom, de a játékosok száma már elérte a maximálisat. Ebben a játékban " .. tostring(players) .. " játékos játszhat.")
				end
			end
		else
			aslib:Message(uid, "Az áldalad megadott azonosító alatt nem Akasztófa játék fut!")
		end
	else
		aslib:Message(uid, "Nincs " .. gameid .. " azonosítójú játék!")
	end
	
end

hangman.DropUser = function(this, user, session, nick)
	
	local ret = false
	
	ret = user:Drop("Kiléptél a játékból.")
	if ret then
		local count = session:UserCount()
		session:Message(nick .. " kilépett a játékból. Még " .. tostring(count) .. " felhasználó van ebben a játékban.")
		local gametype = session:GetField("gametype")
		if gametype == "championship" then
			local uid = user:GetUid()
			local playerlist = session:GetField("playerlist")
			local players = session:GetField("players")
			local nextuid = session:GetField("next")
			local playernum = false
			for k in pairs(playerlist) do
				if playerlist[k].uid == uid then
					playernum = k
					table.remove(playerlist, k)
				end
			end
			players = players - 1
			--// don't need since playerlist is a reference
			-- session:SetField("playerlist", playerlist)
			session:SetField("players", players)

			if nextuid == uid then --// if the next user quit
				if playerlist[k] then
					nextuid = playerlist[k].uid
					playernum = k
				else
					nextuid = playerlist[1].uid
					playernum = 1
				end
				session:SetField("next", nextuid)
				
				session:MessageUser(nextuid, playerlist[playernum].nick .. " tippje következik.", true)
				session:MessageUser(nextuid, "Te következel!")
				session:ActualizeActivity( nextuid )
			end
		end
	end
	return ret
end

hangman.Guess = function(this, user, session, nick, text)
	
	local uid = user:GetUid()
	text = hangman:FixSpecials(text)
	local gtype = session:GetField("gametype")
	if gtype == "free" then
		if string.len(text) > 5 then
			-- trying to solve
			if hangman:RemoveNonAlpha(hangman:Lower(hangman:GetSolutionString(session))) == hangman:RemoveNonAlpha(hangman:Lower(text)) then
				local prize = session:GetField("prize")
				prize = prize + hangman.score_solve
				session:MessageUser(uid, "Gratulálunk, megfejtetted a feladványt!")
				session:MessageUser(uid, nick .. " megfejtette a feladványt, a nyereménye " .. tostring(prize) .. " Elite Puták!", true)
				session:Message("[" .. session:GetField("soltype") .. " - " .. tostring(prize) .. " pont]: " .. hangman:GetSolutionString(session, true))
				if session:IsUserComplete(uid) then
					local cre = tonumber(session:GetUd(uid, "credit"))
					session:SetUd(uid, "credit", tostring(cre + prize))
					session:SendUserData(uid, "credit", "A nyereményed " .. tostring(prize) .. " Elite Puták. Köszönjük a játékot!")
				else
					session:MessageUser(uid, "Sajnos nem tudjuk, eredetileg mennyi pontod volt, így a nyereményed, ami " .. tostring(prize) .. " Elite Puták, nem tudjuk jóváírni.")
				end
				session:Destroy("A játék véget ért.")
			else
				session:MessageUser(uid, nick .. " megpróbálta megfejteni a feladványt.", true)
				session:MessageUser(uid, "Nem sikerült megfejtened a feladványt!")
				local prize = session:GetField("prize")

				session:Message("[" .. session:GetField("soltype") .. " - " .. tostring(prize) .. " pont]: " .. hangman:GetCurrentString(session))
			end
		else

			local solution = session:GetField("solution")
			local current = session:GetField("current")
			local lettercount = session:GetField("lettercount")
			local solved = session:GetField("solved")
			local prevsolved = solved
			local found = false
		
			--// Consonants
			--// (hangman.score_letter points for every unhidden consonants in free game mode)
			for k in pairs(hangman.alphabet1) do
				if ((text == k) or (text == hangman.alphabet1[k])) then
					found = true

					local letters = session:GetField("letters")
					if letters[k] then
						session:MessageUser(uid, "A(z) " .. hangman.alphabet1[k] .. " betűt előtted már kérték.")
					else
						session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet1[k] .. " betűt kérte.", true)
						letters[k] = true
						session:SetField("letters", letters)
					
						for i in pairs(solution) do
							if (hangman.alphabet1[k] == solution[i]) or (k == solution[i]) then			
								solved = solved + 1	
								current[i] = solution[i]
							end
						end
					
						session:SetField("solved", solved)
						session:SetField("current", current)
						local prize = session:GetField("prize")
						local newprize = prize + (solved - prevsolved) * hangman.score_letter

						session:SetField("prize", newprize)
						session:Message("[" .. session:GetField("soltype") .. " - " .. tostring(newprize) .. " pont]: " .. hangman:GetCurrentString(session))
					
					end
				end
			end	

			--// Wowels
			--// (no points for unhidden wowels in free game mode)
			if not found then
				for k in pairs(hangman.alphabet2) do
					if ((text == k) or (text == hangman.alphabet2[k])) then
						found = true
				
						local letters = session:GetField("letters")
						if letters[k] then
							session:MessageUser(uid, "A(z) " .. hangman.alphabet2[k] .. " betűt előtted már kérték.")
						else
							session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet2[k] .. " betűt kérte.", true)
							letters[k] = true
							session:SetField("letters", letters)
					
							for i in pairs(solution) do
								if (hangman.alphabet2[k] == solution[i]) or (k == solution[i]) then			
									solved = solved + 1	
									current[i] = solution[i]
								end
							end
						
							session:SetField("solved", solved)
							session:SetField("current", current)
							local prize = session:GetField("prize")

							session:Message("[" .. session:GetField("soltype") .. " - " .. tostring(prize) .. " pont]: " .. hangman:GetCurrentString(session))
					
						end
					end
				end	
			end

			if solved == lettercount then
				local prize = session:GetField("prize")
				session:MessageUser(uid, "Gratulálunk, megfejtetted a feladványt!")
				session:MessageUser(uid, nick .. " megfejtette a feladványt!", true)
				
				if session:IsUserComplete(uid) then
					local cre = tonumber(session:GetUd(uid, "credit"))
					session:SetUd(uid, "credit", tostring(cre + prize))
					session:SendUserData(uid, "credit", "A nyereményed " .. tostring(prize) .. " Elite Puták. Köszönjük a játékot!")
				else
					session:MessageUser(uid, "Sajnos nem tudjuk, eredetileg mennyi pontod volt, így a nyereményed, ami " .. tostring(prize) .. " Elite Puták, nem tudjuk jóváírni.")
				end
				session:Destroy("A játék véget ért.")
			end --// if solved == lettercount then
		end --// if string.len(text) > 5 then
	elseif gtype == "championship" then
		local count = session:UserCount()
		local players = session:GetField("players")
		if (count < players) then
			session:MessageUser(uid, "Amíg nincs meg a megfelelő számú játékos, nem tippelhetsz")
		else
			local nextuid = session:GetField("next")
			local playerlist = session:GetField("playerlist")
			local playernum = false
			for k in pairs(playerlist) do
				if playerlist[k].uid == uid then
					playernum = k
				end
			end
			if (uid == nextuid) then
				if string.len(text) > 5 then
					-- trying to solve
					if hangman:RemoveNonAlpha(hangman:Lower(hangman:GetSolutionString(session))) == hangman:RemoveNonAlpha(hangman:Lower(text)) then
						local prize = playerlist[playernum].score
						prize = prize + hangman.score_solve * 2
						session:MessageUser(uid, "Gratulálunk, megfejtetted a feladványt!")
						session:MessageUser(uid, nick .. " megfejtette a feladványt, a nyereménye " .. tostring(prize) .. " Elite Puták!", true)
						session:Message("[" .. session:GetField("soltype") .. "]: " .. hangman:GetSolutionString(session, true))
						if session:IsUserComplete(uid) then
							local cre = tonumber(session:GetUd(uid, "credit"))
							session:SetUd(uid, "credit", tostring(cre + prize))
							session:SendUserData(uid, "credit", "A nyereményed " .. tostring(prize) .. " Elite Puták. Köszönjük a játékot!")
						else
							session:MessageUser(uid, "Sajnos nem tudjuk, eredetileg mennyi pontod volt, így a nyereményed, ami " .. tostring(prize) .. " Elite Puták, nem tudjuk jóváírni.")
						end
						session:Destroy("A játék véget ért.")
					else
						session:MessageUser(uid, nick .. " megpróbálta megfejteni a feladványt.", true)
						session:MessageUser(uid, "Nem sikerült megfejtened a feladványt!")
						local prize = playerlist[playernum].score

						prize = prize - math.floor(hangman.score_solve / 2)
						if prize < 0 then
							prize = 0
						end
						playerlist[playernum].score = prize
						
						session:Message(hangman:GetPlayerList(session))
						playernum = playernum + 1
						if (playernum > players) then
							playernum = 1
						end
						session:SetField("next", playerlist[playernum].uid)
						session:Message("[" .. session:GetField("soltype") .. "]: " .. hangman:GetCurrentString(session))
						session:MessageUser(playerlist[playernum].uid, playerlist[playernum].nick .. " tippje következik.", true)
						session:MessageUser(playerlist[playernum].uid, "Te következel!")
						session:ActualizeActivity( playerlist[playernum].uid )
					end
				else --// if string.len(text) > 5 then
					-- guess a letter
					local solution = session:GetField("solution")
					local current = session:GetField("current")
					local lettercount = session:GetField("lettercount")
					local solved = session:GetField("solved")
					local prevsolved = solved
					local found = false
					
					--// Consonants
					--// (hangman.score_letter * 1.5 points for every unhidden consonants in championship mode)
					for k in pairs(hangman.alphabet1) do
						if ((text == k) or (text == hangman.alphabet1[k])) then
							found = true

							local letters = session:GetField("letters")
							if letters[k] then
								session:MessageUser(uid, "A(z) " .. hangman.alphabet1[k] .. " betűt előtted már kérték.")
								session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet1[k] .. " betűt kérte annak ellenére, hogy azt már kérték korábban.", true)
							else
								session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet1[k] .. " betűt kérte.", true)
								letters[k] = true
								session:SetField("letters", letters)
					
								for i in pairs(solution) do
									if (hangman.alphabet1[k] == solution[i]) or (k == solution[i]) then			
										solved = solved + 1	
										current[i] = solution[i]
									end
								end
					
								session:SetField("solved", solved)
								session:SetField("current", current)
								local prize = playerlist[playernum].score
								prize = prize + (solved - prevsolved) * math.floor(hangman.score_letter * 1.5)
								playerlist[playernum].score = prize
								session:Message(hangman:GetPlayerList(session))
								session:Message("[" .. session:GetField("soltype") .. "]: " .. hangman:GetCurrentString(session))
							end
						end
					end	


					--// Wowels
					--// (everyone can buy wowels for hangman.score_letter * 2 points in championship mode)
					if not found then
						for k in pairs(hangman.alphabet2) do
							if ((text == k) or (text == hangman.alphabet2[k])) then
								found = true
								local prize = playerlist[playernum].score
								if prize < (hangman.score_letter * 2) then
									session:MessageUser(uid, "Nincs elég Putákod magánhangzó vásárlásához!")
									session:MessageUser(uid, nick .. " magánhangzót szeretett volna vásárolni, de nincs elég Putákja hozzá.", true)
								else
									local letters = session:GetField("letters")									
									if letters[k] then
										session:MessageUser(uid, "A(z) " .. hangman.alphabet2[k] .. " betűt előtted már kérték.")
										session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet2[k] .. " betűt kérte annak ellenére, hogy azt már kérték korábban.", true)
									else
										session:MessageUser(uid, nick .. " a(z) " .. hangman.alphabet2[k] .. " betűt kérte.", true)
										letters[k] = true
										session:SetField("letters", letters)
					
										for i in pairs(solution) do
											if (hangman.alphabet2[k] == solution[i]) or (k == solution[i]) then			
												solved = solved + 1	
												current[i] = solution[i]
											end
										end
										
										if prevsolved ~= solved then
											prize = prize - (hangman.score_letter * 2)
											playerlist[playernum].score = prize
										end
										
										session:SetField("solved", solved)
										session:SetField("current", current)
										
										session:Message(hangman:GetPlayerList(session))
										session:Message("[" .. session:GetField("soltype") .. " - " .. tostring(newprize) .. " pont]: " .. hangman:GetCurrentString(session))
					
									end
								end
							end
						end	
					end
					if solved == lettercount then
						local prize = playerlist[playernum].score
						session:MessageUser(uid, "Gratulálunk, megfejtetted a feladványt!")
						session:MessageUser(uid, nick .. " megfejtette a feladványt!", true)
						
						if session:IsUserComplete(uid) then
							local cre = tonumber(session:GetUd(uid, "credit"))
							session:SetUd(uid, "credit", tostring(cre + prize))
							session:SendUserData(uid, "credit", "A nyereményed " .. tostring(prize) .. " Elite Puták. Köszönjük a játékot!")
						else
							session:MessageUser(uid, "Sajnos nem tudjuk, eredetileg mennyi pontod volt, így a nyereményed, ami " .. tostring(prize) .. " Elite Puták, nem tudjuk jóváírni.")
						end
						session:Destroy("A játék véget ért.")
					elseif solved == prevsolved then
						playernum = playernum + 1
						if (playernum > players) then
							playernum = 1
						end
						session:SetField("next", playerlist[playernum].uid)
						session:MessageUser(playerlist[playernum].uid, playerlist[playernum].nick .. " tippje következik.", true)
						session:MessageUser(playerlist[playernum].uid, "Te következel!")
						session:ActualizeActivity( playerlist[playernum].uid )
					else
						session:MessageUser(playerlist[playernum].uid, "Újra " .. playerlist[playernum].nick .. " tippje következik.", true)
						session:MessageUser(playerlist[playernum].uid, "Újra te tippelhetsz!")
						session:ActualizeActivity( playerlist[playernum].uid )
					end --// if solved == lettercount then
				end --// if string.len(text) > 5 then
			else --// if (uid == nextuid) then
				session:MessageUser(uid, "Most nem te vagy soron!")
			end --// if (uid == nextuid) then
		end --// if (count < players) then
		
	end --// if gtype == "free" then
	return true
end

aslib:SetListener("onmessage", hangman.appname, "hmmsglistener",
	function(uid, nick, message)
		local params = aslib:Tokenize(message)
		if params[1] == "hm" then
			local stype = false
			if string.find(message, ".*hm +.*$") then
				stype = string.gsub(message, ".*hm +(.*)$", "%1")
			end
			hangman:NewGame(uid, nick, stype, "free")
		elseif params[1] == "hmc" then
			if not params[2] then
				aslib:Message(uid, "A parancs használata: hmc <játékosok száma>")
			else
				local pnum = tonumber(params[2])
				if pnum then
					if (pnum < 2) or (pnum > hangman.maxplayers) then
						aslib:Message(uid, "Legalább 2, de legfeljebb " .. tostring(hangman.maxplayers) .. " játékos megadása szükséges a játék elindításához!")
					else
						hangman:NewGame(uid, nick, false, "championship", pnum)
					end
				else
					aslib:Message(uid, "A parancs használata: hmc <játékosok száma>")
				end
			end
		elseif params[1] == "hmjoin" then
			if params[2] then
				hangman:JoinUser(uid, nick, params[2])
			else
				aslib:Message(uid, "A parancs használata: hmjoin <játékazonosító>")
			end
		elseif params[1] == "hmcats" then
			hangman:ListCats(uid)
		elseif params[1] == "help" then
			aslib:Message(uid, "[Hangman] hm [kategória]: Új szabadjáték, hmc <játékosok>: Új körverseny indítása, hmjoin <id>: Belépés már meglévő játékba, hmcats: Kategóriák listázása")
		end
	end
)

aslib:SetListener("onsessionmessage", hangman.appname, "hmsmsglistener",
	function(user, session, nick, message)
		local params = aslib:Tokenize(message)
		if params[1] == "quit" then
			hangman:DropUser(user, session, nick)
		elseif params[1] == "letters" then
				user:Message("Eddigi betűk: " .. hangman:GetLetterString(session))
		elseif params[1] == "help" then
			user:Message("[Hangman] quit: Játék elhagyása, letters: Eddig kért betűk")
		else
			hangman:Guess(user, session, nick, message)
		end
	end
)

aslib:SetListener("onuserdata", hangman.appname, "hmudlistener",
	function(user, session, variable, value)
		if (variable == "credit") then
			user:Message("Jelenleg " .. value .. " Elite Putákod van.")
		end
	end
)

aslib:SetListener("onquit", hangman.appname, "hmquitlistener",
	function(uid, sname, nick)
		local session = aslib:GetSession(sname)
		if session then
			local count = session:UserCount()
			if (count ~= 0) then
				session:Message(nick .. " kilépett a hubról. Még " .. tostring(count) .. " felhasználó van ebben a játékban.")
				local gametype = session:GetField("gametype")
				if gametype == "championship" then
					local playerlist = session:GetField("playerlist")
					local players = session:GetField("players")
					local nextuid = session:GetField("next")
					local playernum = false
					for k in pairs(playerlist) do
						if playerlist[k].uid == uid then
							playernum = k
							table.remove(playerlist, k)
						end
					end
					players = players - 1
					--// don't need since playerlist is a reference
					-- session:SetField("playerlist", playerlist)
					session:SetField("players", players)
					if nextuid == uid then --// if the next user quit
						if playerlist[k] then
							nextuid = playerlist[k].uid
							playernum = k
						else
							nextuid = playerlist[1].uid
							playernum = 1
						end
						session:SetField("next", nextuid)
						session:MessageUser(nextuid, playerlist[playernum].nick .. " tippje következik.", true)
						session:MessageUser(nextuid, "Te következel!")
						session:ActualizeActivity( nextuid )
					end
				end
			end
		end
	end
)

aslib:SetListener("ontimer", hangman.appname, "hmtimer",
	function()
		if hangman.nexttimer then
			if os.time() > hangman.nexttimer then
				hangman.nexttimer = os.time() + 15
				local sessions = aslib:GetSessions(hangman.appname)
				local championcount = 0
				for sname, session in pairs(sessions) do
					local gtype = session:GetField("gametype")
					if (gtype == "championship") then
						championcount = championcount + 1
						local nextuid = session:GetField("next")
						if (os.time() > (session:GetActivity(nextuid) + hangman.timeout)) then
							local players = session:GetField("players")
							local playerlist = session:GetField("playerlist")
							local playernum = 0
							local oldnick = ""
							for k in pairs(playerlist) do
								if playerlist[k].uid == nextuid then
									playernum = k
									oldnick = playerlist[k].nick
								end
							end
							playernum = playernum + 1
							if (playernum > players) then
								playernum = 1
							end
							session:SetField("next", playerlist[playernum].uid)
							session:Message("[" .. session:GetField("soltype") .. "]: " .. hangman:GetCurrentString(session))
							session:MessageUser(playerlist[playernum].uid, "Mivel " .. oldnick .. " már régóta nem tippelt, most " .. playerlist[playernum].nick .. " tippje következik.", true)
							session:MessageUser(playerlist[playernum].uid, "Mivel " .. oldnick .. " már régóta nem tippelt, Te következel!")
							session:ActualizeActivity( playerlist[playernum].uid )
						end
					end
				end
				--// No need to check timeouts if no championship running
				if (championcount == 0) then
					hangman.nexttimer = false
				end
			end
		end --// end if hangman.nexttimer
	end	--// end function																	
)

hangman.alphabet1 = hangman:InitializeAlphabet1()
hangman.alphabet2 = hangman:InitializeAlphabet2()
hangman.specials = hangman:InitializeSpecials()
hangman:LoadData()

aslib:Debug( "** Loaded hangman.lua **" )
