--[[

Inventory Plus for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-inventory_plus
License: BSD-3-Clause https://raw.github.com/cornernote/minetest-inventory_plus/master/LICENSE

Edited by TenPlus1 (23rd March 2016)

]]--

-- expose api
inventory_plus = {}

-- define buttons
inventory_plus.buttons = {}

-- default inventory page
inventory_plus.default = minetest.setting_get("inventory_default") or "craft"

-- should we use small 2x2 crafting grid?
inventory_plus.small_craft = true

-- register_button
inventory_plus.register_button = function(player, name, label)

	local player_name = player:get_player_name()

	if inventory_plus.buttons[player_name] == nil then
		inventory_plus.buttons[player_name] = {}
	end

	inventory_plus.buttons[player_name][name] = label
end

-- set_inventory_formspec
inventory_plus.set_inventory_formspec = function(player, formspec)

	 -- error checking
	if not formspec then
		return
	end

	if minetest.setting_getbool("creative_mode") then

		-- if creative mode is on then wait a bit
		minetest.after(0.01,function()
			player:set_inventory_formspec(formspec)
		end)
	else
		player:set_inventory_formspec(formspec)
	end
end

-- create detached inventory for trashcan
local trashInv = minetest.create_detached_inventory("trash", {

	on_put = function(inv, toList, toIndex, stack, player)
		inv:set_stack(toList, toIndex, ItemStack(nil))
	end
})

trashInv:set_size("main", 1)

-- get_formspec
inventory_plus.get_formspec = function(player, page)

	if not player then
		return
	end

	-- default inventory page
	local formspec = "size[8,7.5]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "list[current_player;main;0,3.5;8,4;]"

	-- craft page
	if page == "craft" then

		local inv = player:get_inventory() or nil

		if not inv then
			print ("NO INVENTORY FOUND")
			return
		end

		formspec = formspec
			.. "button[0,1;2,0.5;main;Back]"
			.. "list[current_player;craftpreview;7,1;1,1;]"

		if inventory_plus.small_craft == true then
			formspec = formspec .. "list[current_player;craft;3,0;2,2;]"
		else
			formspec = formspec .. "list[current_player;craft;3,0;3,3;]"
		end

		formspec = formspec .. "listring[current_name;craft]"
			.. "listring[current_player;main]"
			-- trash icon
			.. "list[detached:trash;main;1,2;1,1;]"
			.. "image[1.1,2.1;0.8,0.8;creative_trash_icon.png]"
	end

	-- creative page
	if page == "creative" then

		return player:get_inventory_formspec()
			.. "button[5.4,4.2;2.65,0.3;main;Back]"
	end
	
	-- main page
	if page == "main" then

		-- buttons
		local x, y = 0, 1

		for k, v in pairs(inventory_plus.buttons[player:get_player_name()]) do

			formspec = formspec .. "button[" .. x .. ","
				 .. y .. ";2,0.5;" .. k .. ";" .. v .. "]"

			x = x + 2

			if x == 8 then
				x = 0
				y = y + 1
			end
		end
	end
	
	return formspec
end

-- register_on_joinplayer
minetest.register_on_joinplayer(function(player)

	-- set crafting grid size
	if inventory_plus.small_craft == true then
		player:get_inventory():set_width("craft", 2)
		player:get_inventory():set_size("craft", 2 * 2)
	else
		player:get_inventory():set_width("craft", 3)
		player:get_inventory():set_size("craft", 3 * 3)
	end

	inventory_plus.register_button(player,"craft", "Craft")

	if minetest.setting_getbool("creative_mode") then
		inventory_plus.register_button(player, "creative_prev", "Creative")
	end

	minetest.after(1, function()

		inventory_plus.set_inventory_formspec(player,
			inventory_plus.get_formspec(player, inventory_plus.default))
	end)
end)

-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)

	-- main

	if fields.main then

		inventory_plus.set_inventory_formspec(player,
			inventory_plus.get_formspec(player, "main"))

		return
	end

	-- craft
	if fields.craft then

		inventory_plus.set_inventory_formspec(player,
			inventory_plus.get_formspec(player, "craft"))

		return
	end

	-- creative
	if fields.creative_prev
	or fields.creative_next then

		minetest.after(0.1, function()

			inventory_plus.set_inventory_formspec(player,
				inventory_plus.get_formspec(player, "creative"))
		end)

		return
	end
