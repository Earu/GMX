local function run_on_server()
	local server_autorun_code = file.Read("lua/gmx/gmx_scripts/dynamic/metastruct.net/server.lua", "MOD")
	gmx.RunOnClient(([[
		if engine.ActiveGamemode():match("sandbox") then
			local code = (%q):gsub("{STEAM_ID}", LocalPlayer():SteamID())
			if luadev and luadev.RunOnServer and hook.Run("LuaDevIsPlayerAllowed", LocalPlayer(), "") then
				luadev.RunOnServer(code, "GMX")
			elseif aowl and aowl.ConsoleCommand then
				aowl.ConsoleCommand(LocalPlayer(), nil, {"p"}, "      " .. code)
			end
		end
	]]):format(server_autorun_code))
end

hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
	run_on_server()
	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)

-- dont report our errors via HTTP
hook.Add("OnHTTPRequest", "gmx_no_error_reports", function(url)
	if url and url:lower():match("%/metaconcord%/gmod%/errors") then return true end
end)

if IsInGame() and not IsInLoading() then
	run_on_server()
end