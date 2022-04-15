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

local function fetch_servers(srv_type, callback)
	serverlist.Query({
		Type = srv_type,
		Callback = function(ping, host_name, description, map_name, ply_count, max_ply_count, bot_ply_count, has_password, workshop_id, ip_address, gamemode)
			local actual_host_name, tags = parse_host_name_tags(host_name)
			callback({
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
			})
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
	local bad_col = HSVToColor(hue % 180 * 2, saturation and 0.3 or 0.6, value and 0.6 or 1)
	return Color(bad_col.r, bad_col.g, bad_col.b, bad_col.a)
end

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

local COLOR_BG_HOVERED = Color(255, 157, 0)
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_BLACK = Color(0, 0, 0)
local function add_category(categories, type, name)
	local category = categories:Add(name)
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
			surface.SetDrawColor(143, 99, 29, 201)
			surface.DrawLine(0, 0, 0, h)
			surface.DrawLine(w - 1, 0, w - 1, h)
			surface.DrawLine(0, h - 1, w, h - 1)
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
	end)
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

	local categories = frame:Add("DCategoryList")
	categories:Dock(FILL)
	function categories:Paint() end

	add_category(categories, "favorite", "Favorites")
	add_category(categories, "history", "History")
	add_category(categories, "lan", "LAN")
end

gmx.ShowMultiplayerPanel = show_servers