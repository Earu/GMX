require("fontsx")

local function parse_host_name_tags(host_name)
	local tags = {}
	local function add_tag(tag)
		tag = tag:Trim()
		if #tag > 1 and #tag < 15 then
			table.insert(tags, tag)
		end
	end

	local start_index, _ = host_name:find("[%|%,%-]")
	local end_index = 1
	while start_index do
		local tag = end_index == 1
			and host_name:sub(end_index, start_index - 1):Trim()
			or host_name:sub(end_index, start_index - 1):gsub("[%[%]%(%)]", ""):Trim()
			add_tag(tag)

		end_index = start_index + 1
		start_index, _ = host_name:find("[%|%,%-]", end_index)
	end

	local last_tag = host_name:sub(end_index, #host_name):gsub("[%[%]%(%)]", ""):Trim()
	add_tag(last_tag)

	local explicit_tag_patterns = {
		"%[(.+)%]", "%((.+)%)", "%{(.+)%}", "%<(.+)%>",
		"%[(.+)$", "%((.+)$", "%{(.+)$", "%<(.+)$",
	}

	local actual_host_name = (table.remove(tags, 1) or host_name)
	for _, tag_pattern in ipairs(explicit_tag_patterns) do
		actual_host_name = actual_host_name:gsub(tag_pattern, function(tag)
			add_tag(tag)
			return ""
		end)
	end

	if #tags <= 0 then
		add_tag("N/A")
	end

	return actual_host_name, tags
end

local valid_filters = {
	["host"] = "FullHostName",
	["tag"] = "Tags",
	["gm"] = "Description",
	["map"] = "Map",
	["ip"] = "IPAddress",
}

local function default_search_processor(server, search_query)
	local has_matching_tag = false
	for _, tag in ipairs(server.Tags) do
		if tag:lower():find(search_query, 1, true) then
			has_matching_tag = true
			break
		end
	end

	return server.FullHostName:lower():find(search_query, 1, true)
		or server.Description:lower():find(search_query, 1, true)
		or server.Map:lower():find(search_query, 1, true)
		or server.Gamemode:lower():find(search_query, 1, true)
		or server.IPAddress:find(search_query, 1, true)
		or has_matching_tag
end

local function parse_search_query(search_query)
	if not search_query or #search_query:Trim() <= 0 then
		return function(server) return true end
	end

	local filter_processors = {}
	local filters = search_query:Split(";")
	for _, filter in ipairs(filters) do
		local chunks = filter:Split("=")
		local has_valid_filter_value = chunks[2] and #chunks[2] > 0
		if has_valid_filter_value then
			local filter_type = chunks[1]:Trim():lower()
			local filter_value = chunks[2]:lower()
			if not valid_filters[filter_type] then
				table.insert(filter_processors, function(server) return false end)
				continue
			end

			table.insert(filter_processors, function(server)
				local server_value = server[valid_filters[filter_type]]
				if not server_value then
					return false
				end

				local server_value_type = type(server_value)
				if isstring(server_value) then
					return server_value:lower():find(filter_value, 1, true)
				elseif server_value_type == "table" then
					for _, value in ipairs(server_value) do
						if value:lower():find(filter_value, 1, true) then
							return true
						end
					end

					return false
				else
					return tostring(server_value):lower():find(filter_value, 1, true)
				end
			end)
		else
			table.insert(filter_processors, function(server) return default_search_processor(server, filter:Trim():lower()) end)
		end
	end

	return function(server)
		for _, filter_processor in ipairs(filter_processors) do
			if not filter_processor(server) then
				return false
			end
		end

		return true
	end
end

local function fetch_servers(srv_type, callback, search_query)
	serverlist.Query({
		Type = srv_type,
		Callback = function(ping, host_name, description, map_name, ply_count, max_ply_count, bot_ply_count, has_password, workshop_id, ip_address, gamemode)
			local actual_host_name, tags = parse_host_name_tags(host_name)
			local server = {
				Ping = ping,
				FullHostName = host_name,
				HostName = actual_host_name,
				Tags = tags,
				Description = description,
				Map = map_name,
				PlayerCount = ply_count,
				MaxPlayerCount = max_ply_count,
				BotPlayerCount = bot_ply_count,
				HasPassword = has_password,
				WorkshopID = workshop_id,
				IPAddress = ip_address,
				Gamemode = gamemode,
			}

			if search_query then
				local execute_query = parse_search_query(search_query:lower())
				if execute_query(server) then
					callback(server)
				end
			else
				callback(server)
			end
		end,
	})
end

local function string_hash(text)
	local counter = 1
	local len = #text
	for i = 1, len, 3 do
		counter =
			math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
			(text:byte(i) * 16776193) +
			((text:byte(i + 1) or (len - i + 256)) * 8372226) +
			((text:byte(i + 2) or (len - i + 256)) * 3932164)
	end

	return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

local function pastellize_tag(nick)
	local hue = string_hash(nick)
	local saturation, value = hue % 3 == 0, hue % 127 == 0

	-- HSVToColor doesnt return a color with the color metatable...
	local bad_col = HSVToColor(hue % 20 * 2, saturation and 0.3 or 0.6, value and 0.6 or 1)
	return Color(bad_col.r, bad_col.g, bad_col.b, bad_col.a)
end

surface.CreateFont("gmx_server_search", {
	font = fonts.Exists("Iosevka Type") and "Iosevka Type" or "Arial",
	extended = true,
	size = 22,
	weight = 500,
	antialias = true,
})

surface.CreateFont("gmx_server_tag", {
	font = fonts.Exists("Iosevka Type") and "Iosevka Type" or "Arial",
	extended = true,
	size = 20,
	weight = 600,
	antialias = true,
})

surface.CreateFont("gmx_server_info", {
	font = fonts.Exists("Iosevka Type") and "Iosevka Type" or "Arial",
	extended = true,
	size = 18,
	weight = 500,
	antialias = true,
})

local COLOR_HOVERED = Color(255, 196, 0)
local COLOR_BG_HOVERED = Color(255, 157, 0)
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_BLACK = Color(0, 0, 0)
local function add_category(categories, type, name, expanded, search_query)
	local category = categories:Add(name)
	category:SetExpanded(expanded)

	function category:Paint(w, h)
		surface.SetDrawColor(143, 99, 29, 201)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		surface.SetDrawColor(COLOR_BG_HOVERED)
		surface.DrawOutlinedRect(0, 0, w, 20)
	end

	fetch_servers(type, function(server)
		if not IsValid(category) then return end

		local item = category:Add("")
		item:SetTall(64)
		function item:DoDoubleClick()
			RunGameUICommand("engine connect " .. server.IPAddress)
		end

		function item:Paint(w, h)
			surface.SetDrawColor(143, 99, 29, 201)
			surface.DrawLine(0, h - 1, w, h - 1)

			if self:IsHovered() then
				surface.SetDrawColor(COLOR_BG_HOVERED)
				surface.DrawRect(0, 0, w, h)
			end
		end

		local label = item:Add("DLabel")
		label:SetText(server.FullHostName)
		label:SetTextColor(COLOR_WHITE)
		label:SetTall(64)
		label:Dock(FILL)
		label:DockMargin(8, 0, 0, 0)
		label:SetFont("gmx_server_info")

		local button = item:Add("DButton")
		button:SetText("Connect")
		button:Dock(RIGHT)
		button:SetWide(category:GetWide() / 10)
		button:SetTextColor(COLOR_WHITE)
		button:SetFont("gmx_server_info")
		function button:Paint(w, h)
			if self:IsHovered() then
				surface.SetDrawColor(COLOR_BG_HOVERED)
				surface.DrawRect(0, 0, w, h)
			else
				surface.SetDrawColor(143, 99, 29, 201)
				surface.DrawLine(0, 0, 0, h)
				surface.DrawLine(w - 1, 0, w - 1, h)
				surface.DrawLine(0, h - 1, w, h - 1)
			end
		end

		function button:DoClick()
			RunGameUICommand("engine connect " .. server.IPAddress)
		end

		local gamemode_label = item:Add("DLabel")
		gamemode_label:SetText(server.Description)
		gamemode_label:SetTextColor(COLOR_WHITE)
		gamemode_label:Dock(RIGHT)
		gamemode_label:DockMargin(8, 0, 8, 0)
		gamemode_label:SetWide(category:GetWide() / 10)
		gamemode_label:SetFont("gmx_server_info")
		gamemode_label:SetContentAlignment(5)

		local ply_count_label = item:Add("DLabel")
		ply_count_label:SetText((server.PlayerCount - server.BotPlayerCount) .. " / " .. server.MaxPlayerCount)
		ply_count_label:SetTextColor(COLOR_WHITE)
		ply_count_label:Dock(RIGHT)
		ply_count_label:SetWide(category:GetWide() / 10)
		ply_count_label:DockMargin(8, 0, 0, 0)
		ply_count_label:SetFont("gmx_server_info")
		ply_count_label:SetContentAlignment(5)

		local ip_label = item:Add("DLabel")
		ip_label:SetText(server.IPAddress)
		ip_label:SetTextColor(COLOR_WHITE)
		ip_label:SetWide(category:GetWide() / 10)
		ip_label:Dock(RIGHT)
		ip_label:DockMargin(15, 0, 0, 0)
		ip_label:SetContentAlignment(5)
		ip_label:SetFont("gmx_server_info")

		local tag_container = item:Add("DPanel")
		tag_container:Dock(BOTTOM)
		tag_container:SetTall(32)
		tag_container:DockMargin(0, 0, 0, 0)
		tag_container:DockPadding(8, 0, 5, 8)
		function tag_container:Paint() end

		for _, tag in ipairs(server.Tags) do
			local tag_label = tag_container:Add("DLabel")
			tag_label:SetText(tag)
			tag_label:SetWide(100)
			tag_label:SetTextColor(COLOR_BLACK)
			tag_label:Dock(BOTTOM)
			tag_label:Dock(LEFT)
			tag_label:DockMargin(0, 0, 10, 0)
			tag_label:SetContentAlignment(5)
			tag_label:SetFont("gmx_server_tag")

			local col = tag == "N/A" and Color(143, 143, 143, 201) or pastellize_tag(tag)
			function tag_label:Paint(w, h)
				surface.SetDrawColor(col)
				surface.DrawRect(0, 0, w, h)
			end
		end
	end, search_query)

	return category
end

local function show_servers()
	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() * 0.8, ScrH() * 0.6)
	frame:SetTitle("Multiplayer")
	frame:Center()
	frame:MakePopup()
	frame.btnMinim:Hide()
	frame.btnMaxim:Hide()
	frame.lblTitle:SetFont("gmx_info")

	function frame.btnClose:Paint()
		surface.SetTextColor(COLOR_BG_HOVERED)
		surface.SetTextPos(10, 5)
		surface.SetFont("DermaDefaultBold")
		surface.DrawText("X")
	end

	function frame:Paint(w, h)
		Derma_DrawBackgroundBlur(self, 0)

		surface.SetDrawColor(143, 99, 29, 201)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

		surface.SetDrawColor(65, 40, 0, 240)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(COLOR_BG_HOVERED)
		surface.DrawOutlinedRect(0, 0, w, 25)
	end

	function frame:Think()
		if input.IsKeyDown(KEY_ESCAPE) then
			self:Remove()
		end
	end

	local categories = frame:Add("DCategoryList")
	categories:Dock(FILL)
	function categories:Paint() end

	add_category(categories, "favorite", "Favorites", true)
	add_category(categories, "history", "History", false)

	local search_bar = frame:Add("DPanel")
	search_bar:Dock(BOTTOM)
	search_bar:SetTall(32)
	search_bar:DockMargin(0, 0, 0, 0)
	search_bar:DockPadding(0, 0, 0, 0)

	function search_bar:Paint(w, h)
		surface.SetDrawColor(COLOR_BG_HOVERED)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local search_input_header = search_bar:Add("DLabel")
	search_input_header:SetFont("gmx_server_search")
	search_input_header:SetTextColor(COLOR_WHITE)
	search_input_header:SetText("")
	search_input_header:SetSize(75, 32)
	search_input_header:Dock(LEFT)

	function search_input_header:Paint(w, h)
		surface.SetDrawColor(255, 157, 0, 200)
		surface.DrawLine(0, 0, 0, h)

		surface.DisableClipping(true)
		surface.DrawLine(w - 12, 0, w, h / 2)
		surface.DrawLine(w - 12, h, w, h / 2)
		surface.DisableClipping(false)

		surface.SetTextColor(COLOR_WHITE)
		surface.SetFont("gmx_server_search")
		local tw, th = surface.GetTextSize("Search")
		surface.SetTextPos(w / 2 - tw / 2 - 5, h / 2 - th / 2)
		surface.DrawText("Search")
	end

	local search_input = search_bar:Add("DTextEntry")
	search_input:Dock(FILL)
	search_input:SetTextColor(COLOR_WHITE)
	search_input:SetFont("gmx_server_search")
	search_input:SetUpdateOnType(true)
	search_input:SetKeyboardInputEnabled(true)
	search_input:SetMouseInputEnabled(true)

	function search_input:Paint(w, h)
		self:DrawTextEntryText(COLOR_WHITE, COLOR_HOVERED, COLOR_BG_HOVERED)
	end

	local cur_search_category
	function search_input:OnEnter()
		local search_query = self:GetText():Trim()
		if #search_query < 1 then return end

		if IsValid(cur_search_category) then
			cur_search_category:Remove()
		end

		cur_search_category = add_category(categories, "internet", "Search", true, search_query)
	end
end

gmx.ShowMultiplayerPanel = show_servers