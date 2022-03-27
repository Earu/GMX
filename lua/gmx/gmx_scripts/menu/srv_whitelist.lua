local host_ip_cvar = GetConVar("hostip")
local cached_ip
local next_cache_update = 0
function gmx.GetIPAddress(force)
	if force or not cached_ip or CurTime() >= next_cache_update then
		local host_ip = host_ip_cvar:GetInt()
		local ip = {}

		ip[1] = bit.rshift(bit.band(host_ip, 0xFF000000), 24)
		ip[2] = bit.rshift(bit.band(host_ip, 0x00FF0000), 16)
		ip[3] = bit.rshift(bit.band(host_ip, 0x0000FF00), 8)
		ip[4] = bit.band(host_ip, 0x000000FF)

		cached_ip = table.concat(ip, ".")
		next_cache_update = CurTime() + 0.5
	end

	return cached_ip
end

local cur_ip_addr = gmx.GetIPAddress()
hook.Add("ClientStateCreated", "gmx_srv_whitelist", function()
	cur_ip_addr = gmx.GetIPAddress(true)
end)

local WHITELIST = {
	["0"] = true, -- menu
	["149.202.89.113"] = true, -- s1.hbn.gg:27025
}

function gmx.IsGameWhitelisted()
	if not IsInGame() then return true end
	return WHITELIST[cur_ip_addr] ~= nil
end