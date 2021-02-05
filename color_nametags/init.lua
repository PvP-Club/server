local greens = {"DiamondPlane", "Elvis26", "gameit", "end", "Skyisblue"}

minetest.register_on_joinplayer(function(player)
  for _, n in pairs(greens) do
    if player:get_player_name() == n then
      player:set_nametag_attributes({color = "#00ff3c"})
      break
    end
  end
end)

local blues = {"Darkf4antom", "TenPlusTwo", "realyg", "smugler5", "KitoCat"}

minetest.register_on_joinplayer(function(player)
  for _, n in pairs(blues) do
    if player:get_player_name() == n then
      player:set_nametag_attributes({color = "#0000FF"})
      break
    end
  end
end)

local yellows = {"j45", "-lipop-", "RUBIUSOMG11", "minetest", "cephalotus"}

minetest.register_on_joinplayer(function(player)
  for _, n in pairs(yellows) do
    if player:get_player_name() == n then
      player:set_nametag_attributes({color = "#FFFF00"})
      break
    end
  end
end)
