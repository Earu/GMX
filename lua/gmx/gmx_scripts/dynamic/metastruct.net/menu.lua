if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/outgoing.lua")

FilterOutgoingMessage(net_Tick, function(netchan, read, write)
	write:WriteUInt(net_Tick, NET_MESSAGE_BITS)

	local tick = read:ReadLong()
	write:WriteLong(tick)

	local frames = read:ReadUInt(16)
	write:WriteUInt(frames / 10, 16)

	local hostframetimedeviation = read:ReadUInt(16)
	write:WriteUInt(hostframetimedeviation, 16)
end)

hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
	local server_autorun_code = file.Read("lua/gmx/gmx_scripts/dynamic/metastruct.net/server.lua", "MOD")
	gmx.RunOnClient(("if luadev and luadev.RunOnServer then luadev.RunOnServer((%q):gsub(\"{STEAM_ID}\", LocalPlayer():SteamID()), \"GMX\") end"):format(server_autorun_code))

	-- for convenience
	gmx.RunOnClient(
		[[gmx = {
			Colors = {
				Text = Color(255, 255, 255, 255),
				TextAlternative = Color(200, 200, 200, 255),
				Wallpaper = Color(0, 0, 0),
				Background = Color(30, 30, 30),
				BackgroundStrip = Color(59, 59, 59),
				Accent = Color(255, 157, 0),
				AccentAlternative = Color(255, 196, 0),
			}
		}]] .. "\n"
		.. file.Read("lua/gmx/gmx_scripts/menu/debug.lua", "MOD")
		.. [[
			concommand.Add("gmx_cl", function(_, _, _, cmd)
				cmd = cmd:Trim()
				if #cmd == 0 then return end

				if file.Exists(cmd, "MOD") then
					local lua = file.Read(cmd, "MOD")
					RunString(lua, "gmx")
					return
				end

				local err = RunString(("GMX_DBG_PRINT(select(1, %q))"):format(cmd), "gmx", false)
				if err then
					error(err)
				end
			end)
		]]
	)

	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)