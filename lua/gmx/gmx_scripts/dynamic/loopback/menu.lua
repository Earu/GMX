hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
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
			hook.Remove("GMXInitialized", "gmx_crash_report")
			concommand.Add("gmx_cl", function(_, _, _, cmd)
				cmd = cmd:Trim()
				if #cmd == 0 then return end

				if file.Exists(cmd, "MOD") then
					local lua = file.Read(cmd, "MOD")
					RunString(lua, "gmx")
					return
				end

				local err = RunString(("print(select(1, %s))"):format(cmd), "gmx", false)
				if err then err = RunString(cmd, "gmx", false) end
				if err then error(err) end
			end)
		]]
	)

	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)