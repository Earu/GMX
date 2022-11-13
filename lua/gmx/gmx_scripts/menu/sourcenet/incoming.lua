include("client.lua")
include("netmessages.lua")

-- Initialization
HookNetChannel(
	-- nochan prevents a net channel being passed to the attach/detach functions
	-- CNetChan::ProcessMessages doesn't use a virtual hook, so we don't need to pass the net channel
	{name = "CNetChan::ProcessMessages", nochan = true}
)

local NET_MESSAGES_INSTANCES = {}

local function GetNetMessageInstance(netchan, msgtype)
	local handler = NET_MESSAGES_INSTANCES[msgtype]
	if handler == nil then
		handler = NetMessage(netchan, msgtype, not SERVER)
		NET_MESSAGES_INSTANCES[msgtype] = handler
	else
		handler:Reset()
	end

	return handler
end

local NET_MESSAGES_INCOMING_COPY = {
	NET = {},
	CLC = {},
	SVC = {}
}

local function GetIncomingCopyTableForMessageType(msgtype)
	if NET_MESSAGES.NET[msgtype] ~= nil then
		return NET_MESSAGES_INCOMING_COPY.NET
	end

	if CLIENT and NET_MESSAGES.SVC[msgtype] ~= nil then
		return NET_MESSAGES_INCOMING_COPY.SVC
	end

	if SERVER and NET_MESSAGES.CLC[msgtype] ~= nil then
		return NET_MESSAGES_INCOMING_COPY.CLC
	end

	return nil
end

local function DefaultCopy(netchan, read, write, handler)
	handler:ReadFromBuffer(read)
	handler:WriteToBuffer(write)
end

local should_discard = false
hook.Add("PreProcessMessages", "InFilter", function(netchan, read, write, localchan)
	if not IsInGame() then return false end
	if should_discard then return true end

	local islocal = netchan == localchan
	if ((islocal and SERVER) or (not islocal and CLIENT)) then
		return
	end

	while read:GetNumBitsLeft() >= NET_MESSAGE_BITS do
		local msgtype = read:ReadUInt(NET_MESSAGE_BITS)
		local handler = GetNetMessageInstance(netchan, msgtype)
		if handler == nil then
			--MsgC(Color(255, 0, 0), "Unknown outgoing message " .. msgtype .. " with " .. read:GetNumBitsLeft() .. " bit(s) left\n")
			return false
		end

		local incoming_copy_table = GetIncomingCopyTableForMessageType(msgtype)
		local copy_function = incoming_copy_table ~= nil and incoming_copy_table[msgtype] or DefaultCopy
		copy_function(netchan, read, write, handler)

		--MsgC(Color(255, 255, 255), "NetMessage: " .. tostring(handler) .. "\n")
	end

	local bitsleft = read:GetNumBitsLeft()
	if bitsleft > 0 then
		-- Should be inocuous padding bits but just to be sure, let's copy them
		local data = read:ReadBits(bitsleft)
		write:WriteBits(data)
	end

	--MsgC(Color(0, 255, 0), "Fully parsed stream with " .. totalbits .. " bit(s) written\n")
	return true
end)

function FilterIncomingMessage(msg_type, func)
	local incoming_copy_table = GetIncomingCopyTableForMessageType(msg_type)
	if incoming_copy_table == nil then
		return false
	end

	incoming_copy_table[msg_type] = func
	return true
end

function UnFilterIncomingMessage(msg_type)
	return FilterIncomingMessage(msg_type, nil)
end

function DiscardIncomingMessages(time)
	should_discard = true

	timer.Create("gmx_sourcenet_discard_msgs", time, 1, function()
		should_discard = false
	end)
end