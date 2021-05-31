-- configuration
local mt = minetest
local ms = mt.get_mod_storage()
PVP = {}
PVP.players = {}
PVP.team_colors = {
    test = "#FFFFFF",
    blue = "#0000FF",
    yellow = "#FFFF00",
    green = "#64f20b",
    red = "#e32727",
    aqua = "#00f1ff"
}
PVP.teams = {
    test = {"Test1"},
    red = {"clownwolf", "FranzJoseph", "Beta", "Rtx", "-cigarette-", "kitty02", "Elvis26", "danicoo", "Liberty45"},
    blue = {"TenPlusTwo", "Darkf4antom", "AnthonyDe", "SoulSeeker", "JediKnight", "Gladius", "Xenon", "5uper1ach", "PantsMan"},
    yellow = {"-lipop-", "minetest", "j45", "RUBIUSOMG11", "cephalotus", "Amine35", "realyg", "popidog_assaillant", "Elyas_Crack", "Luis_Mi"},
    green = {"DiamondPlane", "gameit", "end", "Skyisblue", "-CrocMoney-", "N4xQ", "LuaFrank", "Code-Sploit", "winniepee0", "The_World"},
    aqua = {"Elvis26", "liverpool"}
}
PVP.spawn = {
    r = 20,
    h = 20,
    immunity_time = 12, --time in seconds
    pos = {
        x = 1841,
        y = 2,
        z = -1061
    },
}

function table.includes(tab, val)
    return table.indexof(tab, val) >= 1
end

local dead_players = {}
local immune_players = {}
local respawn_message = {}

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
	    return mt.colorize(PVP.team_color(name), "<" ..name .. "> ") .. message
end

-- Name tag coloring
local owners = {"DiamondPlane", "gameit", "Elvis26"}
mt.register_on_joinplayer(function(player, n)
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
                    props.text = props.text..mt.colorize("#d88119", " (Owner)")
                end
                player:set_nametag_attributes(props)
                immune_players[player:get_player_name()] = PVP.spawn.immunity_time
                minetest.after(0,function(player)
                    player:hud_set_hotbar_image("pvp_club_hotbar_"..PVP.get_team(player:get_player_name())..".png")
                    player:hud_set_hotbar_selected_image("pvp_club_hotbar_selected_"..PVP.get_team(player:get_player_name())..".png")
                end,player)
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

local function is_inside_spawn(pos)
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
    local name = player:get_player_name()
	dead_players[name] = nil
    immune_players[name] = PVP.spawn.immunity_time
    if respawn_message[name] then
        mt.chat_send_all(respawn_message[name])
        respawn_message[name] = nil
    end
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
            minetest.chat_send_player(a_name, "PvP at the spawn is disabled!")
            return true
        end

        if PVP.get_team(a_name) == PVP.get_team(v_name) then
            minetest.chat_send_player(a_name, minetest.colorize(PVP.team_color(v_name),v_name).." is on your team!")
            return true
        end
        if immune_players[v_name] then
            minetest.chat_send_player(a_name, minetest.colorize(PVP.team_color(v_name),v_name).." has just (re)spawned!")
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
        end
        victim:set_hp(victim_hp - damage)
    end
end)

--chat commands
minetest.register_on_newplayer(function (player)
    local name = player:get_player_name()
    ms:set_string(name.."kills", tostring(0))
    ms:set_string(name.."deaths", tostring(0))
    ms:set_string(name.."score", tostring(0))
end)

mt.register_on_dieplayer(function (player, reason)
    if reason.type == "punch" then
        local kills = tonumber(ms:get_string(reason.object:get_player_name().."kills")) or 0
        local deaths = tonumber(ms:get_string(player:get_player_name().."deaths")) or 0
	local score = tonumber(ms:get_string(reason.object:get_player_name().."score")) or 0
        ms:set_string(reason.object:get_player_name().."kills", tostring(kills + 1))
        ms:set_string(player:get_player_name().."deaths", tostring(deaths + 1))
	ms:set_string(reason.object:get_player_name().."score", tostring(score + 10))
	mt.chat_send_all(mt.colorize(PVP.team_color(reason.object:get_player_name()), reason.object:get_player_name())..mt.colorize("#FF0000", " has killed ")..mt.colorize(PVP.team_color(player:get_player_name()), player:get_player_name()))
    else
        local deaths = tonumber(ms:get_string(player:get_player_name().."deaths")) or 0
        ms:set_string(player:get_player_name().."deaths", tostring(deaths + 1))
    end
end)

mt.register_chatcommand("tchat", {
    privs = {
        interact = true,
    },
    func = function(name, param)
	for index, member in pairs(PVP.teams[PVP.get_team(name)]) do
		minetest.chat_send_player(member, mt.colorize(PVP.team_color(member), "[Team] <" ..name .. "> " .. param))
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
            ms:set_string(param.."kills", tostring(0))
            ms:set_string(param.."deaths", tostring(0))
	    ms:set_string(param.."score", tostring(0))
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

mt.register_on_joinplayer(function (player)
    player:set_properties({
        hp_max = 60,
    })
    player:set_hp(60)
end)

mt.register_on_respawnplayer(function (player)
    player:set_properties({
        hp_max = 60,
    })
    player:set_hp(60)
end)

minetest.register_chatcommand("stats", {
    privs = {
        interact = true,
    },
    func = function (name, param)
        if param ~= ("" or nil) then

            if not table.includes(PVP.players, param) then
                return true,"Invalid player name."
            end

            local kills = tostring(0)
            local deaths = tostring(0)
            local score = tostring(0)

            if ms:get_string(param.."kills") ~= "" or ms:get_string(param.."kills") ~= nil then
                kills = ms:get_string(param.."kills")
            end
            if ms:get_string(param.."deaths") ~= "" or ms:get_string(param.."deaths") ~= nil then
                deaths = ms:get_string(param.."deaths")
            end
            if ms:get_string(param.."score") ~= "" or ms:get_string(param.."score") ~= nil then
                score = ms:get_string(param.."score")
            end

            return minetest.chat_send_player(name, "Stats of "..minetest.colorize(PVP.team_color(param), param).." are:\nKills: "..kills.."\nDeaths: "..deaths.."\nScore: "..score)
        end

        local kills = tostring(0)
        local deaths = tostring(0)
        local score = tostring(0)

        if ms:get_string(name.."kills") ~= (nil or "") then
            kills = ms:get_string(name.."kills")
        end
        if ms:get_string(name.."deaths") ~= (nil or "") then
            deaths = ms:get_string(name.."deaths")
        end
        if ms:get_string(name.."score") ~= (nil or "") then
            score = ms:get_string(name.."score")
        end

        minetest.chat_send_player(name, "Stats of "..minetest.colorize(PVP.team_color(name), name).." are:\nKills: "..kills.."\nDeaths: "..deaths.."\nScore: "..score)
    end
});
