local color_white = Color(255, 255, 255)
local offset = Vector(0, 0, 20)
hook.Add("HUDPaint", GEN_NAME(), function()
	surface.SetTextColor(color_white)
	surface.SetFont("DermaDefaultBold")
	for _, ply in ipairs(player.GetAll()) do
		local text = tostring(ply)
		local tw, th = surface.GetTextSize(text)
		local pos = (ply:EyePos() + offset):ToScreen()
		surface.SetTextPos(pos.x - tw / 2, pos.y - th / 2)
		surface.DrawText(text)

		cam.Start3D()
		cam.IgnoreZ(true)
		ply:DrawModel()
		cam.IgnoreZ(false)
		cam.End3D()
	end
end)