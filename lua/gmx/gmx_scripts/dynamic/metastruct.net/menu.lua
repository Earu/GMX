hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
	local server_autorun_code = file.Read("lua/gmx/gmx_scripts/dynamic/metastruct.net/server.lua", "MOD")
	gmx.RunOnClient(("if luadev and luadev.RunOnServer then luadev.RunOnServer((%q):gsub(\"{STEAM_ID}\", LocalPlayer():SteamID()), \"GMX\") end"):format(server_autorun_code))

	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)

-- dont report our errors via HTTP
hook.Add("OnHTTPRequest", "gmx_no_error_reports", function(url)
	if url and url:lower():match("%/metaconcord%/gmod%/errors") then return true end
end)