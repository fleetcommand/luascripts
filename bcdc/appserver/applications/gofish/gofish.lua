--// WELCOME AND LICENSE //--
--[[
     gofish.lua -- Version 0.1a
     gofish.lua -- The traditional "Go Fish" card game for BCDC++ which utilizes the AS LUA Library.
     gofish.lua -- Revision: 004/20080827

     Copyright (C) 2008 Szabolcs Molnár <fleet@elitemail.hu>
     
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
		004/20080827: Fixed: A bug wich caused lua error when the computer makes a book
		003/20080601: Fixed: A bug when joining a second user to the game
		002/20080516: Added some computer strategy
		001/20080512: Initial release
]]

dofile( DC():GetAppPath() .. "scripts\\aslib.lua" )

gofish = {}
gofish.appname = "GoFish"
gofish.scounter = 0
--// Game difficulty (0-10)
gofish.difficulty = 8
--// It's the prize for every book (if won)
gofish.defaultprize = 30
repeat
	gofish.rseed1 = os.clock()
	gofish.rseed1 = math.floor((gofish.rseed1 - math.floor(gofish.rseed1) ) * 1000)
until (gofish.rseed1 ~= 0)
gofish.rseed2 = false
gofish.rseed = false

gofish.GetCards = function(this)
	
	local cards = {}
	
	for i = 1, 4 do
		local tmp = {}
		tmp.name = "A"
		tmp.value = 1
		table.insert(cards, tmp)
		tmp = {}
		tmp.name = "K"
		tmp.value = 13
		table.insert(cards, tmp)
		tmp = {}
		tmp.name = "Q"
		tmp.value = 12
		table.insert(cards, tmp)
		tmp = {}
		tmp.name = "J"
		tmp.value = 11
		table.insert(cards, tmp)
		for j = 2, 10 do
			tmp = {}
			tmp.name = tostring(j)
			tmp.value = j
			table.insert(cards, tmp)
		end
	end
	return cards
	
end

