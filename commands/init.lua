minetest.override_chatcommand("admin", {
	  func = function(name)
        minetest.chat_send_player(name, "Owners of the server are: DiamondPlane, Elvis26, gameit.")
	end
})
