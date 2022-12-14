
-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S = minetest.get_translator and minetest.get_translator("inventory_plus") or
		dofile(MP .. "/intllib.lua")

-- static spawn position
local statspawn = minetest.string_to_pos(minetest.settings:get("static_spawnpoint"))
		or {x = 0, y = 12, z = 0}

local home_gui = {}

-- get_formspec
home_gui.get_formspec = function(player)

	local formspec = "size[6,2]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "button[0,0;2,0.5;main;" .. S("Back") .. "]"
		.. "button_exit[0,1.5;2,0.5;home_gui_set;" .. S("Set Home") .. "]"
		.. "button_exit[2,1.5;2,0.5;home_gui_go;Go " .. S("Home") .. "]"
		.. "button_exit[4,1.5;2,0.5;home_gui_spawn;" .. S("Spawn") .. "]"

	local home = sethome.get( player:get_player_name() )

	if home then
		formspec = formspec
			.."label[2.5,-0.2;" .. S("Home set to:") .. "]"
			.."label[2.5,0.4;".. minetest.pos_to_string(vector.round(home)) .. "]"
	end

	return formspec
end

-- add inventory_plus page when player joins
minetest.register_on_joinplayer(function(player)
	inventory_plus.register_button(player, "home_gui", S("Home Pos"))
end)

-- what to do when we press da buttons
minetest.register_on_player_receive_fields(function(player, formname, fields)

	local privs =  minetest.get_player_privs(player:get_player_name()).home

	if privs and fields.home_gui_set then
		sethome.set(player:get_player_name(), player:get_pos())
	end

	if privs and fields.home_gui_go then
		sethome.go(player:get_player_name())
	end

	if privs and fields.home_gui_spawn then
		player:set_pos(statspawn)
	end

	if fields.home_gui or fields.home_gui_set or fields.home_gui_go then
		inventory_plus.set_inventory_formspec(player, home_gui.get_formspec(player))
	end
end)

-- spawn command
minetest.register_chatcommand("spawn", {
	description = S("Go to Spawn"),
	privs = {home = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		player:set_pos(statspawn)
	end,
})
