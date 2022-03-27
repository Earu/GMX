function get_cur_ip_address()
	local hostip = GetConVar("hostip"):GetInt()

	local ip = {}
	ip[1] = bit.rshift(bit.band(hostip, 0xFF000000), 24)
	ip[2] = bit.rshift(bit.band(hostip, 0x00FF0000), 16)
	ip[3] = bit.rshift(bit.band(hostip, 0x0000FF00), 8)
	ip[4] = bit.band(hostip, 0x000000FF)

	return table.concat(ip, ".")
end

local cur_ip_addr = get_cur_ip_address()
hook.Add("ClientStateCreated", "gmx_srv_whitelist", function()
	cur_ip_addr = get_cur_ip_address()
end)

local WHITELIST = {
	["0"] = true, -- menu
	["149.202.89.113"] = true, -- s1.hbn.gg:27025
}

function gmx.IsGameWhitelisted()
	if not IsInGame() then return true end
	return WHITELIST[cur_ip_addr] ~= nil
end