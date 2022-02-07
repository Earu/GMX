include("client.lua")
include("netmessages.lua")

-- Initialization
HookNetChannel(
	-- nochan prevents a net channel being passed to the attach/detach functions
	-- CNetChan::ProcessMessages doesn't use a virtual hook, so we don't need to pass the net channel
	{name = "CNetChan::ProcessMessages", nochan = true}
)

local NET_MESSAGES_INSTANCES = {}

local function GetNetMessageInstance(netchan, msg_type)
	local handler = NET_MESSAGES_INSTANCES[msg_type]
	if handler == nil then
		handler = NetMessage(netchan, msg_type)
		NET_MESSAGES_INSTANCES[msg_type] = handler
	else
		handler:Reset()
	end

	return handler
end

local NET_MESSAGES_INCOMING_COPY = {
	NET = {},
	SVC = {}
}

local function GetIncomingCopyTableForMessageType(msg_type)
	if NET_MESSAGES.NET[msg_type] ~= nil then
		return NET_MESSAGES_INCOMING_COPY.NET
	end

	if MENU_DLL and NET_MESSAGES.SVC[msg_type] ~= nil then
		return NET_MESSAGES_INCOMING_COPY.SVC
	end

	return nil
end

local function DefaultCopy(netchan, read, write, handler)
	handler:ReadFromBuffer(read)
	handler:WriteToBuffer(write)
end

hook.Add("PreProcessMessages", "InFilter", function(netchan, read, write, localchan)
	if not IsInGame() then return end

	local is_local = netchan == localchan
	if not is_local and MENU_DLL then return end

	while read:GetNumBitsLeft() >= NET_MESSAGE_BITS do
		local msg_type = read:ReadUInt(NET_MESSAGE_BITS)
		local handler = GetNetMessageInstance(netchan, msg_type)
		if handler == nil then
			MsgC(Color(255, 0, 0), "Unknown outgoing message " .. msg_type .. " with " .. read:GetNumBitsLeft() .. " bit(s) left\n")
			return false
		end

		local incoming_copy_table = GetIncomingCopyTableForMessageType(msg_type)
		local copy_function = incoming_copy_table ~= nil and incoming_copy_table[msg_type] or DefaultCopy
		copy_function(netchan, read, write, handler)

		--MsgC(Color(255, 255, 255), "NetMessage: " .. tostring(handler) .. "\n")
	end

	local bits_left = read:GetNumBitsLeft()
	if bits_left > 0 then
		-- Should be inocuous padding bits but just to be sure, let's copy them
		local data = read:ReadBits(bits_left)
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
