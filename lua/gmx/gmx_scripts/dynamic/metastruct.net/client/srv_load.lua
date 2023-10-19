hook.Remove("HUDPaint", "svfpshud") -- remove this annoying one

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

surface.CreateFont("gmx_perf_hud", {
	font = "Arial",
	extended = true,
	size = 100,
	weight = 800,
})

surface.CreateFont("gmx_perf_hud_bg", {
	font = "Arial",
	extended = true,
	size = 30,
	weight = 800,
})

local MAX_DATA_POINTS = 100
local MAX_HEIGHT = 100
local data_points = {}
local next_load = 0
local display_ratio = 0
hook.Add("HUDPaint", "gmx_perf_hud", function()
	local max_fps = 1 / engine.TickInterval()
	local sfps, deviation = engine.ServerFrameTime()
	sfps = 1 / sfps

	local new_data_point = { max_fps = max_fps, fps = sfps, deviation = deviation }
	table.insert(data_points, new_data_point)
	if #data_points >= MAX_DATA_POINTS then
		table.remove(data_points, 1)
	end

	local base_x, base_y = ScrW() - (50 + MAX_DATA_POINTS * 5), ScrH() - (60 + MAX_HEIGHT)

	surface.SetTextColor(255, 255, 255, 200)
	surface.SetFont("gmx_perf_hud_bg")
	surface.SetTextPos(base_x, base_y - 35)
	surface.DrawText("SERVER LOAD")

	blur(base_x + (MAX_DATA_POINTS * 5) / 2, base_y + (MAX_HEIGHT + 10) / 2, MAX_DATA_POINTS * 5, MAX_HEIGHT + 10, 0, 2, 3)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(base_x, base_y, MAX_DATA_POINTS * 5, MAX_HEIGHT + 10)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(base_x, base_y, MAX_DATA_POINTS * 5, MAX_HEIGHT + 10)

	local total = 0
	for i, data_point in ipairs(data_points) do
		local ratio = math.min(1, data_point.fps / data_point.max_fps)
		local x, y = ScrW() - (50 + 5 * i), ScrH() - (50 + MAX_HEIGHT * (1 - ratio))
		surface.SetDrawColor(255, 100 + 155 * ratio, 100 + 155 * ratio, 255)
		surface.DrawRect(x, y, 2, 2)

		total = total + ratio

		local j = i + 1
		local next_data_point = data_points[j]
		if next_data_point then
			local next_ratio = math.min(1, next_data_point.fps / next_data_point.max_fps)
			local next_x, next_y = ScrW() - (50 + 5 * j), ScrH() - (50 + MAX_HEIGHT * (1 - next_ratio))
			--local bad_factor = 1 - (math.abs(data_point.deviation - next_data_point.deviation) * 10000) / 100

			--surface.SetDrawColor(255, 255 * bad_factor, 255 * bad_factor, 255)
			surface.DrawLine(x, y, next_x, next_y)
		end
	end

	if SysTime() >= next_load then
		display_ratio = total / #data_points
		next_load = SysTime() + 0.25
	end

	surface.SetTextColor(255, 100 + 155 * display_ratio, 100 + 155 * display_ratio, 255)
	surface.SetFont("gmx_perf_hud")
	surface.SetTextPos(base_x + 10, base_y + 5)
	surface.DrawText(("%d%%"):format((1 - display_ratio) * 100))
end)