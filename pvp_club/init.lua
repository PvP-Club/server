-- configuration
local mt = minetest
local hunter = nil
local prey = nil
local ms = mt.get_mod_storage()

-- server metadata
local players = {"TenPlusTwo","realyg","Darkf4antom","smugler5","Elvis26","DiamondPlane","end","gameit", "-lipop-", "minetest","j45", "RUBIUSOMG11"}
local teams = {
    blue = {"TenPlusTwo", "realyg", "Darkf4antom", "smugler5"},
    yellow = {"-lipop-", "minetest", "j45", "RUBIUSOMG11"},
    green = {"Elvis26", "DiamondPlane", "gameit", "end"}
}

--blue team color
ms:set_string("TenPlusTwoc", "#0000FF")
ms:set_string("realygc", "#0000FF")
ms:set_string("Darkf4antom","#0000FF")
ms:set_string("smugler5c", "#0000FF")

--yellow team color
ms:set_string("-lipop-c", "#FFFF00")
ms:set_string("minetestc", "#FFFF00")
ms:set_string("j45c", "#FFFF00")
ms:set_string("RUBIUSOMG11c", "#FFFF00")

--grean team color
ms:set_string("Elvis26c" , "#00FF3C")
ms:set_string("DiamondPlanec", "#00FF3C")
ms:set_string("gameitc", "#00FF3C")
ms:set_string("endc", "#00FF3C")

minetest.register_on_prejoinplayer(function(name)
        if table.indexof(players, name) >= 1 then
            mt.log("Welcome ".. name.."!")
            else
            return "Sorry, this is a private server!"
        end
 end)

-- Kill History
mt.register_on_dieplayer(function (player, reason)
    if reason.object ~= nil then
        hunter = reason.object:get_player_name()
        prey = player:get_player_name()
        if ms:get_string(hunter.."c") then
            mt.chat_send_all(mt.colorize(ms:get_string(hunter.."c"), hunter)..mt.colorize("#FF0000", " has killed ")..mt.colorize(ms:get_string(prey.."c"), prey)) 
        end
        hunter = nil
        prey = nil
    end
end)

mt.register_on_punchplayer(function (player, hitter,time_from_last_punch,tool_capabilities,dir, damage)
    if table.indexof(teams.blue, player:get_player_name()) >= 1 then
        if table.indexof(teams.blue, hitter:get_player_name()) >= 1 then
            local php = player:get_hp()
            player:set_hp(php + damage)
        end
    end
end)

mt.register_on_punchplayer(function (player, hitter,time_from_last_punch,tool_capabilities,dir, damage)
    if table.indexof(teams.yellow, player:get_player_name()) >= 1 then
        if table.indexof(teams.yellow, hitter:get_player_name()) >= 1 then
            local php = player:get_hp()
            player:set_hp(php + damage)
        end
    end
end)

mt.register_on_punchplayer(function (player, hitter,time_from_last_punch,tool_capabilities,dir, damage)
    if table.indexof(teams.green, player:get_player_name()) >= 1 then
        if table.indexof(teams.green, hitter:get_player_name()) >= 1 then
            local php = player:get_hp()
            player:set_hp(php + damage)
        end
    end
end)
