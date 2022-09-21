--[[

Inventory Plus for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-inventory_plus
License: BSD-3-Clause https://raw.github.com/cornernote/minetest-inventory_plus/master/LICENSE

Edited by TenPlus1 (26th August 2020)

]]--


-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S = minetest.get_translator and minetest.get_translator("inventory_plus") or
		dofile(MP .. "/intllib.lua")

-- compatibility with older minetest versions
if not rawget(_G, "creative") then
	local creative = {}
end

-- check for new creative addition (TENPLUS1 - changed due to new creative formspec in 5.x)
local addition = ""
if creative and creative.formspec_add then
	creative.formspec_add = "button[5.2,4.9;2.6,0.3;main;" .. S("Back") .. "]"
else
	addition = "button[5.4,4.2;2.65,0.3;main;" .. S("Back") .. "]"
end

-- expose api
inventory_plus = {}

-- define buttons
inventory_plus.buttons = {}

-- default inventory page
inventory_plus.default = minetest.settings:get("inventory_default") or "main"

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

	-- short pause before setting inventory
	minetest.after(0.02, function()
		player:set_inventory_formspec(formspec)
	end)
end

-- create detached inventory for trashcan
local trashInv = minetest.create_detached_inventory("trash", {

	on_put = function(inv, toList, toIndex, stack, player)
		inv:set_stack(toList, toIndex, {})
	end
})

trashInv:set_size("main", 1)

-- get_formspec
inventory_plus.get_formspec = function(player, page)

	if not player or not page then
		return
	end

	-- default inventory page
	local formspec = "size[8,7.5]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "list[current_player;main;0,3.5;8,4;]"

	-- main page
	if page == "main" then

		local name = player:get_player_name()
		local num = 0

		-- count buttons
		for k, v in pairs(inventory_plus.buttons[name]) do
			num = num + 1
		end

		-- buttons
		local x = 0
		local f = math.ceil(num / 4)
		local y = (2.5 / 2) / f

		for k, v in pairs(inventory_plus.buttons[name]) do

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

	if minetest.settings:get_bool("creative_mode")
	or minetest.check_player_privs(player:get_player_name(), {creative = true}) then
		inventory_plus.register_button(player, "invplus_creative", S("Creative"))
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

	-- creative
	if fields.creative_prev
	or fields.creative_next then

		minetest.after(0.2, function()

			inventory_plus.set_inventory_formspec(player,
					player:get_inventory_formspec() .. addition)
		end)

		return
	end
end)

-- compatabiltiy with old workbench (right-click wood to get items back)
minetest.register_alias("inventory_plus:workbench", "default:wood")

-- Add Home GUI
if minetest.get_modpath("sethome") and sethome then
	print (S("sethome found, adding home_gui to inventory plus"))
	dofile(MP .. "/home_gui.lua")
end

