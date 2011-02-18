--// WELCOME AND LICENSE //--
--[[
     blackjack.lua -- Version 0.1a
     blackjack.lua -- A BlackJack Game for BCDC++ which utilizes the AS LUA Library.
     blackjack.lua -- Revision: 015/20090415

     Copyright (C) 2008-2009 Szabolcs Molnár <fleet@elitemail.hu>
     
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
		015/20090415: Fixed: The game allowed to set a lower bet than the minimum
		014/20080602: Fixed: When we play out our deck, get a new one
		013/20080529: Fixed: Two multiplayer bugs, don't allow larger bets than the amount of credits
		012/20080522: Modified: Not showing the other players' new cards if no dealer in session
		011/20080520: Modified: Switched bj command parameters order
		010/20080516: Modified: Altered results display format, fixed a few bugs, added option to surrender when we have a dealer
		009/20080515: Modified: In-game commands, Removed sequential playing, Added possibility to play more than one game at once
		008/20080510: Added: If dealer has a natural, only the original bet is lost (not the increased one taken by doubling down)
		007/20080501: ASLib updates
		006/20080426: Added: bet parameter to -bjjoin
		005/20080425: ASLib updates, option for doubling added
		004/20080419: Modified: Some in-game messages
		003/20080418: Added: dealer optional for non-single player games, showing computer as first player when displaying table, sending credits
		002/20080418: Added: rounds optional, hole card, computer plays hard17 by default
		001/20080410: Initial release
]]

dofile( DC():GetAppPath() .. "scripts\\aslib.lua" )

blackjack = {}
blackjack.appname = "BlackJack"
blackjack.scounter = 0
repeat
	blackjack.rseed1 = os.clock()
	blackjack.rseed1 = math.floor((blackjack.rseed1 - math.floor(blackjack.rseed1) ) * 1000)
until (blackjack.rseed1 ~= 0)
blackjack.rseed2 = false
blackjack.rseed = false
blackjack.defaultbet = 10
--// The number of decks in game
blackjack.decks = 2
--// blackjack.dealer is the max number of players which require dealer in their game
--// if the number of required players for a new session exceeds blackjack.dealer, the game won't include computer as a dealer
--// keep it between 1 and 5
blackjack.dealer = 1
--// dealer strategy: h17 or s17
blackjack.strategy = "h17"

blackjack.GetCards = function(this, iter)
	
	local cards = {}
	local cardtypes = {}
	cardtypes[1] = "pikk"
	cardtypes[2] = "treff"
	cardtypes[3] = "káró"
	cardtypes[4] = "kör"
	
	for k in pairs(cardtypes) do
		local tmp = {}
		tmp.name = cardtypes[k] .. " ász"
		tmp.value = 11
		tmp.value2 = 1
		for i = 1, iter do
			table.insert(cards, tmp)
		end
		tmp = {}
		tmp.name = cardtypes[k] .. " dáma"
		tmp.value = 10
		for i = 1, iter do
			table.insert(cards, tmp)
		end
		tmp = {}
		tmp.name = cardtypes[k] .. " király"
		tmp.value = 10
		for i = 1, iter do
			table.insert(cards, tmp)
		end
		tmp = {}
		tmp.name = cardtypes[k] .. " bubi"
		tmp.value = 10
		for i = 1, iter do
			table.insert(cards, tmp)
		end
		for i = 2, 10 do
			tmp = {}
			tmp.name = cardtypes[k] .. " " .. tostring(i)
			tmp.value = i
			for j = 1, iter do
				table.insert(cards, tmp)
			end
		end
	end
	return cards
	
end

blackjack.InitializeRandom = function(this)
	
	-- initialize second part of random seed
	repeat
		local rseed2 = os.clock()
		blackjack.rseed2 = math.floor((rseed2 - math.floor(rseed2) ) * 1000)
	until (blackjack.rseed2 ~= 0)
	blackjack.rseed = blackjack.rseed1 * blackjack.rseed2 * blackjack.rseed2
	math.randomseed( blackjack.rseed )
	return true
	
end

