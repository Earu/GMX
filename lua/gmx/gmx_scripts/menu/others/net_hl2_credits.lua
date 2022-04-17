-- TO RUN ON A SERVER RUNNING SOURCENET

local function play_credits(ply)
	local buffer = ply:GetNetChannel():GetReliableBuffer()
	buffer:WriteUInt(svc_UserMessage, NET_MESSAGE_BITS)
	buffer:WriteByte(24)

	local ptr = UCHARPTR(256)
	local write = sn_bf_write(ptr)
	write:WriteByte(3)
	buffer:WriteUInt(write:GetNumBitsWritten(), 11)
	buffer:WriteBits(ptr)
end