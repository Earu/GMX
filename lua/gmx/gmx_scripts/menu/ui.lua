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

surface.CreateFont("gmx_info", {
	font = "Roboto",
	extended = true,
	size = 16,
	weight = 500,
	antialias = true,
	shadow = true,
})

local New2d
do -- game of life
	New2d = {}

	local ometa = {}
	local imeta = {}
	local factory = {}
	local get = rawget

	setmetatable(New2d,factory)

	ometa.__meta   = "uh"
	imeta.__meta   = "hm"
	factory.__meta = "ok"

	function imeta:__index( k )
		if get(self,k) then
			return get(self,k)
		else
			self[k] = 0
			return get(self,k)
		end
	end

	function ometa:__index( k )
		if get(self,k) then
			return get(self,k)
		else
			self[k] = {}
			setmetatable(get(self,k), imeta)
			return get(self,k)
		end
	end

	function factory:__call(tab)
		local new_table = {}
		setmetatable(new_table,ometa)
		return new_table
	end
end

local function gol_rect(w, h, board)
	for x, i in pairs(board) do
		for y, v in pairs(i) do
			surface.SetDrawColor(200 - y, 200 - y, 200 - y, 255)
			surface.DrawRect(w + x * 5, h + y * 5, 5, 5)
		end
	end
end

local function gol_glow(w, h, board)
	for x,i in pairs(board) do
		for y,v in pairs(i) do
			surface.SetDrawColor(v * 30, v * 20, v, 255)
			surface.DrawRect(w + x * 5, h + y * 5, 5, 5)
		end
	end
end

local render_board = New2d()
local render_old = New2d()
local function gol_calc_life()
	local counts = New2d()
	local new = New2d()

	for x, i in pairs(render_board) do
		for y,v in pairs(i) do
			counts[x - 1][y - 1] = counts[x - 1][y - 1] + 1
			counts[x][y - 1] = counts[x][y - 1] + 1
			counts[x + 1][y - 1] = counts[x + 1][y - 1] + 1
			counts[x + 1][y] = counts[x + 1][y] + 1
			counts[x + 1][y + 1] = counts[x + 1][y + 1] + 1
			counts[x][y + 1] = counts[x][y + 1] + 1
			counts[x - 1][y + 1] = counts[x - 1][y + 1] + 1
			counts[x - 1][y] = counts[x - 1][y] + 1
		end
	end

	for x, i in pairs(counts) do
		for y, v in pairs(i) do
			if render_board[x][y] == 0 and counts[x][y] == 3 then
				new[x][y] = 1
			elseif render_board[x][y] == 1 and counts[x][y] == 2 or counts[x][y] == 3 then
				new[x][y] = 1
			end
		end
	end
	render_board = new
	render_old = counts
end

local width = ScrW() / 12
local height = ScrW() / 20
local rand = math.random
for i = 0, 5000 do
	render_board[rand(-width, width)][rand(-height, height)] = 1
end

gol_calc_life()
gol_calc_life()
timer.Create("GameOfLife", 0.1, 0, gol_calc_life)

local current_ip = ""
local current_hostname = ""
hook.Add("ClientFullyInitialized", "gmx_ui_game_info", function(ip, hostname)
	current_ip = ip
	current_hostname = hostname
end)

function bg:Paint(w, h)
	if not IsInGame() then
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, w, h)
		gol_glow(w / 2, h / 2, render_old)
		gol_rect(w / 2, h / 2, render_board)
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

	surface.SetTextPos(55, 640)
	surface.DrawText("FPS: " .. math.Round(1 / FrameTime()))

	surface.SetTextPos(55, 660)
	surface.DrawText("OS: " .. jit.os)

	surface.SetTextPos(55, 680)
	surface.DrawText("Arch: " .. jit.arch)

	surface.SetTextPos(55, 700)
	surface.DrawText("LuaJIT: " .. jit.version)

	surface.SetTextPos(55, 720)
	surface.DrawText("Lua Version: " .. _VERSION)

	surface.SetTextPos(55, 740)
	surface.DrawText("GMod Version: " .. VERSIONSTR)

	surface.SetTextPos(55, 760)
	surface.DrawText("GMod Branch: " .. BRANCH)

	if IsInGame() then
		surface.SetTextPos(55, 800)
		surface.DrawText("Game IP: " .. current_ip)

		surface.SetTextPos(55, 820)
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

