local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG_HOVERED = Color(255, 157, 0)
local COLOR_HOVERED = Color(255, 196, 0)
local COLOR_BLACK = Color(0, 0, 0, 255)

local bg = vgui.Create("DPanel")
bg:SetSize(ScrW(), ScrH())

surface.CreateFont("gmx_header", {
	font = "Arial",
	extended = true,
	size = 100,
	weight = 600,
	antialias = true,
	shadow = true,
})

surface.CreateFont("gmx_clock", {
	font = "Arial",
	extended = true,
	size = 60,
	weight = 600,
	antialias = true,
	shadow = true,
})

surface.CreateFont("gmx_sub_header", {
	font = "Arial",
	extended = true,
	size = 30,
	weight = 600,
	antialias = true,
	shadow = true,
})

surface.CreateFont("gmx_button", {
	font = "Arial",
	extended = true,
	size = 25,
	weight = 600,
	antialias = true,
	shadow = true,
})

surface.CreateFont("gmx_info", {
	font = "Arial",
	extended = true,
	size = 15,
	weight = 600,
	antialias = true,
	shadow = true,
})

local current_ip = ""
local current_hostname = ""
hook.Add("ClientFullyInitialized", "gmx_ui_game_info", function(ip, hostname)
	current_ip = ip
	current_hostname = hostname
end)

function bg:Paint(w, h)
	if IsInGame() then
		surface.SetDrawColor(0, 0, 0, 20)
	else
		surface.SetDrawColor(COLOR_BLACK)
	end
	surface.DrawRect(0, 0, w, h)

	surface.SetFont("gmx_header")
	surface.SetTextColor(COLOR_WHITE)
	surface.SetTextPos(50, 50)
	surface.DrawText("G M X")

	surface.SetFont("gmx_clock")
	local time = os.date("%X")
	local tw, _ = surface.GetTextSize(time)
	surface.SetTextPos(ScrW() / 2 - tw / 2, 20)
	surface.DrawText(time)

	surface.SetFont("gmx_sub_header")
	surface.SetTextColor(COLOR_BG_HOVERED)
	surface.SetTextPos(55, 135)
	surface.DrawText("Garrys  Mod     eXtended")

	surface.SetFont("gmx_info")

	surface.SetTextPos(55, 620)
	surface.DrawText("FPS: " .. math.Round(1 / FrameTime()))

	surface.SetTextPos(55, 640)
	surface.DrawText("Arch: " .. jit.arch)

	surface.SetTextPos(55, 660)
	surface.DrawText("LuaJIT: " .. jit.version)

	surface.SetTextPos(55, 680)
	surface.DrawText("OS: " .. jit.os)

	if IsInGame() then
		surface.SetTextPos(55, 700)
		surface.DrawText("Game IP: " .. current_ip)

		surface.SetTextPos(55, 720)
		surface.DrawText("Game Hostname: " .. current_hostname)
	end
end


local function add_button(text, x, y, w, h, func)
	local button = vgui.Create("DButton")
	button:SetSize(w, h)
	button:SetPos(x, y)
	button:SetText(text)
	button:SetTextColor(COLOR_WHITE)
	button:SetFont("gmx_button")

	button.DoClick = func

	function button:Paint()
		if self:IsHovered() then
			surface.SetDrawColor(COLOR_BG_HOVERED)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(COLOR_HOVERED)
		else
			surface.SetDrawColor(30, 30, 30, IsInGame() and 240 or 255)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(COLOR_WHITE)
		end

		surface.DrawOutlinedRect(0, 0, w, h)
	end

	bg:Add(button)
end

add_button("Start Game", 50, 200, 300, 50, function()
	RunGameUICommand("OpenCreateMultiplayerGameDialog")
end)

add_button("Multiplayer", 50, 260, 300, 50, function()
	RunGameUICommand("OpenServerBrowser")
end)

add_button("Lua Editor", 50, 320, 300, 50, function()
	RunConsoleCommand("gmx_editor")
end)

add_button("Explore Server Files", 50, 380, 300, 50, function()
	if not IsInGame() then return end
	RunConsoleCommand("gmx_explore_server_files")
end)

add_button("Settings", 50 , 440, 300, 50, function()
	RunGameUICommand("OpenOptionsDialog")
end)

add_button("Exit", 50, 500, 300, 50, function()
	RunGameUICommand("Quit")
end)