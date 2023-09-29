require("asc")
require("dns")

local WHITELIST = {
	["0"] = true, -- menu
	["149.202.89.113"] = true, -- s1.hbn.gg:27025
}

local HOSTNAMES_TO_REVERSE = {}

local host_scripts_dir = "lua/gmx/gmx_scripts/dynamic/"
local _, script_dirs = file.Find(host_scripts_dir .. "/*", "MOD")
for _, script_dir in ipairs(script_dirs) do
	local host_config_path = ("%s%s/config.json"):format(host_scripts_dir, script_dir)
	if file.Exists(host_config_path, "MOD") then
		local json = file.Read(host_config_path, "MOD")
		local host_config = util.JSONToTable(json)
		if istable(host_config.SubDomains) then
			for _, sub_domain in ipairs(host_config.SubDomains) do
				table.insert(HOSTNAMES_TO_REVERSE, sub_domain)

				if host_config.Trusted then
					local ip = dns.Lookup(sub_domain)[1]
					if ip then WHITELIST[ip] = true end
				end
			end
		end
	else
		if script_dir ~= "loopback" then
			table.insert(HOSTNAMES_TO_REVERSE, script_dir)
		end
	end
end

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

_G.OldGameDetails = _G.OldGameDetails or _G.GameDetails
function GameDetails(server_name, server_url, map_name, max_players, steamid, gm)
	if gmx.GetConnectedServerIPAddress() == INVALID_IP then
		if CNetChan and CNetChan() then
			cached_address = tostring(CNetChan():GetAddress()):gsub("%:[0-9]+$", "")
			hook.Run("GMXHostConnected", gmx.GetConnectedServerIPAddress())

			return
		end

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

	local is_blocked = hook.Run("OnHTTPRequest", server_url, "GET", {}, "text/html", "")
	if is_blocked then return end

	_G.OldGameDetails(server_name, server_url, map_name, max_players, steamid, gm)
end

if IsInGame() then
	if CNetChan and CNetChan() then
		cached_address = tostring(CNetChan():GetAddress()):gsub("%:[0-9]+$", "")
	else
		gmx.RequestClientData("game.GetIPAddress()", function(ip)
			cached_address = sanitize_address(ip)
		end)
	end
end

--
-- GetConfigValue( ESteamNetworkingConfigValue eValue, ESteamNetworkingConfigScope eScopeType, intptr_t scopeObj, ESteamNetworkingConfigDataType *pOutDataType, void *pResult, size_t *cbResult );

hook.Add("AllowStringCommand", "gmx_host_address", function(cmd_str)
	if cmd_str:lower():match("^connect") then
		local args = cmd_str:lower():Split(" ")
		cached_address = sanitize_address(table.concat(args, " ", 2))

		hook.Run("GMXHostConnected", gmx.GetConnectedServerIPAddress())
	elseif cmd_str:lower():match("^disconnect") or cmd_str:lower():match("^retry") then
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

function gmx.IsHostWhitelisted()
	if not IsInGame() then return true end
	return WHITELIST[gmx.GetConnectedServerIPAddress()] ~= nil
end

local HOSTNAME_LOOKUP = {}
for _, hostname in ipairs(HOSTNAMES_TO_REVERSE) do
	local ips = dns.Lookup(hostname)
	for _, ip in ipairs(ips) do
		HOSTNAME_LOOKUP[ip] = hostname
	end
end

function gmx.GetConnectedServerHostname()
	return HOSTNAME_LOOKUP[gmx.GetConnectedServerIPAddress()]
end

local scripts_running = false
function gmx.RunningHostCode()
	return scripts_running
end

local init_script_identifiers = {}
local function run_host_custom_code(ip)
	local hostname = HOSTNAME_LOOKUP[ip]
	if not hostname then return end

	gmx.Print("Hostname Detected", ip)

	local host_script_base_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(hostname)
	if not file.Exists(host_script_base_path, "MOD") then -- priority to subdomains then global domain
		local hostname_components = hostname:Split(".")
		local base_hostname = ("%s.%s"):format(hostname_components[#hostname_components - 1], hostname_components[#hostname_components])
		host_script_base_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(base_hostname)
	end

	gmx.Print("Loading Custom Code", hostname, host_script_base_path)

	local host_config_path = ("%s/config.json"):format(host_script_base_path)
	if file.Exists(host_config_path, "MOD") then
		local json = file.Read(host_config_path, "MOD")
		local config = util.JSONToTable(json)

		if config.Trusted then
			gmx.Print("Host is TRUSTED/WHITELISTED")
		end

		if istable(config.MenuFiles) then
			for _, menu_file in pairs(config.MenuFiles) do
				local menu_file_path = ("%s/%s"):format(host_script_base_path, menu_file)
				if file.Exists(menu_file_path, "MOD") then
					menu_file_path = menu_file_path:gsub("^lua/", "")
					gmx.Print(("Running \"%s\""):format(menu_file_path))
					include(menu_file_path)

					scripts_running = true
				end
			end
		end

		if istable(config.ClientFiles) then
			for _, client_file in pairs(config.ClientFiles) do
				local client_file_path = ("%s/%s"):format(host_script_base_path, client_file)
				if file.Exists(client_file_path, "MOD") then
					local code = file.Read(client_file_path, "MOD")
					gmx.Print(("Injecting \"%s\""):format(client_file_path))

					if IsInGame() and not IsInLoading() then
						gmx.RunOnClient(code, {
							"util",
							"detouring",
							"interop"
						})
					else
						local identifier = ("gmx_host_custom_code[%s]"):format(client_file_path)
						gmx.AddClientInitScript(code, true, identifier)
						table.insert(init_script_identifiers, identifier)
					end

					scripts_running = true
				end
			end
		end
	end
end

hook.Add("GMXHostConnected", "gmx_hostname_custom_code", run_host_custom_code)
concommand.Add("gmx_run_host_code", function() run_host_custom_code(gmx.GetConnectedServerIPAddress()) end)

hook.Add("GMXHostDisconnected", "gmx_hostname_custom_code", function()
	for _, identifier in ipairs(init_script_identifiers) do
		gmx.RemoveClientInitScript(true, identifier)
	end

	scripts_running = false
	init_script_identifiers = {}
end)