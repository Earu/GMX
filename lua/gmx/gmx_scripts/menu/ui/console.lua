require("enginespew")
require("fontsx")

surface.CreateFont("gmx_console", {
	font = fonts.Exists("Iosevka Type") and "Iosevka Type" or "Arial",
	extended = true,
	size = 20,
	weight = 500,
	antialias = true,
	shadow = false,
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
	local alpha = (gmx.Colors.Background.r > 128 and gmx.Colors.Background.g > 128 and gmx.Colors.Background.b > 128) and 20 or 200

	surface.SetDrawColor(gmx.Colors.Background.r, gmx.Colors.Background.g, gmx.Colors.Background.b, alpha)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(gmx.Colors.BackgroundStrip.r, gmx.Colors.BackgroundStrip.g, gmx.Colors.BackgroundStrip.b, alpha)
	surface.DrawLine(0, 0, 0, h)
end

local console_input_header = console:Add("DLabel")
console_input_header:SetFont("gmx_console")
gmx.SetVGUIElementColor(console_input_header, console_input_header.SetTextColor, "Text")
console_input_header:SetText("")
console_input_header:SetSize(75, 30)
console_input_header:SetPos(0, console:GetTall() - 30)

function console_input_header:Paint(w, h)
	local alpha = (gmx.Colors.Background.r > 128 and gmx.Colors.Background.g > 128 and gmx.Colors.Background.b > 128) and 20 or 200

	surface.SetDrawColor(gmx.Colors.Background.r, gmx.Colors.Background.g, gmx.Colors.Background.b, alpha)
	surface.DrawLine(0, 0, 0, h)

	surface.DisableClipping(true)
	surface.DrawLine(0, 0, console:GetWide(), 0)
	surface.DrawLine(0, h - 1, console:GetWide(), h - 1)
	surface.DrawLine(w - 12, 0, w, h / 2)
	surface.DrawLine(w - 12, h, w, h / 2)
	surface.DisableClipping(false)

	surface.SetTextColor(gmx.Colors.Text)
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
gmx.SetVGUIElementColor(console_input, console_input.SetTextColor, "Text")
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
	self:DrawTextEntryText(gmx.Colors.Text, gmx.Colors.Accent, gmx.Colors.AccentAlternative)

	surface.SetFont("gmx_console")
	surface.DisableClipping(true)

	for i, completion in pairs(cur_completions) do
		surface.SetTextColor(i == cur_selection and gmx.Colors.Accent or gmx.Colors.Text)
		local tw, th = surface.GetTextSize(completion)

		local x, y = -75 - tw, -i * (th + 5)
		surface.SetTextPos(x, y)
		surface.DrawText(completion)

		if i == cur_selection then
			surface.SetDrawColor(gmx.Colors.Accent)
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

	if (gmx.Colors.Text.r < 128 and gmx.Colors.Text.g < 128 and gmx.Colors.Text.b < 128)
		and (r == 255 and g == 255 and b == 255)
	then
		r, g, b = gmx.Colors.Text.r, gmx.Colors.Text.g, gmx.Colors.Text.b
	else
		if r == 0 and g == 0 and b == 0 then
			r, g, b = gmx.Colors.Text.r, gmx.Colors.Text.g, gmx.Colors.Text.b
		end
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

	if cmd:Trim() == "clear" then
		console_output:Clear()
		console_output:SetText("")
	end

	RunGameUICommand("engine " .. cmd)
	self:SetText("")

	console_output:InsertColorChange(gmx.Colors.Text.r, gmx.Colors.Text.g, gmx.Colors.Text.b, 255)
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
--RunGameUICommand("engine alias showconsole gmx_toggleconsole")

console:MakePopup()

hook.Add("GMXReload", "gmx_console", function()
	if not IsValid(console) then return end
	console:Remove()
end)