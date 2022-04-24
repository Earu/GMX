require("sourcenet")

local host_ip_cvar = GetConVar("hostip")
function gmx.GetIPAddress(force)
	if IsInGame() then
		local chan_addr = CNetChan():GetAddress()
		if chan_addr then
			return tostring(chan_addr)
		end
	end

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
	return WHITELIST[gmx.GetIPAddress()] ~= nil
end