blackjack.Shuffle = function(this)
	
	if not blackjack.rseed then
		blackjack:InitializeRandom()
	end
	
	local shuffled = {}
	local cards = blackjack:GetCards(blackjack.decks)
	
	while( #cards > 0) do
		local rnd = math.random(1, #cards)
		table.insert(shuffled, cards[rnd])
		table.remove(cards, rnd)
	end
	
	return shuffled
	
end

blackjack.RequestGame = function(this, uid, nick, players, bet)
	
	local wecanstart = true
	local playersint = 1
	
	if players then
		local pstring = tostring(players)
		if string.find(pstring, "^[1-5]$") then
			playersint = tonumber(players)
		else
			aslib:Message(uid, "A játékosok száma 1 és 5 közötti egész szám lehet! A játék az álalad megadott paraméterrel nem indítható.")
			wecanstart = false
		end
	end
	
	local betint = blackjack.defaultbet
	if bet then
		if string.find(bet, "^[1-9][0-9]*0$") then
			betint = tonumber(bet)
		else
			aslib:Message(uid, "A minimum tét csak tízzel osztható pozitív egész szám lehet! A játék az álalad megadott paraméterrel nem indítható.")
			wecanstart = false
		end
	end
	
	if wecanstart then
		blackjack.scounter = blackjack.scounter + 1
		local sid = "bj" .. tostring(blackjack.scounter)
		
		--// Creating new session and setting basic info
		local session = aslib:SCreate(sid, blackjack.appname)
		local dealerinf = {}
		session:SetField("players", playersint)
		session:SetField("minimumbet", betint)
		session:SetField("status", "pending")
		session:SetField("dealerinf", dealerinf)
		session:SetField("round", 0)
		
		--// If needed, adding Computer player
		if (playersint <= blackjack.dealer) then
			session:SetField("dealer", true)
			dealerinf.nick = "MZ/X"
			dealerinf.cards = {}
			dealerinf.sum = 0
			dealerinf.status = "playing"
		else
			session:SetField("dealer", false)
		end
		
		--// Shuffling cards
		local shuffled = blackjack:Shuffle()
		session:SetField("cards", shuffled)
		blackjack:JoinUser(uid, nick, sid)
	end --// end if wecanstart
	return true
	
end

blackjack.JoinUser = function(this, uid, nick, requestedsession)
	
	local session = aslib:GetSession(requestedsession)
	
	if not session then
		aslib:Message(uid, "Az álalad megadott játékazonosító alatt nem fut játék!")
	else
		if (session:GetAppName() ~= blackjack.appname) then
			aslib:Message(uid, "Az álalad megadott azonosító alatt " .. session:GetAppName() .. " fut, nem " .. blackjack.appname .. "!")
		else
			local players = session:GetField("players")
			local count = session:UserCount()
			local bet = session:GetField("minimumbet")
			--// If the ingame players exceed the user limit, don't allow to request join
			if (count >= players) then
				aslib:Message(uid, "A játékban egyszerre " .. tostring(players) .. " játékos vehet részt. A játékosok száma (" .. tostring(count) .. ") már elérte a maximálisat.")
			else
				session:JoinUser(uid, nick, "")
				--// Setting up basic player fields
				local user = session:GetUser(uid)
				user:SetField("sum", 0)
				user:SetField("status", "playing")
				user:SetField("cards", {})
				user:SetField("bet", false)
				user:SetField("originalbet", false)
				user:SetField("previousbet", false)
				
				--// requesting userdata makes the session and the user "incomplete" until the data arrives
				session:RequestUserData(uid, "credit")
			end
		end
	end
	return true
	
end

blackjack.CheckCredit = function(this, user, session)
	
	local uid = user:GetUid()
	local cre = tonumber(session:GetUd(uid, "credit"))
	local minimumbet = session:GetField("minimumbet")
	local players = session:GetField("players")
	local nick = session:GetLastNick(uid)
	local sname = session:GetSName()
	
	if (cre < minimumbet) then
		user:Drop("Sajnos csupán " .. tostring(cre) .. " Elite Putákod van, a játék minimum tétje azonban " .. tostring(minimumbet) .. " EP lenne.")
	else
		local count = session:UserCount()
		user:SetField("originalcredit", cre)
		user:SetField("won", 0)
		user:SetField("lost", 0)
		session:MessageUser(uid, "Szeretettel üdvözlünk a játékosok között! Jelenleg " .. tostring(cre) .. " Elite Putákod van. A minimum tét " .. tostring(minimumbet) .. " EP. Rövid ismertetőért írd be: intro")
		session:MessageUser(uid, nick .. " belépett a játékba.", true)
		
		if (session:IsComplete() and (count == players)) then
			--// Change the status to "between" and ask the players to take their bets
			blackjack:GoBetween(session)
		elseif (session:IsComplete() and (count < players)) then
			session:Message("Még " .. tostring(players - count) .. " játékosra várunk...")
		end
		if ((count == 1) and (players > 1)) then
			aslib:Broadcast( nick .. " elindított egy " .. tostring(players) .. " személyes BlackJack játékot. A legkisebb feltehető tét " .. tostring(minimumbet) .. " Elite Puták. Ha csatlakozni szeretnél, írd be nekem privát üzenetként: bjjoin " .. sname )
		end
	end
	return true
	
end

blackjack.DropUser = function(this, user, session, nick)
	
	local ret = false
	local uid = user:GetUid()
	
	local status = session:GetField("status")
	if (status == "pending") then
		ret = user:Drop("Kiléptél a játékból.")
		if ret then
			session:Message(nick .. " kilépett a játékból, mielőtt a többiek megérkeztek volna. Még " .. tostring(session:UserCount()) .. " játékos van az asztalnál.")
		end
	elseif (status == "inprogress") then
		local dealer = session:GetField("dealer")
		local bet = user:GetField("bet")
		--// surrender losts only the half of his bet - only available when we have a delaer
		if dealer then
			bet = bet / 2
		end
		local credit = tonumber(session:GetUd(uid, "credit"))
		
		session:SetUd(uid, "credit", tostring(credit - bet))
		session:SendUserData(uid, "credit", "Sajnos " .. tostring(bet) .. " EP-t vesztettél. Jelenleg " .. tostring(credit) .. " Elite Putákod van.")
		ret = user:Drop("Kiléptél a játékból.")
		if ret then
			local count = session:UserCount()
			session:Message(nick .. " feladta a játékot és kilépett. Még " .. tostring(count) .. " játékos van az asztalnál.")
			session:SetField("players", count)
			if session:GetField("dealer") then
				count = count + 1
			end
			if count < 2 then
				session:Destroy("Sajnos nincs elég játékos az asztalnál a folytatáshoz. A játék véget ért.")
			end
		end
	else --// "between"
		ret = user:Drop("Kiléptél a játékból.")
		if ret then
			session:Message(nick .. " kilépett a játékból.")
			local count = session:UserCount()
			session:SetField("players", count)
			if session:GetField("dealer") then
				count = count + 1
			end
			if count >= 2 then
				blackjack:CheckBetween(session)
			else
				session:Destroy("Sajnos nincs elég játékos az asztalnál a folytatáshoz. A játék véget ért.")
			end
		end
	end
	return ret
	
end

--// returns with a string containing the desk to send to the user(s)
blackjack.GetDesk = function(this, session, force, requester)
	
	local ret = "\n-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n"
	ret = ret .. "   Az asztalon lévő lapok:\n"
	ret = ret .. "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n"
	
	local dealer = session:GetField("dealer")
	
	--// If we have a dealer, take him first
	if dealer then
		local dealerinf = session:GetField("dealerinf")
		local gothc = false
		ret = ret .. "   " .. dealerinf.nick .. ": "
		for cardid, card in ipairs(dealerinf.cards) do
			if card.hc then
				gothc = true
				ret = ret .. "   ??? (?)"
			else
				ret = ret .. "   " .. card.name .. " (" .. card.value .. ")"
			end
		end
		if gothc then
			ret = ret .. "      [?]\n\n"
		else
			ret = ret .. "      [" .. dealerinf.sum .. "]\n\n"
		end
	end
	
	--// Showing living players' cards
	for id, user in pairs(session:GetUsers()) do
		ret = ret .. "   " .. tostring(user:GetField("bet")) .. " EP: " .. user:GetNick() .. ": "
		for cardid, card in ipairs(user:GetField("cards")) do
			if (dealer) or (cardid <= 2) or (force) or (requester == user) then
				ret = ret .. "   " .. card.name .. " (" .. card.value .. ")"
			elseif not dealer then
				ret = ret .. "   ??? (?)"
			end
		end
		if (dealer) or (force) or (requester == user) then
			ret = ret .. "      [" .. user:GetField("sum") .. "]\n"
		else
			ret = ret .. "\n"
		end
	end
	return ret
	
end

--// String containing the results
blackjack.BuildResults = function(this, session, results, dealerinf)
		--// build the string containing the results
		local text = "\n------------------------------------------------------------------------------------------------------------------------------------------\n"
		text = text .. "   Eredmények a(z) " .. session:GetField("round") .. ". osztás után:\n"
		text = text .. "   Nick\t\t\t\tTét\tVált.\tÖssz.\tNyert/Vesztett\n"
		text = text .. " ------------------------------------------------------------------------------------------------------------------------------------------\n"
		
		--// computer
		if dealerinf then
			text = text .. "   A bank: "
			text = text .. dealerinf.nick .. " - ["
				if ((dealerinf.sum == 21) and (#dealerinf.cards == 2)) then
					text = text .. "BJ"
				else
					text = text .. tostring(dealerinf.sum)
				end
			text = text .. "]\n\n"
		end
		
		--// living ones
		for k in ipairs(results.winners) do
			text = text .. "   " .. results.winners[k].nick .. " - ["
			if ((results.winners[k].sum == 21) and (results.winners[k].cards == 2)) then
				text = text .. "BJ"
			else
				text = text .. tostring(results.winners[k].sum)
			end
			text = text .. "]\t\t"
			--// Double down
			if (results.winners[k].originalbet ~= results.winners[k].bet) then
				text = text .. "d"
			end
			text = text .. tostring(results.winners[k].originalbet) .. "\t+" .. tostring(results.winners[k].creditchange) .. "\t"
			text = text .. tostring(tonumber(session:GetUd(results.winners[k].uid, "credit")) - results.winners[k].originalcredit + results.winners[k].creditchange) .. "\t"
			text = text .. tostring(results.winners[k].won) .. "/" .. tostring(results.winners[k].lost) .. "\n"
		end
		
		for k in ipairs(results.pushers) do
			text = text .. "   " .. results.pushers[k].nick .. " - ["
			if ((results.pushers[k].sum == 21) and (results.pushers[k].cards == 2)) then
				text = text .. "BJ"
			else
				text = text .. tostring(results.pushers[k].sum)
			end
			text = text .. "]\t\t"
			--// Double down
			if (results.pushers[k].originalbet ~= results.pushers[k].bet) then
				text = text .. "d"
			end
			text = text .. tostring(results.pushers[k].originalbet) .. "\t0\t"
			text = text .. tostring(tonumber(session:GetUd(results.pushers[k].uid, "credit")) - results.pushers[k].originalcredit) .. "\t"
			text = text .. tostring(results.pushers[k].won) .. "/" .. tostring(results.pushers[k].lost) .. "\n"
		end
		
		for k in ipairs(results.losers) do
			text = text .. "   " .. results.losers[k].nick .. " - [" .. tostring(results.losers[k].sum) .. "]\t\t"
			--// Double down
			if (results.losers[k].originalbet ~= results.losers[k].bet) then
				text = text .. "d"
			end
			text = text .. tostring(results.losers[k].originalbet) .."\t-" .. tostring(results.losers[k].creditchange) .. "\t"
			text = text .. tostring(tonumber(session:GetUd(results.losers[k].uid, "credit")) - results.losers[k].originalcredit - results.losers[k].creditchange) .. "\t"
			text = text .. tostring(results.losers[k].won) .. "/" .. tostring(results.losers[k].lost) .. "\n"
		end
		return text
end

blackjack.RevealHoleCard = function(this, session)
	
	local dealerinf = session:GetField("dealerinf")
	for cardid, card in pairs(dealerinf.cards) do
		if card.hc then
			card.hc = false
		end
	end
	return true
	
end

--// Deal a card then return the name and value of it. hc = hole card: true or false
--// Need to count new card with cardval2 if cardval1 would cause the user to bust.
--// This function also modifies the values of the cards if the player would bust and has a soft hand.
blackjack.DealComputer = function(this, session, hc)
	
	local cardname = false
	local value = false
	
	local cardval1 = false
	local cardval2 = false
	local cards = session:GetField("cards")
	local dealerinf = session:GetField("dealerinf")
	
	if not cards[1] then
		session:Message("Új pakli, keverés...")
		local shuffled = blackjack:Shuffle()
		session:SetField("cards", shuffled)
	end
	
	cardname = cards[1].name
	cardval1 = cards[1].value
	if cards[1].value2 then
		cardval2 = cards[1].value2
	end
	
	--// analyzing new card...
	local tmp = {}
	tmp.name = cardname
	tmp.value = cardval1
	tmp.value2 = cardval2
	
	--// ... counting second value if first value would cause the user to bust
	if cardval2 then
		if (dealerinf.sum + cardval1) > 21 then
			dealerinf.sum = dealerinf.sum + cardval2
			value = cardval2
			tmp.value = cardval2
		else
			dealerinf.sum = dealerinf.sum + cardval1
			value = cardval1
		end
	else
		dealerinf.sum = dealerinf.sum + cardval1
		value = cardval1
	end
	
	--// adding card to user's deck
	table.remove(cards, 1)
	table.insert(dealerinf.cards, tmp)
	
	--// If hole card, set up hc flag
	if hc then
		tmp.hc = hc
	else
		tmp.hc = false
	end
	
	--// Checking deck if busted
	if (dealerinf.sum > 21) then
		for cardid, card in pairs(dealerinf.cards) do
			if (card.value2 and (card.value ~= card.value2)) then
				dealerinf.sum = dealerinf.sum - card.value + card.value2
				card.value = card.value2
				if (dealerinf.sum <= 21) then
					break
				end
			end
		end
	end
	
	return cardname, value
	
end

--// Deal a card then return the name and value of it
--// Need to count new card with cardval2 if cardval1 would cause the user to bust.
--// This function also modifies the values of the cards if the player would bust and has a soft hand.
blackjack.DealPlayer = function(this, session, user)
	
	local cardname = false
	local value = false
	
	local cardval1 = false
	local cardval2 = false
	local deck = session:GetField("cards")
	local cards = user:GetField("cards")
	local sum = user:GetField("sum")
	
	if not deck[1] then
		session:Message("Új pakli, keverés...")
		deck = blackjack:Shuffle()
		session:SetField("cards", deck)
	end
	
	cardname = deck[1].name
	cardval1 = deck[1].value
	if deck[1].value2 then
		cardval2 = deck[1].value2
	end
	
	--// analyzing new card...
	local tmp = {}
	tmp.name = cardname
	tmp.value = cardval1
	tmp.value2 = cardval2
	
	--// ... counting second value if first value would cause the user to bust
	if cardval2 then
		if (sum + cardval1) > 21 then
			sum = sum + cardval2
			value = cardval2
			tmp.value = cardval2
		else
			sum = sum + cardval1
			value = cardval1
		end
	else
		sum = sum + cardval1
		value = cardval1
	end
	user:SetField("sum", sum)
	
	--// adding card to user's deck
	table.remove(deck, 1)
	table.insert(cards, tmp)
	
	--// Checking deck if busted
	if (sum > 21) then
		for cardid, card in pairs(cards) do
			if (card.value2 and (card.value ~= card.value2)) then
				sum = sum - card.value + card.value2
				card.value = card.value2
				if (sum <= 21) then
					break
				end
			end
		end
		user:SetField("sum", sum)
	end
	
	return cardname, value
	
end

blackjack.DecideDealer = function(this, session)
	
	local dealerinf = session:GetField("dealerinf")
	local sname = session:GetSName()
	local softhand = false
	
	--// checking if dealer has a soft hand
	for cardid, card in pairs(dealerinf.cards) do
		--// dealer has a soft hand if any card has a different value2 than the current value
		if (card.value2 and (card.value ~= card.value2)) then
			softhand = true
			break
		end
	end
	
	--// decide whether to deal or not
	if ((dealerinf.sum < 17) or ((dealerinf.sum == 17) and (blackjack.strategy == "h17") and softhand)) then
		
		local cname, cval =  blackjack:DealComputer(session)
		session:Message(dealerinf.nick .. " húzott egy lapot: " .. cname )
		if (dealerinf.sum > 21) then
			dealerinf.status = "lost"
			session:Message(dealerinf.nick .. " besokallt!")
		end
	else
		dealerinf.status = "stopped"
		session:Message(dealerinf.nick .. " megállt!")
	end
	return true
	
end

blackjack.Hit = function(this, user, session, nick)
	
	local status = user:GetField("status")
	local uid = user:GetUid()
	
	if status == "stopped" then
		user:Message("Már korábban megálltál, ilyenkor már nem gondolhatod meg magad!")
	elseif status == "lost" then
		user:Message("Már besokalltál, nem húzhatsz új lapot!")
	elseif status == "surrender" then
		user:Message("Már feladtad a kört, nem húzhatsz új lapot!")
	elseif status == "playing" then
		local dealer = session:GetField("dealer")
		--// deal a new card
		local cname, cval = blackjack:DealPlayer(session, user)
		
		session:MessageUser(uid, "Új lap: " .. cname .. " (" .. tostring(cval) .. ")")
		if dealer then
			session:MessageUser(uid, nick .. " húzott egy lapot: " .. cname .. ".", true)
		else
			session:MessageUser(uid, nick .. " húzott egy lapot.", true)
		end
		
		if (user:GetField("sum") > 21) then
			user:SetField("status", "lost")
			session:MessageUser(uid, "Besokalltál!")
			session:MessageUser(uid, nick .. " besokallt!", true)
		end
	end
	
	--// Verify if we have anyone in game
	blackjack:CheckProgress(session)
	
end

blackjack.Stand = function(this, user, session)
	
	local uid = user:GetUid()
	local status = user:GetField("status")
	
	if status == "playing" then
		user:SetField("status", "stopped")
		session:MessageUser(uid, "Megálltál. Amennyiben még több játékos is van a játékban, kérlek, várd meg őket!")
		session:MessageUser(uid, user:GetNick() .. " megállt!", true)
		blackjack:CheckProgress(session)
	elseif status == "stopped" then
		user:Message("Már korábban megálltál, nem tudsz kétszer kiszállni egy játékból...")
	elseif status == "lost" then
		user:Message("Már besokalltál, ilyenkor késő kiszállni...")
	elseif status == "surrender" then
		user:Message("Ezt a kört már feladtad, megállni már nem tudsz...")
	end
	
end

blackjack.Surrender = function(this, user, session)
	
	local uid = user:GetUid()
	local status = user:GetField("status")
	local dealer = session:GetField("dealer")
	
	if not dealer then
		user:Message("A játékban a bank nem játszik, nincs lehetőséged fél téttel menekülni.")
	elseif status == "playing" then
		user:SetField("status", "surrender")
		session:MessageUser(uid, "Feladtad a kört. Amennyiben még több játékos is van a játékban, kérlek, várd meg őket!")
		session:MessageUser(uid, user:GetNick() .. " feladta a kört!", true)
		blackjack:CheckProgress(session)
	elseif status == "stopped" then
		user:Message("Már korábban megálltál, ilyenkor már nem lehet feladni...")
	elseif status == "lost" then
		user:Message("Már besokalltál, ilyenkor már késő feladni...")
	elseif status == "surrender" then
		user:Message("Ezt a kört már egyszer feladtad...")
	end
	
end

blackjack.Double = function(this, user, session)
	
	local uid = user:GetUid()
	local status = user:GetField("status")
	
	if status == "playing" then
		--// Checking if player has enough credit for doubling
		local bet = user:GetField("bet")
		local cre = tonumber(session:GetUd(uid, "credit"))
		if (cre >= (bet * 2)) then
			bet = bet * 2
			local nick = user:GetNick()
			user:SetField("bet", bet)
			session:MessageUser(uid, "Dupláztál...")
			session:MessageUser(uid, nick .. " duplázott...", true)
			
			--// deal a new card
			local cname, cval = blackjack:DealPlayer(session, user)
			
			session:MessageUser(uid, "A húzott lapod: " .. cname .. " (" .. tostring(cval) .. ")")
			session:MessageUser(uid, nick .. " lapja: " .. cname .. ".", true)
			
			if (user:GetField("sum") > 21) then
				user:SetField("status", "lost")
				session:MessageUser(uid, "Besokalltál!")
				session:MessageUser(uid, nick .. " besokallt!", true)
			else
				user:SetField("status", "stopped")
			end
			blackjack:CheckProgress(session)
		else
			user:Message("Csupán " .. tostring(cre) .. " EP-d van. Ez nem elég ahhoz, hogy megduplázd a téted!")
		end
	elseif status == "stopped" then
		user:Message("Nem duplázhatsz azután, hogy megálltál!")
	elseif status == "lost" then
		user:Message("Nem duplázhatsz, már besokalltál!")
	elseif status == "surrender" then
		user:Message("Nem duplázhatsz azután, hogy feladtad!")
	end
	
end

blackjack.GoBetween = function(this, session)
	--// Set session state: between
	session:SetField("status", "between")
	local minimumbet = session:GetField("minimumbet")
	local anyoneleft = true
	
	--// Remove cards from the users and initialize their bets. Drop user if not enough credit
	if session:GetField("dealer") then
		local dealerinf = session:GetField("dealerinf")
		dealerinf.sum = 0
		dealerinf.status = "playing"
		dealerinf.cards = {}
	end
	for id, user in pairs(session:GetUsers()) do
		user:SetField("bet", false)
		user:SetField("originalbet", false)
		user:SetField("cards", {})
		user:SetField("sum", 0)
		user:SetField("status", "playing")
		
		local credit = tonumber(session:GetUd(user:GetUid(), "credit"))
		if credit < minimumbet then
			local nick = user:GetNick()
			if user:Drop("A jelenlegi játékban a minimum tét " .. tostring(minimumbet) .. " Puták. Neked csupán " .. tostring(credit) .. " EP-d van. Köszönjük az eddigi játékot!") then
				session:Message(nick .. " nem rendelkezik legalább " .. tostring(minimumbet) .. " Putákkal, így nem folytathatja a játékot.")
			else
				anyoneleft = false
			end
		end
	end
	
	--// Check user count. If we have enough players, continue the game
	if anyoneleft then
		local count = session:UserCount()
		if session:GetField("dealer") then
			count = count + 1
		end
		if count >= 2 then
			session:Message("Megkérjük a játékosokat, hogy tegyék meg tétjeiket (folytatás az előző vagy alapértelmezett téttel: c, kilépés: quit)")
		else
			session:Destroy("Sajnos elegendő játékos hiányában nem kezdhetünk új kört. A játék véget ért.")
		end
	end
	
end

blackjack.SetBet = function(this, user, session, bet)
	local uid = user:GetUid()
	if bet == "c" then
		local prev = user:GetField("previousbet")
		if prev then
			local cre = tonumber(session:GetUd(uid, "credit"))
			if prev <= cre then
				user:SetField("bet", prev)
				user:SetField("originalbet", prev)
				session:MessageUser(uid, "A téted: " .. tostring(prev) .. " EP")
				session:MessageUser(uid, user:GetNick() .. " tétje: " .. tostring(prev) .. " EP", true)
			else
				user:Message("Az előző téted " .. tostring(prev) .. " Puták volt. Csupán " .. tostring(cre) .. " Putákkal rendelkezel, adj meg másik tétet!")
			end
		else
			local def = session:GetField("minimumbet")
			user:SetField("bet", def)
			user:SetField("originalbet", def)
			user:SetField("previousbet", def)
			session:MessageUser(uid, "A téted: " .. tostring(def) .. " EP")
			session:MessageUser(uid, user:GetNick() .. " tétje: " .. tostring(def) .. " EP", true)
		end
	else
		local betint = tonumber(bet)
		local minimumbet = session:GetField("minimumbet")
		local cre = tonumber(session:GetUd(uid, "credit"))
		if betint < minimumbet then
			user:Message("A játék minimum tétje " .. tostring(minimumbet) .. ", annál kevesebbet nem tehetsz fel egy körben! Kérünk, adj meg másik tétet!")
		elseif betint <= cre then
			user:SetField("bet", betint)
			user:SetField("originalbet", betint)
			user:SetField("previousbet", betint)
			session:MessageUser(uid, "A téted: " .. tostring(betint) .. " EP")
			session:MessageUser(uid, user:GetNick() .. " tétje: " .. tostring(betint) .. " EP", true)
		else
			user:Message("Csupán " .. tostring(cre) .. " Putákkal rendelkezel, annál többet nem tehetsz fel! Kérünk, adj meg másik tétet!")
		end
	end
	blackjack:CheckBetween(session)
end

--// Transforms the game from "between" to "inprogress" state if all users taken their bets
blackjack.CheckBetween = function(this, session)
	
	local needtransform = true
	for id, user in pairs(session:GetUsers()) do
		if not user:GetField("bet") then
			needtransform = false
		end
	end
	
	if needtransform then
		local users = session:GetUsers()
		local dealer = session:GetField("dealer")
		local round = session:GetField("round") + 1
		session:SetField("round", round)
		session:Message(tostring(round) .. ". kör: osztás " .. tostring(#session:GetField("cards")) .. " lapból...")
		session:SetField("status", "inprogress")
		
		if dealer then
			--// deal two cards for computer, one of them is the hole card
			blackjack:DealComputer(session)
			blackjack:DealComputer(session, true)
		end
		
		--// deal two cards for all other users
		for i, user in pairs(users) do
			blackjack:DealPlayer(session, user)
			blackjack:DealPlayer(session, user)
		end
		
		session:Message(blackjack:GetDesk(session))
		session:Message("Kérjük a játékosokat, hogy játsszák meg a leosztást!")
	end
	
	return true
end

--// Transforms the game from "inprogress" to "between" state
--// verifies if the game has ended. If so, finish computer's game,
--// credit the users then put the session to "between" state
blackjack.CheckProgress = function(this, session)
	
	local dealer = session:GetField("dealer")
	local hasuser = false
	
	for id, user in pairs(session:GetUsers()) do
		if (user:GetField("status") == "playing") then
			hasuser = true
		end
	end
	
	if not hasuser then
		
		--// game is over, do the final jobs...
		
		--// noone's playing. Finish computer game, if any
		if dealer then
			--// Reveal hole card and show desk
			blackjack:RevealHoleCard(session)
			session:Message(blackjack:GetDesk(session))
			
			local dealerinf = session:GetField("dealerinf")
			while (dealerinf.status == "playing") do
				blackjack:DecideDealer(session)
			end
			
		end
		
		--// Showing final state of the desk
		session:Message(blackjack:GetDesk(session, true))
		
		--// Decide who wins the game and credit the points
		
		--// different credit rules if playing with or without dealer
		if dealer then
			
			--// initialize variables
			local round = session:GetField("round")
			local dealerinf = session:GetField("dealerinf")
			local results = {}
			results.winners = {}
			results.pushers = {}
			results.losers = {}
			
			--// build result arrays
			for id, user in pairs(session:GetUsers()) do
					
					local tmp = {}
					tmp.u = user
					tmp.nick = user:GetNick()
					tmp.uid = user:GetUid()
					tmp.sum = user:GetField("sum")
					tmp.cards = #user:GetField("cards")
					tmp.bet = user:GetField("bet")
					tmp.lost = user:GetField("lost")
					tmp.won = user:GetField("won")
					tmp.originalbet = user:GetField("originalbet")
					tmp.originalcredit = user:GetField("originalcredit")
								
					if user:GetField("status") == "surrender" then
						
						--// surrender losts only the half of his bet
						tmp.creditchange = tmp.bet / 2
						tmp.lost = tmp.lost + 1
						table.insert(results.losers, tmp)
						user:SetField("lost", tmp.lost)
						
					elseif user:GetField("status") == "lost" then
						
						--// busted
						--// if dealer has a natural, only the original bet is lost (not lost doubling)
						if ((dealerinf.sum == 21) and (#dealerinf.cards == 2)) then
							tmp.creditchange = tmp.originalbet
							tmp.lost = tmp.lost + 1
							table.insert(results.losers, tmp)
							user:SetField("lost", tmp.lost)
						else
							tmp.creditchange = tmp.bet
							tmp.lost = tmp.lost + 1
							table.insert(results.losers, tmp)
							user:SetField("lost", tmp.lost)
						end
						
					elseif dealerinf.status == "lost" then
						
						--// if dealer is busted, all remaining players win
						tmp.creditchange = tmp.bet
						tmp.won = tmp.won + 1
						table.insert(results.winners, tmp)
						user:SetField("won", tmp.won)
						
					elseif ((dealerinf.sum == 21) and (#dealerinf.cards == 2)) then
					
						--// if dealer has natural, player lost the original bet (not the doubles) until he also has a natural
						if ((tmp.cards == 2) and (tmp.sum == 21)) then
							table.insert(results.pushers, tmp)
						else
							tmp.creditchange = tmp.originalbet
							tmp.lost = tmp.lost + 1
							table.insert(results.losers, tmp)
							user:SetField("lost", tmp.lost)
						end
						
					elseif ((tmp.cards == 2) and (tmp.sum == 21)) then
						
						--// natural pays 3:2 of the original bet unless the dealer has also a natural
						if ((dealerinf.sum == 21) and (#dealerinf.cards == 2)) then
							table.insert(results.pushers, tmp)
						else
							tmp.creditchange = math.floor(tmp.bet * 1.5)
							tmp.won = tmp.won + 1
							table.insert(results.winners, tmp)
							user:SetField("won", tmp.won)
						end
						
					elseif (tmp.sum == dealerinf.sum) then
						
						table.insert(results.pushers, tmp)
						
					elseif (tmp.sum > dealerinf.sum) then
						
						tmp.creditchange = tmp.bet
						tmp.won = tmp.won + 1
						table.insert(results.winners, tmp)
						user:SetField("won", tmp.won)
						
					else
						
						--// if dealer has a natural, only the original bet is lost (don't lost doubling)
						if ((dealerinf.sum == 21) and (#dealerinf.cards == 2)) then
							tmp.creditchange = tmp.originalbet
							tmp.lost = tmp.lost + 1
							table.insert(results.losers, tmp)
							user:SetField("lost", tmp.lost)
						else
							tmp.creditchange = tmp.bet
							tmp.lost = tmp.lost + 1
							table.insert(results.losers, tmp)
							user:SetField("lost", tmp.lost)
						end
						
					end
					
			end --// end build result arrays
			
			--// sending results
			session:Message(blackjack:BuildResults(session, results, dealerinf))
			
			--// sending credits
			for k in pairs(results.winners) do
				local oldcredit = tonumber(session:GetUd(results.winners[k].uid, "credit"))
				local newcredit = tostring(tonumber(oldcredit) + results.winners[k].creditchange)
				session:SetUd(results.winners[k].uid, "credit", newcredit)
				session:SendUserData(results.winners[k].uid, "credit", "Gratulálunk, nyertél! Nyereményed " .. results.winners[k].creditchange .. " EP, így összesen " .. newcredit .. " Elite Putákod van.")
			end
			for k in pairs(results.losers) do
				local oldcredit = tonumber(session:GetUd(results.losers[k].uid, "credit"))
				local newcredit = tostring(tonumber(oldcredit) - results.losers[k].creditchange)
				session:SetUd(results.losers[k].uid, "credit", newcredit)
				session:SendUserData(results.losers[k].uid, "credit", "Sajnos most vesztettél " .. results.losers[k].creditchange .. " EP-t, így összesen " .. newcredit .. " Elite Putákod van.")
			end
			for k in pairs(results.pushers) do
				session:MessageUser(results.pushers[k].uid, "Most döntetlent játszottál, így a feltett " .. tostring(results.pushers[k].bet) .. " EP-t visszakaptad.")
			end
			
		else
			--// initialize variables
			local round = session:GetField("round")
			local results = {}
			results.all = {}
			results.winners = {}
			results.pushers = {}
			results.losers = {}
			local winner = 0
			local prize = 0
			local foundnatural = false
			
			--// build results array containing the results
			for id, user in pairs(session:GetUsers()) do
				local tmp = {}
				tmp.u = user
				tmp.nick = user:GetNick()
				tmp.uid = user:GetUid()
				tmp.sum = user:GetField("sum")
				tmp.cards = #user:GetField("cards")
				tmp.bet = user:GetField("bet")
				tmp.lost = user:GetField("lost")
				tmp.won = user:GetField("won")
				tmp.originalbet = user:GetField("originalbet")
				tmp.originalcredit = user:GetField("originalcredit")
				table.insert(results.all, tmp)
			end
			
			--// order results (desc)
			for k = 1, (#results.all -1) do
				for l = k, #results.all do
					if results.all[l].sum > results.all[k].sum then
						results.all[l], results.all[k] = results.all[k], results.all[l]
					end
				end
			end
			
			--// checking if anyone has natural
			for k in pairs(results.all) do
				if ((results.all[k].sum == 21) and (results.all[k].cards == 2)) then
					foundnatural = true
					winner = 21
				end
			end
			
			--// deciding winning sum and fill losers/winners array
			for k in ipairs(results.all) do
				
				if (results.all[k].sum > 21) then
					
					--// busted
					table.insert(results.losers, results.all[k])
					prize = prize + results.all[k].bet
					
				elseif (results.all[k].sum >= winner) then
					
					if foundnatural then
						if ((results.all[k].sum == 21) and (results.all[k].cards == 2)) then
							table.insert(results.winners, results.all[k])
						else
							table.insert(results.losers, results.all[k])
							prize = prize + results.all[k].bet
						end
					else
						winner = results.all[k].sum
						table.insert(results.winners, results.all[k])
					end
					
				else
					
					table.insert(results.losers, results.all[k])
					prize = prize + results.all[k].bet
					
				end
			end
			
			--// sharing the prize between the winners
			if #results.winners == 0 then
				prize = 0
			else
				prize = math.floor(prize / #results.winners)
				--// pays 3:2 for natural
				if foundnatural then
					prize = math.floor(prize * 1.5)
				end
			end
			
			--// setting up creditchange info on the users
			for k in pairs(results.winners) do
				results.winners[k].creditchange = prize
				if prize > 0 then
					results.winners[k].won = results.winners[k].won + 1
					results.winners[k].u:SetField("won", results.winners[k].won)
				end
			end
			for k in pairs(results.losers) do
				results.losers[k].creditchange = results.losers[k].bet
				results.losers[k].lost = results.losers[k].lost + 1
				results.losers[k].u:SetField("lost", results.losers[k].lost)
			end
			
			session:Message(blackjack:BuildResults(session, results))
			
			--// sending credits
			for k in pairs(results.winners) do
				if prize > 0 then
					local oldcredit = tonumber(session:GetUd(results.winners[k].uid, "credit"))
					local newcredit = tostring(tonumber(oldcredit) + prize)
					session:SetUd(results.winners[k].uid, "credit", newcredit)
					session:SendUserData(results.winners[k].uid, "credit", "Gratulálunk, nyertél! Nyereményed " .. tostring(prize) .. " EP, így összesen " .. newcredit .. " Elite Putákod van.")
				else
					session:MessageUser(results.winners[k].uid, "Mivel döntetlent játszottatok, a téted, ami " .. tostring(results.winners[k].bet) .. " EP, visszakaptad.")
				end
			end
			
			for k in pairs(results.losers) do
				local oldcredit = tonumber(session:GetUd(results.losers[k].uid, "credit"))
				local newcredit = tostring(tonumber(oldcredit) - results.losers[k].bet)
				session:SetUd(results.losers[k].uid, "credit", newcredit)
				session:SendUserData(results.losers[k].uid, "credit", "Sajnos vesztettél " .. tostring(results.losers[k].bet) .. " EP-t, így összesen " .. newcredit .. " Elite Putákod van.")
			end
			
		end
		
		--// After one game ends, let the users choose if they want to continue
		blackjack:GoBetween(session)
		
	end
	return true
	
end

blackjack.Intro = function(this, user)
	local msg = "\n"
	msg = msg .. "BlackJack\n"
	msg = msg .. "----------------------\n\n"
	msg = msg .. "A BlackJack a közismert huszonegyes kaszinó kártyajáték változata. A cél, hogy a nálad lévő lapok összértéke legyen a legnagyobb,\n"
	msg = msg .. "de ne lépje túl a 21-et. A 21 feletti összegű osztásokra mondjuk, hogy \"besokallt\", és ez a feltett tét elvesztésével is jár. A számozott\n"
	msg = msg .. "lapok annyit érnek, amennyi a rajtuk feltüntetett számérték, a király, dáma, bubi 10-et ér, az ász pedig 11-et, kivéve, ha ez azzal járna,\n"
	msg = msg .. "hogy a játékos besokall, mert akkor csak 1-et.\n\n"
	msg = msg .. "A játék menete:\n"
	msg = msg .. "-------------------------\n\n"
	msg = msg .. "A számítógép felkéri a játékosokat, hogy tegyék meg tétjeiket. A feltett tét csak tízzel osztható pozitív szám lehet, és nem lehet kisebb\n"
	msg = msg .. "a játék minimum tétjénél. A minimum tétet a játékot indító játékos határozza meg. A tét megtételéhez nincs másra szükség, mint hogy\n"
	msg = msg .. "a felszólítás után beírd az összeget, számmal. Amennyiben azzal a téttel szeretnéd folytatni a játékot, amivel az előző körben játszottál,\n"
	msg = msg .. "írj a tét helyett csupán egy \"c\" betűt! Amennyiben ez az első kör a játékban, a \"c\" hatására a minimum tét kerül megjátszásra.\n\n"
	msg = msg .. "Miután minden játékos feltette a tétjét, a számítógép mindenkinek oszt két-két lapot, beleértve saját magát is. A bank egyik lapja\n"
	msg = msg .. "lefelé van fordítva, az csak azután kerül felfedésre, hogy minden játékos megjátszotta a leosztást. Az EliteGames BlackJack játékában\n"
	msg = msg .. "két paklinyi lapból kerülnek osztásra a kártyák.\n\n"
	msg = msg .. "Osztás után a játékosok az alábbi parancsok kiadásával választhatnak a lehetőségeik közül:\n\n"
	msg = msg .. "Parancs         Jelentése\n"
	msg = msg .. "--------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n"
	msg = msg .. "hit                   Új lap kérése\n"
	msg = msg .. "stand              Megállás. Ezután a játékos új lapot nem kérhet már\n"
	msg = msg .. "double            A feltett tét megduplázása és pontosan egy új lap kérése. Ezután a játékos nem kérhet új lapot\n"
	msg = msg .. "surrender        Az aktuális kör feladása\n"
	msg = msg .. "quit                 Az aktuális kör feladása, majd kilépés a játékból\n"
	msg = msg .. "table               Megmutatja az asztalon lévő lapokat\n\n"
	msg = msg .. "A kör addig tart, amíg a játékosok meg nem állnak, nem sokallnak be vagy nem dupláznak. Ezután a számítógép kielemzi az eredményeket,\n"
	msg = msg .. "majd lehetőséget teremt új kör lejátszására.\n\n"
	msg = msg .. "Teljes, részletes szabályok:\n"
	msg = msg .. "------------------------------------------\n\n"
	msg = msg .. "A játék teljes leírását a honlapunkon, a http://www.4242.hu/?q=hu/games/blackjack címen találhatod."
	
	user:Message(msg)
end

aslib:SetListener("onmessage", blackjack.appname, "bjmsglistener",
	function(uid, nick, message)
		
		local params = aslib:Tokenize(message)
		
		if params[1] == "bj" then
			blackjack:RequestGame(uid, nick, params[2], params[3])
		elseif params[1] == "bjjoin" then
			if params[2] then
				blackjack:JoinUser(uid, nick, params[2])
			else
				aslib:Message(uid, "A parancs használata: bjjoin <játékazonosító>")
			end
		elseif params[1] == "help" then
			aslib:Message(uid, "[BlackJack] bj [játékosszám] [minimumtét]: Új játék; bjjoin <id>: Belépés már meglévő játékba")
		end
		
	end
)

aslib:SetListener("onsessionmessage", blackjack.appname, "bjsmsglistener",
	function(user, session, nick, message)
		
		local params = aslib:Tokenize(message)
		local status = session:GetField("status")
		
		if status == "pending" then
			if params[1] == "quit" then
				blackjack:DropUser(user, session, nick)
			elseif params[1] == "intro" then
				blackjack:Intro(user)
			elseif params[1] == "help" then
				user:Message("[BlackJack] quit: Kilépés, intro: Rövid ismertető")
			end
		elseif status == "inprogress" then
			if params[1] == "quit" then
				blackjack:DropUser(user, session, nick)
			elseif params[1] == "help" then
				user:Message("[BlackJack] hit: Új lap kérése; double: Duplázás; stand: Megállás; surrender: A kör feladása; quit: Játék feladása és kilépés; table: Asztal mutatása; intro: Rövid ismertető")
			elseif params[1] == "hit" then
				blackjack:Hit(user, session, nick)
			elseif params[1] == "double" then
				blackjack:Double(user, session)
			elseif params[1] == "stand" then
				blackjack:Stand(user, session)
			elseif params[1] == "surrender" then
				blackjack:Surrender(user, session)
			elseif params[1] == "table" then
				user:Message(blackjack:GetDesk(session, false, user))
			elseif params[1] == "intro" then
				blackjack:Intro(user)
			end
		else --// "between"
			if params[1] == "quit" then
				blackjack:DropUser(user, session, nick)
			elseif params[1] == "c" or string.find(params[1], "^[1-9][0-9]*0$") then
				blackjack:SetBet(user, session, params[1])
			elseif params[1] == "help" then
				user:Message("[BlackJack] Megteheted a tétedet, vagy c: Folytatás az előző/alapértelmezett téttel; quit: Kilépés; intro: Rövid ismertető")
			elseif params[1] == "intro" then
				blackjack:Intro(user)
			elseif string.find(params[1], "^[1-9]+$") then
				user:Message("A tét csak tízzel osztható szám lehet!")
			end
		end
		

		
	end
)

aslib:SetListener("onuserdata", blackjack.appname, "bjudlistener",
	function(user, session, variable, value)
		
		if (variable == "credit") then
			--// Need to check if credit is enough for playing. If not, drop the user
			blackjack:CheckCredit(user, session)
		end
		
	end
)

aslib:SetListener("onquit", blackjack.appname, "bjquitlistener",
	function(uid, sname, nick)
		
		local session = aslib:GetSession(sname)
		if session then
			local count = session:UserCount()
			local status = session:GetField("status")
			
			if status == "inprogress" or status == "between" then
				session:SetField("players", count)
			end
			
			session:Message(nick .. " kilépett a hubról. Még " .. tostring(count) .. " játékos van az asztalnál.")
			if session:GetField("dealer") then
				count = count + 1
			end
			if count < 2 then
				session:Destroy("Sajnos nincs elég játékos az asztalnál a folytatáshoz. A játék véget ért.")
			end
		end
		
	end
)

aslib:Debug( "** Loaded blackjack.lua **" )