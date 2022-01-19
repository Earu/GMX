include("gmx/deps/sourcenet/incoming.lua")

local HEADER_COLOR = Color(255, 157, 0)
local BODY_COLOR = Color(255, 196, 0)
local function gmx_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[GMX] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
	r_cleardecals = true,
}

-- force the client to fullupdate, or we can get stuck in some weird limbo
hook.Add("ClientFullyInitialized", "gmx_fix_timeout", function()
	RunOnClient("", "", [[
		LocalPlayer():ConCommand("record removeme", true)
		RunConsoleCommand("stop")
	]])
end)

FilterIncomingMessage(net_StringCmd, function(netchan, read, write)
	local cmd = read:ReadString()
	local real_cmd = cmd:Split(" ")[1]:lower():Trim()
	if WHITELIST[real_cmd] then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)
		return
	end

	gmx_print(string.format("Blocked incoming server (%s) command \"%s\"", netchan:GetAddress(), cmd))
end)