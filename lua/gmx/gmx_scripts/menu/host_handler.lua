require("asc")
require("dns")

local cached_address
hook.Add("AllowStringCommand", "gmx_host_address", function(cmd_str)
	if not cmd_str:lower():match("^connect") then return end

	local args = cmd_str:lower():Split(" ")
	cached_address = table.concat(args, " ", 2):Trim():gsub("%:[0-9]+$", "")

	hook.Run("GMXHostConnected", gmx.GetConnectedServerIPAddress())
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

local INVALID_IP = "0.0.0.0"
function gmx.GetConnectedServerIPAddress()
	if cached_address then
		local ip = cached_address
		if not cached_address:match("^%d+%.%d+%.%d+%.%d+$") then
			ip = dns.Lookup(cached_address)[1]
		end

		if ip then
			cached_address = ip
			return cached_address
		end
	end

	return INVALID_IP
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

local function is_connected_to_server()
	return gmx.GetConnectedServerIPAddress() ~= INVALID_IP
end

local connected_state = is_connected_to_server()
hook.Add("Think", "gmx_host_hooks", function()
	local cur_state = is_connected_to_server()
	if cur_state ~= connected_state then
		connected_state = cur_state
		if not connected_state then
			hook.Run("GMXHostDisconnected")
		end
	end
end)

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