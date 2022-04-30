if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/outgoing.lua")

FilterOutgoingMessage(net_Tick, function(netchan, read, write)
	write:WriteUInt(net_Tick, NET_MESSAGE_BITS)

	local tick = read:ReadLong()
	write:WriteLong(tick)

	read:ReadUInt(16)
	write:WriteUInt(1, 16)

	local hostframetimedeviation = read:ReadUInt(16)
	write:WriteUInt(hostframetimedeviation, 16)
end)

hook.Add("ClientFullyInitialized", "gmx_host_server_autorun", function()
	local code = file.Read("lua/gmx/gmx_scripts/dynamic/metastruct.net/server.lua", "MOD")
	gmx.RunOnClient(("if luadev and luadev.RunOnServer then luadev.RunOnServer(([[%s]]):gsub(\"{STEAM_ID}\", LocalPlayer():SteamID()), \"GMX\") end"):format(code))
	hook.Remove("ClientFullyInitialized", "gmx_host_server_autorun")
end)