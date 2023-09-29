local GMX_HUD = CreateClientConVar("gmx_hud", "1", true)

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
	if not GMX_HUD:GetBool() then return end

	if element == "CHudPoisonDamageIndicator" then
		timer.Create("gmx_hud_poison", 1, 1, function()
			is_poisoned = false
		end)

		is_poisoned = true
		return false
	end

	if elements_to_hide[element] then return false end
end)

hook.Add("ShouldDrawNameTag", "gmx_hud", function()
	if not GMX_HUD:GetBool() then return end
	return false
end)

hook.Add("HUDDrawTargetID", "gmx_hud", function()
	if not GMX_HUD:GetBool() then return end
	return true
end)

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
local ARMOR_COLOR = Color(255, 162, 0, 240)
local TEXT_COLOR = Color(255, 255, 255)
local AMMO_COLOR = Color(200, 200, 200, 240)
local HUD_ANG = Angle(0, 45, 0)
local FAR_FRIEND = Color(255, 255, 255)
local FAR_NOT_FRIEND = Color(220, 0, 60)

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

local function smoothen_value(cur_value, target_value)
	if cur_value < target_value then
		local coef = (target_value - cur_value) * FrameTime() * 2
		cur_value = math.min(target_value, cur_value + coef)
	elseif cur_value > target_value then
		local coef = (cur_value - target_value) * FrameTime() * 2
		cur_value = math.max(target_value, cur_value - coef)
	end

	return cur_value
end

local last_health_perc, last_armor_perc = 1, 1
local function draw_local_player_hud()
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

	last_health_perc, last_armor_perc = smoothen_value(last_health_perc, health_perc), smoothen_value(last_armor_perc, armor_perc)

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
	local real_health_perc = LocalPlayer():Health() / LocalPlayer():GetMaxHealth()
	local health_text = (is_poisoned or not LocalPlayer():Alive()) and "\xe2\x98\xa0" or ("%.0f%%"):format(real_health_perc * 100)
	local health_text_w, _ = surface.GetTextSize(health_text)
	surface.SetTextPos(ScrW() / 2 - health_text_w / 2 - 50 * size_coef, ScrH() - 50 * size_coef)
	surface.DrawText(health_text)

	surface.SetTextColor(ARMOR_COLOR)
	local real_armor_perc = LocalPlayer():Armor() / LocalPlayer():GetMaxArmor()
	local armor_text = ("%.0f%%"):format(real_armor_perc * 100)
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

local function draw_rotated_value_rect(value, total_value, x, y, w, h, ang, color)
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

	local perc = math.max(0, math.min(1, value / total_value))
	surface.SetDrawColor(color)
	surface.DrawRect(x - w / 2, y + h  / 2 - h * perc, w, h * 10)

	render.SetStencilEnable(false)
end

local HEAD_OFFSET = Vector(0, 0, 25)
local MAX_DIST_FOR_VEHICLE = 500 * 500
local function draw_players_hud()
	--local size_coef = ScrW() / 2560
	--local size = 50 * size_coef

	local looked_at_ent = LocalPlayer():GetEyeTrace().Entity
	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() then continue end
		if ply == LocalPlayer() then continue end
		if ply:IsDormant() then continue end

		local is_friend = ply:GetFriendStatus() == "friend"
		local is_far = ply:GetPos():DistToSqr(LocalPlayer():GetPos()) >= MAX_DIST_FOR_VEHICLE
		local is_looked_at = IsValid(looked_at_ent) and looked_at_ent == ply
		local screen_pos = is_looked_at
			and { x = ScrW() / 2 + 100, y = ScrH() / 2, visible = true }
			or (is_far and ply:EyePos() or ply:EyePos() + HEAD_OFFSET):ToScreen()

		if not screen_pos.visible then continue end

		if is_far and not is_looked_at then
			draw.NoTexture()
			surface.SetDrawColor(is_friend and FAR_FRIEND or FAR_NOT_FRIEND)
			surface.DrawTexturedRectRotated(screen_pos.x, screen_pos.y, 8, 8, HUD_ANG.y)

			local screen_pos2 = ply:GetPos():ToScreen()
			surface.DrawLine(screen_pos.x - 1.5, screen_pos.y, screen_pos2.x - 1.5, screen_pos2.y)

			continue
		end

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

			if is_friend then
				surface.SetDrawColor(TEXT_COLOR)
				surface.DrawOutlinedRect(x + w + 5, y, h, h)

				surface.SetTextPos(x + w + 10, y + 2.5, h, h)
				surface.DrawText("F")
			end
		end

		-- health & armor square
		do
			local ang = is_looked_at and ((RealTime() * 100) % 360) or HUD_ANG.y

			ply.GMXHUDLastHealthPerc = smoothen_value(ply.GMXHUDLastHealthPerc or 1, ply:Health())
			ply.GMXHUDLastArmorPerc = smoothen_value(ply.GMXHUDLastArmorPerc or 1, ply:Armor())

			draw.NoTexture()
			if is_looked_at then
				surface.SetDrawColor(is_friend and FAR_FRIEND or FAR_NOT_FRIEND)
				surface.DrawTexturedRectRotated(screen_pos.x - 100, screen_pos.y, 7, 7, HUD_ANG.y)
				surface.DrawLine(screen_pos.x - 100, screen_pos.y, screen_pos.x, screen_pos.y)
			end

			surface.SetDrawColor(BG_COLOR)
			surface.DrawTexturedRectRotated(screen_pos.x, screen_pos.y, 45, 45, ang)

			draw_rotated_value_rect(ply.GMXHUDLastArmorPerc, ply:GetMaxArmor(), screen_pos.x, screen_pos.y, 100, 100, ang, ARMOR_COLOR)
			draw_rotated_value_rect(ply.GMXHUDLastHealthPerc, ply:GetMaxHealth(), screen_pos.x, screen_pos.y, 90, 90, ang, HEALTH_COLOR)

			draw.NoTexture()
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawTexturedRectRotated(screen_pos.x, screen_pos.y, 37, 37, ang)

			local health_raw_perc = (ply:Health() / ply:GetMaxHealth()) * 100
			local health_perc = health_raw_perc >= 1000 and ("%dK%%"):format(health_raw_perc / 1000) or ("%.0f%%"):format(health_raw_perc)

			surface.SetTextColor(TEXT_COLOR)
			surface.SetFont("gmd_hud_small")

			local tw, th = surface.GetTextSize(health_perc)
			surface.SetTextPos(screen_pos.x - tw / 2, screen_pos.y - th / 2)
			surface.DrawText(health_perc)
		end
	end
end

hook.Add("HUDPaint", "gmx_hud", function()
	if not GMX_HUD:GetBool() then return end

	update_font_sizes()
	draw_players_hud()
	draw_local_player_hud()
end)