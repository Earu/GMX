if not system.IsWindows() then return end

include("gmx/gmx_scripts/menu/sourcenet/outgoing.lua")

local COLOR_RED = Color(255, 0, 0)
FilterOutgoingMessage(clc_GMod_ClientToServer, function(netchan, read, write)
	local bits = buffer:ReadUInt(20)
	local msg_type = buffer:ReadByte()

	-- lua error
	if msg_type == 2 then
		local err = buffer:ReadString()
		MsgC(COLOR_RED, err, "\n")

		-- don't send to server
		--write:WriteString(err)
		return
	end

	write:WriteUInt(clc_GMod_ClientToServer, NET_MESSAGE_BITS)
	write:WriteUInt(bits, 20)
	write:WriteByte(msg_type)

	local remaining_bits = bits - 8
	if msg_type == 0 then
		local id = buffer:ReadWord()
		remaining_bits = remaining_bits - 16

		write:WriteWord(id)

		if remaining_bits > 0 then
			local data = buffer:ReadBits(remaining_bits)
			write:WriteBits(data)
		end
	elseif msg_type == 4 then
		local count = remaining_bits / 16
		for i = 1, count do
			local id = buffer:ReadUInt(16)
			write:WriteUInt(id, 16)
		end
	end
end)