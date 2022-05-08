if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/incoming.lua")

local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
	r_cleardecals = true,
}

FilterIncomingMessage(net_StringCmd, function(net_chan, read, write)
	local cmd = read:ReadString()
	local real_cmd = cmd:Split(" ")[1]:lower():Trim()
	if WHITELIST[real_cmd] then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)
		return
	end

	gmx.Print(("Blocked incoming server (%s) command \"%s\""):format(net_chan:GetAddress(), cmd))
end)