--[[
ANTISWEAR
]]--

local badwords = {}
local worldpath = minetest.get_worldpath()

if worldpath then
	worldpath = worldpath .. "/"
end

local badword_file = "badwords.txt"

local function load_badwords()
	local full_path = worldpath .. badword_file

	local file = io.open(full_path, "r")

	for line in file:lines() do
		table.insert(badwords, line)
	end
end

load_badwords()

minetest.register_privilege("canswear", {
	description = "Can swear in game chat",
	give_to_singleplayer = false,
	give_to_admin = false
})

minetest.register_on_chat_message(function(name, message)
	local has_canswear = minetest.check_player_privs(name, {canswear = true})

	if has_canswear then return end

	load_badwords()

	for badword in pairs(badwords) do
		if string.find(message, string.sub(badword, 0, string.len(badword) - 1)) then
			minetest.chat_send_player(name, minetest.colorize("#FF0000", "No swearing!"))

			return true
		end
	end
end)

minetest.register_globalstep(function()
	if badwords == {} then
		load_badwords()
	end
end)
