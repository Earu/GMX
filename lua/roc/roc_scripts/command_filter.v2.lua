include("roc/deps/sourcenet/incoming.lua")

local HEADER_COLOR = Color(255, 0, 0)
local BODY_COLOR = Color(197, 53, 17)
local function roc_print(...)
	local args = {}
	for key, arg in pairs({ ... }) do
		args[key] = tostring(arg)
	end

	MsgC(HEADER_COLOR, "[ROC] ", BODY_COLOR, table.concat(args, "\t") .. "\n")
end

local WHITELIST = {
	dsp_player = true,
	gmod_toolmode = true,
	r_cleardecals = true,
}

FilterIncomingMessage(net_StringCmd, function(netchan, read, write)
	local cmd = read:ReadString()
	local real_cmd = cmd:Split(" ")[1]:lower():Trim()
	if WHITELIST[real_cmd] then
		write:WriteUInt(net_StringCmd, NET_MESSAGE_BITS)
		write:WriteString(cmd)
		return
	end

	roc_print(string.format("Blocked incoming server (%s) command \"%s\"", netchan:GetAddress(), cmd))
end)