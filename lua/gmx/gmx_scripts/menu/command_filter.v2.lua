if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/incoming.lua")

local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
	r_cleardecals = true,
}

local function command_filtering(net_chan, read, write)
	local cmd = read:ReadString()
	local real_cmd = cmd:Split(" ")[1]:lower():Trim()

	local should_allow = WHITELIST[real_cmd]--hook.Run("GMXShouldRunCommand", real_cmd, cmd) == true or WHITELIST[real_cmd]
	if should_allow then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)
	end

	gmx.Print(("Blocked incoming server (%s) command \"%s\""):format(net_chan:GetAddress(), cmd))
	return true
end

FilterIncomingMessage(net_StringCmd, command_filtering)