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

hook.Add("ShouldDrawNameTag", "gmx_hud", function() return false end)
hook.Add("HUDDrawTargetID", "gmx_hud", function() return true end)

local FONT_HEIGHT = ScrW() > 1900 and 24 or 18
surface.CreateFont("gmx_hud", {
	font = "Roboto",
	extended = true,
	weight = 500,
	size = FONT_HEIGHT,
})

local FONT_HEIGHT_BIG = math.max(20, 32 * ScrH() / 1440)
surface.CreateFont("gmd_hud_big", {
	font = "Roboto",
	extended = true,
	weight = 500,
	size = FONT_HEIGHT_BIG,
})

local FONT_HEIGHT_SMALL = math.max(18, 18 * ScrH() / 1440)
surface.CreateFont("gmd_hud_small", {
	font = "Roboto",
	extended = true,
	weight = 500,
	size = FONT_HEIGHT_SMALL,
})

local BG_COLOR = Color(10, 10, 10, 200)
local HEALTH_COLOR = Color(220, 0, 60)
local HEALTH_POISONED_COLOR = Color(170, 255, 60, 200)
local ARMOR_COLOR = Color(3, 140, 252)
local TEXT_COLOR = Color(255, 255, 255)
local AMMO_COLOR = Color(200, 200, 200, 240)
local HUD_ANG = Angle(0, 45, 0)

local last_scrw, last_scrh = ScrW(), ScrH()
local function update_font_sizes()
	if ScrW() ~= last_scrw or ScrH() ~= last_scrh then
		last_scrw, last_scrh = ScrW(), ScrH()

		-- update these with resolution change
		FONT_HEIGHT = ScrW() > 1900 and 24 or 18
		FONT_HEIGHT_BIG = math.max(20, 32 * ScrH() / 1440)
	end
end

local BLUR_MAT = Material("pp/blurscreen")
local function blur(x, y, w, h, ang, layers, quality)
	-- Reset everything to known good
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.ClearStencil()

	render.SetStencilEnable(true)

	-- Set the reference value to 1. This is what the compare function tests against
	render.SetStencilReferenceValue(1)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	-- Refuse to write things to the screen unless that pixel's value is 1
	render.SetStencilCompareFunction(STENCIL_NEVER)

	draw.NoTexture()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRectRotated(x, y, w, h, ang)

	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilCompareFunction(STENCIL_EQUAL)

	surface.SetMaterial(BLUR_MAT)
	surface.SetDrawColor(255, 255, 255, 255)
	for i = 1, layers do
		BLUR_MAT:SetFloat("$blur", (i / layers) * quality)
		BLUR_MAT:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	render.SetStencilEnable(false)
end

local last_health_perc, last_armor_perc = 1, 1
local function draw_own_hud()
	local size_coef = ScrW() / 2560
	local size, padding = 200 * size_coef, 80 * size_coef
	local x, y = ScrW() / 2 - size / 2, ScrH() - size / 2
	local bar_width, bar_margin = 36 * size_coef, 2 * size_coef
	local steps = 4

	local wep = LocalPlayer():GetActiveWeapon()
	local has_prim_ammo = IsValid(wep) and (wep:GetPrimaryAmmoType() ~= -1 or wep:Clip1() ~= -1)
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

	blur(x + size / 2, y + size / 2 + 85 * size_coef, size * 2, size * 2, HUD_ANG.y, 2, 3)

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
		local ammo_steps = wep:GetMaxClip1() > -1 and math.min(50, wep:GetMaxClip1()) or 30
		local step_size = (size / ammo_steps)
		local step_x, step_y = x - bar_width * 2, y
		local cur_clip = wep:Clip1() ~= -1 and wep:Clip1() or LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType())

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
			local ammo_steps = math.min(15, max_clip)
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

	surface.SetFont("gmd_hud_big")

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

	surface.SetFont("gmx_hud")

	local nick = LocalPlayer().EngineNick and LocalPlayer():EngineNick() or LocalPlayer():Nick()
	local nick_text_w, _ = surface.GetTextSize(nick)
	surface.SetTextPos(ScrW() / 2 - nick_text_w / 2, ScrH() - 90 * size_coef)
	surface.DrawText(nick)

	surface.SetFont("gmd_hud_big")

	if has_prim_ammo then
		local total_ammos = wep:GetPrimaryAmmoType() > -1 and LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType()) or wep:GetMaxClip1()
		local cur_clip = math.min(9999, wep:Clip1())
		local ammo_text = "EMPTY"

		if cur_clip > -1 then
			ammo_text = tostring(math.min(9999, wep:Clip1()))
		end

		if total_ammos > 0 then
			if cur_clip > -1 then
				ammo_text = ammo_text .. " / " .. tostring(math.min(9999, total_ammos))
			else
				ammo_text = tostring(math.min(9999, total_ammos))
			end
		elseif cur_clip <= 0 then
			ammo_text = "EMPTY"
		end

		local ammo_text_w, _ = surface.GetTextSize(ammo_text)

		local ammo_mtx = Matrix()
		ammo_mtx:Translate(tr)
		ammo_mtx:SetAngles(-HUD_ANG)
		ammo_mtx:Translate(-tr)

		cam.PushModelMatrix(ammo_mtx)
		surface.DisableClipping(true)

		surface.SetDrawColor(BG_COLOR)
		surface.DrawRect(ScrW() / 2 - ammo_text_w / 2 - 20, ScrH() - size / 2 - FONT_HEIGHT_BIG * 2 - 10 * size_coef, ammo_text_w + 40, FONT_HEIGHT_BIG)

		surface.SetTextColor(AMMO_COLOR)
		surface.SetTextPos(ScrW() / 2 - ammo_text_w / 2, ScrH() - size / 2 - FONT_HEIGHT_BIG * 2 - 10 * size_coef)
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
		surface.DrawRect(ScrW() / 2 - ammo_text_w / 2 - 20, ScrH() - size / 2 - FONT_HEIGHT_BIG * 2 - 10 * size_coef, ammo_text_w + 40, FONT_HEIGHT_BIG)

		surface.SetTextColor(AMMO_COLOR)
		surface.SetTextPos(ScrW() / 2 - ammo_text_w / 2, ScrH() - size / 2 - FONT_HEIGHT_BIG * 2 - 10 * size_coef)
		surface.DrawText(ammo_text)

		surface.DisableClipping(false)
		cam.PopModelMatrix()
	end
