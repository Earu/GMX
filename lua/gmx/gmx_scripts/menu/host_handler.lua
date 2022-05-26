require("asc")
require("dns")

local function sanitize_address(address)
	if not address then return end
	return address:Trim():gsub("%:[0-9]+$", "")
end

local INVALID_IP = "0.0.0.0"
local cached_address
function gmx.GetConnectedServerIPAddress()
	if cached_address == "loopback" then return cached_address end

	if cached_address then
		local ip = cached_address
		if not cached_address:match("^%d+%.%d+%.%d+%.%d+$") then
			local succ, err = pcall(dns.Lookup, cached_address)
			if succ then ip = err[1] else ip = nil end
		end

		if ip then
			cached_address = ip
			return cached_address
		end
	end

	return INVALID_IP
end

local old_game_details = _G.GameDetails
function GameDetails(server_name, server_url, map_name, max_players, steamid, gm)
	if gmx.GetConnectedServerIPAddress() == INVALID_IP then
		gmx.Print("Joining server via Steam or retry command, relying on public Steam API...")
		http.Fetch("http://steamcommunity.com/profiles/" .. steamid .. "?xml=1", function(xml)
			cached_address = sanitize_address(xml:match("%<inGameServerIP%>(.+)%<%/inGameServerIP%>"))
			if not cached_address then
				gmx.Print("Failed to get server IP address, Steam profile is private!")
			else
				hook.Run("GMXHostConnected", gmx.GetConnectedServerIPAddress())
			end
		end, function(err)
			gmx.Print("Failed to get server IP address: " .. err)
		end)
	end

	old_game_details(server_name, server_url, map_name, max_players, steamid, gm)
end

if IsInGame() then
	gmx.RequestClientData("game.GetIPAddress()", function(ip)
		cached_address = sanitize_address(ip)
	end)
end

--
-- GetConfigValue( ESteamNetworkingConfigValue eValue, ESteamNetworkingConfigScope eScopeType, intptr_t scopeObj, ESteamNetworkingConfigDataType *pOutDataType, void *pResult, size_t *cbResult );

hook.Add("AllowStringCommand", "gmx_host_address", function(cmd_str)
	if cmd_str:lower():match("^connect") then
		local args = cmd_str:lower():Split(" ")
		cached_address = sanitize_address(table.concat(args, " ", 2))

		hook.Run("GMXHostConnected", gmx.GetConnectedServerIPAddress())
	elseif cmd_str:lower():match("^disconnect") then
		cached_address = nil
		hook.Run("GMXHostDisconnected")
	end
end)

local host_ip_cvar = GetConVar("hostip")
function gmx.GetLocalNetworkIPAddress()
	local host_ip = host_ip_cvar:GetInt()
	local ip = {}

	ip[1] = bit.rshift(bit.band(host_ip, 0xFF000000), 24)
	ip[2] = bit.rshift(bit.band(host_ip, 0x00FF0000), 16)
	ip[3] = bit.rshift(bit.band(host_ip, 0x0000FF00), 8)
	ip[4] = bit.band(host_ip, 0x000000FF)

	return table.concat(ip, ".")
end

local WHITELIST = {
	["0"] = true, -- menu
	["149.202.89.113"] = true, -- s1.hbn.gg:27025
}

function gmx.IsGameWhitelisted()
	if not IsInGame() then return true end
	return WHITELIST[gmx.GetConnectedServerIPAddress()] ~= nil
end

local HOSTNAMES_TO_REVERSE = {
	"g2.metastruct.net", "g1.metastruct.net"
}

local HOSTNAME_LOOKUP = {}
for _, hostname in ipairs(HOSTNAMES_TO_REVERSE) do
	local ips = dns.Lookup(hostname)
	for _, ip in ipairs(ips) do
		HOSTNAME_LOOKUP[ip] = hostname
	end
end

local function run_host_custom_code(ip)
	local hostname = HOSTNAME_LOOKUP[ip]
	if not hostname then return end

	gmx.Print("Hostname Detected", ip)

	local custom_hostname_code_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(hostname)
	if not file.Exists(custom_hostname_code_path, "MOD") then -- priority to subdomains then global domain
		local hostname_components = hostname:Split(".")
		local base_hostname = ("%s.%s"):format(hostname_components[#hostname_components - 1], hostname_components[#hostname_components])
		custom_hostname_code_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(base_hostname)
	end

	gmx.Print("Loading Custom Code", hostname, custom_hostname_code_path)

	local custom_hostname_menu_script_path = ("%s/menu.lua"):format(custom_hostname_code_path)
	if file.Exists(custom_hostname_menu_script_path, "MOD") then
		custom_hostname_menu_script_path = custom_hostname_menu_script_path:gsub("^lua/", "")

		gmx.Print(("Running \"%s\""):format(custom_hostname_menu_script_path))
		include(custom_hostname_menu_script_path)
	end

	local custom_hostname_client_script_path = ("%s/client.lua"):format(custom_hostname_code_path)
	if file.Exists(custom_hostname_client_script_path, "MOD") then
		local code = file.Read(custom_hostname_client_script_path, "MOD")
		gmx.Print(("Injecting \"%s\""):format(custom_hostname_client_script_path))
		gmx.AddClientInitScript(code, true, "gmx_host_custom_code")
	end
end

hook.Add("GMXHostConnected", "gmx_hostname_custom_code", run_host_custom_code)
concommand.Add("gmx_run_host_code", function() run_host_custom_code(gmx.GetConnectedServerIPAddress()) end)

hook.Add("GMXHostDisconnected", "gmx_hostname_custom_code", function()
	gmx.RemoveClientInitScript(true, "gmx_host_custom_code")
end)