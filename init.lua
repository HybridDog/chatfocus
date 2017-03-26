-- load settings
--~ local I = minetest.setting_get"name"
--~ assert(type(I) == "string", "Could not detect my player name.")
--~ local default_hility = minetest.setting_get"chatfocus.default_hility"
	--~ or "default"
--~ local mentioncolour_chat = minetest.setting_get"chatfocus.mentioncolour_chat"
	--~ or "#ff2a00"
--~ local mentioncolour_term = minetest.setting_get"chatfocus.mentioncolour_term"
	--~ or "91"
--~ local pcolseed = minetest.setting_get"chatfocus.player_colour_seed"
	--~ or 19
--~ local pcoloff = minetest.setting_get"chatfocus.player_colour_variety"
	--~ or 50

-- temporary solution because setting_get isn't available yet
local default_hility = "default"
local mentioncolour_chat = "#ff2a00"
local mentioncolour_term = "91"
local pcolseed = 19
local pcoloff = 50
local I = "¬" -- keep this "¬" for name detection

-- tells whether a character can belong to a playername
local function valid_pnamechar(c)
	return c == "-"
		or (
			c >= "0"
			and (
				c <= "9"
				or (
					c >= "A"
					and (
						c <= "Z"
						or c == "_"
						or (
							c >= "a"
							and c <= "z"
		)))))
end

-- detects whether the message is from a player etc.
local function get_playername(msg)
	if #msg < 3 then
		return
	end
	if msg:sub(1, 1) == "<" then
		-- usual chat message
		local name = ""
		local textstart
		for p = 2,#msg do
			local c = msg:sub(p, p)
			if c == ">" then
				if msg:sub(p+1, p+1) == " " then
					textstart = p+2
					break
				end
				return
			end
			if not valid_pnamechar(c) then
				return
			end
			name = name .. c
		end
		-- temporary solution to get my playername
		if I == "¬"
		and msg:sub(textstart, #msg) == "hello  " then
			I = name
		end
		return name, textstart
	end
	if msg:sub(1, 2) == "* " then
		-- message emanating from /me
		local name = ""
		local textstart
		for p = 3,#msg do
			local c = msg:sub(p, p)
			if c == " " then
				textstart = p+1
				break
			end
			if not valid_pnamechar(c) then
				return
			end
			name = name .. c
		end
		return name, textstart
	end
	if msg:sub(1, 4) == "*** " then
		-- player leaving and joining
		local name, left
		if msg:sub(-15) == " left the game." then
			name = msg:sub(5, -16)
			left = true
		elseif msg:sub(-17) == " joined the game." then
			name = msg:sub(5, -18)
		else
			return
		end
		for p = 1,#name do
			if not valid_pnamechar(name:sub(p, p)) then
				return
			end
		end
		return name, #name + 5, left
	end
end

-- used for the colours
local function tohex(n)
	local t = {0,1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f"}
	return t[math.floor(n / 16)+1] .. t[n % 16 + 1]
end

-- gives a colour depending on the name and seed
local playercolours = {}
local function get_playercolour(pname)
	if playercolours[pname] then
		return playercolours[pname]
	end
	local data = pcolseed
	for i = 1,#pname do
		data = data + pname:byte(i)
	end
	-- need PseudoRandom here
	math.randomseed(data)
	local ro = math.random(0, pcoloff)
	local go = math.random(0, pcoloff)
	local bo = math.random(0, pcoloff)
	local col = "#" .. tohex(255 - ro) .. tohex(255 - go) .. tohex(255 - bo)
	playercolours[pname] = col
	return col
end

-- prints a message to terminal and tests the escape character usage
local function print_esc(msg, col)
	if msg:find"" then
		-- forbid destroying the terminal output
		local newmsg = ""
		for i = 1,#msg do
			local c = msg:sub(i, i)
			if c ~= "" then
				newmsg = newmsg .. c
			end
		end
		msg = newmsg
	end
	print("[" .. col .. "m" .. msg .. "[m")
end

-- use for showing a chatmessage when being mentioned in it
local function show_mentioned(msg)
	print_esc(msg, mentioncolour_term)
	minetest.display_chat_message(minetest.colorize(mentioncolour_chat, msg))
end

-- the available highlight types
local hility_funcs = {
	["stark-hide"] = function()
	end,
	hide = function(msg, tagged)
		if not tagged then
			print_esc(msg, "30")
		else
			show_mentioned(msg)
		end
	end,
	["dark-grey"] = function(msg, tagged)
		if not tagged then
			minetest.display_chat_message(minetest.colorize(
				"#525252",
				msg
			))
			print_esc(msg, "90")
		else
			show_mentioned(msg)
		end
	end,
	grey = function(msg, tagged)
		if not tagged then
			minetest.display_chat_message(minetest.colorize(
				"#ABABAB",
				msg
			))
			print_esc(msg, "37;2")
		else
			show_mentioned(msg)
		end
	end,
	default = function(msg, tagged, pname)
		if not tagged then
			minetest.display_chat_message(minetest.colorize(
				get_playercolour(pname),
				msg
			))
			print_esc(msg, "0")
		else
			show_mentioned(msg)
		end
	end,
	important = show_mentioned,
}
local available_hilitys = {"nil"}
for hility in pairs(hility_funcs) do
	available_hilitys[#available_hilitys+1] = hility
end
available_hilitys = "higlhight types: " .. table.concat(available_hilitys, ", ")

-- the command for configuring the highlight mode
local playerdata = {}
minetest.register_chatcommand("chatfocus", {
	func = function(param)
		local fs = param:find" "
		if not fs then
			return false, "/chatfocus <playername> <hility>"
		end
		local pname = param:sub(1, fs-1)
		local hility = param:sub(fs+1):trim()
		if not hility_funcs[hility] then
			return false, available_hilitys
		end
		if pname == "*" then
			default_hility = hility
			return true, "default highlight type set to " .. hility
		end
		if pname == "?" then
			return true, "default highlight type set to " .. hility .. "\n" ..
				dump(playerdata)
		end
		for i = 1,#pname do
			if not valid_pnamechar(pname:sub(i, i)) then
				return false, "invalid player name and neither * nor ?"
			end
		end
		playerdata[pname] = hility
		return true, 'highlight type of "' .. pname .. "' set to " .. hility
	end
})

local known_pnames = {}

-- called when a chatmessage is obtained
local function handle_chatmsg(msg)
	local pname,_,left = get_playername(msg)
	if not pname then
		-- not emanating from a player
		minetest.display_chat_message(msg)
		return
	end
	known_pnames[pname] = not left
	local mine = pname == I
	local hility = playerdata[pname] or (mine and "grey") or default_hility
	local tagged = not mine and msg:find(I)
	hility_funcs[hility](msg, tagged, pname)
end

-- register the function
local recfuncs = minetest.registered_on_receiving_chat_messages
local fnum = #recfuncs+1
recfuncs[fnum] = function(message)
	handle_chatmsg(message)
	-- Execute later registered functions
	for i = fnum+1, #recfuncs do
		if recfuncs[i](message) == true then
			error"Can't properly handle chat message"
		end
	end
	return true
end
