HOOK("HUDPaint", function()
	for _, ply in ipairs(player.GetAll()) do
		local pos = ply:GetPos():ToScreen()
		if not pos.visible then continue end

		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(pos.x, pos.y, 5, 5)
	end
end)