add_button("Lua Repl Cache", 50, 440, 300, 50, function()
	RunConsoleCommand("gmx_repl_cache")
end)

add_button("Settings", 50 , 500, 300, 50, function()
	RunGameUICommand("OpenOptionsDialog")
end)

add_button("Exit", 50, 560, 300, 50, function()
	RunGameUICommand("Quit")
end)

do -- console
	require("enginespew")

	surface.CreateFont("gmx_console", {
		font = "Roboto",
		extended = true,
		size = 18,
		weight = 500,
		antialias = true,
		shadow = true,
	})

	local console = vgui.Create("DFrame")
	console:SetSize(ScrW() / 3, ScrH() - 10)
	console:SetPos(ScrW() - console:GetWide(), 0)
	console:DockPadding(0, 0, 0, 0)
	console:SetKeyboardInputEnabled(true)
	console:SetMouseInputEnabled(true)
	console.lblTitle:Hide()
	console.btnClose:Hide()
	console.btnMaxim:Hide()
	console.btnMinim:Hide()

	function console:Paint(w, h)
		surface.SetDrawColor(143, 99, 29, 201)
		surface.DrawLine(0, 0, 0, h)

		surface.SetDrawColor(65, 40, 0, 200)
		surface.DrawRect(0, 0, w, h)
	end

	local console_input_header = console:Add("DLabel")
	console_input_header:SetFont("gmx_console")
	console_input_header:SetTextColor(COLOR_WHITE)
	console_input_header:SetText("")
	console_input_header:SetSize(75, 30)
	console_input_header:SetPos(0, console:GetTall() - 30)

	function console_input_header:Paint(w, h)
		surface.SetDrawColor(255, 157, 0, 200)
		surface.DrawLine(0, 0, 0, h)

		surface.DisableClipping(true)
		surface.DrawLine(0, 0, console:GetWide(), 0)
		surface.DrawLine(0, h - 1, console:GetWide(), h - 1)
		surface.DrawLine(w - 12, 0, w, h / 2)
		surface.DrawLine(w - 12, h, w, h / 2)
		surface.DisableClipping(false)

		surface.SetTextColor(COLOR_WHITE)
		surface.SetFont("gmx_console")
		local tw, th = surface.GetTextSize("Console")
		surface.SetTextPos(w / 2 - tw / 2 - 5, h / 2 - th / 2)
		surface.DrawText("Console")
	end

	local console_input = console:Add("DTextEntry")
	console_input:Dock(BOTTOM)
	console_input:DockMargin(75, 0, 0, 0)
	console_input:SetTall(30)
	console_input:SetFont("gmx_console")
	console_input:SetTextColor(COLOR_WHITE)
	console_input:SetUpdateOnType(true)
	console_input:SetKeyboardInputEnabled(true)
	console_input:SetMouseInputEnabled(true)
	console_input:SetHistoryEnabled(true)
	console_input.HistoryPos = 0

	function console_input:Think()
		local bind = input.LookupBinding("toggleconsole")
		if not bind then return end

		local key_code = input.GetKeyCode(bind)
		if input.IsButtonDown(key_code) then
			gui.ActivateGameUI()
			console:MakePopup()
			self:RequestFocus()
		end
	end

	local cur_completions = {}
	local cur_selection = -1
	function console_input:Paint(w, h)
		self:DrawTextEntryText(COLOR_WHITE, COLOR_HOVERED, COLOR_BG_HOVERED)

		surface.SetFont("gmx_console")
		surface.DisableClipping(true)

		for i, completion in pairs(cur_completions) do
			surface.SetTextColor(i == cur_selection and COLOR_BG_HOVERED or COLOR_WHITE)
			local tw, th = surface.GetTextSize(completion)

			local x, y = -75 - tw, -i * (th + 5)
			surface.SetTextPos(x, y)
			surface.DrawText(completion)

			if i == cur_selection then
				surface.SetDrawColor(COLOR_BG_HOVERED)
				surface.DrawOutlinedRect(x - 5, y, tw + 5, th + 2)
			end

		end

		surface.DisableClipping(false)
	end

	function console_input:OnValueChange(text)
		cur_completions = ConsoleAutoComplete(text) or {}
		cur_selection = -1
	end

	function console_input:HandleHistory(key_code)
		if key_code == KEY_ENTER or key_code == KEY_PAD_ENTER then
			self:AddHistory(self:GetText())
			self.HistoryPos = 0
		end

		if key_code == KEY_ESCAPE then
			self.HistoryPos = 0
		end

		if not self.HistoryPos then return end

		if key_code == KEY_UP then
			self.HistoryPos = self.HistoryPos - 1
			self:UpdateFromHistory()
		elseif key_code == KEY_DOWN then
			self.HistoryPos = self.HistoryPos + 1
			self:UpdateFromHistory()
		end
	end

	function console_input:OnKeyCodeTyped(key_code)
		self:HandleHistory(key_code)

		if key_code == KEY_ENTER or key_code == KEY_PAD_ENTER then
			self:OnEnter()
			return
		end

		if key_code ~= KEY_TAB then return end

		cur_selection = cur_selection - 1
		if cur_selection > #cur_completions or cur_selection <= 0 then
			cur_selection = #cur_completions
		end

		timer.Simple(0, function()
			self:SetCaretPos(#self:GetText())
			self:RequestFocus()
		end)
	end

	local console_output = console:Add("RichText")
	console_output:Dock(FILL)
	console_output:DockMargin(10, 10, 0, 0)
	console_output:SetFontInternal("gmx_info")

	function console_output:PerformLayout()
		self:SetFontInternal("gmx_console")
		self:SetUnderlineFont("gmx_console")
	end

	hook.Add("EngineSpew", "gmx_console", function(log_type, log_msg, log_grp, log_lvl, r, g, b)
		if not IsValid(console_output) then return end
		if log_type == 0 then return end -- ignore these?

		if r == 0 and g == 0 and b == 0 then
			r, g, b = 255, 255, 255
		end

		console_output:InsertColorChange(r, g, b, 255)
		console_output:AppendText(log_msg)
	end)

	function console_input:OnEnter()
		local cmd = self:GetText()
		if cur_selection > 0 then
			self:SetText(cur_completions[cur_selection])
			cur_selection = -1
			cur_completions = {}

			timer.Simple(0, function()
				self:SetCaretPos(#self:GetText())
				self:RequestFocus()
			end)

			return
		end

		if #cmd:Trim() == 0 then
			self:SetText("")
			return
		end

		RunGameUICommand("engine " .. cmd)
		self:SetText("")

		console_output:InsertColorChange(255, 255, 255, 255)
		console_output:AppendText((">> %s\n"):format(cmd))

		cur_selection = -1
		cur_completions = {}

		console:MakePopup()
		self:RequestFocus()
	end

	local loading_state = false
	local has_init = IsInGame()
	hook.Add("DrawOverlay", "gmx_console", function()
		if not IsValid(console) then return end

		local loading = IsInLoading() or (IsInGame() and not has_init)
		if loading ~= loading_state then
			loading_state = loading
			console:SetPaintedManually(loading)
			console_output:SetPaintedManually(loading)
		end

		if loading then
			console:PaintManual()
			console_output:PaintManual()
		end
	end)

	hook.Add("ClientFullyInitialized", "gmx_console", function()
		has_init = true
	end)

	hook.Add("ClientStateDestroyed", "gmx_console", function()
		has_init = false
	end)

	concommand.Remove("gmx_toggleconsole")
	concommand.Add("gmx_toggleconsole", function()
		if gui.IsGameUIVisible() and IsInGame() then
			gui.HideGameUI()
			return
		end

		gui.ActivateGameUI()
		if not IsValid(console_input) then return end

		console:MakePopup()
		console_input:RequestFocus()
	end)

	RunGameUICommand("engine alias toggleconsole gmx_toggleconsole")
	RunGameUICommand("engine alias showconsole gmx_toggleconsole")

	console:MakePopup()

	hook.Add("GMXReload", "gmx_console", function()
		if not IsValid(bg) then return end
		bg:Remove()
		console:Remove()
	end)
end

do -- repl cache
	local function create_lua_cache_panel()
		local frame = vgui.Create("DFrame")
		frame:SetSize(600, 300)
		frame:SetTitle("Lua Repl Cache")
		frame:MakePopup()
		frame:DockPadding(0, 25, 0, 0)
		frame:Center()
		frame.btnMinim:Hide()

		function frame.btnMaxim.Paint()
			surface.SetTextColor(COLOR_BG_HOVERED)
			surface.SetTextPos(10, 5)
			surface.SetFont("DermaDefaultBold")
			surface.DrawText("↻")
		end

		frame.btnMaxim:SetEnabled(true)
		function frame.btnMaxim:DoClick()
			gmx.ReplFilterCache = {}
			hook.Run("GMXReplFilterCacheChanged")
			gmx.Print("Cleared repl lua cache")
		end

		function frame.btnClose:Paint()
			surface.SetTextColor(COLOR_BG_HOVERED)
			surface.SetTextPos(10, 5)
			surface.SetFont("DermaDefaultBold")
			surface.DrawText("X")
		end

		function frame:Paint(w, h)
			surface.SetDrawColor(65, 40, 0, 200)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(143, 99, 29, 201)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
		end

		local list_view = frame:Add("DListView")
		list_view:Dock(FILL)
		list_view:SetMultiSelect(true)
		function list_view:Paint() end

		local columns = {}
		table.insert(columns, list_view:AddColumn("ID"))
		table.insert(columns, list_view:AddColumn("Name"))
		table.insert(columns, list_view:AddColumn("Method"))
		for _, column in ipairs(columns) do
			column.Header:SetTextColor(COLOR_WHITE)
			column.Header:SetFont("gmx_info")
			column.Header:SetTall(30)
			function column.Header:Paint(w, h)
				surface.SetDrawColor(255, 157, 0, 200)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
		end

		local btn_open = frame:Add("DButton")
		btn_open:Dock(BOTTOM)
		btn_open:SetText("Open")
		btn_open:SetSize(frame:GetWide(), 30)
		btn_open:SetFont("gmx_info")
		btn_open:SetTextColor(COLOR_WHITE)

		local function update_list()
			list_view:Clear()

			for i, data in ipairs(gmx.ReplFilterCache) do
				local line = list_view:AddLine(tostring(i), data.Path, data.Method)
				for _, column in pairs(line.Columns) do
					column:SetTextColor(COLOR_WHITE)
				end

				function line:Paint(w, h)
					if self:IsHovered() or self:IsLineSelected() then
						self:SetCursor("hand")
						surface.SetDrawColor(255, 157, 0, 200)
						surface.DrawRect(0, 0, w, h)
					end
				end
			end
		end

		update_list()
		hook.Add("GMXReplFilterCacheChanged", list_view, update_list)

		function btn_open:Paint(w, h)
			surface.SetDrawColor(65, 40, 0, 200)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(255, 157, 0, 200)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
		end

		function btn_open:DoClick()
			local selected = list_view:GetSelected()
			if not selected or #selected == 0 then return end

			for _, line in pairs(selected) do
				local id = tonumber(line:GetColumnText(1)) or -1
				if id == -1 then continue end

				local data = gmx.ReplFilterCache[id]
				if not data then continue end

				gmx.OpenCodeTab(data.Path, data.Lua)
			end
		end

		function list_view:DoDoubleClick(_, line)
			local id = tonumber(line:GetColumnText(1)) or -1
			if id == -1 then return end

			local data = gmx.ReplFilterCache[id]
			if not data then return end

			gmx.OpenCodeTab(data.Path, data.Lua)
		end
	end

	concommand.Remove("gmx_repl_cache")
	concommand.Add("gmx_repl_cache", function()
		create_lua_cache_panel()
	end)
end