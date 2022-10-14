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

	local should_allow = hook.Run("GMXShouldRunCommand", real_cmd, cmd) == true or WHITELIST[real_cmd]
	if should_allow then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)

		return
	end

	gmx.Print(("Blocked incoming server (%s) command \"%s\""):format(net_chan:GetAddress(), cmd))
end

FilterIncomingMessage(net_StringCmd, command_filtering)

--[[FilterIncomingMessage(net_SetConVar, function(_, read, write)
	local count = read:ReadByte()
	for i = 1, count do
		local cvar_name = read:ReadString()
		local cvar_value = read:ReadString()

		local should_set = hook.Run("GMXConVarShouldSet", cvar_name, cvar_value)
		if should_set == false then continue end

		write:WriteString(cvar_name)
		write:WriteString(cvar_value)
	end
end)]]--