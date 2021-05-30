minetest.register_globalstep(function()
	minetest.settings:set("time_speed", "0")
end)

minetest.register_globalstep(function()
	minetest.set_timeofday(0.5)
end)
