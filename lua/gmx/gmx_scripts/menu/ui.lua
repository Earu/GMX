local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_BG_HOVERED = Color(255, 157, 0)
local COLOR_HOVERED = Color(255, 196, 0)

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

surface.CreateFont("gmx_button_secondary", {
	font = "Roboto",
	extended = true,
	size = 20,
	weight = 500,
	antialias = true,
	shadow = true,
})

surface.CreateFont("gmx_info", {
	font = "Roboto",
	extended = true,
	size = 16,
	weight = 500,
	antialias = true,
	shadow = true,
})

local current_hostname = ""
hook.Add("ClientFullyInitialized", "gmx_ui_game_info", function(hostname)
	current_hostname = hostname
end)

function bg:Paint(w, h)
	if not IsInGame() then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)
	else
		surface.SetDrawColor(0, 0, 0, 20)
		surface.DrawRect(0, 0, w, h)
	end

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
		surface.DrawText("Game IP: " .. gmx.GetIPAddress())

		base_y = base_y + 20
		surface.SetTextPos(55, base_y)
		surface.DrawText("Game Hostname: " .. current_hostname)
	end

	surface.SetDrawColor(255, 157, 0, 200)
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
	button:SetTextColor(COLOR_WHITE)
	button:SetFont(secondary and "gmx_button_secondary" or "gmx_button")

	button.DoClick = func

	if secondary then
		function button:Paint()
			surface.SetDrawColor(143, 99, 29, 201)
			surface.DrawOutlinedRect(0, 0, w, h)

			surface.SetDrawColor(65, 40, 0, 200)
			surface.DrawRect(0, 0, w, h)

			if self:IsHovered() then
				surface.SetDrawColor(255, 157, 0, 200)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
		end
	else
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