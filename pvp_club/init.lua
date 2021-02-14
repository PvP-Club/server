-- configuration
mt = minetest
ms = mt.get_mod_storage()
PVP = {}
PVP.players = {}
PVP.team_chat_enabled = {}
PVP.team_colours = {
    blue = "#0000FF",
    yellow = "#FFFF00",
    green = "#64f20b"
}
PVP.teams = {
    blue = {"TenPlusTwo", "realyg", "Darkf4antom", "KitoCat", "AnthonyDe", "SoulSeeker", "JediKnight", "Panquesito7"},
    yellow = {"-lipop-", "minetest", "j45", "RUBIUSOMG11", "cephalotus", "Amine35", "realyg"},
    green = {"Elvis26", "DiamondPlane", "gameit", "end", "Skyisblue", "-CrocMoney-", "N4xQ", "LuaFrank"}
}

local dead_players = {}

for team, p_table in pairs(PVP.teams) do
    for index, member in pairs(p_table) do
        table.insert(PVP.players, member)
    end
end

-- Chat coloring
mt.format_chat_message = function(name, message)
    if PVP.team_chat_enabled[name] == true then
        for index, member in pairs(PVP.teams[PVP.get_team(name)]) do
            minetest.chat_send_player(member, mt.colorize(PVP.team_colour(member), "<" ..name .. "> " .. message))
        end
        return ""
    else
	    return mt.colorize(PVP.team_colour(name), "<" ..name .. "> ") .. message
    end
end

-- Name tag coloring
minetest.register_on_joinplayer(function(player)
    for team, p_table in pairs(PVP.teams) do
        for index, member in pairs(p_table) do
            if player:get_player_name() == member then
                player:set_nametag_attributes({color = PVP.team_colour(member)})
                return
            end
        end
    end
end)

--Private Server
mt.register_on_prejoinplayer(function(name)
    if table.indexof(PVP.players, name) >= 1 then
        mt.log("Welcome ".. name.."!")
    else
        return "You are not whitelisted! Ask for add you to whitelist in discord: https://discord.com/invite/C2AuTuRSEb"
    end
 end)

 --Helper functions
function PVP.get_team(p_name)
    for team, p_table in pairs(PVP.teams) do
        if table.indexof(p_table, p_name) > 0 then
            return tostring(team)
        end
    end
end

function PVP.team_colour(name)
    return PVP.team_colours[PVP.get_team(name)]
end

--minetest. Registering
mt.register_on_respawnplayer(function(player)
	dead_players[player:get_player_name()] = nil
end)

--PvP logistics
mt.register_on_punchplayer(function (victim,attacker,time_from_last_punch,tool_capabilities,dir, damage)
    if victim and attacker and table.indexof(dead_players, victim) < 1 then
        local a_name = attacker:get_player_name()
        local v_name = victim:get_player_name()

        if dead_players[v_name] then
            return true
        end

        if PVP.get_team(a_name) ~= PVP.get_team(v_name) then
            local victim_hp = victim:get_hp()
            if victim_hp == 0 then
                return false
            end

            if victim_hp - damage <= 0 then
                dead_players[v_name] = true

                -- Kill History
                mt.chat_send_all(
                    mt.colorize(PVP.team_colour(a_name), a_name)..
                    mt.colorize("#FF0000", " has killed ")..
                    mt.colorize(PVP.team_colour(v_name), v_name)
                )
                return false
            end
            victim:set_hp(victim_hp - damage)
        end
        return true
    end
end)

--chat commands
minetest.register_on_newplayer(function (player)
    local name = player:get_player_name()
    ms:set_string(name.."kills", tostring(0))
    ms:set_string(name.."deaths", tostring(0))
end)

mt.register_on_dieplayer(function (player, reason)
    if reason.type == "punch" then
        local kills = tonumber(ms:get_string(reason.object:get_player_name().."kills")) or 0
        local deaths = tonumber(ms:get_string(player:get_player_name().."deaths")) or 0
        ms:set_string(reason.object:get_player_name().."kills", tostring(kills + 1))
        ms:set_string(player:get_player_name().."deaths", tostring(deaths + 1))
    elseif reason.type == "fall" then
        local deaths = tonumber(ms:get_string(player:get_player_name().."deaths")) or 0
        ms:set_string(player:get_player_name().."deaths", tostring(deaths + 1))
    end
end)

mt.register_chatcommand("kills", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        if param ~= nil then
            if param == "" then
                local kills = tonumber(ms:get_string(name.."kills")) or 0
                return true, "Player "..mt.colorize(PVP.team_colour(name),name).." has "..kills.." kills."
            elseif table.indexof(PVP.players, param) >= 1 then
                local kills = tonumber(ms:get_string(param.."kills")) or 0
                return true, "Player "..mt.colorize(PVP.team_colour(param),param).." has "..kills.." kills."
            end
            return true, "No such player called "..param.."."
        end
    end
})

mt.register_chatcommand("deaths", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        if param ~= nil then
            if param == "" then
                local deaths = tonumber(ms:get_string(name.."deaths")) or 0
                return true, "Player "..mt.colorize(PVP.team_colour(name),name).." has "..deaths.." deaths."
            elseif table.indexof(PVP.players, param) >= 1 then
                local deaths = tonumber(ms:get_string(param.."deaths")) or 0
                return true, "Player "..mt.colorize(PVP.team_colour(param),param).." has "..deaths.." deaths."
            else
                return true, "No such player called "..param.."."
            end
        end
    end
})

mt.register_chatcommand("tchat", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        if param ~= nil then
            if PVP.team_chat_enabled[name] then
                PVP.team_chat_enabled[name] = nil
                return true, "Team chat disabled"
            else
                PVP.team_chat_enabled[name] = true
                return true, "Team chat enabled"
            end
        end
    end
})

for team, p_table in pairs(PVP.teams) do
    mt.register_chatcommand("t"..team, {
        description = "You can look "..team.." team players.",
        func = function(name)
            local players_str = ""
            for index, member in pairs(p_table) do
                players_str = players_str .. member
                if index < #p_table then
                    players_str = players_str .. ", "
                end
            end
            minetest.chat_send_player(name,
            minetest.colorize(PVP.team_colours[team], "["..team.." team] = "..players_str))
         end
     })
end

-- Owners
local owners = {"DiamondPlane", "gameit", "Elvis26"}

minetest.register_on_joinplayer(function(player, n)
  for _, n in pairs(owners) do
    if player:get_player_name() == n then
      player:set_nametag_attributes({text = "" .. n .. " (Owner)"})
     end
  end
 end)
