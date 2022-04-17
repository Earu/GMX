include ("gmx/gmx_scripts/menu/sourcenet/outgoing.lua")

FilterOutgoingMessage(net_Tick, function(netchan, read, write)
	write:WriteUInt(net_Tick, NET_MESSAGE_BITS)

	local tick = read:ReadLong()
	write:WriteLong(tick)

	read:ReadUInt(16)
	write:WriteUInt(1, 16)

	local hostframetimedeviation = read:ReadUInt(16)
	write:WriteUInt(hostframetimedeviation, 16)
end)