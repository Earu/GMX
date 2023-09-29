hook.Add("DrawOverlay", "gmx_hostname_custom_code", function()
	if not IsInGame() then return end
	if gui.IsGameUIVisible() then return end
	if not gmx.RunningHostCode() then return end

	local x = ScrW() / 10
	local alpha = 100 + math.abs(math.sin(CurTime() * 3)) * 155
	local bg_r, bg_g, bg_b = gmx.Colors.Background:Unpack()
	local a_r, a_g, a_b = gmx.Colors.Accent:Unpack()

	surface.SetDrawColor(bg_r, bg_g, bg_b, alpha)
	surface.DrawRect(x - 5, 9, 250, 20)

	surface.SetFont("gmx_info")
	surface.SetTextColor(a_r, a_g, a_b, alpha)
	surface.SetTextPos(x, 10)
	surface.DrawText("● GMX - HOST SCRIPTS RUNNING")
end)