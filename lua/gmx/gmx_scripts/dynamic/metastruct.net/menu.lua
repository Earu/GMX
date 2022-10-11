if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/outgoing.lua")

FilterOutgoingMessage(net_Tick, function(netchan, read, write)
	write:WriteUInt(net_Tick, NET_MESSAGE_BITS)

	local tick = read:ReadLong()
	write:WriteLong(tick)

	local frames = read:ReadUInt(16) / 4
	write:WriteUInt(frames, 16)

	local host_frame_time_deviation = read:ReadUInt(16)
	write:WriteUInt(host_frame_time_deviation, 16)
end)

hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
	local server_autorun_code = file.Read("lua/gmx/gmx_scripts/dynamic/metastruct.net/server.lua", "MOD")
	gmx.RunOnClient(("if luadev and luadev.RunOnServer then luadev.RunOnServer((%q):gsub(\"{STEAM_ID}\", LocalPlayer():SteamID()), \"GMX\") end"):format(server_autorun_code))

	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)