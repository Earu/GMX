
local elements_to_hide = {
	CHudBattery = true,
	CHudHealth = true,
	CHudSuitPower = true,
	CHudPoisonDamageIndicator = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
}

local is_poisoned = false
hook.Add("HUDShouldDraw", "gmx_hud", function(element)
	if element == "CHudPoisonDamageIndicator" then
		timer.Create("gmx_hud_poison", 1, 1, function()
			is_poisoned = false
		end)

		is_poisoned = true
		return false
	end

	if elements_to_hide[element] then return false end
end)

local FONT_HEIGHT = ScrW() > 1900 and 24 or 18
surface.CreateFont("gmx_hud", {
	font = "Roboto",
	extended = true,
	weight = 500,
	size = FONT_HEIGHT,
})

local BG_COLOR = Color(10, 10, 10, 200)
local HEALTH_COLOR = Color(220, 0, 60)
local HEALTH_POISONED_COLOR = Color(170, 255, 60, 200)
local ARMOR_COLOR = Color(3, 140, 252)
local TEXT_COLOR = Color(255, 255, 255)
local AMMO_COLOR = Color(200, 200, 200, 240)
local HUD_ANG = Angle(0, 45, 0)

local last_health_perc, last_armor_perc = 1, 1
hook.Add("HUDPaint", "gmx_hud", function()
	local size_coef = ScrW() / 2560
	local size, padding = 200 * size_coef, 80 * size_coef
	local x, y = ScrW() / 2 - size / 2, ScrH() - size / 2
	local bar_width, bar_margin = 36 * size_coef, 2 * size_coef
	local steps = 4

	local wep = LocalPlayer():GetActiveWeapon()
	local has_prim_ammo = IsValid(wep) and wep:GetPrimaryAmmoType() ~= -1 and wep:Clip1() ~= -1
	local has_sec_ammo = false
	local sec_ammo_count = 0

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

	if is_poisoned then
		surface.SetDrawColor(HEALTH_POISONED_COLOR)
		surface.DrawRect(x - (bar_width + bar_margin), y + ((size - padding) * -last_health_perc) + (size - padding), bar_width, (size - padding) * last_health_perc + size)
	end

	surface.SetDrawColor(BG_COLOR)
	for i = 0, steps do
		surface.DrawOutlinedRect(x - (bar_width + bar_margin * 2), y + i * size / steps, bar_width + bar_margin * 2, size / steps, 1)
	end

	-- primary ammo
	if has_prim_ammo then
		local max_clip = wep:GetMaxClip1() > -1 and wep:GetMaxClip1() or 255
		local ammo_steps = math.min(30, max_clip)
		local step_size = (size / ammo_steps)
		local step_x, step_y = x - bar_width * 2, y
		local cur_clip = wep:Clip1()

		for i = 1, ammo_steps do
			if cur_clip >= i then
				surface.SetDrawColor(AMMO_COLOR)
				surface.DrawRect(step_x, step_y + (i - 1) * step_size, 20 * size_coef, step_size - 2)

				surface.SetDrawColor(BG_COLOR)
				surface.DrawOutlinedRect(step_x, step_y + (i - 1) * step_size, 20 * size_coef, step_size - 2)
			else
				surface.SetDrawColor(BG_COLOR)
				surface.DrawRect(step_x, step_y + (i - 1) * step_size, 20 * size_coef, step_size - 2)
			end
		end
	end

	-- armor
	surface.SetDrawColor(ARMOR_COLOR)
	surface.DrawRect(x + ((size - padding) * -last_armor_perc) + (size - padding), y - (bar_width + bar_margin), (size - padding) * last_armor_perc + size, bar_width)

	surface.SetDrawColor(BG_COLOR)
	for i = 0, steps do
		surface.DrawOutlinedRect(x + i * size / steps, y - (bar_width + bar_margin * 2), size / steps, bar_width + bar_margin * 2, 1)
	end

	if IsValid(wep) then
		sec_ammo_count = wep:GetMaxClip2() > -1 and wep:Clip2() or -1
		if sec_ammo_count < 0 then
			sec_ammo_count = LocalPlayer():GetAmmoCount(has_prim_ammo and wep:GetSecondaryAmmoType() or wep:GetPrimaryAmmoType())
		end

		if sec_ammo_count > 0 then
			has_sec_ammo = true

			local max_clip = wep:GetMaxClip2() > -1 and wep:GetMaxClip2() or 15
			local ammo_steps = math.min(30, max_clip)
			local step_size = (size / ammo_steps)
			local step_x, step_y = x, y - bar_width * 2

			for i = 1, ammo_steps do
				if sec_ammo_count >= i then
					surface.SetDrawColor(AMMO_COLOR)
					surface.DrawRect(step_x + (i - 1) * step_size, step_y, step_size - 2, 20 * size_coef)

					surface.SetDrawColor(BG_COLOR)
					surface.DrawOutlinedRect(step_x + (i - 1) * step_size, step_y, step_size - 2, 20 * size_coef)
				else
					surface.SetDrawColor(BG_COLOR)
					surface.DrawRect(step_x + (i - 1) * step_size, step_y, step_size - 2, 20 * size_coef)
				end
			end
		end
	end

	surface.DisableClipping(false)
	cam.PopModelMatrix()

	surface.SetFont("gmx_hud")

	surface.SetTextColor(is_poisoned and HEALTH_POISONED_COLOR or HEALTH_COLOR)
	local health_text = (is_poisoned or not LocalPlayer():Alive()) and "\xe2\x98\xa0" or ("%.0f%%"):format(last_health_perc * 100)
	local health_text_w, _ = surface.GetTextSize(health_text)
	surface.SetTextPos(ScrW() / 2 - health_text_w / 2 - 50 * size_coef, ScrH() - 50 * size_coef)
	surface.DrawText(health_text)

	surface.SetTextColor(ARMOR_COLOR)
	local armor_text = ("%.0f%%"):format(last_armor_perc * 100)
	local armor_text_w, _ = surface.GetTextSize(armor_text)
	surface.SetTextPos(ScrW() / 2 - armor_text_w / 2 + 50 * size_coef, ScrH() - 50 * size_coef)
	surface.DrawText(armor_text)

	surface.SetTextColor(TEXT_COLOR)
	surface.SetTextPos(ScrW() / 2 - 5 * size_coef, ScrH() - 50 * size_coef)
	surface.DrawText("/")

	local nick = LocalPlayer().EngineNick and LocalPlayer():EngineNick() or LocalPlayer():Nick()
	local nick_text_w, _ = surface.GetTextSize(nick)
	surface.SetTextPos(ScrW() / 2 - nick_text_w / 2, ScrH() - 90 * size_coef)
	surface.DrawText(nick)

	if has_prim_ammo then
		local ammo_text = tostring(math.min(9999, wep:Clip1())) .. " / " .. tostring(math.min(9999, LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType())))
		local ammo_text_w, _ = surface.GetTextSize(ammo_text)

		local ammo_mtx = Matrix()
		ammo_mtx:Translate(tr)
		ammo_mtx:SetAngles(-HUD_ANG)
		ammo_mtx:Translate(-tr)

		cam.PushModelMatrix(ammo_mtx)
		surface.DisableClipping(true)

		surface.SetDrawColor(BG_COLOR)
		surface.DrawRect(ScrW() / 2 - ammo_text_w / 2 - 20, ScrH() - size / 2 - FONT_HEIGHT * 2, ammo_text_w + 40, FONT_HEIGHT)

		surface.SetTextColor(AMMO_COLOR)
		surface.SetTextPos(ScrW() / 2 - ammo_text_w / 2, ScrH() - size / 2 - FONT_HEIGHT * 2)
		surface.DrawText(ammo_text)

		surface.DisableClipping(false)
		cam.PopModelMatrix()
	end

	if has_sec_ammo then
		local ammo_text = tostring(sec_ammo_count)
		local ammo_text_w, _ = surface.GetTextSize(ammo_text)

		local ammo_mtx = Matrix()
		ammo_mtx:Translate(tr)
		ammo_mtx:SetAngles(HUD_ANG)
		ammo_mtx:Translate(-tr)

		cam.PushModelMatrix(ammo_mtx)
		surface.DisableClipping(true)

		surface.SetDrawColor(BG_COLOR)
		surface.DrawRect(ScrW() / 2 - ammo_text_w / 2 - 20, ScrH() - size / 2 - FONT_HEIGHT * 2, ammo_text_w + 40, FONT_HEIGHT)

		surface.SetTextColor(AMMO_COLOR)
		surface.SetTextPos(ScrW() / 2 - ammo_text_w / 2, ScrH() - size / 2 - FONT_HEIGHT * 2)
		surface.DrawText(ammo_text)

		surface.DisableClipping(false)
		cam.PopModelMatrix()
	end
end)