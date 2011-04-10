--// announce_topic.lua

local function AnnounceTopic(nick)
  -- string10: hub topic
  -- string21: hub security nick
  local topic = SetMan.GetString(10)
  local hubSecurity = SetMan.GetString(21)
  
  if nick then
    Core.SendToNick(nick, "<" .. hubSecurity .. "> The hub topic is set to: " .. topic)
  else
    Core.SendToAll("<" .. hubSecurity .. "> The hub topic is set to: " .. topic)
  end
end

function UserConnected(tUser)
  -- string10: hub topic
  local topic = SetMan.GetString(10)
  -- the previous command returns nil when no topic is set
  if topic then
    AnnounceTopic(tUser.sNick)
  end
  return false
end

function RegConnected(tUser)
  return UserConnected(tUser)
end

function OpConnected(tUser)
  return UserConnected(tUser)
end