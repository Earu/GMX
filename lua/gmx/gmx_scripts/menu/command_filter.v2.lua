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

local function cvars_filtering(_, read, write)
	local count = read:ReadByte()
	local cvars_to_network = {}
	local count_to_network = 0
	for _ = 1, count do
		local cvar_name = read:ReadString()
		local cvar_value = read:ReadString()

		local should_set = hook.Run("GMXConVarShouldSet", cvar_name, cvar_value)
		if should_set == false then continue end

		cvars_to_network[cvar_name] = cvar_value
		count_to_network = count_to_network + 1
	end

	if count_to_network < 1 then return end

	write:WriteByte(count_to_network)
	for cvar_name, cvar_value in pairs(cvars_to_network) do
		write:WriteString(cvar_name)
		write:WriteString(cvar_value)
	end
end

FilterIncomingMessage(net_StringCmd, command_filtering)
FilterIncomingMessage(net_SetConVar, cvars_filtering)