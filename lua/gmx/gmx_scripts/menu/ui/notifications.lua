surface.CreateFont("GMXNotify", {
	font = "Arial",
	extended = true,
	size = 18,
	weight = 500,
})

local notices = {}
function gmx.Notification(text, length)
	local parent = nil
	if _G.GetOverlayPanel then
		parent = _G.GetOverlayPanel()
	end

	local panel = vgui.Create("GMXNoticePanel", parent)
	panel.StartTime = SysTime()
	panel.Length = math.max(length, 0)
	panel.VelX = -5
	panel.VelY = 0

	panel.fx = 10
	panel.fy = ScrH() + 200

	panel:SetAlpha(255)
	panel:SetText(text)
	panel:SetPos(panel.fx, panel.fy)

	table.insert(notices, panel)

	if not gui.IsGameUIVisible() then
		surface.PlaySound("ui/alert_clink.wav")
	end
end

-- This is ugly because it's ripped straight from the old notice system
local function update_notice(panel, total_h)
	local x = panel.fx
	local y = panel.fy
	local h = panel:GetTall() + 4
	local ideal_y = ScrH() - h - total_h - 50
	local ideal_x = 10
	local time_left = panel.StartTime - (SysTime() - panel.Length)

	if panel.Length < 0 then
		time_left = 1
	end

	-- Gone!
	if time_left < 0.2 then
		ideal_y = ideal_y + h * 2
	end

	local speed = FrameTime() * 15
	y = y + panel.VelY * speed
	x = x + panel.VelX * speed
	local dist = ideal_y - y
	panel.VelY = panel.VelY + dist * speed * 1

	if math.abs(dist) < 2 and math.abs(panel.VelY) < 0.1 then
		panel.VelY = 0
	end

	dist = ideal_x - x
	panel.VelX = panel.VelX + dist * speed * 1

	if math.abs(dist) < 2 and math.abs(panel.VelX) < 0.1 then
		panel.VelX = 0
	end

	-- Friction.. kind of FPS independant.
	panel.VelX = panel.VelX * (0.95 - FrameTime() * draw.GetFontHeight("GMXNotify"))
	panel.VelY = panel.VelY * (0.95 - FrameTime() * draw.GetFontHeight("GMXNotify"))
	panel.fx = x
	panel.fy = y

	-- If the panel is too high up (out of screen), do not update its position. This lags a lot when there are lot of panels outside of the screen
	if ideal_y > -ScrH() then
		panel:SetPos(panel.fx, panel.fy)
	end

	return total_h + h
end

hook.Add("Think", "GMXNotifications", function()
	if not notices then return end

	local h = 0
	for key, panel in pairs(notices) do
		h = update_notice(panel, h)
	end

	for k, panel in pairs(notices) do
		if not IsValid(panel) or panel:KillSelf() then
			notices[k] = nil
		end
	end
end)

hook.Add("GMXReload", "GMXNotifications", function()
	for k, panel in pairs(notices) do
		if IsValid(panel) then
			panel:Remove()
		end
	end
end)

local PANEL = {}
function PANEL:Init()
	self:DockPadding(15 + 8, 3, 3, 3)
	self.Label = vgui.Create("DLabel", self)
	self.Label:Dock(FILL)
	self.Label:SetFont("GMXNotify")
	self.Label:SetTextColor(gmx.Colors.Text)
	self:SetBackgroundColor(gmx.Colors.Background)
end

function PANEL:SetText(txt)
	self.Label:SetText(txt)
	self:SizeToContents()
end

function PANEL:SizeToContents()
	self.Label:SizeToContents()
	local width, tall = self.Label:GetSize()
	tall = math.max(tall, 32) + 6
	width = width + 30

	self:SetSize(width, tall)
	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	local bg_color = gmx.Colors.Background
	surface.SetDrawColor(bg_color.r, bg_color.b, bg_color.b, 200)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(gmx.Colors.Accent)
	surface.DrawOutlinedRect(0, 0, w, h)
	surface.DrawRect(0, 0, 15, h)
end

function PANEL:KillSelf()
	-- Infinite length
	if self.Length < 0 then return false end

	if self.StartTime + self.Length < SysTime() then
		self:Remove()

		return true
	end

	return false
end

vgui.Register("GMXNoticePanel", PANEL, "DPanel")

hook.Add("GMXUINotification", "gmx_ui_notifications", function(msg)
	gmx.Notification(msg:Trim(), 10)
end)