end)

-- workbench
minetest.register_node("inventory_plus:workbench", {
	description = "WorkBench",
	drawtype = "nodebox",
	node_box = {type = "fixed", fixed = {
		{ -0.4, -0.5, -0.4, -0.3,  0.4, -0.3 },
		{  0.3, -0.5, -0.4,  0.4,  0.4, -0.3 },
		{ -0.4, -0.5,  0.3, -0.3,  0.4,  0.4 },
		{  0.3, -0.5,  0.3,  0.4,  0.4,  0.4 },
		{ -0.5,  0.4, -0.5,  0.5,  0.5,  0.5 },
	}},
	tiles = {"invplus_workbench_top.png","default_wood.png","default_wood.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {choppy = 2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		meta:set_string("formspec", "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "list[current_name;table;1,1;3,3;]"
			.. "list[current_name;dst;6,2;1,1;]"
			.. "list[current_player;main;0,5;8,4;]"
			.. "image[4.75,2;1,1;gui_furnace_arrow_bg.png^[transformR270]")

		meta:set_string("infotext", "WorkBench")

		local inv = meta:get_inventory()

		inv:set_size("table", 3 * 3)
		inv:set_size("dst", 1)
	end,

	can_dig = function(pos,player)

		local inv = minetest.get_meta(pos):get_inventory()

		return inv:is_empty("table") and inv:is_empty("dst")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)

		if to_list == "dst" then
			return 0
		end

		return count
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)

		if listname == "dst" then
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)

		return stack:get_count()
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)

		minetest.node_metadata_inventory_move_allow_all(
				pos, from_list, from_index, to_list, to_index, count, player)

		if to_list == "table" or from_list == "table" then

			local inv = minetest.get_meta(pos):get_inventory()
			local tablelist = inv:get_list("table")
			local crafted = nil

			if tablelist then
				crafted = minetest.get_craft_result({
					method = "normal",
					width = 3,
					items = tablelist
				})
			end

			if crafted then
				inv:set_stack("dst", 1, crafted.item)
			else
				inv:set_stack("dst", 1, nil)
			end
		end
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)

		if listname == "table" then

			local inv = minetest.get_meta(pos):get_inventory()
			local tablelist = inv:get_list("table")
			local crafted = nil

			if tablelist then
				crafted = minetest.get_craft_result({
					method = "normal",
					width = 3,
					items = tablelist
				})
			end

			if crafted then
				inv:set_stack("dst", 1, crafted.item)
			else
				inv:set_stack("dst", 1, nil)
			end
		end
	end,

	on_metadata_inventory_take = function(pos, listname, index, count, player)

		if listname == "table" then

			local inv = minetest.get_meta(pos):get_inventory()
			local tablelist = inv:get_list("table")
			local crafted = nil

			if tablelist then
				crafted = minetest.get_craft_result({
					method = "normal",
					width = 3,
					items = tablelist
				})
			end

			if crafted then
				inv:set_stack("dst", 1, crafted.item)
			else
				inv:set_stack("dst", 1, nil)
			end

		elseif listname == "dst" then

			local inv = minetest.get_meta(pos):get_inventory()
			local tablelist = inv:get_list("table")
			local crafted = nil
			local table_dec = nil

			if tablelist then
				crafted, table_dec = minetest.get_craft_result({
					method = "normal",
					width = 3,
					items = tablelist
				})
			end

			if table_dec then
				inv:set_list("table", table_dec.items)
			else
				inv:set_list("table", nil)
			end

			local tablelist = inv:get_list("table")

			if tablelist then
				crafted, table_dec = minetest.get_craft_result({
					method = "normal",
					width = 3,
					items = tablelist
				})
			end

			if crafted then
				inv:set_stack("dst", 1, crafted.item)
			else
				inv:set_stack("dst", 1, nil)
			end
		end

	end,
})

minetest.register_craft({
	output = 'inventory_plus:workbench',
	recipe = {
		{'group:wood','group:wood'},
		{'group:wood','group:wood'},
	}
})