gofish.Shuffle = function(this)
	
	local shuffled = {}
	local cards = gofish:GetCards()
	
	while( #cards > 0) do
		local rnd = math.random(1, #cards)
		table.insert(shuffled, cards[rnd])
		table.remove(cards, rnd)
	end
	
	return shuffled
	
end

gofish.Draw = function(this, session, uid)

	local book = false
	--// Get session cards
	local cards = session:GetField("cards")
	
	--// Get the user cards
	local usercards = false
	local userbooks = false
	
	if uid == "computer" then
		usercards = session:GetField("ccards")
		userbooks = session:GetField("cbooks")
	else
		local user = session:GetUser(uid)
		usercards = user:GetField("cards")
		userbooks = user:GetField("books")
	end
	
	--// Give the first one to the user
	local tmp = {}
	tmp.name = cards[1].name
	tmp.value = cards[1].value
	table.insert(usercards, tmp)
	table.remove(cards, 1)
	
	--// Order cards ascending
	for i = 1, #usercards do
		for j = (i+1), #usercards do
			if usercards[j].value < usercards[i].value then
				usercards[i], usercards[j] = usercards[j], usercards[i]
			end
		end
	end
	
	--// Check for books
	local counter = 0
	local tested = 0
	for i = 1, #usercards do

		if usercards[i].value ~= tested then
			tested = usercards[i].value
			counter = 1
		else
			counter = counter + 1
		end
		if counter == 4 then
			local newbook = {}
			newbook.name = usercards[i].name
			newbook.value = usercards[i].value
			table.insert(userbooks, newbook)
			book = usercards[i].name
		end
	end
	
	--// Remove booked cards from hand
	for i in pairs(userbooks) do
		local j = 1
		while(j <= #usercards) do
			if usercards[j].value == userbooks[i].value then
				table.remove(usercards, j)
				j = j - 1
			end
			j = j + 1
		end
	end
	
	--// Order books ascending
	for i = 1, #userbooks do
		for j = (i+1), #userbooks do
			if userbooks[j].value < userbooks[i].value then
				userbooks[i], userbooks[j] = userbooks[j], userbooks[i]
			end
		end
	end
	
	return tmp.name, book
end

gofish.Move = function(this, session, uid, victimuid, cardname)

	local book = false
	local moved = 0
	
	--// Get the user cards
	local usercards = false
	local userbooks = false
	
	if uid == "computer" then
		usercards = session:GetField("ccards")
		userbooks = session:GetField("cbooks")
	else
		local user = session:GetUser(uid)
		usercards = user:GetField("cards")
		userbooks = user:GetField("books")
	end
	
	--// Get Victim cards
	local victimcards = false
	
	if victimuid == "computer" then
		victimcards = session:GetField("ccards")
	else
		local victim = session:GetUser(victimuid)
		victimcards = victim:GetField("cards")
	end
	
	--// Card to move
	local tmp = {}
	tmp.name = ""
	tmp.value = 0
	
	--// Count how many cards the opponent have
	for i in pairs(victimcards) do
		if victimcards[i].name == cardname then
			moved = moved + 1
			if moved == 1 then
				tmp.name = victimcards[i].name
				tmp.value = victimcards[i].value
			end
		end
	end
	
	--// Remove the cards from the opponent
	local i = 1
	while (i <= #victimcards) do
		if victimcards[i].name == cardname then
			table.remove(victimcards, i)
			i = i - 1
		end
		i = i + 1
	end
	
	--// Give the cards for the one who asked for
	for i = 1, moved do
		table.insert(usercards, tmp)
	end
	
	--// Order cards ascending
	for i = 1, #usercards do
		for j = (i+1), #usercards do
			if usercards[j].value < usercards[i].value then
				usercards[i], usercards[j] = usercards[j], usercards[i]
			end
		end
	end
	
	--// Check for books
	local counter = 0
	local tested = 0
	
	for i = 1, #usercards do
		
		if usercards[i].value ~= tested then
			tested = usercards[i].value
			counter = 1
		else
			counter = counter + 1
		end
		if counter == 4 then
			local newbook = {}
			newbook.name = usercards[i].name
			newbook.value = usercards[i].value
			table.insert(userbooks, newbook)
			book = usercards[i].name
		end
	end
	
	--// Remove booked cards from hand
	for i in pairs(userbooks) do
		local j = 1
		while(j <= #usercards) do
			if usercards[j].value == userbooks[i].value then
				table.remove(usercards, j)
				j = j - 1
			end
			j = j + 1
		end
	end
	
	--// Order books ascending
	for i = 1, #userbooks do
		for j = (i+1), #userbooks do
			if userbooks[j].value < userbooks[i].value then
				userbooks[i], userbooks[j] = userbooks[j], userbooks[i]
			end
		end
	end
	
	return moved, book
end

gofish.Intro = function(this, user)
	local msg = "\n"
	msg = msg .. " Go Fish!\n"
	msg = msg .. "----------------\n\n"
	msg = msg .. "A Go Fish egy hagyományos gyermek kártyajáték változata. A cél, hogy a játékosok összegyűjtsék az egyfoma értékű lapokat.\n"
	msg = msg .. "Ha valaki megszerez négy egyforma értékű lapot, akkor azokat összerakja könyvvé majd leteszi a kezéből. A játék akkor ér véget,\n"
	msg = msg .. "ha legalább az egyik játékos kezéből elfogynak a kártyák. A nyertes az, akinek több könyve van.\n\n"
	msg = msg .. " Szabályok\n"
	msg = msg .. "-------------------\n\n"
	msg = msg .. "Kezdéskor a számítógép mindkét játékosnak oszt hét-hét lapot, majd a játékosok elkezdenek egymástól lapokat kérni. Például az\n"
	msg = msg .. "éppen soron következő játékos tőled csak olyan lapot kérhet, amilyennel ő maga is rendelkezik. Ha a kért lapból legalább egy a\n"
	msg = msg .. "kezedben van, az összeset oda kell adnod a társadnak, majd újra ő következik. Ha nem lenne nálad egy sem a kért lapból, azt mondod:\n"
	msg = msg .. "\"Menj horgászni!\", ami annyit tesz, hogy a társad húz egy lapot. Ha kihúzza az általa előzőleg kért lapot, újra ő kérhet, különben pedig\n"
	msg = msg .. "te következel.\n\n"
	msg = msg .. "Ha összegyűlik egy könyv négy egyforma kártyából, azt a paklitól külön kell tárolni. A játék akkor ér véget, ha az egyik játékos\n"
	msg = msg .. "kezéből elfogynak a kártyák. A nyertes az lesz, akinek több összegyűjtött könyve van.\n\n"
	msg = msg .. "  A játék menete\n"
	msg = msg .. "----------------------------\n\n"
	msg = msg .. "A hét-hét lapot a számítógép automatikusan kiosztja, majd véletlenszerűen eldönti, hogy ki kezd. Ha két ember játszik egymással,\n"
	msg = msg .. "akkor a játékot indító játékos kezd. Lap kéréséhez csupán be kell írni az értékét: \"A\", \"2\", \"3\", \"4\", \"5\", \"6\", \"7\", \"8\", \"9\", \"10\",\n"
	msg = msg .. "\"J\", \"Q\", \"K\".\n\n"
	msg = msg .. " Egyéb parancsok:\n"
	msg = msg .. " Parancs         Jelentése\n"
	msg = msg .. "-------------------------------------------------------------------------------------------------------------------\n"
	msg = msg .. " s                     Megmutatja, hogy hány lapja és könyve van a társadnak\n"
	msg = msg .. " quit                 Kilépés a játékból\n\n"
	msg = msg .. " Teljes, részletes szabályzat:\n"
	msg = msg .. "----------------------------------------------\n\n"
	msg = msg .. "A játék teljes leírását a honlapunkon, a http://www.4242.hu/hu/games/fish címen találhatod.\n"
	user:Message(msg)
	return true
end

gofish.InitializeRandom = function(this)
	repeat
		local rseed2 = os.clock()
		gofish.rseed2 = math.floor((rseed2 - math.floor(rseed2) ) * 1000)
	until (gofish.rseed2 ~= 0)
	gofish.rseed = gofish.rseed1 * gofish.rseed2 * gofish.rseed2
	math.randomseed( gofish.rseed )
	return true
end

gofish.StartGame = function(this, uid, nick, players)

	--// Init
	if not gofish.rseed then
		gofish:InitializeRandom()
	end
	
	local maxplayers = 1
	
	if (players and string.find(players, "^[12]$")) then
		maxplayers = tonumber(players)
	elseif players then
		aslib:Message(uid, "fish: érvénytelen paraméter: " .. players .. ". A játékosok száma 1 vagy 2 lehet!")
		return false
	end
	
	gofish.scounter = gofish.scounter + 1
	local sname = "gf" .. tostring(gofish.scounter)
	local session = aslib:SCreate(sname, gofish.appname)
	local msg = "Szeretettel köszöntünk!"
	local current = uid
	if maxplayers == 1 then
		
		--// If single player game, chose randomly who starts
		if math.random(1, 2) == 2 then
			msg = msg .. " Ezt a játékot én kezdem."
			current = "computer"
		else
			msg = msg .. " Ezt a játékot te kezdheted!"
		end
		
		msg = msg .. " Rövid ismertetőhöz írd be: intro"
		session:SetField("status", "inprogress")
		session:SetField("ccards", {})
		session:SetField("cbooks", {})
		session:SetField("mystrat", {})
		
	else
		
		msg = msg .. " A játék elindításához még várunk egy felhasználóra."
		aslib:Broadcast( nick .. " elindított egy kétszemélyes Go Fish! játékot. Ha szeretnél játszani, írd be nekem privát üzenetként: fishjoin " .. sname )
		session:SetField("status", "pending")
		
	end
	
	local shuffled = gofish:Shuffle()
	session:SetField("cards", shuffled)
	session:SetField("maxplayers", maxplayers)
	session:SetField("current", current)
	session:JoinUser(uid, nick, msg)
	session:RequestUserData(uid, "credit")
	local user = session:GetUser(uid)
	user:SetField("cards", {})
	user:SetField("books", {})
	
	if maxplayers == 1 then
		--// Deal 7 cards for each. We are going to be honest, so deal separately for both users
		for i = 1, 7 do
			gofish:Draw(session, uid)
		end
		gofish:ShowHand(session, uid)
		
		for i = 1, 7 do
			gofish:Draw(session, "computer")
		end
		if current == "computer" then
			gofish:VerifySession(session)
		else
			user:Message("Mit szeretnél kérni?")
		end
	end
	
	return true
end

gofish.JoinUser = function(this, uid, nick, sname)
	local session = aslib:GetSession(sname)
	if session then
		if (session:GetAppName() == gofish.appname) then
			if session:GetField("status") == "pending" then
				
				local current = session:GetField("current")
				local firstuser = session:GetUser(current)
				session:JoinUser(uid, nick, "Szeretettel köszöntünk! Rövid ismertetőhöz írd be: intro")
				session:MessageUser(uid, nick .. " belépett a játékba. Mivel mindketten megvagytok, a játék elkezdődik.", true)
				session:SetField("status", "inprogress")
				
				--// Set up empty hand for our new user
				local user = session:GetUser(uid)
				user:SetField("cards", {})
				user:SetField("books", {})
				
				--// Deal 7 cards for each. We are going to be honest, so deal separately for both users
				for id, victim in pairs(session:GetUsers()) do
					local uid = victim:GetUid()
					for i = 1, 7 do
						gofish:Draw(session, uid)
					end
					gofish:ShowHand(session, uid)
					if current == uid then
						victim:Message("Mit szeretnél kérni?")
					end
				end
				
			else
				aslib:Message(uid, "fishjoin: Sajnálom, de a játék már elkezdődött, így nem csatlakozhatsz.")
			end
		else
			aslib:Message(uid, "fishjoin: érvénytelen azonosító: " .. sname .. ". Nem csatlakozhatsz, mert nem Go Fish! játék fut benne!")
		end
	else
		aslib:Message(uid, "fishjoin: érvénytelen azonosító: " .. sname .. ". Nem létezik vagy nem Go Fish! fut benne.")
	end
	return true
end

gofish.AskFor = function(this, user, session, cardname)
	local current = session:GetField("current")
	local status = session:GetField("status")
	local uid = user:GetUid()
	if status == "inprogress" then
		if (uid == current) then
			local cardname = string.upper(cardname)
			if string.find(cardname, "^[AQKJ23456789]$") or cardname == "10" then
				
				--// Check if the user has any of this card
				local havecard = false
				local cards = user:GetField("cards")
				for i in pairs(cards) do
					if cards[i].name == cardname then
						havecard = true
					end
				end
				
				if havecard then
					--// Check if the other player has it
					--// ... Actually, the other player can be the computer too
					if session:GetField("maxplayers") == 1 then
						local mystrat = session:GetField("mystrat")
						local othercards = session:GetField("ccards")
						-- user:Message("A következőt kérted: " .. cardname)
						local moved, book = gofish:Move(session, uid, "computer", cardname)
						
						--// To let the computer play smart:
						if not mystrat[cardname] then
							mystrat[cardname] = {}
							mystrat[cardname].risk = 1
							mystrat[cardname].draws = 0
						end
						if mystrat[cardname].risk > 0 then
							mystrat[cardname].risk = mystrat[cardname].risk + moved
							mystrat[cardname].draws = 0
						else
							mystrat[cardname].risk = moved + 1
							mystrat[cardname].draws = 0
						end
						
						if moved > 0 then
							local msg = tostring(moved) .. " lapom volt a következőből: " .. cardname .. "."
							if book then
								msg = msg .. " Csináltál egy könyvet: " .. book .. "."
							end
							user:Message(msg)
							gofish:ShowHand(session, uid)
							user:Message("Mit szeretnél kérni?")
						else
							user:Message("Azt mondom: \"Menj horgászni!\"")
							local newcard, newbook = gofish:Draw(session, uid)
							if newcard == cardname then
								--// If the user gets the asked card, increase the risk
								mystrat[newcard].risk = mystrat[newcard].risk + 1
								
								local msg = "Kihúztad a kért lapot (" .. newcard .. "), újra te kérhetsz."
								if newbook then
									msg = msg .. " Csináltál egy könyvet: " .. newbook .. "."
								end
								user:Message(msg)
								gofish:ShowHand(session, uid)
								user:Message("Mit szeretnél kérni?")
							else
								--// Increase the unkonwn draws' counter
								for k in pairs(mystrat) do
									mystrat[k].draws = mystrat[k].draws + 1
								end
								
								session:SetField("current", "computer")
								local msg = "Az alábbi lapot húztad: " .. newcard .. "."
								if newbook then
									msg = msg .. " Csináltál egy könvet: " .. newbook .. "."
								end
								user:Message(msg)
							end
							
						end
						
					else
						local otherone = false
						for otheruid, remoteuser in pairs(session:GetUsers()) do
							if remoteuser:GetUid() ~= uid then
								otherone = remoteuser
							end
						end
						local othercards = otherone:GetField("cards")
						local otheruid = otherone:GetUid()
						-- user:Message("A következőt kérted: " .. cardname)
						otherone:Message(user:GetNick() .. " a következőt kérte: " .. cardname)
						local moved, book = gofish:Move(session, uid, otheruid, cardname)
						if moved > 0 then
							local msg = "Átadtál " .. tostring(moved) .. " lapot."
							if book then
								msg = msg .. " " .. user:GetNick() .. " csinált egy könyvet: " .. book .. "."
							end
							otherone:Message(msg)
							
							msg = otherone:GetNick() .. " " .. tostring(moved) .. " " .. cardname .. " lapot adott át."
							if book then
								msg = msg .. " Csináltál egy könyvet: " .. book .. "."
							end
							user:Message(msg)
							gofish:ShowHand(session. uid)
							otherone:Message("Mit szeretnél kérni?")
						else
							user:Message(otherone:GetNick() .. " azt mondja: \"Menj horgászni!\"")
							otherone:Message("Azt mondod: \"Menj horgászni!\"")
							local newcard, newbook = gofish:Draw(session, uid)
							if newcard == cardname then
								
								local msg = "Kihúztad a kért lapot: " .. newcard .. "."
								if newbook then
									msg = msg .. " Csináltál egy könyvet " .. newbook .. "."
								end
								msg = msg .. " Újra te kérhetsz!"
								user:Message(msg)
								
								msg = user:GetNick() .. " kihúzta a kért lapot."
								if newbook then
									msg = msg .. " Csinált egy könyvet: " .. newbook .. "."
								end
								msg = msg .. " Újra ő kérhet!"
								otherone:Message(msg)
								
								gofish:ShowHand(session, uid)
								user:Message("Mit szeretnél kérni?")
							else
								local msg = "Az alábbi lapot húztad: " .. newcard .. "."
								if newbook then
									msg = msg .. " Csináltál egy könyvet " .. newbook .. "."
									otherone:Message(user:GetNick() .. " csinált egy könyvet: " .. newbook .. ".")
								end
								msg = msg .. " " .. otherone:GetNick() .. " következik!"
								user:Message(msg)
								
								session:SetField("current", otheruid)
								gofish:ShowHand(session. otheruid)
								otherone:Message("Mit szeretnél kérni?")
							end
							
						end
					end
					
					gofish:VerifySession(session)
					
				else
					user:Message("Nincs egyáltalán nálad " .. cardname .. ". Kérj újat!")
				end
			else
				user:Message("Érvénytelen kártya: " .. cardname .. ". Kérlek, add meg a kért kártyát újra!")
			end
		else
			local otherone = session:GetUser(current)
			user:Message("Most " .. otherone:GetNick() .. " következik, légyszíves várd ki a sorod!")
		end
	else
		user:Message("A játék még nem kezdődött el. Várd meg a második játékost!")
	end
end

gofish.DropUser = function(this, user, session, nick)
	local maxplayers = session:GetField("maxplayers")
	user:Drop("Kiléptél a játékból.")
	if maxplayers == 2 then
		session:Destroy(nick .. " feladta, így sajnos vége a játéknak.")
	end
	return true
end

gofish.ShowHand = function(this, session, uid)
	
	--// Note that uid must be a real uid, no sense to show hands for the computer
	
	local user = session:GetUser(uid)
	local usercards = user:GetField("cards")
	local userbooks = user:GetField("books")
	local msg = "A lapjaid:"
	
	if #usercards > 0 then
		for i = 1, #usercards do
			msg = msg .. " " .. usercards[i].name
		end
	else
		msg = msg .. " semmi"
	end
	
	for i = 1, #userbooks do
		if i == 1 and #userbooks == 1 then
			msg = msg .. " + Az alábbi könyv:"
		elseif i == 1 then
			msg = msg .. " + Az alábbi könyvek:"
		end
		msg = msg .. " " .. userbooks[i].name
	end
	
	user:Message(msg)
	
	return true
end

gofish.ShowStatus = function(this, session, user)
	
	local uid = user:GetUid()
	local maxplayers = session:GetField("maxplayers")
	local cards = session:GetField("cards")
	local msg = ""
	if maxplayers == 1 then
		--// Status of the computer
		local ucards = session:GetField("ccards")
		local ubooks = session:GetField("cbooks")
		msg = tostring(#ucards) .. " lap"
		for i = 1, #ubooks do
			if i == 1 and #ubooks == 1 then
				msg = msg .. " + Az alábbi könyv:"
			elseif i == 1 then
				msg = msg .. " + Az alábbi könyvek:"
			end
			msg = msg .. " " .. ubooks[i].name
		end
		msg = msg .. " van a kezemben, " .. tostring(#cards) .. " pedig a pakliban."
	else
		--// Status of the other user
		for id, otherone in pairs(session:GetUsers()) do
			if otherone:GetUid() ~= uid then
				local ucards = otherone:GetField("cards")
				local ubooks = otherone:GetField("books")
				msg = otherone:GetNick() .. " kezében " .. tostring(#ucards) .. " lap"
				for i = 1, #ubooks do
					if i == 1 and #ubooks == 1 then
						msg = msg .. " + Az alábbi könyv:"
					elseif i == 1 then
						msg = msg .. " + Az alábbi könyvek:"
					end
					msg = msg .. " " .. ubooks[i].name
				end
				msg = msg .. " van, a pakliban pedig " .. tostring(#cards) .. "."
			end
		end
	end
	user:Message(msg)
	
	return true
end

gofish.VerifySession = function(this, session)
	
	local maxplayers = session:GetField("maxplayers")
	
	--// First check if we have a computer next
	if maxplayers == 1 and session:GetField("current") == "computer" then
		--// I think it's my turn :)
		local myturn = true
		
		--// Find the victim
		local victim = false
		for id, user in pairs(session:GetUsers()) do
			--// There's no need to verify anything: there is only a single living player
			victim = user
		end
		local victimuid = victim:GetUid()
		repeat
			
			--// OK, first chose a card to ask for
			local mycards = session:GetField("ccards")
			local mystrat = session:GetField("mystrat")
			local cardtoask = false
			local rnd1 = math.random(1, 10)
			local rnd2 = math.random(1, 10) * rnd1 / 10
			
			if gofish.difficulty >= rnd1 then
				local lastrisk = 0
				local lastdraw = 0
				-- session:Message("###: Diff")
				--// Search my cards for those the opponent already asked for
				for cname in pairs(mystrat) do
					for i in pairs(mycards) do
						if mycards[i].name == cname then
							-- session:Message("###: We have " .. cname)
							if gofish.difficulty >= rnd2 then
								-- session:Message("###: Check for risk/draw")
								--// We have this one. Check for risk and draws since last ask
								if mystrat[cname].risk > lastrisk then
									cardtoask = cname
									lastrisk = mystrat[cname].risk
									lastdraw = mystrat[cname].draws
								elseif mystrat[cname].risk == lastrisk then
									if mystrat[cname].draws > lastdraw then
										cardtoask = cname
										lastdraw = mystrat[cname].draws
									end
								end
							else
								-- session:Message("###: Not checking for risk")
								cardtoask = cname
							end
						end
					end
				end
				--// If lastrisk is 0 then rather chose a random card
				if lastrisk == 0 then
					-- session:Message("###: Getting random card since last risk is 0, lastdraw is " .. tostring(lastdraw))
					cardtoask = false
				end
			end
			
			--// If we didn't chose a card yet, chose randomly
			if not cardtoask then
				cardtoask = mycards[math.random(1, #mycards)].name
			end
			
			victim:Message("Az alábbi lapot kérem tőled: " .. cardtoask)
			local moved, book = gofish:Move(session, "computer", victimuid, cardtoask)
			if moved > 0 then
				local msg = tostring(moved) .. " ilyen lapod van."
				if book then
					msg = msg .. " Csináltam egy könyvet: " .. book .. "."
				end
				victim:Message(msg)
				
				--// Computer strategy
				if not mystrat[cardtoask] then
					mystrat[cardtoask] = {}
				end
				mystrat[cardtoask].risk = 0
				mystrat[cardtoask].draws = 0
				
				--// Do we have any cards remaining?
				if #mycards == 0 then
					myturn = false
				end
			else
				victim:Message("Azt mondod: \"Menj horgászni!\"")
				
				--// Computer strategy
				if not mystrat[cardtoask] then
					mystrat[cardtoask] = {}
				end
				mystrat[cardtoask].risk = 0
				mystrat[cardtoask].draws = 0
				
				--// Draw another card
				local newcard, newbook = gofish:Draw(session, "computer")
				if newcard == cardtoask then
					local msg = "Kihúztam a kért lapot, megint én kérek."
					if newbook then
						msg = msg .. " Csináltam egy könyvet: " .. newbook .. "."
					end
					victim:Message(msg)
					
					--// Do we have any cards remaining?
					if #mycards == 0 then
						myturn = false
					end
				else
					myturn = false
					session:SetField("current", victimuid)
					gofish:ShowHand(session, victimuid)
					victim:Message("Mit szeretnél kérni?")
				end
			end
		until (myturn == false)
	end
	
	--// Now check if any player has an empty hand
	local wearethere = false
	for id, user in pairs(session:GetUsers()) do
		local ucards = user:GetField("cards")
		if #ucards == 0 then
			wearethere = true
			user:Message("Nincs több lap a kezedben.")
			session:MessageUser(user:GetUid(), "Nincs több lap " .. user:GetNick() .. " kezében.", true)
		end
	end
	
	--// Check if the computer has empty hand
	if ((wearethere == false) and (maxplayers == 1)) then
		local ucards = session:GetField("ccards")
		if #ucards == 0 then
			wearethere = true
			--// Exactly one user
			for id, user in pairs(session:GetUsers()) do
				user:Message("Nincs több lap a kezemben.")
			end
		end
	end

	--// If one of the players has an empty hand, the game has ended
	if wearethere then
		local winnerid = ""
		local winnervalue = 0
		local results = {}
		
		--// Fill the results table
		for id, user in pairs(session:GetUsers()) do
			local tmp = {}
			tmp.uid = user:GetUid()
			tmp.nick = user:GetNick()
			tmp.books = #user:GetField("books")
			table.insert(results, tmp)
			if tmp.books > winnervalue then
				winnervalue = tmp.books
				winnerid = tmp.uid
			elseif tmp.books == winnervalue then
				winnerid = "tie"
			end
		end
		if maxplayers == 1 then
			local tmp = {}
			tmp.uid = "computer"
			tmp.books = #session:GetField("cbooks")
			table.insert(results, tmp)
			if tmp.books > winnervalue then
				winnervalue = tmp.books
				winnerid = tmp.uid
			elseif tmp.books == winnervalue then
				winnerid = "tie"
			end
		end
		
		--// winnerid can be "tie", "computer" or uid
		if winnerid == "tie" then
			if maxplayers == 1 then
				session:Message("Mindkettőnknek " .. tostring(winnervalue) .. " könyve van: döntetlen.")
			else
				session:Message("Mindkettőtöknek " .. tostring(winnervalue) .. " könyve van: döntetlen.")
			end
		elseif winnerid == "computer" then
			--// Find the living player first
			for id, user in pairs(session:GetUsers()) do
				session:Message("Nekem " .. tostring(winnervalue) .. ", neked " .. tostring(#user:GetField("books")) .. " könyved van: ezt a játékot én nyertem.")
			end
		else
			--// Notice the user that he won the game and credit some points
			if maxplayers == 1 then
				session:Message("Neked " .. tostring(winnervalue) .. ", nekem " .. tostring(#session:GetField("cbooks")) .. " könyvem van: ezt a játékot te nyerted!")
			else
				local msg = "Az eredmény:"
				local first = true
				for id, user in pairs(session:GetUsers()) do
					if first then
						first = false
					else
						msg = msg .. ","
					end
					msg = msg .. " " .. user:GetNick() .. ": " .. tostring(user:GetField("books"))
				end
				msg = msg .. " könyv."
				for id, user in pairs(session:GetUsers()) do
					if user:GetUid() == winnerid then
						user:Message(msg .. " Ezt a játékot te nyerted!")
					else
						user:Message(msg .. " Sajnos most nem nyertél.")
					end
				end
			end
			local prize = winnervalue * gofish.defaultprize
			if session:IsUserComplete(winnerid) then
				local credit = tonumber(session:GetUd(winnerid, "credit"))
				credit = credit + prize
				session:SetUd(winnerid, "credit", tostring(credit))
				session:SendUserData(winnerid, "credit", "A nyereményed " .. tostring(prize) .. " Elite Puták, így most összesen " .. tostring(credit) .. " Putákod van. Gratulálunk!")
			else
				session:MessageUser(winnerid, "Sajnos nem tudjuk, mennyi Putákod van, így a nyereményed, ami " .. tostring(prize) .. " EP lenne, nem tudjuk jóváírni.")
			end
		end
		
		local msg = "A játék véget ért."
		if maxplayers == 1 then
			msg = "Köszönöm a játékot!"
		end
		session:Destroy(msg)
		
	end
	
end

aslib:SetListener("onmessage", gofish.appname, "gfmsglistener",
	function(uid, nick, message)
		
		local params = aslib:Tokenize(message)
		
		if params[1] == "fish" then
			gofish:StartGame(uid, nick, params[2])
		elseif params[1] == "fishjoin" then
			if params[2] then
				gofish:JoinUser(uid, nick, params[2])
			else
				aslib:Message(uid, "fishjoin: hiányzó paraméter. A parancs használata: -gfjoin <játékazonosító>")
			end
		elseif params[1] == "help" then
			aslib:Message(uid, "[GoFish] fish [játékosszám]: Új játék; fishjoin <id>: Belépés már meglévő játékba")
		end
		
	end
)

aslib:SetListener("onsessionmessage", gofish.appname, "gfsmsglistener",
	function(user, session, nick, message)
		
		local params = aslib:Tokenize(message)

		if params[1] == "intro" then
			gofish:Intro(user)
		elseif params[1] == "s" then
			gofish:ShowStatus(session, user)
		elseif params[1] == "quit" then
			gofish:DropUser(user, session, nick)
		elseif params[1] == "help" then
			user:Message("[GoFish] intro: Rövid ismertető; s: Másik játékos állása; quit: Kilépés a játékból")
		else
			gofish:AskFor(user, session, params[1])
		end
		
	end
)

--[[
aslib:SetListener("onuserdata", gofish.appname, "gfudlistener",
	function(user, session, variable, value)
		
		if (variable == "credit") then
			user:Message("Jelenleg " .. value .. " Elite Putákod van.")
		end
		
	end
)
]]

aslib:SetListener("onquit", gofish.appname, "gfquitlistener",
	function(uid, sname, nick)
		
		local session = aslib:GetSession(sname)
		if session then
			local maxplayers = session:GetField("maxplayers")
			if maxplayers == 2 then
				session:Destroy(nick .. " kilépett a hubról, így sajnos a játék félbeszakadt.")
			end
		end
		
	end
)

aslib:Debug( "** Loaded gofish.lua **" )