end

local function draw_player_health_square(value, total_value, x, y, w, h, ang, color)
	-- Reset everything to known good
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.ClearStencil()

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	render.SetStencilCompareFunction(STENCIL_NEVER)

	draw.NoTexture()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRectRotated(x, y, w / 2, h / 2, ang)

	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilCompareFunction(STENCIL_EQUAL)

	local perc = value / total_value
	surface.SetDrawColor(color)
	surface.DrawRect(x - w / 2, y + h  / 2 - h * perc, w, h * 10)

	render.SetStencilEnable(false)
end

local HEAD_OFFSET = Vector(0, 0, 25)
local function draw_players_hud()
	--local size_coef = ScrW() / 2560
	--local size = 50 * size_coef

	local looked_at_ent = LocalPlayer():GetEyeTrace().Entity
	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() then continue end
		if ply == LocalPlayer() then continue end

		local screen_pos = IsValid(looked_at_ent) and looked_at_ent == ply
			and { x = ScrW() / 2, y = ScrH() / 2 - 100, visible = true }
			or (ply:EyePos() + HEAD_OFFSET):ToScreen()

		if not screen_pos.visible then continue end

		-- nick
		do
			local nick = ply:Nick()
			surface.SetTextColor(TEXT_COLOR)
			surface.SetFont("gmd_hud_small")

			local tw, _ = surface.GetTextSize(nick)
			local x, y, w, h = screen_pos.x, screen_pos.y - FONT_HEIGHT_SMALL / 2 - 1, tw + 50, FONT_HEIGHT_SMALL + 2
			blur(x + w / 2, y + h / 2, w, h, 0, 2, 3)

			surface.SetDrawColor(BG_COLOR)
			surface.DrawRect(x, y, w, h)

			surface.SetTextPos(screen_pos.x + 40, screen_pos.y - FONT_HEIGHT_SMALL / 2)
			surface.DrawText(nick)
		end

		-- health & armor square
		do
			blur(screen_pos.x, screen_pos.y, 45, 45, HUD_ANG.y, 2, 3)

			draw.NoTexture()
			surface.SetDrawColor(BG_COLOR)
			surface.DrawTexturedRectRotated(screen_pos.x, screen_pos.y, 45, 45, HUD_ANG.y)

			draw_player_health_square(ply:Armor(), ply:GetMaxArmor(), screen_pos.x, screen_pos.y, 70, 70, 45, AMMO_COLOR)
			draw_player_health_square(ply:Health(), ply:GetMaxHealth(), screen_pos.x, screen_pos.y, 65, 65, 45, HEALTH_COLOR)

			local health_perc = ("%.0f%%"):format((ply:Health() / ply:GetMaxHealth()) * 100)
			surface.SetTextColor(TEXT_COLOR)
			surface.SetFont("gmd_hud_small")

			local tw, th = surface.GetTextSize(health_perc)
			surface.SetTextPos(screen_pos.x - tw / 2, screen_pos.y - th / 2)
			surface.DrawText(health_perc)
		end
	end
end

hook.Add("HUDPaint", "gmx_hud", function()
	update_font_sizes()
	draw_players_hud()
	draw_own_hud()
end)