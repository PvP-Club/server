minetest.override_chatcommand("admin", {
	  func = function(name)
        minetest.chat_send_player(name, "Admins of the server are: DiamondPlane, Elvis26, gameit and AnthonyDe.")
	end
})
