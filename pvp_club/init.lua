-- configuration
local mt = minetest
local ms = mt.get_mod_storage()
PVP = {}
PVP.players = {}
PVP.team_chat_enabled = {}
PVP.team_colors = {
    blue = "#0000FF",
    yellow = "#FFFF00",
    green = "#64f20b"
}
PVP.teams = {
    blue = {"TenPlusTwo", "Darkf4antom", "KitoCat", "AnthonyDe", "SoulSeeker", "JediKnight", "Panquesito7", "Koda_", "Gladius"},
    yellow = {"-lipop-", "minetest", "j45", "RUBIUSOMG11", "cephalotus", "Amine35", "realyg", "popidog_assaillant", "Elyas_Crack"},
    green = {"Elvis26", "DiamondPlane", "gameit", "end", "Skyisblue", "-CrocMoney-", "N4xQ", "LuaFrank"}
}
PVP.spawn = {
    r = 20,
    h = 20,
    immunity_time = 12, --time in seconds
    pos = {
        x = 1516,
        y = 20,
        z = -28536
    },
}

local dead_players = {}
local immune_players = {}

for team, p_table in pairs(PVP.teams) do
    for index, member in pairs(p_table) do
        table.insert(PVP.players, member)
    end
end

-- Spawn immunity
minetest.register_globalstep(function(dtime)
    for name, ctime in pairs(immune_players) do
        immune_players[name] = math.max((ctime or 0)-dtime, 0)
        if immune_players[name] == 0 then
            minetest.chat_send_player(name, "Your immunity has ended!")
            immune_players[name] = nil
        end
    end
end)

-- Chat coloring
mt.format_chat_message = function(name, message)
    if PVP.team_chat_enabled[name] == true then
        for index, member in pairs(PVP.teams[PVP.get_team(name)]) do
            minetest.chat_send_player(member, mt.colorize(PVP.team_color(member), "<" ..name .. "> " .. message))
        end
        return ""
    else
	    return mt.colorize(PVP.team_color(name), "<" ..name .. "> ") .. message
    end
end

-- Name tag coloring
local owners = {"DiamondPlane", "gameit", "Elvis26"}
minetest.register_on_joinplayer(function(player, n)
    for team, p_table in pairs(PVP.teams) do
        for index, member in pairs(p_table) do
            if player:get_player_name() == member then
                local is_owner = false
                for i=1, #owners do
                    if owners[i] == member then
                        is_owner = true
                        i = #owners + 1
                    end
                end
                local props = {
                    color = PVP.team_color(member),
                    text = member
                }
                if is_owner then
                    props.text = props.text.." (Owner)"
                end
                player:set_nametag_attributes(props)
                immune_players[player:get_player_name()] = PVP.spawn.immunity_time
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
    return nil
end

function PVP.team_color(name)
    return PVP.team_colors[PVP.get_team(name)]
end

function is_inside_spawn(pos)
	if pos.x < PVP.spawn.pos.x + PVP.spawn.r
	and pos.x > PVP.spawn.pos.x - PVP.spawn.r
	and pos.y < PVP.spawn.pos.y + PVP.spawn.h
	and pos.y > PVP.spawn.pos.y - PVP.spawn.h
	and pos.z < PVP.spawn.pos.z + PVP.spawn.r
	and pos.z > PVP.spawn.pos.z - PVP.spawn.r then
		return true
	end
	return false
end

--minetest. Registering
mt.register_on_respawnplayer(function(player)
	dead_players[player:get_player_name()] = nil
    immune_players[player:get_player_name()] = PVP.spawn.immunity_time
    return true
end)

--PvP logistics
mt.register_on_punchplayer(function (victim,attacker,time_from_last_punch,tool_capabilities,dir, damage)
    if victim and attacker and table.indexof(dead_players, victim) < 1 then
        local a_name = attacker:get_player_name()
        local v_name = victim:get_player_name()

        if dead_players[v_name] then
            return true
        end

        if is_inside_spawn(victim:get_pos()) then
            minetest.chat_send_player(a_name, "No pvp at spawn!")
            return true
        end

        if PVP.get_team(a_name) == PVP.get_team(v_name) then
            minetest.chat_send_player(a_name, minetest.colorize(PVP.team_color(v_name),v_name).." is on your team!")
            return true
        end
        if immune_players[v_name] then
            minetest.chat_send_player(a_name, minetest.colorize(PVP.team_color(v_name),v_name).." has just respawned!")
            return true
        end
        if immune_players[a_name] then
            minetest.chat_send_player(a_name, "Your immunity has ended!")
            immune_players[a_name] = nil
        end
        local victim_hp = victim:get_hp()
        if victim_hp == 0 then
            return false
        end

        if victim_hp - damage <= 0 then
            dead_players[v_name] = true

            -- Kill History
            mt.chat_send_all(
                mt.colorize(PVP.team_color(a_name), a_name)..
                mt.colorize("#FF0000", " has killed ")..
                mt.colorize(PVP.team_color(v_name), v_name)
            )
            return false
        end
        victim:set_hp(victim_hp - damage)
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
                return true, "Player "..mt.colorize(PVP.team_color(name),name).." has "..kills.." kills."
            elseif table.indexof(PVP.players, param) >= 1 then
                local kills = tonumber(ms:get_string(param.."kills")) or 0
                return true, "Player "..mt.colorize(PVP.team_color(param),param).." has "..kills.." kills."
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
                return true, "Player "..mt.colorize(PVP.team_color(name),name).." has "..deaths.." deaths."
            elseif table.indexof(PVP.players, param) >= 1 then
                local deaths = tonumber(ms:get_string(param.."deaths")) or 0
                return true, "Player "..mt.colorize(PVP.team_color(param),param).." has "..deaths.." deaths."
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

mt.register_chatcommand("rplayer", {
    privs = {
        server = true,
    },
    description = "Used to clear player stats. /rplayer <name>",
    func = function(name, param)
        if param == "" then
            return true, "Try: \n/rplayer <name>"
        end
        if PVP.get_team(param) then
            ms:set_string(param.."kills", 0)
            ms:set_string(param.."deaths", 0)
            return true, param.."'s stats have been reset."
        end
        return true, "["..param.."] is not a player!"
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
            minetest.colorize(PVP.team_colors[team], "["..team.." team] = "..players_str))
         end
     })
end
