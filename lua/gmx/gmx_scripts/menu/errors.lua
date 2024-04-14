local ERRORS = {}
hook.Add("OnLuaError", "MenuErrorHandler", function(str, realm, stack, addon_title, addon_id)
	addon_id = addon_id or 0

	if ERRORS[addon_id] then
		ERRORS[addon_id].times = ERRORS[addon_id].times + 1
		ERRORS[addon_id].last = SysTime()

		return
	end

	local text = ("[%s] %s"):format(realm:upper() .. (isstring(addon_title) and " | " .. addon_title or ""), stack[1] and stack[1].File or language.GetPhrase("errors.something_p"))
	ERRORS[addon_id] = {
		first = SysTime(),
		last = SysTime(),
		times = 1,
		title = addon_title,
		x = 32,
		text = text
	}
end)

local MAT_ALERT = Material("icon16/error.png")
local CL_DRAW_HUD = GetConVar("cl_drawhud")
local BLACK_COLOR = Color(0, 0, 0, 220)
local RED_COLOR = Color(255, 0, 0, 0)
hook.Add("DrawOverlay", "MenuDrawLuaErrors", function()
	if table.IsEmpty(ERRORS) then return end
	if not CL_DRAW_HUD:GetBool() then return end

	local ideal_y = 32
	local height = 30
	local end_time = SysTime() - 10
	local recent = SysTime() - 0.5
	for k, v in SortedPairsByMemberValue(ERRORS, "last") do
		surface.SetFont("DermaDefaultBold")

		if not v.y then
			v.y = ideal_y
		end

		if not v.w then
			v.w = surface.GetTextSize(v.text) + 48
		end

		draw.RoundedBox(2, v.x, v.y, v.w, height, BLACK_COLOR)

		if v.last > recent then
			RED_COLOR.a = (v.last - recent) * 510
			draw.RoundedBox(2, v.x, v.y, v.w, height, RED_COLOR)
		end

		surface.SetTextColor(255, 200, 0, 255)
		surface.SetTextPos(v.x + 34, v.y + 8)
		surface.DrawText(v.text)

		surface.SetDrawColor(255, 255, 255, 150 + math.sin(v.y + SysTime() * 30) * 100)
		surface.SetMaterial(MAT_ALERT)
		surface.DrawTexturedRect(v.x + 6, v.y + 6, 16, 16)

		v.y = ideal_y
		ideal_y = ideal_y + 40

		if v.last < end_time then
			ERRORS[k] = nil
		end
	end
end)