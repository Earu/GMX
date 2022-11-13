local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
	r_cleardecals = true,
	material_override = true,
}

local function command_filtering(_, read, write)
	local cmd = read:ReadString()
	local real_cmd = cmd:Split(" ")[1]:lower():Trim()

	local should_allow = hook.Run("GMXShouldRunCommand", real_cmd, cmd) == true or WHITELIST[real_cmd]
	if should_allow then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)

		return
	end

	gmx.Print(("Blocked incoming server command \"%s\""):format(cmd))
	return true
end

FilterIncomingMessage(net_StringCmd, command_filtering)