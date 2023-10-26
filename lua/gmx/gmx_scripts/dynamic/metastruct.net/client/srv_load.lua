local GMX_HUD = GetConVar("gmx_hud")
if not GMX_HUD then
	GMX_HUD = CreateClientConVar("gmx_hud", "1", true)
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

surface.CreateFont("gmx_perf_hud", {
	font = "Arial",
	extended = true,
	size = 80,
	weight = 800,
})

surface.CreateFont("gmx_perf_hud_bg", {
	font = "Arial",
	extended = true,
	size = 30,
	weight = 800,
})

local net_buffer_size = 0
hook.Add("netincoming", "gmx_perf_hud", function(msg_name, len, client, fn)
	net_buffer_size = net_buffer_size + len
end)

local empty_buffer_frames = 0
hook.Add("Tick", "gmx_perf_hud", function()
	if net_buffer_size == 0 then
		empty_buffer_frames = empty_buffer_frames + 1
	else
		empty_buffer_frames = 0
	end

	net_buffer_size = 0
end)

local MAX_DATA_POINTS = 100
local MAX_HEIGHT = 80
local data_points = {}
local next_load = 0
local avg_ratio = 0
local same_frame_count = 0
hook.Add("HUDPaint", "gmx_perf_hud", function()
	if not GMX_HUD:GetBool() then return end

	hook.Remove("HUDPaint", "svfpshud") -- remove this annoying one

	local is_timing_out = GetTimeoutInfo()
	local max_fps = 1 / engine.TickInterval()
	local sfps, deviation = engine.ServerFrameTime()
	sfps = 1 / sfps

	if data_points[#data_points] and data_points[#data_points].fps == sfps and data_points[#data_points].deviation == deviation then
		same_frame_count = same_frame_count + 1
	else
		same_frame_count = 0
	end

	local is_net_buffering = empty_buffer_frames >= 20 and same_frame_count >= 10 and avg_ratio >= 0.25
	if not is_timing_out then
		local new_data_point = { max_fps = max_fps, fps = sfps, deviation = deviation }
		table.insert(data_points, new_data_point)
		if #data_points >= MAX_DATA_POINTS then
			table.remove(data_points, 1)
		end
	end

	local scale_coef = ScrW() / 2560
	local base_x, base_y = ScrW() - (40 + MAX_DATA_POINTS * 5), ScrH() - (40 + MAX_HEIGHT)
	local base_w, base_h = MAX_DATA_POINTS * 5, MAX_HEIGHT + 10

	local tr = Vector(base_x + base_w / 2, base_y + base_h / 2)
	local m = Matrix()
	m:Translate(tr)
	m:Scale(Vector(scale_coef, scale_coef, scale_coef))
	m:Translate(-tr)

	cam.PushModelMatrix(m)

	surface.SetTextColor(255, 255, 255, 200)
	surface.SetFont("gmx_perf_hud_bg")
	surface.SetTextPos(base_x, base_y - 35)
	surface.DrawText("SERVER LOAD")

	blur(base_x + (MAX_DATA_POINTS * 5) / 2, base_y + (MAX_HEIGHT + 10) / 2, base_w, base_h , 0, 2, 3)

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(base_x, base_y, base_w, base_h )

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(base_x, base_y, base_w, base_h )

	local total = 0
	for i, data_point in ipairs(data_points) do
		local ratio = math.min(1, data_point.fps / data_point.max_fps)
		local x, y = ScrW() - (40 + 5 * i), ScrH() - (40 + MAX_HEIGHT * (1 - ratio))
		surface.SetDrawColor(255, 100 + 155 * ratio, 100 + 155 * ratio, 255)
		surface.DrawRect(x, y, 2, 2)

		total = total + ratio

		local j = i + 1
		local next_data_point = data_points[j]
		if next_data_point then
			local next_ratio = math.min(1, next_data_point.fps / next_data_point.max_fps)
			local next_x, next_y = ScrW() - (40 + 5 * j), ScrH() - (40 + MAX_HEIGHT * (1 - next_ratio))

			surface.DrawLine(x, y, next_x, next_y)
		end
	end

	if SysTime() >= next_load then
		avg_ratio = total / #data_points
		next_load = SysTime() + 0.25
	end

	if is_timing_out or is_net_buffering then
		surface.SetTextColor(255, 0, 0, 255)
	else
		surface.SetTextColor(255, 100 + 155 * avg_ratio, 100 + 155 * avg_ratio, 255)
	end

	surface.SetFont("gmx_perf_hud")
	surface.SetTextPos(base_x + 10, base_y + 5)
	surface.DrawText(is_timing_out and "TIMEOUT" or is_net_buffering and "BUFFERING" or ("%d%%"):format((1 - avg_ratio) * 100))

	cam.PopModelMatrix()
end)