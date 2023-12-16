local GMX_HUD = GetConVar("gmx_hud")
if not GMX_HUD then
	GMX_HUD = CreateClientConVar("gmx_hud", "1", true)
end

local active_slot, active_pos = 0, 1
local function get_weapons()
	if not IsValid(LocalPlayer()) then return {}, -1 end -- during init

	local weps = LocalPlayer():GetWeapons()
	local weps_per_slot = {}

	if #weps < 1 then return weps_per_slot, -1 end

	local max_slot = 0
	table.sort(weps, function(a, b) return a:GetSlotPos() < b:GetSlotPos() end)

	for _, wep in ipairs(weps) do
		local slot = wep:GetSlot()
		if not weps_per_slot[slot] then
			weps_per_slot[slot] = {}
		end

		local pos = table.insert(weps_per_slot[slot], wep)
		if wep == LocalPlayer():GetActiveWeapon() then
			active_slot, active_pos = slot, pos
		end

		if slot > max_slot then
			max_slot = slot
		end
	end

	return weps_per_slot, max_slot
end

local held_weps, max_slot = {}, -1
local cur_slot = max_slot < 1 and 0 or 1
local cur_pos = 1
local is_active = false
local next_wheel = 0
local fast_switch = GetConVar("hud_fastswitch")
hook.Add("InputMouseApply", "gmx_hud_weapon_select", function(cmd, x, y, ang)
	if not GMX_HUD:GetBool() then return end

	local wep = LocalPlayer():GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "weapon_physgun" and input.IsMouseDown(MOUSE_LEFT) then return end

	local val = cmd:GetMouseWheel()

	if val == 0 then return end
	if SysTime() < next_wheel then return end

	next_wheel = math.abs(val) > 1 and 0 or SysTime() + 0.025

	held_weps, max_slot = get_weapons()
	if max_slot == -1 then return end

	surface.PlaySound("common/wpn_moveselect.wav")

	if not is_active then
		is_active = true
		cur_slot = active_slot
		cur_pos = active_pos

		--return
	end

	if val > 0 then
		cur_pos = cur_pos - 1
		if cur_pos < 1 then
			cur_slot = cur_slot - 1

			if cur_slot < 0 then
				cur_slot = max_slot
			end

			while not held_weps[cur_slot] do
				cur_slot = cur_slot - 1

				if cur_slot < 0 then
					cur_slot = max_slot
				end
			end

			cur_pos = (held_weps[cur_slot] and #held_weps[cur_slot] or 0)
		end
	elseif val < 0 then
		cur_pos = cur_pos + 1
		if cur_pos > (held_weps[cur_slot] and #held_weps[cur_slot] or 0) then
			cur_slot = cur_slot + 1
			if cur_slot > max_slot then
				cur_slot = 0
			end

			while not held_weps[cur_slot] do
				cur_slot = cur_slot + 1

				if cur_slot > max_slot then
					cur_slot = 0
				end
			end

			cur_pos = 1
		end
	end

	if fast_switch:GetBool() and IsValid(held_weps[cur_slot][cur_pos]) then
		input.SelectWeapon(held_weps[cur_slot][cur_pos])
		surface.PlaySound("common/wpn_hudoff.wav")
	end

	timer.Create("gmx_hud_weapon_select", 1.25, 1, function()
		is_active = false
	end)
end)

hook.Add("HUDShouldDraw", "gmx_hud_weapon_select", function(name)
	if not GMX_HUD:GetBool() then return end
	if name == "CHudWeaponSelection" then return false end
end)

hook.Add("PlayerButtonDown", "gmx_hud_weapon_select", function(ply, btn)
	if not GMX_HUD:GetBool() then return end
	if not IsFirstTimePredicted() then return end
	if btn >= 1 and btn <= 6 then
		held_weps, max_slot = get_weapons()
		if max_slot == -1 then return end

		timer.Create("gmx_hud_weapon_select", 1.25, 1, function()
			is_active = false
		end)

		if not is_active then
			is_active = true
			cur_pos = 1
			cur_slot = btn - 2

			return
		end

		if cur_slot == btn - 2 then
			cur_pos = cur_pos + 1
			if cur_pos > (held_weps[cur_slot] and #held_weps[cur_slot] or 0) then
				cur_pos = 1
			end
		else
			cur_slot = btn - 2
		end
	end
end)

hook.Add("PlayerBindPress", "gmx_hud_weapon_select", function(ply, bind)
	if not GMX_HUD:GetBool() then return end
	if ply ~= LocalPlayer() then return end
	if not is_active then return end

	if bind == "+attack" and held_weps[cur_slot] and IsValid(held_weps[cur_slot][cur_pos]) then
		surface.PlaySound("common/wpn_hudoff.wav")
		timer.Remove("gmx_hud_weapon_select")
		input.SelectWeapon(held_weps[cur_slot][cur_pos])
		is_active = false

		return true
	end
end)

surface.CreateFont("gmx_hud_weapon_select", {
	font = "Arial",
	extended = true,
	size = 18,
	weight = 800,
})

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

hook.Add("DrawOverlay", "gmx_hud_weapon_select", function()
	if not GMX_HUD:GetBool() then return end
	if not is_active then return end
	if not LocalPlayer():Alive() then return end

	local base_width = 200 * ScrW() / 2560
	local base_x = ScrW() / 2 - ((base_width + 5) * 6) / 2
	for slot = 0, 5 do
		local x = base_x + (base_width + 5) * slot

		surface.SetFont("gmx_hud_weapon_select")

		if held_weps[slot] then
			local h_add = 0
			for pos, wep in pairs(held_weps[slot]) do
				if not IsValid(wep) then continue end

				local y = 40 + 45 * pos + h_add
				local w, h = base_width, 40
				local is_selected = pos == cur_pos and cur_slot == slot
				if is_selected then
					h = 100
					h_add = 60
				end

				blur(x + w / 2, y + h / 2, w, h, 0, 2, 3)

				surface.SetDrawColor(0, 0, 0, 200)
				surface.DrawRect(x, y, w, h)

				render.SetScissorRect(x, y, x + w, y + h, true)

				draw.NoTexture()

				local name = (wep.PrintName or language.GetPhrase(wep:GetClass()))
				name = language.GetPhrase(name):upper()

				local tw, th = surface.GetTextSize(name)
				surface.SetTextPos(x + w / 2 - tw / 2, y + h / 2 - th / 2)


				if is_selected then
					surface.SetDrawColor(255, 255, 255, 240)
					surface.DrawOutlinedRect(x, y, w, h, 2)

					surface.SetTextColor(255, 255, 255, 255)
					surface.DrawTexturedRectRotated(x + w / 2 - tw / 2 - 20, y + h / 2, 8, 8, CurTime() * 300 % 360)
				else
					surface.SetDrawColor(0, 0, 0, 255)
					surface.DrawOutlinedRect(x, y, w, h, 1)
					surface.SetTextColor(255, 162, 0, 255)
				end

				surface.DrawText(name)

				render.SetScissorRect(x, y, w, h, false)
			end
		else
			blur(x + 100, 85 + 20, 200, 40, 0, 2, 3)
			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawRect(x, 85, base_width, 40)
		end

		surface.SetTextColor(255, 162, 0, 255)
		surface.SetTextPos(x + 10, 95)
		surface.DrawText("0" .. slot + 1)
	end
end)

--[[hook.Remove("DrawOverlay", "gmx_hud_weapon_select")
hook.Remove("PlayerBindPress", "gmx_hud_weapon_select")
hook.Remove("KeyPress", "gmx_hud_weapon_select")
hook.Remove("HUDShouldDraw", "gmx_hud_weapon_select")
hook.Remove("InputMouseApply", "gmx_hud_weapon_select")
hook.Remove("PlayerButtonDown", "gmx_hud_weapon_select")]]