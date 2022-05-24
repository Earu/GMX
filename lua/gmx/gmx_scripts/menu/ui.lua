local night_colors = {
	Text = Color(255, 255, 255, 255),
	Wallpaper = Color(0, 0, 0),
	Background = Color(30, 30, 30),
	BackgroundStrip = Color(59, 59, 59),
	Accent = Color(255, 157, 0),
	AccentAlternative = Color(255, 196, 0),
}

local day_colors = {
	Text = Color(0, 0, 0, 255),
	Wallpaper = Color(220, 220, 220, 255),
	Background = Color(255, 255, 255, 255),
	BackgroundStrip = Color(225, 225, 225, 255),
	Accent = Color(255, 157, 0),
	AccentAlternative = Color(255, 196, 0),
}

gmx.Colors = gmx.Colors.Text and gmx.Colors or day_colors

local function parse_12_hours_datetime(str)
	local chunks = str:Split(":")
	local last_chunk_chunks = chunks[#chunks]:Split(" ")
	chunks[#chunks] = last_chunk_chunks[1]:Trim()
	local is_afternoon = last_chunk_chunks[2]:lower() == "pm"

	return {
		Hours = tonumber(chunks[1]) + (is_afternoon and 12 or 0),
		Minutes = tonumber(chunks[2]),
		Seconds = tonumber(chunks[3]),
	}
end

local elements_to_update = {}
local function update_day_colors(latitude, longitude)
	local url = ("https://api.sunrise-sunset.org/json?lat=%f&lng=%f"):format(latitude, longitude)
	http.Fetch(url, function(res)
		local results = util.JSONToTable(res).results
		local is_afternoon = os.date("%p"):lower() == "pm"
		local cur_hour = tonumber(os.date("%I")) + (is_afternoon and 12 or 0)
		local sunset = parse_12_hours_datetime(results.sunset)
		local sunrise = parse_12_hours_datetime(results.sunrise)

		local prev_colors = gmx.Colors
		if cur_hour >= sunset.Hours or cur_hour <= sunrise.Hours then
			gmx.Colors = night_colors
		else
			gmx.Colors = day_colors
		end

		if prev_colors ~= gmx.Colors then
			for element, element_data in pairs(elements_to_update) do
				if not IsValid(element) then
					elements_to_update[element] = nil
					continue
				end

				element_data.SetterFunction(element, gmx.Colors[element_data.ThemeColorKey])
			end

			print(cur_hour, sunrise.Hours, sunset.Hours)
			gmx.Print("Day time changing to " .. gmx.GetCurrentDayState())
		end
	end, gmx.Print)
end

http.Fetch("http://ip-api.com/json/", function(body)
	local data = util.JSONToTable(body)
	update_day_colors(data.lat, data.lon)
	timer.Create("gmx_sunset_timer", 60 * 5, 0, function()
		update_day_colors(data.lat, data.lon)
	end)
end, gmx.Print)

function gmx.GetCurrentDayState()
	return gmx.Colors == day_colors and "day" or "night"
end

function gmx.SetVGUIElementColor(element, setter_fn, theme_color_key)
	if not IsValid(element) then return end
	if not setter_fn then return end
	if not gmx.Colors[theme_color_key] then return end

	setter_fn(element, element[theme_color_key])
	elements_to_update[element] = {
		Element = element,
		SetterFunction = setter_fn,
		ThemeColorKey = theme_color_key,
	}
end

local bg = vgui.Create("DPanel")
bg:SetSize(ScrW(), ScrH())

surface.CreateFont("gmx_header", {
	font = "Arial",
	extended = true,
	size = 100,
	weight = 600,
	antialias = true,
	shadow = false,
})

surface.CreateFont("gmx_clock", {
	font = "Arial",
	extended = true,
	size = 60,
	weight = 600,
	antialias = true,
	shadow = false,
})

surface.CreateFont("gmx_sub_header", {
	font = "Arial",
	extended = true,
	size = 30,
	weight = 600,
	antialias = true,
	shadow = false,
})

surface.CreateFont("gmx_button", {
	font = "Arial",
	extended = true,
	size = 25,
	weight = 600,
	antialias = true,
	shadow = false,
})

surface.CreateFont("gmx_button_secondary", {
	font = "Roboto",
	extended = true,
	size = 20,
	weight = 500,
	antialias = true,
	shadow = false,
})

surface.CreateFont("gmx_info", {
	font = "Roboto",
	extended = true,
	size = 16,
	weight = 500,
	antialias = true,
	shadow = false,
})

local current_hostname = ""
hook.Add("ClientFullyInitialized", "gmx_ui_game_info", function(hostname)
	current_hostname = hostname
end)

function bg:Paint(w, h)
	if not IsInGame() then
		surface.SetDrawColor(gmx.Colors.Wallpaper)
		surface.DrawRect(0, 0, w, h)
	else
		surface.SetDrawColor(0, 0, 0, 20)
		surface.DrawRect(0, 0, w, h)
	end

	surface.SetFont("gmx_header")
	surface.SetTextColor(gmx.Colors.Text)
	surface.SetTextPos(50, 50)
	surface.DrawText("G M X")

	surface.SetFont("gmx_clock")
	local time = os.date("%X")
	local tw, _ = surface.GetTextSize(time)
	surface.SetTextPos(ScrW() / 2 - tw / 2, 20)
	surface.DrawText(time)

	surface.SetFont("gmx_sub_header")
	surface.SetTextColor(gmx.Colors.Accent)
	surface.SetTextPos(55, 135)
	surface.DrawText("Garrys  Mod     eXtended")

	surface.SetFont("gmx_info")

	local base_y = 460
	surface.SetTextPos(55, base_y)
	surface.DrawText("FPS: " .. math.Round(1 / FrameTime()))

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("OS: " .. jit.os)

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("Arch: " .. jit.arch)

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("LuaJIT: " .. jit.version)

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("Lua Version: " .. _VERSION)

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("GMod Version: " .. VERSIONSTR)

	base_y = base_y + 20
	surface.SetTextPos(55, base_y)
	surface.DrawText("GMod Branch: " .. BRANCH)

	if IsInGame() then
		base_y = base_y + 40
		surface.SetTextPos(55, base_y)
		surface.DrawText("Game IP: " .. gmx.GetConnectedServerIPAddress())

		base_y = base_y + 20
		surface.SetTextPos(55, base_y)
		surface.DrawText("Game Hostname: " .. current_hostname)
	end

	surface.SetDrawColor(gmx.Colors.Accent)
	surface.DrawLine(375, 195, 375, 430)
	surface.DrawLine(375, 195, 585, 195)

	surface.SetTextPos(380, 180)
	surface.DrawText("Debug")
end

local function add_button(text, x, y, w, h, func, secondary)
	local button = vgui.Create("DButton")
	button:SetSize(w, h)
	button:SetPos(x, y)
	button:SetText(text)
	gmx.SetVGUIElementColor(button, button.SetTextColor, "Text")
	button:SetFont(secondary and "gmx_button_secondary" or "gmx_button")

	button.DoClick = func

	if secondary then
		function button:Paint()
			surface.SetDrawColor(gmx.Colors.Background)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(gmx.Colors.BackgroundStrip)
			surface.DrawOutlinedRect(0, 0, w, h)

			if self:IsHovered() then
				surface.SetDrawColor(gmx.Colors.Accent)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
		end
	else
		function button:Paint()
			if self:IsHovered() then
				surface.SetDrawColor(gmx.Colors.Accent)
				surface.DrawRect(0, 0, w, h)

				surface.SetDrawColor(gmx.Colors.AccentAlternative)
			else
				surface.SetDrawColor(gmx.Colors.Background.r, gmx.Colors.Background.g, gmx.Colors.Background.b, IsInGame() and 240 or 255)
				surface.DrawRect(0, 0, w, h)

				surface.SetDrawColor(gmx.Colors.BackgroundStrip)
			end

			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end
	end

	bg:Add(button)
end

-- main buttons
do
	add_button("Start Game", 50, 200, 300, 50, function()
		RunGameUICommand("OpenCreateMultiplayerGameDialog")
	end)

	add_button("Multiplayer", 50, 260, 300, 50, function()
		gmx.ShowMultiplayerPanel()
	end)

	add_button("Settings", 50 , 320, 300, 50, function()
		RunGameUICommand("OpenOptionsDialog")
	end)

	add_button("Exit", 50, 380, 300, 50, function()
		RunGameUICommand("Quit")
	end)
end

-- debug buttons
do
	add_button("Lua Editor", 380, 200, 200, 35, function()
		RunConsoleCommand("gmx_editor")
	end, true)

	add_button("Explore Server Files", 380, 240, 200, 35, function()
		if not IsInGame() then return end
		RunConsoleCommand("gmx_explore_server_files")
	end, true)

	add_button("Lua Repl Cache", 380, 280, 200, 35, function()
		RunConsoleCommand("gmx_repl_cache")
	end, true)

	add_button("Binary Editor", 380, 320, 200, 35, function()
		RunConsoleCommand("gmx_binary_editor")
	end, true)
end

hook.Add("GMXReload", "gmx_ui", function()
	if not IsValid(bg) then return end
	bg:Remove()
end)

include("gmx/gmx_scripts/menu/ui/lua_editor.lua")
include("gmx/gmx_scripts/menu/ui/console.lua")
include("gmx/gmx_scripts/menu/ui/lua_repl_cache.lua")
include("gmx/gmx_scripts/menu/ui/binary_editor.lua")
include("gmx/gmx_scripts/menu/ui/multiplayer.lua")

local last_scrw, last_scrh = ScrW(), ScrH()
hook.Add("Think", "gmx_ui_scaling", function()
	if ScrW() ~= last_scrw or ScrH() ~= last_scrh then
		last_scrw, last_scrh = ScrW(), ScrH()
		RunGameUICommand("engine gmx reload")
	end
end)