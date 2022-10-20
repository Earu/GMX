
local elements_to_hide = {
	CHudBattery = true,
	CHudHealth = true,
	CHudSuitPower = true,
	CHudPoisonDamageIndicator = true,
	CHudAmmo = true
}
hook.Add("HUDShouldDraw", "gmx_hud", function(element)
	if elements_to_hide[element] then return false end
end)

surface.CreateFont("gmx_hud", {
	font = "Roboto",
	extended = true,
	weight = 500,
	size = 24
})

local BG_COLOR = Color(10, 10, 10, 200)
local HEALTH_COLOR = Color(220, 0, 60)
local ARMOR_COLOR = Color(3, 140, 252)
local TEXT_COLOR = Color(255, 255, 255)
local HUD_ANG = Angle(0, 45, 0)

local last_health_perc, last_armor_perc = 1, 1
hook.Add("HUDPaint", "gmx_hud", function()
	local size, padding = 200, 80
	local x, y = ScrW() / 2 - size / 2, ScrH() - size / 2
	local bar_width, bar_margin = 35, 2

	local health_perc = math.min(1, LocalPlayer():Health() / LocalPlayer():GetMaxHealth())
	local armor_perc = math.min(1, LocalPlayer():Armor() / LocalPlayer():GetMaxArmor())

	if last_health_perc < health_perc then
		local coef = (health_perc - last_health_perc) * FrameTime() * 2
		last_health_perc = math.min(health_perc, last_health_perc + coef)
	elseif last_health_perc > health_perc then
		local coef = (last_health_perc - health_perc) * FrameTime() * 2
		last_health_perc = math.max(health_perc, last_health_perc - coef)
	end

	if last_armor_perc < armor_perc then
		local coef = (armor_perc - last_armor_perc) * FrameTime() * 2
		last_armor_perc = math.min(armor_perc, last_armor_perc + coef)
	elseif last_armor_perc > armor_perc then
		local coef = (last_armor_perc - armor_perc) * FrameTime() * 2
		last_armor_perc = math.max(armor_perc, last_armor_perc - coef)
	end

	local tr = Vector(x + size / 2, y + size / 2)
	local m = Matrix()
	m:Translate(tr)
	m:SetAngles(HUD_ANG)
	m:Translate(-tr)

	cam.PushModelMatrix(m)
	surface.DisableClipping(true)

	if health_perc <= 0.2 and armor_perc <= 0.1 then
		surface.SetDrawColor(255, 0, 0, 100 * math.abs(math.sin(CurTime() * 3)))
		surface.DrawRect(x - padding / 2, y - padding / 2, size * 2, size * 2)
	end

	surface.SetDrawColor(BG_COLOR)
	surface.DrawRect(x, y, size - padding + size, size - padding + size)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(x - padding / 2, y - padding / 2, size * 2, size * 2)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(x - padding / 2, y - padding / 2, padding / 2, padding / 2)

	size = size + (size / 2)

	-- health
	surface.SetDrawColor(HEALTH_COLOR)
	surface.DrawRect(x - (bar_width + bar_margin), y + ((size - padding) * -last_health_perc) + (size - padding), bar_width, (size - padding) * last_health_perc + size)

	surface.SetDrawColor(0, 0, 0, 200)
	for i = 0, 4 do
		surface.DrawOutlinedRect(x - (bar_width + bar_margin * 2), y + i * size / 4, bar_width + bar_margin * 2, (size - padding) + size, 2)
	end

	-- armor
	surface.SetDrawColor(ARMOR_COLOR)
	surface.DrawRect(x + ((size - padding) * -last_armor_perc) + (size - padding), y - (bar_width + bar_margin), (size - padding) * last_armor_perc + size, bar_width)

	surface.SetDrawColor(0, 0, 0, 200)
	for i = 0, 4 do
		surface.DrawOutlinedRect(x + i * size / 4, y - (bar_width + bar_margin * 2), (size - padding) + size, bar_width + bar_margin * 2, 2)
	end

	surface.DisableClipping(false)
	cam.PopModelMatrix()

	surface.SetFont("DermaLarge")

	surface.SetTextColor(HEALTH_COLOR)
	local health_text = ("%.0f%%"):format(last_health_perc * 100)
	local health_text_w, _ = surface.GetTextSize(health_text)
	surface.SetTextPos(ScrW() / 2 - health_text_w / 2 - 50, ScrH() - 50)
	surface.DrawText(health_text)

	surface.SetTextColor(ARMOR_COLOR)
	local armor_text = ("%.0f%%"):format(last_armor_perc * 100)
	local armor_text_w, _ = surface.GetTextSize(armor_text)
	surface.SetTextPos(ScrW() / 2 - armor_text_w / 2 + 50, ScrH() - 50)
	surface.DrawText(armor_text)

	surface.SetTextColor(TEXT_COLOR)
	surface.SetTextPos(ScrW() / 2 - 5, ScrH() - 50)
	surface.DrawText("/")

	surface.SetFont("gmx_hud")
	local nick = LocalPlayer().EngineNick and LocalPlayer():EngineNick() or LocalPlayer():Nick()
	local nick_text_w, _ = surface.GetTextSize(nick)
	surface.SetTextPos(ScrW() / 2 - nick_text_w / 2, ScrH() - 90)
	surface.DrawText(nick)
end)