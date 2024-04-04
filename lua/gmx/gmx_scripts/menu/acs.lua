hook.Add("RunOnClient", "gmx_acs", function(source, script)
	if gmx.IsHostWhitelisted() then return end

	source = source:lower()

	if source:find("cl_anticheat.lua") and script:find("Awesome AntiCheat Plugin - AACP") or source:find("cl_settingsderma.lua") then return false end -- Awesome Anti-Cheat Plugin (AACP)
	if source:find("cl_draw_check.lua") or script:find("Blade AntiCheat?") then return false end -- Blade Anti-Cheat (BAC)
	if source:find("cl_dazanticheat.lua") then return false end -- Daz Anti-Cheat (DAC)
	if source:find("fuckme.lua") and script:find("mrand()") then return false end -- Flow Network Anti-Cheat (FNAC)
	if script:find("mAC_Ban") then return false end -- GmodZ Anti-Cheat
	if script:find("local servRCC") then return false end -- Sharkey's(?) Anti-Cheat (SAC)
	if source:find("cl_leyac_menu.lua") then return false end -- LeyAC Anti-Cheat (LAC)
	if source:find("cl_vbac.lua") then return false end -- Very Basic Anti-Cheat (VBAC)

	-- Fish Anti-Cheat (FAC)
	if script:find("//---Fish's AntiCheat---//") then
		return [[
			usermessage.Hook("facSTL", function()
				net.Start("ferpHUDSqu")
					net.WriteTable({})
					net.WriteString("garrysmod")
				net.SendToServer()
			end)
		]]
	end

	-- Kevlar
	if source:find("cl_kevlar.lua") then
		--[[
			I assume this is some sort of global notification
			that someone was just caught cheating? Whatever,
			not like it hurts to listen for this message.
		--]]
		return [[
			net.Receive("lolwut", function()
				for i = 1, 6 do
					if (i <= 4) then
						net.Start("lolwut")
							net.WriteInt(i, 8)
							net.WriteTable({})
						net.SendToServer()
					else
						net.Start("lolwut")
							net.WriteInt(i, 8)
							net.WriteString("N/A")
						net.SendToServer()
					end
				end
			end)
			net.Receive("gotcha", function()
				chat.AddText(Color(0, 100, 255), "[Kevlar] ", Color(255, 255, 255), net.ReadString())
			end)
		]]
	end

	-- LeyAC
	if source == "luacmd" and (script:find("if not " .. hi_pass) or script:find("LeyAC = false if")) then
		return [[
			local receive_pass = "ijustwannahaveyourightbymyside"
			local hi_pass = "hellohellohelloimcool"
			net.Start(receive_pass)
				net.WriteString(" ")
			net.SendToServer()
		]]
	end

	if source:find("_ley_imp.lua") then
		if not script:find("CheckCV") then
			return [[
				local receive_pass = "ijustwannahaveyourightbymyside"
				local hi_pass = "hellohellohelloimcool"
				net.Receive(receive_pass, function()
					net.Start(receive_pass)
						net.WriteString(" ")
					net.SendToServer()
				end)
				hook.Add("InitPostEntity", "LeyAC", function()
					net.Start(receive_pass)
						net.WriteString("in")
						net.WriteString(hi_pass)
					net.SendToServer()
					hook.Remove("InitPostEntity", "LeyAC")
				end)
			]]
		else
			return [[
				local receive_pass = "ijustwannahaveyourightbymyside"
				local hi_pass = "hellohellohelloimcool"
				local trash = ""
				for i = 1, 1000 do
					trash = trash .. "a"
				end
				net.Receive(receive_pass, function()
					local message = net.ReadString()
					if message == "a" then
						net.Start(receive_pass)
							net.WriteString("in")
							net.WriteUInt(#trash, 32)
							net.WriteString(hi_pass)
							net.WriteData(trash, #trash)
						net.SendToServer()
					elseif message == "c" then
						chat.AddText(Color(0, 154, 255), "[ACS] ", Color(255, 255, 255), "LeyAC attempted to screenshot you.")
					elseif message == "z" then
						chat.AddText(Color(0, 154, 255), "[ACS] ", Color(255, 255, 255), "LeyAC attempted to read your files.")
					end
				end)
			]]
		end
	end

	-- NNJG Anti-Cheat
	if script:find("tc(name1") then
		return [[
			local leave_net = "fxxcvsaw3t"
			net.Receive(leave_net, function()
				local ply = net.ReadEntity()
				if IsValid(ply) then
					chat.AddText(Color(255, 0, 0, 255), ply:Nick() .. " is a dirty cheater!")
				end
			end)
		]]
	end

	-- Quack Anti-Cheat (QAC)
	if source:find("cl_qac.lua") then
		return [[
			net.Receive("Ping2", function()
				local CNum = net.ReadInt(10)
				net.Start("Ping1")
					net.WriteInt(CNum, 16)
				net.SendToServer()
			end)
			net.Receive("Debug2", function()
				local CNum = net.ReadInt(10)
				net.Start("Debug1")
					net.WriteInt(CNum, 16)
				net.SendToServer()
			end)
		]]
	end

	if source:find("sh_screengrab.lua") or source:find("cl_screengrab.lua") then
		return [[
			net.Receive("screengrab_start", function()
				net.Start("screengrab_start")
					net.WriteUInt(1, 32)
				net.SendToServer()
			end)
			net.Receive("screengrab_part", function()
				net.Start("screengrab_part")
					net.WriteUInt(1, 32 )
					net.WriteData(util.Compress(1), len )
				net.SendToServer()
			end)
		]]
	end

	-- Tyler's Anti-Cheat (TAC)
	if source:find("cl_blunderbuss.lua") then
		return [[
			timer.Create("TACTimer", math.random(60, 120), 0, function()
				net.Start("ttt_scoreboard")
					net.WriteString("gotit")
				net.SendToServer()
				net.Start("dm_vars")
					net.WriteString("gotit")
				net.SendToServer()
			end)
		]]
	end

	-- General annoyances
	if script:find("while true do end") then
		gmx.Print("The server attempted to crash you.", source)
		return false
	end
end)