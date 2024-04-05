gmx.Require("dns", function()
	dns = {
		Lookup = function() error("module dns was not loaded") end,
		ReverseLookup = function() error("module dns was not loaded") end,
	}
end)

gmx.Require("gameevent", function()
	gameevent = {
		Listen = function() end
	}
end)

gameevent.Listen("client_beginconnect")
gameevent.Listen("client_disconnect")
gameevent.Listen("server_spawn")
gameevent.Listen("OnRequestFullUpdate")

local HOST = gmx.Module("Host")
local INTEROP = gmx.Module("Interop")
local INIT = gmx.Module("ClientInit")
local WHITELIST = {}
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
function HOST.GetIPAddress()
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

local is_connected = false
local client_fully_initialized = false
local host_display_name = ""
local function set_host_state(state, addr)
	if is_connected == state then return end

	if state then
		is_connected = true
		cached_address = addr
		hook.Run("GMXHostConnected", HOST.GetIPAddress())
	else
		is_connected = false
		host_display_name = ""
		client_fully_initialized = false
		cached_address = nil
		hook.Run("GMXHostDisconnected")
	end
end

hook.Add("client_beginconnect", "gmx_host_connection_status", function(connection_data)
	if is_connected then
		-- force disconnect before, in some cases like map changes client_disconnect is not called
		set_host_state(false)
	end

	set_host_state(true, sanitize_address(connection_data.address))
end)

hook.Add("client_disconnect", "gmx_host_connection_status", function()
	set_host_state(false)
end)

hook.Add("server_spawn", "host_display_name", function(data)
	host_display_name = data.hostname
end)

function HOST.GetDisplayName()
	return host_display_name
end

hook.Add("OnRequestFullUpdate", "gmx_client_fully_initialized", function()
	if client_fully_initialized then return end

	timer.Create("gmx_client_fully_initialized", 5, 0, function()
		if not IsInGame() then return end
		if IsInLoading() then return end

		if not is_connected then
			timer.Remove("gmx_client_fully_initialized")
			return
		end

		hook.Run("ClientFullyInitialized")
		client_fully_initialized = true
		timer.Remove("gmx_client_fully_initialized")

		gmx.Print("Client fully initialized!")
	end)
end)

_G.OldGameDetails = _G.OldGameDetails or _G.GameDetails
function GameDetails(server_name, server_url, map_name, max_players, steamid, gm)
	local is_blocked = hook.Run("OnHTTPRequest", server_url, "GET", {}, "text/html", "")
	if is_blocked then return end

	_G.OldGameDetails(server_name, server_url, map_name, max_players, steamid, gm)
end

hook.Add("GMXInitialized", "gmx_host_ip", function()
	if not IsInGame() then return end

	INTEROP.RequestClientData("game.GetIPAddress()", function(ip)
		cached_address = sanitize_address(ip)
	end)

	is_connected = true
end)

local host_ip_cvar = GetConVar("hostip")
function HOST.GetLocalNetworkIPAddress()
	local host_ip = host_ip_cvar:GetInt()
	local ip = {}

	ip[1] = bit.rshift(bit.band(host_ip, 0xFF000000), 24)
	ip[2] = bit.rshift(bit.band(host_ip, 0x00FF0000), 16)
	ip[3] = bit.rshift(bit.band(host_ip, 0x0000FF00), 8)
	ip[4] = bit.band(host_ip, 0x000000FF)

	return table.concat(ip, ".")
end

function HOST.IsWhitelisted()
	if not IsInGame() and not IsInLoading() then return true end

	return WHITELIST[HOST.GetIPAddress()] ~= nil
end

gmx.RegisterConstantProvider("GMX_HOST_WHITELISTED", function()
	return WHITELIST[HOST.GetIPAddress()] ~= nil
end)

local HOSTNAME_LOOKUP = {}
for _, hostname in ipairs(HOSTNAMES_TO_REVERSE) do
	local ips = dns.Lookup(hostname)
	for _, ip in ipairs(ips) do
		HOSTNAME_LOOKUP[ip] = hostname
	end
end

function HOST.GetHostname()
	return HOSTNAME_LOOKUP[HOST.GetIPAddress()]
end

local scripts_running = false
function HOST.IsRunningCode()
	return scripts_running
end

local init_script_identifiers = {}
local function run_host_custom_code(ip)
	local host_script_base_path
	local hostname = HOSTNAME_LOOKUP[ip]
	if not hostname then
		local _, dirs = file.Find("lua/gmx/gmx_scripts/dynamic/" .. ip .. "*", "MOD")
		if dirs[1] and dirs[1]:StartWith(ip) then
			hostname = dirs[1]
			host_script_base_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(dirs[1])
		else
			-- discard
			return
		end
	else
		host_script_base_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(hostname)

		if not file.Exists(host_script_base_path, "MOD") then -- priority to subdomains then global domain
			local hostname_components = hostname:Split(".")
			local base_hostname = ("%s.%s"):format(hostname_components[#hostname_components - 1], hostname_components[#hostname_components])
			host_script_base_path = ("lua/gmx/gmx_scripts/dynamic/%s"):format(base_hostname)
		end
	end

	gmx.Print("Hostname Detected", ip)

	local host_config_path = ("%s/config.json"):format(host_script_base_path)
	if file.Exists(host_config_path, "MOD") then
		local json = file.Read(host_config_path, "MOD")
		local config = util.JSONToTable(json)

		gmx.Print("Loading Custom Code", ("[ %s ]"):format(config.Name or hostname), host_script_base_path)

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
						-- ran only manually through the command when connected to host
						gmx.RunOnClient(code, {
							"util",
							"interop"
						})
					else
						-- added as soon as we're loading / connecting to host
						local identifier = ("gmx_host_custom_code[%s]"):format(client_file_path)
						INIT.AddClientInitScript(code, true, identifier)
						table.insert(init_script_identifiers, identifier)
					end

					scripts_running = true
				end
			end
		end
	end
end

hook.Add("GMXHostConnected", "gmx_hostname_custom_code", run_host_custom_code)
concommand.Add("gmx_run_host_code", function() run_host_custom_code(HOST.GetIPAddress()) end)

hook.Add("GMXHostDisconnected", "gmx_hostname_custom_code", function()
	for _, identifier in ipairs(init_script_identifiers) do
		INIT.RemoveClientInitScript(true, identifier)
	end

	scripts_running = false
	init_script_identifiers = {}
end)